import { env } from "@/config/env";
import { getFirebaseIdToken } from "@/lib/firebase-client";

let tokenProvider: () => Promise<string | null> = () => getFirebaseIdToken().catch(() => null);
export function setTokenProvider(fn: () => Promise<string | null>) {
  tokenProvider = fn;
}

export class ApiError extends Error {
  constructor(public status: number, message: string, public code?: string) {
    super(message);
  }
}

export async function http<T>(path: string, init: RequestInit & { json?: unknown; timeoutMs?: number } = {}): Promise<T> {
  const { json, timeoutMs = 30000, headers, ...rest } = init;
  const token = await tokenProvider();
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(`${env.apiUrl}${path}`, {
      ...rest,
      signal: controller.signal,
      headers: {
        ...(json !== undefined ? { "Content-Type": "application/json" } : {}),
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...headers,
      },
      body: json !== undefined ? JSON.stringify(json) : rest.body,
    });
    if (!res.ok) {
      const body = await res.json().catch(() => ({}));
      throw new ApiError(res.status, body.message ?? body.error ?? res.statusText, body.code);
    }
    return (await res.json()) as T;
  } catch (e) {
    if ((e as Error).name === "AbortError") {
      throw new ApiError(408, "Máy chủ phản hồi quá lâu. Vui lòng thử lại.", "timeout");
    }
    if (e instanceof ApiError) throw e;
    throw new ApiError(0, "Mất kết nối máy chủ. Vui lòng kiểm tra lại kết nối mạng và thử lại.", "network_error");
  } finally {
    clearTimeout(timer);
  }
}
