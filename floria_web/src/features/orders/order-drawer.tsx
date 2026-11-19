"use client";

import { useEffect, useState } from "react";
import { Ban, CheckCircle2, CircleDollarSign, Package, RotateCcw, ShieldAlert, Truck } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { DetailDrawer, DetailSection, InfoGrid } from "@/components/shared/detail-drawer";
import { StatusBadge, statusLabel } from "@/components/shared/status-badge";
import { ActivityTimeline } from "@/components/shared/activity-timeline";
import { ConfirmDialog } from "@/components/shared/confirm-dialog";
import { useAuthStore } from "@/stores/auth-store";
import { formatDateTime, formatVND } from "@/lib/format";
import type { FulfillmentStatus, Order } from "@/types";
import { canConfirmCod, canRequestRefund, isVerifiedTransaction, nextStatuses, orderSubtotal } from "./order-rules";

const ICON: Record<FulfillmentStatus, typeof Package> = { pending: Package, confirmed: CheckCircle2, shipping: Truck, delivered: CheckCircle2, cancelled: Ban };

export function OrderDrawer({ order, onOpenChange, onUpdate, canEdit }: { order: Order | null; onOpenChange: (o: boolean) => void; onUpdate: (patch: Partial<Order>, before: string) => void; canEdit: boolean }) {
  const admin = useAuthStore((s) => s.session?.name ?? "Admin");
  const [notes, setNotes] = useState("");
  const [confirm, setConfirm] = useState<null | { label: string; run: () => void; danger?: boolean }>(null);
  useEffect(() => setNotes(order?.notes ?? ""), [order?.id, order?.notes]);
  if (!order) return <DetailDrawer open={false} onOpenChange={onOpenChange} title=""><span /></DetailDrawer>;

  const move = (to: FulfillmentStatus) =>
    setConfirm({
      label: `Chuyển đơn sang "${statusLabel(to)}"?`,
      danger: to === "cancelled",
      run: () =>
        onUpdate(
          {
            fulfillment: to,
            timeline: [...order.timeline, { status: to, at: new Date().toISOString(), by: admin }],
            ...(to === "cancelled" && order.paymentStatus === "paid" ? { paymentStatus: "refund_requested" as const } : {}),
          },
          order.fulfillment,
        ),
    });

  return (
    <DetailDrawer
      open={!!order}
      onOpenChange={onOpenChange}
      className="sm:max-w-2xl"
      title={<span className="flex items-center gap-2">Đơn {order.code} <StatusBadge status={order.fulfillment} /></span>}
      description={`Đặt lúc ${formatDateTime(order.createdAt)}`}
      footer={canEdit ? (
        <>
          {nextStatuses(order.fulfillment).map((s) => (
            <Button key={s} variant={s === "cancelled" ? "danger-soft" : "default"} onClick={() => move(s)}>{s === "cancelled" ? <Ban /> : <Truck />} {s === "cancelled" ? "Huỷ đơn" : `Chuyển: ${statusLabel(s)}`}</Button>
          ))}
        </>
      ) : undefined}
    >
      <DetailSection title="Khách hàng & giao hàng">
        <InfoGrid items={[{ label: "Khách hàng", value: order.customerName }, { label: "Điện thoại", value: order.phone }, { label: "Email", value: order.customerEmail }, { label: "Địa chỉ", value: order.address }]} />
      </DetailSection>
      <DetailSection title="Sản phẩm">
        <div className="overflow-hidden rounded-xl border">
          <table className="w-full text-sm">
            <tbody className="divide-y">
              {order.items.map((it, i) => (
                <tr key={i}><td className="px-3 py-2.5">{it.name}</td><td className="px-3 text-center text-muted-foreground tabular">×{it.qty}</td><td className="px-3 text-right tabular">{formatVND(it.price * it.qty)}</td></tr>
              ))}
            </tbody>
            <tfoot className="bg-surface-2/50 text-sm">
              <tr><td className="px-3 pt-2.5 text-muted-foreground" colSpan={2}>Tạm tính</td><td className="px-3 pt-2.5 text-right tabular">{formatVND(orderSubtotal(order))}</td></tr>
              <tr><td className="px-3 text-muted-foreground" colSpan={2}>Phí vận chuyển</td><td className="px-3 text-right tabular">{order.shippingFee ? formatVND(order.shippingFee) : "Miễn phí"}</td></tr>
              {order.discount > 0 && <tr><td className="px-3 text-muted-foreground" colSpan={2}>Voucher {order.voucherCode}</td><td className="px-3 text-right text-success tabular">−{formatVND(order.discount)}</td></tr>}
              <tr className="font-semibold"><td className="px-3 py-2.5" colSpan={2}>Tổng cộng</td><td className="px-3 py-2.5 text-right tabular">{formatVND(order.total)}</td></tr>
            </tfoot>
          </table>
        </div>
      </DetailSection>
      <DetailSection title="Thanh toán">
        <InfoGrid items={[
          { label: "Phương thức", value: order.paymentMethod === "COD" ? "COD — Thanh toán khi nhận" : "ZaloPay" },
          { label: "Trạng thái", value: <StatusBadge status={order.paymentStatus} /> },
          { label: "Mã giao dịch", value: order.transaction ? <span className="font-mono text-xs">{order.transaction.id}</span> : "—" },
          { label: "Thời gian giao dịch", value: order.transaction ? formatDateTime(order.transaction.at) : "—" },
        ]} />
        {order.transaction && !isVerifiedTransaction(order) && (
          <p className="mt-2 flex items-center gap-2 rounded-lg bg-warning-soft px-3 py-2 text-xs text-warning"><ShieldAlert className="size-4" /> Giao dịch ZaloPay sandbox / mô phỏng — chưa được xác thực với cổng thanh toán thật.</p>
        )}
        {canEdit && (
          <div className="mt-3 flex flex-wrap gap-2">
            {canConfirmCod(order) && <Button size="sm" variant="success" onClick={() => setConfirm({ label: "Xác nhận đã thu tiền COD?", run: () => onUpdate({ paymentStatus: "paid" }, order.paymentStatus) })}><CircleDollarSign /> Xác nhận đã thu COD</Button>}
            {canRequestRefund(order) && <Button size="sm" variant="outline" onClick={() => setConfirm({ label: "Tạo yêu cầu hoàn tiền?", danger: true, run: () => onUpdate({ paymentStatus: "refund_requested" }, order.paymentStatus) })}><RotateCcw /> Yêu cầu hoàn tiền</Button>}
            {order.paymentStatus === "refund_requested" && <Button size="sm" variant="outline" onClick={() => setConfirm({ label: "Đánh dấu đã hoàn tiền?", run: () => onUpdate({ paymentStatus: "refunded" }, order.paymentStatus) })}><RotateCcw /> Đánh dấu đã hoàn tiền</Button>}
          </div>
        )}
      </DetailSection>
      <DetailSection title="Tiến trình đơn hàng">
        <ActivityTimeline items={[...order.timeline].reverse().map((t, i) => ({ id: String(i), title: statusLabel(t.status), description: `bởi ${t.by}`, time: formatDateTime(t.at), icon: ICON[t.status], tone: t.status === "cancelled" ? "danger" : t.status === "delivered" ? "leaf" : "info" }))} />
      </DetailSection>
      <DetailSection title="Ghi chú nội bộ" action={canEdit && notes !== order.notes ? <Button size="sm" variant="soft" onClick={() => onUpdate({ notes }, order.notes || "—")}>Lưu ghi chú</Button> : undefined}>
        <Textarea value={notes} onChange={(e) => setNotes(e.target.value)} placeholder="Chỉ quản trị viên nhìn thấy" disabled={!canEdit} />
      </DetailSection>
      <ConfirmDialog open={!!confirm} onOpenChange={(o) => !o && setConfirm(null)} title={confirm?.label ?? ""} tone={confirm?.danger ? "danger" : "default"} onConfirm={() => confirm?.run()} />
    </DetailDrawer>
  );
}
