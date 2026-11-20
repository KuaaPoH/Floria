"use client";

import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Check, Download, FolderOpen, Microscope, Pencil, Sprout, Trash2, X } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { StatusBadge } from "@/components/shared/status-badge";
import { Field } from "@/components/shared/field";
import { EmptyState, CardGridSkeleton } from "@/components/shared/states";
import { apiRequest } from "@/lib/api-client";
import { getFirebaseIdToken } from "@/lib/firebase-client";
import { logAudit } from "@/services";
import { formatDateTime } from "@/lib/format";
import { cn } from "@/lib/utils";
import type { PlantRequestItem } from "@/app/api/admin/ai/requests/route";

interface DatasetSummary {
  totalImages: number;
  folders: Array<{
    name: string;
    count: number;
    items: Array<{ id: string; fileName: string; imageUrl: string; createdAt: string }>;
  }>;
}

function toSafeFolderName(raw: string): string {
  return raw
    .trim()
    .replace(/\s+/g, "_")
    .replace(/[<>:"/\\|?*]+/g, "_");
}

async function downloadDatasetZip(folder: string) {
  const token = await getFirebaseIdToken();
  const res = await fetch(`/api/admin/ai/dataset/download?folder=${encodeURIComponent(folder)}`, {
    headers: token ? { Authorization: `Bearer ${token}` } : undefined,
  });
  if (!res.ok) {
    const err = (await res.json().catch(() => ({}))) as { error?: string };
    throw new Error(err.error || "Không thể tải file nén dataset");
  }
  const blob = await res.blob();
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = folder === "all" ? "floria_dataset_all.zip" : `floria_dataset_${folder}.zip`;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}

export function ActiveLearning({ canApprove }: { canApprove: boolean }) {
  const qc = useQueryClient();
  const list = useQuery({
    queryKey: ["ai-plant-requests"],
    queryFn: () => apiRequest<PlantRequestItem[]>("/ai/requests"),
  });

  const dataset = useQuery({
    queryKey: ["ai-dataset-folders"],
    queryFn: () => apiRequest<DatasetSummary>("/ai/dataset"),
  });

  const [tab, setTab] = useState<"pending" | "approved" | "rejected" | "all">("pending");
  const [open, setOpen] = useState<PlantRequestItem | null>(null);
  const [datasetOpen, setDatasetOpen] = useState(false);

  const items = useMemo(
    () => (list.data ?? []).filter((x) => tab === "all" || x.status === tab),
    [list.data, tab],
  );
  const counts = (s: "pending" | "approved" | "rejected") =>
    list.data?.filter((x) => x.status === s).length ?? 0;

  return (
    <div className="space-y-4">
      {/* Thanh tổng quan thư mục Dataset tích lũy để train */}
      <div className="flex flex-wrap items-center justify-between gap-3 rounded-xl border bg-surface-2/40 px-4 py-3">
        <div className="flex items-center gap-3 text-xs">
          <span className="grid size-8 place-items-center rounded-lg bg-forest/10 text-forest">
            <FolderOpen className="size-4" />
          </span>
          <div>
            <p className="font-semibold text-foreground">
              Kho ảnh tích lũy để Train: {dataset.data?.totalImages ?? 0} ảnh ({dataset.data?.folders.length ?? 0} thư mục loài)
            </p>
            <p className="text-muted-foreground">
              Ảnh lưu trên Cloudinary & lập chỉ mục trong Firestore <code className="font-mono">TrainingDataset</code> — bấm Tải sẽ nén .zip trực tiếp.
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Button size="sm" variant="outline" onClick={() => setDatasetOpen(true)}>
            <FolderOpen className="size-3.5" /> Quản lý thư mục
          </Button>
          {(dataset.data?.totalImages ?? 0) > 0 && (
            <Button
              size="sm"
              onClick={() =>
                downloadDatasetZip("all").catch((e) =>
                  toast.error(e instanceof Error ? e.message : "Lỗi tải dataset"),
                )
              }
            >
              <Download className="size-3.5" /> Tải toàn bộ (.zip)
            </Button>
          )}
        </div>
      </div>

      <Tabs value={tab} onValueChange={(v) => setTab(v as typeof tab)}>
        <TabsList>
          <TabsTrigger value="pending">Chờ duyệt ({counts("pending")})</TabsTrigger>
          <TabsTrigger value="approved">Đã duyệt ({counts("approved")})</TabsTrigger>
          <TabsTrigger value="rejected">Từ chối ({counts("rejected")})</TabsTrigger>
          <TabsTrigger value="all">Tất cả ({list.data?.length ?? 0})</TabsTrigger>
        </TabsList>
      </Tabs>

      {list.isLoading ? (
        <CardGridSkeleton />
      ) : items.length === 0 ? (
        <div className="card-surface">
          <EmptyState
            title="Hàng đợi PlantRequests trống"
            description="Chưa có báo cáo cây mới / bệnh mới hoặc phản hồi nhận diện sai nào từ Floria App trong mục này."
          />
        </div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {items.map((it) => {
            const confPct =
              it.confidence == null
                ? null
                : it.confidence <= 1
                  ? it.confidence * 100
                  : it.confidence;
            return (
              <button
                key={it.id}
                onClick={() => setOpen(it)}
                className="card-surface group overflow-hidden text-left transition hover:shadow-raised"
              >
                <div className="relative aspect-[4/3] overflow-hidden bg-muted">
                  {it.imageUrl ? (
                    <img
                      src={it.imageUrl}
                      alt={it.suggestedName || it.predictedNameVi || "PlantRequest"}
                      className="size-full object-cover transition duration-300 group-hover:scale-105"
                      loading="lazy"
                    />
                  ) : (
                    <div className="grid size-full place-items-center text-xs text-muted-foreground">
                      Không có ảnh
                    </div>
                  )}
                  <span className="absolute left-2 top-2">
                    <StatusBadge status={it.status} />
                  </span>
                  {confPct !== null && (
                    <span
                      className={cn(
                        "absolute right-2 top-2 rounded-md px-1.5 py-0.5 text-[11px] font-semibold tabular",
                        confPct < 50
                          ? "bg-danger text-primary-foreground"
                          : "bg-warning text-primary-foreground",
                      )}
                    >
                      {confPct.toFixed(0)}%
                    </span>
                  )}
                  <span className="absolute bottom-2 left-2 inline-flex items-center gap-1 rounded-md bg-black/65 px-2 py-0.5 text-[10px] font-medium text-white">
                    {it.isDiseaseScan ? <Microscope className="size-3" /> : <Sprout className="size-3" />}
                    {it.isDiseaseScan ? "Bệnh lá" : "Loài cây"}
                  </span>
                </div>
                <div className="space-y-1 p-3">
                  <p className="truncate text-sm font-semibold">
                    {it.finalLabel || it.suggestedName || "(Chưa đặt tên)"}
                  </p>
                  <p className="truncate text-xs text-muted-foreground">
                    AI đoán: {it.predictedNameVi || it.predictedLabel || "Không rõ"}
                  </p>
                  <p className="text-[11px] text-muted-foreground">
                    {it.userName} · {formatDateTime(it.createdAt)}
                  </p>
                </div>
              </button>
            );
          })}
        </div>
      )}

      <ReviewModal
        item={open}
        onClose={() => setOpen(null)}
        canApprove={canApprove}
        onDone={() => {
          qc.invalidateQueries({ queryKey: ["ai-plant-requests"] });
          qc.invalidateQueries({ queryKey: ["ai-dataset-folders"] });
          qc.invalidateQueries({ queryKey: ["plants"] });
          setOpen(null);
        }}
      />

      <DatasetManagerModal
        open={datasetOpen}
        onClose={() => setDatasetOpen(false)}
        summary={dataset.data}
        canApprove={canApprove}
        onChanged={() => qc.invalidateQueries({ queryKey: ["ai-dataset-folders"] })}
      />
    </div>
  );
}

function ReviewModal({
  item,
  onClose,
  canApprove,
  onDone,
}: {
  item: PlantRequestItem | null;
  onClose: () => void;
  canApprove: boolean;
  onDone: () => void;
}) {
  const [saving, setSaving] = useState(false);

  // Thông tin lưu vào plants_info
  const [saveToPlantsInfo, setSaveToPlantsInfo] = useState(true);
  const [sciName, setSciName] = useState("");
  const [viName, setViName] = useState("");
  const [category, setCategory] = useState("Cây cảnh");
  const [family, setFamily] = useState("");
  const [origin, setOrigin] = useState("");
  const [difficulty, setDifficulty] = useState("Trung bình");
  const [light, setLight] = useState("Ánh sáng gián tiếp");
  const [watering, setWatering] = useState("2-3 lần/tuần");
  const [temperature, setTemperature] = useState("18-28°C");
  const [humidity, setHumidity] = useState("50-70%");
  const [soil, setSoil] = useState("");
  const [toxicityNote, setToxicityNote] = useState("Không độc");
  const [identification, setIdentification] = useState("");
  const [description, setDescription] = useState("");
  const [wikiDetail, setWikiDetail] = useState("");

  // Thông tin lưu ảnh vào thư mục Dataset
  const [saveToDataset, setSaveToDataset] = useState(true);
  const [folderName, setFolderName] = useState("");
  const [adminNotes, setAdminNotes] = useState("");

  const init = (it: PlantRequestItem) => {
    const rawSci =
      it.predictedLabel && !/không|invalid/i.test(it.predictedLabel)
        ? it.predictedLabel
        : "";
    const rawVi = it.finalLabel || it.suggestedName || it.predictedNameVi || "";

    setSaveToPlantsInfo(!it.isDiseaseScan);
    setSciName(rawSci);
    setViName(rawVi);
    setCategory("Cây cảnh");
    setFamily("");
    setOrigin("");
    setDifficulty("Trung bình");
    setLight("Ánh sáng gián tiếp");
    setWatering("2-3 lần/tuần");
    setTemperature("18-28°C");
    setHumidity("50-70%");
    setSoil("");
    setToxicityNote("Không độc");
    setIdentification("");
    setDescription(it.note || "");
    setWikiDetail("");

    setSaveToDataset(Boolean(it.imageUrl));
    setFolderName(toSafeFolderName(rawSci || rawVi || "unknown_plant"));
    setAdminNotes(it.adminNotes || "");
  };

  const handleApprove = async () => {
    if (!item) return;
    if (saveToPlantsInfo && (!sciName.trim() || !viName.trim())) {
      toast.error("Vui lòng nhập đầy đủ Tên khoa học và Tên tiếng Việt để lưu vào plants_info.");
      return;
    }
    if (saveToDataset && item.imageUrl && !folderName.trim()) {
      toast.error("Vui lòng nhập tên thư mục lưu ảnh train.");
      return;
    }

    setSaving(true);
    try {
      // 1. Lưu vào collection plants_info trên Firestore
      if (saveToPlantsInfo) {
        await apiRequest("/plants", {
          method: "POST",
          body: JSON.stringify({
            sciName: sciName.trim(),
            viName: viName.trim(),
            enName: sciName.trim(),
            category: category.trim(),
            family: family.trim(),
            origin: origin.trim(),
            difficulty: difficulty.trim(),
            light: light.trim(),
            watering: watering.trim(),
            temperature: temperature.trim(),
            humidity: humidity.trim(),
            soil: soil.trim(),
            toxicityNote: toxicityNote.trim(),
            identification: identification.trim(),
            description: description.trim(),
            wikiDetail: wikiDetail.trim(),
            image: item.imageUrl || "",
            status: "published",
          }),
        });
      }

      // 2. Lưu ảnh vào thư mục riêng để tích luỹ train
      if (saveToDataset && item.imageUrl) {
        await apiRequest("/ai/dataset", {
          method: "POST",
          body: JSON.stringify({
            imageUrl: item.imageUrl,
            folderName: folderName.trim(),
            fileName: `${toSafeFolderName(sciName || viName || item.id)}_${Date.now()}`,
            requestId: item.id,
          }),
        });
      }

      // 3. Cập nhật trạng thái PlantRequests thành approved
      await apiRequest(`/ai/requests/${item.id}`, {
        method: "PATCH",
        body: JSON.stringify({
          status: "approved",
          finalLabel: viName.trim() || sciName.trim(),
          adminNotes: adminNotes.trim(),
        }),
      });

      toast.success("Đã duyệt, cập nhật từ điển & lưu ảnh vào thư mục train!");
      logAudit({
        action: "Duyệt PlantRequest",
        target: `plants_info/${sciName || item.id}`,
        before: "pending",
        after: `approved (${folderName})`,
      });
      onDone();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Lỗi khi duyệt báo cáo");
    } finally {
      setSaving(false);
    }
  };

  const handleReject = async () => {
    if (!item) return;
    setSaving(true);
    try {
      await apiRequest(`/ai/requests/${item.id}`, {
        method: "PATCH",
        body: JSON.stringify({
          status: "rejected",
          adminNotes: adminNotes.trim(),
        }),
      });
      toast.success("Đã từ chối báo cáo");
      onDone();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Lỗi từ chối báo cáo");
    } finally {
      setSaving(false);
    }
  };

  return (
    <Dialog open={!!item} onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="max-h-[90vh] overflow-y-auto rounded-2xl sm:max-w-4xl" onOpenAutoFocus={() => item && init(item)}>
        {item && (
          <>
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2">
                Duyệt & Cập nhật Thông tin Cây · <StatusBadge status={item.status} />
              </DialogTitle>
              <DialogDescription>
                Gửi bởi <b>{item.userName}</b> ({item.userEmail || item.userId}) lúc {formatDateTime(item.createdAt)}
              </DialogDescription>
            </DialogHeader>

            <div className="grid gap-5 md:grid-cols-[260px_1fr]">
              <div className="space-y-3">
                <div className="overflow-hidden rounded-xl border bg-muted">
                  {item.imageUrl ? (
                    <img src={item.imageUrl} alt={item.suggestedName} className="aspect-square w-full object-cover" />
                  ) : (
                    <div className="grid aspect-square place-items-center text-sm text-muted-foreground">
                      Không có ảnh
                    </div>
                  )}
                </div>

                <div className="rounded-xl bg-surface-2/70 p-3 text-xs">
                  <p className="text-muted-foreground">Người dùng gửi lên:</p>
                  <p className="mt-1 font-semibold text-forest">{item.suggestedName || "—"}</p>
                  {item.note && <p className="mt-1 text-muted-foreground">Ghi chú: {item.note}</p>}
                  <p className="mt-2 text-muted-foreground">
                    AI dự đoán cũ: <b>{item.predictedNameVi || item.predictedLabel || "—"}</b>
                  </p>
                </div>

                {item.imageUrl && (
                  <div className="space-y-2 rounded-xl border p-3">
                    <label className="flex items-center justify-between text-xs font-semibold">
                      <span>Lưu ảnh vào kho Train</span>
                      <Switch
                        checked={saveToDataset}
                        onCheckedChange={setSaveToDataset}
                        disabled={!canApprove || saving}
                      />
                    </label>
                    {saveToDataset && (
                      <Field label="Tên thư mục (Dataset)">
                        <Input
                          value={folderName}
                          onChange={(e) => setFolderName(e.target.value)}
                          placeholder="VD: Rosa_chinensis"
                          disabled={!canApprove || saving}
                          className="h-8 font-mono text-xs"
                        />
                      </Field>
                    )}
                  </div>
                )}

                <Field label="Ghi chú duyệt của Admin">
                  <Textarea
                    rows={2}
                    value={adminNotes}
                    onChange={(e) => setAdminNotes(e.target.value)}
                    placeholder="Ghi chú thêm..."
                    disabled={!canApprove || saving}
                    className="text-xs"
                  />
                </Field>
              </div>

              <div className="space-y-4">
                <label className="flex items-center justify-between rounded-xl border bg-surface-2/40 px-4 py-2.5 text-sm font-semibold">
                  <span>Cập nhật / Thêm vào từ điển <code className="font-mono text-xs">plants_info</code></span>
                  <Switch
                    checked={saveToPlantsInfo}
                    onCheckedChange={setSaveToPlantsInfo}
                    disabled={!canApprove || saving}
                  />
                </label>

                {saveToPlantsInfo && (
                  <div className="grid gap-3 sm:grid-cols-2">
                    <Field label="Tên khoa học (Document ID) *">
                      <Input
                        value={sciName}
                        onChange={(e) => {
                          setSciName(e.target.value);
                          if (!folderName || folderName === toSafeFolderName(sciName)) {
                            setFolderName(toSafeFolderName(e.target.value || viName));
                          }
                        }}
                        placeholder="VD: Rosa chinensis"
                        disabled={!canApprove || saving}
                      />
                    </Field>
                    <Field label="Tên tiếng Việt *">
                      <Input
                        value={viName}
                        onChange={(e) => setViName(e.target.value)}
                        placeholder="VD: Hoa hồng"
                        disabled={!canApprove || saving}
                      />
                    </Field>
                    <Field label="Loại cây (plant_type)">
                      <Input value={category} onChange={(e) => setCategory(e.target.value)} disabled={!canApprove || saving} />
                    </Field>
                    <Field label="Họ thực vật (family)">
                      <Input value={family} onChange={(e) => setFamily(e.target.value)} placeholder="VD: Rosaceae" disabled={!canApprove || saving} />
                    </Field>
                    <Field label="Nguồn gốc (origin)">
                      <Input value={origin} onChange={(e) => setOrigin(e.target.value)} placeholder="VD: Châu Á" disabled={!canApprove || saving} />
                    </Field>
                    <Field label="Mức độ chăm sóc">
                      <Input value={difficulty} onChange={(e) => setDifficulty(e.target.value)} disabled={!canApprove || saving} />
                    </Field>
                    <Field label="Ánh sáng (light)">
                      <Input value={light} onChange={(e) => setLight(e.target.value)} disabled={!canApprove || saving} />
                    </Field>
                    <Field label="Tưới nước (water_frequency)">
                      <Input value={watering} onChange={(e) => setWatering(e.target.value)} disabled={!canApprove || saving} />
                    </Field>
                    <Field label="Nhiệt độ (temperature)">
                      <Input value={temperature} onChange={(e) => setTemperature(e.target.value)} disabled={!canApprove || saving} />
                    </Field>
                    <Field label="Độ ẩm (humidity)">
                      <Input value={humidity} onChange={(e) => setHumidity(e.target.value)} disabled={!canApprove || saving} />
                    </Field>
                    <Field label="Loại rễ (root_type)">
                      <Input value={soil} onChange={(e) => setSoil(e.target.value)} placeholder="VD: Rễ chùm" disabled={!canApprove || saving} />
                    </Field>
                    <Field label="Độc tính (toxicity)">
                      <Input value={toxicityNote} onChange={(e) => setToxicityNote(e.target.value)} disabled={!canApprove || saving} />
                    </Field>
                    <Field label="Đặc điểm nhận dạng (identification)" className="sm:col-span-2">
                      <Input value={identification} onChange={(e) => setIdentification(e.target.value)} disabled={!canApprove || saving} />
                    </Field>
                    <Field label="Mô tả ngắn (short_desc)" className="sm:col-span-2">
                      <Textarea rows={2} value={description} onChange={(e) => setDescription(e.target.value)} disabled={!canApprove || saving} />
                    </Field>
                    <Field label="Thông tin Bách khoa chi tiết (wiki_detail)" className="sm:col-span-2">
                      <Textarea rows={3} value={wikiDetail} onChange={(e) => setWikiDetail(e.target.value)} disabled={!canApprove || saving} />
                    </Field>
                  </div>
                )}
              </div>
            </div>

            {canApprove ? (
              <DialogFooter className="gap-2">
                <Button variant="danger-soft" disabled={saving} onClick={handleReject}>
                  <X /> Từ chối
                </Button>
                <Button disabled={saving} onClick={handleApprove}>
                  <Check /> {saving ? "Đang lưu..." : "Duyệt & Lưu thông tin"}
                </Button>
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

function DatasetManagerModal({
  open,
  onClose,
  summary,
  canApprove,
  onChanged,
}: {
  open: boolean;
  onClose: () => void;
  summary?: DatasetSummary;
  canApprove: boolean;
  onChanged: () => void;
}) {
  const [renaming, setRenaming] = useState<string | null>(null);
  const [newName, setNewName] = useState("");
  const [expanded, setExpanded] = useState<string | null>(null);

  const renameMutation = useMutation({
    mutationFn: (payload: { oldName: string; newName: string }) =>
      apiRequest("/ai/dataset", { method: "PATCH", body: JSON.stringify(payload) }),
    onSuccess: () => {
      toast.success("Đã đổi tên thư mục");
      setRenaming(null);
      onChanged();
    },
    onError: (e) => toast.error(e instanceof Error ? e.message : "Lỗi đổi tên thư mục"),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => apiRequest(`/ai/dataset?id=${encodeURIComponent(id)}`, { method: "DELETE" }),
    onSuccess: () => {
      toast.success("Đã xoá ảnh khỏi kho Dataset");
      onChanged();
    },
    onError: (e) => toast.error(e instanceof Error ? e.message : "Lỗi xoá ảnh"),
  });

  return (
    <Dialog open={open} onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="max-h-[85vh] overflow-y-auto rounded-2xl sm:max-w-3xl">
        <DialogHeader>
          <DialogTitle>Kho ảnh Dataset tích lũy (Cloudinary)</DialogTitle>
          <DialogDescription>
            Xem trước ảnh theo từng thư mục loài cây. Bấm <b>Tải .zip</b> để nén ảnh từ Cloudinary và tải về máy.
          </DialogDescription>
        </DialogHeader>

        {!summary || summary.folders.length === 0 ? (
          <EmptyState
            title="Chưa có thư mục ảnh nào"
            description="Khi bạn duyệt báo cáo và bật Lưu ảnh vào kho Train, ảnh sẽ xuất hiện tại đây."
          />
        ) : (
          <div className="space-y-3">
            {summary.folders.map((f) => (
              <div key={f.name} className="rounded-xl border p-3 text-sm">
                <div className="flex items-center justify-between gap-3">
                  {renaming === f.name ? (
                    <div className="flex flex-1 items-center gap-2">
                      <Input
                        value={newName}
                        onChange={(e) => setNewName(e.target.value)}
                        className="h-8 font-mono text-xs"
                      />
                      <Button
                        size="sm"
                        disabled={renameMutation.isPending}
                        onClick={() => renameMutation.mutate({ oldName: f.name, newName })}
                      >
                        Lưu
                      </Button>
                      <Button size="sm" variant="ghost" onClick={() => setRenaming(null)}>
                        Huỷ
                      </Button>
                    </div>
                  ) : (
                    <>
                      <button
                        type="button"
                        onClick={() => setExpanded(expanded === f.name ? null : f.name)}
                        className="min-w-0 flex-1 text-left"
                      >
                        <p className="truncate font-mono font-semibold text-forest">{f.name}</p>
                        <p className="text-xs text-muted-foreground">
                          {f.count} ảnh · Bấm để {expanded === f.name ? "thu gọn" : "xem ảnh"}
                        </p>
                      </button>
                      <div className="flex items-center gap-1.5">
                        {canApprove && (
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => {
                              setRenaming(f.name);
                              setNewName(f.name);
                            }}
                          >
                            <Pencil className="size-3.5" /> Đổi tên
                          </Button>
                        )}
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() =>
                            downloadDatasetZip(f.name).catch((e) =>
                              toast.error(e instanceof Error ? e.message : "Lỗi tải"),
                            )
                          }
                        >
                          <Download className="size-3.5" /> Tải .zip
                        </Button>
                      </div>
                    </>
                  )}
                </div>

                {expanded === f.name && f.items.length > 0 && (
                  <div className="mt-3 grid grid-cols-3 gap-2 border-t pt-3 sm:grid-cols-5">
                    {f.items.map((img) => (
                      <div key={img.id} className="group relative overflow-hidden rounded-lg border bg-muted">
                        <img
                          src={img.imageUrl}
                          alt={img.fileName}
                          className="aspect-square w-full object-cover"
                          loading="lazy"
                        />
                        {canApprove && (
                          <button
                            type="button"
                            onClick={() => deleteMutation.mutate(img.id)}
                            title="Xoá khỏi kho Dataset"
                            className="absolute right-1 top-1 hidden rounded-md bg-black/70 p-1 text-white group-hover:block"
                          >
                            <Trash2 className="size-3" />
                          </button>
                        )}
                      </div>
                    ))}
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}
