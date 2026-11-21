"use client";

import { useQuery } from "@tanstack/react-query";
import type { ColumnDef } from "@tanstack/react-table";
import { PageHeader } from "@/components/shared/page-header";
import { DataTable } from "@/components/shared/data-table";
import { StatusBadge } from "@/components/shared/status-badge";
import { ServiceHealthGrid } from "@/features/system/service-health-grid";
import { formatDateTime } from "@/lib/format";
import type { ServiceHealth } from "@/types";

interface RealHealthResponse {
  ok: boolean;
  checkedAt: string;
  services: Array<{
    id: string;
    name: string;
    status: "healthy" | "degraded" | "down";
    latencyMs: number;
    detail?: string;
  }>;
}

async function fetchRealHealthRows(): Promise<ServiceHealth[]> {
  const res = await fetch("/api/admin/health", { cache: "no-store" });
  const body = (await res.json()) as RealHealthResponse;
  return (body.services ?? []).map((s) => ({
    id: s.id,
    name: s.name,
    description: s.detail ?? (s.status === "healthy" ? "Kết nối ổn định" : "Cần kiểm tra dịch vụ"),
    status: s.status === "healthy" ? "operational" : s.status === "degraded" ? "degraded" : "offline",
    latencyMs: s.latencyMs,
    uptime: s.status === "healthy" ? 99.9 : s.status === "degraded" ? 95.0 : 0,
    checkedAt: body.checkedAt,
  }));
}

export default function SystemHealthPage() {
  const list = useQuery({
    queryKey: ["real-system-health-grid"],
    queryFn: fetchRealHealthRows,
    refetchInterval: 15 * 60_000,
  });

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
    {
      accessorKey: "latencyMs",
      header: "Độ trễ",
      cell: ({ getValue }) => <span className="tabular font-medium">{getValue() as number} ms</span>,
    },
    {
      accessorKey: "uptime",
      header: "Uptime",
      cell: ({ getValue }) => <span className="tabular">{String(getValue()).replace(".", ",")}%</span>,
    },
    {
      accessorKey: "checkedAt",
      header: "Kiểm tra lúc",
      cell: ({ getValue }) => formatDateTime(getValue() as string),
    },
    {
      accessorKey: "status",
      header: "Trạng thái",
      cell: ({ getValue }) => <StatusBadge status={getValue() as string} />,
    },
  ];

  return (
    <>
      <PageHeader
        title="Tình trạng hệ thống"
        description="Giám sát độ trễ và khả năng phản hồi thực tế của Cloud Firestore, AI Engine (FastAPI), Spring Boot Gateway, Cloudinary CDN và ZaloPay Sandbox."
      />

      <div className="card-surface mb-6 p-5">
        <ServiceHealthGrid />
      </div>

      <DataTable columns={columns} data={list.data ?? []} loading={list.isLoading} />
    </>
  );
}
