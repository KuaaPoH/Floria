"use client";

import type { ColumnDef } from "@tanstack/react-table";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { PageHeader } from "@/components/shared/page-header";
import { DemoBadge } from "@/components/shared/demo-badge";
import { DataTable } from "@/components/shared/data-table";
import { StatusBadge } from "@/components/shared/status-badge";
import { ServiceHealthGrid } from "@/features/system/service-health-grid";
import { useResourceList, useResourceMutations } from "@/hooks/use-resource";
import { usePermission } from "@/stores/rbac-store";
import { servicesHealthService } from "@/services";
import { formatDateTime } from "@/lib/format";
import type { ServiceHealth } from "@/types";

export default function SystemHealthPage() {
  const list = useResourceList(servicesHealthService);
  const { update } = useResourceMutations(servicesHealthService, { entity: "Trạng thái dịch vụ" });
  const canConfigure = usePermission("system", "configure");

  const columns: ColumnDef<ServiceHealth, unknown>[] = [
    {
      accessorKey: "name",
      header: "Dịch vụ",
      cell: ({ row }) => (
        <div>
          <p className="font-medium">{row.original.name}</p>
          <p className="text-xs text-muted-foreground">{row.original.description}</p>
        </div>
      ),
    },
    { accessorKey: "latencyMs", header: "Độ trễ", cell: ({ getValue }) => <span className="tabular font-medium">{getValue() as number} ms</span> },
    { accessorKey: "uptime", header: "Uptime", cell: ({ getValue }) => <span className="tabular">{String(getValue()).replace(".", ",")}%</span> },
    { accessorKey: "checkedAt", header: "Kiểm tra lúc", cell: ({ getValue }) => formatDateTime(getValue() as string) },
    { accessorKey: "status", header: "Trạng thái", cell: ({ getValue }) => <StatusBadge status={getValue() as string} /> },
    {
      id: "sim",
      header: "Mô phỏng trạng thái",
      enableSorting: false,
      cell: ({ row }) =>
        canConfigure ? (
          <Select
            value={row.original.status}
            onValueChange={(v) =>
              update.mutate({
                id: row.original.id,
                patch: { status: v as ServiceHealth["status"], checkedAt: new Date().toISOString() },
                before: row.original.status,
                label: row.original.name,
              })
            }
          >
            <SelectTrigger className="h-8 w-36 text-xs">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="operational">Hoạt động</SelectItem>
              <SelectItem value="degraded">Suy giảm</SelectItem>
              <SelectItem value="offline">Ngừng</SelectItem>
            </SelectContent>
          </Select>
        ) : null,
    },
  ];

  return (
    <>
      <PageHeader
        title="Tình trạng hệ thống"
        description="Giám sát độ trễ, uptime và khả năng phản hồi của Spring Boot API, Python AI Engine (ONNX), Firestore, Firebase Storage và ZaloPay."
        badge={<DemoBadge label="Mô phỏng Health Probe" />}
      />

      <div className="card-surface mb-6 p-5">
        <ServiceHealthGrid />
      </div>

      <DataTable columns={columns} data={list.data ?? []} loading={list.isLoading} />
    </>
  );
}
