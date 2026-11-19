export function toIsoString(val: unknown, fallback = new Date().toISOString()): string {
  if (val === null || val === undefined || val === "") return fallback;
  if (typeof val === "number") {
    if (!Number.isFinite(val)) return fallback;
    const ms = val < 1e12 ? val * 1000 : val;
    return new Date(ms).toISOString();
  }
  if (typeof val === "string") {
    const asNum = Number(val);
    if (!Number.isNaN(asNum) && /^\d+$/.test(val.trim())) {
      const ms = asNum < 1e12 ? asNum * 1000 : asNum;
      return new Date(ms).toISOString();
    }
    const t = Date.parse(val);
    return Number.isNaN(t) ? fallback : new Date(t).toISOString();
  }
  if (val instanceof Date) {
    return val.toISOString();
  }
  if (typeof val === "object" && val !== null) {
    const maybeTs = val as { toDate?: () => Date; _seconds?: number; seconds?: number };
    if (typeof maybeTs.toDate === "function") {
      return maybeTs.toDate().toISOString();
    }
    const sec = maybeTs.seconds ?? maybeTs._seconds;
    if (typeof sec === "number") {
      return new Date(sec * 1000).toISOString();
    }
  }
  return fallback;
}

export function extractUserAvatar(data: Record<string, unknown>, authPhotoUrl?: string | null): string | undefined {
  const candidates = [data.customPhotoUrl, data.googlePhotoUrl, data.photoUrl, data.avatar, authPhotoUrl];
  for (const raw of candidates) {
    if (typeof raw !== "string") continue;
    const trimmed = raw.trim();
    if (!trimmed || trimmed === "null" || trimmed === "None" || trimmed === "undefined") continue;
    return trimmed;
  }
  return undefined;
}

function getPreferredAddress(data: Record<string, unknown>): Record<string, unknown> | null {
  const addresses = data.addresses;
  if (!Array.isArray(addresses) || addresses.length === 0) return null;
  const preferred =
    addresses.find((a) => typeof a === "object" && a !== null && (a as Record<string, unknown>).isDefault === true) ??
    addresses[0];
  return typeof preferred === "object" && preferred !== null ? (preferred as Record<string, unknown>) : null;
}

export function extractUserPhone(data: Record<string, unknown>, authPhone?: string | null): string {
  const addr = getPreferredAddress(data);
  if (addr && typeof addr.phone === "string" && addr.phone.trim()) {
    return addr.phone.trim();
  }
  if (typeof data.phone === "string" && data.phone.trim()) {
    return data.phone.trim();
  }
  if (typeof authPhone === "string" && authPhone.trim()) {
    return authPhone.trim();
  }
  return "";
}

export function extractCity(data: Record<string, unknown>): string {
  const addr = getPreferredAddress(data);
  if (addr) {
    const city = addr.provinceName ?? addr.province ?? addr.city ?? addr.districtName ?? addr.district;
    if (typeof city === "string" && city.trim()) return city.trim();
    if (typeof addr.address === "string" && addr.address.trim()) {
      const parts = addr.address.split(",").map((s) => s.trim()).filter(Boolean);
      if (parts.length > 0) return parts[parts.length - 1];
    }
  }
  if (typeof data.city === "string" && data.city.trim()) return data.city.trim();
  if (typeof data.address === "string" && data.address.trim()) {
    const parts = data.address.split(",").map((s) => s.trim()).filter(Boolean);
    if (parts.length > 0) return parts[parts.length - 1];
  }
  return "Chưa cập nhật";
}
