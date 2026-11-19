"use client";

import { useEffect, useMemo, useState } from "react";
import { useSearchParams } from "next/navigation";
import type { ColumnDef } from "@tanstack/react-table";
import { Clock, Download, ShoppingBag, Truck, Wallet } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { PageHeader } from "@/components/shared/page-header";
import { DataTable } from "@/components/shared/data-table";
import { SearchInput } from "@/components/shared/search-input";
import { FilterSelect } from "@/components/shared/filter-select";
import { StatusBadge, statusLabel } from "@/components/shared/status-badge";
import { StatCard } from "@/components/shared/stat-card";
import { OrderDrawer } from "@/features/orders/order-drawer";
import { useResourceList, useResourceMutations } from "@/hooks/use-resource";
import { usePermission } from "@/stores/rbac-store";
import { ordersService } from "@/services";
import { exportCsv } from "@/lib/export";
import { formatDate, formatDateTime, formatVND } from "@/lib/format";
import type { Order } from "@/types";

const FUL = ["pending", "confirmed", "shipping", "delivered", "cancelled"];
const PAY = ["unpaid", "paid", "refund_requested", "refunded", "failed"];

export default function OrdersPage() {
  const searchParams = useSearchParams();
  const q = searchParams.get("q") ?? "";
  const list = useResourceList(ordersService);
  const { update } = useResourceMutations(ordersService, { entity: "Đơn hàng", silent: true });
  const canEdit = usePermission("orders", "edit");
  const [search, setSearch] = useState(q);
  const [ful, setFul] = useState("all");
  const [pay, setPay] = useState("all");
  const [method, setMethod] = useState("all");
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const selected = list.data?.find((o) => o.id === selectedId) ?? null;

  useEffect(() => {
    if (q) setSearch(q);
  }, [q]);

  const rows = useMemo(() => {
    const s = search.toLowerCase();
    return (list.data ?? []).filter((o) => {
      const d = o.createdAt.slice(0, 10);
      return (!s || o.code.toLowerCase().includes(s) || o.customerName.toLowerCase().includes(s)) && (ful === "all" || o.fulfillment === ful) && (pay === "all" || o.paymentStatus === pay) && (method === "all" || o.paymentMethod === method) && (!from || d >= from) && (!to || d <= to);
    });
  }, [list.data, search, ful, pay, method, from, to]);

  const columns: ColumnDef<Order, unknown>[] = [
    { accessorKey: "code", header: "Mã đơn", cell: ({ getValue }) => <span className="font-mono text-xs font-semibold">{getValue() as string}</span> },
    {
      accessorKey: "customerName",
      header: "Khách hàng",
      cell: ({ row }) => (
        <div>
          <p className="font-medium">{row.original.customerName}</p>
          <p className="text-xs text-muted-foreground">{row.original.phone}</p>
        </div>
      ),
    },
    { accessorKey: "createdAt", header: "Ngày đặt", cell: ({ getValue }) => <span className="tabular">{formatDateTime(getValue() as string)}</span> },
    { id: "items", header: "Sản phẩm", cell: ({ row }) => <span className="line-clamp-1 max-w-48 text-xs text-muted-foreground">{row.original.items.map((i) => `${i.name} ×${i.qty}`).join(", ")}</span> },
    { accessorKey: "total", header: "Tổng tiền", cell: ({ getValue }) => <span className="font-semibold tabular">{formatVND(getValue() as number)}</span> },
    { accessorKey: "paymentMethod", header: "Thanh toán", cell: ({ getValue }) => <span className="text-xs font-medium">{getValue() === "ZALOPAY" ? "ZaloPay" : "COD"}</span> },
    { accessorKey: "paymentStatus", header: "TT thanh toán", cell: ({ getValue }) => <StatusBadge status={getValue() as string} /> },
    { accessorKey: "fulfillment", header: "Giao hàng", cell: ({ getValue }) => <StatusBadge status={getValue() as string} /> },
    { id: "a", header: "", enableSorting: false, cell: () => <Button size="sm" variant="ghost">Xem</Button> },
  ];

  const all = list.data ?? [];
  return (
    <>
      <PageHeader
        title="Quản lý đơn hàng"
        description="Theo dõi và cập nhật trạng thái đơn, thanh toán COD và ZaloPay."
        actions={
          <Button
            variant="outline"
            onClick={() => {
              exportCsv(
                "floria-don-hang",
                rows.map((o) => ({
                  ma_don: o.code,
                  khach_hang: o.customerName,
                  ngay: formatDate(o.createdAt),
                  tong_vnd: o.total,
                  thanh_toan: o.paymentMethod === "ZALOPAY" ? "ZaloPay" : "COD",
                  tt_thanh_toan: statusLabel(o.paymentStatus),
                  giao_hang: statusLabel(o.fulfillment),
                })),
              );
              toast.success("Đã xuất CSV");
            }}
          >
            <Download /> Xuất CSV
          </Button>
        }
      />
      <div className="mb-4 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="Tổng đơn" value={String(all.length)} icon={ShoppingBag} tone="leaf" />
        <StatCard label="Chờ xác nhận" value={String(all.filter((o) => o.fulfillment === "pending").length)} icon={Clock} tone="warning" />
        <StatCard label="Đang giao" value={String(all.filter((o) => o.fulfillment === "shipping").length)} icon={Truck} tone="info" />
        <StatCard label="Doanh thu đã thu" value={formatVND(all.filter((o) => o.paymentStatus === "paid").reduce((s, o) => s + o.total, 0))} icon={Wallet} tone="sage" />
      </div>
      <DataTable
        columns={columns}
        data={rows}
        loading={list.isLoading}
        onRowClick={(o) => setSelectedId(o.id)}
        toolbar={
          <>
            <SearchInput value={search} onChange={setSearch} placeholder="Mã đơn hoặc tên khách…" />
            <FilterSelect value={ful} onChange={setFul} allLabel="Mọi trạng thái đơn" options={FUL.map((v) => ({ value: v, label: statusLabel(v) }))} />
            <FilterSelect value={pay} onChange={setPay} allLabel="Mọi TT thanh toán" options={PAY.map((v) => ({ value: v, label: statusLabel(v) }))} />
            <FilterSelect
              value={method}
              onChange={setMethod}
              allLabel="COD & ZaloPay"
              className="sm:w-36"
              options={[
                { value: "COD", label: "COD" },
                { value: "ZALOPAY", label: "ZaloPay" },
              ]}
            />
            <div className="flex items-center gap-1.5">
              <Input type="date" value={from} onChange={(e) => setFrom(e.target.value)} className="w-[150px]" aria-label="Từ ngày" />
              <span className="text-muted-foreground">–</span>
              <Input type="date" value={to} onChange={(e) => setTo(e.target.value)} className="w-[150px]" aria-label="Đến ngày" />
            </div>
          </>
        }
      />
      <OrderDrawer
        order={selected}
        canEdit={canEdit}
        onOpenChange={(o) => !o && setSelectedId(null)}
        onUpdate={(patch, before) =>
          selected && update.mutate({ id: selected.id, patch, before, label: selected.code }, { onSuccess: () => toast.success(`Đã cập nhật đơn ${selected.code}`) })
        }
      />
    </>
  );
}
