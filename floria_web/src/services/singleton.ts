import { apiRequest } from "@/lib/api-client";
import { IS_MOCK } from "@/lib/config";
import { delay, readStore, writeStore } from "@/lib/mock-db";

export interface SingletonService<T> {
  key: string;
  get(): Promise<T>;
  save(value: T): Promise<T>;
}

/** A single configuration document (AI config, assistant settings, remote UI draft…). */
export function createSingletonService<T>(
  resource: string,
  seed: () => T,
  options?: { forceMock?: boolean },
): SingletonService<T> {
  if (IS_MOCK || options?.forceMock) {
    return {
      key: resource,
      async get() {
        await delay(150);
        return structuredClone(readStore<T>(resource, seed));
      },
      async save(value) {
        await delay(250);
        writeStore(resource, value);
        return value;
      },
    };
  }
  return {
    key: resource,
    get: () => apiRequest<T>(`/${resource}`),
    save: (value) => apiRequest<T>(`/${resource}`, { method: "PUT", body: JSON.stringify(value) }),
  };
}
