"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import {
  AlertTriangle,
  ArrowLeft,
  ArrowRight,
  Check,
  CheckCircle2,
  Droplets,
  Flag,
  HeartPulse,
  Loader2,
  Minus,
  Plus,
  ShieldCheck,
  Sparkles,
  Sprout,
  Sun,
  Wand2,
} from "lucide-react";
import { toast } from "sonner";
import { ReportScanDialog } from "@/components/ai/ReportScanDialog";
import { ScanUploader } from "@/components/ai/ScanUploader";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Field } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { useGardens, usePlantMutations, useSpecies } from "@/hooks/queries";
import { useT } from "@/i18n";
import { common } from "@/i18n/common";
import { ENV_LABEL } from "@/i18n/labels";
import { percent } from "@/lib/format";
import { cn } from "@/lib/utils";
import { findPlantInfoOrFallback, getAllPlantsInfo, slugifySpecies } from "@/mocks/user/plants-info";
import { scanService, type HintIdentifyResponse } from "@/services/scan.service";
import { uploadService } from "@/services/upload.service";
import type { PlantInfo } from "@/types/user";

type Step = 1 | 2 | 3;
type HealthOption = "Khỏe mạnh" | "Cần chú ý" | "Đang phục hồi";

const HEALTH_OPTIONS: { value: HealthOption; activeClass: string }[] = [
  { value: "Khỏe mạnh", activeClass: "border-emerald-600 bg-emerald-600 text-white" },
  { value: "Cần chú ý", activeClass: "border-amber-600 bg-amber-600 text-white" },
  { value: "Đang phục hồi", activeClass: "border-blue-600 bg-blue-600 text-white" },
];

export function AddPlantWizard({
  open,
  onOpenChange,
  defaultGardenId,
  presetSpeciesId,
  presetImage,
}: {
  open: boolean;
  onOpenChange: (o: boolean) => void;
  defaultGardenId?: string;
  presetSpeciesId?: string;
  presetImage?: string;
}) {
  const t = useT(common);
  const router = useRouter();
  const { data: gardens = [] } = useGardens();
  const { data: speciesData } = useSpecies();
  const speciesList = useMemo(() => speciesData ?? getAllPlantsInfo(), [speciesData]);
  const { add } = usePlantMutations();

  const [step, setStep] = useState<Step>(1);
  const [image, setImage] = useState<string | null>(null);
  const [description, setDescription] = useState("");
  const [identifying, setIdentifying] = useState(false);
  const [result, setResult] = useState<HintIdentifyResponse | null>(null);
  const [speciesId, setSpeciesId] = useState<string | null>(null);
  const [gardenId, setGardenId] = useState<string>("");
  const [location, setLocation] = useState("");
  const [nickname, setNickname] = useState("");

  // Thiết lập chăm sóc giống App
  const [healthStatus, setHealthStatus] = useState<HealthOption>("Khỏe mạnh");
  const [timesPerWeek, setTimesPerWeek] = useState<number>(2);
  const [enableFertilizer, setEnableFertilizer] = useState<boolean>(true);
  const [fertilizeDays, setFertilizeDays] = useState<number>(20);
  const [checkPestDays, setCheckPestDays] = useState<number>(3);
  const [careNotes, setCareNotes] = useState<string>("");
  const [reportOpen, setReportOpen] = useState(false);

  // Tra cứu thông tin & ảnh chuẩn từ Từ điển cây Admin (plants_info)
  const resolveSpecies = useMemo(() => {
    return (id: string | null | undefined): PlantInfo | undefined => {
      if (!id) return undefined;
      const slug = slugifySpecies(id);
      const fromAdmin = speciesList.find(
        (p) =>
          p.id.toLowerCase() === id.toLowerCase() ||
          slugifySpecies(p.scientificName) === slug ||
          slugifySpecies(p.id) === slug,
      );
      return fromAdmin ?? findPlantInfoOrFallback(id);
    };
  }, [speciesList]);

  useEffect(() => {
    if (!open) return;
    setStep(presetSpeciesId ? 2 : 1);
    setImage(presetImage ?? null);
    setDescription("");
    setResult(null);
    setSpeciesId(presetSpeciesId ?? null);
    setGardenId(defaultGardenId ?? "");
    setLocation("");
    setNickname("");
    setHealthStatus("Khỏe mạnh");
    setTimesPerWeek(2);
    setEnableFertilizer(true);
    setFertilizeDays(20);
    setCheckPestDays(3);
    setCareNotes("");
  }, [open, presetSpeciesId, presetImage, defaultGardenId]);

  useEffect(() => {
    if (!gardenId && gardens[0]) setGardenId(defaultGardenId ?? gardens[0].id);
  }, [gardens, gardenId, defaultGardenId]);

  const info = resolveSpecies(speciesId);
  const garden = gardens.find((g) => g.id === gardenId);

  // Đồng bộ tần suất tưới khuyến nghị khi đổi loài cây
  useEffect(() => {
    if (!info) return;
    const recDays = Math.max(1, info.wateringDays || 5);
    setTimesPerWeek(Math.min(14, Math.max(1, Math.round(7 / recDays))));
    setFertilizeDays(Math.min(60, Math.max(7, info.fertilizingDays || 20)));
    setCheckPestDays(Math.min(14, Math.max(1, info.inspectionDays || 3)));
  }, [info]);

  const waterIntervalDays = Math.min(14, Math.max(1, Math.round(7 / timesPerWeek)));

  const identify = async () => {
    if (!image && !description.trim()) {
      toast.error("Hãy tải ảnh hoặc nhập miêu tả đặc điểm cây.");
      return;
    }
    setIdentifying(true);
    try {
      const r = await scanService.identifyWithHint({ image, description });
      setResult(r);
      setSpeciesId(r.speciesId);
      if (r.speciesId) {
        const matched = resolveSpecies(r.speciesId);
        toast.success(`Đã nhận diện: ${matched?.commonName ?? r.speciesId}`);
        if (description.trim()) setCareNotes(description.trim());
        setStep(2);
      }
    } catch (e) {
      toast.error((e as Error).message || "Không thể nhận diện lúc này.");
    } finally {
      setIdentifying(false);
    }
  };

  const save = async () => {
    if (!info || !garden || !location.trim()) return;
    let finalImage = image ?? info.image;
    if (finalImage.startsWith("data:")) {
      try {
        finalImage = await uploadService.ensureUploadedUrl(finalImage, "plants");
      } catch {
        toast.error("Tải ảnh lên Cloudinary thất bại, dùng ảnh từ điển của loài.");
        finalImage = info.image;
      }
    }
    const p = await add.mutateAsync({
      gardenId: garden.id,
      speciesId: info.id,
      nickname: nickname.trim() || info.commonName,
      location: location.trim(),
      image: finalImage,
      healthStatus,
      waterFrequencyDays: waterIntervalDays,
      fertilizeFrequencyDays: fertilizeDays,
      fertilizeEnabled: enableFertilizer,
      checkPestFrequencyDays: checkPestDays,
      notes: careNotes.trim(),
    });
    toast.success(`Đã thêm ${p.nickname} vào ${garden.name}`, {
      description: "Lịch chăm sóc đã được thiết lập theo tùy chỉnh của bạn.",
    });
    onOpenChange(false);
    router.push(`/garden/${garden.id}/plants/${p.id}`);
  };

  const topSuggestions = useMemo(() => {
    if (!result?.speciesId) return [];
    const list = [{ speciesId: result.speciesId, confidence: result.confidence }, ...result.alternatives];
    const seen = new Set<string>();
    return list
      .filter((item) => {
        if (!item.speciesId || seen.has(item.speciesId)) return false;
        seen.add(item.speciesId);
        return true;
      })
      .slice(0, 3);
  }, [result]);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[92vh] w-[calc(100vw-1.5rem)] max-w-2xl overflow-y-auto overflow-x-hidden rounded-3xl p-5 sm:p-6">
        <DialogHeader>
          <DialogTitle>Thêm cây vào vườn</DialogTitle>
          <ol className="mt-3 flex flex-wrap items-center gap-2 text-xs font-semibold">
            {["Nhận diện", "Thiết lập & Vị trí", "Xác nhận"].map((label, i) => {
              const n = (i + 1) as Step;
              return (
                <li key={label} className="flex items-center gap-2">
                  <span
                    className={cn(
                      "grid size-6 shrink-0 place-items-center rounded-full",
                      step > n
                        ? "bg-leaf text-primary-foreground"
                        : step === n
                          ? "bg-forest text-forest-foreground"
                          : "bg-muted text-muted-foreground",
                    )}
                  >
                    {step > n ? <Check className="size-3.5" /> : n}
                  </span>
                  <span className={step === n ? "text-foreground" : "text-muted-foreground"}>{label}</span>
                  {i < 2 && <span className="h-px w-5 bg-border" />}
                </li>
              );
            })}
          </ol>
        </DialogHeader>

        {step === 1 && (
          <div className="min-w-0 space-y-4">
            <ScanUploader
              value={image}
              onChange={(v) => {
                setImage(v);
                setResult(null);
              }}
              scanning={identifying}
              hint="Ảnh rõ lá và thân giúp nhận diện chính xác hơn"
            />
            <Field label="Miêu tả đặc điểm" htmlFor="desc">
              <Textarea
                id="desc"
                rows={2}
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Lá to, xẻ thùy, thân leo, có đốm trắng…"
              />
            </Field>
            {result && !result.speciesId && (
              <div className="rounded-2xl border bg-mint/40 p-4">
                <p className="flex items-center gap-2 text-sm text-warning break-words">
                  <AlertTriangle className="size-4 shrink-0" /> {result.note}
                </p>
              </div>
            )}
            <Button size="lg" className="w-full" onClick={identify} disabled={identifying}>
              {identifying ? <Loader2 className="animate-spin" /> : <Wand2 />} Nhận diện
            </Button>
          </div>
        )}

        {step === 2 && info && (
          <div className="min-w-0 space-y-4">
            {/* Thông tin loài cây đã nhận diện */}
            <div className="flex items-start gap-3 rounded-2xl bg-mint/50 p-3.5">
              <img src={image ?? info.image} alt={info.commonName} className="size-16 shrink-0 rounded-xl object-cover" />
              <div className="min-w-0 flex-1">
                <p className="font-semibold leading-snug break-words">{info.commonName}</p>
                <p className="text-xs italic text-muted-foreground break-words">{info.scientificName}</p>
                {result?.note && (
                  <p className="mt-1 text-[11px] leading-relaxed text-leaf break-words">{result.note}</p>
                )}
              </div>
            </div>

            {/* Chỉ số đặc tính cây giống App (Ánh sáng · Tưới nước · Chăm sóc) */}
            <div className="grid grid-cols-1 gap-2 sm:grid-cols-3">
              <div className="rounded-2xl border bg-card p-3">
                <p className="flex items-center gap-1.5 text-[11px] font-semibold text-amber-600">
                  <Sun className="size-3.5 shrink-0" /> Ánh sáng
                </p>
                <p className="mt-1 text-xs font-medium break-words">{info.light}</p>
              </div>
              <div className="rounded-2xl border bg-card p-3">
                <p className="flex items-center gap-1.5 text-[11px] font-semibold text-sky-600">
                  <Droplets className="size-3.5 shrink-0" /> Tưới nước
                </p>
                <p className="mt-1 text-xs font-medium break-words">{info.water}</p>
              </div>
              <div className="rounded-2xl border bg-card p-3">
                <p className="flex items-center gap-1.5 text-[11px] font-semibold text-emerald-600">
                  <Sprout className="size-3.5 shrink-0" /> Chăm sóc
                </p>
                <p className="mt-1 text-xs font-medium break-words">{info.difficulty ?? "Trung bình"}</p>
              </div>
            </div>

            {/* Gợi ý khác từ hệ thống (Top 3 dùng ảnh từ Từ điển cây Admin) */}
            {topSuggestions.length > 0 && (
              <div className="rounded-2xl border bg-muted/30 p-3">
                <p className="mb-2 flex items-center gap-1.5 text-xs font-semibold text-muted-foreground">
                  <Sparkles className="size-3.5 shrink-0 text-leaf" /> Gợi ý khác từ hệ thống:
                </p>
                <div className="grid grid-cols-1 gap-2 sm:grid-cols-3">
                  {topSuggestions.map((pr) => {
                    const s = resolveSpecies(pr.speciesId) ?? findPlantInfoOrFallback(pr.speciesId);
                    const active = speciesId === pr.speciesId;
                    return (
                      <button
                        key={pr.speciesId}
                        type="button"
                        onClick={() => setSpeciesId(pr.speciesId)}
                        className={cn(
                          "flex min-w-0 items-center gap-2 rounded-xl border bg-card p-2 text-left transition-all",
                          active ? "border-leaf ring-2 ring-leaf/30" : "hover:border-leaf/50",
                        )}
                      >
                        <img src={s.image} alt={s.commonName} className="size-10 shrink-0 rounded-lg object-cover" />
                        <span className="min-w-0 flex-1">
                          <span className="block truncate text-xs font-semibold">{s.commonName}</span>
                          <span className="block text-[11px] text-muted-foreground">{percent(pr.confidence)}</span>
                        </span>
                      </button>
                    );
                  })}
                </div>
              </div>
            )}

            {/* Chỉ hiển thị chọn khu vườn khi chưa đi từ một khu vườn cụ thể */}
            {!defaultGardenId && gardens.length > 0 && (
              <Field label="Khu vườn" htmlFor="garden">
                <Select value={gardenId} onValueChange={setGardenId}>
                  <SelectTrigger id="garden" className="h-11 rounded-[10px]"><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {gardens.map((g) => (
                      <SelectItem key={g.id} value={g.id}>
                        {g.name} · {t(ENV_LABEL[g.environment])}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </Field>
            )}

            {/* Tình trạng sức khỏe ban đầu giống App */}
            <div>
              <p className="mb-2 flex items-center gap-1.5 text-sm font-semibold">
                <HeartPulse className="size-4 text-leaf" /> Tình trạng sức khỏe ban đầu
              </p>
              <div className="flex flex-wrap gap-2">
                {HEALTH_OPTIONS.map((opt) => {
                  const active = healthStatus === opt.value;
                  return (
                    <button
                      key={opt.value}
                      type="button"
                      onClick={() => setHealthStatus(opt.value)}
                      className={cn(
                        "rounded-full border px-3.5 py-1.5 text-xs font-semibold transition-all",
                        active ? opt.activeClass : "bg-card text-foreground hover:border-leaf/50",
                      )}
                    >
                      {opt.value}
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Vị trí & Tên riêng */}
            <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
              <Field label="Vị trí đặt cây" htmlFor="loc">
                <Input
                  id="loc"
                  value={location}
                  onChange={(e) => setLocation(e.target.value)}
                  placeholder="Ví dụ: Cạnh cửa sổ, Bàn làm việc…"
                />
              </Field>
              <Field label="Tên riêng cho cây (tùy chọn)" htmlFor="nick">
                <Input
                  id="nick"
                  value={nickname}
                  onChange={(e) => setNickname(e.target.value)}
                  placeholder={info.commonName}
                  maxLength={40}
                />
              </Field>
            </div>

            {/* Setup lịch tưới nước: Khuyến nghị & Tùy chỉnh giống App */}
            <div className="space-y-2.5 rounded-2xl border bg-card p-3.5">
              <div className="flex flex-wrap items-center justify-between gap-2">
                <span className="flex items-center gap-1.5 text-sm font-semibold">
                  <Droplets className="size-4 text-sky-600" /> Lịch tưới nước
                </span>
                <span className="rounded-lg bg-mint px-2.5 py-0.5 text-[11px] font-semibold text-forest">
                  Khuyến nghị: {info.water}
                </span>
              </div>
              <div className="flex flex-wrap gap-2">
                {[
                  { label: "1 lần / tuần", val: 1 },
                  { label: "2 lần / tuần", val: 2 },
                  { label: "3 lần / tuần", val: 3 },
                  { label: "Hàng ngày (7 lần)", val: 7 },
                ].map((chip) => (
                  <button
                    key={chip.val}
                    type="button"
                    onClick={() => setTimesPerWeek(chip.val)}
                    className={cn(
                      "rounded-full border px-3 py-1 text-xs font-medium transition-all",
                      timesPerWeek === chip.val
                        ? "border-sky-600 bg-sky-600 text-white"
                        : "bg-muted/40 text-foreground hover:border-sky-400",
                    )}
                  >
                    {chip.label}
                  </button>
                ))}
              </div>
              <div className="flex items-center justify-between gap-3 rounded-xl border bg-muted/30 px-3 py-2">
                <span className="text-xs font-medium text-muted-foreground">
                  Tùy chỉnh: <b className="text-foreground">{timesPerWeek} lần/tuần</b> (~mỗi {waterIntervalDays} ngày)
                </span>
                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    disabled={timesPerWeek <= 1}
                    onClick={() => setTimesPerWeek((v) => Math.max(1, v - 1))}
                    className="grid size-7 place-items-center rounded-full border bg-card text-foreground disabled:opacity-40"
                    aria-label="Giảm số lần tưới"
                  >
                    <Minus className="size-3.5" />
                  </button>
                  <span className="w-5 text-center text-sm font-bold">{timesPerWeek}</span>
                  <button
                    type="button"
                    disabled={timesPerWeek >= 14}
                    onClick={() => setTimesPerWeek((v) => Math.min(14, v + 1))}
                    className="grid size-7 place-items-center rounded-full border bg-card text-foreground disabled:opacity-40"
                    aria-label="Tăng số lần tưới"
                  >
                    <Plus className="size-3.5" />
                  </button>
                </div>
              </div>
            </div>

            {/* Yêu cầu bón phân dinh dưỡng (có thanh trượt giống App) */}
            <div className="space-y-2.5 rounded-2xl border bg-card p-3.5">
              <div className="flex flex-wrap items-center justify-between gap-2">
                <span className="text-sm font-semibold">Yêu cầu bón phân dinh dưỡng</span>
                {enableFertilizer && (
                  <span className="rounded-lg bg-amber-100 px-2.5 py-0.5 text-xs font-bold text-amber-800">
                    Mỗi {fertilizeDays} ngày / lần
                  </span>
                )}
              </div>
              <div className="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={() => setEnableFertilizer(true)}
                  className={cn(
                    "rounded-xl border px-3 py-2 text-xs font-semibold transition-all",
                    enableFertilizer
                      ? "border-amber-500 bg-amber-50 text-amber-900"
                      : "bg-muted/30 text-muted-foreground",
                  )}
                >
                  Cần bón phân
                </button>
                <button
                  type="button"
                  onClick={() => setEnableFertilizer(false)}
                  className={cn(
                    "rounded-xl border px-3 py-2 text-xs font-semibold transition-all",
                    !enableFertilizer
                      ? "border-foreground/40 bg-muted text-foreground"
                      : "bg-muted/30 text-muted-foreground",
                  )}
                >
                  Không cần bón
                </button>
              </div>
              {enableFertilizer ? (
                <div className="pt-1">
                  <input
                    type="range"
                    min={7}
                    max={60}
                    step={1}
                    value={fertilizeDays}
                    onChange={(e) => setFertilizeDays(Number(e.target.value))}
                    className="w-full accent-amber-500"
                  />
                  <div className="flex justify-between text-[11px] text-muted-foreground">
                    <span>7 ngày</span>
                    <span>60 ngày</span>
                  </div>
                </div>
              ) : (
                <p className="text-xs italic text-muted-foreground">
                  Tác vụ nhắc bón phân sẽ được tắt khỏi lịch chăm sóc của cây này.
                </p>
              )}
            </div>

            {/* Chu kỳ kiểm tra sâu bệnh & lau lá (có thanh trượt giống App) */}
            <div className="space-y-2 rounded-2xl border bg-card p-3.5">
              <div className="flex flex-wrap items-center justify-between gap-2">
                <span className="flex items-center gap-1.5 text-sm font-semibold">
                  <ShieldCheck className="size-4 text-sky-600" /> Chu kỳ kiểm tra sâu bệnh & lau lá
                </span>
                <span className="rounded-lg bg-sky-100 px-2.5 py-0.5 text-xs font-bold text-sky-800">
                  Mỗi {checkPestDays} ngày / lần
                </span>
              </div>
              <input
                type="range"
                min={1}
                max={14}
                step={1}
                value={checkPestDays}
                onChange={(e) => setCheckPestDays(Number(e.target.value))}
                className="w-full accent-sky-600"
              />
              <div className="flex justify-between text-[11px] text-muted-foreground">
                <span>Mỗi ngày</span>
                <span>14 ngày</span>
              </div>
            </div>

            {/* Ghi chú chăm sóc */}
            <Field label="Ghi chú chăm sóc" htmlFor="care-notes">
              <Textarea
                id="care-notes"
                rows={2}
                value={careNotes}
                onChange={(e) => setCareNotes(e.target.value)}
                placeholder="Ghi chú thêm về đất trồng, ánh sáng, tình trạng lá…"
              />
            </Field>

            <div className="flex flex-wrap items-center justify-between gap-2 pt-2">
              <div className="flex items-center gap-2">
                <Button variant="ghost" onClick={() => setStep(1)}>
                  <ArrowLeft /> {t("back")}
                </Button>
                <Button type="button" variant="outline" size="sm" onClick={() => setReportOpen(true)}>
                  <Flag className="size-3.5" /> Báo cáo
                </Button>
              </div>
              <Button onClick={() => setStep(3)} disabled={!garden || !location.trim()}>
                Xem lại <ArrowRight />
              </Button>
            </div>
          </div>
        )}

        {step === 3 && info && garden && (
          <div className="min-w-0 space-y-4">
            <div className="overflow-hidden rounded-3xl border">
              <div className="grid sm:grid-cols-[180px_1fr]">
                <img src={image ?? info.image} alt={info.commonName} className="aspect-square w-full object-cover sm:h-full" />
                <dl className="grid grid-cols-2 gap-3 p-5 text-sm">
                  <div className="col-span-2">
                    <dt className="text-xs text-muted-foreground">Tên cây</dt>
                    <dd className="text-lg font-semibold break-words">{nickname.trim() || info.commonName}</dd>
                  </div>
                  <div>
                    <dt className="text-xs text-muted-foreground">Loài</dt>
                    <dd className="font-medium break-words">{info.commonName}</dd>
                  </div>
                  <div>
                    <dt className="text-xs text-muted-foreground">Sức khỏe</dt>
                    <dd className="font-medium">{healthStatus}</dd>
                  </div>
                  <div>
                    <dt className="text-xs text-muted-foreground">Vị trí</dt>
                    <dd className="font-medium break-words">{location}</dd>
                  </div>
                  <div>
                    <dt className="text-xs text-muted-foreground">Tưới nước</dt>
                    <dd className="font-medium">{t("everyNDays", { n: waterIntervalDays })}</dd>
                  </div>
                  <div>
                    <dt className="text-xs text-muted-foreground">Bón phân</dt>
                    <dd className="font-medium">
                      {enableFertilizer ? t("everyNDays", { n: fertilizeDays }) : "Không cần bón"}
                    </dd>
                  </div>
                  <div>
                    <dt className="text-xs text-muted-foreground">Kiểm tra lá</dt>
                    <dd className="font-medium">{t("everyNDays", { n: checkPestDays })}</dd>
                  </div>
                  {careNotes.trim() && (
                    <div className="col-span-2">
                      <dt className="text-xs text-muted-foreground">Ghi chú</dt>
                      <dd className="text-xs text-muted-foreground break-words">{careNotes}</dd>
                    </div>
                  )}
                </dl>
              </div>
            </div>
            <p className="flex items-center gap-2 text-sm text-muted-foreground">
              <CheckCircle2 className="size-4 shrink-0 text-leaf" /> Floria sẽ tạo lịch nhắc chăm sóc theo đúng chu kỳ bạn đã chọn.
            </p>
            <div className="flex justify-between gap-2">
              <Button variant="ghost" onClick={() => setStep(2)}>
                <ArrowLeft /> {t("back")}
              </Button>
              <Button size="lg" onClick={save} disabled={add.isPending}>
                {add.isPending && <Loader2 className="animate-spin" />} Lưu vào khu vườn
              </Button>
            </div>
          </div>
        )}
      </DialogContent>
      {info && (
        <ReportScanDialog
          open={reportOpen}
          onOpenChange={setReportOpen}
          predictedLabel={info.scientificName}
          predictedNameVi={info.commonName}
          confidence={result?.confidence ?? null}
          isValidPlant={true}
          isDiseaseScan={false}
          imageUrl={image ?? info.image}
        />
      )}
    </Dialog>
  );
}
