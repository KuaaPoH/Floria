"use client";

import { useEffect, useState } from "react";
import { useForm, Controller } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { RotateCcw, Save } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Slider } from "@/components/ui/slider";
import { Switch } from "@/components/ui/switch";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { Field } from "@/components/shared/field";
import { ConfirmDialog } from "@/components/shared/confirm-dialog";
import { ChartCard } from "@/components/shared/chart-card";
import { useSingleton } from "@/hooks/use-singleton";
import { useResourceList } from "@/hooks/use-resource";
import { aiConfigService, logAudit, modelsService } from "@/services";
import { DEFAULT_AI_CONFIG } from "@/mocks/ai";
import type { AiConfig } from "@/types";

export const aiConfigSchema = z.object({
  confidenceThreshold: z.number().min(0.1, "Tối thiểu 0,1").max(0.99, "Tối đa 0,99"),
  gatekeeperThreshold: z.number().min(0.1).max(0.99),
  topK: z.number().int().min(1, "Tối thiểu 1").max(10, "Tối đa 10"),
  inputSize: z.number().refine((v) => [224, 256, 288, 320, 384].includes(v), "Kích thước không hỗ trợ"),
  speciesVersion: z.string().min(1),
  diseaseVersion: z.string().min(1),
  executionProvider: z.enum(["CPUExecutionProvider", "CUDAExecutionProvider"]),
  batchSize: z.number().int().min(1, "Tối thiểu 1").max(32, "Tối đa 32"),
  normalize: z.boolean(),
});

export function AiConfigForm({ canConfigure }: { canConfigure: boolean }) {
  const cfg = useSingleton(aiConfigService);
  const models = useResourceList(modelsService);
  const form = useForm<AiConfig>({ resolver: zodResolver(aiConfigSchema), defaultValues: DEFAULT_AI_CONFIG });
  const [pending, setPending] = useState<AiConfig | null>(null);

  useEffect(() => {
    if (cfg.data) form.reset(cfg.data);
  }, [cfg.data, form]);

  const speciesVersions = models.data?.find((m) => m.kind === "species")?.versions ?? [];
  const diseaseVersions = models.data?.find((m) => m.kind === "disease")?.versions ?? [];
  const e = form.formState.errors;

  if (cfg.isLoading) return <Skeleton className="h-96 rounded-xl" />;

  return (
    <ChartCard title="Cấu hình suy luận AI" description="Áp dụng cho Python AI Engine khi kết nối. Mọi thay đổi được ghi nhật ký.">
      <form onSubmit={form.handleSubmit((v) => setPending(v))} className="space-y-5">
        <fieldset disabled={!canConfigure} className="grid gap-5 md:grid-cols-2">
          <Controller
            control={form.control}
            name="confidenceThreshold"
            render={({ field }) => (
              <Field label={`Ngưỡng độ tin cậy: ${field.value.toFixed(2).replace(".", ",")}`} hint="Kết quả thấp hơn ngưỡng sẽ hiển thị 'Không chắc chắn'." error={e.confidenceThreshold?.message}>
                <Slider value={[field.value]} min={0.1} max={0.99} step={0.01} onValueChange={([v]) => field.onChange(v)} className="py-2" />
              </Field>
            )}
          />
          <Controller
            control={form.control}
            name="gatekeeperThreshold"
            render={({ field }) => (
              <Field label={`Ngưỡng CLIP Gatekeeper: ${field.value.toFixed(2).replace(".", ",")}`} hint="Ảnh dưới ngưỡng bị từ chối là 'không phải cây'." error={e.gatekeeperThreshold?.message}>
                <Slider value={[field.value]} min={0.1} max={0.99} step={0.01} onValueChange={([v]) => field.onChange(v)} className="py-2" />
              </Field>
            )}
          />
          <Field label="Top-K dự đoán" htmlFor="topK" error={e.topK?.message}>
            <Input id="topK" type="number" {...form.register("topK", { valueAsNumber: true })} />
          </Field>
          <Controller
            control={form.control}
            name="inputSize"
            render={({ field }) => (
              <Field label="Kích thước ảnh đầu vào" error={e.inputSize?.message}>
                <Select value={String(field.value)} onValueChange={(v) => field.onChange(Number(v))}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>{[224, 256, 288, 320, 384].map((s) => <SelectItem key={s} value={String(s)}>{s} × {s} px</SelectItem>)}</SelectContent>
                </Select>
              </Field>
            )}
          />
          <Controller
            control={form.control}
            name="speciesVersion"
            render={({ field }) => (
              <Field label="Phiên bản mô hình loài">
                <Select value={field.value} onValueChange={field.onChange}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>{speciesVersions.map((v) => <SelectItem key={v.version} value={v.version}>tf_efficientnetv2_b0 · v{v.version}</SelectItem>)}</SelectContent>
                </Select>
              </Field>
            )}
          />
          <Controller
            control={form.control}
            name="diseaseVersion"
            render={({ field }) => (
              <Field label="Phiên bản mô hình bệnh">
                <Select value={field.value} onValueChange={field.onChange}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>{diseaseVersions.map((v) => <SelectItem key={v.version} value={v.version}>disease · v{v.version}</SelectItem>)}</SelectContent>
                </Select>
              </Field>
            )}
          />
          <Controller
            control={form.control}
            name="executionProvider"
            render={({ field }) => (
              <Field label="ONNX Execution Provider">
                <Select value={field.value} onValueChange={field.onChange}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="CPUExecutionProvider">CPUExecutionProvider</SelectItem>
                    <SelectItem value="CUDAExecutionProvider">CUDAExecutionProvider</SelectItem>
                  </SelectContent>
                </Select>
              </Field>
            )}
          />
          <Field label="Batch size" htmlFor="batch" error={e.batchSize?.message}>
            <Input id="batch" type="number" {...form.register("batchSize", { valueAsNumber: true })} />
          </Field>
          <Controller
            control={form.control}
            name="normalize"
            render={({ field }) => (
              <label className="flex items-center justify-between rounded-xl border p-3 md:col-span-2">
                <span>
                  <span className="block text-sm font-medium">Chuẩn hoá ảnh (ImageNet mean/std)</span>
                  <span className="block text-xs text-muted-foreground">Bắt buộc với các mô hình EfficientNetV2 hiện tại.</span>
                </span>
                <Switch checked={field.value} onCheckedChange={field.onChange} />
              </label>
            )}
          />
        </fieldset>
        {canConfigure ? (
          <div className="flex justify-end gap-2">
            <Button type="button" variant="ghost" onClick={() => cfg.data && form.reset(cfg.data)} disabled={!form.formState.isDirty}><RotateCcw /> Hoàn tác</Button>
            <Button type="submit" disabled={!form.formState.isDirty}><Save /> Lưu cấu hình</Button>
          </div>
        ) : (
          <p className="text-xs text-muted-foreground">Bạn chỉ có quyền xem cấu hình này.</p>
        )}
      </form>
      <ConfirmDialog
        open={!!pending}
        onOpenChange={(o) => !o && setPending(null)}
        title="Áp dụng cấu hình AI mới?"
        description="Cấu hình sẽ có hiệu lực cho mọi yêu cầu nhận diện tiếp theo."
        confirmLabel="Áp dụng"
        onConfirm={() => {
          if (!pending || !cfg.data) return;
          const before = cfg.data;
          const changed = (Object.keys(pending) as (keyof AiConfig)[]).filter((k) => pending[k] !== before[k]);
          cfg.save.mutate(pending, {
            onSuccess: () => {
              toast.success("Đã lưu cấu hình AI");
              logAudit({ action: "Cập nhật cấu hình AI", target: `AI Config · ${changed.join(", ")}`, before: changed.map((k) => `${k}: ${before[k]}`).join(", "), after: changed.map((k) => `${k}: ${pending[k]}`).join(", ") });
            },
          });
        }}
      />
    </ChartCard>
  );
}
