/**
 * Local mock persistence: each collection is seeded from src/mocks and stored in localStorage,
 * so CRUD operations survive reloads in demo mode. Reset with resetMockDb().
 */
const PREFIX = "floria.mock.";
const memory = new Map<string, unknown>();

const hasStorage = () => typeof window !== "undefined" && !!window.localStorage;

export function readStore<T>(key: string, seed: () => T): T {
  if (memory.has(key)) return memory.get(key) as T;
  let value: T | undefined;
  if (hasStorage()) {
    const raw = window.localStorage.getItem(PREFIX + key);
    if (raw) {
      try {
        value = JSON.parse(raw) as T;
      } catch {
        value = undefined;
      }
    }
  }
  if (value === undefined) value = seed();
  memory.set(key, value);
  return value;
}

export function writeStore<T>(key: string, value: T) {
  memory.set(key, value);
  if (hasStorage()) window.localStorage.setItem(PREFIX + key, JSON.stringify(value));
}

export function resetMockDb() {
  memory.clear();
  if (!hasStorage()) return;
  Object.keys(window.localStorage)
    .filter((k) => k.startsWith(PREFIX))
    .forEach((k) => window.localStorage.removeItem(k));
}

export const delay = (ms = 220) => new Promise((r) => setTimeout(r, ms));

export interface Collection<T extends { id: string }> {
  list(): Promise<T[]>;
  get(id: string): Promise<T | undefined>;
  create(item: T): Promise<T>;
  update(id: string, patch: Partial<T>): Promise<T>;
  remove(id: string): Promise<void>;
  replaceAll(items: T[]): Promise<void>;
}

export function createCollection<T extends { id: string }>(key: string, seed: () => T[]): Collection<T> {
  const all = () => readStore<T[]>(key, seed);
  return {
    async list() {
      await delay();
      return [...all()];
    },
    async get(id) {
      await delay(120);
      return all().find((x) => x.id === id);
    },
    async create(item) {
      await delay();
      writeStore(key, [item, ...all()]);
      return item;
    },
    async update(id, patch) {
      await delay();
      let updated: T | undefined;
      writeStore(
        key,
        all().map((x) => {
          if (x.id !== id) return x;
          updated = { ...x, ...patch };
          return updated;
        }),
      );
      if (!updated) throw new Error("Không tìm thấy bản ghi");
      return updated;
    },
    async remove(id) {
      await delay();
      writeStore(
        key,
        all().filter((x) => x.id !== id),
      );
    },
    async replaceAll(items) {
      writeStore(key, items);
    },
  };
}
