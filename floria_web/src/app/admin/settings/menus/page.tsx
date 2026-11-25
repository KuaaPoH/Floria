"use client";

import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Ban, ChevronRight, Eye, EyeOff, FolderPlus, Globe, Menu as MenuIcon, Pencil, Plus, Smartphone, Trash2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Switch } from "@/components/ui/switch";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { PageHeader } from "@/components/shared/page-header";
import { Field } from "@/components/shared/field";
import { FormDialog } from "@/components/shared/form-dialog";
import { ConfirmDialog } from "@/components/shared/confirm-dialog";
import { usePermission } from "@/stores/rbac-store";
import { apiRequest } from "@/lib/api-client";
import { ICON_LABELS, ICON_OPTIONS, resolveIcon } from "@/lib/icon-registry";
import { MODULES } from "@/lib/rbac";
import type { MenuItemDoc, MenuTarget } from "@/lib/server/menu-seed";
import { cn } from "@/lib/utils";

interface MenuFormState {
  id?: string;
  target: MenuTarget;
  parentId: string | null;
  title: string;
  titleEn: string;
  route: string;
  icon: string;
  module: string;
  badgeKey: string;
  order: number;
  visible: boolean;
}

const MOBILE_APP_ROUTES = [
  { value: "home", label: "Trang chủ (home)" },
  { value: "garden", label: "Khu vườn (garden)" },
  { value: "scan", label: "Quét AI / Camera (scan)" },
  { value: "shop", label: "Cửa hàng (shop)" },
  { value: "profile", label: "Cá nhân (profile)" },
] as const;

const TARGET_META: Record<MenuTarget, { label: string; description: string; addButton: string }> = {
  admin_sidebar: {
    label: "Sidebar Admin",
    description: "Cấu trúc 3 cấp: Nhóm cha (VD: WORKSPACE, HỆ THỐNG) → Mục chính (có Icon) → Mục con (trang chức năng).",
    addButton: "Thêm menu",
  },
  mobile_app: {
    label: "Menu App Mobile",
    description: "Thanh điều hướng đáy (Bottom Bar) trên điện thoại. Chỉ gồm 1 cấp các tab chính kèm Icon và tên song ngữ.",
    addButton: "Thêm tab App",
  },
  web_user: {
    label: "Menu Web User",
    description: "Thanh điều hướng cho phiên bản Web người dùng (dùng để cấu hình sẵn cho trang chủ /).",
    addButton: "Thêm menu Web",
  },
};

export default function MenusManagementPage() {
  const qc = useQueryClient();
  const canConfigure = usePermission("system", "configure");

  const [target, setTarget] = useState<MenuTarget>("admin_sidebar");
  const [formOpen, setFormOpen] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<MenuItemDoc | null>(null);
  const [form, setForm] = useState<MenuFormState>({
    target: "admin_sidebar",
    parentId: null,
    title: "",
    titleEn: "",
    route: "",
    icon: "Menu",
    module: "",
    badgeKey: "",
    order: 1,
    visible: true,
  });

  const menusQuery = useQuery({
    queryKey: ["admin-menus", "all"],
    queryFn: () => apiRequest<MenuItemDoc[]>("/menus"),
  });

  const saveMutation = useMutation({
    mutationFn: async (data: MenuFormState) => {
      const payload = {
        target: data.target,
        parentId: data.parentId || null,
        title: data.title.trim(),
        titleEn: data.titleEn.trim() || data.title.trim(),
        route: data.route.trim(),
        icon: data.icon ?? "",
        module: data.module.trim(),
        badgeKey: data.badgeKey.trim(),
        order: Number(data.order) || 1,
        visible: data.visible,
      };
      if (data.id) {
        return apiRequest<MenuItemDoc>(`/menus/${encodeURIComponent(data.id)}`, {
          method: "PATCH",
          body: JSON.stringify(payload),
        });
      }
      return apiRequest<MenuItemDoc>("/menus", {
        method: "POST",
        body: JSON.stringify(payload),
      });
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin-menus"] });
      toast.success(form.id ? "Đã cập nhật mục menu" : "Đã thêm mục menu mới");
      setFormOpen(false);
    },
    onError: (err) => {
      toast.error(err instanceof Error ? err.message : "Không thể lưu mục menu");
    },
  });

  const toggleMutation = useMutation({
    mutationFn: ({ id, visible }: { id: string; visible: boolean }) =>
      apiRequest<MenuItemDoc>(`/menus/${encodeURIComponent(id)}`, {
        method: "PATCH",
        body: JSON.stringify({ visible }),
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin-menus"] });
    },
    onError: (err) => {
      toast.error(err instanceof Error ? err.message : "Không thể đổi trạng thái hiển thị");
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) =>
      apiRequest<{ ok: boolean }>(`/menus/${encodeURIComponent(id)}`, { method: "DELETE" }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin-menus"] });
      toast.success("Đã xóa mục menu");
      setDeleteTarget(null);
    },
    onError: (err) => {
      toast.error(err instanceof Error ? err.message : "Không thể xóa mục menu");
    },
  });

  const itemsForTarget = useMemo(
    () => (menusQuery.data ?? []).filter((m) => m.target === target).sort((a, b) => a.order - b.order),
    [menusQuery.data, target],
  );

  const treeRows = useMemo(() => {
    const rows: { item: MenuItemDoc; depth: number; childCount: number }[] = [];
    const byParent = new Map<string | null, MenuItemDoc[]>();
    for (const item of itemsForTarget) {
      const key = item.parentId ?? null;
      const arr = byParent.get(key) ?? [];
      arr.push(item);
      byParent.set(key, arr);
    }

    const walk = (parentId: string | null, depth: number) => {
      const children = (byParent.get(parentId) ?? []).sort((a, b) => a.order - b.order);
      for (const child of children) {
        const sub = byParent.get(child.id) ?? [];
        rows.push({ item: child, depth, childCount: sub.length });
        walk(child.id, depth + 1);
      }
    };
    walk(null, 0);
    return rows;
  }, [itemsForTarget]);

  const parentCandidates = useMemo(() => {
    if (form.target === "mobile_app") return [];
    // Chỉ cho phép chọn mục cấp 0 hoặc cấp 1 làm cha (tối đa 3 cấp)
    const rootIds = new Set(itemsForTarget.filter((m) => !m.parentId).map((m) => m.id));
    return itemsForTarget.filter((m) => m.id !== form.id && (!m.parentId || rootIds.has(m.parentId)));
  }, [itemsForTarget, form.id, form.target]);

  const openCreate = (parentId: string | null = null) => {
    const siblings = itemsForTarget.filter((m) => (m.parentId ?? null) === parentId);
    const maxOrder = siblings.reduce((m, x) => Math.max(m, x.order || 0), 0);
    setForm({
      target,
      parentId,
      title: "",
      titleEn: "",
      route: target === "mobile_app" ? "home" : "",
      icon: target === "mobile_app" ? "Home" : "LayoutDashboard",
      module: target === "admin_sidebar" && parentId ? "overview" : "",
      badgeKey: "",
      order: maxOrder + 1,
      visible: true,
    });
    setFormOpen(true);
  };

  const openEdit = (item: MenuItemDoc) => {
    setForm({
      id: item.id,
      target: item.target,
      parentId: item.parentId,
      title: item.title,
      titleEn: item.titleEn,
      route: item.route,
      icon: item.icon,
      module: item.module ?? "",
      badgeKey: item.badgeKey ?? "",
      order: item.order,
      visible: item.visible,
    });
    setFormOpen(true);
  };

  const formDepth = useMemo(() => {
    if (form.target !== "admin_sidebar") return 1;
    if (!form.parentId) return 0;
    const parent = itemsForTarget.find((m) => m.id === form.parentId);
    return parent && parent.parentId ? 2 : 1;
  }, [form.target, form.parentId, itemsForTarget]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.title.trim()) {
      toast.error("Vui lòng nhập tên menu");
      return;
    }
    saveMutation.mutate(form);
  };

  const dialogTitle = useMemo(() => {
    if (form.id) return "Chỉnh sửa mục menu";
    if (form.target === "mobile_app") return "Thêm tab cho App Mobile";
    if (form.target === "web_user") return "Thêm menu cho Web User";
    if (formDepth === 0) return "Thêm nhóm cha (Sidebar Admin)";
    if (formDepth === 1) return "Thêm mục chính (Sidebar Admin)";
    return "Thêm mục con (Sidebar Admin)";
  }, [form.id, form.target, formDepth]);

  return (
    <>
      <PageHeader
        title="Quản lý Menu hệ thống"
        description="Quản lý danh mục điều hướng, phân cấp cha-con và biểu tượng (icon) lưu trên CSDL cho Admin Sidebar, App Mobile và Web User."
        actions={
          canConfigure && (
            <Button type="button" onClick={() => openCreate(null)}>
              <FolderPlus /> {TARGET_META[target].addButton}
            </Button>
          )
        }
      />

      <Tabs value={target} onValueChange={(v) => setTarget(v as MenuTarget)}>
        <TabsList className="mb-5">
          <TabsTrigger value="admin_sidebar" className="gap-2">
            <MenuIcon className="size-4" /> Sidebar Admin
          </TabsTrigger>
          <TabsTrigger value="mobile_app" className="gap-2">
            <Smartphone className="size-4" /> Menu App Mobile
          </TabsTrigger>
          <TabsTrigger value="web_user" className="gap-2">
            <Globe className="size-4" /> Menu Web User
          </TabsTrigger>
        </TabsList>

        {(["admin_sidebar", "mobile_app", "web_user"] as const).map((t) => (
          <TabsContent key={t} value={t} className="space-y-4">
            <div className="card-surface p-4 text-xs text-muted-foreground">{TARGET_META[t].description}</div>

            <div className="card-surface overflow-hidden">
              {menusQuery.isLoading ? (
                <div className="p-8 text-center text-sm text-muted-foreground">Đang tải cấu trúc menu từ Firestore…</div>
              ) : treeRows.length === 0 ? (
                <div className="p-8 text-center">
                  <p className="text-sm text-muted-foreground">Chưa có mục menu nào cho nền tảng này.</p>
                  {canConfigure && (
                    <Button type="button" variant="outline" className="mt-3" onClick={() => openCreate(null)}>
                      <Plus /> {TARGET_META[t].addButton}
                    </Button>
                  )}
                </div>
              ) : (
                <div className="divide-y">
                  {treeRows.map(({ item, depth, childCount }) => {
                    const Icon = resolveIcon(item.icon);
                    const isGroupRoot = depth === 0 && target === "admin_sidebar";
                    const showIcon = Boolean(item.icon) && (target !== "admin_sidebar" || depth === 1);
                    const canAddChild = target !== "mobile_app" && depth < 2;
                    return (
                      <div
                        key={item.id}
                        className={cn(
                          "flex flex-wrap items-center justify-between gap-3 px-4 py-3 transition hover:bg-muted/40",
                          isGroupRoot && "bg-surface-2/60",
                        )}
                      >
                        <div className="flex min-w-0 flex-1 items-center gap-3" style={{ paddingLeft: `${depth * 24}px` }}>
                          {depth > 0 && <ChevronRight className="size-3.5 shrink-0 text-muted-foreground" />}
                          {showIcon ? (
                            <div className="grid size-8 shrink-0 place-items-center rounded-lg border bg-card text-muted-foreground">
                              <Icon className="size-4" />
                            </div>
                          ) : isGroupRoot ? null : (
                            <span className="size-1.5 shrink-0 rounded-full bg-muted-foreground/50" />
                          )}
                          <div className="min-w-0">
                            <div className="flex items-center gap-2">
                              <span
                                className={cn(
                                  "truncate text-sm",
                                  isGroupRoot ? "font-bold uppercase tracking-wider text-forest" : "font-medium text-foreground",
                                )}
                              >
                                {item.title}
                              </span>
                              {item.titleEn && item.titleEn !== item.title && (
                                <span className="hidden text-xs text-muted-foreground sm:inline">({item.titleEn})</span>
                              )}
                              <span className="rounded bg-muted px-1.5 py-0.5 font-mono text-[10px] text-muted-foreground">
                                #{item.order}
                              </span>
                              {childCount > 0 && (
                                <span className="rounded-full bg-forest/10 px-2 py-0.5 text-[10px] font-medium text-forest">
                                  {childCount} mục con
                                </span>
                              )}
                            </div>
                            <div className="flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
                              {showIcon && <span>Icon: {ICON_LABELS[item.icon] ?? item.icon}</span>}
                              {showIcon && (item.route || item.module) && <span>·</span>}
                              {item.route && <span className="font-mono">{item.route}</span>}
                              {item.route && item.module && <span>·</span>}
                              {item.module && <span>Quyền: {item.module}</span>}
                            </div>
                          </div>
                        </div>

                        <div className="flex items-center gap-1.5">
                          <span
                            className={cn(
                              "mr-1 inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[11px] font-medium",
                              item.visible ? "bg-success-soft text-success" : "bg-muted text-muted-foreground",
                            )}
                          >
                            {item.visible ? <Eye className="size-3" /> : <EyeOff className="size-3" />}
                            {item.visible ? "Hiện" : "Ẩn"}
                          </span>

                          {canConfigure && (
                            <>
                              {canAddChild && (
                                <Button
                                  type="button"
                                  size="sm"
                                  variant="ghost"
                                  title="Thêm mục con bên trong"
                                  onClick={() => openCreate(item.id)}
                                >
                                  <Plus className="size-3.5" /> Thêm mục
                                </Button>
                              )}
                              <Button
                                type="button"
                                size="icon"
                                variant="ghost"
                                title={item.visible ? "Ẩn menu" : "Hiện menu"}
                                onClick={() => toggleMutation.mutate({ id: item.id, visible: !item.visible })}
                              >
                                {item.visible ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
                              </Button>
                              <Button type="button" size="icon" variant="ghost" title="Chỉnh sửa" onClick={() => openEdit(item)}>
                                <Pencil className="size-4" />
                              </Button>
                              <Button
                                type="button"
                                size="icon"
                                variant="ghost"
                                className="text-danger hover:text-danger"
                                title="Xóa"
                                onClick={() => setDeleteTarget(item)}
                              >
                                <Trash2 className="size-4" />
                              </Button>
                            </>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </TabsContent>
        ))}
      </Tabs>

      <FormDialog
        open={formOpen}
        onOpenChange={setFormOpen}
        title={dialogTitle}
        description="Điền tên hiển thị và chọn vị trí, đường dẫn phù hợp."
        onSubmit={handleSubmit}
        submitLabel={form.id ? "Lưu thay đổi" : "Thêm mới"}
        pending={saveMutation.isPending}
        className="sm:max-w-2xl"
      >
        <div className="grid gap-4 sm:grid-cols-2">
          {form.target !== "mobile_app" && (
            <Field label="Thuộc mục cha nào?">
              <Select
                value={form.parentId ?? "__root__"}
                onValueChange={(v) => setForm((prev) => ({ ...prev, parentId: v === "__root__" ? null : v }))}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="__root__">Là nhóm cha cao nhất (VD: WORKSPACE)</SelectItem>
                  {parentCandidates.map((p) => (
                    <SelectItem key={p.id} value={p.id}>
                      {p.parentId ? `↳ Con của: ${p.title}` : `Nhóm: ${p.title}`}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </Field>
          )}

          <Field label="Thứ tự hiển thị (1, 2, 3...)" className={form.target === "mobile_app" ? "sm:col-span-2" : ""}>
            <Input
              type="number"
              min={1}
              value={form.order}
              onChange={(e) => setForm((prev) => ({ ...prev, order: Number(e.target.value) || 1 }))}
            />
          </Field>

          <Field label="Tên hiển thị (Tiếng Việt) *">
            <Input
              value={form.title}
              onChange={(e) => setForm((prev) => ({ ...prev, title: e.target.value }))}
              placeholder={formDepth === 0 ? "VD: Quản lý mở rộng" : "VD: Tổng quan / Khu vườn"}
            />
          </Field>

          <Field label="Tên hiển thị (Tiếng Anh)">
            <Input
              value={form.titleEn}
              onChange={(e) => setForm((prev) => ({ ...prev, titleEn: e.target.value }))}
              placeholder="Để trống sẽ tự dùng Tiếng Việt"
            />
          </Field>

          {form.target === "mobile_app" ? (
            <Field label="Màn hình mở khi chạm vào tab" className="sm:col-span-2">
              <Select value={form.route || "home"} onValueChange={(v) => setForm((prev) => ({ ...prev, route: v }))}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {MOBILE_APP_ROUTES.map((r) => (
                    <SelectItem key={r.value} value={r.value}>
                      {r.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </Field>
          ) : (
            <Field label="Đích đến / Đường dẫn trang (bỏ trống nếu là nhóm cha)">
              <Input
                className="font-mono text-xs"
                value={form.route}
                onChange={(e) => setForm((prev) => ({ ...prev, route: e.target.value }))}
                placeholder={form.target === "admin_sidebar" ? "/admin/..." : "/..."}
              />
            </Field>
          )}

          {form.target === "admin_sidebar" && (
            <Field label="Phân quyền theo chức năng (RBAC)">
              <Select
                value={form.module || "__none__"}
                onValueChange={(v) => setForm((prev) => ({ ...prev, module: v === "__none__" ? "" : v }))}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="__none__">Không giới hạn (Nhóm cha / Mở chung)</SelectItem>
                  {MODULES.map((m) => (
                    <SelectItem key={m.id} value={m.id}>
                      {m.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </Field>
          )}

          <Field label="Chọn biểu tượng (Icon)" className="sm:col-span-2">
            <div className="grid max-h-48 grid-cols-4 gap-2 overflow-y-auto rounded-xl border p-2.5 sm:grid-cols-6">
              <button
                type="button"
                title="Không chọn icon"
                onClick={() => setForm((prev) => ({ ...prev, icon: "" }))}
                className={cn(
                  "flex flex-col items-center justify-center gap-1 rounded-lg border p-2 text-[11px] transition",
                  !form.icon ? "border-forest bg-forest/10 font-semibold text-forest" : "border-transparent hover:bg-muted",
                )}
              >
                <Ban className="size-4" />
                <span className="w-full truncate text-center">Không chọn</span>
              </button>
              {ICON_OPTIONS.map((iconName) => {
                const IconComp = resolveIcon(iconName);
                const selected = form.icon === iconName;
                return (
                  <button
                    key={iconName}
                    type="button"
                    title={ICON_LABELS[iconName] ?? iconName}
                    onClick={() => setForm((prev) => ({ ...prev, icon: iconName }))}
                    className={cn(
                      "flex flex-col items-center justify-center gap-1 rounded-lg border p-2 text-[11px] transition",
                      selected ? "border-forest bg-forest/10 font-semibold text-forest" : "border-transparent hover:bg-muted",
                    )}
                  >
                    <IconComp className="size-4" />
                    <span className="w-full truncate text-center">{ICON_LABELS[iconName] ?? iconName}</span>
                  </button>
                );
              })}
            </div>
          </Field>

          <div className="flex items-center justify-between rounded-xl border p-3 sm:col-span-2">
            <div>
              <p className="text-sm font-medium">Hiển thị trên thanh menu</p>
              <p className="text-xs text-muted-foreground">Tắt nếu muốn tạm ẩn mục này mà không cần xóa.</p>
            </div>
            <Switch checked={form.visible} onCheckedChange={(checked) => setForm((prev) => ({ ...prev, visible: checked }))} />
          </div>
        </div>
      </FormDialog>

      <ConfirmDialog
        open={!!deleteTarget}
        onOpenChange={(o) => !o && setDeleteTarget(null)}
        title="Xóa mục menu?"
        description={`Mục "${deleteTarget?.title ?? ""}" (và toàn bộ mục con bên trong nếu có) sẽ bị xóa khỏi CSDL Firestore.`}
        confirmLabel="Xóa"
        tone="danger"
        onConfirm={() => deleteTarget && deleteMutation.mutate(deleteTarget.id)}
      />
    </>
  );
}
