/** Data mode: "mock" uses local seeded data persisted in the browser; "api" calls the Next.js /api/admin routes backed by Firebase & AI Engine. */
export type DataMode = "mock" | "api";

export const DATA_MODE: DataMode =
  (process.env.NEXT_PUBLIC_DATA_MODE as DataMode | undefined) === "api" ? "api" : "mock";

/** Base URL for the admin API routes (defaults to internal Next.js Route Handlers). */
export const API_URL: string = process.env.NEXT_PUBLIC_API_URL ?? "/api/admin";

export const IS_MOCK = DATA_MODE === "mock";
