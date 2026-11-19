"use client";

import { Bar, BarChart, CartesianGrid, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis, Cell, Legend } from "recharts";
import { ChartCard, chartTheme } from "@/components/shared/chart-card";
import { DemoBadge } from "@/components/shared/demo-badge";
import { CLIP_REJECTION, CONFIDENCE_BUCKETS, CONFUSED_DISEASES, CONFUSED_SPECIES, DISEASE_CONFUSION } from "@/mocks/ai";
import { DISEASE_CLASSES } from "@/mocks/ai-classes";
import { useResourceList } from "@/hooks/use-resource";
import { modelsService } from "@/services";
import { formatDate, formatNumber } from "@/lib/format";

export function AiAnalytics() {
  const models = useResourceList(modelsService);
  const perf = (models.data ?? []).map((m) => ({ name: m.name.replace(" Recognition", "").replace(" Detection", ""), Accuracy: m.accuracy, Precision: m.precision, Recall: m.recall, F1: m.f1 }));
  return (
    <div className="space-y-4">
      <div className="flex justify-end"><DemoBadge label="Phân tích demo" /></div>
      <div className="grid gap-4 lg:grid-cols-2">
        <ChartCard title="Phân bố độ tin cậy" description="Số dự đoán theo khoảng confidence (30 ngày)">
          <div className="h-60"><ResponsiveContainer><BarChart data={CONFIDENCE_BUCKETS}>
            <CartesianGrid stroke={chartTheme.grid} vertical={false} />
            <XAxis dataKey="bucket" tick={chartTheme.axis} axisLine={false} tickLine={false} />
            <YAxis tick={chartTheme.axis} axisLine={false} tickLine={false} width={40} />
            <Tooltip {...chartTheme.tooltip} formatter={(v: number) => [formatNumber(v), "Dự đoán"]} cursor={{ fill: "var(--muted)" }} />
            <Bar dataKey="count" radius={[6, 6, 0, 0]}>{CONFIDENCE_BUCKETS.map((_, i) => <Cell key={i} fill={i < 2 ? "var(--danger)" : i < 3 ? "var(--warning)" : "var(--leaf)"} />)}</Bar>
          </BarChart></ResponsiveContainer></div>
        </ChartCard>
        <ChartCard title="Tỉ lệ từ chối của CLIP Gatekeeper" description="% ảnh bị đánh giá không phải cây">
          <div className="h-60"><ResponsiveContainer><LineChart data={CLIP_REJECTION}>
            <CartesianGrid stroke={chartTheme.grid} vertical={false} />
            <XAxis dataKey="day" tickFormatter={(v) => formatDate(v).slice(0, 5)} tick={chartTheme.axis} axisLine={false} tickLine={false} />
            <YAxis tick={chartTheme.axis} axisLine={false} tickLine={false} width={32} unit="%" />
            <Tooltip {...chartTheme.tooltip} labelFormatter={(v) => formatDate(v as string)} formatter={(v: number) => [`${v}%`, "Từ chối"]} />
            <Line type="monotone" dataKey="rate" stroke="var(--info)" strokeWidth={2} dot={{ r: 2.5 }} />
          </LineChart></ResponsiveContainer></div>
        </ChartCard>
        <ConfusedList title="Loài thường bị nhầm lẫn" rows={CONFUSED_SPECIES} tone="var(--chart-2)" />
        <ConfusedList title="Bệnh thường bị nhầm lẫn" rows={CONFUSED_DISEASES} tone="var(--chart-3)" />
      </div>
      <div className="grid gap-4 lg:grid-cols-[1.1fr_1fr]">
        <ChartCard title="Ma trận nhầm lẫn · Disease Detection" description="Hàng: nhãn thực tế · Cột: dự đoán (%)">
          <div className="overflow-x-auto">
            <table className="w-full border-separate border-spacing-1 text-xs">
              <thead><tr><th />{DISEASE_CLASSES.map((c) => <th key={c.id} className="px-1 pb-1 text-[10px] font-medium text-muted-foreground">{c.vi.split(" ")[0]} {c.vi.split(" ")[1] ?? ""}</th>)}</tr></thead>
              <tbody>
                {DISEASE_CONFUSION.map((row, i) => (
                  <tr key={i}>
                    <th className="whitespace-nowrap pr-2 text-right text-[11px] font-medium text-muted-foreground">{DISEASE_CLASSES[i].vi}</th>
                    {row.map((v, j) => (
                      <td key={j} className="h-10 min-w-10 rounded-md text-center font-semibold tabular" style={{ background: i === j ? `color-mix(in oklab, var(--leaf) ${v}%, var(--card))` : v > 0 ? `color-mix(in oklab, var(--danger) ${Math.min(80, v * 7)}%, var(--card))` : "var(--muted)", color: (i === j && v > 50) || v > 8 ? "var(--primary-foreground)" : "var(--foreground)" }}>
                        {v}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </ChartCard>
        <ChartCard title="So sánh hiệu năng mô hình" description="Chỉ số demo của phiên bản hiện tại">
          <div className="h-72"><ResponsiveContainer><BarChart data={perf}>
            <CartesianGrid stroke={chartTheme.grid} vertical={false} />
            <XAxis dataKey="name" tick={chartTheme.axis} axisLine={false} tickLine={false} />
            <YAxis domain={[80, 100]} tick={chartTheme.axis} axisLine={false} tickLine={false} width={32} />
            <Tooltip {...chartTheme.tooltip} />
            <Legend wrapperStyle={{ fontSize: 12 }} />
            {["Accuracy", "Precision", "Recall", "F1"].map((k, i) => <Bar key={k} dataKey={k} fill={chartTheme.colors[i]} radius={[4, 4, 0, 0]} />)}
          </BarChart></ResponsiveContainer></div>
        </ChartCard>
      </div>
    </div>
  );
}

function ConfusedList({ title, rows, tone }: { title: string; rows: { pair: string; count: number }[]; tone: string }) {
  const max = Math.max(...rows.map((r) => r.count));
  return (
    <ChartCard title={title} description="Số lần botanist sửa nhãn (30 ngày)">
      <ul className="space-y-3">
        {rows.map((r) => (
          <li key={r.pair}>
            <div className="mb-1 flex justify-between text-sm"><span>{r.pair}</span><span className="font-medium tabular">{r.count}</span></div>
            <div className="h-2 overflow-hidden rounded-full bg-muted"><div className="h-full rounded-full" style={{ width: `${(r.count / max) * 100}%`, background: tone }} /></div>
          </li>
        ))}
      </ul>
    </ChartCard>
  );
}
