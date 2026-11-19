"use client";

import { useState } from "react";
import { ArrowRight, CheckCircle2, Loader2, Play, ShieldCheck, Sprout, Microscope, XCircle, AlertTriangle, RefreshCw } from "lucide-react";
import { Button } from "@/components/ui/button";
import { ImageUploader } from "@/components/shared/image-uploader";
import { ChartCard } from "@/components/shared/chart-card";
import { DemoBadge } from "@/components/shared/demo-badge";
import { EmptyState } from "@/components/shared/states";
import { useSingleton } from "@/hooks/use-singleton";
import { aiConfigService } from "@/services";
import { DEFAULT_AI_CONFIG } from "@/mocks/ai";
import { IMAGES } from "@/mocks/images";
import { cn } from "@/lib/utils";
import { hashString, simulatePipeline, type PipelineResult, type Prediction } from "./simulate";

type Stage = "idle" | "gate" | "species" | "disease" | "done";

const SAMPLES = [IMAGES.monstera, IMAGES.leafSpot, IMAGES.orchid, IMAGES.mildew];

export function AiSandbox() {
  const cfg = useSingleton(aiConfigService);
  const config = cfg.data ?? DEFAULT_AI_CONFIG;
  const [image, setImage] = useState("");
  const [stage, setStage] = useState<Stage>("idle");
  const [result, setResult] = useState<PipelineResult | null>(null);

  const run = async () => {
    if (!image) return;
    const res = simulatePipeline(hashString(image.slice(-2000)) + image.length, config);
    setResult(null);
    setStage("gate");
    await wait(res.gatekeeper.ms * 8);
    if (!res.gatekeeper.isPlant) {
      setResult(res);
      setStage("done");
      return;
    }
    setStage("species");
    await wait((res.species?.ms ?? 50) * 8);
    setStage("disease");
    await wait((res.disease?.ms ?? 50) * 8);
    setResult(res);
    setStage("done");
  };

  const running = stage !== "idle" && stage !== "done";

  return (
    <div className="space-y-4">
      <div className="flex items-start gap-3 rounded-xl border border-warning/30 bg-warning-soft/60 p-3 text-sm text-warning">
        <AlertTriangle className="mt-0.5 size-4 shrink-0" />
        <p><b>DEMO / SIMULATED</b> — Sandbox đang tạo kết quả mô phỏng có tính xác định, chưa gọi Python AI Engine thật. Không dùng kết quả này để đánh giá mô hình.</p>
      </div>
      <div className="grid gap-4 lg:grid-cols-[minmax(0,420px)_1fr]">
        <ChartCard title="Ảnh đầu vào" description={`Resize ${config.inputSize}×${config.inputSize} · Top-${config.topK} · Ngưỡng ${config.confidenceThreshold}`}>
          <ImageUploader value={image} onChange={(v) => { setImage(v); setResult(null); setStage("idle"); }} />
          <div className="mt-3">
            <p className="mb-2 text-xs text-muted-foreground">Hoặc chọn ảnh mẫu</p>
            <div className="grid grid-cols-4 gap-2">
              {SAMPLES.map((s) => (
                <button key={s} onClick={() => { setImage(s); setResult(null); setStage("idle"); }} className={cn("overflow-hidden rounded-lg ring-2 ring-transparent transition", image === s && "ring-leaf")}>
                  <img src={s} alt="Ảnh mẫu" className="aspect-square w-full object-cover" loading="lazy" />
                </button>
              ))}
            </div>
          </div>
          <div className="mt-4 flex gap-2">
            <Button className="flex-1" onClick={run} disabled={!image || running}>
              {running ? <Loader2 className="animate-spin" /> : <Play />} Chạy pipeline mô phỏng
            </Button>
            {result && <Button variant="outline" onClick={() => { setImage(""); setResult(null); setStage("idle"); }}><RefreshCw /> Ảnh khác</Button>}
          </div>
        </ChartCard>

        <ChartCard title="Kết quả dự đoán" actions={<DemoBadge />}>
          {!result && !running && <EmptyState title="Chưa có kết quả" description="Tải ảnh lên và chạy pipeline để xem dự đoán mô phỏng." />}
          {running && <div className="flex flex-col items-center gap-3 py-16 text-sm text-muted-foreground"><Loader2 className="size-6 animate-spin text-leaf" /> Đang xử lý…</div>}
          {result && !running && (
            <div className="space-y-5">
              <div className={cn("flex items-center gap-3 rounded-xl p-3", result.gatekeeper.isPlant ? "bg-success-soft" : "bg-danger-soft")}>
                {result.gatekeeper.isPlant ? <CheckCircle2 className="size-5 text-success" /> : <XCircle className="size-5 text-danger" />}
                <div className="flex-1 text-sm">
                  <p className="font-semibold">{result.gatekeeper.isPlant ? "Gatekeeper: ảnh chứa cây/lá" : "Gatekeeper: ảnh bị từ chối — không phải cây"}</p>
                  <p className="text-xs text-muted-foreground">Điểm CLIP {result.gatekeeper.score.toFixed(3)} (ngưỡng {config.gatekeeperThreshold})</p>
                </div>
              </div>
              {result.species && <PredList title="Loài cây" icon={Sprout} preds={result.species.top} uncertain={result.species.uncertain} />}
              {result.disease && <PredList title="Tình trạng bệnh" icon={Microscope} preds={result.disease.top} uncertain={result.disease.uncertain} />}
            </div>
          )}
        </ChartCard>
      </div>

      <ChartCard title="Pipeline suy luận" description={result ? `Tổng thời gian mô phỏng: ${result.totalMs} ms` : "CLIP Gatekeeper → Species Recognition → Disease Detection"}>
        <div className="flex flex-col items-stretch gap-3 md:flex-row md:items-center">
          <PipeStep icon={ShieldCheck} name="CLIP Gatekeeper" ms={result?.gatekeeper.ms} state={stepState("gate", stage, result, !!result && !result.gatekeeper.isPlant)} />
          <ArrowRight className="mx-auto hidden size-4 text-muted-foreground md:block" />
          <PipeStep icon={Sprout} name="Species Recognition" ms={result?.species?.ms} state={stepState("species", stage, result, false)} />
          <ArrowRight className="mx-auto hidden size-4 text-muted-foreground md:block" />
          <PipeStep icon={Microscope} name="Disease Detection" ms={result?.disease?.ms} state={stepState("disease", stage, result, false)} />
        </div>
      </ChartCard>
    </div>
  );
}

const wait = (ms: number) => new Promise((r) => setTimeout(r, ms));
const ORDER: Stage[] = ["gate", "species", "disease", "done"];

function stepState(step: Stage, stage: Stage, result: PipelineResult | null, rejected: boolean): "idle" | "running" | "done" | "skipped" | "rejected" {
  if (rejected) return "rejected";
  if (stage === "done" && result) {
    if (step !== "gate" && !result.gatekeeper.isPlant) return "skipped";
    return "done";
  }
  if (stage === step) return "running";
  if (ORDER.indexOf(stage) > ORDER.indexOf(step)) return "done";
  return "idle";
}

function PipeStep({ icon: Icon, name, ms, state }: { icon: typeof Sprout; name: string; ms?: number; state: ReturnType<typeof stepState> }) {
  return (
    <div className={cn("flex flex-1 items-center gap-3 rounded-xl border p-3 transition-colors", state === "running" && "border-leaf bg-accent", state === "done" && "bg-success-soft/60", state === "rejected" && "border-danger/30 bg-danger-soft", state === "skipped" && "opacity-50")}>
      <span className="grid size-9 place-items-center rounded-lg bg-card text-forest shadow-xs">{state === "running" ? <Loader2 className="size-4 animate-spin" /> : <Icon className="size-4" />}</span>
      <div className="flex-1">
        <p className="text-sm font-medium">{name}</p>
        <p className="text-xs text-muted-foreground">{state === "done" && ms ? `${ms} ms` : state === "running" ? "Đang chạy…" : state === "skipped" ? "Bỏ qua" : state === "rejected" ? `Từ chối · ${ms} ms` : "Chờ"}</p>
      </div>
    </div>
  );
}

function PredList({ title, icon: Icon, preds, uncertain }: { title: string; icon: typeof Sprout; preds: Prediction[]; uncertain: boolean }) {
  return (
    <div>
      <div className="mb-2 flex items-center gap-2">
        <Icon className="size-4 text-leaf" />
        <p className="text-sm font-semibold">{title}</p>
        {uncertain && <span className="rounded-md bg-warning-soft px-1.5 py-0.5 text-[11px] font-medium text-warning">Dưới ngưỡng tin cậy</span>}
      </div>
      <ul className="space-y-2">
        {preds.map((p, i) => (
          <li key={p.className}>
            <div className="mb-1 flex justify-between text-sm">
              <span className={cn(i === 0 ? "font-semibold" : "text-muted-foreground")}>{p.label} <span className="font-mono text-[10px] text-muted-foreground">{p.className}</span></span>
              <span className="tabular font-medium">{(p.probability * 100).toFixed(1).replace(".", ",")}%</span>
            </div>
            <div className="h-1.5 overflow-hidden rounded-full bg-muted">
              <div className={cn("h-full rounded-full", i === 0 ? "bg-leaf" : "bg-sage/60")} style={{ width: `${p.probability * 100}%` }} />
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}
