"use client";

import { Check, History, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { CARE_ICON, CARE_TONE } from "@/components/botanical";
import { Button } from "@/components/ui/button";
import { useScheduleMutations } from "@/hooks/queries";
import { useLang, useT } from "@/i18n";
import { common } from "@/i18n/common";
import { CARE_LABEL } from "@/i18n/labels";
import { formatDateTime, formatRelativeDays } from "@/lib/format";
import { cn } from "@/lib/utils";
import type { CareSchedule } from "@/types/user";
import { isScheduleDue, isScheduleOverdue } from "./logic";

/** One of the three independent care schedules of a plant. */
export function CareScheduleCard({ schedule }: { schedule: CareSchedule }) {
  const t = useT(common);
  const lang = useLang();
  const { complete } = useScheduleMutations();

  if (!schedule.enabled) return null;

  const Icon = CARE_ICON[schedule.type];
  const due = isScheduleDue(schedule);
  const overdue = isScheduleOverdue(schedule);
  const completedCycle = !due;
  const progress = schedule.lastDoneAt
    ? Math.min(1, (Date.now() - new Date(schedule.lastDoneAt).getTime()) / (schedule.intervalDays * 86400000))
    : 1;

  return (
    <div
      className={cn(
        "flex flex-col rounded-3xl border p-5 shadow-soft transition-colors",
        completedCycle ? "bg-muted/40 opacity-65" : "bg-card",
      )}
    >
      <div className="flex items-start gap-3">
        <span className={cn("grid size-11 shrink-0 place-items-center rounded-2xl", CARE_TONE[schedule.type])}>
          <Icon className="size-5" />
        </span>
        <div className="min-w-0">
          <h3 className="font-semibold leading-tight">{t(CARE_LABEL[schedule.type])}</h3>
          <p className="text-xs text-muted-foreground">
            {t("everyNDays", { n: schedule.intervalDays })} · {schedule.preferredTime}
          </p>
        </div>
      </div>

      <div className="mt-5 h-1.5 overflow-hidden rounded-full bg-muted">
        <div
          className={cn("h-full rounded-full transition-all", overdue ? "bg-danger" : due ? "bg-warning" : "bg-leaf")}
          style={{ width: `${progress * 100}%` }}
        />
      </div>

      <dl className="mt-4 grid grid-cols-2 gap-3 text-sm">
        <div>
          <dt className="text-xs text-muted-foreground">Lần gần nhất</dt>
          <dd className="font-medium">{schedule.lastDoneAt ? formatRelativeDays(schedule.lastDoneAt, lang) : "Chưa có"}</dd>
        </div>
        <div>
          <dt className="text-xs text-muted-foreground">Lần tiếp theo</dt>
          <dd className={cn("font-medium", overdue && "text-danger")}>{formatRelativeDays(schedule.nextDueAt, lang)}</dd>
        </div>
      </dl>

      <div className="mt-3 flex items-center gap-2 text-xs">
        <span
          className={cn(
            "rounded-full px-2 py-0.5 font-semibold",
            overdue
              ? "bg-danger-soft text-danger"
              : due
                ? "bg-warning-soft text-warning"
                : "bg-success-soft text-success",
          )}
        >
          {overdue ? "Quá hạn" : due ? "Đến hạn hôm nay" : "Đã hoàn thành chu kỳ"}
        </span>
      </div>

      {schedule.history.length > 0 && (
        <details className="mt-4 text-sm">
          <summary className="flex cursor-pointer list-none items-center gap-1.5 text-xs font-semibold text-muted-foreground hover:text-foreground">
            <History className="size-3.5" /> Lịch sử ({schedule.history.length})
          </summary>
          <ul className="mt-2 space-y-1 border-l-2 border-mint pl-3 text-xs text-muted-foreground">
            {schedule.history.slice(0, 6).map((h) => (
              <li key={h.id}>{formatDateTime(h.doneAt, lang)}</li>
            ))}
          </ul>
        </details>
      )}

      <Button
        className="mt-5"
        variant={completedCycle ? "secondary" : "default"}
        disabled={completedCycle || complete.isPending}
        onClick={() =>
          complete.mutate(schedule.id, {
            onSuccess: () => toast.success(`Đã ghi nhận: ${t(CARE_LABEL[schedule.type])}`),
          })
        }
      >
        {complete.isPending ? <Loader2 className="animate-spin" /> : <Check />}
        {completedCycle ? "Đã hoàn thành" : "Đánh dấu hoàn thành"}
      </Button>
    </div>
  );
}
