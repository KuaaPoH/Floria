import { API_URL } from "./config";
import { getFirebaseIdToken } from "./firebase-client";

/** Thin REST client for API mode. Automatically attaches Firebase ID token when signed in. */
export async function apiRequest<T>(path: string, init?: RequestInit): Promise<T> {
  const token = await getFirebaseIdToken();
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    ...(init?.headers as Record<string, string> | undefined),
  };
  if (token && !headers.Authorization) {
    headers.Authorization = `Bearer ${token}`;
  }

  const res = await fetch(`${API_URL}${path}`, {
    ...init,
    headers,
  });
  if (!res.ok) {
    const text = await res.text();
    let msg = text;
    try {
      const parsed = JSON.parse(text) as { error?: string };
      if (parsed?.error) msg = parsed.error;
    } catch {
      // Giữ nguyên raw text nếu không phải JSON
    }
    throw new Error(msg || `API ${res.status}`);
  }
  return (await res.json()) as T;
}
