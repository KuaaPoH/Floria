/**
 * Mock persistence: a tiny localStorage-backed document store used by the
 * mock service implementations only. Components never import this file.
 */
import { buildSeed, DB_VERSION, type MockDbShape } from "./seed";

const KEY = "floria:db:v1";
let cache: MockDbShape | null = null;

function hasStorage() {
  return typeof window !== "undefined" && typeof window.localStorage !== "undefined";
}

export function readDb(): MockDbShape {
  if (cache) return cache;
  if (hasStorage()) {
    try {
      const raw = window.localStorage.getItem(KEY);
      if (raw) {
        const parsed = JSON.parse(raw) as MockDbShape;
        if (parsed.version === DB_VERSION) {
          cache = parsed;
          return parsed;
        }
      }
    } catch {
      /* corrupted storage — reseed */
    }
  }
  cache = buildSeed();
  persist();
  return cache;
}

function persist() {
  if (!cache || !hasStorage()) return;
  try {
    window.localStorage.setItem(KEY, JSON.stringify(cache));
  } catch {
    /* quota exceeded: keep in-memory copy */
  }
}

/** Mutate the db in place and persist. Returns whatever the mutator returns. */
export function writeDb<T>(mutator: (db: MockDbShape) => T): T {
  const db = readDb();
  const result = mutator(db);
  persist();
  return result;
}

export function resetDb() {
  cache = buildSeed();
  persist();
}
