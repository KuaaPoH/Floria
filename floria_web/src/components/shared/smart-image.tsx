"use client";

import { useState, type ReactNode } from "react";
import { cn } from "@/lib/utils";

interface SmartImageProps {
  src?: string | null;
  alt: string;
  className?: string;
  fallback: ReactNode;
}

export function SmartImage({ src, alt, className, fallback }: SmartImageProps) {
  const [loadedSrc, setLoadedSrc] = useState<string | null>(null);
  const [failedSrc, setFailedSrc] = useState<string | null>(null);

  const cleanSrc = src?.trim() ?? "";
  const isValid = Boolean(cleanSrc) && failedSrc !== cleanSrc;
  const isLoaded = isValid && loadedSrc === cleanSrc;

  if (!isValid) {
    return <>{fallback}</>;
  }

  return (
    <span className={cn("relative inline-block overflow-hidden bg-muted", className)}>
      {!isLoaded && <span aria-hidden className="absolute inset-0 animate-pulse bg-muted" />}
      <img
        src={cleanSrc}
        alt={alt}
        referrerPolicy="no-referrer"
        onLoad={() => setLoadedSrc(cleanSrc)}
        onError={() => setFailedSrc(cleanSrc)}
        className={cn(
          "size-full object-cover transition-opacity duration-200",
          isLoaded ? "opacity-100" : "opacity-0",
        )}
      />
    </span>
  );
}
