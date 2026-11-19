"use client";

import type { ReactNode } from "react";
import { cn } from "@/lib/utils";

interface ChartCardProps {
  title: string;
  description?: string;
  actions?: ReactNode;
  children: ReactNode;
  className?: string;
  bodyClassName?: string;
}

export function ChartCard({ title, description, actions, children, className, bodyClassName }: ChartCardProps) {
  return (
    <section className={cn("card-surface flex flex-col", className)}>
      <header className="flex items-start justify-between gap-3 px-5 pt-5">
        <div>
          <h3 className="text-[15px] font-semibold text-foreground">{title}</h3>
          {description && <p className="mt-0.5 text-xs text-muted-foreground">{description}</p>}
        </div>
        {actions}
      </header>
      <div className={cn("flex-1 px-5 pb-5 pt-4", bodyClassName)}>{children}</div>
    </section>
  );
}

/** Shared Recharts styling so every chart uses the design tokens. */
export const chartTheme = {
  grid: "var(--border)",
  axis: { fontSize: 11, fill: "var(--muted-foreground)" },
  tooltip: {
    contentStyle: {
      background: "var(--card)",
      border: "1px solid var(--border)",
      borderRadius: 10,
      fontSize: 12,
      boxShadow: "var(--shadow-lift)",
    },
    labelStyle: { color: "var(--foreground)", fontWeight: 600 },
  },
  colors: ["var(--chart-1)", "var(--chart-2)", "var(--chart-3)", "var(--chart-4)", "var(--chart-5)", "var(--chart-6)"],
};
