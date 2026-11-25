"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { Cloud, CloudDrizzle, CloudLightning, CloudSun, Droplets, MapPin, RotateCw, Snowflake, Sun, Wind } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { useAddresses, useCatalog } from "@/hooks/queries";
import { useLang } from "@/i18n";
import { weatherService } from "@/services/content.service";
import type { HomeWeatherWidget, WeatherAdviceRuleItem, WeatherSnapshot } from "@/types/user";

function describe(code: number) {
  if (code === 0) return { label: "Trời quang", Icon: Sun };
  if (code <= 3) return { label: "Có mây", Icon: CloudSun };
  if (code <= 48) return { label: "Sương mù", Icon: Cloud };
  if (code <= 67 || (code >= 80 && code <= 82)) return { label: "Có mưa", Icon: CloudDrizzle };
  if (code <= 77) return { label: "Tuyết", Icon: Snowflake };
  return { label: "Dông", Icon: CloudLightning };
}

function matchWeatherRule(w: WeatherSnapshot, rules: WeatherAdviceRuleItem[]): WeatherAdviceRuleItem | null {
  for (const r of rules) {
    if (!r.active) continue;
    switch (r.conditionType) {
      case "temperature_high":
        if (w.temperature >= (r.minTemp ?? 33)) return r;
        break;
      case "temperature_low":
        if (w.temperature < (r.maxTemp ?? 18)) return r;
        break;
      case "humidity_high":
        if (w.humidity >= (r.minHumidity ?? 85)) return r;
        break;
      case "humidity_low":
        if (w.humidity <= (r.maxHumidity ?? 50)) return r;
        break;
      case "rain": {
        const codes = r.weatherCodes.length > 0 ? r.weatherCodes : [51, 53, 55, 61, 63, 65, 80, 81, 82];
        if (codes.includes(w.weatherCode) || w.humidity >= (r.minHumidity ?? 85)) return r;
        break;
      }
      case "storm_wind": {
        const codes = r.weatherCodes.length > 0 ? r.weatherCodes : [95, 96, 99];
        if (codes.includes(w.weatherCode) || w.windSpeed >= (r.minWindSpeed ?? 25)) return r;
        break;
      }
      default:
        break;
    }
  }
  return null;
}

/** Care recommendation derived strictly from Firestore WeatherAdviceRules managed in Admin. */
export function weatherAdvice(w: WeatherSnapshot, rules: WeatherAdviceRuleItem[] = []): WeatherAdviceRuleItem | null {
  return matchWeatherRule(w, rules);
}

export function currentSlot(widgets: HomeWeatherWidget[], hour = new Date().getHours()) {
  return widgets.find((w) => (w.fromHour < w.toHour ? hour >= w.fromHour && hour < w.toHour : hour >= w.fromHour || hour < w.toHour)) ?? widgets[0];
}

export function WeatherCard() {
  const lang = useLang();
  const { data: addresses, isLoading: addrLoading } = useAddresses();
  const { data: catalog } = useCatalog();
  const def = addresses?.find((a) => a.isDefault) ?? addresses?.[0];
  const hasCoords = Boolean(def && def.latitude !== null && def.longitude !== null);
  const lat = hasCoords ? def!.latitude! : 10.7769;
  const lon = hasCoords ? def!.longitude! : 106.7009;

  const q = useQuery({
    queryKey: ["weather", lat, lon],
    queryFn: () => weatherService.current(lat, lon),
    staleTime: 15 * 60_000,
    retry: 1,
  });

  const widgets = catalog?.weatherWidgets?.length ? catalog.weatherWidgets : weatherService.widgets();
  const rules = catalog?.weatherRules ?? weatherService.rules();
  const slot = currentSlot(widgets);

  return (
    <div className="relative flex h-full flex-col overflow-hidden rounded-3xl bg-forest-gradient p-6 text-forest-foreground shadow-card">
      <div className="leaf-pattern pointer-events-none absolute inset-0 opacity-20" />
      <div className="relative flex items-center justify-between gap-2">
        <p className="text-sm font-semibold text-forest-foreground/80">{(lang === "vi" ? slot?.greeting : slot?.greetingEn) ?? "Khu vườn Floria"}</p>
        {hasCoords && def ? (
          <Link href="/profile/addresses" className="inline-flex items-center gap-1 text-xs text-forest-foreground/75 hover:underline">
            <MapPin className="size-3" />{def.wardName || def.provinceName}
          </Link>
        ) : (
          <Link href="/profile/addresses" className="inline-flex items-center gap-1 text-xs text-forest-foreground/75 hover:underline">
            <MapPin className="size-3" /> TP. Hồ Chí Minh · Đổi vị trí
          </Link>
        )}
      </div>
      {addrLoading || q.isLoading ? (
        <div className="relative mt-6 space-y-3">
          <Skeleton className="h-12 w-28 bg-forest-foreground/15" />
          <Skeleton className="h-4 w-48 bg-forest-foreground/15" />
        </div>
      ) : q.isError || !q.data ? (
        <div className="relative mt-5 flex flex-1 flex-col">
          <p className="text-lg font-semibold">Không thể tải thời tiết</p>
          <p className="mt-1 text-sm text-forest-foreground/75">Dịch vụ Open-Meteo tạm thời không phản hồi.</p>
          <Button variant="glass" size="sm" className="mt-auto w-fit" onClick={() => q.refetch()}><RotateCw /> Thử lại</Button>
        </div>
      ) : (
        <WeatherBody w={q.data} rules={rules} message={(lang === "vi" ? slot?.message : slot?.messageEn) ?? ""} />
      )}
    </div>
  );
}

function WeatherBody({ w, rules, message }: { w: WeatherSnapshot; rules: WeatherAdviceRuleItem[]; message: string }) {
  const { label, Icon } = describe(w.weatherCode);
  const matchedRule = weatherAdvice(w, rules);
  return (
    <div className="relative mt-4 flex flex-1 flex-col">
      <div className="flex items-center gap-4">
        <Icon className="size-12 text-sage" />
        <div>
          <p className="text-5xl font-bold tracking-tight">{Math.round(w.temperature)}°</p>
          <p className="text-sm text-forest-foreground/80">{label}</p>
        </div>
      </div>
      <div className="mt-4 flex gap-4 text-sm text-forest-foreground/80">
        <span className="inline-flex items-center gap-1.5"><Droplets className="size-4" />{w.humidity}%</span>
        <span className="inline-flex items-center gap-1.5"><Wind className="size-4" />{Math.round(w.windSpeed)} km/h</span>
      </div>
      <div className="mt-auto pt-5">
        {matchedRule && (
          <div className="rounded-2xl bg-forest-foreground/10 p-3 text-sm leading-relaxed backdrop-blur">
            {matchedRule.badgeText && <p className="mb-1 text-xs font-semibold uppercase tracking-wider text-sage">{matchedRule.badgeText}</p>}
            <p>{matchedRule.advice}</p>
          </div>
        )}
        {message && <p className="mt-2 text-xs text-forest-foreground/60">{message}</p>}
      </div>
    </div>
  );
}
