import { env, isMock } from "@/config/env";
import { readDb, writeDb } from "@/mocks/user/db";
import { setRuntimeDiseasesInfo } from "@/mocks/user/diseases";
import { HOME_WEATHER_WIDGETS, PLANT_HANDBOOK } from "@/mocks/user/handbook";
import { setRuntimePlantsInfo } from "@/mocks/user/plants-info";
import { setRuntimeProducts } from "@/mocks/user/shop";
import type {
  DiseaseInfo,
  HandbookArticle,
  HomeWeatherWidget,
  PlantInfo,
  ProductReview,
  ReminderSettings,
  ShopProduct,
  SupportFaqItem,
  SystemNotificationItem,
  Voucher,
  WeatherAdviceRuleItem,
  WeatherSnapshot,
} from "@/types/user";
import { http } from "./api/http";
import { latency, requireUid } from "./mock/util";
import { session } from "./session";

export interface Province { id: string; code: string; name: string }
export interface Ward { id: string; code: string; name: string }

export interface CatalogPayload {
  source?: "firestore" | "mock";
  products: ShopProduct[];
  handbook: HandbookArticle[];
  vouchers: Voucher[];
  reviews: ProductReview[];
  plantsInfo?: PlantInfo[];
  diseasesInfo?: DiseaseInfo[];
  weatherWidgets?: HomeWeatherWidget[];
  weatherRules?: WeatherAdviceRuleItem[];
  supportArticles?: SupportFaqItem[];
  notifications?: SystemNotificationItem[];
}

let catalogCache: { data: CatalogPayload; expiresAt: number } | null = null;
let catalogInflight: Promise<CatalogPayload | null> | null = null;

export function invalidateCatalogCache() {
  catalogCache = null;
}

export async function fetchUserCatalog(force = false): Promise<CatalogPayload | null> {
  if (typeof window === "undefined" || isMock()) return null;
  if (!force && catalogCache && catalogCache.expiresAt > Date.now()) return catalogCache.data;
  if (!force && catalogInflight) return catalogInflight;

  catalogInflight = fetch("/api/user/catalog", { cache: "no-store" })
    .then(async (res) => {
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        throw new Error(body.error || body.message || "Mất kết nối máy chủ. Không thể tải dữ liệu từ hệ thống.");
      }
      const data = (await res.json()) as CatalogPayload;
      if (data.plantsInfo?.length) setRuntimePlantsInfo(data.plantsInfo);
      if (data.diseasesInfo?.length) setRuntimeDiseasesInfo(data.diseasesInfo);
      if (data.products?.length) setRuntimeProducts(data.products);
      catalogCache = { data, expiresAt: Date.now() + 2 * 60_000 };
      return data;
    })
    .catch((err) => {
      if (err instanceof Error && err.message && err.message !== "Failed to fetch") {
        throw err;
      }
      throw new Error("Mất kết nối máy chủ. Vui lòng kiểm tra lại kết nối mạng và thử lại.");
    })
    .finally(() => {
      catalogInflight = null;
    });

  return catalogInflight;
}

/** Real public data sources (no key): Open-Meteo weather, esgoo.net administrative units (34 provinces). */
export const weatherService = {
  async current(lat: number, lon: number): Promise<WeatherSnapshot> {
    const url = `${env.openMeteoUrl}?latitude=${lat}&longitude=${lon}&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code,is_day&timezone=auto`;
    const res = await fetch(url);
    if (!res.ok) throw new Error("weather_unavailable");
    const j = await res.json();
    const c = j.current;
    return {
      temperature: c.temperature_2m,
      humidity: c.relative_humidity_2m,
      windSpeed: c.wind_speed_10m,
      weatherCode: c.weather_code,
      isDay: c.is_day === 1,
      fetchedAt: new Date().toISOString(),
    };
  },
  widgets(): HomeWeatherWidget[] {
    if (catalogCache?.data.weatherWidgets?.length) {
      return catalogCache.data.weatherWidgets;
    }
    return isMock() ? HOME_WEATHER_WIDGETS : [];
  },
  rules(): WeatherAdviceRuleItem[] {
    return catalogCache?.data.weatherRules ?? [];
  },
};

export const regionService = {
  async provinces(): Promise<Province[]> {
    const res = await fetch(`${env.provincesUrl}/1/0.htm`);
    const j = await res.json();
    if (j.error !== 0) throw new Error("provinces_unavailable");
    return (j.data as Province[]).map(({ id, code, name }) => ({ id, code, name })).sort((a, b) => a.name.localeCompare(b.name, "vi"));
  },
  async wards(provinceId: string): Promise<Ward[]> {
    const res = await fetch(`${env.provincesUrl}/2/${provinceId}.htm`);
    const j = await res.json();
    if (j.error !== 0) throw new Error("wards_unavailable");
    return (j.data as { id: string; code: string; full_name: string }[]).map((w) => ({ id: w.id, code: w.code, name: w.full_name }));
  },
};

export const handbookService = {
  async list(): Promise<HandbookArticle[]> {
    if (!isMock()) {
      const cat = await fetchUserCatalog();
      return cat?.handbook ?? [];
    }
    await latency(120, 240);
    return [...PLANT_HANDBOOK].sort((a, b) => b.publishedAt.localeCompare(a.publishedAt));
  },
  async get(slug: string): Promise<HandbookArticle | null> {
    if (!isMock()) {
      const cat = await fetchUserCatalog();
      return cat?.handbook.find((a) => a.slug === slug || a.id === slug) ?? null;
    }
    await latency(80, 160);
    return PLANT_HANDBOOK.find((a) => a.slug === slug || a.id === slug) ?? null;
  },
};

export const supportService = {
  async list(): Promise<SupportFaqItem[]> {
    if (!isMock()) {
      const cat = await fetchUserCatalog();
      return cat?.supportArticles ?? [];
    }
    return [];
  },
};

export const reminderService = {
  async get(): Promise<ReminderSettings> {
    if (!isMock()) {
      const data = await http<{ reminderSettings?: Partial<ReminderSettings> }>("/auth/sync");
      const r = data.reminderSettings ?? {};
      const u = session.get() ?? "";
      return {
        userId: u,
        pushEnabled: Boolean(r.pushEnabled ?? false),
        watering: r.watering !== false,
        fertilizing: r.fertilizing !== false,
        inspection: r.inspection !== false,
        dndEnabled: Boolean(r.dndEnabled ?? false),
        dndStart: String(r.dndStart ?? "22:00"),
        dndEnd: String(r.dndEnd ?? "06:30"),
      };
    }
    await latency(100, 220);
    const u = requireUid(session.get());
    return (
      readDb().reminders.find((r) => r.userId === u) ?? {
        userId: u,
        pushEnabled: false,
        watering: true,
        fertilizing: true,
        inspection: true,
        dndEnabled: false,
        dndStart: "22:00",
        dndEnd: "06:30",
      }
    );
  },
  async update(patch: Partial<Omit<ReminderSettings, "userId">>): Promise<ReminderSettings> {
    if (!isMock()) {
      const current = await reminderService.get();
      const next = { ...current, ...patch };
      await http("/auth/sync", { method: "POST", json: { reminderSettings: next } });
      return next;
    }
    await latency(100, 220);
    const u = requireUid(session.get());
    return writeDb((db) => {
      let r = db.reminders.find((x) => x.userId === u);
      if (!r) {
        r = {
          userId: u,
          pushEnabled: false,
          watering: true,
          fertilizing: true,
          inspection: true,
          dndEnabled: false,
          dndStart: "22:00",
          dndEnd: "06:30",
        };
        db.reminders.push(r);
      }
      Object.assign(r, patch);
      return r;
    });
  },
};
