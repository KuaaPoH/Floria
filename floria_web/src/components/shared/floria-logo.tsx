import { cn } from "@/lib/utils";

/** Floria brand mark: two overlapping leaves forming an "F" silhouette. */
export function FloriaMark({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 32 32" className={cn("size-8", className)} aria-hidden>
      <rect width="32" height="32" rx="9" className="fill-mint" />
      <path d="M10 25c0-8 4.5-14 13-16-1 7.5-5.5 12.5-13 16Z" className="fill-forest" />
      <path d="M10 25c1.2-4.6 4-8.4 8.2-11.2" className="stroke-mint" strokeWidth="1.4" fill="none" strokeLinecap="round" />
      <path d="M9.5 18.5C8 14 9.6 9.8 13.8 7.5c.9 3.8-.6 7.6-4.3 11Z" className="fill-leaf" />
    </svg>
  );
}
