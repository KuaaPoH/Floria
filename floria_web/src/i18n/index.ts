"use client";

import { useCallback } from "react";
import { useSettings } from "@/stores/settings";
import type { Lang } from "@/types/user";

/**
 * i18n: every feature declares its own dictionary with defineDict({ vi, en }).
 * The English table must provide every Vietnamese key (enforced by the type).
 */
export type DictShape<T extends Record<string, string>> = { vi: T; en: { [K in keyof T]: string } };

export function defineDict<const T extends Record<string, string>>(d: DictShape<T>) {
  return d;
}

export function interpolate(s: string, vars?: Record<string, string | number>) {
  if (!vars) return s;
  return s.replace(/\{(\w+)\}/g, (_, k) => (vars[k] !== undefined ? String(vars[k]) : `{${k}}`));
}

export function translate<T extends Record<string, string>>(dict: DictShape<T>, lang: Lang, key: keyof T, vars?: Record<string, string | number>) {
  return interpolate((dict[lang] as Record<keyof T, string>)[key] ?? dict.vi[key], vars);
}

export const useLang = () => useSettings((s) => s.lang);

export function useT<T extends Record<string, string>>(dict: DictShape<T>) {
  const lang = useLang();
  return useCallback((key: keyof T, vars?: Record<string, string | number>) => translate(dict, lang, key, vars), [dict, lang]);
}
