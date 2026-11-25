import type { ReactNode } from "react";
import { Label } from "@/components/ui/label";
import { cn } from "@/lib/utils";

/** Labelled form field with inline error message. */
export function Field({
  label,
  htmlFor,
  error,
  children,
  className,
  hint,
}: {
  label: ReactNode;
  htmlFor: string;
  error?: string;
  children: ReactNode;
  className?: string;
  hint?: ReactNode;
}) {
  return (
    <div className={cn("space-y-1.5", className)}>
      <div className="flex items-center justify-between">
        <Label htmlFor={htmlFor} className="text-sm font-semibold">
          {label}
        </Label>
        {hint}
      </div>
      {children}
      {error && <p className="text-xs font-medium text-danger">{error}</p>}
    </div>
  );
}
