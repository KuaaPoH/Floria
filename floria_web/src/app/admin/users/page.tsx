"use client";

import { useEffect, useMemo, useState } from "react";
import { useSearchParams } from "next/navigation";
import type { ColumnDef } from "@tanstack/react-table";
import { Download, Eye, Lock, MoreHorizontal, Unlock, UserCheck, UserX, Users } from "lucide-react";
import { Button } from "@/components/ui/button";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { PageHeader } from "@/components/shared/page-header";
import { DataTable } from "@/components/shared/data-table";
import { SearchInput } from "@/components/shared/search-input";
import { FilterSelect } from "@/components/shared/filter-select";
import { StatusBadge } from "@/components/shared/status-badge";
import { UserAvatar } from "@/components/shared/user-avatar";
import { ConfirmDialog } from "@/components/shared/confirm-dialog";
import { StatCard } from "@/components/shared/stat-card";
import { UserDetailDrawer } from "@/features/users/user-detail-drawer";
import { PROVIDER_LABEL } from "@/features/users/provider";
import { useResourceList, useResourceMutations } from "@/hooks/use-resource";
import { usePermission } from "@/stores/rbac-store";
import { usersService } from "@/services";
import { exportCsv } from "@/lib/export";
import { formatDate, formatNumber } from "@/lib/format";
import type { AppUser } from "@/types";
import { toast } from "sonner";

export default function UsersPage() {
  const searchParams = useSearchParams();
  const q = searchParams.get("q") ?? "";
  const [search, setSearch] = useState(q);
  const [status, setStatus] = useState("all");
  const [provider, setProvider] = useState("all");
  const [selected, setSelected] = useState<AppUser | null>(null);
  const [confirm, setConfirm] = useState<AppUser | null>(null);
  const canEdit = usePermission("users", "edit");

  useEffect(() => {
    if (q) setSearch(q);
  }, [q]);

  const list = useResourceList(usersService);
  const { update } = useResourceMutations(usersService, { entity: "Người dùng", silent: true });

  const rows = useMemo(() => {
    const s = search.trim().toLowerCase();
    return (list.data ?? []).filter(
      (u) => (!s || u.fullName.toLowerCase().includes(s) || u.email.toLowerCase().includes(s)) && (status === "all" || u.status === status) && (provider === "all" || u.provider === provider),
    );
  }, [list.data, search, status, provider]);

  const toggleLock = (u: AppUser) => {
    const next = u.status === "locked" ? "active" : "locked";
    update.mutate(
      { id: u.id, patch: { status: next }, before: u.status, label: u.fullName },
      {
        onSuccess: (nu) => {
          setSelected((cur) => (cur?.id === nu.id ? nu : cur));
          toast.success(next === "locked" ? `Đã khoá ${u.fullName}` : `Đã mở khoá ${u.fullName}`);
        },
      },
    );
  };

  const columns: ColumnDef<AppUser, unknown>[] = [
    {
      accessorKey: "fullName",
      header: "Người dùng",
      cell: ({ row }) => (
        <div className="flex items-center gap-3">
          <UserAvatar name={row.original.fullName} src={row.original.avatar} />
          <div className="min-w-0">
            <p className="truncate font-medium text-foreground">{row.original.fullName}</p>
            <p className="truncate text-xs text-muted-foreground">{row.original.email}</p>
          </div>
        </div>
      ),
    },
    { accessorKey: "provider", header: "Đăng nhập", cell: ({ getValue }) => <span className="text-muted-foreground">{PROVIDER_LABEL[getValue() as AppUser["provider"]]}</span> },
    { accessorKey: "registeredAt", header: "Ngày đăng ký", cell: ({ getValue }) => <span className="tabular">{formatDate(getValue() as string)}</span> },
    { accessorKey: "plants", header: "Số cây", cell: ({ getValue }) => <span className="tabular">{getValue() as number}</span> },
    { accessorKey: "scans", header: "Lượt quét", cell: ({ getValue }) => <span className="tabular">{getValue() as number}</span> },
    { accessorKey: "orders", header: "Đơn hàng", cell: ({ getValue }) => <span className="tabular">{getValue() as number}</span> },
    { accessorKey: "status", header: "Trạng thái", cell: ({ getValue }) => <StatusBadge status={getValue() as string} /> },
    {
      id: "actions",
      header: "",
      enableSorting: false,
      cell: ({ row }) => (
        <div onClick={(e) => e.stopPropagation()} className="text-right">
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="icon-sm" aria-label="Thao tác">
                <MoreHorizontal />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuItem onSelect={() => setSelected(row.original)}>
                <Eye /> Xem chi tiết
              </DropdownMenuItem>
              {canEdit && (
                <DropdownMenuItem onSelect={() => setConfirm(row.original)} className={row.original.status === "locked" ? "" : "text-danger focus:text-danger"}>
                  {row.original.status === "locked" ? (
                    <>
                      <Unlock /> Mở khoá
                    </>
                  ) : (
                    <>
                      <Lock /> Khoá tài khoản
                    </>
                  )}
                </DropdownMenuItem>
              )}
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      ),
    },
  ];

  const all = list.data ?? [];
  return (
    <>
      <PageHeader
        title="Quản lý người dùng"
        description="Tài khoản người dùng ứng dụng Floria, khu vườn cá nhân và lịch sử sử dụng AI."
        actions={
          <Button
            variant="outline"
            onClick={() =>
              exportCsv(
                "floria-nguoi-dung",
                rows.map((u) => ({
                  ho_ten: u.fullName,
                  email: u.email,
                  dang_nhap: PROVIDER_LABEL[u.provider],
                  ngay_dang_ky: formatDate(u.registeredAt),
                  so_cay: u.plants,
                  luot_quet: u.scans,
                  don_hang: u.orders,
                  trang_thai: u.status,
                })),
              )
            }
          >
            <Download /> Xuất dữ liệu
          </Button>
        }
      />
      <div className="mb-4 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="Tổng tài khoản" value={formatNumber(all.length)} icon={Users} tone="leaf" />
        <StatCard label="Đang hoạt động" value={formatNumber(all.filter((u) => u.status === "active").length)} icon={UserCheck} tone="info" />
        <StatCard label="Chờ xác minh" value={formatNumber(all.filter((u) => u.status === "pending").length)} icon={Users} tone="warning" />
        <StatCard label="Đã khoá" value={formatNumber(all.filter((u) => u.status === "locked").length)} icon={UserX} tone="danger" />
      </div>
      <DataTable
        columns={columns}
        data={rows}
        loading={list.isLoading}
        error={list.error}
        onRetry={() => list.refetch()}
        onRowClick={setSelected}
        toolbar={
          <>
            <SearchInput value={search} onChange={setSearch} placeholder="Tìm theo tên hoặc email…" />
            <FilterSelect
              value={status}
              onChange={setStatus}
              allLabel="Mọi trạng thái"
              options={[
                { value: "active", label: "Hoạt động" },
                { value: "pending", label: "Chờ xác minh" },
                { value: "locked", label: "Đã khoá" },
              ]}
            />
            <FilterSelect value={provider} onChange={setProvider} allLabel="Mọi phương thức" options={Object.entries(PROVIDER_LABEL).map(([value, label]) => ({ value, label }))} />
          </>
        }
      />
      <UserDetailDrawer user={selected} onOpenChange={(o) => !o && setSelected(null)} onToggleLock={(u) => setConfirm(u)} canEdit={canEdit} />
      <ConfirmDialog
        open={!!confirm}
        onOpenChange={(o) => !o && setConfirm(null)}
        title={confirm?.status === "locked" ? "Mở khoá tài khoản?" : "Khoá tài khoản?"}
        description={confirm?.status === "locked" ? `${confirm?.fullName} sẽ có thể đăng nhập lại.` : `${confirm?.fullName} sẽ không thể đăng nhập cho đến khi được mở khoá.`}
        tone={confirm?.status === "locked" ? "default" : "danger"}
        confirmLabel={confirm?.status === "locked" ? "Mở khoá" : "Khoá tài khoản"}
        onConfirm={() => confirm && toggleLock(confirm)}
      />
    </>
  );
}
