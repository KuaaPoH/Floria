"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { AlertTriangle, Camera, Leaf, Loader2, ScanLine, Sun, Trees } from "lucide-react";
import { ScanUploader } from "@/components/ai/ScanUploader";
import { DemoNotice } from "@/components/layout/DemoBadge";
import { PageContainer } from "@/components/layout/PageContainer";
import { Button } from "@/components/ui/button";
import { Progress } from "@/components/ui/progress";
import { cn } from "@/lib/utils";
import { scanService } from "@/services/scan.service";

type Phase = "idle" | "uploading" | "processing" | "error" | "timeout";

export default function DiscoveryPage() {
  const router = useRouter();
  const [image, setImage] = useState<string | null>(null);
  const [phase, setPhase] = useState<Phase>("idle");
  const [err, setErr] = useState("");
  const busy = phase === "uploading" || phase === "processing";

  const scan = async () => {
    if (!image) return;
    setPhase("uploading");
    try {
      await new Promise((r) => setTimeout(r, 450));
      setPhase("processing");
      const res = await scanService.identify(image);
      router.push(`/discovery/result/${res.scanId}`);
    } catch (e) {
      const m = (e as Error).message;
      setPhase(m === "timeout" ? "timeout" : "error");
      setErr(m);
    }
  };

  return (
    <PageContainer className="max-w-6xl">
      <div className="grid gap-10 lg:grid-cols-[1.25fr_1fr] lg:items-start">
        <div>
          <p className="eyebrow">Plant Discovery</p>
          <h1 className="mt-2 text-4xl font-bold tracking-tight md:text-5xl">Cây này là cây gì?</h1>
          <p className="mt-3 max-w-xl text-muted-foreground">Tải ảnh cây của bạn lên — Floria kiểm tra ảnh có phải thực vật, nhận diện loài cây phổ biến và lưu kết quả vào lịch sử quét.</p>
          <div className="mt-8 space-y-4">
            <ScanUploader value={image} onChange={(v) => { setImage(v); setPhase("idle"); }} scanning={busy} />
            {busy && (
              <div className="rounded-2xl border bg-card p-4">
                <p className="flex items-center gap-2 text-sm font-semibold"><Loader2 className="size-4 animate-spin text-leaf" />{phase === "uploading" ? "Đang tải ảnh lên…" : "Đang kiểm tra ảnh và nhận diện loài cây…"}</p>
                <Progress value={phase === "uploading" ? 25 : 70} className="mt-3 h-1.5" />
              </div>
            )}
            {(phase === "error" || phase === "timeout") && (
              <div className="flex items-center gap-2 rounded-2xl border border-danger/30 bg-danger-soft/50 p-4 text-sm text-danger">
                <AlertTriangle className="size-4" />{phase === "timeout" ? "Quá thời gian xử lý. Vui lòng thử lại." : err || "Không thể xử lý ảnh."}
              </div>
            )}
            <Button size="lg" className="w-full" onClick={scan} disabled={!image || busy}>{busy ? <Loader2 className="animate-spin" /> : <ScanLine />} Nhận diện cây</Button>
            <DemoNotice>Chế độ demo: kết quả được mô phỏng trên trình duyệt. Kết nối POST /api/scan-disease (CLIP + EfficientNetV2) để nhận diện thật.</DemoNotice>
          </div>
        </div>
        <aside className="rounded-[2rem] bg-forest-gradient p-7 text-forest-foreground lg:sticky lg:top-24">
          <h2 className="text-lg font-semibold">Mẹo chụp ảnh chuẩn</h2>
          <ul className="mt-5 space-y-5">
            {[
              { icon: Trees, t: "Chụp rõ toàn cây", d: "Đặt cây ở giữa khung hình, không bị cắt mất." },
              { icon: Leaf, t: "Ưu tiên lá và thân", d: "Hình dạng lá là đặc điểm nhận diện quan trọng nhất." },
              { icon: Sun, t: "Ánh sáng đầy đủ", d: "Ánh sáng tự nhiên, tránh ngược sáng." },
              { icon: Camera, t: "Không che khuất", d: "Tránh tay, đồ vật che phủ cây." },
            ].map((x, i) => (
              <li key={x.t} className="flex gap-4">
                <span className={cn("grid size-10 shrink-0 place-items-center rounded-2xl bg-forest-foreground/10")}><x.icon className="size-5 text-sage" /></span>
                <span><span className="text-xs text-forest-foreground/60">0{i + 1}</span><b className="block">{x.t}</b><span className="text-sm text-forest-foreground/75">{x.d}</span></span>
              </li>
            ))}
          </ul>
        </aside>
      </div>
    </PageContainer>
  );
}
