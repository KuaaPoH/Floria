"use client";

import { useState } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { AlertTriangle, ArrowLeft, Calendar, Droplets, FlaskConical, Leaf, MapPin, MessageCircle, MoreHorizontal, MoveRight, Pencil, Skull, Stethoscope, Sun, Thermometer, Trash2, Wind } from "lucide-react";
import { toast } from "sonner";
import { PlantStatusBadge } from "@/components/botanical";
import { ConfirmDialog } from "@/components/layout/ConfirmDialog";
import { PageContainer } from "@/components/layout/PageContainer";
import { EmptyState, ErrorState, LoadingState } from "@/components/layout/states";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { Field } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Progress } from "@/components/ui/progress";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { CareScheduleCard } from "@/features/garden/CareScheduleCard";
import { EditCareSchedulesDialog } from "@/features/garden/EditCareSchedulesDialog";
import { ImageUploader } from "@/components/shared/image-uploader";
import { computeEffectiveStatus, locationChips } from "@/features/garden/logic";
import { PlantDiary } from "@/features/garden/PlantDiary";
import { useDiseases, useGardens, usePlantMutations, usePlants, useScanHistory, useSchedules, useSpecies } from "@/hooks/queries";
import { useLang } from "@/i18n";
import { formatDate, formatDateTime, formatRelativeDays, percent } from "@/lib/format";
import { findDisease } from "@/mocks/user/diseases";
import { findPlantInfoOrFallback } from "@/mocks/user/plants-info";
import type { CareType } from "@/types/user";

const ORDER: CareType[] = ["watering", "fertilizing", "inspection"];

export default function PlantDetailPage() {
  const { gardenId, plantId } = useParams<{ gardenId: string; plantId: string }>();
  const lang = useLang();
  const router = useRouter();
  const plantsQ = usePlants();
  useSpecies();
  useDiseases();
  const { data: gardens = [] } = useGardens();
  const { data: schedules = [] } = useSchedules();
  const { data: scans = [] } = useScanHistory();
  const { update, remove } = usePlantMutations();
  const [editOpen, setEditOpen] = useState(false);
  const [editSchedulesOpen, setEditSchedulesOpen] = useState(false);
  const [delOpen, setDelOpen] = useState(false);
  const plant = plantsQ.data?.find((p) => p.id === plantId);
  const [form, setForm] = useState({ nickname: "", location: "", gardenId: "", image: "" });

  if (plantsQ.isLoading) return <LoadingState className="min-h-[60vh]" />;
  if (plantsQ.isError) return <PageContainer><ErrorState onRetry={() => plantsQ.refetch()} /></PageContainer>;
  if (!plant) return <PageContainer><EmptyState title="Không tìm thấy cây" description="Cây này không tồn tại hoặc đã bị xóa." action={<Button asChild><Link href="/garden">Về khu vườn</Link></Button>} /></PageContainer>;

  const info = findPlantInfoOrFallback(plant.speciesId, plant.nickname, plant.image);
  const garden = gardens.find((g) => g.id === plant.gardenId);
  const status = computeEffectiveStatus(plant, schedules);
  const mine = schedules.filter((s) => s.plantId === plant.id).sort((a, b) => ORDER.indexOf(a.type) - ORDER.indexOf(b.type));
  const activeSchedules = mine.filter((s) => s.enabled);
  const disease = plant.activeDiseaseId ? findDisease(plant.activeDiseaseId) : null;
  const existingLocations = locationChips((plantsQ.data ?? []).filter((p) => p.gardenId === (form.gardenId || plant.gardenId))).map((c) => c.name);
  const waterSched = mine.find((s) => s.type === "watering");
  const soilMoisture = (() => {
    const lastMs = waterSched?.lastDoneAt ? Date.parse(waterSched.lastDoneAt) : Date.parse(plant.addedAt);
    const totalHours = Math.max(1, (waterSched?.intervalDays ?? info.wateringDays ?? 5) * 24);
    const elapsedHours = Math.max(0, (Date.now() - lastMs) / 3600000);
    return Math.min(1, Math.max(0.05, 1 - elapsedHours / totalHours));
  })();
  const soilMoistureLabel =
    soilMoisture >= 0.75
      ? "Đất ẩm lý tưởng (75–100%)"
      : soilMoisture >= 0.45
        ? "Độ ẩm vừa phải (45–75%)"
        : soilMoisture >= 0.2
          ? "Đất bắt đầu se khô (20–45%)"
          : "Đất khô hạn (Cần tưới ngay)";
  const plantScans = scans.filter((s) => s.type === "diagnose" && s.plantId === plant.id).slice(0, 4);

  const openEdit = () => {
    setForm({ nickname: plant.nickname, location: plant.location, gardenId: plant.gardenId, image: plant.image });
    setEditOpen(true);
  };

  return (
    <PageContainer>
      <div className="mb-6 flex items-center justify-between">
        <Button asChild variant="ghost" size="sm"><Link href={`/garden/${gardenId}`}><ArrowLeft /> {garden?.name ?? "Khu vườn"}</Link></Button>
        <DropdownMenu>
          <DropdownMenuTrigger asChild><Button variant="outline" size="sm"><MoreHorizontal /> Thao tác</Button></DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="rounded-xl">
            <DropdownMenuItem onClick={openEdit}><Pencil /> Chỉnh sửa thông tin</DropdownMenuItem>
            <DropdownMenuItem onClick={openEdit}><MapPin /> Chuyển vị trí</DropdownMenuItem>
            <DropdownMenuItem onClick={openEdit}><MoveRight /> Chuyển khu vườn</DropdownMenuItem>
            <DropdownMenuItem className="text-danger focus:text-danger" onClick={() => setDelOpen(true)}><Trash2 /> Xóa cây</DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>

      <section className="grid gap-8 lg:grid-cols-[0.9fr_1.1fr]">
        <div className="relative overflow-hidden rounded-[2rem] bg-mint shadow-card">
          <img src={plant.image} alt={plant.nickname} className="aspect-[4/5] w-full object-cover" />
          <PlantStatusBadge status={status} className="absolute left-4 top-4 shadow-soft" />
        </div>
        <div className="flex flex-col">
          <p className="eyebrow">{info.family}</p>
          <h1 className="mt-2 text-4xl font-bold tracking-tight md:text-5xl">{plant.nickname}</h1>
          <p className="mt-1 text-lg text-muted-foreground">{info.commonName} · <i>{info.scientificName}</i></p>
          <dl className="mt-6 grid grid-cols-2 gap-3 sm:grid-cols-3">
            {[
              { icon: Leaf, label: "Khu vườn", value: garden?.name ?? "—" },
              { icon: MapPin, label: "Vị trí", value: plant.location },
              { icon: Calendar, label: "Ngày thêm", value: formatDate(plant.addedAt, lang) },
            ].map((x) => (
              <div key={x.label} className="rounded-2xl border bg-card p-3">
                <dt className="flex items-center gap-1.5 text-xs text-muted-foreground"><x.icon className="size-3.5" />{x.label}</dt>
                <dd className="mt-1 truncate font-semibold">{x.value}</dd>
              </div>
            ))}
          </dl>
          {disease && (
            <div className="mt-4 flex items-start gap-3 rounded-2xl border border-danger/25 bg-danger-soft/50 p-4">
              <AlertTriangle className="mt-0.5 size-5 shrink-0 text-danger" />
              <div className="text-sm">
                <p className="font-semibold text-danger">Đang điều trị: {disease.name}</p>
                <p className="mt-0.5 text-muted-foreground">{disease.treatment[0]}</p>
              </div>
            </div>
          )}
          {plant.healthStatus === "recovering" && !disease && (
            <p className="mt-4 rounded-2xl bg-warning-soft p-3 text-sm text-warning">Cây đang trong giai đoạn hồi phục — tiếp tục theo dõi nhật ký sức khỏe.</p>
          )}
          <p className="mt-6 leading-relaxed text-muted-foreground">{info.description}</p>
          <div className="mt-auto flex flex-wrap gap-2 pt-6">
            <Button asChild size="lg"><Link href={`/garden/${plant.gardenId}/plants/${plant.id}/diagnosis`}><Stethoscope /> Quét bệnh</Link></Button>
            <Button asChild size="lg" variant="outline"><Link href={`/assistant?q=${encodeURIComponent(`Tư vấn chăm sóc cây ${info.commonName} (${plant.nickname}) đặt ở ${plant.location}`)}`}><MessageCircle /> Hỏi Trợ lý Floria</Link></Button>
          </div>
        </div>
      </section>

      <Tabs defaultValue="schedule" className="mt-12">
        <TabsList className="scrollbar-none h-auto w-full justify-start overflow-x-auto rounded-2xl bg-mint/60 p-1">
          {[["overview", "Tổng quan"], ["schedule", "Lịch chăm sóc"], ["encyclopedia", "Bách khoa"], ["diary", "Nhật ký cây"]].map(([v, l]) => (
            <TabsTrigger key={v} value={v} className="rounded-xl px-4 py-2 data-[state=active]:bg-card data-[state=active]:shadow-soft">{l}</TabsTrigger>
          ))}
        </TabsList>
        <TabsContent value="overview" className="mt-6 space-y-5">
          <div className="grid gap-5 md:grid-cols-2">
            <div className="rounded-3xl border bg-card p-6">
              <div className="flex items-center justify-between gap-2">
                <h3 className="flex items-center gap-2 font-semibold"><Droplets className="size-4 text-info" /> Độ ẩm đất ước tính</h3>
                <span className="text-lg font-bold text-forest dark:text-foreground">{Math.round(soilMoisture * 100)}%</span>
              </div>
              <Progress value={soilMoisture * 100} className="mt-3 h-2.5" />
              <p className="mt-2 text-xs text-muted-foreground">{soilMoistureLabel}</p>
              <dl className="mt-5 grid grid-cols-3 gap-2 border-t pt-4 text-xs">
                {activeSchedules.map((s) => (
                  <div key={s.id} className="rounded-xl bg-mint/40 p-2.5">
                    <dt className="text-muted-foreground">{s.type === "watering" ? "Tưới nước" : s.type === "fertilizing" ? "Bón phân" : "Kiểm tra"}</dt>
                    <dd className="mt-1 font-semibold">{formatRelativeDays(s.nextDueAt, lang)}</dd>
                  </div>
                ))}
              </dl>
              <div className="mt-4 flex items-center gap-2 text-sm">Trạng thái hiện tại: <PlantStatusBadge status={status} /></div>
            </div>
            <div className="rounded-3xl border bg-card p-6">
              <h3 className="font-semibold">Điều kiện phù hợp & chăm sóc</h3>
              <ul className="mt-4 space-y-3 text-sm">
                <li className="flex gap-3"><Sun className="size-4 shrink-0 text-warning" /><span>{info.light}</span></li>
                <li className="flex gap-3"><Droplets className="size-4 shrink-0 text-info" /><span>{info.water}</span></li>
                <li className="flex gap-3"><Thermometer className="size-4 shrink-0 text-danger" /><span>{info.temperature}</span></li>
                <li className="flex gap-3"><Wind className="size-4 shrink-0 text-leaf" /><span>Độ ẩm {info.humidity}</span></li>
              </ul>
            </div>
          </div>

          <div className="rounded-3xl border bg-card p-6">
            <div className="flex items-center justify-between gap-2">
              <h3 className="flex items-center gap-2 font-semibold"><Stethoscope className="size-4 text-leaf" /> Lịch sử chẩn đoán bệnh lá gần đây</h3>
              <Button asChild size="sm" variant="outline"><Link href={`/garden/${plant.gardenId}/plants/${plant.id}/diagnosis`}>Quét bệnh mới</Link></Button>
            </div>
            {plantScans.length === 0 ? (
              <p className="mt-3 text-sm text-muted-foreground">Chưa có lượt chẩn đoán bệnh lá nào cho cây này.</p>
            ) : (
              <div className="mt-4 grid gap-3 sm:grid-cols-2">
                {plantScans.map((sc) => {
                  const d = sc.diseaseId ? findDisease(sc.diseaseId) : null;
                  return (
                    <div key={sc.id} className="flex items-center gap-3 rounded-2xl border bg-background/60 p-3">
                      <img src={sc.image} alt="" className="size-12 shrink-0 rounded-xl object-cover" />
                      <div className="min-w-0 flex-1">
                        <p className="truncate text-sm font-semibold">{d?.name ?? sc.diseaseId ?? "Kết quả quét"}</p>
                        <p className="text-xs text-muted-foreground">
                          {formatDateTime(sc.createdAt, lang)} {sc.confidence ? `· ${percent(sc.confidence)}` : ""}
                        </p>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </TabsContent>
        <TabsContent value="schedule" className="mt-6">
          <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
            <p className="text-sm text-muted-foreground">
              Các lịch hoạt động độc lập — hoàn thành một lịch không ảnh hưởng đến các lịch còn lại.
            </p>
            <Button variant="outline" size="sm" onClick={() => setEditSchedulesOpen(true)}>
              <Pencil className="size-3.5" /> Chỉnh sửa
            </Button>
          </div>
          <div className="grid gap-5 md:grid-cols-3">
            {activeSchedules.map((s) => (
              <CareScheduleCard key={s.id} schedule={s} />
            ))}
          </div>
          <EditCareSchedulesDialog
            open={editSchedulesOpen}
            onOpenChange={setEditSchedulesOpen}
            schedules={mine}
            recommendedWater={info.water}
          />
        </TabsContent>
        <TabsContent value="encyclopedia" className="mt-6">
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {[
              { label: "Đặc điểm", value: info.description, icon: Leaf },
              { label: "Nguồn gốc", value: info.origin, icon: MapPin },
              { label: "Môi trường", value: info.environment, icon: Leaf },
              { label: "Ánh sáng", value: info.light, icon: Sun },
              { label: "Nước", value: info.water, icon: Droplets },
              { label: "Đất", value: info.soil, icon: FlaskConical },
              { label: "Nhiệt độ", value: info.temperature, icon: Thermometer },
              { label: "Độ ẩm", value: info.humidity, icon: Wind },
              { label: "Độc tính", value: info.toxicity ?? "Không ghi nhận độc tính", icon: Skull },
            ].map((x) => (
              <div key={x.label} className="rounded-3xl border bg-card p-5">
                <p className="flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-leaf"><x.icon className="size-3.5" />{x.label}</p>
                <p className="mt-2 text-sm leading-relaxed">{x.value}</p>
              </div>
            ))}
          </div>
        </TabsContent>
        <TabsContent value="diary" className="mt-6 max-w-3xl"><PlantDiary plantId={plant.id} /></TabsContent>
      </Tabs>

      <Dialog open={editOpen} onOpenChange={setEditOpen}>
        <DialogContent className="max-h-[90vh] overflow-y-auto rounded-3xl sm:max-w-md">
          <DialogHeader><DialogTitle>Chỉnh sửa cây</DialogTitle></DialogHeader>
          <div className="space-y-4">
            <Field label="Ảnh cây" htmlFor="plant-img">
              <ImageUploader
                aspect="wide"
                className="max-h-44"
                label="Kéo thả hoặc chọn ảnh mới cho cây"
                value={form.image}
                onChange={(url) => setForm({ ...form, image: url })}
              />
            </Field>
            <Field label="Tên riêng" htmlFor="nn" error={form.nickname.trim() ? undefined : "Vui lòng nhập tên"}><Input id="nn" value={form.nickname} maxLength={40} onChange={(e) => setForm({ ...form, nickname: e.target.value })} /></Field>
            <Field label="Khu vườn" htmlFor="gd">
              <Select value={form.gardenId} onValueChange={(v) => setForm({ ...form, gardenId: v })}>
                <SelectTrigger id="gd" className="h-11 rounded-[10px]"><SelectValue /></SelectTrigger>
                <SelectContent>{gardens.map((g) => <SelectItem key={g.id} value={g.id}>{g.name}</SelectItem>)}</SelectContent>
              </Select>
            </Field>
            <Field label="Vị trí" htmlFor="lc" error={form.location.trim() ? undefined : "Vui lòng nhập vị trí"}><Input id="lc" value={form.location} onChange={(e) => setForm({ ...form, location: e.target.value })} /></Field>
            <div className="flex flex-wrap gap-2">{existingLocations.map((l) => <button key={l} onClick={() => setForm({ ...form, location: l })} className="rounded-full border bg-card px-3 py-1 text-xs hover:border-leaf">{l}</button>)}</div>
          </div>
          <DialogFooter>
            <Button variant="ghost" onClick={() => setEditOpen(false)}>Hủy</Button>
            <Button
              disabled={!form.nickname.trim() || !form.location.trim() || update.isPending}
              onClick={async () => {
                await update.mutateAsync({
                  id: plant.id,
                  patch: {
                    nickname: form.nickname.trim(),
                    location: form.location.trim(),
                    gardenId: form.gardenId,
                    image: form.image.trim() || plant.image,
                  },
                });
                toast.success("Đã cập nhật cây");
                setEditOpen(false);
                if (form.gardenId !== gardenId) router.push(`/garden/${form.gardenId}/plants/${plant.id}`);
              }}
            >Lưu</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
      <ConfirmDialog
        open={delOpen}
        onOpenChange={setDelOpen}
        destructive
        loading={remove.isPending}
        title={`Xóa ${plant.nickname}?`}
        description="Ba lịch chăm sóc và toàn bộ nhật ký của cây sẽ bị xóa vĩnh viễn."
        confirmLabel="Xóa cây"
        onConfirm={async () => {
          await remove.mutateAsync(plant.id);
          toast.success("Đã xóa cây");
          router.push(`/garden/${gardenId}`);
        }}
      />
    </PageContainer>
  );
}
