"use client";

import { useQuery } from "@tanstack/react-query";
import { RefreshCw } from "lucide-react";
import { Bar, BarChart, CartesianGrid, Cell, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { Button } from "@/components/ui/button";
import { ChartCard, chartTheme } from "@/components/shared/chart-card";
import { Skeleton } from "@/components/ui/skeleton";
import { apiRequest } from "@/lib/api-client";
import { DISEASE_CONFUSION } from "@/mocks/ai";
import { DISEASE_CLASSES } from "@/mocks/ai-classes";
import { formatNumber } from "@/lib/format";

interface AnalyticsPayload {
  generatedAt: string;
  sampleSize: number;
  totalRequests: number;
  pendingRequests: number;
  confidenceBuckets: { bucket: string; count: number }[];
  modelUsage: { model: string; count: number }[];
  scanTypes: { name: string; count: number }[];
  topScanned: { label: string; count: number }[];
  topReported: { label: string; count: number }[];
}

export function AiAnalytics() {
  const analytics = useQuery({
    queryKey: ["ai-analytics"],
    queryFn: () => apiRequest<AnalyticsPayload>("/ai/analytics"),
    staleTime: 5 * 60_000,
  });

  if (analytics.isLoading) {
    return (
      <div className="grid gap-4 lg:grid-cols-2">
        <Skeleton className="h-72 rounded-xl" />
        <Skeleton className="h-72 rounded-xl" />
        <Skeleton className="h-72 rounded-xl" />
        <Skeleton className="h-72 rounded-xl" />
      </div>
    );
  }

  const d = analytics.data;

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-2 rounded-xl border bg-surface-2/40 px-4 py-2.5 text-xs text-muted-foreground">
        <span>
          Tổng hợp từ <b className="text-foreground">{d?.sampleSize ?? 0}</b> lượt quét gần nhất (ScanHistory) &{" "}
          <b className="text-foreground">{d?.totalRequests ?? 0}</b> báo cáo (PlantRequests · {d?.pendingRequests ?? 0} chờ duyệt).
        </span>
        <Button
          size="sm"
          variant="outline"
          onClick={async () => {
            await apiRequest<AnalyticsPayload>("/ai/analytics?refresh=1");
            await analytics.refetch();
          }}
          disabled={analytics.isFetching}
        >
          <RefreshCw className={analytics.isFetching ? "animate-spin" : ""} /> Làm mới
        </Button>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <ChartCard
          title="Phân bố độ tin cậy thực tế"
          description="Thống kê mức độ tự tin của các lượt quét từ người dùng"
        >
          <div className="h-60">
            <ResponsiveContainer>
              <BarChart data={d?.confidenceBuckets ?? []}>
                <CartesianGrid stroke={chartTheme.grid} vertical={false} />
                <XAxis dataKey="bucket" tick={chartTheme.axis} axisLine={false} tickLine={false} />
                <YAxis tick={chartTheme.axis} axisLine={false} tickLine={false} width={40} />
                <Tooltip
                  {...chartTheme.tooltip}
                  formatter={(v: number) => [formatNumber(v), "Lượt quét"]}
                  cursor={{ fill: "var(--muted)" }}
                />
                <Bar dataKey="count" radius={[6, 6, 0, 0]}>
                  {(d?.confidenceBuckets ?? []).map((_, i) => (
                    <Cell
                      key={i}
                      fill={i === 0 ? "var(--danger)" : i === 1 ? "var(--warning)" : "var(--leaf)"}
                    />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </div>
        </ChartCard>

        <ChartCard
          title="Tỷ lệ sử dụng mô hình (Model Usage)"
          description="So sánh lượt xử lý bằng LLM Multimodal vs ONNX Engine nội bộ"
        >
          <div className="h-60">
            <ResponsiveContainer>
              <BarChart data={d?.modelUsage ?? []} layout="vertical" margin={{ left: 16 }}>
                <CartesianGrid stroke={chartTheme.grid} horizontal={false} />
                <XAxis type="number" tick={chartTheme.axis} axisLine={false} tickLine={false} />
                <YAxis
                  type="category"
                  dataKey="model"
                  width={160}
                  tick={chartTheme.axis}
                  axisLine={false}
                  tickLine={false}
                />
                <Tooltip {...chartTheme.tooltip} formatter={(v: number) => [formatNumber(v), "Lượt quét"]} />
                <Bar dataKey="count" fill="var(--chart-1)" radius={[0, 6, 6, 0]} barSize={22} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </ChartCard>

        <RankList
          title="Loài / Bệnh được quét nhiều nhất"
          description="Từ lịch sử ScanHistory thực tế"
          rows={d?.topScanned ?? []}
          tone="var(--chart-2)"
        />
        <RankList
          title="Nhãn được người dùng báo cáo nhiều nhất"
          description="Từ PlantRequests — ưu tiên bổ sung dữ liệu train"
          rows={d?.topReported ?? []}
          tone="var(--chart-3)"
        />
      </div>

      <ChartCard
        title="Ma trận nhầm lẫn · Disease Detection (Benchmark tập Test Colab)"
        description="Kết quả đánh giá offline trên tập Test chuẩn của mô hình tf_efficientnetv2_b0_disease (Accuracy ~92,5%)"
      >
        <div className="overflow-x-auto">
          <table className="w-full border-separate border-spacing-1 text-xs">
            <thead>
              <tr>
                <th />
                {DISEASE_CLASSES.map((c) => (
                  <th key={c.id} className="px-1 pb-1 text-[10px] font-medium text-muted-foreground">
                    {c.vi.split(" ")[0]} {c.vi.split(" ")[1] ?? ""}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {DISEASE_CONFUSION.map((row, i) => (
                <tr key={i}>
                  <th className="whitespace-nowrap pr-2 text-right text-[11px] font-medium text-muted-foreground">
                    {DISEASE_CLASSES[i].vi}
                  </th>
                  {row.map((v, j) => (
                    <td
                      key={j}
                      className="h-10 min-w-10 rounded-md text-center font-semibold tabular"
                      style={{
                        background:
                          i === j
                            ? `color-mix(in oklab, var(--leaf) ${v}%, var(--card))`
                            : v > 0
                              ? `color-mix(in oklab, var(--danger) ${Math.min(80, v * 7)}%, var(--card))`
                              : "var(--muted)",
                        color: (i === j && v > 50) || v > 8 ? "var(--primary-foreground)" : "var(--foreground)",
                      }}
                    >
                      {v}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </ChartCard>
    </div>
  );
}

function RankList({
  title,
  description,
  rows,
  tone,
}: {
  title: string;
  description: string;
  rows: { label: string; count: number }[];
  tone: string;
}) {
  const max = Math.max(1, ...rows.map((r) => r.count));
  return (
    <ChartCard title={title} description={description}>
      {rows.length === 0 ? (
        <p className="py-8 text-center text-xs text-muted-foreground">Chưa có dữ liệu.</p>
      ) : (
        <ul className="space-y-3">
          {rows.map((r) => (
            <li key={r.label}>
              <div className="mb-1 flex justify-between text-sm">
                <span className="truncate pr-2">{r.label}</span>
                <span className="font-medium tabular">{r.count}</span>
              </div>
              <div className="h-2 overflow-hidden rounded-full bg-muted">
                <div
                  className="h-full rounded-full"
                  style={{ width: `${(r.count / max) * 100}%`, background: tone }}
                />
              </div>
            </li>
          ))}
        </ul>
      )}
    </ChartCard>
  );
}
