"use client";

import { useState } from "react";
import {
  ArrowRight,
  CheckCircle2,
  Loader2,
  Microscope,
  Play,
  RefreshCw,
  ShieldCheck,
  Sprout,
  XCircle,
  AlertCircle,
} from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { ImageUploader } from "@/components/shared/image-uploader";
import { ChartCard } from "@/components/shared/chart-card";
import { EmptyState } from "@/components/shared/states";
import { StatusBadge } from "@/components/shared/status-badge";
import { getFirebaseIdToken } from "@/lib/firebase-client";
import { IMAGES } from "@/mocks/images";
import { cn } from "@/lib/utils";

type Mode = "species" | "disease";

interface SandboxResult {
  mode: Mode;
  model_used?: string;
  prediction?: string;
  prediction_vi?: string;
  confidence?: number;
  is_valid_plant?: boolean;
  is_in_database?: boolean;
  clip_plant_prob?: number | null;
  clip_non_plant_prob?: number | null;
  latency_ms?: number;
  roundTripMs?: number;
  severity?: string;
  cause?: string;
  treatment_steps?: string[];
  message?: string;
  top_3?: Array<{ class: string; name_vi?: string; confidence: number }>;
}

const SAMPLES = [
  { url: IMAGES.monstera, label: "Trầu bà" },
  { url: IMAGES.leafSpot, label: "Đốm lá" },
  { url: IMAGES.orchid, label: "Lan hồ điệp" },
  { url: IMAGES.mildew, label: "Phấn trắng" },
];

export function AiSandbox() {
  const [mode, setMode] = useState<Mode>("species");
  const [image, setImage] = useState("");
  const [running, setRunning] = useState(false);
  const [result, setResult] = useState<SandboxResult | null>(null);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const run = async () => {
    if (!image) return;
    setRunning(true);
    setResult(null);
    setErrorMsg(null);

    try {
      const formData = new FormData();
      formData.append("mode", mode);

      if (image.startsWith("data:")) {
        const blobRes = await fetch(image);
        const blob = await blobRes.blob();
        formData.append("file", blob, "upload.jpg");
      } else {
        formData.append("imageUrl", image);
      }

      const token = await getFirebaseIdToken();
      const res = await fetch("/api/admin/ai/sandbox", {
        method: "POST",
        headers: token ? { Authorization: `Bearer ${token}` } : undefined,
        body: formData,
      });

      const data = (await res.json()) as SandboxResult & { error?: string };
      if (!res.ok) {
        throw new Error(data.error || `Lỗi máy chủ (${res.status})`);
      }

      setResult(data);
    } catch (err) {
      const msg = err instanceof Error ? err.message : "Không thể chạy kiểm thử AI Engine";
      setErrorMsg(msg);
      toast.error(msg);
    } finally {
      setRunning(false);
    }
  };

  return (
    <div className="space-y-4">
      <div className="grid gap-4 lg:grid-cols-[minmax(0,420px)_1fr]">
        <ChartCard
          title="Ảnh đầu vào"
          description="Gửi ảnh trực tiếp tới Python AI Engine (:8000) để kiểm thử CLIP Gatekeeper & mô hình ONNX thật"
        >
          <div className="mb-4 grid grid-cols-2 gap-2 rounded-xl bg-muted/60 p-1">
            <button
              type="button"
              onClick={() => {
                setMode("species");
                setResult(null);
              }}
              className={cn(
                "flex items-center justify-center gap-1.5 rounded-lg py-2 text-xs font-semibold transition",
                mode === "species"
                  ? "bg-card text-forest shadow-xs"
                  : "text-muted-foreground hover:text-foreground",
              )}
            >
              <Sprout className="size-3.5" /> Nhận diện Loài
            </button>
            <button
              type="button"
              onClick={() => {
                setMode("disease");
                setResult(null);
              }}
              className={cn(
                "flex items-center justify-center gap-1.5 rounded-lg py-2 text-xs font-semibold transition",
                mode === "disease"
                  ? "bg-card text-forest shadow-xs"
                  : "text-muted-foreground hover:text-foreground",
              )}
            >
              <Microscope className="size-3.5" /> Chẩn đoán Bệnh
            </button>
          </div>

          <ImageUploader
            localOnly
            value={image}
            onChange={(v) => {
              setImage(v);
              setResult(null);
              setErrorMsg(null);
            }}
          />

          <div className="mt-3">
            <p className="mb-2 text-xs text-muted-foreground">Hoặc chọn ảnh mẫu</p>
            <div className="grid grid-cols-4 gap-2">
              {SAMPLES.map((s) => (
                <button
                  key={s.url}
                  type="button"
                  onClick={() => {
                    setImage(s.url);
                    setResult(null);
                    setErrorMsg(null);
                  }}
                  className={cn(
                    "group relative overflow-hidden rounded-lg ring-2 ring-transparent transition",
                    image === s.url && "ring-leaf",
                  )}
                >
                  <img src={s.url} alt={s.label} className="aspect-square w-full object-cover" loading="lazy" />
                  <span className="absolute inset-x-0 bottom-0 bg-black/55 px-1 py-0.5 text-[10px] font-medium text-white">
                    {s.label}
                  </span>
                </button>
              ))}
            </div>
          </div>

          <div className="mt-4 flex gap-2">
            <Button className="flex-1" onClick={run} disabled={!image || running}>
              {running ? <Loader2 className="animate-spin" /> : <Play />}
              {mode === "species" ? "Chạy nhận diện Loài" : "Chạy chẩn đoán Bệnh"}
            </Button>
            {result && (
              <Button
                variant="outline"
                onClick={() => {
                  setImage("");
                  setResult(null);
                  setErrorMsg(null);
                }}
              >
                <RefreshCw /> Ảnh khác
              </Button>
            )}
          </div>
        </ChartCard>

        <ChartCard
          title="Kết quả từ AI Engine"
          actions={
            result ? (
              <StatusBadge
                status={result.is_valid_plant ? "active" : "inactive"}
                label={result.latency_ms ? `${result.latency_ms} ms (Engine)` : `${result.roundTripMs ?? 0} ms`}
              />
            ) : null
          }
        >
          {!result && !running && !errorMsg && (
            <EmptyState
              title="Chưa có kết quả"
              description="Tải ảnh lên hoặc chọn ảnh mẫu rồi bấm Chạy để kiểm thử trực tiếp AI Engine."
            />
          )}

          {running && (
            <div className="flex flex-col items-center gap-3 py-16 text-sm text-muted-foreground">
              <Loader2 className="size-6 animate-spin text-leaf" />
              Đang gửi ảnh tới Python AI Engine...
            </div>
          )}

          {errorMsg && !running && (
            <div className="flex items-start gap-3 rounded-xl border border-danger/30 bg-danger-soft p-4 text-sm text-danger">
              <AlertCircle className="mt-0.5 size-5 shrink-0" />
              <div>
                <p className="font-semibold">Không thể chạy kiểm thử</p>
                <p className="mt-1 text-xs">{errorMsg}</p>
                <p className="mt-2 text-xs text-muted-foreground">
                  Hãy đảm bảo Python AI Engine đang chạy tại cổng 8000 (hoặc biến môi trường AI_ENGINE_URL).
                </p>
              </div>
            </div>
          )}

          {result && !running && (
            <div className="space-y-5">
              {/* Gatekeeper Status */}
              <div
                className={cn(
                  "flex items-center gap-3 rounded-xl p-3.5",
                  result.is_valid_plant ? "bg-success-soft" : "bg-danger-soft",
                )}
              >
                {result.is_valid_plant ? (
                  <CheckCircle2 className="size-5 shrink-0 text-success" />
                ) : (
                  <XCircle className="size-5 shrink-0 text-danger" />
                )}
                <div className="flex-1 text-sm">
                  <p className="font-semibold">
                    {result.is_valid_plant
                      ? "CLIP Gatekeeper: Ảnh hợp lệ (Thực vật)"
                      : `Từ chối: ${result.prediction || "Không hợp lệ"}`}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    {result.clip_non_plant_prob != null
                      ? `Xác suất không phải cây: ${(result.clip_non_plant_prob * 100).toFixed(1)}% · Xác suất thực vật: ${((result.clip_plant_prob ?? 0) * 100).toFixed(1)}%`
                      : result.message}
                  </p>
                </div>
              </div>

              {result.is_valid_plant && (
                <>
                  {/* Main Prediction */}
                  <div className="rounded-xl border bg-surface-2/50 p-4">
                    <div className="flex flex-wrap items-center justify-between gap-2">
                      <div>
                        <p className="text-xs text-muted-foreground">
                          Mô hình: <span className="font-mono">{result.model_used}</span>
                        </p>
                        <h4 className="mt-1 text-lg font-bold text-foreground">
                          {result.prediction_vi || result.prediction}
                        </h4>
                        {result.prediction_vi && result.prediction && (
                          <p className="font-mono text-xs text-muted-foreground">{result.prediction}</p>
                        )}
                      </div>
                      <div className="text-right">
                        <p className="text-2xl font-bold tabular text-forest">
                          {(result.confidence ?? 0).toFixed(2)}%
                        </p>
                        <StatusBadge
                          status={result.is_in_database ? "active" : "warning"}
                          label={result.is_in_database ? "Khớp trong CSDL" : "Ngoài CSDL / Độ tin cậy thấp"}
                        />
                      </div>
                    </div>
                  </div>

                  {/* Disease details */}
                  {result.mode === "disease" && result.cause && (
                    <div className="space-y-2 rounded-xl border p-4 text-sm">
                      <div className="flex items-center justify-between">
                        <span className="font-semibold">Thông tin bệnh lý</span>
                        {result.severity && <StatusBadge status="warning" label={result.severity} />}
                      </div>
                      <p className="text-xs text-muted-foreground">{result.cause}</p>
                      {result.treatment_steps && result.treatment_steps.length > 0 && (
                        <ul className="mt-2 list-disc space-y-1 pl-4 text-xs text-muted-foreground">
                          {result.treatment_steps.map((step, i) => (
                            <li key={i}>{step}</li>
                          ))}
                        </ul>
                      )}
                    </div>
                  )}

                  {/* Raw Confidence Breakdown (Top candidates from AI Engine) */}
                  {result.top_3 && result.top_3.length > 0 && (
                    <div>
                      <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                        Phân bố xác suất Softmax từ mô hình ONNX
                      </p>
                      <ul className="space-y-2">
                        {result.top_3.map((p, i) => (
                          <li key={p.class}>
                            <div className="mb-1 flex justify-between text-xs">
                              <span className={cn(i === 0 ? "font-semibold" : "text-muted-foreground")}>
                                {p.name_vi ? `${p.name_vi} (${p.class})` : p.class}
                              </span>
                              <span className="font-medium tabular">{p.confidence.toFixed(2)}%</span>
                            </div>
                            <div className="h-1.5 overflow-hidden rounded-full bg-muted">
                              <div
                                className={cn("h-full rounded-full", i === 0 ? "bg-leaf" : "bg-sage/60")}
                                style={{ width: `${Math.min(100, p.confidence)}%` }}
                              />
                            </div>
                          </li>
                        ))}
                      </ul>
                    </div>
                  )}
                </>
              )}
            </div>
          )}
        </ChartCard>
      </div>

      <ChartCard
        title="Luồng thực thi thực tế"
        description={
          result
            ? `AI Engine xử lý trong ${result.latency_ms ?? 0} ms (Tổng round-trip: ${result.roundTripMs ?? 0} ms)`
            : "Kiểm tra độ sáng → CLIP Gatekeeper → ONNX EfficientNetV2"
        }
      >
        <div className="flex flex-col items-stretch gap-3 md:flex-row md:items-center">
          <div className="flex flex-1 items-center gap-3 rounded-xl border bg-surface-2/40 p-3">
            <span className="grid size-9 place-items-center rounded-lg bg-card text-forest shadow-xs">
              <ShieldCheck className="size-4" />
            </span>
            <div>
              <p className="text-sm font-medium">1. Độ sáng & CLIP Gatekeeper</p>
              <p className="text-xs text-muted-foreground">
                {result
                  ? result.is_valid_plant
                    ? "Đã vượt qua kiểm duyệt"
                    : "Đã chặn ảnh không hợp lệ"
                  : "Chờ ảnh đầu vào"}
              </p>
            </div>
          </div>
          <ArrowRight className="mx-auto hidden size-4 text-muted-foreground md:block" />
          <div className="flex flex-1 items-center gap-3 rounded-xl border bg-surface-2/40 p-3">
            <span className="grid size-9 place-items-center rounded-lg bg-card text-forest shadow-xs">
              {mode === "species" ? <Sprout className="size-4" /> : <Microscope className="size-4" />}
            </span>
            <div>
              <p className="text-sm font-medium">
                2. {mode === "species" ? "EfficientNetV2 (40 loài)" : "EfficientNetV2 (5 bệnh)"}
              </p>
              <p className="text-xs text-muted-foreground">
                {result?.is_valid_plant
                  ? `${result.prediction_vi || result.prediction} (${(result.confidence ?? 0).toFixed(1)}%)`
                  : "Đầu vào chuẩn 224×224 px"}
              </p>
            </div>
          </div>
        </div>
      </ChartCard>
    </div>
  );
}
