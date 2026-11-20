"use client";

import { useEffect, useState } from "react";
import { useForm, Controller } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { z } from "zod";
import { Lock, RotateCcw, Save, Sparkles } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Slider } from "@/components/ui/slider";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import { Field } from "@/components/shared/field";
import { ConfirmDialog } from "@/components/shared/confirm-dialog";
import { ChartCard } from "@/components/shared/chart-card";
import { apiRequest } from "@/lib/api-client";
import { logAudit } from "@/services";
import type { RealAiConfig } from "@/app/api/admin/ai/config/route";

const aiConfigSchema = z.object({
  preferGemini: z.boolean(),
  speciesConfidenceThreshold: z.number().min(10).max(99),
  diseaseConfidenceThreshold: z.number().min(10).max(99),
  gatekeeperSpeciesThreshold: z.number().min(0.1).max(0.99),
  gatekeeperDiseaseThreshold: z.number().min(0.1).max(0.99),
});

type EditableConfig = z.infer<typeof aiConfigSchema>;

const FALLBACK_CONFIG: RealAiConfig = {
  preferGemini: true,
  speciesConfidenceThreshold: 70,
  diseaseConfidenceThreshold: 50,
  gatekeeperSpeciesThreshold: 0.7,
  gatekeeperDiseaseThreshold: 0.5,
  inputSize: 224,
  normalize: true,
  executionProvider: "CPUExecutionProvider",
  speciesModel: "tf_efficientnetv2_b0.onnx",
  diseaseModel: "tf_efficientnetv2_b0_disease.onnx",
};

export function AiConfigForm({ canConfigure }: { canConfigure: boolean }) {
  const qc = useQueryClient();
  const cfgQuery = useQuery({
    queryKey: ["ai-real-config"],
    queryFn: () => apiRequest<RealAiConfig>("/ai/config"),
  });

  const form = useForm<EditableConfig>({
    resolver: zodResolver(aiConfigSchema),
    defaultValues: {
      preferGemini: FALLBACK_CONFIG.preferGemini,
      speciesConfidenceThreshold: FALLBACK_CONFIG.speciesConfidenceThreshold,
      diseaseConfidenceThreshold: FALLBACK_CONFIG.diseaseConfidenceThreshold,
      gatekeeperSpeciesThreshold: FALLBACK_CONFIG.gatekeeperSpeciesThreshold,
      gatekeeperDiseaseThreshold: FALLBACK_CONFIG.gatekeeperDiseaseThreshold,
    },
  });

  const [pending, setPending] = useState<EditableConfig | null>(null);

  useEffect(() => {
    if (cfgQuery.data) {
      form.reset({
        preferGemini: cfgQuery.data.preferGemini,
        speciesConfidenceThreshold: cfgQuery.data.speciesConfidenceThreshold,
        diseaseConfidenceThreshold: cfgQuery.data.diseaseConfidenceThreshold,
        gatekeeperSpeciesThreshold: cfgQuery.data.gatekeeperSpeciesThreshold,
        gatekeeperDiseaseThreshold: cfgQuery.data.gatekeeperDiseaseThreshold,
      });
    }
  }, [cfgQuery.data, form]);

  const saveMutation = useMutation({
    mutationFn: (payload: EditableConfig) =>
      apiRequest<RealAiConfig & { engineReloaded?: boolean }>("/ai/config", {
        method: "PUT",
        body: JSON.stringify(payload),
      }),
    onSuccess: (res, variables) => {
      qc.setQueryData(["ai-real-config"], res);
      form.reset(variables);
      toast.success(
        res.engineReloaded
          ? "Đã lưu cấu hình lên Firestore & đồng bộ nóng AI Engine"
          : "Đã lưu cấu hình lên Firestore (App sẽ cập nhật khi mở lại)",
      );
      logAudit({
        action: "Cập nhật cấu hình AI",
        target: "SystemConfig/ai_config",
        before: cfgQuery.data ? JSON.stringify({ preferGemini: cfgQuery.data.preferGemini, species: cfgQuery.data.speciesConfidenceThreshold, disease: cfgQuery.data.diseaseConfidenceThreshold }) : "",
        after: JSON.stringify(variables),
      });
      setPending(null);
    },
    onError: (err) => {
      toast.error(err instanceof Error ? err.message : "Không thể lưu cấu hình AI");
      setPending(null);
    },
  });

  if (cfgQuery.isLoading) return <Skeleton className="h-96 rounded-xl" />;

  const data = cfgQuery.data ?? FALLBACK_CONFIG;

  return (
    <ChartCard
      title="Cấu hình suy luận & Đồng bộ App / AI Engine"
      description="Lưu tại SystemConfig/ai_config. Tự động áp dụng cho Python AI Engine và đồng bộ khi mở Floria App."
    >
      <form onSubmit={form.handleSubmit((v) => setPending(v))} className="space-y-6">
        <fieldset disabled={!canConfigure || saveMutation.isPending} className="space-y-5">
          <Controller
            control={form.control}
            name="preferGemini"
            render={({ field }) => (
              <label className="flex items-center justify-between gap-4 rounded-xl border bg-surface-2/40 p-4">
                <span className="flex items-start gap-3">
                  <span className="grid size-9 shrink-0 place-items-center rounded-lg bg-forest/10 text-forest">
                    <Sparkles className="size-4" />
                  </span>
                  <span>
                    <span className="block text-sm font-semibold">Ưu tiên LLM Multimodal trên Floria App</span>
                    <span className="block text-xs text-muted-foreground">
                      Khi bật: App nhận diện cây/bệnh qua LLM trước (hỗ trợ ngoài danh mục), lỗi mới chuyển sang ONNX. Khi tắt: App chạy thẳng về AI Engine nội bộ.
                    </span>
                  </span>
                </span>
                <Switch checked={field.value} onCheckedChange={field.onChange} />
              </label>
            )}
          />

          <div className="grid gap-5 md:grid-cols-2">
            <Controller
              control={form.control}
              name="speciesConfidenceThreshold"
              render={({ field }) => (
                <Field
                  label={`Ngưỡng khớp CSDL Loài (40 loài): ${field.value}%`}
                  hint="Dưới ngưỡng này, AI Engine đánh dấu is_in_database = false (cây ngoài danh mục)."
                >
                  <Slider
                    value={[field.value]}
                    min={10}
                    max={99}
                    step={1}
                    onValueChange={([v]) => field.onChange(v)}
                    className="py-2"
                  />
                </Field>
              )}
            />

            <Controller
              control={form.control}
              name="diseaseConfidenceThreshold"
              render={({ field }) => (
                <Field
                  label={`Ngưỡng khớp CSDL Bệnh (5 nhóm): ${field.value}%`}
                  hint="Dưới ngưỡng này, bệnh được xem là chưa chắc chắn thuộc 5 nhóm chuẩn."
                >
                  <Slider
                    value={[field.value]}
                    min={10}
                    max={99}
                    step={1}
                    onValueChange={([v]) => field.onChange(v)}
                    className="py-2"
                  />
                </Field>
              )}
            />

            <Controller
              control={form.control}
              name="gatekeeperSpeciesThreshold"
              render={({ field }) => (
                <Field
                  label={`CLIP Gatekeeper (Quét Loài): ${field.value.toFixed(2)}`}
                  hint="Từ chối ảnh nếu xác suất không phải thực vật vượt ngưỡng này (mặc định 0.70)."
                >
                  <Slider
                    value={[field.value]}
                    min={0.1}
                    max={0.99}
                    step={0.01}
                    onValueChange={([v]) => field.onChange(v)}
                    className="py-2"
                  />
                </Field>
              )}
            />

            <Controller
              control={form.control}
              name="gatekeeperDiseaseThreshold"
              render={({ field }) => (
                <Field
                  label={`CLIP Gatekeeper (Quét Bệnh): ${field.value.toFixed(2)}`}
                  hint="Áp dụng cho ảnh chụp cận cảnh phiến lá bệnh (mặc định 0.50)."
                >
                  <Slider
                    value={[field.value]}
                    min={0.1}
                    max={0.99}
                    step={0.01}
                    onValueChange={([v]) => field.onChange(v)}
                    className="py-2"
                  />
                </Field>
              )}
            />
          </div>

          <div className="rounded-xl border border-dashed bg-muted/30 p-4">
            <div className="mb-3 flex items-center gap-2 text-xs font-semibold uppercase tracking-wide text-muted-foreground">
              <Lock className="size-3.5" /> Thông số mô hình ONNX (Chỉ đọc — khóa theo file .onnx)
            </div>
            <div className="grid gap-3 text-xs sm:grid-cols-2 lg:grid-cols-4">
              <div className="rounded-lg bg-card p-2.5">
                <p className="text-muted-foreground">Kích thước ảnh đầu vào</p>
                <p className="mt-0.5 font-mono font-semibold">{data.inputSize} × {data.inputSize} px</p>
              </div>
              <div className="rounded-lg bg-card p-2.5">
                <p className="text-muted-foreground">Chuẩn hoá ảnh</p>
                <p className="mt-0.5 font-mono font-semibold">{data.normalize ? "ImageNet mean/std" : "Tắt"}</p>
              </div>
              <div className="rounded-lg bg-card p-2.5">
                <p className="text-muted-foreground">Execution Provider</p>
                <p className="mt-0.5 font-mono font-semibold">{data.executionProvider}</p>
              </div>
              <div className="rounded-lg bg-card p-2.5">
                <p className="text-muted-foreground">Cặp mô hình ONNX</p>
                <p className="mt-0.5 truncate font-mono font-semibold" title={`${data.speciesModel} & ${data.diseaseModel}`}>
                  EfficientNetV2-B0
                </p>
              </div>
            </div>
          </div>
        </fieldset>

        {canConfigure ? (
          <div className="flex items-center justify-between gap-2">
            <p className="text-xs text-muted-foreground">
              {data.updatedAt ? `Cập nhật lần cuối: ${new Date(data.updatedAt).toLocaleString("vi-VN")}${data.updatedBy ? ` bởi ${data.updatedBy}` : ""}` : "Đang dùng cấu hình mặc định"}
            </p>
            <div className="flex gap-2">
              <Button
                type="button"
                variant="ghost"
                onClick={() => form.reset()}
                disabled={!form.formState.isDirty || saveMutation.isPending}
              >
                <RotateCcw /> Hoàn tác
              </Button>
              <Button type="submit" disabled={!form.formState.isDirty || saveMutation.isPending}>
                <Save /> Lưu & Đồng bộ
              </Button>
            </div>
          </div>
        ) : (
          <p className="text-xs text-muted-foreground">Bạn chỉ có quyền xem cấu hình này.</p>
        )}
      </form>

      <ConfirmDialog
        open={!!pending}
        onOpenChange={(o) => !o && setPending(null)}
        title="Lưu & đồng bộ cấu hình AI?"
        description="Cấu hình mới sẽ được ghi vào Firestore SystemConfig/ai_config, cập nhật nóng cho Python AI Engine và đồng bộ sang Floria App khi người dùng mở lại ứng dụng."
        confirmLabel="Lưu cấu hình"
        onConfirm={() => pending && saveMutation.mutate(pending)}
      />
    </ChartCard>
  );
}
