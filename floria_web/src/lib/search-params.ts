/** Shared `?q=` search param used by list pages that global search can deep-link into. */
export type QSearch = { q?: string };
export const validateQSearch = (s: Record<string, unknown>): QSearch => (typeof s.q === "string" && s.q ? { q: s.q } : {});
