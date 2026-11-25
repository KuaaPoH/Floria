"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { AlertCircle, Check, CreditCard, Loader2, MapPin, Pencil, Plus, ShoppingBag, Tag, Truck } from "lucide-react";
import { toast } from "sonner";
import { PageContainer, PageHeader } from "@/components/layout/PageContainer";
import { EmptyState, LoadingState } from "@/components/layout/states";
import { ZaloPayGatewayDialog, type ZaloPaySessionInfo } from "@/components/products/ZaloPayGatewayDialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { cartLines, evaluateVoucher, orderTotals } from "@/features/ecommerce/logic";
import { AddressFormDialog } from "@/features/profile/AddressFormDialog";
import { useAddresses, useOrderMutations, useProducts, useVouchers } from "@/hooks/queries";
import { formatVND } from "@/lib/format";
import { cn } from "@/lib/utils";
import { commerceService } from "@/services/commerce.service";
import { useCart } from "@/stores/cart";
import type { Address, PaymentMethod } from "@/types/user";

export default function CheckoutPage() {
  const router = useRouter();
  const { data: products = [], isLoading: prodLoading } = useProducts();
  const { data: addresses = [], isLoading: addrLoading } = useAddresses();
  const { data: vouchers = [] } = useVouchers();
  const { place } = useOrderMutations();

  const items = useCart((s) => s.items);
  const checkoutIds = useCart((s) => s.checkoutIds);
  const removeOrdered = useCart((s) => s.removeOrdered);

  const targetLines = useMemo(() => {
    const lines = cartLines(items, products);
    if (checkoutIds.length > 0) {
      const set = new Set(checkoutIds);
      return lines.filter((l) => set.has(l.item.productId));
    }
    return lines.filter((l) => l.item.selected);
  }, [items, products, checkoutIds]);

  const [addressId, setAddressId] = useState<string>("");
  const [addrDialog, setAddrDialog] = useState<{ open: boolean; editing?: Address }>({ open: false });
  const [voucherInput, setVoucherInput] = useState("");
  const [appliedCode, setAppliedCode] = useState<string | null>(null);
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>("zalopay");
  const [zaloPaySession, setZaloPaySession] = useState<ZaloPaySessionInfo | null>(null);

  useEffect(() => {
    if (!addressId && addresses.length) {
      setAddressId((addresses.find((a) => a.isDefault) ?? addresses[0]).id);
    }
  }, [addresses, addressId]);

  const subtotal = targetLines.reduce((s, l) => s + l.lineTotal, 0);
  const activeVoucher = appliedCode ? vouchers.find((v) => v.code === appliedCode) : undefined;
  const voucherCheck = appliedCode ? evaluateVoucher(activeVoucher, subtotal) : null;
  const totals = orderTotals(subtotal, 0, voucherCheck);

  const applyCode = (code: string) => {
    const clean = code.trim().toUpperCase();
    if (!clean) {
      setAppliedCode(null);
      return;
    }
    const v = vouchers.find((x) => x.code.toUpperCase() === clean);
    const check = evaluateVoucher(v, subtotal);
    if (!check.ok) {
      const msg =
        check.reason === "not_found"
          ? "Mã giảm giá không tồn tại."
          : check.reason === "inactive"
            ? "Mã giảm giá hiện không khả dụng."
            : check.reason === "expired"
              ? "Mã giảm giá đã hết hạn."
              : `Đơn tối thiểu ${formatVND(check.minOrder ?? 0)} để áp dụng mã này.`;
      toast.error(msg);
      return;
    }
    setVoucherInput(v!.code);
    setAppliedCode(v!.code);
    toast.success(`Đã áp dụng mã ${v!.code}`);
  };

  const submitOrder = async () => {
    if (!addressId) {
      toast.error("Vui lòng chọn hoặc thêm địa chỉ giao hàng.");
      return;
    }
    if (!targetLines.length) {
      toast.error("Không có sản phẩm nào được chọn.");
      return;
    }
    try {
      const orderedIds = targetLines.map((l) => l.item.productId);
      const ord = await place.mutateAsync({
        items: targetLines.map((l) => ({ productId: l.item.productId, quantity: l.item.quantity })),
        addressId,
        voucherCode: voucherCheck?.ok ? appliedCode : null,
        paymentMethod,
      });

      if (paymentMethod === "zalopay") {
        const zp = await commerceService.createZaloPayPayment(ord.id);
        removeOrdered(orderedIds);
        window.open(zp.order_url, "_blank", "noopener,noreferrer");
        setZaloPaySession({
          orderId: ord.id,
          orderCode: ord.code,
          amount: ord.total,
          orderUrl: zp.order_url,
          appTransId: zp.app_trans_id,
        });
        toast.success(`Đã tạo đơn hàng ${ord.code}. Vui lòng hoàn tất thanh toán ZaloPay.`);
        return;
      }

      removeOrdered(orderedIds);
      toast.success(`Đặt hàng thành công (${ord.code})`);
      router.push("/orders");
    } catch (e) {
      toast.error((e as Error).message);
    }
  };

  if (prodLoading || addrLoading) return <LoadingState className="min-h-[60vh]" />;
  if (targetLines.length === 0) {
    return (
      <PageContainer>
        <EmptyState
          icon={<ShoppingBag />}
          title="Chưa có sản phẩm để thanh toán"
          description="Hãy chọn ít nhất 1 sản phẩm trong giỏ hàng trước khi chuyển sang thanh toán."
          action={<Button asChild><Link href="/cart">Về giỏ hàng</Link></Button>}
        />
      </PageContainer>
    );
  }

  return (
    <PageContainer className="max-w-6xl">
      <PageHeader eyebrow="Thanh toán" title="Hoàn tất đơn hàng" description="Kiểm tra địa chỉ nhận hàng, mã ưu đãi và phương thức thanh toán." />

      <div className="grid gap-8 lg:grid-cols-[1.4fr_1fr] lg:items-start">
        <div className="space-y-6">
          {/* Addresses */}
          <section className="rounded-3xl border bg-card p-6 shadow-soft">
            <div className="mb-4 flex items-center justify-between gap-2">
              <h2 className="flex items-center gap-2 text-lg font-semibold"><MapPin className="size-5 text-leaf" /> Địa chỉ giao hàng</h2>
              <Button size="sm" variant="outline" onClick={() => setAddrDialog({ open: true })}><Plus /> Thêm địa chỉ</Button>
            </div>
            {addresses.length === 0 ? (
              <p className="text-sm text-muted-foreground">Bạn chưa có địa chỉ nào. Hãy thêm địa chỉ nhận hàng.</p>
            ) : (
              <div className="grid gap-3 sm:grid-cols-2">
                {addresses.map((a) => {
                  const active = a.id === addressId;
                  return (
                    <div
                      key={a.id}
                      onClick={() => setAddressId(a.id)}
                      className={cn("cursor-pointer rounded-2xl border p-4 transition-all", active ? "border-leaf bg-mint/40 ring-2 ring-leaf/25" : "hover:border-leaf/40")}
                    >
                      <div className="flex items-start justify-between gap-2">
                        <div className="flex flex-wrap items-center gap-1.5">
                          <span className="font-semibold">{a.recipientName}</span>
                          {a.isDefault && <Badge variant="success">Mặc định</Badge>}
                          {a.label && <Badge variant="muted">{a.label}</Badge>}
                        </div>
                        <button
                          type="button"
                          onClick={(e) => { e.stopPropagation(); setAddrDialog({ open: true, editing: a }); }}
                          className="text-muted-foreground hover:text-foreground"
                          aria-label="Sửa địa chỉ"
                        >
                          <Pencil className="size-4" />
                        </button>
                      </div>
                      <p className="mt-1 text-xs text-muted-foreground">{a.phone}</p>
                      <p className="mt-1.5 text-sm">{a.street}, {a.wardName}, {a.provinceName}</p>
                    </div>
                  );
                })}
              </div>
            )}
          </section>

          {/* Selected Products */}
          <section className="rounded-3xl border bg-card p-6 shadow-soft">
            <h2 className="mb-4 text-lg font-semibold">Sản phẩm đặt mua ({targetLines.length})</h2>
            <ul className="divide-y">
              {targetLines.map(({ item, product, lineTotal }) => (
                <li key={item.productId} className="flex items-center gap-4 py-3 first:pt-0 last:pb-0">
                  <img src={product.images[0]} alt={product.name} className="size-16 rounded-2xl object-cover" />
                  <div className="min-w-0 flex-1">
                    <p className="truncate font-semibold">{product.name}</p>
                    <p className="text-xs text-muted-foreground">Số lượng: {item.quantity}</p>
                  </div>
                  <p className="font-semibold">{formatVND(lineTotal)}</p>
                </li>
              ))}
            </ul>
          </section>

          {/* Voucher */}
          <section className="rounded-3xl border bg-card p-6 shadow-soft">
            <h2 className="mb-4 flex items-center gap-2 text-lg font-semibold"><Tag className="size-5 text-leaf" /> Mã giảm giá</h2>
            <div className="flex gap-2">
              <Input value={voucherInput} onChange={(e) => setVoucherInput(e.target.value)} placeholder="Nhập mã (VD: FLORIA10, FREESHIP)" />
              <Button variant="outline" onClick={() => applyCode(voucherInput)}>Áp dụng</Button>
              {appliedCode && <Button variant="ghost" onClick={() => { setAppliedCode(null); setVoucherInput(""); }}>Bỏ</Button>}
            </div>
            <div className="mt-4 grid gap-2 sm:grid-cols-2">
              {vouchers.map((v) => {
                const check = evaluateVoucher(v, subtotal);
                const selected = appliedCode === v.code && voucherCheck?.ok;
                return (
                  <button
                    key={v.code}
                    type="button"
                    disabled={!check.ok}
                    onClick={() => applyCode(v.code)}
                    className={cn("rounded-2xl border p-3 text-left transition-all disabled:cursor-not-allowed disabled:opacity-50", selected ? "border-leaf bg-mint/50" : "hover:border-leaf/40")}
                  >
                    <div className="flex items-center justify-between">
                      <span className="font-mono text-sm font-bold text-forest dark:text-foreground">{v.code}</span>
                      {selected && <Check className="size-4 text-leaf" />}
                    </div>
                    <p className="mt-1 text-xs font-medium">{v.title}</p>
                    <p className="mt-0.5 text-[11px] text-muted-foreground">Đơn tối thiểu {formatVND(v.minOrder)}</p>
                  </button>
                );
              })}
            </div>
          </section>

          {/* Payment */}
          <section className="rounded-3xl border bg-card p-6 shadow-soft">
            <h2 className="mb-4 flex items-center gap-2 text-lg font-semibold"><CreditCard className="size-5 text-leaf" /> Phương thức thanh toán</h2>
            <div className="grid gap-3 sm:grid-cols-2">
              {[
                { id: "zalopay" as const, title: "Thanh toán qua ZaloPay", desc: "Mở cổng thanh toán trực tuyến ZaloPay (Sandbox).", icon: CreditCard },
                { id: "cod" as const, title: "Thanh toán khi nhận hàng (COD)", desc: "Kiểm tra hàng trước khi thanh toán cho đơn vị vận chuyển.", icon: Truck },
              ].map((m) => {
                const active = paymentMethod === m.id;
                return (
                  <button
                    key={m.id}
                    type="button"
                    onClick={() => setPaymentMethod(m.id)}
                    className={cn("flex items-start gap-3 rounded-2xl border p-4 text-left transition-all", active ? "border-leaf bg-mint/40 ring-2 ring-leaf/25" : "hover:border-leaf/40")}
                  >
                    <span className={cn("grid size-10 shrink-0 place-items-center rounded-xl", m.id === "zalopay" ? "bg-[#EAF2FF] text-[#0068FF]" : "bg-mint text-forest")}><m.icon className="size-5" /></span>
                    <div>
                      <p className="font-semibold">{m.title}</p>
                      <p className="mt-1 text-xs text-muted-foreground">{m.desc}</p>
                    </div>
                  </button>
                );
              })}
            </div>
          </section>
        </div>

        {/* Summary */}
        <aside className="rounded-3xl border bg-card p-6 shadow-card lg:sticky lg:top-24">
          <h2 className="text-lg font-semibold">Chi tiết thanh toán</h2>
          <dl className="mt-5 space-y-3 text-sm">
            <div className="flex justify-between"><dt className="text-muted-foreground">Tạm tính</dt><dd className="font-medium">{formatVND(totals.subtotal)}</dd></div>
            {totals.discount > 0 && (
              <div className="flex justify-between text-success"><dt>Giảm giá ({appliedCode})</dt><dd className="font-semibold">-{formatVND(totals.discount)}</dd></div>
            )}
            <div className="flex justify-between border-t pt-3 text-base">
              <dt className="font-semibold">Tổng thanh toán</dt>
              <dd className="text-2xl font-bold text-forest dark:text-foreground">{formatVND(totals.total)}</dd>
            </div>
          </dl>
          {!addressId && (
            <p className="mt-4 flex items-center gap-2 rounded-xl bg-warning-soft px-3 py-2 text-xs text-warning">
              <AlertCircle className="size-4 shrink-0" /> Vui lòng thêm địa chỉ nhận hàng.
            </p>
          )}
          <Button size="lg" className="mt-6 w-full" disabled={place.isPending || !addressId} onClick={submitOrder}>
            {place.isPending && <Loader2 className="animate-spin" />}
            {paymentMethod === "zalopay" ? "Thanh toán ZaloPay" : "Đặt hàng ngay"}
          </Button>
        </aside>
      </div>

      <AddressFormDialog
        open={addrDialog.open}
        onOpenChange={(o) => setAddrDialog((s) => ({ ...s, open: o }))}
        address={addrDialog.editing}
        onSaved={(saved) => setAddressId(saved.id)}
      />

      <ZaloPayGatewayDialog
        session={zaloPaySession}
        onClose={() => router.push("/orders")}
        onPaid={() => router.push("/orders?tab=shipping")}
      />
    </PageContainer>
  );
}
