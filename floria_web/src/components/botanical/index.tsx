"use client";

import Link from "next/link";
import { motion } from "framer-motion";
import { Bug, Check, ChevronRight, Droplets, FlaskConical, MapPin, Sprout, Sun, type LucideIcon } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { isScheduleOverdue, type EffectiveStatusKey } from "@/features/garden/logic";
import { useLang, useT } from "@/i18n";
import { common } from "@/i18n/common";
import { CARE_SHORT_LABEL, ENV_LABEL, LIGHT_LABEL, SEVERITY_LABEL, STATUS_LABEL } from "@/i18n/labels";
import { formatRelativeDays } from "@/lib/format";
import { cn } from "@/lib/utils";
import type { CareSchedule, CareType, DiseaseSeverity, PlantInfo, UserGarden, UserPlant } from "@/types/user";

const STATUS_VARIANT: Record<EffectiveStatusKey, "danger" | "info" | "warning" | "success"> = {
  sick: "danger",
  needs_water: "info",
  needs_fertilizer: "warning",
  needs_inspection: "warning",
  healthy: "success",
};

export const CARE_ICON: Record<CareType, LucideIcon> = { watering: Droplets, fertilizing: FlaskConical, inspection: Bug };
export const CARE_TONE: Record<CareType, string> = {
  watering: "bg-info-soft text-info",
  fertilizing: "bg-warning-soft text-warning",
  inspection: "bg-success-soft text-success",
};

export function PlantStatusBadge({ status, className }: { status: EffectiveStatusKey; className?: string }) {
  const t = useT(common);
  return (
    <Badge variant={STATUS_VARIANT[status]} className={className}>
      <span className="size-1.5 rounded-full bg-current" />
      {t(STATUS_LABEL[status])}
    </Badge>
  );
}

export function DiseaseSeverityBadge({ severity }: { severity: DiseaseSeverity }) {
  const t = useT(common);
  const v = severity === "none" ? "success" : severity === "low" ? "info" : severity === "medium" ? "warning" : "danger";
  return <Badge variant={v}>{t(SEVERITY_LABEL[severity])}</Badge>;
}

export function PlantImage({ src, alt, className, ratio = "aspect-[4/5]" }: { src: string; alt: string; className?: string; ratio?: string }) {
  return (
    <div className={cn("relative overflow-hidden bg-mint", ratio, className)}>
      <img src={src} alt={alt} loading="lazy" className="absolute inset-0 size-full object-cover transition-transform duration-700 group-hover:scale-[1.04]" />
    </div>
  );
}

export function PlantCard({ plant, info, status, next, gardenName }: { plant: UserPlant; info?: PlantInfo; status: EffectiveStatusKey; next: CareSchedule | null; gardenName?: string }) {
  const t = useT(common);
  const lang = useLang();
  const NextIcon = next ? CARE_ICON[next.type] : Sprout;
  return (
    <Link
      href={`/garden/${plant.gardenId}/plants/${plant.id}`}
      className="group flex flex-col overflow-hidden rounded-3xl border bg-card shadow-soft transition-all duration-300 hover:-translate-y-1 hover:shadow-lift"
    >
      <div className="relative">
        <PlantImage src={plant.image} alt={plant.nickname} />
        <PlantStatusBadge status={status} className="absolute left-3 top-3 border-card/50 shadow-soft backdrop-blur" />
      </div>
      <div className="flex flex-1 flex-col gap-3 p-4">
        <div>
          <h3 className="text-lg font-semibold leading-tight">{plant.nickname}</h3>
          <p className="text-sm italic text-muted-foreground">{info?.scientificName}</p>
        </div>
        <div className="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground">
          <span className="inline-flex items-center gap-1"><MapPin className="size-3.5" />{plant.location}</span>
          {gardenName && <span className="truncate">· {gardenName}</span>}
        </div>
        {next && (
          <div className="mt-auto flex items-center justify-between rounded-2xl bg-muted/70 px-3 py-2 text-xs">
            <span className="inline-flex items-center gap-1.5 font-medium"><NextIcon className="size-3.5 text-leaf" />{t(CARE_SHORT_LABEL[next.type])}</span>
            <span className={cn("font-semibold", isScheduleOverdue(next) ? "text-danger" : "text-forest dark:text-foreground")}>{formatRelativeDays(next.nextDueAt, lang)}</span>
          </div>
        )}
      </div>
    </Link>
  );
}

export function GardenCard({ garden, plantCount, attention, onClick, active }: { garden: UserGarden; plantCount: number; attention: number; onClick?: () => void; active?: boolean }) {
  const t = useT(common);
  return (
    <Link
      href={`/garden/${garden.id}`}
      onClick={onClick}
      className={cn("group relative block overflow-hidden rounded-3xl shadow-soft ring-offset-2 ring-offset-background transition-all hover:shadow-lift", active && "ring-2 ring-leaf")}
    >
      <PlantImage src={garden.coverImage} alt={garden.name} ratio="aspect-[16/11]" />
      <div className="absolute inset-0 bg-image-scrim" />
      <div className="absolute inset-x-0 bottom-0 p-5 text-forest-foreground">
        <div className="mb-2 flex flex-wrap gap-1.5">
          <Badge variant="glass">{t(ENV_LABEL[garden.environment])}</Badge>
          <Badge variant="glass"><Sun />{t(LIGHT_LABEL[garden.light])}</Badge>
        </div>
        <h3 className="text-xl font-semibold">{garden.name}</h3>
        <div className="mt-1 flex items-center justify-between text-sm text-forest-foreground/80">
          <span>{plantCount} cây{attention > 0 ? ` · ${attention} cần chú ý` : ""}</span>
          <ChevronRight className="size-4 transition-transform group-hover:translate-x-1" />
        </div>
      </div>
    </Link>
  );
}

export function LocationChips({ chips, value, onChange, allLabel }: { chips: { name: string; count: number }[]; value: string | null; onChange: (v: string | null) => void; allLabel: string }) {
  const total = chips.reduce((s, c) => s + c.count, 0);
  const items = [{ name: null as string | null, label: allLabel, count: total }, ...chips.map((c) => ({ name: c.name as string | null, label: c.name, count: c.count }))];
  return (
    <div className="scrollbar-none -mx-1 flex gap-2 overflow-x-auto px-1 pb-1">
      {items.map((c) => {
        const active = value === c.name;
        return (
          <button
            key={c.label}
            onClick={() => onChange(c.name)}
            className={cn(
              "inline-flex shrink-0 items-center gap-2 rounded-full border px-4 py-2 text-sm font-medium transition-all",
              active ? "border-forest bg-forest text-forest-foreground" : "bg-card text-foreground hover:border-leaf/50",
            )}
          >
            {c.label}
            <span className={cn("rounded-full px-1.5 text-[11px]", active ? "bg-forest-foreground/20" : "bg-muted text-muted-foreground")}>{c.count}</span>
          </button>
        );
      })}
    </div>
  );
}

export function CareTaskItem({ schedule, plant, onComplete, pending }: { schedule: CareSchedule; plant?: UserPlant; onComplete: () => void; pending?: boolean }) {
  const t = useT(common);
  const lang = useLang();
  const Icon = CARE_ICON[schedule.type];
  const overdue = isScheduleOverdue(schedule);
  return (
    <motion.li layout initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, x: 24 }} className="flex items-center gap-3 rounded-2xl border bg-card p-3 shadow-soft">
      {plant && <img src={plant.image} alt={plant.nickname} className="size-12 shrink-0 rounded-xl object-cover" />}
      <div className="min-w-0 flex-1">
        <p className="truncate font-semibold">{plant?.nickname}</p>
        <div className="mt-0.5 flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
          <span className={cn("inline-flex items-center gap-1 rounded-full px-2 py-0.5 font-medium", CARE_TONE[schedule.type])}>
            <Icon className="size-3" /> {t(CARE_SHORT_LABEL[schedule.type])}
          </span>
          <span>{schedule.preferredTime}</span>
          {overdue && <span className="font-semibold text-danger">· {formatRelativeDays(schedule.nextDueAt, lang)}</span>}
        </div>
      </div>
      <Button size="icon-sm" variant="outline" className="rounded-full hover:border-leaf hover:bg-leaf hover:text-primary-foreground" onClick={onComplete} disabled={pending} aria-label="Hoàn thành">
        <Check />
      </Button>
    </motion.li>
  );
}
