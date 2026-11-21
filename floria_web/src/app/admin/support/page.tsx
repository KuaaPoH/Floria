"use client";

import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import type { ColumnDef } from "@tanstack/react-table";
import { Eye, EyeOff, FileQuestion, HelpCircle, Pencil, Plus, Trash2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { PageHeader } from "@/components/shared/page-header";
import { StatCard } from "@/components/shared/stat-card";
import { DataTable } from "@/components/shared/data-table";
import { SearchInput } from "@/components/shared/search-input";
import { FilterSelect } from "@/components/shared/filter-select";
import { Field } from "@/components/shared/field";
import { FormDialog } from "@/components/shared/form-dialog";
import { ConfirmDialog } from "@/components/shared/confirm-dialog";
import { usePermission } from "@/stores/rbac-store";
import { apiRequest } from "@/lib/api-client";
import { formatDateTime } from "@/lib/format";
import type { SupportArticle } from "@/app/api/admin/support/route";

const SUPPORT_CATEGORIES = [
  { value: "scan", vi: "Quét ảnh & Chẩn đoán AI", en: "Photo Scan & AI Diagnosis" },
  { value: "care", vi: "Lịch chăm sóc & Nhắc nhở", en: "Care Schedule & Reminders" },
  { value: "account", vi: "Tài khoản & Mua sắm", en: "Account & Shopping" },
  { value: "other", vi: "Hỗ trợ chung", en: "General Support" },
] as const;

interface ArticleFormState {
  id?: string;
  category: string;
  questionVi: string;
  questionEn: string;
  answerVi: string;
  answerEn: string;
  order: number;
  visible: boolean;
}

const EMPTY_FORM: ArticleFormState = {
  category: "scan",
  questionVi: "",
  questionEn: "",
  answerVi: "",
  answerEn: "",
  order: 1,
  visible: true,
};

export default function SupportPage() {
  const qc = useQueryClient();
  const canCreate = usePermission("support", "create");
  const canEdit = usePermission("support", "edit");
  const canDelete = usePermission("support", "delete");

  const [search, setSearch] = useState("");
  const [catFilter, setCatFilter] = useState("all");
  const [formOpen, setFormOpen] = useState(false);
  const [form, setForm] = useState<ArticleFormState>(EMPTY_FORM);
  const [deleteTarget, setDeleteTarget] = useState<SupportArticle | null>(null);

  const list = useQuery({
    queryKey: ["support-articles"],
    queryFn: () => apiRequest<SupportArticle[]>("/support"),
  });

  const saveMutation = useMutation({
    mutationFn: async (data: ArticleFormState) => {
      const catMeta = SUPPORT_CATEGORIES.find((c) => c.value === data.category) ?? SUPPORT_CATEGORIES[3];
      const payload = {
        category: catMeta.value,
        categoryVi: catMeta.vi,
        categoryEn: catMeta.en,
        questionVi: data.questionVi.trim(),
        questionEn: data.questionEn.trim(),
        answerVi: data.answerVi.trim(),
        answerEn: data.answerEn.trim(),
        order: Number(data.order) || 1,
        visible: data.visible,
      };
      if (data.id) {
        return apiRequest<SupportArticle>(`/support/${encodeURIComponent(data.id)}`, {
          method: "PATCH",
          body: JSON.stringify(payload),
        });
      }
      return apiRequest<SupportArticle>("/support", {
        method: "POST",
        body: JSON.stringify(payload),
      });
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["support-articles"] });
      toast.success(form.id ? "Đã cập nhật bài viết hỗ trợ" : "Đã thêm bài viết hỗ trợ mới");
      setFormOpen(false);
    },
    onError: (err) => {
      toast.error(err instanceof Error ? err.message : "Không thể lưu bài viết");
    },
  });

  const toggleVisibleMutation = useMutation({
    mutationFn: ({ id, visible }: { id: string; visible: boolean }) =>
      apiRequest<SupportArticle>(`/support/${encodeURIComponent(id)}`, {
        method: "PATCH",
        body: JSON.stringify({ visible }),
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["support-articles"] });
    },
    onError: (err) => {
      toast.error(err instanceof Error ? err.message : "Không thể đổi trạng thái hiển thị");
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) =>
      apiRequest<{ ok: boolean }>(`/support/${encodeURIComponent(id)}`, { method: "DELETE" }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["support-articles"] });
      toast.success("Đã xóa bài viết hỗ trợ");
      setDeleteTarget(null);
    },
    onError: (err) => {
      toast.error(err instanceof Error ? err.message : "Không thể xóa bài viết");
    },
  });

  const all = list.data ?? [];
  const visibleCount = all.filter((a) => a.visible).length;

  const rows = useMemo(() => {
    const s = search.trim().toLowerCase();
    return all.filter(
      (a) =>
        (!s ||
          a.questionVi.toLowerCase().includes(s) ||
          a.questionEn.toLowerCase().includes(s) ||
          a.answerVi.toLowerCase().includes(s)) &&
        (catFilter === "all" || a.category === catFilter),
    );
  }, [all, search, catFilter]);

  const openCreate = () => {
    const maxOrder = all.reduce((m, item) => Math.max(m, item.order || 0), 0);
    setForm({ ...EMPTY_FORM, order: maxOrder + 1 });
    setFormOpen(true);
  };

  const openEdit = (item: SupportArticle) => {
    setForm({
      id: item.id,
      category: item.category,
      questionVi: item.questionVi,
      questionEn: item.questionEn,
      answerVi: item.answerVi,
      answerEn: item.answerEn,
      order: item.order,
      visible: item.visible,
    });
    setFormOpen(true);
  };

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.questionVi.trim() || !form.answerVi.trim()) {
      toast.error("Vui lòng nhập đầy đủ câu hỏi và nội dung trả lời (Tiếng Việt)");
      return;
    }
    saveMutation.mutate(form);
  };

  const columns: ColumnDef<SupportArticle, unknown>[] = [
    {
      accessorKey: "order",
      header: "Thứ tự",
      cell: ({ getValue }) => <span className="font-mono text-xs text-muted-foreground">#{getValue() as number}</span>,
    },
    {
      accessorKey: "questionVi",
      header: "Bài viết / Câu hỏi",
      cell: ({ row }) => (
        <div className="max-w-md">
          <p className="font-medium text-foreground">{row.original.questionVi}</p>
          <p className="line-clamp-2 text-xs text-muted-foreground">{row.original.answerVi}</p>
        </div>
      ),
    },
    {
      accessorKey: "categoryVi",
      header: "Nhóm danh mục",
      cell: ({ getValue }) => <span className="text-xs font-medium">{getValue() as string}</span>,
    },
    {
      accessorKey: "visible",
      header: "Hiển thị",
      cell: ({ row }) => (
        <span
          className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-medium ${
            row.original.visible ? "bg-success-soft text-success" : "bg-muted text-muted-foreground"
          }`}
        >
          {row.original.visible ? <Eye className="size-3" /> : <EyeOff className="size-3" />}
          {row.original.visible ? "Đang hiện" : "Đang ẩn"}
        </span>
      ),
    },
    {
      accessorKey: "updatedAt",
      header: "Cập nhật",
      cell: ({ getValue }) => <span className="text-xs text-muted-foreground">{formatDateTime(getValue() as string)}</span>,
    },
    {
      id: "actions",
      header: "",
      cell: ({ row }) => (
        <div className="flex items-center justify-end gap-1" onClick={(e) => e.stopPropagation()}>
          {canEdit && (
            <>
              <Button
                type="button"
                size="icon"
                variant="ghost"
                title={row.original.visible ? "Ẩn khỏi app" : "Hiện trên app"}
                onClick={() => toggleVisibleMutation.mutate({ id: row.original.id, visible: !row.original.visible })}
              >
                {row.original.visible ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
              </Button>
              <Button type="button" size="icon" variant="ghost" title="Chỉnh sửa" onClick={() => openEdit(row.original)}>
                <Pencil className="size-4" />
              </Button>
            </>
          )}
          {canDelete && (
            <Button
              type="button"
              size="icon"
              variant="ghost"
              className="text-danger hover:text-danger"
              title="Xóa bài viết"
              onClick={() => setDeleteTarget(row.original)}
            >
              <Trash2 className="size-4" />
            </Button>
          )}
        </div>
      ),
    },
  ];

  return (
    <>
      <PageHeader
        title="Trung tâm hỗ trợ"
        description="Quản lý danh sách bài viết & câu hỏi thường gặp hiển thị trong mục Trung tâm hỗ trợ trên ứng dụng Floria."
        actions={
          canCreate && (
            <Button type="button" onClick={openCreate}>
              <Plus /> Thêm bài viết
            </Button>
          )
        }
      />

      <div className="mb-4 grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        <StatCard label="Tổng bài viết" value={String(all.length)} icon={HelpCircle} tone="leaf" />
        <StatCard label="Đang hiển thị trên app" value={String(visibleCount)} icon={Eye} tone="sage" />
        <StatCard label="Đang ẩn" value={String(all.length - visibleCount)} icon={FileQuestion} tone="warning" />
      </div>

      <DataTable
        columns={columns}
        data={rows}
        loading={list.isLoading}
        onRowClick={(item) => canEdit && openEdit(item)}
        toolbar={
          <>
            <SearchInput value={search} onChange={setSearch} placeholder="Tìm theo tiêu đề câu hỏi, nội dung…" />
            <FilterSelect
              value={catFilter}
              onChange={setCatFilter}
              allLabel="Mọi danh mục"
              options={SUPPORT_CATEGORIES.map((c) => ({ value: c.value, label: c.vi }))}
            />
          </>
        }
      />

      <FormDialog
        open={formOpen}
        onOpenChange={setFormOpen}
        title={form.id ? "Chỉnh sửa bài viết hỗ trợ" : "Thêm bài viết hỗ trợ mới"}
        description="Nội dung này sẽ được đồng bộ trực tiếp tới màn hình Trung tâm hỗ trợ của ứng dụng Floria."
        onSubmit={handleSave}
        submitLabel={form.id ? "Lưu thay đổi" : "Thêm bài viết"}
        pending={saveMutation.isPending}
        className="sm:max-w-2xl"
      >
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Nhóm danh mục">
            <Select value={form.category} onValueChange={(v) => setForm((prev) => ({ ...prev, category: v }))}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {SUPPORT_CATEGORIES.map((c) => (
                  <SelectItem key={c.value} value={c.value}>
                    {c.vi}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </Field>

          <Field label="Thứ tự hiển thị">
            <Input
              type="number"
              min={1}
              value={form.order}
              onChange={(e) => setForm((prev) => ({ ...prev, order: Number(e.target.value) || 1 }))}
            />
          </Field>

          <Field label="Câu hỏi / Tiêu đề (Tiếng Việt) *" className="sm:col-span-2">
            <Input
              value={form.questionVi}
              onChange={(e) => setForm((prev) => ({ ...prev, questionVi: e.target.value }))}
              placeholder="VD: Làm sao để chụp ảnh lá cho kết quả chính xác nhất?"
            />
          </Field>

          <Field label="Nội dung trả lời (Tiếng Việt) *" className="sm:col-span-2">
            <Textarea
              rows={4}
              value={form.answerVi}
              onChange={(e) => setForm((prev) => ({ ...prev, answerVi: e.target.value }))}
              placeholder="Nhập hướng dẫn chi tiết cho người dùng…"
            />
          </Field>

          <Field label="Câu hỏi (Tiếng Anh - tuỳ chọn)" className="sm:col-span-2">
            <Input
              value={form.questionEn}
              onChange={(e) => setForm((prev) => ({ ...prev, questionEn: e.target.value }))}
              placeholder="Để trống sẽ tự dùng tiêu đề Tiếng Việt"
            />
          </Field>

          <Field label="Nội dung trả lời (Tiếng Anh - tuỳ chọn)" className="sm:col-span-2">
            <Textarea
              rows={3}
              value={form.answerEn}
              onChange={(e) => setForm((prev) => ({ ...prev, answerEn: e.target.value }))}
              placeholder="Để trống sẽ tự dùng nội dung Tiếng Việt"
            />
          </Field>

          <div className="flex items-center justify-between rounded-xl border p-3 sm:col-span-2">
            <div>
              <p className="text-sm font-medium">Hiển thị trên ứng dụng</p>
              <p className="text-xs text-muted-foreground">Bật để người dùng thấy bài viết này trong Trung tâm hỗ trợ.</p>
            </div>
            <Switch checked={form.visible} onCheckedChange={(checked) => setForm((prev) => ({ ...prev, visible: checked }))} />
          </div>
        </div>
      </FormDialog>

      <ConfirmDialog
        open={!!deleteTarget}
        onOpenChange={(o) => !o && setDeleteTarget(null)}
        title="Xóa bài viết hỗ trợ?"
        description={`Bài viết "${deleteTarget?.questionVi ?? ""}" sẽ bị xóa khỏi CSDL Firestore và không còn hiển thị trên app.`}
        confirmLabel="Xóa"
        tone="danger"
        onConfirm={() => deleteTarget && deleteMutation.mutate(deleteTarget.id)}
      />
    </>
  );
}
