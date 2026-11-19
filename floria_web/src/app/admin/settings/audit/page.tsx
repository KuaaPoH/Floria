"use client";

import { useMemo, useState } from "react";
import type { ColumnDef } from "@tanstack/react-table";
import { Download } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { PageHeader } from "@/components/shared/page-header";
import { DataTable } from "@/components/shared/data-table";
import { SearchInput } from "@/components/shared/search-input";
import { FilterSelect } from "@/components/shared/filter-select";
import { useResourceList } from "@/hooks/use-resource";
import { auditService } from "@/services";
import { ROLES } from "@/lib/rbac";
import { exportCsv } from "@/lib/export";
import { formatDateTime } from "@/lib/format";
import type { AuditLog } from "@/types";

export default function AuditLogsPage() {
  const list = useResourceList(auditService);
  const [search, setSearch] = useState("");
  const [role, setRole] = useState("all");

  const rows = useMemo(() => {
    const s = search.toLowerCase();
    return (list.data ?? []).filter(
      (a) =>
        (!s || a.admin.toLowerCase().includes(s) || a.action.toLowerCase().includes(s) || a.target.toLowerCase().includes(s)) &&
        (role === "all" || a.role === role),
    );
  }, [list.data, search, role]);

  const columns: ColumnDef<AuditLog, unknown>[] = [
    { accessorKey: "at", header: "Thời gian", cell: ({ getValue }) => <span className="tabular text-xs">{formatDateTime(getValue() as string)}</span> },
    {
      accessorKey: "admin",
      header: "Quản trị viên",
      cell: ({ row }) => (
        <div>
          <p className="font-medium">{row.original.admin}</p>
          <p className="text-[11px] text-muted-foreground">{ROLES.find((r) => r.id === row.original.role)?.name}</p>
        </div>
      ),
    },
    { accessorKey: "action", header: "Hành động", cell: ({ getValue }) => <span className="font-medium text-forest">{getValue() as string}</span> },
    { accessorKey: "target", header: "Đối tượng" },
    { accessorKey: "before", header: "Giá trị cũ", cell: ({ getValue }) => <span className="font-mono text-xs text-muted-foreground">{getValue() as string}</span> },
    { accessorKey: "after", header: "Giá trị mới", cell: ({ getValue }) => <span className="font-mono text-xs text-foreground">{getValue() as string}</span> },
    { accessorKey: "ip", header: "IP", cell: ({ getValue }) => <span className="font-mono text-xs text-muted-foreground">{getValue() as string}</span> },
  ];

  return (
    <>
      <PageHeader
        title="Nhật ký hoạt động (Audit Logs)"
        description="Theo dõi toàn bộ thao tác thay đổi dữ liệu và cấu hình của quản trị viên."
        actions={
          <Button
            variant="outline"
            onClick={() => {
              exportCsv(
                "floria-audit-logs",
                rows.map((a) => ({ thoi_gian: formatDateTime(a.at), quan_tri_vien: a.admin, vai_tro: a.role, hanh_dong: a.action, doi_tuong: a.target, truoc: a.before, sau: a.after, ip: a.ip })),
              );
              toast.success("Đã xuất nhật ký CSV");
            }}
          >
            <Download /> Xuất CSV
          </Button>
        }
      />

      <DataTable
        columns={columns}
        data={rows}
        loading={list.isLoading}
        toolbar={
          <>
            <SearchInput value={search} onChange={setSearch} placeholder="Tìm quản trị viên, hành động, đối tượng…" />
            <FilterSelect value={role} onChange={setRole} allLabel="Mọi vai trò" options={ROLES.map((r) => ({ value: r.id, label: r.name }))} />
          </>
        }
      />
    </>
  );
}
