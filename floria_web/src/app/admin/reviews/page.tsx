"use client";

import { useMemo, useState } from "react";
import type { ColumnDef } from "@tanstack/react-table";
import { Check, EyeOff, MessageSquareReply, Star, XCircle } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { PageHeader } from "@/components/shared/page-header";
import { StatCard } from "@/components/shared/stat-card";
import { DataTable } from "@/components/shared/data-table";
import { SearchInput } from "@/components/shared/search-input";
import { FilterSelect } from "@/components/shared/filter-select";
import { SmartImage } from "@/components/shared/smart-image";
import { StatusBadge, statusLabel } from "@/components/shared/status-badge";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { FormDialog } from "@/components/shared/form-dialog";
import { Field } from "@/components/shared/field";
import { useResourceList, useResourceMutations } from "@/hooks/use-resource";
import { usePermission } from "@/stores/rbac-store";
import { reviewsService } from "@/services";
import { formatDateTime } from "@/lib/format";
import type { ProductReview } from "@/types";

export default function ReviewsPage() {
  const list = useResourceList(reviewsService);
  const { update } = useResourceMutations(reviewsService, { entity: "Đánh giá" });
  const canApprove = usePermission("reviews", "approve");
  const canEdit = usePermission("reviews", "edit");

  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("all");
  const [rating, setRating] = useState("all");
  const [replyTarget, setReplyTarget] = useState<ProductReview | null>(null);
  const [replyText, setReplyText] = useState("");
  const [previewImg, setPreviewImg] = useState<string | null>(null);

  const all = list.data ?? [];
  const avg = all.length ? (all.reduce((s, r) => s + r.rating, 0) / all.length).toFixed(1).replace(".", ",") : "0";

  const rows = useMemo(() => {
    const s = search.toLowerCase();
    return all.filter(
      (r) =>
        (!s || r.productName.toLowerCase().includes(s) || r.customer.toLowerCase().includes(s) || r.content.toLowerCase().includes(s)) &&
        (status === "all" || r.status === status) &&
        (rating === "all" || String(r.rating) === rating),
    );
  }, [all, search, status, rating]);

  const setReviewStatus = (r: ProductReview, next: ProductReview["status"]) => {
    update.mutate({ id: r.id, patch: { status: next }, before: r.status, label: `${r.customer} · ${r.productName}` });
  };

  const submitReply = (e: React.FormEvent) => {
    e.preventDefault();
    if (!replyTarget || !replyText.trim()) {
      toast.error("Vui lòng nhập nội dung phản hồi");
      return;
    }
    update.mutate(
      { id: replyTarget.id, patch: { reply: replyText.trim(), status: "approved" }, label: replyTarget.customer },
      { onSuccess: () => setReplyTarget(null) },
    );
  };

  const columns: ColumnDef<ProductReview, unknown>[] = [
    {
      accessorKey: "productName",
      header: "Sản phẩm",
      cell: ({ row }) => (
        <div>
          <p className="font-medium">{row.original.productName}</p>
          <p className="text-xs text-muted-foreground">Khách: {row.original.customer}</p>
        </div>
      ),
    },
    {
      accessorKey: "rating",
      header: "Số sao",
      cell: ({ getValue }) => {
        const val = getValue() as number;
        return (
          <div className="flex items-center gap-1 text-warning">
            <Star className="size-3.5 fill-current" />
            <span className="font-semibold text-foreground tabular">{val}</span>
          </div>
        );
      },
    },
    {
      accessorKey: "content",
      header: "Nội dung đánh giá",
      cell: ({ row }) => (
        <div className="max-w-md space-y-1.5">
          <p className="text-sm">{row.original.content}</p>
          {row.original.images && row.original.images.length > 0 && (
            <div className="flex flex-wrap gap-1.5">
              {row.original.images.map((src, idx) => (
                <button
                  key={`${src}_${idx}`}
                  type="button"
                  onClick={() => setPreviewImg(src)}
                  className="cursor-zoom-in overflow-hidden rounded-md border transition hover:opacity-90"
                  title="Bấm để xem ảnh lớn"
                >
                  <SmartImage
                    src={src}
                    alt={`Ảnh đánh giá ${idx + 1}`}
                    className="size-10"
                    fallback={<span className="grid size-10 place-items-center bg-muted text-[10px]">Ảnh</span>}
                  />
                </button>
              ))}
            </div>
          )}
          {row.original.reply && <p className="rounded-md bg-surface-2 px-2 py-1 text-xs text-forest">Floria phản hồi: {row.original.reply}</p>}
        </div>
      ),
    },
    { accessorKey: "createdAt", header: "Ngày gửi", cell: ({ getValue }) => formatDateTime(getValue() as string) },
    { accessorKey: "status", header: "Kiểm duyệt", cell: ({ getValue }) => <StatusBadge status={getValue() as string} /> },
    {
      id: "a",
      header: "",
      enableSorting: false,
      cell: ({ row }) => (
        <div className="flex justify-end gap-1">
          {canApprove && row.original.status !== "approved" && (
            <Button size="icon-sm" variant="ghost" className="text-success" title="Duyệt" onClick={() => setReviewStatus(row.original, "approved")}>
              <Check />
            </Button>
          )}
          {canApprove && row.original.status !== "hidden" && (
            <Button size="icon-sm" variant="ghost" title="Ẩn" onClick={() => setReviewStatus(row.original, "hidden")}>
              <EyeOff />
            </Button>
          )}
          {canApprove && row.original.status !== "rejected" && (
            <Button size="icon-sm" variant="ghost" className="text-danger" title="Từ chối" onClick={() => setReviewStatus(row.original, "rejected")}>
              <XCircle />
            </Button>
          )}
          {canEdit && (
            <Button
              size="icon-sm"
              variant="ghost"
              title="Phản hồi"
              onClick={() => {
                setReplyTarget(row.original);
                setReplyText(row.original.reply ?? "");
              }}
            >
              <MessageSquareReply />
            </Button>
          )}
        </div>
      ),
    },
  ];

  return (
    <>
      <PageHeader title="Quản lý đánh giá" description="Kiểm duyệt đánh giá sản phẩm và phản hồi khách hàng với tư cách Floria." />
      <div className="mb-4 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="Tổng đánh giá" value={String(all.length)} icon={MessageSquareReply} tone="leaf" />
        <StatCard label="Chờ duyệt" value={String(all.filter((r) => r.status === "pending").length)} icon={EyeOff} tone="warning" />
        <StatCard label="Điểm trung bình" value={`${avg} ★`} icon={Star} tone="sage" />
        <StatCard label="Đã phản hồi" value={String(all.filter((r) => !!r.reply).length)} icon={Check} tone="info" />
      </div>

      <DataTable
        columns={columns}
        data={rows}
        loading={list.isLoading}
        toolbar={
          <>
            <SearchInput value={search} onChange={setSearch} placeholder="Tìm sản phẩm, khách hàng, nội dung…" />
            <FilterSelect
              value={status}
              onChange={setStatus}
              allLabel="Mọi trạng thái"
              options={["pending", "approved", "hidden", "rejected"].map((v) => ({ value: v, label: statusLabel(v) }))}
            />
            <FilterSelect
              value={rating}
              onChange={setRating}
              allLabel="Mọi số sao"
              options={[5, 4, 3, 2, 1].map((n) => ({ value: String(n), label: `${n} sao` }))}
            />
          </>
        }
      />

      <FormDialog
        open={!!replyTarget}
        onOpenChange={(o) => !o && setReplyTarget(null)}
        title={`Phản hồi · ${replyTarget?.customer ?? ""}`}
        description={replyTarget?.content}
        submitLabel="Gửi phản hồi"
        onSubmit={submitReply}
      >
        <Field label="Nội dung trả lời (hiển thị dưới tên Floria)">
          <Textarea rows={4} value={replyText} onChange={(e) => setReplyText(e.target.value)} placeholder="Cảm ơn bạn đã tin dùng sản phẩm của Floria…" />
        </Field>
      </FormDialog>
      <Dialog open={!!previewImg} onOpenChange={(o) => !o && setPreviewImg(null)}>
        <DialogContent className="max-w-lg p-4">
          <DialogHeader>
            <DialogTitle>Ảnh đánh giá từ khách hàng</DialogTitle>
          </DialogHeader>
          {previewImg && (
            <img
              src={previewImg}
              alt="Ảnh đánh giá"
              referrerPolicy="no-referrer"
              className="max-h-[70vh] w-full rounded-xl object-contain bg-muted"
            />
          )}
        </DialogContent>
      </Dialog>
    </>
  );
}
