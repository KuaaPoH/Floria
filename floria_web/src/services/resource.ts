import { apiRequest } from "@/lib/api-client";
import { IS_MOCK } from "@/lib/config";
import { createCollection } from "@/lib/mock-db";

export interface ResourceService<T extends { id: string }> {
  key: string;
  list(): Promise<T[]>;
  get(id: string): Promise<T | undefined>;
  create(item: T): Promise<T>;
  update(id: string, patch: Partial<T>): Promise<T>;
  remove(id: string): Promise<void>;
}

/**
 * Builds a CRUD service that reads from the local mock collection in MOCK mode
 * and from `${API_URL}/{resource}` in API mode. Feature services wrap this.
 */
export function createResourceService<T extends { id: string }>(
  resource: string,
  seed: () => T[],
  options?: { forceMock?: boolean },
): ResourceService<T> {
  if (IS_MOCK || options?.forceMock) {
    const col = createCollection<T>(resource, seed);
    return { key: resource, ...col };
  }
  return {
    key: resource,
    list: () => apiRequest<T[]>(`/${resource}`),
    get: (id) => apiRequest<T>(`/${resource}/${id}`),
    create: (item) => apiRequest<T>(`/${resource}`, { method: "POST", body: JSON.stringify(item) }),
    update: (id, patch) =>
      apiRequest<T>(`/${resource}/${id}`, { method: "PATCH", body: JSON.stringify(patch) }),
    remove: (id) => apiRequest<void>(`/${resource}/${id}`, { method: "DELETE" }),
  };
}
