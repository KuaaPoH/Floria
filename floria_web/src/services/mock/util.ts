import { delay } from "@/lib/id";

/** Simulated network latency for mock services. */
export const latency = (min = 250, max = 650) => delay(min + Math.random() * (max - min));

export class MockError extends Error {
  constructor(message: string, public code: string) {
    super(message);
  }
}

export function requireUid(uid: string | null | undefined): string {
  if (!uid) throw new MockError("Bạn cần đăng nhập để thực hiện thao tác này.", "unauthenticated");
  return uid;
}
