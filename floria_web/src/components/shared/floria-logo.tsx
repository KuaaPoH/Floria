import { cn } from "@/lib/utils";

/** Floria brand mark: Logo biểu tượng chính thức của Floria Admin */
export function FloriaMark({ className }: { className?: string }) {
  return (
    <img
      src="/adminicon.jpg"
      alt="Floria Logo"
      className={cn("size-8 rounded-[9px] object-cover shadow-sm select-none shrink-0", className)}
      loading="eager"
    />
  );
}
