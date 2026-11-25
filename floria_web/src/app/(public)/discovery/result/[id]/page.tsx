"use client";

import { Suspense, useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useParams, useRouter, useSearchParams } from "next/navigation";
import { AlertOctagon, BookOpen, Droplets, Flag, Home, MessageCircle, RotateCw, ScanLine, Sprout, Sun, Thermometer } from "lucide-react";
import { ReportScanDialog } from "@/components/ai/ReportScanDialog";
import { PlantProfileDialog } from "@/components/botanical/PlantProfileDialog";
import { DemoNotice } from "@/components/layout/DemoBadge";
import { PageContainer } from "@/components/layout/PageContainer";
import { EmptyState, ErrorState, LoadingState } from "@/components/layout/states";
import { Button } from "@/components/ui/button";
import { Progress } from "@/components/ui/progress";
import { isMock } from "@/config/env";
import { AddPlantWizard } from "@/features/garden/AddPlantWizard";
import { useScan, useSpecies } from "@/hooks/queries";
import { percent } from "@/lib/format";
import { cn } from "@/lib/utils";
import { findPlantInfoOrFallback, getAllPlantsInfo, slugifySpecies } from "@/mocks/user/plants-info";
import { useAuth } from "@/stores/auth";
import type { GardenEnvironment, LightCondition, PlantInfo } from "@/types/user";

function ResultContent() {
  const { id } = useParams<{ id: string }>();
  const searchParams = useSearchParams();
  const saveParam = searchParams.get("save") === "1" ? "1" : undefined;
  const pickParam = searchParams.get("pick") ?? undefined;
  const router = useRouter();
  const authed = useAuth((s) => s.status === "authenticated");
  const { data: speciesData } = useSpecies();
  const speciesList = useMemo(() => speciesData ?? (isMock() ? getAllPlantsInfo() : []), [speciesData]);
  const { data: scan, isLoading, isError, refetch } = useScan(id);
  const [selected, setSelected] = useState(0);
  const [wizard, setWizard] = useState(false);
  const [reportOpen, setReportOpen] = useState(false);
  const [profileOpen, setProfileOpen] = useState(false);

  const resolveSpecies = useMemo(() => {
    return (pred?: { speciesId: string; nameVi?: string; scientificName?: string; matchedDatabase?: boolean }): PlantInfo => {
      const speciesId = pred?.speciesId ?? "plant";
      const slug = slugifySpecies(speciesId);
      const fromAdmin = speciesList.find(
        (p) =>
          p.id.toLowerCase() === speciesId.toLowerCase() ||
          slugifySpecies(p.scientificName) === slug ||
          slugifySpecies(p.id) === slug,
      );
      if (fromAdmin) return fromAdmin;
      if (pred?.matchedDatabase === false || (pred?.nameVi && !findPlantInfoOrFallback(speciesId).commonName.toLowerCase().includes(pred.nameVi.toLowerCase()))) {
        return {
          id: slug || speciesId,
          commonName: pred.nameVi || pred.scientificName || "Thực vật chưa có trong từ điển",
          commonNameEn: pred.scientificName || "Unknown plant",
          scientificName: pred.scientificName || "Đang cập nhật...",
          family: "Đang cập nhật...",
          image: scan?.image || "/user-assets/plants/monstera.jpg",
          description: "Loài cây này chưa có thông tin chi tiết trong từ điển loài cây của Floria. Bạn có thể gửi Yêu cầu cập nhật để đội ngũ bổ sung.",
          wikiDetail: "Đang cập nhật...",
          origin: "Đang cập nhật...",
          environment: "Đang cập nhật...",
          light: "Đang cập nhật...",
          water: "Đang cập nhật...",
          difficulty: "Đang cập nhật...",
          soil: "Đang cập nhật...",
          temperature: "Đang cập nhật...",
          humidity: "Đang cập nhật...",
          toxicity: null,
          careTips: [],
          wateringDays: 5,
          fertilizingDays: 20,
          inspectionDays: 5,
          idealLight: ["indirect", "bright"] as LightCondition[],
          idealEnvironments: ["indoor", "balcony"] as GardenEnvironment[],
        };
      }
      return findPlantInfoOrFallback(speciesId);
    };
  }, [speciesList, scan?.image]);

  useEffect(() => {
    if (saveParam === "1" && authed && scan?.isValidPlant) setWizard(true);
  }, [saveParam, authed, scan?.isValidPlant]);

  if (isLoading) return <LoadingState className="min-h-[60vh]" />;
  if (isError) return <PageContainer><ErrorState onRetry={() => refetch()} /></PageContainer>;
  if (!scan) return <PageContainer><EmptyState title="Không tìm thấy kết quả quét" action={<Button asChild><Link href="/discovery">Quét cây mới</Link></Button>} /></PageContainer>;

  // Invalid image: show ONLY image, warning, explanation, retake and home. No plant actions at all.
  if (!scan.isValidPlant) {
    return (
      <PageContainer className="max-w-xl text-center">
        <img src={scan.image} alt="Ảnh đã quét" className="mx-auto aspect-[4/3] w-full rounded-3xl object-cover shadow-card" />
        <div className="mt-6 rounded-3xl border border-warning/40 bg-warning-soft/60 p-6">
          <AlertOctagon className="mx-auto size-8 text-warning" />
          <h1 className="mt-3 text-xl font-bold">Ảnh này không phải thực vật</h1>
          <p className="mt-2 text-sm text-muted-foreground">Bộ lọc của Floria không tìm thấy cây trồng trong ảnh. Hãy chụp lại với cây nằm rõ ở giữa khung hình, đủ ánh sáng và không bị che khuất.</p>
        </div>
        <div className="mt-6 flex flex-wrap justify-center gap-3">
          <Button asChild size="lg"><Link href="/discovery"><RotateCw /> Chụp lại ảnh khác</Link></Button>
          <Button asChild size="lg" variant="outline"><Link href="/"><Home /> Về trang chủ</Link></Button>
          <Button size="lg" variant="ghost" onClick={() => setReportOpen(true)}><Flag /> Báo cáo</Button>
        </div>
        <ReportScanDialog
          open={reportOpen}
          onOpenChange={setReportOpen}
          predictedLabel="Không phải cây"
          predictedNameVi="Không phải cây"
          confidence={0}
          isValidPlant={false}
          isDiseaseScan={false}
          imageUrl={scan.image}
        />
      </PageContainer>
    );
  }

  const preds = scan.predictions ?? [];
  const pickIdx = pickParam ? Math.max(0, preds.findIndex((p) => p.speciesId === pickParam)) : selected;
  const current = preds[pickIdx] ?? preds[0];
  const info = resolveSpecies(current);

  const onSave = () => {
    if (!authed) {
      router.push(`/login?redirect=${encodeURIComponent(`/discovery/result/${id}?save=1&pick=${current.speciesId}`)}`);
      return;
    }
    setWizard(true);
  };

  return (
    <PageContainer>
      <div className="grid gap-8 lg:grid-cols-[1fr_1.15fr]">
        <div className="space-y-4">
          <img src={scan.image} alt="Ảnh đầu vào" className="aspect-square w-full rounded-[2rem] object-cover shadow-card" />
          <div>
            <p className="mb-2 text-sm font-semibold">Top 3 dự đoán</p>
            <div className="grid gap-2">
              {preds.map((p, i) => {
                const s = resolveSpecies(p);
                const active = i === pickIdx;
                return (
                  <button key={p.speciesId} onClick={() => { setSelected(i); if (pickParam) router.replace(`/discovery/result/${id}`); }} className={cn("flex items-center gap-3 rounded-2xl border bg-card p-3 text-left transition-all", active ? "border-leaf ring-2 ring-leaf/25" : "hover:border-leaf/40")}>
                    <img src={s.image} alt="" className="size-12 rounded-xl object-cover" />
                    <div className="min-w-0 flex-1">
                      <p className="truncate font-semibold">{s.commonName}</p>
                      <p className="truncate text-xs italic text-muted-foreground">{s.scientificName}</p>
                    </div>
                    <span className={cn("text-sm font-bold", active ? "text-leaf" : "text-muted-foreground")}>{percent(p.confidence)}</span>
                  </button>
                );
              })}
            </div>
          </div>
        </div>
        <div>
          <p className="eyebrow">Kết quả nhận diện</p>
          <h1 className="mt-2 text-4xl font-bold tracking-tight md:text-5xl">{info.commonName}</h1>
          <p className="mt-1 text-lg italic text-muted-foreground">{info.scientificName} · {info.family}</p>
          <div className="mt-5 max-w-sm">
            <div className="flex justify-between text-sm"><span>Độ tin cậy</span><b>{percent(current.confidence)}</b></div>
            <Progress value={current.confidence * 100} className="mt-2 h-2" />
          </div>
          <p className="mt-6 leading-relaxed">{info.description}</p>
          <div className="mt-6 grid gap-3 sm:grid-cols-2">
            {[
              { icon: Sun, l: "Ánh sáng", v: info.light },
              { icon: Droplets, l: "Nước", v: info.water },
              { icon: Thermometer, l: "Nhiệt độ", v: info.temperature },
              { icon: Sprout, l: "Nguồn gốc", v: info.origin },
            ].map((x) => (
              <div key={x.l} className="rounded-2xl border bg-card p-4">
                <p className="flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-leaf"><x.icon className="size-3.5" />{x.l}</p>
                <p className="mt-1.5 text-sm">{x.v}</p>
              </div>
            ))}
          </div>
          {info.toxicity && <p className="mt-4 rounded-2xl bg-warning-soft p-3 text-sm text-warning">Lưu ý độc tính: {info.toxicity}</p>}
          {isMock() && <DemoNotice className="mt-4">Kết quả mô phỏng trong chế độ demo.</DemoNotice>}
          <div className="mt-8 flex flex-wrap gap-2">
            <Button size="lg" onClick={onSave}><Sprout /> Lưu vào vườn</Button>
            <Button size="lg" variant="outline" onClick={() => setProfileOpen(true)}><BookOpen /> Cẩm nang liên quan</Button>
            <Button asChild size="lg" variant="outline"><Link href={`/assistant?q=${encodeURIComponent(`Cách chăm sóc ${info.commonName} (${info.scientificName})?`)}`}><MessageCircle /> Hỏi Trợ lý Floria</Link></Button>
            <Button asChild size="lg" variant="ghost"><Link href="/discovery"><ScanLine /> Quét ảnh khác</Link></Button>
            <Button size="lg" variant="ghost" onClick={() => setReportOpen(true)}><Flag /> Báo cáo</Button>
          </div>
        </div>
      </div>
      <PlantProfileDialog open={profileOpen} onOpenChange={setProfileOpen} info={info} onSaveToGarden={onSave} />
      {authed && <AddPlantWizard open={wizard} onOpenChange={setWizard} presetSpeciesId={info.id} presetImage={scan.image} />}
      <ReportScanDialog
        open={reportOpen}
        onOpenChange={setReportOpen}
        predictedLabel={info.scientificName}
        predictedNameVi={info.commonName}
        confidence={current?.confidence ?? null}
        isValidPlant={scan.isValidPlant}
        isDiseaseScan={false}
        imageUrl={scan.image}
      />
    </PageContainer>
  );
}

export default function DiscoveryResultPage() {
  return (
    <Suspense fallback={<LoadingState className="min-h-[60vh]" />}>
      <ResultContent />
    </Suspense>
  );
}
