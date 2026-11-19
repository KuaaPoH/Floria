"use client";

import { useEffect } from "react";
import { useQuery } from "@tanstack/react-query";
import { Controller, useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { FormDialog } from "@/components/shared/form-dialog";
import { Field } from "@/components/shared/field";
import { ImageUploader } from "@/components/shared/image-uploader";
import { apiRequest } from "@/lib/api-client";
import { IS_MOCK } from "@/lib/config";
import { SPECIES_CLASSES } from "@/mocks/ai-classes";
import type { Plant } from "@/types";

const schema = z.object({
  viName: z.string().trim().min(2, "Nhập tên tiếng Việt"),
  sciName: z.string().trim().min(2, "Nhập tên khoa học"),
  category: z.string().trim().min(1, "Nhập loại cây"),
  family: z.string(),
  origin: z.string(),
  identification: z.string(),
  image: z.string(),
  description: z.string(),
  wikiDetail: z.string(),
  light: z.string(),
  watering: z.string(),
  temperature: z.string(),
  humidity: z.string(),
  soil: z.string(),
  toxicityNote: z.string(),
  difficulty: z.string(),
  placements: z.string(),
  aiClassId: z.string(),
});
type Values = z.infer<typeof schema>;

const empty: Values = {
  viName: "",
  sciName: "",
  category: "Cây thân thảo",
  family: "",
  origin: "",
  identification: "",
  image: "",
  description: "",
  wikiDetail: "",
  light: "",
  watering: "",
  temperature: "",
  humidity: "",
  soil: "",
  toxicityNote: "",
  difficulty: "",
  placements: "",
  aiClassId: "none",
};

export function PlantFormDialog({
  open,
  onOpenChange,
  plant,
  onSubmit,
  pending,
}: {
  open: boolean;
  onOpenChange: (o: boolean) => void;
  plant?: Plant | null;
  onSubmit: (p: Plant) => void;
  pending?: boolean;
}) {
  const form = useForm<Values>({ resolver: zodResolver(schema), defaultValues: empty });
  const aiClasses = useQuery({
    queryKey: ["ai-classes"],
    queryFn: () => apiRequest<{ species: Array<{ id: number; name: string }> }>("/ai-classes"),
    enabled: !IS_MOCK,
  });
  const speciesClasses = IS_MOCK ? SPECIES_CLASSES : (aiClasses.data?.species ?? SPECIES_CLASSES);

  useEffect(() => {
    if (!open) return;
    if (plant) {
      form.reset({
        viName: plant.viName ?? "",
        sciName: plant.sciName ?? "",
        category: plant.category ?? "",
        family: plant.family ?? "",
        origin: plant.origin ?? "",
        identification: plant.identification ?? "",
        image: plant.image ?? "",
        description: plant.description ?? "",
        wikiDetail: plant.wikiDetail ?? "",
        light: plant.light ?? "",
        watering: plant.watering ?? "",
        temperature: plant.temperature ?? "",
        humidity: plant.humidity ?? "",
        soil: plant.soil ?? "",
        toxicityNote: plant.toxicityNote ?? "",
        difficulty: plant.difficulty ?? "",
        placements: (plant.placements ?? []).join(", "),
        aiClassId: plant.aiClassId === null ? "none" : String(plant.aiClassId),
      });
    } else {
      form.reset(empty);
    }
  }, [open, plant, form]);

  const e = form.formState.errors;

  const submit = form.handleSubmit((v) => {
    const classId = v.aiClassId === "none" ? null : Number(v.aiClassId);
    const placements = v.placements
      .split(",")
      .map((s) => s.trim())
      .filter(Boolean);
    const petToxic = Boolean(v.toxicityNote && !/không độc|an toàn/i.test(v.toxicityNote));

    onSubmit({
      ...(plant ?? {
        id: v.sciName.trim(),
        enName: v.sciName.trim(),
        relatedDiseaseIds: [],
        careTips: [],
        status: "published" as const,
      }),
      viName: v.viName.trim(),
      sciName: v.sciName.trim(),
      enName: plant?.enName || v.sciName.trim(),
      category: v.category.trim(),
      family: v.family.trim(),
      origin: v.origin.trim(),
      identification: v.identification.trim(),
      image: v.image.trim(),
      description: v.description.trim(),
      wikiDetail: v.wikiDetail.trim(),
      light: v.light.trim(),
      watering: v.watering.trim(),
      temperature: v.temperature.trim(),
      humidity: v.humidity.trim(),
      soil: v.soil.trim(),
      toxicityNote: v.toxicityNote.trim(),
      difficulty: v.difficulty.trim(),
      placements,
      petToxic,
      careTips: v.difficulty.trim() ? [v.difficulty.trim()] : plant?.careTips ?? [],
      aiClassId: classId,
      aiClassName: classId === null ? "" : (speciesClasses.find((c) => c.id === classId)?.name ?? ""),
      updatedAt: new Date().toISOString(),
    } as Plant);
  });

  return (
    <FormDialog
      open={open}
      onOpenChange={onOpenChange}
      title={plant ? `Sửa · ${plant.viName}` : "Thêm loài cây mới"}
      onSubmit={submit}
      pending={pending}
      className="sm:max-w-3xl"
    >
      <div className="grid gap-5 md:grid-cols-[190px_1fr]">
        <Controller
          control={form.control}
          name="image"
          render={({ field }) => (
            <Field label="Ảnh minh họa (Admin)" error={e.image?.message}>
              <ImageUploader value={field.value} onChange={field.onChange} />
            </Field>
          )}
        />
        <div className="grid gap-3.5 sm:grid-cols-2">
          <Field label="Tên tiếng Việt (name_vi)" error={e.viName?.message}>
            <Input placeholder="VD: Cây hoa sứ" {...form.register("viName")} />
          </Field>
          <Field label="Tên khoa học (scientific_name)" error={e.sciName?.message}>
            <Input className="italic" placeholder="VD: Adenium obesum" {...form.register("sciName")} />
          </Field>
          <Field label="Loại cây (plant_type)" error={e.category?.message}>
            <Input placeholder="VD: Cây thân thảo, Cây mọng nước..." {...form.register("category")} />
          </Field>
          <Field label="Họ thực vật (family)">
            <Input placeholder="VD: Araceae (Họ Ráy)" {...form.register("family")} />
          </Field>
          <Field label="Nguồn gốc (origin)">
            <Input placeholder="VD: Đông Nam Á" {...form.register("origin")} />
          </Field>
          <Field label="Vị trí đặt gợi ý (placements)">
            <Input placeholder="Ban công, Phòng khách..." {...form.register("placements")} />
          </Field>
        </div>
      </div>

      <div className="mt-4 grid gap-3.5 sm:grid-cols-2">
        <Field label="Đặc điểm nhận dạng (identification)" className="sm:col-span-2">
          <Input placeholder="Mô tả đặc điểm lá, thân, hoa..." {...form.register("identification")} />
        </Field>
        <Field label="Mô tả ngắn (short_desc)" className="sm:col-span-2">
          <Textarea rows={2} {...form.register("description")} />
        </Field>
        <Field label="Bài viết chi tiết (wiki_detail)" className="sm:col-span-2">
          <Textarea rows={3} {...form.register("wikiDetail")} />
        </Field>
        <Field label="Ánh sáng (light)">
          <Input placeholder="VD: Sáng gián tiếp" {...form.register("light")} />
        </Field>
        <Field label="Tần suất tưới (water_frequency)">
          <Input placeholder="VD: 2-3 lần/tuần" {...form.register("watering")} />
        </Field>
        <Field label="Nhiệt độ (temperature)">
          <Input placeholder="VD: 18-28°C" {...form.register("temperature")} />
        </Field>
        <Field label="Độ ẩm (humidity)">
          <Input placeholder="VD: 60-80%" {...form.register("humidity")} />
        </Field>
        <Field label="Loại rễ (root_type)">
          <Input placeholder="VD: Rễ chùm, sinh trưởng nông" {...form.register("soil")} />
        </Field>
        <Field label="Độc tính (toxicity)">
          <Input placeholder="VD: Có độc nhẹ / An toàn" {...form.register("toxicityNote")} />
        </Field>
        <Field label="Độ khó chăm sóc (difficulty)" className="sm:col-span-2">
          <Input placeholder="VD: Dễ chăm sóc, thích nghi tốt trong nhà..." {...form.register("difficulty")} />
        </Field>
        <Controller
          control={form.control}
          name="aiClassId"
          render={({ field }) => (
            <Field label="AI class (tf_efficientnetv2_b0)" className="sm:col-span-2">
              <Select value={field.value} onValueChange={field.onChange}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="none">— Chưa ánh xạ —</SelectItem>
                  {speciesClasses.map((c) => (
                    <SelectItem key={c.id} value={String(c.id)}>
                      #{c.id} · {c.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </Field>
          )}
        />
      </div>
    </FormDialog>
  );
}
