import type { LucideIcon } from "lucide-react";
import { cn } from "@/lib/utils";

export interface TimelineItem {
  id: string;
  title: string;
  description?: string;
  time: string;
  icon?: LucideIcon;
  tone?: "leaf" | "info" | "warning" | "danger" | "neutral";
}

const TONE: Record<NonNullable<TimelineItem["tone"]>, string> = {
  leaf: "bg-success-soft text-leaf",
  info: "bg-info-soft text-info",
  warning: "bg-warning-soft text-warning",
  danger: "bg-danger-soft text-danger",
  neutral: "bg-muted text-muted-foreground",
};

export function ActivityTimeline({ items, className }: { items: TimelineItem[]; className?: string }) {
  return (
    <ol className={cn("relative", className)}>
      {items.map((it, i) => {
        const Icon = it.icon;
        return (
          <li key={it.id} className="relative flex gap-3 pb-5 last:pb-0">
            {i < items.length - 1 && <span className="absolute left-[15px] top-8 h-[calc(100%-2rem)] w-px bg-border" />}
            <span className={cn("relative z-10 grid size-8 shrink-0 place-items-center rounded-full", TONE[it.tone ?? "neutral"])}>
              {Icon ? <Icon className="size-4" /> : <span className="size-2 rounded-full bg-current" />}
            </span>
            <div className="min-w-0 flex-1 pt-1">
              <p className="text-sm font-medium leading-snug text-foreground">{it.title}</p>
              {it.description && <p className="mt-0.5 text-xs text-muted-foreground">{it.description}</p>}
              <p className="mt-1 text-[11px] text-muted-foreground">{it.time}</p>
            </div>
          </li>
        );
      })}
    </ol>
  );
}
