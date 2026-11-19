"use client";

import { useState } from "react";
import { initials } from "@/lib/format";
import { cn } from "@/lib/utils";

const TONES = ["bg-accent text-forest", "bg-info-soft text-info", "bg-warning-soft text-warning", "bg-danger-soft text-danger", "bg-success-soft text-success"];

// Material Icons SVG paths khớp 100% với FloriaAvatarPreset trong floria_app
const PRESET_MAP: Record<string, { from: string; to: string; title: string; path: string }> = {
  sprout: {
    from: "#2E6F40",
    to: "#68B684",
    title: "Mầm Xanh Floria",
    // Icons.spa_rounded
    path: "M15.49 9.63c-.18-2.79-1.31-5.51-3.43-7.63-2.14 2.14-3.32 4.86-3.55 7.63 1.28.68 2.46 1.56 3.49 2.63 1.03-1.06 2.21-1.94 3.49-2.63zm-6.5 2.65c-.14-.1-.3-.19-.45-.29.15.11.31.19.45.29zm6.42-.25c-.13.09-.27.16-.4.26.13-.1.27-.17.4-.26zM12 15.45C9.85 12.17 6.18 10 2 10c0 5.32 3.36 9.82 8.03 11.49.63.23 1.29.4 1.97.51.68-.12 1.33-.29 1.97-.51C18.64 19.82 22 15.32 22 10c-4.18 0-7.85 2.17-10 5.45z",
  },
  monstera: {
    from: "#1B4332",
    to: "#40916C",
    title: "Trầu Bà Nam Mỹ",
    // Icons.eco_rounded
    path: "M6.05 8.05a7.001 7.001 0 0 0 9.9 9.9C19 14.9 19 8.1 19 5c-3.1 0-9.9 0-12.95 3.05zM15.6 15.6c-1.5 1.5-4.3 1.6-6.2.5 1.8-1.9 3.7-3.8 5.6-5.7.2-.2.2-.5 0-.7-.2-.2-.5-.2-.7 0-1.9 1.9-3.8 3.8-5.7 5.6-1.1-1.9-1-4.7.5-6.2C11.1 7.1 15 6.9 17 7c.1 2-.1 5.9-1.4 8.6z",
  },
  succulent: {
    from: "#2B5B84",
    to: "#6BA3BE",
    title: "Sen Đá Cát Tường",
    // Icons.filter_vintage_rounded
    path: "M18.7 12.4c-.28-.16-.57-.29-.86-.4.29-.11.58-.24.86-.4 1.92-1.11 2.99-3.12 3-5.19-1.79-1.03-4.07-1.11-6 0-.28.16-.54.35-.78.54.05-.31.08-.63.08-.95 0-2.22-1.21-4.15-3-5.19C10.21 1.85 9 3.78 9 6c0 .32.03.64.08.95-.24-.2-.5-.39-.78-.55-1.92-1.11-4.2-1.03-6 0 0 2.07 1.07 4.08 3 5.19.28.16.57.29.86.4-.29.11-.58.24-.86.4-1.92 1.11-2.99 3.12-3 5.19 1.79 1.03 4.07 1.11 6 0 .28-.16.54-.35.78-.54-.05.32-.08.64-.08.96 0 2.22 1.21 4.15 3 5.19 1.79-1.04 3-2.97 3-5.19 0-.32-.03-.64-.08-.95.24.2.5.38.78.54 1.92 1.11 4.2 1.03 6 0-.01-2.07-1.08-4.08-3-5.19zM12 16c-2.21 0-4-1.79-4-4s1.79-4 4-4 4 1.79 4 4-1.79 4-4 4z",
  },
  cactus: {
    from: "#2D6A4F",
    to: "#74C69D",
    title: "Xương Rồng Sa Mạc",
    // Icons.nature_rounded
    path: "M13 16.12c3.47-.41 6.17-3.36 6.17-6.95 0-3.87-3.13-7-7-7s-7 3.13-7 7c0 3.47 2.52 6.34 5.83 6.89V20H6c-.55 0-1 .45-1 1s.45 1 1 1h12c.55 0 1-.45 1-1s-.45-1-1-1h-5v-3.88z",
  },
  sunflower: {
    from: "#D9531E",
    to: "#F4A261",
    title: "Hướng Dương Rực Rỡ",
    // Icons.wb_sunny_rounded
    path: "M6.76 4.84l-1.8-1.79-1.41 1.41 1.79 1.79 1.42-1.41zM4 10.5H1v2h3v-2zm9-9.95h-2V3.5h2V.55zm7.45 3.91l-1.41-1.41-1.79 1.79 1.41 1.41 1.79-1.79zm-3.21 13.7l1.79 1.8 1.41-1.41-1.8-1.79-1.4 1.4zM20 10.5v2h3v-2h-3zm-8-5c-3.31 0-6 2.69-6 6s2.69 6 6 6 6-2.69 6-6-2.69-6-6-6zm-1 16.95h2V19.5h-2v2.95zm-7.45-3.91l1.41 1.41 1.79-1.8-1.41-1.41-1.79 1.8z",
  },
  bonsai: {
    from: "#3F4E4F",
    to: "#2C3639",
    title: "Bonsai Trí Tuệ",
    // Icons.park_rounded
    path: "M17 12h2L12 2 5 12h2l-3.9 6h6.92v4h3.96v-4H21z",
  },
};

export function UserAvatar({ name, src, className }: { name: string; src?: string; className?: string }) {
  const [loadedSrc, setLoadedSrc] = useState<string | null>(null);
  const [failedSrc, setFailedSrc] = useState<string | null>(null);
  const tone = TONES[[...name].reduce((s, c) => s + c.charCodeAt(0), 0) % TONES.length];
  const raw = src?.trim() ?? "";

  if (raw.startsWith("preset:")) {
    const id = raw.slice("preset:".length).trim();
    const preset = PRESET_MAP[id] ?? PRESET_MAP.sprout;
    return (
      <span
        title={preset.title}
        style={{ backgroundImage: `linear-gradient(135deg, ${preset.from}, ${preset.to})` }}
        className={cn("grid size-8 shrink-0 place-items-center rounded-full text-white shadow-xs", className)}
      >
        <svg viewBox="0 0 24 24" fill="currentColor" className="size-[55%]" aria-hidden="true">
          <path d={preset.path} />
        </svg>
      </span>
    );
  }

  const isUrl = raw.startsWith("http://") || raw.startsWith("https://") || raw.startsWith("data:image/") || raw.startsWith("/");
  const isValid = isUrl && failedSrc !== raw;
  const isLoaded = isValid && loadedSrc === raw;

  if (isValid) {
    return (
      <span className={cn("relative inline-block size-8 shrink-0 overflow-hidden rounded-full border border-border/60 bg-muted", className)}>
        {!isLoaded && <span aria-hidden className="absolute inset-0 animate-pulse bg-muted" />}
        <img
          src={raw}
          alt={name}
          referrerPolicy="no-referrer"
          onLoad={() => setLoadedSrc(raw)}
          onError={() => setFailedSrc(raw)}
          className={cn("size-full object-cover transition-opacity duration-200", isLoaded ? "opacity-100" : "opacity-0")}
        />
      </span>
    );
  }

  return (
    <span className={cn("grid size-8 shrink-0 place-items-center rounded-full text-xs font-semibold", tone, className)}>
      {initials(name)}
    </span>
  );
}
