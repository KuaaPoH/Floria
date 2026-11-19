"use client";

import { useEffect, useMemo, useState } from "react";
import { useSearchParams } from "next/navigation";
import { Controller, useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import type { ColumnDef } from "@tanstack/react-table";
import { AlertTriangle, Eye, EyeOff, LayoutGrid, List, Package, Pencil, Plus, TicketPercent, Trash2, TrendingUp } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group";
import { PageHeader } from "@/components/shared/page-header";
import { StatCard } from "@/components/shared/stat-card";
import { DataTable } from "@/components/shared/data-table";
import { SearchInput } from "@/components/shared/search-input";
import { FilterSelect } from "@/components/shared/filter-select";
import { StatusBadge } from "@/components/shared/status-badge";
import { FormDialog } from "@/components/shared/form-dialog";
import { ConfirmDialog } from "@/components/shared/confirm-dialog";
import { Field } from "@/components/shared/field";
import { ImageUploader } from "@/components/shared/image-uploader";
import { CardGridSkeleton, EmptyState } from "@/components/shared/states";
import { useResourceList, useResourceMutations } from "@/hooks/use-resource";
import { usePermission } from "@/stores/rbac-store";
import { productsService, vouchersService } from "@/services";
import { formatDate, formatNumber, formatVND } from "@/lib/format";
import { uid } from "@/lib/id";
import { IMAGES } from "@/mocks/images";
import { PRODUCT_CATEGORIES, type Product, type Voucher } from "@/types";

const productSchema = z.object({
  name: z.string().trim().min(2, "Nhập tên sản phẩm"),
  sku: z.string().trim().min(2, "Nhập mã SKU"),
  category: z.string().trim().min(1, "Nhập danh mục"),
  originalPrice: z.coerce.number().min(0),
  price: z.coerce.number().min(1000, "Giá bán tối thiểu 1.000 ₫"),
  stock: z.coerce.number().min(0),
  lowStockThreshold: z.coerce.number().min(1),
  image: z.string(),
  shortDesc: z.string(),
  description: z.string(),
  usageGuide: z.string(),
  indications: z.string(),
  tag: z.string(),
  visible: z.boolean(),
});
type ProductValues = z.infer<typeof productSchema>;

const voucherSchema = z.object({
  code: z.string().trim().min(3, "Nhập mã voucher").toUpperCase(),
  type: z.enum(["percent", "fixed"]),
  value: z.coerce.number().min(1, "Nhập giá trị giảm"),
  minOrder: z.coerce.number().min(0),
  maxUsage: z.coerce.number().min(1),
  expiresAt: z.string().min(1, "Chọn ngày hết hạn"),
  active: z.boolean(),
});
type VoucherValues = z.infer<typeof voucherSchema>;

export default function ProductsPage() {
  const searchParams = useSearchParams();
  const q = searchParams.get("q") ?? "";
  const [tab, setTab] = useState("products");
  const canCreate = usePermission("products", "create");
  const canEdit = usePermission("products", "edit");
  const canDelete = usePermission("products", "delete");

  return (
    <>
      <PageHeader title="Sản phẩm & Voucher" description="Quản lý danh mục sản phẩm làm vườn, giá bán và mã giảm giá trong cửa hàng Floria." />
      <Tabs value={tab} onValueChange={setTab}>
        <TabsList className="mb-5">
          <TabsTrigger value="products">Sản phẩm</TabsTrigger>
          <TabsTrigger value="vouchers">Mã giảm giá (Voucher)</TabsTrigger>
        </TabsList>
        <TabsContent value="products">
          <ProductsTab initialSearch={q} canCreate={canCreate} canEdit={canEdit} canDelete={canDelete} />
        </TabsContent>
        <TabsContent value="vouchers">
          <VouchersTab canCreate={canCreate} canEdit={canEdit} canDelete={canDelete} />
        </TabsContent>
      </Tabs>
    </>
  );
}

function ProductsTab({
  initialSearch,
  canCreate,
  canEdit,
  canDelete,
}: {
  initialSearch: string;
  canCreate: boolean;
  canEdit: boolean;
  canDelete: boolean;
}) {
  const list = useResourceList(productsService);
  const { create, update, remove } = useResourceMutations(productsService, { entity: "Sản phẩm" });
  const [view, setView] = useState<"table" | "grid">("table");
  const [search, setSearch] = useState(initialSearch);
  const [cat, setCat] = useState("all");
  const [vis, setVis] = useState("all");
  const [editing, setEditing] = useState<Product | null | undefined>(undefined);
  const [del, setDel] = useState<Product | null>(null);

  useEffect(() => {
    if (initialSearch) setSearch(initialSearch);
  }, [initialSearch]);

  const rows = useMemo(() => {
    const s = search.toLowerCase();
    return (list.data ?? []).filter(
      (p) =>
        (!s || p.name.toLowerCase().includes(s) || p.sku.toLowerCase().includes(s)) &&
        (cat === "all" || p.category === cat) &&
        (vis === "all" || String(p.visible) === vis),
    );
  }, [list.data, search, cat, vis]);

  const all = list.data ?? [];
  const lowCount = all.filter((p) => p.stock <= p.lowStockThreshold).length;

  const columns: ColumnDef<Product, unknown>[] = [
    {
      accessorKey: "name",
      header: "Sản phẩm",
      cell: ({ row }) => (
        <div className="flex items-center gap-3">
          <img src={row.original.image} alt="" className="size-10 rounded-lg object-cover" loading="lazy" />
          <div>
            <p className="font-medium">{row.original.name}</p>
            <p className="font-mono text-xs text-muted-foreground">{row.original.sku}</p>
          </div>
        </div>
      ),
    },
    { accessorKey: "category", header: "Danh mục" },
    {
      accessorKey: "price",
      header: "Giá bán",
      cell: ({ row }) => (
        <div className="tabular">
          <p className="font-semibold text-foreground">{formatVND(row.original.price)}</p>
          {row.original.originalPrice > row.original.price && <p className="text-xs text-muted-foreground line-through">{formatVND(row.original.originalPrice)}</p>}
        </div>
      ),
    },
    {
      accessorKey: "stock",
      header: "Tồn kho",
      cell: ({ row }) => (
        <span className={`font-medium tabular ${row.original.stock === 0 ? "text-danger" : row.original.stock <= row.original.lowStockThreshold ? "text-warning" : ""}`}>
          {formatNumber(row.original.stock)}
        </span>
      ),
    },
    { accessorKey: "sold", header: "Đã bán", cell: ({ getValue }) => <span className="tabular">{formatNumber(getValue() as number)}</span> },
    {
      accessorKey: "visible",
      header: "Hiển thị",
      cell: ({ row }) => <StatusBadge status={row.original.visible ? "visible" : "hidden"} />,
    },
    {
      id: "a",
      header: "",
      enableSorting: false,
      cell: ({ row }) => (
        <div className="flex justify-end gap-1" onClick={(e) => e.stopPropagation()}>
          {canEdit && (
            <>
              <Button
                size="icon-sm"
                variant="ghost"
                title={row.original.visible ? "Ẩn sản phẩm" : "Hiện sản phẩm"}
                onClick={() => update.mutate({ id: row.original.id, patch: { visible: !row.original.visible }, label: row.original.name })}
              >
                {row.original.visible ? <EyeOff /> : <Eye />}
              </Button>
              <Button size="icon-sm" variant="ghost" onClick={() => setEditing(row.original)} aria-label="Sửa">
                <Pencil />
              </Button>
            </>
          )}
          {canDelete && (
            <Button size="icon-sm" variant="ghost" className="text-danger" onClick={() => setDel(row.original)} aria-label="Xoá">
              <Trash2 />
            </Button>
          )}
        </div>
      ),
    },
  ];

  const toolbar = (
    <>
      <SearchInput value={search} onChange={setSearch} placeholder="Tên sản phẩm hoặc SKU…" />
      <FilterSelect value={cat} onChange={setCat} allLabel="Mọi danh mục" options={PRODUCT_CATEGORIES.map((c) => ({ value: c, label: c }))} />
      <FilterSelect
        value={vis}
        onChange={setVis}
        allLabel="Mọi trạng thái"
        options={[
          { value: "true", label: "Đang hiển thị" },
          { value: "false", label: "Đã ẩn" },
        ]}
      />
      <ToggleGroup type="single" value={view} onValueChange={(v) => v && setView(v as typeof view)} className="ml-auto rounded-lg border bg-card p-1">
        <ToggleGroupItem value="table" className="h-8 w-8 p-0" aria-label="Bảng">
          <List className="size-4" />
        </ToggleGroupItem>
        <ToggleGroupItem value="grid" className="h-8 w-8 p-0" aria-label="Lưới">
          <LayoutGrid className="size-4" />
        </ToggleGroupItem>
      </ToggleGroup>
      {canCreate && (
        <Button onClick={() => setEditing(null)}>
          <Plus /> Thêm sản phẩm
        </Button>
      )}
    </>
  );

  return (
    <>
      <div className="mb-4 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="Tổng sản phẩm" value={formatNumber(all.length)} icon={Package} tone="leaf" />
        <StatCard label="Đang hiển thị" value={formatNumber(all.filter((p) => p.visible).length)} icon={Eye} tone="info" />
        <StatCard label="Sắp hết / hết hàng" value={formatNumber(lowCount)} icon={AlertTriangle} tone="warning" />
        <StatCard label="Tổng lượt bán" value={formatNumber(all.reduce((s, p) => s + p.sold, 0))} icon={TrendingUp} tone="sage" />
      </div>

      {view === "table" ? (
        <DataTable columns={columns} data={rows} loading={list.isLoading} toolbar={toolbar} />
      ) : (
        <>
          <div className="card-surface mb-4 flex flex-col gap-2 p-3 sm:flex-row sm:flex-wrap sm:items-center">{toolbar}</div>
          {list.isLoading ? (
            <CardGridSkeleton />
          ) : rows.length === 0 ? (
            <div className="card-surface">
              <EmptyState title="Không tìm thấy sản phẩm phù hợp" />
            </div>
          ) : (
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
              {rows.map((p) => (
                <div key={p.id} className="card-surface overflow-hidden">
                  <div className="relative aspect-[4/3] bg-surface-2">
                    <img src={p.image} alt={p.name} className="size-full object-cover" loading="lazy" />
                    <span className="absolute right-2 top-2">
                      <StatusBadge status={p.visible ? "visible" : "hidden"} />
                    </span>
                  </div>
                  <div className="p-3.5">
                    <p className="font-mono text-[11px] text-muted-foreground">{p.sku}</p>
                    <p className="mt-0.5 line-clamp-1 font-semibold">{p.name}</p>
                    <div className="mt-2 flex items-baseline justify-between">
                      <span className="font-semibold text-forest tabular">{formatVND(p.price)}</span>
                      <span className="text-xs text-muted-foreground tabular">Tồn: {p.stock}</span>
                    </div>
                  </div>
                  {(canEdit || canDelete) && (
                    <div className="flex items-center justify-between border-t px-3 py-2">
                      <span className="text-xs text-muted-foreground">{p.category}</span>
                      <div className="flex gap-1">
                        {canEdit && (
                          <Button size="icon-sm" variant="ghost" onClick={() => setEditing(p)} aria-label="Sửa">
                            <Pencil />
                          </Button>
                        )}
                        {canDelete && (
                          <Button size="icon-sm" variant="ghost" className="text-danger" onClick={() => setDel(p)} aria-label="Xoá">
                            <Trash2 />
                          </Button>
                        )}
                      </div>
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </>
      )}

      <ProductForm
        open={editing !== undefined}
        onOpenChange={(o) => !o && setEditing(undefined)}
        product={editing}
        pending={create.isPending || update.isPending}
        onSubmit={(p) =>
          editing ? update.mutate({ id: p.id, patch: p, label: p.name }, { onSuccess: () => setEditing(undefined) }) : create.mutate(p, { onSuccess: () => setEditing(undefined) })
        }
      />
      <ConfirmDialog
        open={!!del}
        onOpenChange={(o) => !o && setDel(null)}
        title={`Xoá ${del?.name}?`}
        tone="danger"
        confirmLabel="Xoá"
        description="Sản phẩm sẽ bị xoá khỏi cửa hàng."
        onConfirm={() => del && remove.mutate({ id: del.id, label: del.name })}
      />
    </>
  );
}

function ProductForm({
  open,
  onOpenChange,
  product,
  onSubmit,
  pending,
}: {
  open: boolean;
  onOpenChange: (o: boolean) => void;
  product?: Product | null;
  onSubmit: (p: Product) => void;
  pending: boolean;
}) {
  const form = useForm<ProductValues>({ resolver: zodResolver(productSchema) });
  useEffect(() => {
    if (!open) return;
    form.reset(
      product
        ? {
            name: product.name,
            sku: product.sku,
            category: product.category,
            originalPrice: product.originalPrice,
            price: product.price,
            stock: product.stock,
            lowStockThreshold: product.lowStockThreshold,
            image: product.image,
            shortDesc: product.shortDesc ?? "",
            description: product.description,
            usageGuide: product.usageGuide ?? "",
            indications: (product.indications ?? []).join(", "),
            tag: product.tag ?? "",
            visible: product.visible,
          }
        : {
            name: "",
            sku: `FL-SP-${Math.floor(100 + Math.random() * 900)}`,
            category: "Dụng cụ",
            originalPrice: 100000,
            price: 89000,
            stock: 50,
            lowStockThreshold: 10,
            image: "",
            shortDesc: "",
            description: "",
            usageGuide: "",
            indications: "",
            tag: "",
            visible: true,
          },
    );
  }, [open, product, form]);

  const e = form.formState.errors;
  const submit = form.handleSubmit((v) => {
    const indications = v.indications
      .split(",")
      .map((s) => s.trim())
      .filter(Boolean);
    onSubmit({
      id: product?.id ?? uid("prd"),
      name: v.name,
      sku: v.sku,
      category: v.category,
      originalPrice: v.originalPrice,
      price: v.price,
      stock: v.stock,
      lowStockThreshold: v.lowStockThreshold,
      image: v.image || IMAGES.fertilizer,
      shortDesc: v.shortDesc,
      description: v.description,
      usageGuide: v.usageGuide,
      indications,
      tag: v.tag,
      visible: v.visible,
      sold: product?.sold ?? 0,
      rating: product?.rating ?? 5,
      updatedAt: new Date().toISOString(),
    });
  });

  return (
    <FormDialog open={open} onOpenChange={onOpenChange} title={product ? `Sửa · ${product.name}` : "Thêm sản phẩm"} onSubmit={submit} pending={pending} className="sm:max-w-3xl">
      <div className="grid gap-5 md:grid-cols-[200px_1fr]">
        <Controller control={form.control} name="image" render={({ field }) => <Field label="Ảnh sản phẩm"><ImageUploader value={field.value} onChange={field.onChange} /></Field>} />
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Tên sản phẩm" error={e.name?.message} className="sm:col-span-2">
            <Input {...form.register("name")} />
          </Field>
          <Field label="SKU" error={e.sku?.message}>
            <Input {...form.register("sku")} />
          </Field>
          <Field label="Danh mục" error={e.category?.message}>
            <Input placeholder="VD: Dụng cụ, Phân bón & Dưỡng, Giá thể & Đất..." {...form.register("category")} />
          </Field>
          <Field label="Giá gốc (₫)" error={e.originalPrice?.message}>
            <Input type="number" {...form.register("originalPrice")} />
          </Field>
          <Field label="Giá bán (₫)" error={e.price?.message}>
            <Input type="number" {...form.register("price")} />
          </Field>
          <Field label="Số lượng tồn" error={e.stock?.message}>
            <Input type="number" {...form.register("stock")} />
          </Field>
          <Field label="Ngưỡng cảnh báo tồn" error={e.lowStockThreshold?.message}>
            <Input type="number" {...form.register("lowStockThreshold")} />
          </Field>
          <Field label="Nhãn nổi bật (tag)">
            <Input placeholder="VD: Hot, Bán chạy..." {...form.register("tag")} />
          </Field>
          <Field label="Công dụng / Chỉ định (indications)">
            <Input placeholder="Phun thuốc trị bệnh, Tưới ẩm lá..." {...form.register("indications")} />
          </Field>
          <Field label="Mô tả ngắn (shortDesc)" className="sm:col-span-2">
            <Input placeholder="Tóm tắt 1 dòng hiển thị ở thẻ sản phẩm..." {...form.register("shortDesc")} />
          </Field>
          <Field label="Mô tả chi tiết (description)" className="sm:col-span-2">
            <Textarea rows={2} {...form.register("description")} />
          </Field>
          <Field label="Hướng dẫn sử dụng (usageGuide)" className="sm:col-span-2">
            <Textarea rows={2} {...form.register("usageGuide")} />
          </Field>
          <Controller
            control={form.control}
            name="visible"
            render={({ field }) => (
              <div className="flex items-center gap-3 sm:col-span-2">
                <Switch checked={field.value} onCheckedChange={field.onChange} />
                <span className="text-sm font-medium">Hiển thị trên cửa hàng</span>
              </div>
            )}
          />
        </div>
      </div>
    </FormDialog>
  );
}

function VouchersTab({ canCreate, canEdit, canDelete }: { canCreate: boolean; canEdit: boolean; canDelete: boolean }) {
  const list = useResourceList(vouchersService);
  const { create, update, remove } = useResourceMutations(vouchersService, { entity: "Voucher" });
  const [editing, setEditing] = useState<Voucher | null | undefined>(undefined);
  const [del, setDel] = useState<Voucher | null>(null);

  const form = useForm<VoucherValues>({ resolver: zodResolver(voucherSchema) });
  useEffect(() => {
    if (editing === undefined) return;
    if (editing) {
      form.reset({
        ...editing,
        expiresAt: editing.expiresAt.slice(0, 10),
      });
    } else {
      form.reset({
        code: "",
        type: "percent",
        value: 10,
        minOrder: 200000,
        maxUsage: 200,
        expiresAt: new Date(Date.now() + 1000 * 60 * 60 * 24 * 30).toISOString().slice(0, 10),
        active: true,
      });
    }
  }, [editing, form]);

  const submitVoucher = form.handleSubmit((v) => {
    const payload: Voucher = {
      id: editing?.id ?? uid("vch"),
      code: v.code.toUpperCase(),
      type: v.type,
      value: v.value,
      minOrder: v.minOrder,
      maxUsage: v.maxUsage,
      used: editing?.used ?? 0,
      expiresAt: new Date(v.expiresAt.includes("T") ? v.expiresAt : `${v.expiresAt}T23:59:59`).toISOString(),
      active: v.active,
    };
    if (editing) update.mutate({ id: payload.id, patch: payload, label: payload.code }, { onSuccess: () => setEditing(undefined) });
    else create.mutate(payload, { onSuccess: () => setEditing(undefined) });
  });

  const columns: ColumnDef<Voucher, unknown>[] = [
    {
      accessorKey: "code",
      header: "Mã Voucher",
      cell: ({ getValue }) => (
        <span className="inline-flex items-center gap-1.5 rounded-md bg-accent px-2 py-0.5 font-mono text-xs font-semibold text-forest">
          <TicketPercent className="size-3.5" />
          {getValue() as string}
        </span>
      ),
    },
    {
      accessorKey: "value",
      header: "Mức giảm",
      cell: ({ row }) => <span className="font-semibold tabular">{row.original.type === "percent" ? `${row.original.value}%` : formatVND(row.original.value)}</span>,
    },
    { accessorKey: "minOrder", header: "Đơn tối thiểu", cell: ({ getValue }) => <span className="tabular">{formatVND(getValue() as number)}</span> },
    {
      id: "usage",
      header: "Lượt dùng",
      cell: ({ row }) => (
        <span className="tabular">
          {row.original.used} / {row.original.maxUsage}
        </span>
      ),
    },
    { accessorKey: "expiresAt", header: "Hết hạn", cell: ({ getValue }) => <span className="tabular">{formatDate(getValue() as string)}</span> },
    {
      accessorKey: "active",
      header: "Trạng thái",
      cell: ({ row }) => <StatusBadge status={row.original.active ? "active" : "inactive"} />,
    },
    {
      id: "a",
      header: "",
      enableSorting: false,
      cell: ({ row }) => (
        <div className="flex justify-end gap-1">
          {canEdit && (
            <>
              <Switch
                checked={row.original.active}
                onCheckedChange={(active) => update.mutate({ id: row.original.id, patch: { active }, label: row.original.code })}
              />
              <Button size="icon-sm" variant="ghost" onClick={() => setEditing(row.original)} aria-label="Sửa">
                <Pencil />
              </Button>
            </>
          )}
          {canDelete && (
            <Button size="icon-sm" variant="ghost" className="text-danger" onClick={() => setDel(row.original)} aria-label="Xoá">
              <Trash2 />
            </Button>
          )}
        </div>
      ),
    },
  ];

  const e = form.formState.errors;

  return (
    <>
      <DataTable
        columns={columns}
        data={list.data ?? []}
        loading={list.isLoading}
        toolbar={
          canCreate ? (
            <div className="flex w-full justify-end">
              <Button onClick={() => setEditing(null)}>
                <Plus /> Tạo voucher mới
              </Button>
            </div>
          ) : undefined
        }
      />

      <FormDialog open={editing !== undefined} onOpenChange={(o) => !o && setEditing(undefined)} title={editing ? `Sửa · ${editing.code}` : "Tạo mã giảm giá"} onSubmit={submitVoucher}>
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Mã code" error={e.code?.message}>
            <Input className="font-mono uppercase" {...form.register("code")} />
          </Field>
          <Controller
            control={form.control}
            name="type"
            render={({ field }) => (
              <Field label="Loại giảm giá">
                <Select value={field.value} onValueChange={field.onChange}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="percent">Theo phần trăm (%)</SelectItem>
                    <SelectItem value="fixed">Số tiền cố định (₫)</SelectItem>
                  </SelectContent>
                </Select>
              </Field>
            )}
          />
          <Field label="Giá trị giảm" error={e.value?.message}>
            <Input type="number" {...form.register("value")} />
          </Field>
          <Field label="Đơn tối thiểu (₫)" error={e.minOrder?.message}>
            <Input type="number" {...form.register("minOrder")} />
          </Field>
          <Field label="Lượt dùng tối đa" error={e.maxUsage?.message}>
            <Input type="number" {...form.register("maxUsage")} />
          </Field>
          <Field label="Ngày hết hạn" error={e.expiresAt?.message}>
            <Input type="date" {...form.register("expiresAt")} />
          </Field>
        </div>
      </FormDialog>

      <ConfirmDialog
        open={!!del}
        onOpenChange={(o) => !o && setDel(null)}
        title={`Xoá voucher ${del?.code}?`}
        tone="danger"
        confirmLabel="Xoá"
        onConfirm={() => del && remove.mutate({ id: del.id, label: del.code })}
      />
    </>
  );
}
