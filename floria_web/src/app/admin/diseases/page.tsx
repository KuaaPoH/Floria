"use client";

import { useEffect, useMemo, useState } from "react";
import { useSearchParams } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { Controller, useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import type { ColumnDef } from "@tanstack/react-table";
import { Microscope, Pencil, Plus, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { PageHeader } from "@/components/shared/page-header";
import { DataTable } from "@/components/shared/data-table";
import { SearchInput } from "@/components/shared/search-input";
import { FilterSelect } from "@/components/shared/filter-select";
import { SmartImage } from "@/components/shared/smart-image";
import { StatusBadge } from "@/components/shared/status-badge";
import { ConfirmDialog } from "@/components/shared/confirm-dialog";
import { DetailDrawer, DetailSection, InfoGrid } from "@/components/shared/detail-drawer";
import { FormDialog } from "@/components/shared/form-dialog";
import { Field } from "@/components/shared/field";
import { ImageUploader } from "@/components/shared/image-uploader";
import { useResourceList, useResourceMutations } from "@/hooks/use-resource";
import { usePermission } from "@/stores/rbac-store";
import { diseasesService } from "@/services";
import { apiRequest } from "@/lib/api-client";
import { IS_MOCK } from "@/lib/config";
import { DISEASE_CATEGORIES } from "@/mocks/diseases";
import { DISEASE_CLASSES } from "@/mocks/ai-classes";
import { formatDate } from "@/lib/format";
import { uid } from "@/lib/id";
import type { Disease, Severity } from "@/types";

const SEVERITY_OPTIONS = [
  { label: "Bình thường", severity: "low" as Severity },
  { label: "Cảnh báo", severity: "medium" as Severity },
  { label: "Nguy hiểm", severity: "high" as Severity },
  { label: "Nghiêm trọng", severity: "critical" as Severity },
];

const lines = (s: string) =>
  s
    .split("\n")
    .map((x) => x.trim())
    .filter(Boolean);

const schema = z.object({
  name: z.string().trim().min(2, "Nhập tên bệnh"),
  enName: z.string().trim().min(2, "Nhập tên tiếng Anh"),
  category: z.string().trim().min(1, "Nhập nhóm bệnh"),
  agent: z.string().trim().min(1, "Nhập tác nhân gây bệnh"),
  severityLabel: z.string().min(1, "Chọn mức độ"),
  mechanism: z.string(),
  favorableConditions: z.string(),
  prevention: z.string(),
  image: z.string(),
  aiClassId: z.string(),
});
type Values = z.infer<typeof schema>;

function severityFromLabel(label: string): Severity {
  const s = label.toLowerCase();
  if (s.includes("nghiêm trọng")) return "critical";
  if (s.includes("nguy hiểm") || s.includes("cao")) return "high";
  if (s.includes("cảnh báo") || s.includes("trung bình")) return "medium";
  return "low";
}

export default function DiseasesPage() {
  const searchParams = useSearchParams();
  const q = searchParams.get("q") ?? "";
  const list = useResourceList(diseasesService);
  const aiClasses = useQuery({
    queryKey: ["ai-classes"],
    queryFn: () => apiRequest<{ diseases: Array<{ id: number; name: string }> }>("/ai-classes"),
    enabled: !IS_MOCK,
  });
  const diseaseClasses = IS_MOCK ? DISEASE_CLASSES : (aiClasses.data?.diseases ?? DISEASE_CLASSES);

  const { create, update, remove } = useResourceMutations(diseasesService, { entity: "Bệnh" });
  const canCreate = usePermission("botanical", "create");
  const canEdit = usePermission("botanical", "edit");
  const canDelete = usePermission("botanical", "delete");
  const [search, setSearch] = useState(q);
  const [cat, setCat] = useState("all");
  const [sev, setSev] = useState("all");
  const [view, setView] = useState<Disease | null>(null);
  const [editing, setEditing] = useState<Disease | null | undefined>(undefined);
  const [del, setDel] = useState<Disease | null>(null);

  useEffect(() => {
    if (q) setSearch(q);
  }, [q]);

  const categories = useMemo(() => {
    const set = new Set<string>(DISEASE_CATEGORIES);
    for (const d of list.data ?? []) {
      if (d.category) set.add(d.category);
    }
    return Array.from(set);
  }, [list.data]);

  const rows = useMemo(() => {
    const s = search.toLowerCase();
    return (list.data ?? []).filter(
      (d) =>
        (!s || d.name.toLowerCase().includes(s) || d.enName.toLowerCase().includes(s)) &&
        (cat === "all" || d.category === cat) &&
        (sev === "all" || (d.severityLabel ?? d.severity) === sev),
    );
  }, [list.data, search, cat, sev]);

  const columns: ColumnDef<Disease, unknown>[] = [
    {
      accessorKey: "name",
      header: "Bệnh",
      cell: ({ row }) => (
        <div className="flex items-center gap-3">
          <SmartImage
            src={row.original.images[0]}
            alt={row.original.name}
            className="size-10 shrink-0 rounded-lg border"
            fallback={
              <span className="grid size-10 shrink-0 place-items-center rounded-lg bg-warning-soft text-warning">
                <Microscope className="size-4" />
              </span>
            }
          />
          <div>
            <p className="font-medium">{row.original.name}</p>
            <p className="text-xs text-muted-foreground">{row.original.enName}</p>
          </div>
        </div>
      ),
    },
    { accessorKey: "category", header: "Nhóm" },
    { accessorKey: "agent", header: "Tác nhân (pathogen)" },
    {
      accessorKey: "severity",
      header: "Mức độ (severity)",
      cell: ({ row }) => (
        <StatusBadge status={row.original.severity} label={row.original.severityLabel ?? row.original.severity} />
      ),
    },
    {
      accessorKey: "aiClassId",
      header: "AI class",
      cell: ({ row }) =>
        row.original.aiClassId === null ? (
          "—"
        ) : (
          <span className="font-mono text-xs">
            #{row.original.aiClassId} {row.original.aiClassName}
          </span>
        ),
    },
    {
      id: "a",
      header: "",
      enableSorting: false,
      cell: ({ row }) => (
        <div className="flex justify-end gap-1" onClick={(e) => e.stopPropagation()}>
          {canEdit && (
            <Button size="icon-sm" variant="ghost" onClick={() => setEditing(row.original)} aria-label="Sửa">
              <Pencil />
            </Button>
          )}
          {canDelete && (
            <Button
              size="icon-sm"
              variant="ghost"
              className="text-danger"
              onClick={() => setDel(row.original)}
              aria-label="Xoá"
            >
              <Trash2 />
            </Button>
          )}
        </div>
      ),
    },
  ];

  return (
    <>
      <PageHeader
        title="Từ điển bệnh cây"
        description="Triệu chứng, cơ chế gây bệnh và hướng dẫn phòng ngừa — đồng bộ với Firestore DiseasesInfo."
        actions={
          canCreate && (
            <Button onClick={() => setEditing(null)}>
              <Plus /> Thêm bệnh
            </Button>
          )
        }
      />
      <DataTable
        columns={columns}
        data={rows}
        loading={list.isLoading}
        onRowClick={setView}
        toolbar={
          <>
            <SearchInput value={search} onChange={setSearch} placeholder="Tìm tên bệnh…" />
            <FilterSelect
              value={cat}
              onChange={setCat}
              allLabel="Mọi nhóm"
              options={categories.map((c) => ({ value: c, label: c }))}
            />
            <FilterSelect
              value={sev}
              onChange={setSev}
              allLabel="Mọi mức độ"
              options={SEVERITY_OPTIONS.map((o) => ({ value: o.label, label: o.label }))}
            />
          </>
        }
      />
      <DetailDrawer
        open={!!view}
        onOpenChange={(o) => !o && setView(null)}
        title={view?.name}
        description={view && `${view.enName} · ${view.category}`}
        footer={
          view && canEdit ? (
            <Button
              onClick={() => {
                setEditing(view);
                setView(null);
              }}
            >
              <Pencil /> Chỉnh sửa
            </Button>
          ) : undefined
        }
      >
        {view && (
          <>
            {view.images.length > 0 && (
              <div className="mb-5 grid grid-cols-2 gap-2">
                {view.images.map((src, i) => (
                  <SmartImage
                    key={i}
                    src={src}
                    alt={view.name}
                    className="aspect-square w-full rounded-xl border"
                    fallback={
                      <span className="grid aspect-square w-full place-items-center rounded-xl bg-muted">
                        <Microscope className="size-8 text-muted-foreground" />
                      </span>
                    }
                  />
                ))}
              </div>
            )}
            <DetailSection title="Tổng quan">
              <InfoGrid
                items={[
                  { label: "Tác nhân (pathogen)", value: view.agent },
                  {
                    label: "Mức độ (severity)",
                    value: <StatusBadge status={view.severity} label={view.severityLabel ?? view.severity} />,
                  },
                  { label: "AI class ID", value: view.aiClassId !== null ? `#${view.aiClassId} ${view.aiClassName}` : "—" },
                  { label: "Cập nhật", value: formatDate(view.updatedAt) },
                ]}
              />
            </DetailSection>
            {view.mechanism && (
              <DetailSection title="Cơ chế gây bệnh (mechanism)">
                <p className="text-sm leading-relaxed text-foreground">{view.mechanism}</p>
              </DetailSection>
            )}
            {view.favorableConditions && (
              <DetailSection title="Điều kiện thuận lợi (favorableConditions)">
                <p className="text-sm leading-relaxed text-foreground">{view.favorableConditions}</p>
              </DetailSection>
            )}
            {view.prevention.length > 0 && (
              <DetailSection title="Phòng ngừa (prevention)">
                <ol className="space-y-2">
                  {view.prevention.map((x, i) => (
                    <li key={i} className="flex gap-2 text-sm">
                      <span className="grid size-5 shrink-0 place-items-center rounded-full bg-accent text-[10px] font-semibold text-forest">
                        {i + 1}
                      </span>
                      {x}
                    </li>
                  ))}
                </ol>
              </DetailSection>
            )}
          </>
        )}
      </DetailDrawer>
      <DiseaseForm
        open={editing !== undefined}
        disease={editing}
        diseaseClasses={diseaseClasses}
        onOpenChange={(o) => !o && setEditing(undefined)}
        pending={create.isPending || update.isPending}
        onSubmit={(d) =>
          editing
            ? update.mutate({ id: d.id, patch: d, label: d.name }, { onSuccess: () => setEditing(undefined) })
            : create.mutate(d, { onSuccess: () => setEditing(undefined) })
        }
      />
      <ConfirmDialog
        open={!!del}
        onOpenChange={(o) => !o && setDel(null)}
        title={`Xoá ${del?.name}?`}
        tone="danger"
        confirmLabel="Xoá"
        description="Kết quả chẩn đoán liên kết sẽ không còn hiển thị thông tin bệnh này."
        onConfirm={() => del && remove.mutate({ id: del.id, label: del.name })}
      />
    </>
  );
}

function DiseaseForm({
  open,
  onOpenChange,
  disease,
  diseaseClasses,
  onSubmit,
  pending,
}: {
  open: boolean;
  onOpenChange: (o: boolean) => void;
  disease?: Disease | null;
  diseaseClasses: Array<{ id: number; name: string }>;
  onSubmit: (d: Disease) => void;
  pending: boolean;
}) {
  const form = useForm<Values>({ resolver: zodResolver(schema) });

  useEffect(() => {
    if (!open) return;
    form.reset(
      disease
        ? {
            name: disease.name,
            enName: disease.enName,
            category: disease.category,
            agent: disease.agent,
            severityLabel: disease.severityLabel ?? "Cảnh báo",
            mechanism: disease.mechanism ?? disease.symptoms[0] ?? "",
            favorableConditions: disease.favorableConditions ?? disease.symptoms[1] ?? "",
            prevention: disease.prevention.join("\n"),
            image: disease.images[0] ?? "",
            aiClassId: disease.aiClassId === null ? "none" : String(disease.aiClassId),
          }
        : {
            name: "",
            enName: "",
            category: "Bệnh nấm",
            agent: "",
            severityLabel: "Cảnh báo",
            mechanism: "",
            favorableConditions: "",
            prevention: "",
            image: "",
            aiClassId: "none",
          },
    );
  }, [open, disease, form]);

  const e = form.formState.errors;
  const submit = form.handleSubmit((v) => {
    const cid = v.aiClassId === "none" ? null : Number(v.aiClassId);
    const matchedClass = cid === null ? undefined : diseaseClasses.find((c) => c.id === cid);
    onSubmit({
      id: disease?.id ?? uid("dis"),
      name: v.name.trim(),
      enName: v.enName.trim(),
      category: v.category.trim(),
      agent: v.agent.trim(),
      severity: severityFromLabel(v.severityLabel),
      severityLabel: v.severityLabel,
      mechanism: v.mechanism.trim(),
      favorableConditions: v.favorableConditions.trim(),
      symptoms: [v.mechanism.trim(), v.favorableConditions.trim()].filter(Boolean),
      treatment: disease?.treatment ?? [],
      prevention: lines(v.prevention),
      images: v.image ? [v.image, ...(disease?.images.slice(1) ?? [])] : disease?.images ?? [],
      aiClassId: cid,
      aiClassName: matchedClass?.name ?? disease?.aiClassName ?? "",
      updatedAt: new Date().toISOString(),
    });
  });

  return (
    <FormDialog
      open={open}
      onOpenChange={onOpenChange}
      title={disease ? `Sửa · ${disease.name}` : "Thêm bệnh mới"}
      onSubmit={submit}
      pending={pending}
      className="sm:max-w-3xl"
    >
      <div className="grid gap-5 md:grid-cols-[190px_1fr]">
        <Controller
          control={form.control}
          name="image"
          render={({ field }) => (
            <Field label="Ảnh minh họa (Admin)">
              <ImageUploader value={field.value} onChange={field.onChange} />
            </Field>
          )}
        />
        <div className="grid gap-3.5 sm:grid-cols-2">
          <Field label="Tên bệnh (nameVi)" error={e.name?.message}>
            <Input placeholder="VD: Bệnh Thán Thư" {...form.register("name")} />
          </Field>
          <Field label="Tên tiếng Anh (nameEn)" error={e.enName?.message}>
            <Input placeholder="VD: Anthracnose" {...form.register("enName")} />
          </Field>
          <Field label="Nhóm bệnh" error={e.category?.message}>
            <Input placeholder="VD: Bệnh nấm, Vi khuẩn, Sinh lý..." {...form.register("category")} />
          </Field>
          <Controller
            control={form.control}
            name="severityLabel"
            render={({ field }) => (
              <Field label="Mức độ (severity)">
                <Select value={field.value} onValueChange={field.onChange}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {SEVERITY_OPTIONS.map((o) => (
                      <SelectItem key={o.label} value={o.label}>
                        {o.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </Field>
            )}
          />
          <Field label="Tác nhân gây bệnh (pathogen)" error={e.agent?.message} className="sm:col-span-2">
            <Input placeholder="VD: Nấm Colletotrichum spp." {...form.register("agent")} />
          </Field>
        </div>
      </div>

      <div className="mt-4 grid gap-3.5 sm:grid-cols-2">
        <Field label="Cơ chế gây bệnh (mechanism)">
          <Textarea rows={4} {...form.register("mechanism")} />
        </Field>
        <Field label="Điều kiện thuận lợi (favorableConditions)">
          <Textarea rows={4} {...form.register("favorableConditions")} />
        </Field>
        <Field label="Biện pháp phòng ngừa (prevention)" className="sm:col-span-2">
          <Textarea rows={3} {...form.register("prevention")} />
        </Field>
      </div>

      <Controller
        control={form.control}
        name="aiClassId"
        render={({ field }) => (
          <Field label="AI class (tf_efficientnetv2_b0_disease)" className="mt-4 sm:w-1/2">
            <Select value={field.value} onValueChange={field.onChange}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="none">— Chưa ánh xạ —</SelectItem>
                {diseaseClasses.map((c) => (
                  <SelectItem key={c.id} value={String(c.id)}>
                    #{c.id} · {c.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </Field>
        )}
      />
    </FormDialog>
  );
}
