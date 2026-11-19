"use client";

import { useEffect, useMemo, useState } from "react";
import {
  ArrowDown,
  ArrowUp,
  Bell,
  BookOpen,
  CloudSun,
  History,
  Leaf,
  RotateCcw,
  Save,
  ScanLine,
  ShoppingBag,
  Sparkles,
  UploadCloud,
} from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Switch } from "@/components/ui/switch";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { PageHeader } from "@/components/shared/page-header";
import { DemoBadge } from "@/components/shared/demo-badge";
import { StatusBadge } from "@/components/shared/status-badge";
import { Field } from "@/components/shared/field";
import { ConfirmDialog } from "@/components/shared/confirm-dialog";
import { useSingleton } from "@/hooks/use-singleton";
import { useResourceList, useResourceMutations } from "@/hooks/use-resource";
import { useAuthStore } from "@/stores/auth-store";
import { usePermission } from "@/stores/rbac-store";
import { configVersionsService, flagsService, logAudit, remoteConfigDraftService } from "@/services";
import { formatDateTime } from "@/lib/format";
import { uid } from "@/lib/id";
import type { ConfigVersion, HomeSection, RemoteConfig } from "@/types";

export default function RemoteConfigPage() {
  const adminName = useAuthStore((s) => s.session?.name ?? "Admin");
  const canEdit = usePermission("remote_config", "edit");
  const canPublish = usePermission("remote_config", "publish");

  const draft = useSingleton(remoteConfigDraftService);
  const versions = useResourceList(configVersionsService);
  const { create: createVersion } = useResourceMutations(configVersionsService, { entity: "Phiên bản Remote UI", silent: true });
  const flags = useResourceList(flagsService);
  const { update: updateFlag } = useResourceMutations(flagsService, { entity: "Feature Flag" });

  const [config, setConfig] = useState<RemoteConfig | null>(null);
  const [note, setNote] = useState("");
  const [rollbackTarget, setRollbackTarget] = useState<ConfigVersion | null>(null);

  useEffect(() => {
    if (draft.data) setConfig(structuredClone(draft.data));
  }, [draft.data]);

  const sortedVersions = useMemo(() => [...(versions.data ?? [])].sort((a, b) => b.version - a.version), [versions.data]);
  const latestVersion = sortedVersions[0]?.version ?? 0;

  if (!config) return null;

  const moveSection = (idx: number, dir: -1 | 1) => {
    const target = idx + dir;
    if (target < 0 || target >= config.sections.length) return;
    const next = [...config.sections];
    [next[idx], next[target]] = [next[target], next[idx]];
    setConfig({ ...config, sections: next });
  };

  const updateSection = (id: string, patch: Partial<HomeSection>) => {
    setConfig({
      ...config,
      sections: config.sections.map((s) => (s.id === id ? { ...s, ...patch } : s)),
    });
  };

  const saveDraft = () => {
    draft.save.mutate(config, {
      onSuccess: () => toast.success("Đã lưu bản nháp Remote UI Config"),
    });
  };

  const publishConfig = () => {
    draft.save.mutate(config);
    const nextVer = latestVersion + 1;
    createVersion.mutate(
      {
        id: uid("cfg"),
        version: nextVer,
        status: "published",
        at: new Date().toISOString(),
        by: adminName,
        note: note.trim() || `Cập nhật bố cục & giao diện v${nextVer}`,
        snapshot: structuredClone(config),
      },
      {
        onSuccess: () => {
          logAudit({ action: "Xuất bản Remote UI", target: `Remote UI · v${nextVer}`, before: `v${latestVersion}`, after: `v${nextVer}` });
          toast.success(`Đã xuất bản Remote UI v${nextVer}`);
          setNote("");
        },
      },
    );
  };

  const doRollback = (v: ConfigVersion) => {
    const cloned = structuredClone(v.snapshot);
    setConfig(cloned);
    draft.save.mutate(cloned, {
      onSuccess: () => {
        logAudit({ action: "Rollback Remote UI", target: `Remote UI · v${v.version}`, before: `v${latestVersion}`, after: `v${v.version}` });
        toast.success(`Đã khôi phục bố cục theo v${v.version}`);
      },
    });
  };

  return (
    <>
      <PageHeader
        title="Remote UI Config"
        description="Điều chỉnh bố cục Trang chủ ứng dụng di động, Feature Flags và xem trước trực tiếp (Live Preview)."
        badge={<DemoBadge label="Mô phỏng Live Preview" />}
        actions={
          canEdit && (
            <div className="flex gap-2">
              <Button variant="outline" onClick={saveDraft} disabled={draft.save.isPending}>
                <Save /> Lưu nháp
              </Button>
              {canPublish && (
                <Button onClick={publishConfig} disabled={createVersion.isPending}>
                  <UploadCloud /> Xuất bản (v{latestVersion + 1})
                </Button>
              )}
            </div>
          )
        }
      />

      <div className="grid gap-6 xl:grid-cols-[1.45fr_390px]">
        <Tabs defaultValue="builder">
          <TabsList className="mb-4">
            <TabsTrigger value="builder">Bố cục Trang chủ</TabsTrigger>
            <TabsTrigger value="flags">Feature Flags</TabsTrigger>
            <TabsTrigger value="versions">Lịch sử phiên bản</TabsTrigger>
          </TabsList>

          <TabsContent value="builder" className="space-y-5">
            <div className="card-surface p-5">
              <h3 className="mb-3 text-base font-semibold">Thứ tự & hiển thị các khối Trang chủ</h3>
              <div className="space-y-2.5">
                {config.sections.map((sec, idx) => (
                  <div key={sec.id} className="flex flex-wrap items-center gap-3 rounded-xl border bg-surface-2/40 p-3">
                    <div className="flex flex-col gap-0.5">
                      <Button type="button" size="icon-sm" variant="ghost" className="h-6 w-6" disabled={!canEdit || idx === 0} onClick={() => moveSection(idx, -1)}>
                        <ArrowUp className="size-3.5" />
                      </Button>
                      <Button
                        type="button"
                        size="icon-sm"
                        variant="ghost"
                        className="h-6 w-6"
                        disabled={!canEdit || idx === config.sections.length - 1}
                        onClick={() => moveSection(idx, 1)}
                      >
                        <ArrowDown className="size-3.5" />
                      </Button>
                    </div>
                    <div className="min-w-44 flex-1">
                      <Input
                        value={sec.title}
                        disabled={!canEdit}
                        onChange={(e) => updateSection(sec.id, { title: e.target.value })}
                        className="h-9 bg-card text-sm font-medium"
                      />
                    </div>
                    <Select value={sec.layout} disabled={!canEdit} onValueChange={(layout) => updateSection(sec.id, { layout: layout as HomeSection["layout"] })}>
                      <SelectTrigger className="h-9 w-32 bg-card text-xs">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="carousel">Carousel</SelectItem>
                        <SelectItem value="grid">Lưới (Grid)</SelectItem>
                        <SelectItem value="list">Danh sách</SelectItem>
                      </SelectContent>
                    </Select>
                    <Switch checked={sec.enabled} disabled={!canEdit} onCheckedChange={(enabled) => updateSection(sec.id, { enabled })} />
                  </div>
                ))}
              </div>
            </div>

            <div className="card-surface grid gap-4 p-5 sm:grid-cols-2">
              <div className="sm:col-span-2">
                <h3 className="text-base font-semibold">Giao diện & Nội dung Banner nổi bật</h3>
              </div>
              <Field label="Màu chủ đạo (Primary)">
                <div className="flex items-center gap-2">
                  <Input
                    type="color"
                    className="h-10 w-14 p-1"
                    disabled={!canEdit}
                    value={config.theme.primary}
                    onChange={(e) => setConfig({ ...config, theme: { ...config.theme, primary: e.target.value } })}
                  />
                  <Input
                    className="font-mono text-xs"
                    disabled={!canEdit}
                    value={config.theme.primary}
                    onChange={(e) => setConfig({ ...config, theme: { ...config.theme, primary: e.target.value } })}
                  />
                </div>
              </Field>
              <Field label="Màu nhấn (Accent)">
                <div className="flex items-center gap-2">
                  <Input
                    type="color"
                    className="h-10 w-14 p-1"
                    disabled={!canEdit}
                    value={config.theme.accent}
                    onChange={(e) => setConfig({ ...config, theme: { ...config.theme, accent: e.target.value } })}
                  />
                  <Input
                    className="font-mono text-xs"
                    disabled={!canEdit}
                    value={config.theme.accent}
                    onChange={(e) => setConfig({ ...config, theme: { ...config.theme, accent: e.target.value } })}
                  />
                </div>
              </Field>
              <Field label="Tiêu đề Banner">
                <Input value={config.banner.title} disabled={!canEdit} onChange={(e) => setConfig({ ...config, banner: { ...config.banner, title: e.target.value } })} />
              </Field>
              <Field label="Nút CTA Banner">
                <Input value={config.banner.cta} disabled={!canEdit} onChange={(e) => setConfig({ ...config, banner: { ...config.banner, cta: e.target.value } })} />
              </Field>
              <Field label="Phụ đề Banner" className="sm:col-span-2">
                <Input value={config.banner.subtitle} disabled={!canEdit} onChange={(e) => setConfig({ ...config, banner: { ...config.banner, subtitle: e.target.value } })} />
              </Field>
              <Field label="Ghi chú phiên bản khi xuất bản" className="sm:col-span-2">
                <Input value={note} disabled={!canEdit} onChange={(e) => setNote(e.target.value)} placeholder="VD: Đưa khối Lịch tưới lên đầu trang chủ…" />
              </Field>
            </div>
          </TabsContent>

          <TabsContent value="flags">
            <div className="card-surface divide-y">
              {(flags.data ?? []).map((f) => (
                <div key={f.id} className="flex items-center justify-between gap-4 p-4">
                  <div className="min-w-0">
                    <div className="flex items-center gap-2">
                      <p className="font-semibold text-foreground">{f.name}</p>
                      <span className="rounded bg-surface-2 px-1.5 py-0.5 font-mono text-[11px] text-muted-foreground">{f.key}</span>
                    </div>
                    <p className="mt-0.5 text-xs text-muted-foreground">{f.description}</p>
                    <p className="mt-1 text-[11px] text-muted-foreground">
                      Cập nhật {formatDateTime(f.updatedAt)} bởi {f.updatedBy}
                    </p>
                  </div>
                  <Switch
                    checked={f.enabled}
                    disabled={!canEdit}
                    onCheckedChange={(enabled) =>
                      updateFlag.mutate({
                        id: f.id,
                        patch: { enabled, updatedAt: new Date().toISOString(), updatedBy: adminName },
                        before: String(f.enabled),
                        label: f.name,
                      })
                    }
                  />
                </div>
              ))}
            </div>
          </TabsContent>

          <TabsContent value="versions">
            <div className="space-y-3">
              {sortedVersions.map((v) => (
                <div key={v.id} className="card-surface flex flex-wrap items-center justify-between gap-4 p-4">
                  <div>
                    <div className="flex items-center gap-2">
                      <History className="size-4 text-leaf" />
                      <span className="font-mono text-sm font-semibold">v{v.version}</span>
                      <StatusBadge status={v.status} />
                    </div>
                    <p className="mt-1 text-sm">{v.note}</p>
                    <p className="text-xs text-muted-foreground">
                      {v.by} · {formatDateTime(v.at)} · {v.snapshot.sections.filter((s) => s.enabled).length}/{v.snapshot.sections.length} khối bật
                    </p>
                  </div>
                  {canEdit && (
                    <Button variant="outline" size="sm" onClick={() => setRollbackTarget(v)}>
                      <RotateCcw className="size-3.5" /> Rollback về v{v.version}
                    </Button>
                  )}
                </div>
              ))}
            </div>
          </TabsContent>
        </Tabs>

        <div className="flex flex-col items-center">
          <div className="sticky top-20 w-[340px] rounded-[40px] border-[8px] border-[#1f2923] bg-[#F5F7F3] p-3 shadow-raised">
            <div className="mx-auto mb-3 h-5 w-28 rounded-full bg-[#1f2923]" />
            <div className="h-[580px] space-y-3 overflow-y-auto px-1 pb-4 text-[#26372D]">
              <div className="flex items-center justify-between px-1">
                <div>
                  <p className="text-[11px] text-[#718074]">Chào buổi sáng</p>
                  <p className="text-sm font-bold" style={{ color: config.theme.primary }}>
                    Khu vườn Floria
                  </p>
                </div>
                <span className="grid size-8 place-items-center rounded-full bg-white shadow-xs">
                  <Bell className="size-4" style={{ color: config.theme.primary }} />
                </span>
              </div>

              {config.sections
                .filter((s) => s.enabled)
                .map((sec) => {
                  if (sec.type === "banner") {
                    return (
                      <div key={sec.id} className="rounded-2xl p-3.5 text-white shadow-xs" style={{ backgroundColor: config.theme.primary }}>
                        <p className="text-[10px] uppercase tracking-wider opacity-75">{sec.title}</p>
                        <p className="mt-0.5 text-sm font-semibold">{config.banner.title}</p>
                        <p className="mt-0.5 text-[11px] opacity-85">{config.banner.subtitle}</p>
                        <span className="mt-2 inline-block rounded-lg bg-white px-2.5 py-1 text-[10px] font-semibold" style={{ color: config.theme.primary }}>
                          {config.banner.cta}
                        </span>
                      </div>
                    );
                  }
                  if (sec.type === "quick_actions") {
                    return (
                      <div key={sec.id}>
                        <p className="mb-1.5 text-xs font-semibold">{sec.title}</p>
                        <div className="grid grid-cols-3 gap-2 text-center text-[10px] font-medium">
                          {[
                            [ScanLine, "Quét cây"],
                            [Sparkles, "Floria AI"],
                            [ShoppingBag, "Cửa hàng"],
                          ].map(([Icon, label], i) => {
                            const I = Icon as typeof ScanLine;
                            return (
                              <div key={i} className="rounded-xl bg-white p-2.5 shadow-xs">
                                <I className="mx-auto mb-1 size-4" style={{ color: config.theme.primary }} />
                                {label as string}
                              </div>
                            );
                          })}
                        </div>
                      </div>
                    );
                  }
                  if (sec.type === "weather") {
                    return (
                      <div key={sec.id} className="flex items-center justify-between rounded-2xl bg-white p-3 shadow-xs">
                        <div>
                          <p className="text-[10px] text-[#718074]">{sec.title}</p>
                          <p className="text-sm font-semibold">28°C · Nắng nhẹ</p>
                          <p className="text-[10px] text-[#718074]">Độ ẩm 72% · Phù hợp tưới sáng</p>
                        </div>
                        <CloudSun className="size-7" style={{ color: config.theme.accent }} />
                      </div>
                    );
                  }
                  if (sec.type === "my_plants") {
                    return (
                      <div key={sec.id}>
                        <p className="mb-1.5 text-xs font-semibold">{sec.title}</p>
                        <div className="grid grid-cols-2 gap-2">
                          {["Trầu bà Nam Mỹ", "Lưỡi hổ"].map((p) => (
                            <div key={p} className="rounded-xl bg-white p-2.5 shadow-xs">
                              <div className="mb-1.5 flex size-7 items-center justify-center rounded-lg" style={{ backgroundColor: `${config.theme.accent}28` }}>
                                <Leaf className="size-3.5" style={{ color: config.theme.primary }} />
                              </div>
                              <p className="text-[11px] font-semibold">{p}</p>
                              <p className="text-[10px] text-[#718074]">Khoẻ mạnh</p>
                            </div>
                          ))}
                        </div>
                      </div>
                    );
                  }
                  if (sec.type === "reminders") {
                    return (
                      <div key={sec.id} className="rounded-2xl bg-white p-3 shadow-xs">
                        <p className="text-xs font-semibold">{sec.title}</p>
                        <p className="mt-1 text-[11px] text-[#718074]">• Tưới Monstera ban công (17:30)</p>
                      </div>
                    );
                  }
                  if (sec.type === "shop") {
                    return (
                      <div key={sec.id} className="rounded-2xl bg-white p-3 shadow-xs">
                        <p className="text-xs font-semibold">{sec.title}</p>
                        <p className="mt-1 text-[11px] text-[#718074]">Phân trùn quế 1kg · 79.000 ₫</p>
                      </div>
                    );
                  }
                  return (
                    <div key={sec.id} className="flex items-center gap-2 rounded-2xl bg-white p-3 shadow-xs">
                      <BookOpen className="size-4" style={{ color: config.theme.primary }} />
                      <div>
                        <p className="text-xs font-semibold">{sec.title}</p>
                        <p className="text-[10px] text-[#718074]">Cách tưới cây mùa mưa</p>
                      </div>
                    </div>
                  );
                })}
            </div>
          </div>
          <p className="mt-2 text-xs text-muted-foreground">Mobile Live Preview (mô phỏng giao diện Floria App)</p>
        </div>
      </div>

      <ConfirmDialog
        open={!!rollbackTarget}
        onOpenChange={(o) => !o && setRollbackTarget(null)}
        title={`Khôi phục về phiên bản v${rollbackTarget?.version}?`}
        description="Bản nháp hiện tại sẽ được thay thế bằng cấu hình của phiên bản đã chọn."
        confirmLabel="Khôi phục"
        onConfirm={() => rollbackTarget && doRollback(rollbackTarget)}
      />
    </>
  );
}
