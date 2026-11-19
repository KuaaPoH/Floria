"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { useState } from "react";
import { AlertTriangle, ArrowLeft, Droplets, Flower2, Layers, Pencil, Sun, Thermometer, Waves } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Skeleton } from "@/components/ui/skeleton";
import { SmartImage } from "@/components/shared/smart-image";
import { StatusBadge } from "@/components/shared/status-badge";
import { InfoGrid } from "@/components/shared/detail-drawer";
import { EmptyState } from "@/components/shared/states";
import { PlantFormDialog } from "@/features/botanical/plant-form";
import { useResourceItem, useResourceList, useResourceMutations } from "@/hooks/use-resource";
import { usePermission } from "@/stores/rbac-store";
import { diseasesService, plantsService } from "@/services";
import { SPECIES_CLASSES } from "@/mocks/ai-classes";
import { formatDate } from "@/lib/format";

export default function PlantDetailPage() {
  const params = useParams<{ plantId: string }>();
  const plantId = decodeURIComponent(params?.plantId ?? "");
  const plant = useResourceItem(plantsService, plantId);
  const diseases = useResourceList(diseasesService);
  const { update } = useResourceMutations(plantsService, { entity: "Cây" });
  const canEdit = usePermission("botanical", "edit");
  const canPublish = usePermission("botanical", "publish");
  const [edit, setEdit] = useState(false);

  if (plant.isLoading) return <Skeleton className="h-96 rounded-xl" />;
  const p = plant.data;
  if (!p) {
    return (
      <div className="card-surface">
        <EmptyState
          title="Không tìm thấy cây"
          action={
            <Button asChild variant="outline">
              <Link href="/admin/plants">Về từ điển</Link>
            </Button>
          }
        />
      </div>
    );
  }
  const related = (diseases.data ?? []).filter((d) => p.relatedDiseaseIds.includes(d.id));
  const cls = p.aiClassId === null ? null : SPECIES_CLASSES[p.aiClassId];

  return (
    <>
      <Button asChild variant="ghost" size="sm" className="-ml-2 mb-4">
        <Link href="/admin/plants">
          <ArrowLeft /> Từ điển cây
        </Link>
      </Button>
      <div className="card-surface mb-5 grid overflow-hidden md:grid-cols-[320px_1fr]">
        <SmartImage
          src={p.image}
          alt={p.viName}
          className="aspect-square size-full md:aspect-auto"
          fallback={
            <div className="grid aspect-square size-full place-items-center bg-accent/50 text-forest/70 md:aspect-auto">
              <Flower2 className="size-16" />
            </div>
          }
        />
        <div className="p-6">
          <div className="flex flex-wrap items-center gap-2">
            <StatusBadge status={p.status} />
            <span className="text-xs text-muted-foreground">
              {p.category} · Cập nhật {formatDate(p.updatedAt)}
            </span>
          </div>
          <h1 className="mt-2 text-2xl font-semibold">{p.viName}</h1>
          <p className="italic text-muted-foreground">
            {p.sciName} · {p.enName}
          </p>
          <p className="mt-4 max-w-2xl text-sm leading-relaxed">{p.description}</p>
          {p.petToxic && (
            <div className="mt-4 flex gap-2 rounded-xl bg-danger-soft p-3 text-sm text-danger">
              <AlertTriangle className="mt-0.5 size-4 shrink-0" />
              {p.toxicityNote}
            </div>
          )}
          <div className="mt-5 flex gap-2">
            {canEdit && (
              <Button onClick={() => setEdit(true)}>
                <Pencil /> Chỉnh sửa
              </Button>
            )}
            {canPublish && (
              <Button
                variant="outline"
                onClick={() => update.mutate({ id: p.id, patch: { status: p.status === "published" ? "draft" : "published" }, before: p.status, label: p.viName })}
              >
                {p.status === "published" ? "Chuyển về nháp" : "Xuất bản"}
              </Button>
            )}
          </div>
        </div>
      </div>
      <Tabs defaultValue="general">
        <TabsList className="mb-4 w-full justify-start overflow-x-auto sm:w-auto">
          <TabsTrigger value="general">Thông tin chung</TabsTrigger>
          <TabsTrigger value="care">Hướng dẫn chăm sóc</TabsTrigger>
          <TabsTrigger value="conditions">Điều kiện sinh trưởng</TabsTrigger>
          <TabsTrigger value="diseases">Bệnh liên quan</TabsTrigger>
          <TabsTrigger value="ai">Ánh xạ AI</TabsTrigger>
        </TabsList>
        <TabsContent value="general">
          <InfoGrid
            items={[
              { label: "Tên tiếng Việt", value: p.viName },
              { label: "Tên khoa học", value: <i>{p.sciName}</i> },
              { label: "Tên tiếng Anh", value: p.enName },
              { label: "Danh mục", value: p.category },
              { label: "Độc tính", value: p.petToxic ? "Có" : "Không" },
              { label: "Mã bản ghi", value: <span className="font-mono">{p.id}</span> },
            ]}
          />
        </TabsContent>
        <TabsContent value="care">
          <ol className="card-surface divide-y">
            {p.careTips.map((t, i) => (
              <li key={i} className="flex gap-3 p-4 text-sm">
                <span className="grid size-6 shrink-0 place-items-center rounded-full bg-accent text-xs font-semibold text-forest">{i + 1}</span>
                {t}
              </li>
            ))}
          </ol>
        </TabsContent>
        <TabsContent value="conditions">
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
            {(
              [
                [Sun, "Ánh sáng", p.light],
                [Droplets, "Tưới nước", p.watering],
                [Layers, "Đất", p.soil],
                [Waves, "Độ ẩm", p.humidity],
                [Thermometer, "Nhiệt độ", p.temperature],
              ] as const
            ).map(([Icon, l, v]) => (
              <div key={l} className="card-surface p-4">
                <Icon className="size-5 text-leaf" />
                <p className="mt-2 text-xs text-muted-foreground">{l}</p>
                <p className="text-sm font-medium">{v}</p>
              </div>
            ))}
          </div>
        </TabsContent>
        <TabsContent value="diseases">
          {related.length === 0 ? (
            <div className="card-surface">
              <EmptyState title="Chưa liên kết bệnh" />
            </div>
          ) : (
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
              {related.map((d) => (
                <Link key={d.id} href={`/diseases?q=${encodeURIComponent(d.name)}`} className="card-surface flex gap-3 p-3 hover:shadow-raised">
                  <img src={d.images[0]} alt="" className="size-16 rounded-lg object-cover" />
                  <div>
                    <p className="font-medium">{d.name}</p>
                    <p className="text-xs text-muted-foreground">{d.agent}</p>
                    <div className="mt-1">
                      <StatusBadge status={d.severity} />
                    </div>
                  </div>
                </Link>
              ))}
            </div>
          )}
        </TabsContent>
        <TabsContent value="ai">
          <InfoGrid
            items={[
              { label: "Mô hình", value: "tf_efficientnetv2_b0.onnx" },
              { label: "Class ID", value: cls ? `#${cls.id}` : "—" },
              { label: "Class name", value: <span className="font-mono">{cls?.name ?? "—"}</span> },
              { label: "Trạng thái", value: cls ? <StatusBadge status="approved" label="Đã ánh xạ" /> : <StatusBadge status="pending" label="Chưa ánh xạ" /> },
            ]}
          />
        </TabsContent>
      </Tabs>
      <PlantFormDialog
        open={edit}
        onOpenChange={setEdit}
        plant={p}
        pending={update.isPending}
        onSubmit={(np) =>
          update.mutate(
            { id: p.id, patch: np, label: np.viName },
            {
              onSuccess: () => {
                setEdit(false);
                plant.refetch();
              },
            },
          )
        }
      />
    </>
  );
}
