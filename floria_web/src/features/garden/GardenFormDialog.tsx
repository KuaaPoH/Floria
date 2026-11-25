"use client";

import { useEffect, useRef } from "react";
import { zodResolver } from "@hookform/resolvers/zod";
import { Controller, useForm } from "react-hook-form";
import { Check, Loader2, Upload } from "lucide-react";
import { toast } from "sonner";
import { z } from "zod";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Field } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { useGardenMutations } from "@/hooks/queries";
import { useT } from "@/i18n";
import { common } from "@/i18n/common";
import { ENV_LABEL, LIGHT_LABEL } from "@/i18n/labels";
import { cn } from "@/lib/utils";
import { IMG } from "@/mocks/user/images";
import { uploadService } from "@/services/upload.service";
import type { GardenEnvironment, LightCondition, UserGarden } from "@/types/user";

const schema = z.object({
  name: z.string().trim().min(2, "Tên khu vườn tối thiểu 2 ký tự").max(50, "Tối đa 50 ký tự"),
  environment: z.enum(["indoor", "balcony", "yard", "rooftop"]),
  light: z.enum(["low", "indirect", "bright", "direct"]),
  coverImage: z.string().min(1, "Chọn ảnh đại diện"),
});
type Values = z.infer<typeof schema>;

const COVERS = [IMG.gardens.livingRoom, IMG.gardens.balcony, IMG.gardens.rooftop, IMG.plants.monstera, IMG.plants.bougainvillea];

export function GardenFormDialog({ open, onOpenChange, garden, onSaved }: { open: boolean; onOpenChange: (o: boolean) => void; garden?: UserGarden; onSaved?: (g: UserGarden) => void }) {
  const t = useT(common);
  const { create, update } = useGardenMutations();
  const fileRef = useRef<HTMLInputElement>(null);
  const form = useForm<Values>({ resolver: zodResolver(schema), defaultValues: { name: "", environment: "indoor", light: "indirect", coverImage: COVERS[0] } });
  useEffect(() => {
    if (open) form.reset(garden ? { name: garden.name, environment: garden.environment, light: garden.light, coverImage: garden.coverImage } : { name: "", environment: "indoor", light: "indirect", coverImage: COVERS[0] });
  }, [open, garden, form]);
  const cover = form.watch("coverImage");
  const busy = create.isPending || update.isPending;

  const submit = form.handleSubmit(async (v) => {
    const payload = { ...v, description: garden?.description ?? "" };
    const g = garden ? await update.mutateAsync({ id: garden.id, patch: payload }) : await create.mutateAsync(payload);
    toast.success(garden ? "Đã cập nhật khu vườn" : "Đã tạo khu vườn mới");
    onOpenChange(false);
    onSaved?.(g);
  });

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[92vh] overflow-y-auto rounded-3xl sm:max-w-xl">
        <DialogHeader><DialogTitle>{garden ? "Chỉnh sửa khu vườn" : "Tạo khu vườn mới"}</DialogTitle></DialogHeader>
        <form onSubmit={submit} className="space-y-4" noValidate>
          <div>
            <p className="mb-2 text-sm font-semibold">Ảnh đại diện</p>
            <div className="flex gap-2 overflow-x-auto pb-1">
              {[...new Set([cover, ...COVERS])].map((c) => (
                <button type="button" key={c.slice(0, 80)} onClick={() => form.setValue("coverImage", c)} className={cn("relative size-20 shrink-0 overflow-hidden rounded-2xl ring-offset-2 ring-offset-background", cover === c && "ring-2 ring-leaf")}>
                  <img src={c} alt="" className="size-full object-cover" />
                  {cover === c && <span className="absolute inset-0 grid place-items-center bg-forest/40 text-forest-foreground"><Check className="size-5" /></span>}
                </button>
              ))}
              <button type="button" onClick={() => fileRef.current?.click()} className="grid size-20 shrink-0 place-items-center rounded-2xl border-2 border-dashed text-muted-foreground hover:border-leaf hover:text-leaf">
                <Upload className="size-5" />
              </button>
              <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={async (e) => {
                const f = e.target.files?.[0];
                if (!f) return;
                try {
                  const url = await uploadService.uploadImage(f, "gardens");
                  form.setValue("coverImage", url);
                } catch {
                  toast.error("Tải ảnh bìa khu vườn thất bại");
                } finally {
                  e.target.value = "";
                }
              }} />
            </div>
          </div>
          <Field label="Tên khu vườn" htmlFor="g-name" error={form.formState.errors.name?.message}>
            <Input id="g-name" placeholder="Ví dụ: Ban công phòng ngủ" aria-invalid={!!form.formState.errors.name} {...form.register("name")} />
          </Field>
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label="Môi trường" htmlFor="g-env">
              <Controller control={form.control} name="environment" render={({ field }) => (
                <Select value={field.value} onValueChange={(v) => field.onChange(v as GardenEnvironment)}>
                  <SelectTrigger id="g-env" className="h-11 rounded-[10px]"><SelectValue /></SelectTrigger>
                  <SelectContent>{(Object.keys(ENV_LABEL) as GardenEnvironment[]).map((k) => <SelectItem key={k} value={k}>{t(ENV_LABEL[k])}</SelectItem>)}</SelectContent>
                </Select>
              )} />
            </Field>
            <Field label="Điều kiện ánh sáng" htmlFor="g-light">
              <Controller control={form.control} name="light" render={({ field }) => (
                <Select value={field.value} onValueChange={(v) => field.onChange(v as LightCondition)}>
                  <SelectTrigger id="g-light" className="h-11 rounded-[10px]"><SelectValue /></SelectTrigger>
                  <SelectContent>{(Object.keys(LIGHT_LABEL) as LightCondition[]).map((k) => <SelectItem key={k} value={k}>{t(LIGHT_LABEL[k])}</SelectItem>)}</SelectContent>
                </Select>
              )} />
            </Field>
          </div>
          <DialogFooter>
            <Button type="button" variant="ghost" onClick={() => onOpenChange(false)}>{t("cancel")}</Button>
            <Button type="submit" disabled={busy}>{busy && <Loader2 className="animate-spin" />}{garden ? t("save") : "Tạo khu vườn"}</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
