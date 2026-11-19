"use client";

import { useEffect, useMemo, useState } from "react";
import { ArrowRight, Clock, Image as ImageIcon, Pencil, Plus, Trash2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Switch } from "@/components/ui/switch";
import { PageHeader } from "@/components/shared/page-header";
import { SmartImage } from "@/components/shared/smart-image";
import { StatusBadge } from "@/components/shared/status-badge";
import { FormDialog } from "@/components/shared/form-dialog";
import { ConfirmDialog } from "@/components/shared/confirm-dialog";
import { Field } from "@/components/shared/field";
import { ImageUploader } from "@/components/shared/image-uploader";
import { useResourceList, useResourceMutations } from "@/hooks/use-resource";
import { usePermission } from "@/stores/rbac-store";
import { bannersService } from "@/services";
import { IMAGES } from "@/mocks/images";
import { formatDate } from "@/lib/format";
import { uid } from "@/lib/id";
import type { Banner } from "@/types";

export default function BannersPage() {
  const list = useResourceList(bannersService);
  const { create, update, remove } = useResourceMutations(bannersService, { entity: "Banner" });
  const canCreate = usePermission("content", "create");
  const canEdit = usePermission("content", "edit");
  const canDelete = usePermission("content", "delete");

  const [editing, setEditing] = useState<Banner | null | undefined>(undefined);
  const [del, setDel] = useState<Banner | null>(null);
  const [form, setForm] = useState<Banner>({
    id: "",
    title: "",
    subtitle: "",
    cta: "Khám phá",
    deepLink: "floria://shop",
    image: IMAGES.bannerHome,
    startDate: new Date().toISOString().slice(0, 10),
    endDate: new Date(Date.now() + 1000 * 60 * 60 * 24 * 30).toISOString().slice(0, 10),
    active: true,
    order: 1,
  });

  useEffect(() => {
    if (editing === undefined) return;
    if (editing) {
      setForm({ ...editing, startDate: editing.startDate.slice(0, 10), endDate: editing.endDate.slice(0, 10) });
    } else {
      setForm({
        id: uid("bnr"),
        title: "",
        subtitle: "",
        cta: "Xem ngay",
        deepLink: "floria://shop",
        image: IMAGES.bannerHome,
        startDate: new Date().toISOString().slice(0, 10),
        endDate: new Date(Date.now() + 1000 * 60 * 60 * 24 * 30).toISOString().slice(0, 10),
        active: true,
        order: (list.data?.length ?? 0) + 1,
      });
    }
  }, [editing, list.data?.length]);

  const sorted = useMemo(() => [...(list.data ?? [])].sort((a, b) => a.order - b.order), [list.data]);
  const activeBanners = sorted.filter((b) => b.active);

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.title.trim()) {
      toast.error("Vui lòng nhập tiêu đề banner");
      return;
    }
    const payload: Banner = {
      ...form,
      startDate: new Date(form.startDate).toISOString(),
      endDate: new Date(form.endDate).toISOString(),
    };
    if (editing) update.mutate({ id: payload.id, patch: payload, label: payload.title }, { onSuccess: () => setEditing(undefined) });
    else create.mutate(payload, { onSuccess: () => setEditing(undefined) });
  };

  return (
    <>
      <PageHeader
        title="Banner trang chủ"
        description="Quản lý carousel banner hiển thị trên màn hình Trang chủ của ứng dụng Floria."
        actions={
          canCreate && (
            <Button onClick={() => setEditing(null)}>
              <Plus /> Thêm banner
            </Button>
          )
        }
      />

      <div className="card-surface mb-6 p-5">
        <div className="mb-3 flex items-center justify-between">
          <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">Xem trước banner đang hoạt động ({activeBanners.length})</p>
        </div>
        <div className="grid gap-4 md:grid-cols-2">
          {activeBanners.map((b) => (
            <div key={b.id} className="relative overflow-hidden rounded-2xl border bg-forest-deep text-white">
              <SmartImage
                src={b.image}
                alt={b.title}
                className="h-44 w-full opacity-75"
                fallback={<div className="h-44 w-full bg-forest-deep" />}
              />
              <div className="absolute inset-0 bg-gradient-to-r from-forest-deep/90 via-forest-deep/50 to-transparent p-5 flex flex-col justify-end">
                <p className="text-lg font-semibold">{b.title}</p>
                <p className="mt-1 text-xs text-white/85">{b.subtitle}</p>
                <span className="mt-3 inline-flex w-fit items-center gap-1 rounded-lg bg-white px-3 py-1.5 text-xs font-semibold text-forest">
                  {b.cta} <ArrowRight className="size-3" />
                </span>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {sorted.map((b) => (
          <div key={b.id} className="card-surface overflow-hidden">
            <div className="relative aspect-[2/1] bg-surface-2">
              <SmartImage
                src={b.image}
                alt={b.title}
                className="size-full"
                fallback={
                  <div className="grid size-full place-items-center bg-surface-2">
                    <ImageIcon className="size-8 text-muted-foreground" />
                  </div>
                }
              />
              <span className="absolute left-2 top-2 rounded-md bg-card/90 px-2 py-0.5 font-mono text-[11px] font-semibold">
                {String(b.startHour ?? b.order).padStart(2, "0")}:00 – {String(b.endHour ?? ((b.order + 4) % 24)).padStart(2, "0")}:00
              </span>
              <span className="absolute right-2 top-2">
                <StatusBadge status={b.active ? "visible" : "hidden"} />
              </span>
            </div>
            <div className="p-4">
              <div className="mb-1 flex items-center gap-1.5 text-[11px] font-medium text-primary">
                <Clock className="size-3" /> {b.cta}
              </div>
              <h4 className="font-semibold">{b.title}</h4>
              <p className="mt-0.5 text-xs text-muted-foreground">{b.subtitle}</p>
              <div className="mt-4 flex items-center justify-between border-t pt-3">
                <div className="flex items-center gap-2">
                  <Switch checked={b.active} disabled={!canEdit} onCheckedChange={(active) => update.mutate({ id: b.id, patch: { active }, label: b.title })} />
                  <span className="text-xs text-muted-foreground">{b.active ? "Đang bật" : "Đang tắt"}</span>
                </div>
                <div className="flex gap-1">
                  {canEdit && (
                    <Button size="icon-sm" variant="ghost" onClick={() => setEditing(b)}>
                      <Pencil />
                    </Button>
                  )}
                  {canDelete && (
                    <Button size="icon-sm" variant="ghost" className="text-danger" onClick={() => setDel(b)}>
                      <Trash2 />
                    </Button>
                  )}
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      <FormDialog open={editing !== undefined} onOpenChange={(o) => !o && setEditing(undefined)} title={editing ? `Sửa banner · ${editing.title}` : "Thêm banner mới"} onSubmit={submit}>
        <div className="grid gap-4">
          <Field label="Ảnh banner">
            <ImageUploader value={form.image} aspect="wide" onChange={(image) => setForm({ ...form, image })} />
          </Field>
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label="Tiêu đề chính (mainTitle)">
              <Input value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
            </Field>
            <Field label="Nhãn khung giờ (badgeText)">
              <Input value={form.cta} onChange={(e) => setForm({ ...form, cta: e.target.value })} placeholder="VD: Khung giờ chiều mát" />
            </Field>
            <Field label="Lời khuyên chăm sóc (advice)" className="sm:col-span-2">
              <Input value={form.subtitle} onChange={(e) => setForm({ ...form, subtitle: e.target.value })} />
            </Field>
            <Field label="Giờ bắt đầu (startHour: 0–23)">
              <Input
                type="number"
                min={0}
                max={23}
                value={form.startHour ?? 6}
                onChange={(e) => {
                  const h = Math.min(23, Math.max(0, Number(e.target.value) || 0));
                  setForm({ ...form, startHour: h, order: h });
                }}
              />
            </Field>
            <Field label="Giờ kết thúc (endHour: 0–23)">
              <Input
                type="number"
                min={0}
                max={23}
                value={form.endHour ?? 10}
                onChange={(e) => setForm({ ...form, endHour: Math.min(23, Math.max(0, Number(e.target.value) || 0)) })}
              />
            </Field>
          </div>
        </div>
      </FormDialog>

      <ConfirmDialog
        open={!!del}
        onOpenChange={(o) => !o && setDel(null)}
        title={`Xoá banner "${del?.title}"?`}
        tone="danger"
        confirmLabel="Xoá"
        onConfirm={() => del && remove.mutate({ id: del.id, label: del.title })}
      />
    </>
  );
}
