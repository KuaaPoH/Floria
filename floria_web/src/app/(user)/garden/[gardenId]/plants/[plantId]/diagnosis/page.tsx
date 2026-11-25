"use client";

import { useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { AlertTriangle, ArrowLeft, Camera, CheckCircle2, ClipboardPlus, Flag, Lightbulb, Loader2, MessageCircle, RotateCw, ShieldCheck, Stethoscope, Sun } from "lucide-react";
import { toast } from "sonner";
import { ReportScanDialog } from "@/components/ai/ReportScanDialog";
import { ScanUploader } from "@/components/ai/ScanUploader";
import { DiseaseSeverityBadge } from "@/components/botanical";
import { ConfirmDialog } from "@/components/layout/ConfirmDialog";
import { DemoNotice } from "@/components/layout/DemoBadge";
import { PageContainer } from "@/components/layout/PageContainer";
import { EmptyState, ErrorState, LoadingState } from "@/components/layout/states";
import { Button } from "@/components/ui/button";
import { Progress } from "@/components/ui/progress";
import { isMock } from "@/config/env";
import { useApplyDiagnosis, useDiseases, usePlants, useSpecies } from "@/hooks/queries";
import { percent } from "@/lib/format";
import { cn } from "@/lib/utils";
import { findDisease } from "@/mocks/user/diseases";
import { findPlantInfoOrFallback } from "@/mocks/user/plants-info";
import { scanService, type DiagnoseResponse } from "@/services/scan.service";

type Phase = "idle" | "uploading" | "analyzing" | "result" | "error";

export default function DiagnosisPage() {
  const { gardenId, plantId } = useParams<{ gardenId: string; plantId: string }>();
  const plantsQ = usePlants();
  const { data: speciesList = [] } = useSpecies();
  const { data: diseasesList = [] } = useDiseases();
  const apply = useApplyDiagnosis();
  const [image, setImage] = useState<string | null>(null);
  const [phase, setPhase] = useState<Phase>("idle");
  const [result, setResult] = useState<DiagnoseResponse | null>(null);
  const [error, setError] = useState("");
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [applied, setApplied] = useState(false);
  const [reportOpen, setReportOpen] = useState(false);
  const plant = plantsQ.data?.find((p) => p.id === plantId);

  if (plantsQ.isLoading) return <LoadingState className="min-h-[60vh]" />;
  if (plantsQ.isError) return <PageContainer><ErrorState onRetry={() => plantsQ.refetch()} /></PageContainer>;
  if (!plant) return <PageContainer><EmptyState title="Không tìm thấy cây" action={<Button asChild><Link href="/garden">Về khu vườn</Link></Button>} /></PageContainer>;
  const info =
    speciesList.find((s) => s.id.toLowerCase() === plant.speciesId.toLowerCase()) ??
    (isMock()
      ? findPlantInfoOrFallback(plant.speciesId, plant.nickname, plant.image)
      : { commonName: plant.nickname, wateringDays: 5 });

  const run = async () => {
    if (!image) return;
    setPhase("uploading");
    setError("");
    setApplied(false);
    try {
      await new Promise((r) => setTimeout(r, 500));
      setPhase("analyzing");
      const r = await scanService.diagnose(plant.id, image);
      setResult(r);
      setPhase("result");
    } catch (e) {
      setError((e as Error).message === "timeout" ? "Máy chủ phản hồi quá lâu. Vui lòng thử lại." : (e as Error).message || "Không thể phân tích ảnh.");
      setPhase("error");
    }
  };
  const reset = () => {
    setImage(null);
    setResult(null);
    setPhase("idle");
  };

  const normKey = (s: string) => s.trim().toLowerCase().replace(/[_\s]+/g, "-");
  const disease = result
    ? (diseasesList.find((d) => normKey(d.id) === normKey(result.diseaseId)) ??
        (isMock() ? findDisease(result.diseaseId) : undefined) ?? {
          id: result.diseaseId,
          name: result.diseaseId,
          nameEn: result.diseaseId,
          isHealthy: result.diseaseId.toLowerCase() === "healthy",
          severity: "medium" as const,
          agent: "Đang cập nhật thông tin tác nhân gây bệnh.",
          mechanism: "Đang cập nhật cơ chế gây bệnh.",
          outbreakConditions: "Đang cập nhật điều kiện bùng phát.",
          symptoms: `Phát hiện dấu hiệu bất thường trên lá (${result.diseaseId}).`,
          prevention: ["Theo dõi độ ẩm giá thể và độ thông thoáng."],
          treatment: ["Cách ly cây nếu cần, cắt bỏ phần lá bị tổn thương và hỏi thêm Trợ lý Floria."],
          relatedProductIds: [],
        })
    : null;
  const sevTone = disease?.severity === "high" ? "border-danger/40 bg-danger-soft/50" : disease?.severity === "medium" ? "border-warning/40 bg-warning-soft/50" : disease?.severity === "low" ? "border-info/30 bg-info-soft/50" : "border-success/30 bg-success-soft/50";

  return (
    <PageContainer className="max-w-6xl">
      <Button asChild variant="ghost" size="sm" className="mb-6"><Link href={`/garden/${gardenId}/plants/${plantId}`}><ArrowLeft /> {plant.nickname}</Link></Button>
      <div className="mb-8 flex items-center gap-4">
        <img src={plant.image} alt="" className="size-16 rounded-2xl object-cover" />
        <div>
          <p className="eyebrow">Chẩn đoán bệnh lá</p>
          <h1 className="text-3xl font-bold">Kiểm tra sức khỏe {plant.nickname}</h1>
          <p className="text-sm text-muted-foreground">{info.commonName} · {plant.location}</p>
        </div>
      </div>

      {phase !== "result" ? (
        <div className="grid gap-8 lg:grid-cols-[1.3fr_1fr]">
          <div className="space-y-4">
            <ScanUploader value={image} onChange={setImage} scanning={phase === "uploading" || phase === "analyzing"} hint="Chụp cận cảnh phần lá có dấu hiệu bất thường" />
            {(phase === "uploading" || phase === "analyzing") && (
              <div className="rounded-2xl border bg-card p-4">
                <div className="flex items-center gap-2 text-sm font-semibold"><Loader2 className="size-4 animate-spin text-leaf" />{phase === "uploading" ? "Đang tải ảnh…" : "Đang phân tích mô lá…"}</div>
                <Progress value={phase === "uploading" ? 30 : 75} className="mt-3 h-1.5" />
              </div>
            )}
            {phase === "error" && (
              <div className="flex items-center justify-between gap-3 rounded-2xl border border-danger/30 bg-danger-soft/50 p-4 text-sm">
                <span className="flex items-center gap-2 text-danger"><AlertTriangle className="size-4" />{error}</span>
                <Button size="sm" variant="outline" onClick={run}><RotateCw /> Thử lại</Button>
              </div>
            )}
            <Button size="lg" className="w-full" disabled={!image || phase === "uploading" || phase === "analyzing"} onClick={run}><Stethoscope /> Bắt đầu chẩn đoán</Button>
          </div>
          <aside className="rounded-3xl bg-mint/50 p-6">
            <h2 className="flex items-center gap-2 font-semibold"><Lightbulb className="size-4 text-leaf" /> Hướng dẫn chụp ảnh lá</h2>
            <ul className="mt-4 space-y-4 text-sm">
              {[
                { icon: Camera, t: "Chụp cận một lá", d: "Lá chiếm phần lớn khung hình, lấy nét vào vùng bị bệnh." },
                { icon: Sun, t: "Đủ ánh sáng tự nhiên", d: "Tránh đèn vàng và bóng đổ che vết bệnh." },
                { icon: ShieldCheck, t: "Mặt trên và mặt dưới", d: "Nhiều bệnh như gỉ sắt hiện rõ ở mặt dưới lá." },
              ].map((x) => (
                <li key={x.t} className="flex gap-3"><span className="grid size-9 shrink-0 place-items-center rounded-xl bg-card text-leaf"><x.icon className="size-4" /></span><span><b>{x.t}</b><span className="block text-muted-foreground">{x.d}</span></span></li>
              ))}
            </ul>
          </aside>
        </div>
      ) : result && !result.is_valid_plant ? (
        <div className="mx-auto max-w-lg text-center">
          <img src={result.image} alt="Ảnh đã quét" className="mx-auto aspect-[4/3] w-full rounded-3xl object-cover" />
          <div className="mt-5 rounded-3xl border border-warning/40 bg-warning-soft/60 p-5">
            <AlertTriangle className="mx-auto size-6 text-warning" />
            <p className="mt-2 font-semibold">Ảnh không giống lá cây</p>
            <p className="mt-1 text-sm text-muted-foreground">Không thể chẩn đoán từ ảnh này. Hãy chụp cận cảnh lá cây với đủ ánh sáng.</p>
          </div>
          <Button className="mt-5" onClick={reset}><Camera /> Chụp lại ảnh khác</Button>
        </div>
      ) : disease && result ? (
        <div className="space-y-8">
          <div className="grid gap-6 lg:grid-cols-[0.9fr_1.1fr]">
            <img src={result.image} alt="Ảnh lá đã chẩn đoán" className="aspect-square w-full rounded-3xl object-cover shadow-card" />
            <div className={cn("flex flex-col rounded-3xl border p-6", sevTone)}>
              <div className="flex flex-wrap items-center gap-2"><DiseaseSeverityBadge severity={disease.severity} /><span className="text-xs text-muted-foreground">Mức độ nguy hại</span></div>
              <h2 className="mt-3 text-3xl font-bold">{disease.name}</h2>
              <p className="text-sm italic text-muted-foreground">{disease.nameEn}</p>
              <div className="mt-5">
                <div className="flex justify-between text-sm"><span>Độ tin cậy</span><b>{percent(result.confidence)}</b></div>
                <Progress value={result.confidence * 100} className="mt-2 h-2" />
              </div>
              <p className="mt-5 text-sm leading-relaxed"><b>Triệu chứng:</b> {disease.symptoms}</p>
              {isMock() && <DemoNotice className="mt-5">Kết quả mô phỏng trong chế độ demo — kết nối POST /api/diagnose-disease để chẩn đoán thật.</DemoNotice>}
              <div className="mt-auto flex flex-wrap gap-2 pt-6">
                {applied ? (
                  <span className="inline-flex items-center gap-2 rounded-xl bg-success-soft px-4 py-2.5 text-sm font-semibold text-success"><CheckCircle2 className="size-4" /> Đã cập nhật bệnh án</span>
                ) : (
                  <Button size="lg" onClick={() => setConfirmOpen(true)}><ClipboardPlus /> Cập nhật bệnh án</Button>
                )}
                <Button asChild size="lg" variant="outline">
                  <Link
                    href={`/assistant?q=${encodeURIComponent(
                      `Cây ${plant.nickname} (${info.commonName}) đặt ở ${plant.location} vừa được chẩn đoán: ${disease.name} (độ tin cậy ${percent(result.confidence)}). Hãy tư vấn cách chăm sóc và xử lý chi tiết cho tôi.`,
                    )}`}
                  >
                    <MessageCircle /> Hỏi Trợ lý Floria
                  </Link>
                </Button>
                <Button size="lg" variant="outline" onClick={reset}><RotateCw /> Quét ảnh khác</Button>
                <Button size="lg" variant="ghost" onClick={() => setReportOpen(true)}><Flag /> Báo cáo</Button>
              </div>
            </div>
          </div>

          {!disease.isHealthy && (
            <section className="rounded-3xl border bg-card p-6 md:p-8">
              <h3 className="text-xl font-semibold">Hồ sơ bệnh học</h3>
              <dl className="mt-5 grid gap-5 md:grid-cols-3">
                <div><dt className="eyebrow">Tác nhân</dt><dd className="mt-1 text-sm">{disease.agent}</dd></div>
                <div><dt className="eyebrow">Cơ chế gây bệnh</dt><dd className="mt-1 text-sm">{disease.mechanism}</dd></div>
                <div><dt className="eyebrow">Điều kiện bùng phát</dt><dd className="mt-1 text-sm">{disease.outbreakConditions}</dd></div>
              </dl>
              <div className="mt-6 grid gap-5 md:grid-cols-2">
                <div className="rounded-2xl bg-mint/50 p-5">
                  <p className="font-semibold">Phòng ngừa</p>
                  <ul className="mt-2 list-disc space-y-1 pl-5 text-sm">{disease.prevention.map((x) => <li key={x}>{x}</li>)}</ul>
                </div>
                <div className="rounded-2xl bg-warning-soft/50 p-5">
                  <p className="font-semibold">Hướng xử lý</p>
                  <ol className="mt-2 list-decimal space-y-1 pl-5 text-sm">{disease.treatment.map((x) => <li key={x}>{x}</li>)}</ol>
                </div>
              </div>
            </section>
          )}
        </div>
      ) : null}

      <ConfirmDialog
        open={confirmOpen}
        onOpenChange={setConfirmOpen}
        loading={apply.isPending}
        title="Cập nhật bệnh án cho cây?"
        description={disease && <span>Trạng thái sức khỏe của <b>{plant.nickname}</b> sẽ được cập nhật theo kết quả <b>{disease.name}</b>, và một trang nhật ký sức khỏe kèm ảnh lá sẽ được thêm vào.</span>}
        confirmLabel="Cập nhật"
        onConfirm={async () => {
          try {
            await apply.mutateAsync(result!.scanId);
            setApplied(true);
            setConfirmOpen(false);
            toast.success("Đã cập nhật bệnh án và ghi nhật ký");
          } catch (e) {
            toast.error((e as Error).message);
          }
        }}
      />

      {result && (
        <ReportScanDialog
          open={reportOpen}
          onOpenChange={setReportOpen}
          predictedLabel={disease?.id ?? result.diseaseId}
          predictedNameVi={disease?.name ?? result.diseaseId}
          confidence={result.confidence}
          isValidPlant={result.is_valid_plant}
          isDiseaseScan
          imageUrl={result.image}
        />
      )}
    </PageContainer>
  );
}
