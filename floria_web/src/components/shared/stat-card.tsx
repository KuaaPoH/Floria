"use client";

import type { LucideIcon } from "lucide-react";
import { ArrowDownRight, ArrowUpRight } from "lucide-react";
import { Area, AreaChart, ResponsiveContainer } from "recharts";
import { cn } from "@/lib/utils";

type Tone = "leaf" | "info" | "warning" | "danger" | "sage";

const TONES: Record<Tone, { icon: string; stroke: string }> = {
  leaf: { icon: "bg-success-soft text-leaf", stroke: "var(--leaf)" },
  info: { icon: "bg-info-soft text-info", stroke: "var(--info)" },
  warning: { icon: "bg-warning-soft text-warning", stroke: "var(--warning)" },
  danger: { icon: "bg-danger-soft text-danger", stroke: "var(--danger)" },
  sage: { icon: "bg-accent text-forest", stroke: "var(--sage)" },
};

interface StatCardProps {
  label: string;
  value: string;
  change?: number;
  icon: LucideIcon;
  tone?: Tone;
  trend?: number[];
  hint?: string;
}

export function StatCard({ label, value, change, icon: Icon, tone = "leaf", trend, hint }: StatCardProps) {
  const t = TONES[tone];
  const up = (change ?? 0) >= 0;
  const id = `spark-${label.replace(/\W/g, "")}`;
  return (
    <div className="card-surface flex flex-col gap-3 p-4 transition-shadow hover:shadow-raised">
      <div className="flex items-start justify-between gap-2">
        <div className={cn("grid size-9 place-items-center rounded-lg", t.icon)}>
          <Icon className="size-[18px]" />
        </div>
        {change !== undefined && (
          <span
            className={cn(
              "inline-flex items-center gap-0.5 rounded-md px-1.5 py-0.5 text-xs font-medium tabular",
              up ? "bg-success-soft text-success" : "bg-danger-soft text-danger",
            )}
          >
            {up ? <ArrowUpRight className="size-3" /> : <ArrowDownRight className="size-3" />}
            {Math.abs(change).toFixed(1).replace(".", ",")}%
          </span>
        )}
      </div>
      <div>
        <p className="text-xs font-medium text-muted-foreground">{label}</p>
        <p className="mt-1 text-[22px] font-semibold leading-tight tracking-tight text-foreground tabular">{value}</p>
        {hint && <p className="mt-0.5 text-xs text-muted-foreground">{hint}</p>}
      </div>
      {trend && trend.length > 1 && (
        <div className="-mx-1 h-9">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={trend.map((v, i) => ({ i, v }))}>
              <defs>
                <linearGradient id={id} x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor={t.stroke} stopOpacity={0.25} />
                  <stop offset="100%" stopColor={t.stroke} stopOpacity={0} />
                </linearGradient>
              </defs>
              <Area type="monotone" dataKey="v" stroke={t.stroke} strokeWidth={1.6} fill={`url(#${id})`} isAnimationActive={false} />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      )}
    </div>
  );
}
