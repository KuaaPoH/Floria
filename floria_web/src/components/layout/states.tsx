"use client";

import type { ReactNode } from "react";
import { AlertTriangle, Leaf, Loader2, RotateCw } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { useT } from "@/i18n";
import { common } from "@/i18n/common";
import { cn } from "@/lib/utils";

export function EmptyState({ icon, title, description, action, className }: { icon?: ReactNode; title: string; description?: string; action?: ReactNode; className?: string }) {
  return (
    <div className={cn("flex flex-col items-center justify-center rounded-3xl border border-dashed border-sage/60 bg-mint/30 px-6 py-14 text-center", className)}>
      <div className="mb-4 grid size-14 place-items-center rounded-2xl bg-card text-leaf shadow-soft [&_svg]:size-6">{icon ?? <Leaf />}</div>
      <h3 className="text-lg font-semibold text-foreground">{title}</h3>
      {description && <p className="mt-1.5 max-w-sm text-sm text-muted-foreground">{description}</p>}
      {action && <div className="mt-5">{action}</div>}
    </div>
  );
}

export function ErrorState({ title, description, onRetry, className }: { title?: string; description?: string; onRetry?: () => void; className?: string }) {
  const t = useT(common);
  return (
    <div className={cn("flex flex-col items-center justify-center rounded-3xl border border-danger/25 bg-danger-soft/40 px-6 py-12 text-center", className)}>
      <div className="mb-3 grid size-12 place-items-center rounded-2xl bg-card text-danger shadow-soft">
        <AlertTriangle className="size-5" />
      </div>
      <h3 className="font-semibold">{title ?? t("errorTitle")}</h3>
      <p className="mt-1 max-w-sm text-sm text-muted-foreground">{description ?? t("errorBody")}</p>
      {onRetry && (
        <Button variant="outline" size="sm" className="mt-4" onClick={onRetry}>
          <RotateCw /> {t("retry")}
        </Button>
      )}
    </div>
  );
}

export function LoadingState({ label, className }: { label?: string; className?: string }) {
  const t = useT(common);
  return (
    <div className={cn("flex items-center justify-center gap-2 py-16 text-sm text-muted-foreground", className)}>
      <Loader2 className="size-4 animate-spin text-leaf" /> {label ?? t("loading")}
    </div>
  );
}

export function CardGridSkeleton({ count = 6, className }: { count?: number; className?: string }) {
  return (
    <div className={cn("grid gap-5 sm:grid-cols-2 lg:grid-cols-3", className)}>
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="overflow-hidden rounded-3xl border bg-card">
          <Skeleton className="aspect-[4/3] rounded-none" />
          <div className="space-y-2 p-4">
            <Skeleton className="h-4 w-2/3" />
            <Skeleton className="h-3 w-1/2" />
          </div>
        </div>
      ))}
    </div>
  );
}
