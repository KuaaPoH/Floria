"use client";

import { useEffect, useState } from "react";
import type { ColumnDef } from "@tanstack/react-table";
import { RotateCcw, ShieldCheck, Trash2, UserPlus } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { PageHeader } from "@/components/shared/page-header";
import { DataTable } from "@/components/shared/data-table";
import { StatusBadge } from "@/components/shared/status-badge";
import { FormDialog } from "@/components/shared/form-dialog";
import { ConfirmDialog } from "@/components/shared/confirm-dialog";
import { Field } from "@/components/shared/field";
import { UserAvatar } from "@/components/shared/user-avatar";
import { useResourceList, useResourceMutations } from "@/hooks/use-resource";
import { usePermission, useRbacStore } from "@/stores/rbac-store";
import { adminsService, logAudit } from "@/services";
import { ACTION_LABELS, ACTIONS, MODULES, ROLES } from "@/lib/rbac";
import { formatDateTime } from "@/lib/format";
import { uid } from "@/lib/id";
import type { AdminAccount, RoleId } from "@/types";

export default function RolesSettingsPage() {
  const canConfigure = usePermission("system", "configure");
  const { matrix, saving, loadMatrix, toggle, reset } = useRbacStore();
  const [selectedRole, setSelectedRole] = useState<RoleId>("botanist");

  useEffect(() => {
    void loadMatrix();
  }, [loadMatrix]);

  const admins = useResourceList(adminsService);
  const { create, update, remove } = useResourceMutations(adminsService, { entity: "Tài khoản quản trị" });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<AdminAccount | null>(null);
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [role, setRole] = useState<RoleId>("operations");

  const createAdmin = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim() || !email.includes("@")) {
      toast.error("Vui lòng nhập họ tên và email hợp lệ");
      return;
    }
    if (password.trim().length < 6) {
      toast.error("Vui lòng nhập mật khẩu tối thiểu 6 ký tự");
      return;
    }
    create.mutate(
      {
        id: uid("adm"),
        name: name.trim(),
        email: email.trim(),
        password: password.trim(),
        role,
        status: "active",
        lastLogin: new Date().toISOString(),
        twoFA: false,
      } as AdminAccount & { password: string },
      {
        onSuccess: () => {
          setDialogOpen(false);
          setName("");
          setEmail("");
          setPassword("");
        },
      },
    );
  };

  const columns: ColumnDef<AdminAccount, unknown>[] = [
    {
      accessorKey: "name",
      header: "Quản trị viên",
      cell: ({ row }) => (
        <div className="flex items-center gap-3">
          <UserAvatar name={row.original.name} src={row.original.avatar} />
          <div>
            <p className="font-medium">{row.original.name}</p>
            <p className="text-xs text-muted-foreground">{row.original.email}</p>
          </div>
        </div>
      ),
    },
    {
      accessorKey: "role",
      header: "Vai trò",
      cell: ({ row }) => (
        <Select
          value={row.original.role}
          disabled={!canConfigure}
          onValueChange={(v) => update.mutate({ id: row.original.id, patch: { role: v as RoleId }, before: row.original.role, label: row.original.name })}
        >
          <SelectTrigger className="h-8 w-44 text-xs">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {ROLES.map((r) => (
              <SelectItem key={r.id} value={r.id}>
                {r.name}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      ),
    },
    { accessorKey: "lastLogin", header: "Đăng nhập gần nhất", cell: ({ getValue }) => formatDateTime(getValue() as string) },
    {
      accessorKey: "status",
      header: "Trạng thái",
      cell: ({ row }) => <StatusBadge status={row.original.status} />,
    },
    {
      id: "a",
      header: "",
      enableSorting: false,
      cell: ({ row }) =>
        canConfigure ? (
          <div className="flex items-center justify-end gap-1">
            <Button
              size="sm"
              variant="ghost"
              onClick={() =>
                update.mutate({
                  id: row.original.id,
                  patch: { status: row.original.status === "active" ? "disabled" : "active" },
                  before: row.original.status,
                  label: row.original.name,
                })
              }
            >
              {row.original.status === "active" ? "Vô hiệu hoá" : "Kích hoạt"}
            </Button>
            <Button
              size="icon"
              variant="ghost"
              className="text-danger hover:text-danger"
              title="Xóa tài khoản quản trị"
              onClick={() => setDeleteTarget(row.original)}
            >
              <Trash2 className="size-4" />
            </Button>
          </div>
        ) : null,
    },
  ];

  return (
    <>
      <PageHeader title="Quản trị & Phân quyền (RBAC)" description="Quản lý tài khoản nội bộ và ma trận quyền hạn theo từng module trong Floria Admin." />

      <Tabs defaultValue="rbac">
        <TabsList className="mb-5">
          <TabsTrigger value="rbac">Ma trận phân quyền</TabsTrigger>
          <TabsTrigger value="admins">Tài khoản quản trị</TabsTrigger>
        </TabsList>

        <TabsContent value="rbac" className="space-y-4">
          <div className="grid gap-4 md:grid-cols-3">
            {ROLES.map((r) => (
              <button
                key={r.id}
                type="button"
                onClick={() => setSelectedRole(r.id)}
                className={`card-surface p-4 text-left transition ${selectedRole === r.id ? "ring-2 ring-forest" : "hover:border-sage"}`}
              >
                <div className="flex items-center justify-between">
                  <span className="font-semibold text-foreground">{r.name}</span>
                  <ShieldCheck className={`size-4 ${selectedRole === r.id ? "text-forest" : "text-muted-foreground"}`} />
                </div>
                <p className="mt-1 text-xs text-muted-foreground">{r.description}</p>
              </button>
            ))}
          </div>

          <div className="card-surface overflow-hidden">
            <div className="flex flex-wrap items-center justify-between gap-2 border-b px-4 py-3">
              <div>
                <p className="text-sm font-semibold">Quyền của vai trò: {ROLES.find((r) => r.id === selectedRole)?.name}</p>
                {selectedRole === "super_admin" && <p className="text-xs text-muted-foreground">Super Admin luôn có toàn quyền trên mọi module.</p>}
              </div>
              {canConfigure && (
                <Button
                  size="sm"
                  variant="outline"
                  disabled={saving}
                  onClick={async () => {
                    try {
                      await reset();
                      logAudit({ action: "Khôi phục RBAC", target: "Ma trận phân quyền", before: "Tuỳ chỉnh", after: "Mặc định" });
                      toast.success("Đã khôi phục và lưu ma trận phân quyền mặc định");
                    } catch (err) {
                      toast.error(err instanceof Error ? err.message : "Không thể lưu ma trận phân quyền");
                    }
                  }}
                >
                  <RotateCcw className="size-3.5" /> Khôi phục mặc định
                </Button>
              )}
            </div>
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow className="bg-surface-2/60">
                    <TableHead className="min-w-[200px] pl-4">Module</TableHead>
                    {ACTIONS.map((a) => (
                      <TableHead key={a} className="w-24 text-center">
                        {ACTION_LABELS[a]}
                      </TableHead>
                    ))}
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {MODULES.map((m) => (
                    <TableRow key={m.id}>
                      <TableCell className="pl-4 font-medium">{m.name}</TableCell>
                      {ACTIONS.map((a) => {
                        const checked = matrix[selectedRole]?.[m.id]?.includes(a) ?? false;
                        return (
                          <TableCell key={a} className="w-24 text-center">
                            <div className="flex items-center justify-center">
                              <Checkbox
                                checked={checked}
                                disabled={!canConfigure || selectedRole === "super_admin" || saving}
                                onCheckedChange={() => {
                                  void toggle(selectedRole, m.id, a).catch((err) => {
                                    toast.error(err instanceof Error ? err.message : "Không thể cập nhật quyền");
                                  });
                                }}
                                aria-label={`${m.name} - ${ACTION_LABELS[a]}`}
                              />
                            </div>
                          </TableCell>
                        );
                      })}
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          </div>
        </TabsContent>

        <TabsContent value="admins">
          <DataTable
            columns={columns}
            data={admins.data ?? []}
            loading={admins.isLoading}
            toolbar={
              canConfigure ? (
                <div className="flex w-full justify-end">
                  <Button onClick={() => setDialogOpen(true)}>
                    <UserPlus /> Thêm quản trị viên
                  </Button>
                </div>
              ) : undefined
            }
          />
        </TabsContent>
      </Tabs>

      <FormDialog open={dialogOpen} onOpenChange={setDialogOpen} title="Thêm tài khoản quản trị" onSubmit={createAdmin}>
        <div className="grid gap-4">
          <Field label="Họ và tên">
            <Input value={name} onChange={(e) => setName(e.target.value)} placeholder="VD: Nguyễn Minh Tâm" />
          </Field>
          <Field label="Email công vụ">
            <Input type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="tam.nguyen@floria.vn" />
          </Field>
          <Field label="Mật khẩu đăng nhập (tối thiểu 6 ký tự)">
            <Input type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Nhập mật khẩu cho tài khoản" />
          </Field>
          <Field label="Vai trò">
            <Select value={role} onValueChange={(v) => setRole(v as RoleId)}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {ROLES.map((r) => (
                  <SelectItem key={r.id} value={r.id}>
                    {r.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </Field>
        </div>
      </FormDialog>

      <ConfirmDialog
        open={!!deleteTarget}
        onOpenChange={(o) => !o && setDeleteTarget(null)}
        title="Xóa tài khoản quản trị?"
        description={`Tài khoản "${deleteTarget?.name ?? ""}" (${deleteTarget?.email ?? ""}) sẽ bị xóa khỏi danh sách quản trị AdminAccounts.`}
        confirmLabel="Xóa"
        tone="danger"
        onConfirm={() => {
          if (deleteTarget) {
            remove.mutate({ id: deleteTarget.id, label: deleteTarget.name });
            setDeleteTarget(null);
          }
        }}
      />
    </>
  );
}
