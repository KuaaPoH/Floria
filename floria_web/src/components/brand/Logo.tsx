"use client";

import Link from "next/link";
import { cn } from "@/lib/utils";

export function LogoMark({ className }: { className?: string }) {
  return (
    <img
      src="/logo.jpg"
      alt="Floria"
      className={cn("size-8 rounded-[10px] object-cover shadow-sm shrink-0", className)}
    />
  );
}

export function Logo({ className, inverted = false }: { className?: string; inverted?: boolean }) {
  return (
    <Link href="/" className={cn("flex items-center gap-2.5", className)} aria-label="Floria">
      <LogoMark />
      <span className={cn("text-[1.35rem] font-bold tracking-tight", inverted ? "text-forest-foreground" : "text-forest dark:text-foreground")}>
        Floria
      </span>
    </Link>
  );
}
