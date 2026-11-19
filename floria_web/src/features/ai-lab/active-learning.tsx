"use client";

import { useMemo, useState } from "react";
import { Check, X, Pencil } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { StatusBadge } from "@/components/shared/status-badge";
import { Field } from "@/components/shared/field";
import { EmptyState, CardGridSkeleton } from "@/components/shared/states";
import { useResourceList, useResourceMutations } from "@/hooks/use-resource";
import { labelReviewsService } from "@/services";
import { SPECIES_CLASSES, DISEASE_CLASSES } from "@/mocks/ai-classes";
import { useAuthStore } from "@/stores/auth-store";
import { formatDateTime } from "@/lib/format";
import { cn } from "@/lib/utils";
import type { LabelReview, ReviewStatus } from "@/types";

export function ActiveLearning({ canApprove }: { canApprove: boolean }) {
  const list = useResourceList(labelReviewsService);
  const { update } = useResourceMutations(labelReviewsService, { entity: "Nhãn AI" });
  const [tab, setTab] = useState<ReviewStatus | "all">("pending");
  const [open, setOpen] = useState<LabelReview | null>(null);
  const items = useMemo(() => (list.data ?? []).filter((x) => tab === "all" || x.status === tab), [list.data, tab]);
  const counts = (s: ReviewStatus) => list.data?.filter((x) => x.status === s).length ?? 0;

  return (
    <div>
      <Tabs value={tab} onValueChange={(v) => setTab(v as typeof tab)} className="mb-4">
        <TabsList>
          <TabsTrigger value="pending">Chờ duyệt ({counts("pending")})</TabsTrigger>
          <TabsTrigger value="approved">Đã duyệt ({counts("approved")})</TabsTrigger>
          <TabsTrigger value="rejected">Từ chối ({counts("rejected")})</TabsTrigger>
          <TabsTrigger value="all">Tất cả</TabsTrigger>
        </TabsList>
      </Tabs>
      {list.isLoading ? (
        <CardGridSkeleton />
      ) : items.length === 0 ? (
        <div className="card-surface"><EmptyState title="Hàng đợi trống" description="Không có ảnh nào trong trạng thái này." /></div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {items.map((it) => (
            <button key={it.id} onClick={() => setOpen(it)} className="card-surface group overflow-hidden text-left transition hover:shadow-raised">
              <div className="relative aspect-[4/3] overflow-hidden bg-muted">
                <img src={it.image} alt={it.predictedSpecies} className="size-full object-cover transition duration-300 group-hover:scale-105" loading="lazy" />
                <span className="absolute left-2 top-2"><StatusBadge status={it.status} /></span>
                <span className={cn("absolute right-2 top-2 rounded-md px-1.5 py-0.5 text-[11px] font-semibold tabular", it.confidence < 0.5 ? "bg-danger text-primary-foreground" : "bg-warning text-primary-foreground")}>
                  {(it.confidence * 100).toFixed(0)}%
                </span>
              </div>
              <div className="space-y-1 p-3">
                <p className="truncate text-sm font-semibold">{it.finalSpecies ?? it.predictedSpecies}</p>
                <p className="truncate text-xs text-muted-foreground">Bệnh: {it.finalDisease ?? it.predictedDisease}</p>
                <p className="text-[11px] text-muted-foreground">{it.userName} · {formatDateTime(it.submittedAt)}</p>
              </div>
            </button>
          ))}
        </div>
      )}
      <ReviewModal item={open} onClose={() => setOpen(null)} canApprove={canApprove} onSave={(patch) => open && update.mutate({ id: open.id, patch, before: open.status, label: open.id }, { onSuccess: () => setOpen(null) })} />
    </div>
  );
}

function ReviewModal({ item, onClose, onSave, canApprove }: { item: LabelReview | null; onClose: () => void; onSave: (p: Partial<LabelReview>) => void; canApprove: boolean }) {
  const reviewer = useAuthStore((s) => s.session?.name);
  const [species, setSpecies] = useState("");
  const [disease, setDisease] = useState("");
  const [notes, setNotes] = useState("");
  const [editing, setEditing] = useState(false);

  const init = (it: LabelReview) => {
    setSpecies(it.finalSpecies ?? it.predictedSpecies);
    setDisease(it.finalDisease ?? it.predictedDisease);
    setNotes(it.notes);
    setEditing(false);
  };

  return (
    <Dialog open={!!item} onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="rounded-2xl sm:max-w-3xl" onOpenAutoFocus={() => item && init(item)}>
        {item && (
          <>
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2">Duyệt nhãn · {item.id} <StatusBadge status={item.status} /></DialogTitle>
              <DialogDescription>Gửi bởi {item.userName} lúc {formatDateTime(item.submittedAt)} · Độ tin cậy mô hình {(item.confidence * 100).toFixed(1).replace(".", ",")}%</DialogDescription>
            </DialogHeader>
            <div className="grid gap-5 md:grid-cols-2">
              <img src={item.image} alt="" className="aspect-square w-full rounded-xl object-cover" />
              <div className="space-y-4">
                <div className="rounded-xl bg-surface-2/70 p-3 text-sm">
                  <p className="text-xs text-muted-foreground">Dự đoán của mô hình</p>
                  <p className="mt-1 font-medium">{item.predictedSpecies}</p>
                  <p className="text-muted-foreground">{item.predictedDisease}</p>
                </div>
                <Field label="Nhãn loài">
                  <Select value={species} onValueChange={setSpecies} disabled={!editing}>
                    <SelectTrigger><SelectValue /></SelectTrigger>
                    <SelectContent>{SPECIES_CLASSES.map((s) => <SelectItem key={s.id} value={s.vi}>{s.vi}</SelectItem>)}</SelectContent>
                  </Select>
                </Field>
                <Field label="Nhãn bệnh">
                  <Select value={disease} onValueChange={setDisease} disabled={!editing}>
                    <SelectTrigger><SelectValue /></SelectTrigger>
                    <SelectContent>{DISEASE_CLASSES.map((s) => <SelectItem key={s.id} value={s.vi}>{s.vi}</SelectItem>)}</SelectContent>
                  </Select>
                </Field>
                <Field label="Ghi chú duyệt">
                  <Textarea value={notes} onChange={(e) => setNotes(e.target.value)} placeholder="VD: lá bị che khuất, ánh sáng yếu…" disabled={!canApprove} />
                </Field>
              </div>
            </div>
            {canApprove ? (
              <DialogFooter className="gap-2 sm:justify-between">
                <Button variant="outline" onClick={() => setEditing(!editing)}><Pencil /> {editing ? "Khoá chỉnh nhãn" : "Sửa nhãn"}</Button>
                <div className="flex gap-2">
                  <Button variant="danger-soft" onClick={() => onSave({ status: "rejected", notes, reviewedBy: reviewer, finalSpecies: undefined, finalDisease: undefined })}><X /> Từ chối ảnh</Button>
                  <Button onClick={() => onSave({ status: "approved", finalSpecies: species, finalDisease: disease, notes, reviewedBy: reviewer })}><Check /> Duyệt nhãn</Button>
                </div>
              </DialogFooter>
            ) : (
              <p className="text-xs text-muted-foreground">Bạn chỉ có quyền xem hàng đợi này.</p>
            )}
          </>
        )}
      </DialogContent>
    </Dialog>
  );
}
