"use client";

import { useQuery, useQueryClient } from "@tanstack/react-query";
import { Cpu, CreditCard, Database, HardDrive, RefreshCw, Server } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { StatusBadge } from "@/components/shared/status-badge";
import { servicesHealthService } from "@/services";
import { IS_MOCK } from "@/lib/config";
import { formatDateTime } from "@/lib/format";
import { cn } from "@/lib/utils";
import type { ServiceHealth } from "@/types";
import { toast } from "sonner";

const ICONS: Record<string, typeof Server> = {
  svc_api: Server,
  svc_ai: Cpu,
  svc_fs: Database,
  svc_storage: HardDrive,
  svc_zalopay: CreditCard,
  firestore: Database,
  "ai-engine": Cpu,
  "spring-backend": Server,
  cloudinary: HardDrive,
  zalopay: CreditCard,
};

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

async function fetchRealHealth(): Promise<ServiceHealth[]> {
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

/** Simulated health probe for MOCK mode. */
async function simulateProbe(list: ServiceHealth[]) {
  const now = new Date().toISOString();
  for (const s of list) {
    const jitter = Math.round((Math.random() - 0.5) * s.latencyMs * 0.3);
    await servicesHealthService.update(s.id, { latencyMs: Math.max(20, s.latencyMs + jitter), checkedAt: now });
  }
}

export function ServiceHealthGrid({ compact }: { compact?: boolean }) {
  const qc = useQueryClient();
  const queryKey = IS_MOCK ? [servicesHealthService.key] : ["real-system-health-grid"];
  const { data, isLoading, isFetching } = useQuery({
    queryKey,
    queryFn: () => (IS_MOCK ? servicesHealthService.list() : fetchRealHealth()),
    refetchInterval: IS_MOCK ? false : 15 * 60_000,
  });
  const rows = Array.isArray(data) ? data : [];

  const refresh = async () => {
    if (IS_MOCK) {
      if (!data) return;
      await simulateProbe(data);
      await qc.invalidateQueries({ queryKey });
      toast.success("Đã kiểm tra lại các dịch vụ (mô phỏng)");
      return;
    }
    await qc.invalidateQueries({ queryKey });
    toast.success("Đã kiểm tra lại kết nối dịch vụ");
  };

  return (
    <div>
      <div className="mb-3 flex items-center justify-end">
        <Button variant="ghost" size="sm" onClick={refresh} disabled={isFetching}>
          <RefreshCw className={cn(isFetching && "animate-spin")} /> Kiểm tra lại
        </Button>
      </div>
      <div className={cn("grid gap-3", compact ? "sm:grid-cols-2 xl:grid-cols-3" : "sm:grid-cols-2 lg:grid-cols-3")}>
        {isLoading || !data
          ? Array.from({ length: 5 }).map((_, i) => <Skeleton key={i} className="h-32 rounded-xl" />)
          : rows.map((s) => {
              const Icon = ICONS[s.id] ?? Server;
              const dot = s.status === "operational" ? "bg-success" : s.status === "degraded" ? "bg-warning" : "bg-danger";
              return (
                <div key={s.id} className="rounded-xl border bg-card p-4">
                  <div className="flex items-start justify-between">
                    <div className="grid size-9 place-items-center rounded-lg bg-surface-2 text-forest">
                      <Icon className="size-[18px]" />
                    </div>
                    <span className={cn("mt-1 size-2.5 rounded-full ring-4 ring-current/10", dot)} />
                  </div>
                  <p className="mt-3 text-sm font-semibold text-foreground">{s.name}</p>
                  <p className="text-xs text-muted-foreground">{s.description}</p>
                  <div className="mt-3 flex items-center justify-between">
                    <StatusBadge status={s.status} />
                    <span className={cn("text-xs font-semibold tabular", s.latencyMs > 300 ? "text-warning" : "text-foreground")}>{s.latencyMs} ms</span>
                  </div>
                  <p className="mt-2 text-[11px] text-muted-foreground">Kiểm tra: {formatDateTime(s.checkedAt)}</p>
                </div>
              );
            })}
      </div>
    </div>
  );
}
