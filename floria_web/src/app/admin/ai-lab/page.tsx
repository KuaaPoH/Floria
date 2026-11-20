"use client";

import { useRouter, useSearchParams } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { ArrowRight, CheckCircle2, Cpu, Microscope, RefreshCw, ShieldCheck, Sprout, XCircle } from "lucide-react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { PageHeader } from "@/components/shared/page-header";
import { StatusBadge } from "@/components/shared/status-badge";
import { ChartCard } from "@/components/shared/chart-card";
import { AiConfigForm } from "@/features/ai-lab/ai-config-form";
import { AiSandbox } from "@/features/ai-lab/ai-sandbox";
import { ActiveLearning } from "@/features/ai-lab/active-learning";
import { AiAnalytics } from "@/features/ai-lab/ai-analytics";
import { apiRequest } from "@/lib/api-client";
import { usePermission } from "@/stores/rbac-store";

type Tab = "overview" | "registry" | "sandbox" | "learning" | "analytics";
const TABS: Tab[] = ["overview", "registry", "sandbox", "learning", "analytics"];

interface AiEngineStatus {
  online: boolean;
  latencyMs: number;
  loadedModels: string[];
  clipLoaded: boolean;
  speciesClassesCount: number;
  diseaseClassesCount: number;
  detail?: string;
}

export default function AiLabPage() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const rawTab = searchParams.get("tab") as Tab | null;
  const tab: Tab = rawTab && TABS.includes(rawTab) ? rawTab : "overview";

  const canConfigure = usePermission("ai_lab", "configure");
  const canApprove = usePermission("ai_lab", "approve");

  const statusQuery = useQuery({
    queryKey: ["ai-engine-status"],
    queryFn: () => apiRequest<AiEngineStatus>("/ai/status"),
    staleTime: 60_000,
  });

  const st = statusQuery.data;
  const hasSpeciesModel = st?.loadedModels.includes("tf_efficientnetv2_b0") ?? false;
  const hasDiseaseModel = st?.loadedModels.includes("tf_efficientnetv2_b0_disease") ?? false;

  const modelRows = [
    {
      id: "clip",
      name: "CLIP Gatekeeper",
      file: "openai/clip-vit-base-patch32",
      role: "Lọc ảnh không phải thực vật trước khi suy luận",
      classes: 2,
      accuracy: "Zero-shot",
      loaded: Boolean(st?.clipLoaded),
      input: "CLIP ViT-B/32",
    },
    {
      id: "species",
      name: "Species Recognition",
      file: "tf_efficientnetv2_b0.onnx",
      role: "Nhận diện loài cây cảnh",
      classes: st?.speciesClassesCount ?? 40,
      accuracy: "90,0% (Test)",
      loaded: hasSpeciesModel,
      input: "224 × 224 px",
    },
    {
      id: "disease",
      name: "Disease Detection",
      file: "tf_efficientnetv2_b0_disease.onnx",
      role: "Chẩn đoán 5 nhóm bệnh lá",
      classes: st?.diseaseClassesCount ?? 5,
      accuracy: "92,5% (Test)",
      loaded: hasDiseaseModel,
      input: "224 × 224 px",
    },
  ];

  return (
    <>
      <PageHeader
        title="AI Lab"
        description="Giám sát Python AI Engine, cấu hình đồng bộ App, kiểm thử Sandbox và duyệt PlantRequests."
        actions={
          <div className="flex items-center gap-2">
            <StatusBadge
              status={st?.online ? "active" : "inactive"}
              label={
                statusQuery.isLoading
                  ? "Đang kiểm tra Engine..."
                  : st?.online
                    ? `AI Engine Online · ${st.latencyMs}ms`
                    : "AI Engine Offline"
              }
            />
            <Button
              size="sm"
              variant="outline"
              onClick={() => statusQuery.refetch()}
              disabled={statusQuery.isFetching}
            >
              <RefreshCw className={statusQuery.isFetching ? "animate-spin" : ""} /> Kiểm tra
            </Button>
          </div>
        }
      />

      <Tabs value={tab} onValueChange={(v) => router.replace(`/admin/ai-lab?tab=${v}`)}>
        <TabsList className="mb-5 h-10 w-full justify-start overflow-x-auto sm:w-auto">
          <TabsTrigger value="overview">Tổng quan & Cấu hình</TabsTrigger>
          <TabsTrigger value="registry">Kho mô hình</TabsTrigger>
          <TabsTrigger value="sandbox">Kiểm thử AI</TabsTrigger>
          <TabsTrigger value="learning">Duyệt yêu cầu cây</TabsTrigger>
          <TabsTrigger value="analytics">Phân tích</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-5">
          <ChartCard
            title="Kiến trúc Pipeline Nhận diện"
            description="Mỗi ảnh gửi tới AI Engine đi qua 3 bước kiểm duyệt và suy luận theo thứ tự"
          >
            <div className="flex flex-col items-center gap-3 md:flex-row">
                {[
                  {
                    Icon: ShieldCheck,
                    t: "CLIP Gatekeeper",
                    d: "openai/clip-vit-base-patch32",
                    ok: Boolean(st?.clipLoaded),
                  },
                  {
                    Icon: Sprout,
                    t: `Species · ${st?.speciesClassesCount ?? 40} loài`,
                    d: "tf_efficientnetv2_b0.onnx",
                    ok: hasSpeciesModel,
                  },
                  {
                    Icon: Microscope,
                    t: `Disease · ${st?.diseaseClassesCount ?? 5} bệnh`,
                    d: "tf_efficientnetv2_b0_disease.onnx",
                    ok: hasDiseaseModel,
                  },
                ].map(({ Icon, t, d, ok }, i) => (
                  <div key={t} className="contents">
                    {i > 0 && <ArrowRight className="size-4 rotate-90 text-sage md:rotate-0" />}
                    <div className="flex w-full flex-1 items-center gap-3 rounded-xl bg-surface-2/70 p-3">
                      <span className="grid size-9 shrink-0 place-items-center rounded-lg bg-forest text-primary-foreground">
                        <Icon className="size-4" />
                      </span>
                      <div className="min-w-0 flex-1">
                        <p className="truncate text-sm font-semibold">{t}</p>
                        <p className="truncate font-mono text-[11px] text-muted-foreground">{d}</p>
                      </div>
                      {st?.online ? (
                        ok ? (
                          <CheckCircle2 className="size-4 shrink-0 text-success" />
                        ) : (
                          <XCircle className="size-4 shrink-0 text-danger" />
                        )
                      ) : null}
                    </div>
                  </div>
                ))}
            </div>
          </ChartCard>

          <AiConfigForm canConfigure={canConfigure} />
        </TabsContent>

        <TabsContent value="registry">
          <div className="card-surface overflow-hidden">
            <Table>
              <TableHeader>
                <TableRow className="bg-surface-2/60">
                  <TableHead>Mô hình</TableHead>
                  <TableHead>Vai trò</TableHead>
                  <TableHead>Đầu vào</TableHead>
                  <TableHead>Số lớp</TableHead>
                  <TableHead>Độ chính xác</TableHead>
                  <TableHead>Trạng thái trên AI Engine</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {modelRows.map((m) => (
                  <TableRow key={m.id}>
                    <TableCell>
                      <p className="font-medium">{m.name}</p>
                      <p className="font-mono text-[11px] text-muted-foreground">{m.file}</p>
                    </TableCell>
                    <TableCell className="text-xs text-muted-foreground">{m.role}</TableCell>
                    <TableCell className="font-mono text-xs">{m.input}</TableCell>
                    <TableCell className="tabular">{m.classes} lớp</TableCell>
                    <TableCell className="tabular font-medium">{m.accuracy}</TableCell>
                    <TableCell>
                      {!st?.online ? (
                        <StatusBadge status="inactive" label="Engine Offline" />
                      ) : m.loaded ? (
                        <StatusBadge status="active" label="Đang hoạt động" />
                      ) : (
                        <StatusBadge status="danger" label="Chưa nạp" />
                      )}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
          <div className="mt-4 flex items-center gap-2 rounded-xl border bg-surface-2/40 px-4 py-3 text-xs text-muted-foreground">
            <Cpu className="size-4 shrink-0 text-forest" />
            <span>
              Các mô hình ONNX đang chạy cố định trên <code className="font-mono">CPUExecutionProvider</code> với chuẩn tiền xử lý ImageNet (224 × 224 px).
            </span>
          </div>
        </TabsContent>

        <TabsContent value="sandbox">
          <AiSandbox />
        </TabsContent>

        <TabsContent value="learning">
          <ActiveLearning canApprove={canApprove} />
        </TabsContent>

        <TabsContent value="analytics">
          <AiAnalytics />
        </TabsContent>
      </Tabs>
    </>
  );
}
