"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { AlertOctagon, ArrowRight, History, ScanLine, Stethoscope } from "lucide-react";
import { PageHeader } from "@/components/layout/PageContainer";
import { CardGridSkeleton, EmptyState, ErrorState } from "@/components/layout/states";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { ProfileShell } from "@/features/profile/ProfileShell";
import { useDiseases, usePlants, useScanHistory, useSpecies } from "@/hooks/queries";
import { useLang } from "@/i18n";
import { formatDateTime, percent } from "@/lib/format";
import { cn } from "@/lib/utils";
import { findDisease } from "@/mocks/user/diseases";
import { findPlantInfoOrFallback } from "@/mocks/user/plants-info";
import type { ScanType } from "@/types/user";

type RangeFilter = "all" | "7" | "30" | "90";

export default function ScanHistoryPage() {
  const lang = useLang();
  const scansQ = useScanHistory();
  useSpecies();
  useDiseases();
  const { data: plants = [] } = usePlants();
  const [type, setType] = useState<"all" | ScanType>("all");
  const [range, setRange] = useState<RangeFilter>("all");

  const filtered = useMemo(() => {
    const now = Date.now();
    const limitMs = range === "all" ? null : Number(range) * 86400000;
    return (scansQ.data ?? [])
      .filter((s) => type === "all" || s.type === type)
      .filter((s) => !limitMs || now - new Date(s.createdAt).getTime() <= limitMs);
  }, [scansQ.data, type, range]);

  return (
    <ProfileShell>
      <div className="space-y-6">
        <PageHeader
          eyebrow="Lịch sử nhận diện"
          title="Lịch sử quét cây & bệnh lá"
          description="Xem lại toàn bộ các lượt nhận diện loài cây và chẩn đoán bệnh lá bạn đã thực hiện."
          className="mb-2"
          actions={
            <Button asChild variant="outline"><Link href="/discovery"><ScanLine /> Quét cây mới</Link></Button>
          }
        />

        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex gap-2">
            {[
              { value: "all" as const, label: "Tất cả" },
              { value: "identify" as const, label: "Nhận diện cây" },
              { value: "diagnose" as const, label: "Chẩn đoán bệnh" },
            ].map((item) => (
              <button
                key={item.value}
                onClick={() => setType(item.value)}
                className={cn("rounded-full border px-4 py-1.5 text-sm font-medium transition-colors", type === item.value ? "border-forest bg-forest text-forest-foreground" : "bg-card hover:border-leaf/50")}
              >
                {item.label}
              </button>
            ))}
          </div>

          <Select value={range} onValueChange={(v) => setRange(v as RangeFilter)}>
            <SelectTrigger className="h-10 w-44 rounded-xl"><SelectValue /></SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Mọi thời gian</SelectItem>
              <SelectItem value="7">7 ngày qua</SelectItem>
              <SelectItem value="30">30 ngày qua</SelectItem>
              <SelectItem value="90">90 ngày qua</SelectItem>
            </SelectContent>
          </Select>
        </div>

        {scansQ.isError ? (
          <ErrorState onRetry={() => scansQ.refetch()} />
        ) : scansQ.isLoading ? (
          <CardGridSkeleton count={4} className="lg:grid-cols-2" />
        ) : filtered.length === 0 ? (
          <EmptyState
            icon={<History />}
            title="Chưa có lượt quét nào"
            description="Thử quét nhận diện một loài cây mới hoặc chẩn đoán lá từ khu vườn của bạn."
            action={<Button asChild><Link href="/discovery"><ScanLine /> Quét cây ngay</Link></Button>}
          />
        ) : (
          <div className="grid gap-4 md:grid-cols-2">
            {filtered.map((s) => {
              const top = s.predictions?.[0];
              const species = top ? findPlantInfoOrFallback(top.speciesId) : null;
              const disease = s.diseaseId ? findDisease(s.diseaseId) : null;
              const plant = s.plantId ? plants.find((p) => p.id === s.plantId) : null;
              const href =
                s.type === "identify"
                  ? `/discovery/result/${s.id}`
                  : plant
                    ? `/garden/${plant.gardenId}/plants/${plant.id}/diagnosis`
                    : "/garden";

              return (
                <article key={s.id} className="flex gap-4 rounded-3xl border bg-card p-4 shadow-soft">
                  <img src={s.image} alt="Ảnh quét" className="size-24 shrink-0 rounded-2xl object-cover" />
                  <div className="flex min-w-0 flex-1 flex-col">
                    <div className="flex flex-wrap items-center gap-2">
                      <Badge variant={s.type === "identify" ? "brand" : "info"}>
                        {s.type === "identify" ? <ScanLine /> : <Stethoscope />}
                        {s.type === "identify" ? "Nhận diện" : "Chẩn đoán"}
                      </Badge>
                      <span className="text-xs text-muted-foreground">{formatDateTime(s.createdAt, lang)}</span>
                    </div>

                    {!s.isValidPlant ? (
                      <p className="mt-2 flex items-center gap-1.5 text-sm font-semibold text-warning">
                        <AlertOctagon className="size-4" /> Ảnh không phải thực vật
                      </p>
                    ) : s.type === "identify" ? (
                      <div className="mt-2">
                        <p className="truncate font-semibold">{species?.commonName ?? "Không xác định"}</p>
                        <p className="text-xs text-muted-foreground">
                          {species?.scientificName} {top ? `· Độ tin cậy ${percent(top.confidence)}` : ""}
                        </p>
                      </div>
                    ) : (
                      <div className="mt-2">
                        <p className="truncate font-semibold">{disease?.name ?? "Kết quả chẩn đoán"}</p>
                        <p className="text-xs text-muted-foreground">
                          {plant ? `${plant.nickname} · ` : ""}
                          {s.confidence ? `Độ tin cậy ${percent(s.confidence)}` : ""}
                          {s.appliedToRecord ? " · Đã ghi bệnh án" : ""}
                        </p>
                      </div>
                    )}

                    <div className="mt-auto pt-3">
                      <Button asChild size="sm" variant="outline">
                        <Link href={href}>Xem chi tiết <ArrowRight /></Link>
                      </Button>
                    </div>
                  </div>
                </article>
              );
            })}
          </div>
        )}
      </div>
    </ProfileShell>
  );
}
