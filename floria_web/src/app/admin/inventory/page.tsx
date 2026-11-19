"use client";

import { useMemo, useState } from "react";
import type { ColumnDef } from "@tanstack/react-table";
import { AlertTriangle, ArrowDownUp, Boxes, Package, PackageX } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { PageHeader } from "@/components/shared/page-header";
import { StatCard } from "@/components/shared/stat-card";
import { DataTable } from "@/components/shared/data-table";
import { SearchInput } from "@/components/shared/search-input";
import { FilterSelect } from "@/components/shared/filter-select";
import { StatusBadge } from "@/components/shared/status-badge";
import { FormDialog } from "@/components/shared/form-dialog";
import { Field } from "@/components/shared/field";
import { useResourceList, useResourceMutations } from "@/hooks/use-resource";
import { useAuthStore } from "@/stores/auth-store";
import { usePermission } from "@/stores/rbac-store";
import { inventoryService, productsService } from "@/services";
import { formatDateTime, formatNumber } from "@/lib/format";
import { uid } from "@/lib/id";
import type { InventoryTx, Product } from "@/types";

export default function InventoryPage() {
  const adminName = useAuthStore((s) => s.session?.name ?? "Admin");
  const products = useResourceList(productsService);
  const txs = useResourceList(inventoryService);
  const { update: updateProduct } = useResourceMutations(productsService, { entity: "Tồn kho", silent: true });
  const { create: createTx } = useResourceMutations(inventoryService, { entity: "Giao dịch kho", silent: true });
  const canEdit = usePermission("products", "edit");

  const [search, setSearch] = useState("");
  const [stockFilter, setStockFilter] = useState("all");
  const [txFilter, setTxFilter] = useState("all");
  const [adjusting, setAdjusting] = useState<Product | null>(null);
  const [txType, setTxType] = useState<InventoryTx["type"]>("in");
  const [qty, setQty] = useState(10);
  const [note, setNote] = useState("");

  const all = products.data ?? [];
  const totalStock = all.reduce((s, p) => s + p.stock, 0);
  const lowStock = all.filter((p) => p.stock > 0 && p.stock <= p.lowStockThreshold).length;
  const outStock = all.filter((p) => p.stock === 0).length;

  const filteredProducts = useMemo(() => {
    const s = search.toLowerCase();
    return all.filter((p) => {
      const matchSearch = !s || p.name.toLowerCase().includes(s) || p.sku.toLowerCase().includes(s);
      const matchLevel =
        stockFilter === "all" ||
        (stockFilter === "low" && p.stock > 0 && p.stock <= p.lowStockThreshold) ||
        (stockFilter === "out" && p.stock === 0);
      return matchSearch && matchLevel;
    });
  }, [all, search, stockFilter]);

  const filteredTxs = useMemo(() => {
    return (txs.data ?? []).filter((t) => txFilter === "all" || t.type === txFilter);
  }, [txs.data, txFilter]);

  const submitAdjustment = (e: React.FormEvent) => {
    e.preventDefault();
    if (!adjusting) return;
    if (qty <= 0) {
      toast.error("Số lượng phải lớn hơn 0");
      return;
    }
    const delta = txType === "in" ? qty : txType === "out" ? -qty : qty - adjusting.stock;
    const nextStock = Math.max(0, txType === "adjust" ? qty : adjusting.stock + delta);

    updateProduct.mutate(
      { id: adjusting.id, patch: { stock: nextStock, updatedAt: new Date().toISOString() }, before: String(adjusting.stock), label: adjusting.name },
      {
        onSuccess: () => {
          createTx.mutate({
            id: uid("inv"),
            productId: adjusting.id,
            productName: adjusting.name,
            type: txType,
            qty: txType === "adjust" ? delta : qty,
            note: note || (txType === "in" ? "Nhập hàng bổ sung" : txType === "out" ? "Xuất kho thủ công" : `Kiểm kê đặt lại thành ${nextStock}`),
            by: adminName,
            at: new Date().toISOString(),
          });
          toast.success(`Đã cập nhật tồn kho ${adjusting.name} thành ${nextStock}`);
          setAdjusting(null);
          setNote("");
        },
      },
    );
  };

  const productCols: ColumnDef<Product, unknown>[] = [
    {
      accessorKey: "name",
      header: "Sản phẩm",
      cell: ({ row }) => (
        <div className="flex items-center gap-3">
          <img src={row.original.image} alt="" className="size-10 rounded-lg object-cover" />
          <div>
            <p className="font-medium">{row.original.name}</p>
            <p className="font-mono text-xs text-muted-foreground">{row.original.sku}</p>
          </div>
        </div>
      ),
    },
    { accessorKey: "category", header: "Danh mục" },
    { accessorKey: "stock", header: "Số lượng tồn", cell: ({ getValue }) => <span className="font-semibold tabular">{formatNumber(getValue() as number)}</span> },
    { accessorKey: "lowStockThreshold", header: "Ngưỡng cảnh báo", cell: ({ getValue }) => <span className="tabular text-muted-foreground">{getValue() as number}</span> },
    {
      id: "level",
      header: "Tình trạng",
      cell: ({ row }) =>
        row.original.stock === 0 ? (
          <StatusBadge status="danger" label="Hết hàng" />
        ) : row.original.stock <= row.original.lowStockThreshold ? (
          <StatusBadge status="pending" label="Sắp hết" />
        ) : (
          <StatusBadge status="approved" label="Đủ hàng" />
        ),
    },
    {
      id: "a",
      header: "",
      enableSorting: false,
      cell: ({ row }) =>
        canEdit ? (
          <div className="text-right">
            <Button
              size="sm"
              variant="outline"
              onClick={() => {
                setAdjusting(row.original);
                setTxType("in");
                setQty(20);
                setNote("");
              }}
            >
              <ArrowDownUp className="size-3.5" /> Cập nhật tồn
            </Button>
          </div>
        ) : null,
    },
  ];

  const txCols: ColumnDef<InventoryTx, unknown>[] = [
    { accessorKey: "at", header: "Thời gian", cell: ({ getValue }) => formatDateTime(getValue() as string) },
    { accessorKey: "productName", header: "Sản phẩm", cell: ({ getValue }) => <span className="font-medium">{getValue() as string}</span> },
    {
      accessorKey: "type",
      header: "Loại giao dịch",
      cell: ({ getValue }) => {
        const t = getValue() as InventoryTx["type"];
        return <StatusBadge status={t === "in" ? "approved" : t === "out" ? "info" : "pending"} label={t === "in" ? "Nhập kho" : t === "out" ? "Xuất kho" : "Kiểm kê"} />;
      },
    },
    {
      accessorKey: "qty",
      header: "Số lượng",
      cell: ({ row }) => (
        <span className={`font-semibold tabular ${row.original.type === "in" ? "text-success" : row.original.type === "out" ? "text-info" : "text-warning"}`}>
          {row.original.type === "in" ? `+${row.original.qty}` : row.original.type === "out" ? `-${row.original.qty}` : row.original.qty}
        </span>
      ),
    },
    { accessorKey: "note", header: "Ghi chú", cell: ({ getValue }) => <span className="text-xs text-muted-foreground">{getValue() as string}</span> },
    { accessorKey: "by", header: "Người thực hiện" },
  ];

  return (
    <>
      <PageHeader title="Quản lý kho hàng" description="Theo dõi mức tồn kho, cảnh báo thiếu hàng và lịch sử nhập – xuất – kiểm kê." />
      <div className="mb-4 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="Tổng sản phẩm" value={formatNumber(all.length)} icon={Package} tone="leaf" />
        <StatCard label="Tổng số lượng tồn" value={formatNumber(totalStock)} icon={Boxes} tone="info" />
        <StatCard label="Sản phẩm sắp hết" value={formatNumber(lowStock)} icon={AlertTriangle} tone="warning" />
        <StatCard label="Sản phẩm hết hàng" value={formatNumber(outStock)} icon={PackageX} tone="danger" />
      </div>

      <Tabs defaultValue="stock">
        <TabsList className="mb-4">
          <TabsTrigger value="stock">Tồn kho hiện tại</TabsTrigger>
          <TabsTrigger value="history">Lịch sử nhập / xuất kho</TabsTrigger>
        </TabsList>
        <TabsContent value="stock">
          <DataTable
            columns={productCols}
            data={filteredProducts}
            loading={products.isLoading}
            toolbar={
              <>
                <SearchInput value={search} onChange={setSearch} placeholder="Tìm theo tên hoặc SKU…" />
                <FilterSelect
                  value={stockFilter}
                  onChange={setStockFilter}
                  allLabel="Mọi mức tồn"
                  options={[
                    { value: "low", label: "Sắp hết hàng" },
                    { value: "out", label: "Hết hàng" },
                  ]}
                />
              </>
            }
          />
        </TabsContent>
        <TabsContent value="history">
          <DataTable
            columns={txCols}
            data={filteredTxs}
            loading={txs.isLoading}
            toolbar={
              <FilterSelect
                value={txFilter}
                onChange={setTxFilter}
                allLabel="Mọi giao dịch"
                options={[
                  { value: "in", label: "Nhập kho" },
                  { value: "out", label: "Xuất kho" },
                  { value: "adjust", label: "Kiểm kê" },
                ]}
              />
            }
          />
        </TabsContent>
      </Tabs>

      <FormDialog
        open={!!adjusting}
        onOpenChange={(o) => !o && setAdjusting(null)}
        title={`Cập nhật tồn kho · ${adjusting?.name ?? ""}`}
        description={adjusting ? `Tồn hiện tại: ${adjusting.stock}` : undefined}
        onSubmit={submitAdjustment}
      >
        <div className="grid gap-4">
          <Field label="Loại thao tác">
            <Select value={txType} onValueChange={(v) => setTxType(v as InventoryTx["type"])}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="in">Nhập kho (+)</SelectItem>
                <SelectItem value="out">Xuất kho (-)</SelectItem>
                <SelectItem value="adjust">Đặt lại tồn thực tế (Kiểm kê)</SelectItem>
              </SelectContent>
            </Select>
          </Field>
          <Field label={txType === "adjust" ? "Số lượng tồn mới" : "Số lượng"}>
            <Input type="number" min={1} value={qty} onChange={(e) => setQty(Number(e.target.value) || 0)} />
          </Field>
          <Field label="Ghi chú">
            <Textarea rows={3} value={note} onChange={(e) => setNote(e.target.value)} placeholder="Lý do nhập/xuất hoặc số lô hàng…" />
          </Field>
        </div>
      </FormDialog>
    </>
  );
}
