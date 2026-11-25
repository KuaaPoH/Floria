const vnd = new Intl.NumberFormat("vi-VN");

/** 86500000 -> "86.500.000 ₫" */
export function formatVND(value: number): string {
  return `${vnd.format(Math.round(value))} ₫`;
}

/** Compact VND for chart axes: 86500000 -> "86,5tr" */
export function formatVNDCompact(value: number): string {
  if (Math.abs(value) >= 1_000_000_000) return `${(value / 1_000_000_000).toFixed(1).replace(".", ",")} tỷ`;
  if (Math.abs(value) >= 1_000_000) return `${(value / 1_000_000).toFixed(1).replace(".", ",")}tr`;
  if (Math.abs(value) >= 1_000) return `${Math.round(value / 1_000)}k`;
  return String(value);
}

export function formatNumber(value: number): string {
  return vnd.format(value);
}

export function formatPercent(value: number, digits = 1): string {
  return `${value.toFixed(digits).replace(".", ",")}%`;
}

const pad = (n: number) => String(n).padStart(2, "0");

/** ISO -> "DD/MM/YYYY" (supports optional lang + Intl opts for user web) */
export function formatDate(
  input: string | Date,
  lang: "vi" | "en" = "vi",
  opts?: Intl.DateTimeFormatOptions,
): string {
  const d = typeof input === "string" ? new Date(input) : input;
  if (Number.isNaN(d.getTime())) return "—";
  if (opts || lang === "en") {
    return new Intl.DateTimeFormat(lang === "vi" ? "vi-VN" : "en-GB", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      ...opts,
    }).format(d);
  }
  return `${pad(d.getDate())}/${pad(d.getMonth() + 1)}/${d.getFullYear()}`;
}

/** ISO -> "DD/MM/YYYY HH:mm" */
export function formatDateTime(input: string | Date, lang: "vi" | "en" = "vi"): string {
  const d = typeof input === "string" ? new Date(input) : input;
  if (Number.isNaN(d.getTime())) return "—";
  if (lang === "en") {
    return formatDate(d, lang, { hour: "2-digit", minute: "2-digit" });
  }
  return `${formatDate(d)} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

export function formatTime(iso: string, lang: "vi" | "en" = "vi"): string {
  return new Intl.DateTimeFormat(lang === "vi" ? "vi-VN" : "en-GB", {
    hour: "2-digit",
    minute: "2-digit",
  }).format(new Date(iso));
}

export function formatRelativeDays(iso: string, lang: "vi" | "en" = "vi", now = new Date()): string {
  const d = new Date(iso);
  const start = (x: Date) => new Date(x.getFullYear(), x.getMonth(), x.getDate()).getTime();
  const diff = Math.round((start(d) - start(now)) / 86400000);
  const rtf = new Intl.RelativeTimeFormat(lang === "vi" ? "vi" : "en", { numeric: "auto" });
  return rtf.format(diff, "day");
}

export function percent(n: number): string {
  return `${Math.round(n * 100)}%`;
}

export function formatRelative(input: string | Date): string {
  const d = typeof input === "string" ? new Date(input) : input;
  const diff = (Date.now() - d.getTime()) / 1000;
  if (diff < 60) return "vừa xong";
  if (diff < 3600) return `${Math.floor(diff / 60)} phút trước`;
  if (diff < 86400) return `${Math.floor(diff / 3600)} giờ trước`;
  if (diff < 86400 * 7) return `${Math.floor(diff / 86400)} ngày trước`;
  return formatDate(d);
}

export function initials(name: string): string {
  const parts = name.trim().split(/\s+/);
  return ((parts[0]?.[0] ?? "") + (parts.at(-1)?.[0] ?? "")).toUpperCase();
}
