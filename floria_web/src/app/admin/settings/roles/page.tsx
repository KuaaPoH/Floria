"use client";

import { useState } from "react";
import type { ColumnDef } from "@tanstack/react-table";
import { Plus, RotateCcw, ShieldCheck, UserPlus } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { Input } from "@/components/ui/input";
import { Switch } from "@/components/ui/switch";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { PageHeader } from "@/components/shared/page-header";
import { DataTable } from "@/components/shared/data-table";
import { StatusBadge } from "@/components/shared/status-badge";
import { FormDialog } from "@/components/shared/form-dialog";
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
  const { matrix, toggle, reset } = useRbacStore();
  const [selectedRole, setSelectedRole] = useState<RoleId>("botanist");

  const admins = useResourceList(adminsService);
  const { create, update } = useResourceMutations(adminsService, { entity: "Tài khoản quản trị" });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [role, setRole] = useState<RoleId>("operations");

  const createAdmin = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim() || !email.includes("@")) {
      toast.error("Vui lòng nhập họ tên và email hợp lệ");
      return;
    }
    create.mutate(
      {
        id: uid("adm"),
        name: name.trim(),
        email: email.trim(),
        role,
        status: "active",
        lastLogin: new Date().toISOString(),
        twoFA: false,
      },
      {
        onSuccess: () => {
          setDialogOpen(false);
          setName("");
          setEmail("");
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
          <UserAvatar name={row.original.name} />
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
    {
      accessorKey: "twoFA",
      header: "Bảo mật 2FA",
      cell: ({ row }) => (
        <Switch
          checked={row.original.twoFA}
          disabled={!canConfigure}
          onCheckedChange={(twoFA) => update.mutate({ id: row.original.id, patch: { twoFA }, label: row.original.name })}
        />
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
          <div className="text-right">
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
                  onClick={() => {
                    reset();
                    logAudit({ action: "Khôi phục RBAC", target: "Ma trận phân quyền", before: "Tuỳ chỉnh", after: "Mặc định" });
                    toast.success("Đã khôi phục ma trận phân quyền mặc định");
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
                    <TableHead>Module</TableHead>
                    {ACTIONS.map((a) => (
                      <TableHead key={a} className="text-center">
                        {ACTION_LABELS[a]}
                      </TableHead>
                    ))}
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {MODULES.map((m) => (
                    <TableRow key={m.id}>
                      <TableCell className="font-medium">{m.name}</TableCell>
                      {ACTIONS.map((a) => {
                        const checked = matrix[selectedRole]?.[m.id]?.includes(a) ?? false;
                        return (
                          <TableCell key={a} className="text-center">
                            <Checkbox
                              checked={checked}
                              disabled={!canConfigure || selectedRole === "super_admin"}
                              onCheckedChange={() => toggle(selectedRole, m.id, a)}
                              aria-label={`${m.name} - ${ACTION_LABELS[a]}`}
                            />
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
    </>
  );
}
