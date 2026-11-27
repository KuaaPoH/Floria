import type { AppUser } from "@/types";

interface UsersCacheEntry {
  data: AppUser[];
  expiresAt: number;
}

const globalForUsersCache = globalThis as unknown as {
  __floriaUsersCache?: UsersCacheEntry | null;
};

export function getUsersCache(): AppUser[] | null {
  const entry = globalForUsersCache.__floriaUsersCache;
  if (!entry || entry.expiresAt <= Date.now()) {
    globalForUsersCache.__floriaUsersCache = null;
    return null;
  }
  return entry.data;
}

export function setUsersCache(data: AppUser[], ttlMs = 30_000): void {
  globalForUsersCache.__floriaUsersCache = {
    data,
    expiresAt: Date.now() + ttlMs,
  };
}

export function invalidateUsersCache(): void {
  globalForUsersCache.__floriaUsersCache = null;
}
