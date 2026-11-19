"use client";

import { useRouter, useSearchParams } from "next/navigation";
import { ArrowRight, Microscope, ShieldCheck, Sprout } from "lucide-react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { PageHeader } from "@/components/shared/page-header";
import { DemoBadge } from "@/components/shared/demo-badge";
import { StatusBadge } from "@/components/shared/status-badge";
import { ChartCard } from "@/components/shared/chart-card";
import { CardGridSkeleton } from "@/components/shared/states";
import { ModelCard } from "@/features/ai-lab/model-cards";
import { AiConfigForm } from "@/features/ai-lab/ai-config-form";
import { AiSandbox } from "@/features/ai-lab/ai-sandbox";
import { ActiveLearning } from "@/features/ai-lab/active-learning";
import { AiAnalytics } from "@/features/ai-lab/ai-analytics";
import { useResourceList } from "@/hooks/use-resource";
import { usePermission } from "@/stores/rbac-store";
import { modelsService } from "@/services";
import { formatDate, formatPercent } from "@/lib/format";

type Tab = "overview" | "registry" | "sandbox" | "learning" | "analytics";
const TABS: Tab[] = ["overview", "registry", "sandbox", "learning", "analytics"];

export default function AiLabPage() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const rawTab = searchParams.get("tab") as Tab | null;
  const tab: Tab = rawTab && TABS.includes(rawTab) ? rawTab : "overview";

  const models = useResourceList(modelsService);
  const canConfigure = usePermission("ai_lab", "configure");
  const canApprove = usePermission("ai_lab", "approve");

  return (
    <>
      <PageHeader title="AI Lab" description="Quản lý mô hình nhận diện, cấu hình suy luận và vòng lặp cải thiện dữ liệu." badge={<DemoBadge label="Chỉ số demo" />} />
      <Tabs value={tab} onValueChange={(v) => router.replace(`/ai-lab?tab=${v}`)}>
        <TabsList className="mb-5 h-10 w-full justify-start overflow-x-auto sm:w-auto">
          <TabsTrigger value="overview">Tổng quan</TabsTrigger>
          <TabsTrigger value="registry">Model Registry</TabsTrigger>
          <TabsTrigger value="sandbox">AI Sandbox</TabsTrigger>
          <TabsTrigger value="learning">Active Learning</TabsTrigger>
          <TabsTrigger value="analytics">Phân tích</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-5">
          <ChartCard title="Pipeline nhận diện" description="Mỗi ảnh người dùng gửi lên đi qua 3 mô hình theo thứ tự">
            <div className="flex flex-col items-center gap-3 md:flex-row">
              {(
                [
                  [ShieldCheck, "CLIP Gatekeeper", "Lọc ảnh không phải cây"],
                  [Sprout, "Species · 40 loài", "tf_efficientnetv2_b0.onnx"],
                  [Microscope, "Disease · 5 bệnh + khoẻ", "tf_efficientnetv2_b0_disease.onnx"],
                ] as const
              ).map(([Icon, t, d], i) => (
                <div key={i} className="contents">
                  {i > 0 && <ArrowRight className="size-4 rotate-90 text-sage md:rotate-0" />}
                  <div className="flex w-full flex-1 items-center gap-3 rounded-xl bg-surface-2/70 p-3">
                    <span className="grid size-9 place-items-center rounded-lg bg-forest text-primary-foreground">
                      <Icon className="size-4" />
                    </span>
                    <div>
                      <p className="text-sm font-semibold">{t}</p>
                      <p className="font-mono text-[11px] text-muted-foreground">{d}</p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </ChartCard>
          {models.isLoading ? (
            <CardGridSkeleton count={3} className="lg:grid-cols-3" />
          ) : (
            <div className="grid gap-4 lg:grid-cols-3">
              {models.data?.map((m) => (
                <ModelCard key={m.id} model={m} canConfigure={canConfigure} />
              ))}
            </div>
          )}
          <AiConfigForm canConfigure={canConfigure} />
        </TabsContent>

        <TabsContent value="registry">
          <div className="card-surface overflow-hidden">
            <Table>
              <TableHeader>
                <TableRow className="bg-surface-2/60">
                  <TableHead>Mô hình</TableHead>
                  <TableHead>Phiên bản</TableHead>
                  <TableHead>Phát hành</TableHead>
                  <TableHead>Accuracy</TableHead>
                  <TableHead>F1</TableHead>
                  <TableHead>Latency</TableHead>
                  <TableHead>Trạng thái</TableHead>
                  <TableHead>Ghi chú</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {models.data?.flatMap((m) =>
                  m.versions.map((v) => (
                    <TableRow key={m.id + v.version}>
                      <TableCell>
                        <p className="font-medium">{m.name}</p>
                        <p className="font-mono text-[11px] text-muted-foreground">{m.file}</p>
                      </TableCell>
                      <TableCell className="font-medium">v{v.version}</TableCell>
                      <TableCell>{formatDate(v.releasedAt)}</TableCell>
                      <TableCell className="tabular">{formatPercent(v.accuracy)}</TableCell>
                      <TableCell className="tabular">{formatPercent(v.f1)}</TableCell>
                      <TableCell className="tabular">{v.latencyMs} ms</TableCell>
                      <TableCell>{v.version === m.version ? <StatusBadge status={m.active ? "active" : "inactive"} label={m.active ? `Đang chạy · ${m.rollout}%` : "Tạm tắt"} /> : <StatusBadge status="draft" label="Lưu trữ" />}</TableCell>
                      <TableCell className="max-w-56 text-xs text-muted-foreground">{v.note}</TableCell>
                    </TableRow>
                  )),
                )}
              </TableBody>
            </Table>
          </div>
          <div className="mt-4 grid gap-4 lg:grid-cols-3">
            {models.data?.map((m) => (
              <ModelCard key={m.id} model={m} canConfigure={canConfigure} />
            ))}
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
