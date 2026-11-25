"use client";

import type * as React from "react";
import { FlaskConical } from "lucide-react";
import { isMock } from "@/config/env";
import { useT } from "@/i18n";
import { common } from "@/i18n/common";
import { Tooltip, TooltipContent, TooltipTrigger } from "@/components/ui/tooltip";
import { cn } from "@/lib/utils";

export function DemoBadge({ className }: { className?: string }) {
  const t = useT(common);
  if (!isMock()) return null;
  return (
    <Tooltip>
      <TooltipTrigger asChild>
        <span className={cn("inline-flex items-center gap-1 rounded-full bg-warning-soft px-2 py-0.5 text-[11px] font-semibold text-warning", className)}>
          <FlaskConical className="size-3" /> {t("demoMode")}
        </span>
      </TooltipTrigger>
      <TooltipContent>{t("demoModeHint")}</TooltipContent>
    </Tooltip>
  );
}

/** Inline notice used on AI and payment results produced by mock services. */
export function DemoNotice({ children, className }: { children: React.ReactNode; className?: string }) {
  if (!isMock()) return null;
  return (
    <div className={cn("flex items-start gap-2 rounded-xl border border-warning/30 bg-warning-soft/60 px-3 py-2 text-xs text-foreground/80", className)}>
      <FlaskConical className="mt-0.5 size-3.5 shrink-0 text-warning" />
      <span>{children}</span>
    </div>
  );
}
