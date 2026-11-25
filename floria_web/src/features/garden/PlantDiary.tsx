"use client";

import { useRef, useState } from "react";
import { ImagePlus, Loader2, MoreHorizontal, Pencil, Stethoscope, Trash2, X } from "lucide-react";
import { toast } from "sonner";
import { ConfirmDialog } from "@/components/layout/ConfirmDialog";
import { EmptyState } from "@/components/layout/states";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { Textarea } from "@/components/ui/textarea";
import { useDiary, useDiaryMutations } from "@/hooks/queries";
import { useLang } from "@/i18n";
import { formatDateTime } from "@/lib/format";
import { cn } from "@/lib/utils";
import { uploadService } from "@/services/upload.service";
import type { DiaryCategory, DiaryNote } from "@/types/user";

const CATEGORY: Record<DiaryCategory, { label: string; variant: "info" | "danger" | "success" | "warning" }> = {
  general: { label: "Ghi chú", variant: "info" },
  health: { label: "Sức khỏe", variant: "danger" },
  growth: { label: "Phát triển", variant: "success" },
  care: { label: "Chăm sóc", variant: "warning" },
};

function Composer({ initial, onSubmit, onCancel, pending }: { initial?: DiaryNote; onSubmit: (v: { title: string; content: string; images: string[]; category: DiaryCategory }) => Promise<void>; onCancel?: () => void; pending: boolean }) {
  const [title, setTitle] = useState(initial?.title ?? "");
  const [content, setContent] = useState(initial?.content ?? "");
  const [images, setImages] = useState<string[]>(initial?.images ?? []);
  const [category, setCategory] = useState<DiaryCategory>(initial?.category ?? "general");
  const [uploading, setUploading] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);
  return (
    <div className="rounded-3xl border bg-card p-4 shadow-soft">
      <Input
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        maxLength={100}
        placeholder="Tiêu đề (VD: Ra lá mới, Thay chậu, Cắt tỉa…)"
        className="mb-2 border-0 bg-transparent px-1 font-semibold shadow-none focus-visible:ring-0"
      />
      <Textarea value={content} onChange={(e) => setContent(e.target.value)} rows={3} maxLength={1000} placeholder="Hôm nay cây của bạn thế nào? Lá mới, hoa nở, hay dấu hiệu bất thường…" className="border-0 bg-transparent p-1 shadow-none focus-visible:ring-0" />
      {images.length > 0 && (
        <div className="mt-2 flex flex-wrap gap-2">
          {images.map((src, i) => (
            <div key={i} className="relative">
              <img src={src} alt="" className="size-20 rounded-xl object-cover" />
              <button onClick={() => setImages(images.filter((_, j) => j !== i))} className="absolute -right-1.5 -top-1.5 grid size-5 place-items-center rounded-full bg-forest text-forest-foreground" aria-label="Bỏ ảnh"><X className="size-3" /></button>
            </div>
          ))}
        </div>
      )}
      <div className="mt-3 flex flex-wrap items-center justify-between gap-2 border-t pt-3">
        <div className="flex items-center gap-2">
          <input ref={fileRef} type="file" accept="image/*" multiple className="hidden" onChange={async (e) => {
            const files = Array.from(e.target.files ?? []).slice(0, 6 - images.length);
            if (!files.length) return;
            setUploading(true);
            try {
              setImages([...images, ...(await uploadService.uploadMany(files, "diary"))]);
            } catch {
              toast.error("Tải ảnh thất bại");
            } finally {
              setUploading(false);
              e.target.value = "";
            }
          }} />
          <Button variant="ghost" size="sm" onClick={() => fileRef.current?.click()} disabled={uploading || images.length >= 6}>{uploading ? <Loader2 className="animate-spin" /> : <ImagePlus />} Ảnh ({images.length}/6)</Button>
          <Select value={category} onValueChange={(v) => setCategory(v as DiaryCategory)}>
            <SelectTrigger className="h-8 w-32 rounded-[9px] text-xs"><SelectValue /></SelectTrigger>
            <SelectContent>{(Object.keys(CATEGORY) as DiaryCategory[]).map((k) => <SelectItem key={k} value={k}>{CATEGORY[k].label}</SelectItem>)}</SelectContent>
          </Select>
        </div>
        <div className="flex gap-2">
          {onCancel && <Button variant="ghost" size="sm" onClick={onCancel}>Hủy</Button>}
          <Button size="sm" disabled={!content.trim() || pending || uploading} onClick={async () => {
            await onSubmit({ title: title.trim(), content: content.trim(), images, category });
            if (!initial) { setTitle(""); setContent(""); setImages([]); setCategory("general"); }
          }}>{pending && <Loader2 className="animate-spin" />}{initial ? "Lưu thay đổi" : "Ghi nhật ký"}</Button>
        </div>
      </div>
    </div>
  );
}

export function PlantDiary({ plantId }: { plantId: string }) {
  const lang = useLang();
  const { data, isLoading } = useDiary(plantId);
  const { create, update, remove } = useDiaryMutations();
  const [editing, setEditing] = useState<string | null>(null);
  const [deleting, setDeleting] = useState<DiaryNote | null>(null);
  return (
    <div className="space-y-5">
      <Composer pending={create.isPending} onSubmit={async (v) => { await create.mutateAsync({ plantId, ...v }); toast.success("Đã lưu nhật ký"); }} />
      {isLoading ? (
        <Skeleton className="h-32 rounded-3xl" />
      ) : !data?.length ? (
        <EmptyState title="Chưa có trang nhật ký nào" description="Ghi lại hành trình lớn lên của cây — ảnh lá mới, lần thay chậu hay dấu hiệu bệnh." />
      ) : (
        <ol className="relative space-y-4 border-l-2 border-mint pl-6">
          {data.map((n) => (
            <li key={n.id} className="relative">
              <span className="absolute -left-[33px] top-5 size-4 rounded-full border-4 border-background bg-leaf" />
              {editing === n.id ? (
                <Composer initial={n} pending={update.isPending} onCancel={() => setEditing(null)} onSubmit={async (v) => { await update.mutateAsync({ id: n.id, patch: v }); setEditing(null); toast.success("Đã cập nhật"); }} />
              ) : (
                <article className="rounded-3xl border bg-card p-4 shadow-soft">
                  <div className="flex items-start justify-between gap-3">
                    <div className="flex flex-wrap items-center gap-2">
                      <Badge variant={CATEGORY[n.category].variant}>{n.category === "health" && <Stethoscope />}{CATEGORY[n.category].label}</Badge>
                      <time className="text-xs text-muted-foreground">{formatDateTime(n.createdAt, lang)}</time>
                    </div>
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild><Button variant="ghost" size="icon-sm" aria-label="Tùy chọn"><MoreHorizontal /></Button></DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem onClick={() => setEditing(n.id)}><Pencil /> Chỉnh sửa</DropdownMenuItem>
                        <DropdownMenuItem className="text-danger focus:text-danger" onClick={() => setDeleting(n)}><Trash2 /> Xóa</DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </div>
                  {n.title && !["general", "care", "health", "growth", "note"].includes(n.title) && (
                    <h4 className="mt-2 font-semibold text-foreground">{n.title}</h4>
                  )}
                  <p className={cn("whitespace-pre-line text-sm leading-relaxed", n.title && !["general", "care", "health", "growth", "note"].includes(n.title) ? "mt-1 text-muted-foreground" : "mt-2")}>{n.content}</p>
                  {n.images.length > 0 && (
                    <div className="mt-3 grid grid-cols-3 gap-2 sm:grid-cols-4">
                      {n.images.map((src, i) => <a key={i} href={src} target="_blank" rel="noreferrer"><img src={src} alt="" loading="lazy" className="aspect-square w-full rounded-xl object-cover" /></a>)}
                    </div>
                  )}
                </article>
              )}
            </li>
          ))}
        </ol>
      )}
      <ConfirmDialog open={!!deleting} onOpenChange={(o) => !o && setDeleting(null)} destructive loading={remove.isPending} title="Xóa trang nhật ký này?" description="Nội dung và ảnh đính kèm sẽ bị xóa vĩnh viễn." confirmLabel="Xóa" onConfirm={async () => { await remove.mutateAsync(deleting!.id); setDeleting(null); toast.success("Đã xóa nhật ký"); }} />
    </div>
  );
}
