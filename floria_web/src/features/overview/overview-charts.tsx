"use client";

import { Area, AreaChart, Bar, BarChart, CartesianGrid, Cell, Legend, Line, LineChart, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { ChartCard, chartTheme } from "@/components/shared/chart-card";
import { formatDate, formatNumber, formatVND, formatVNDCompact } from "@/lib/format";
import { statusLabel } from "@/components/shared/status-badge";
import { TOP_DISEASES } from "@/mocks/analytics";
import type { Order } from "@/types";

type Point = ReturnType<typeof import("@/mocks/analytics").overviewSeries>[number];

const tick = (v: string) => formatDate(v).slice(0, 5);

export function UserGrowthChart({ data }: { data: Point[] }) {
  return (
    <ChartCard title="Tăng trưởng người dùng" description="Tổng người dùng tích luỹ và đăng ký mới">
      <div className="h-64">
        <ResponsiveContainer>
          <LineChart data={data}>
            <CartesianGrid stroke={chartTheme.grid} vertical={false} />
            <XAxis dataKey="date" tickFormatter={tick} tick={chartTheme.axis} axisLine={false} tickLine={false} minTickGap={24} />
            <YAxis yAxisId="l" tick={chartTheme.axis} axisLine={false} tickLine={false} width={48} tickFormatter={(v) => formatNumber(v)} domain={["dataMin - 200", "dataMax + 100"]} />
            <YAxis yAxisId="r" orientation="right" tick={chartTheme.axis} axisLine={false} tickLine={false} width={32} />
            <Tooltip {...chartTheme.tooltip} labelFormatter={(v) => formatDate(v as string)} formatter={(v: number, n) => [formatNumber(v), n === "users" ? "Tổng người dùng" : "Đăng ký mới"]} />
            <Legend iconType="circle" wrapperStyle={{ fontSize: 12 }} formatter={(v) => (v === "users" ? "Tổng người dùng" : "Đăng ký mới")} />
            <Line yAxisId="l" type="monotone" dataKey="users" stroke="var(--chart-1)" strokeWidth={2.2} dot={false} />
            <Line yAxisId="r" type="monotone" dataKey="newUsers" stroke="var(--chart-2)" strokeWidth={1.6} dot={false} strokeDasharray="4 3" />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </ChartCard>
  );
}

export function RecognitionChart({ data }: { data: Point[] }) {
  return (
    <ChartCard title="Hoạt động nhận diện hằng ngày" description="Lượt quét nhận diện cây và chẩn đoán bệnh">
      <div className="h-64">
        <ResponsiveContainer>
          <AreaChart data={data}>
            <defs>
              <linearGradient id="g-plant" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="var(--chart-1)" stopOpacity={0.3} />
                <stop offset="100%" stopColor="var(--chart-1)" stopOpacity={0} />
              </linearGradient>
              <linearGradient id="g-dis" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="var(--chart-3)" stopOpacity={0.35} />
                <stop offset="100%" stopColor="var(--chart-3)" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid stroke={chartTheme.grid} vertical={false} />
            <XAxis dataKey="date" tickFormatter={tick} tick={chartTheme.axis} axisLine={false} tickLine={false} minTickGap={24} />
            <YAxis tick={chartTheme.axis} axisLine={false} tickLine={false} width={40} />
            <Tooltip {...chartTheme.tooltip} labelFormatter={(v) => formatDate(v as string)} formatter={(v: number, n) => [formatNumber(v), n === "plantScans" ? "Nhận diện cây" : "Chẩn đoán bệnh"]} />
            <Legend iconType="circle" wrapperStyle={{ fontSize: 12 }} formatter={(v) => (v === "plantScans" ? "Nhận diện cây" : "Chẩn đoán bệnh")} />
            <Area type="monotone" dataKey="plantScans" stroke="var(--chart-1)" strokeWidth={2} fill="url(#g-plant)" />
            <Area type="monotone" dataKey="diseaseScans" stroke="var(--chart-3)" strokeWidth={2} fill="url(#g-dis)" />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </ChartCard>
  );
}

export function TopDiseasesChart({ data }: { data?: { name: string; value: number }[] }) {
  const rows = data && data.length > 0 ? data : TOP_DISEASES;
  return (
    <ChartCard title="Top 5 nhóm bệnh" description="Số lượt chẩn đoán theo nhóm bệnh">
      <div className="h-64">
        <ResponsiveContainer>
          <BarChart data={rows} layout="vertical" margin={{ left: 8 }}>
            <CartesianGrid stroke={chartTheme.grid} horizontal={false} />
            <XAxis type="number" tick={chartTheme.axis} axisLine={false} tickLine={false} />
            <YAxis type="category" dataKey="name" tick={chartTheme.axis} axisLine={false} tickLine={false} width={120} />
            <Tooltip {...chartTheme.tooltip} formatter={(v: number) => [formatNumber(v), "Lượt chẩn đoán"]} cursor={{ fill: "var(--muted)" }} />
            <Bar dataKey="value" radius={[0, 6, 6, 0]} barSize={18}>
              {rows.map((_, i) => (
                <Cell key={i} fill={chartTheme.colors[[3, 2, 0, 4, 1][i]]} />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>
    </ChartCard>
  );
}

export function RevenueChart({ data }: { data: Point[] }) {
  return (
    <ChartCard title="Doanh thu" description="Doanh thu cửa hàng theo ngày (VND)">
      <div className="h-64">
        <ResponsiveContainer>
          <AreaChart data={data}>
            <defs>
              <linearGradient id="g-rev" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="var(--chart-2)" stopOpacity={0.3} />
                <stop offset="100%" stopColor="var(--chart-2)" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid stroke={chartTheme.grid} vertical={false} />
            <XAxis dataKey="date" tickFormatter={tick} tick={chartTheme.axis} axisLine={false} tickLine={false} minTickGap={24} />
            <YAxis tick={chartTheme.axis} axisLine={false} tickLine={false} width={48} tickFormatter={formatVNDCompact} />
            <Tooltip {...chartTheme.tooltip} labelFormatter={(v) => formatDate(v as string)} formatter={(v: number) => [formatVND(v), "Doanh thu"]} />
            <Area type="monotone" dataKey="revenue" stroke="var(--chart-2)" strokeWidth={2} fill="url(#g-rev)" />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </ChartCard>
  );
}

const STATUS_COLORS: Record<string, string> = {
  pending: "var(--warning)",
  confirmed: "var(--info)",
  shipping: "var(--sage)",
  delivered: "var(--leaf)",
  cancelled: "var(--danger)",
};

export function OrderStatusChart({ orders }: { orders: Order[] }) {
  const data = Object.keys(STATUS_COLORS).map((k) => ({ key: k, name: statusLabel(k), value: orders.filter((o) => o.fulfillment === k).length }));
  const total = orders.length;
  return (
    <ChartCard title="Trạng thái đơn hàng" description="Phân bổ theo trạng thái xử lý">
      <div className="relative h-52">
        <ResponsiveContainer>
          <PieChart>
            <Pie data={data} dataKey="value" nameKey="name" innerRadius={58} outerRadius={84} paddingAngle={2} stroke="none">
              {data.map((d) => (
                <Cell key={d.key} fill={STATUS_COLORS[d.key]} />
              ))}
            </Pie>
            <Tooltip {...chartTheme.tooltip} formatter={(v: number, n) => [`${v} đơn`, n]} />
          </PieChart>
        </ResponsiveContainer>
        <div className="pointer-events-none absolute inset-0 grid place-items-center text-center">
          <div>
            <p className="text-2xl font-semibold tabular">{total}</p>
            <p className="text-[11px] text-muted-foreground">đơn hàng</p>
          </div>
        </div>
      </div>
      <ul className="mt-2 grid grid-cols-2 gap-x-3 gap-y-1.5 text-xs">
        {data.map((d) => (
          <li key={d.key} className="flex items-center gap-2">
            <span className="size-2 rounded-full" style={{ background: STATUS_COLORS[d.key] }} />
            <span className="text-muted-foreground">{d.name}</span>
            <span className="ml-auto font-medium tabular">{d.value}</span>
          </li>
        ))}
      </ul>
    </ChartCard>
  );
}
