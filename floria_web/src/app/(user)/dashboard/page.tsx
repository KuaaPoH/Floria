"use client";

import { useMemo } from "react";
import Link from "next/link";
import { AnimatePresence, motion } from "framer-motion";
import { ArrowRight, CalendarCheck, ScanLine, Sparkles, Sprout } from "lucide-react";
import { toast } from "sonner";
import { CareTaskItem, PlantCard } from "@/components/botanical";
import { PageContainer } from "@/components/layout/PageContainer";
import { CardGridSkeleton, EmptyState, ErrorState } from "@/components/layout/states";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { computeEffectiveStatus, nextTask, STATUS_PRIORITY, todaysTasks } from "@/features/garden/logic";
import { currentSlot, WeatherCard } from "@/features/dashboard/WeatherCard";
import { useCatalog, useGardens, useHandbook, usePlants, useScheduleMutations, useSchedules, useSpecies } from "@/hooks/queries";
import { useLang } from "@/i18n";
import { findPlantInfoOrFallback } from "@/mocks/user/plants-info";
import { IMG } from "@/mocks/user/images";
import { useAuth } from "@/stores/auth";

const QUOTES = [
  "Một chút quan tâm mỗi ngày, cả khu vườn sẽ đáp lại bằng màu xanh.",
  "Cây không vội vàng, nhưng mọi thứ vẫn kịp nở hoa.",
  "Chăm cây là cách dịu dàng nhất để chăm chính mình.",
];

export default function DashboardPage() {
  const user = useAuth((s) => s.user)!;
  const lang = useLang();
  const plantsQ = usePlants();
  const schedulesQ = useSchedules();
  const gardensQ = useGardens();
  const handbookQ = useHandbook();
  const { data: catalog } = useCatalog();
  useSpecies();
  const { complete } = useScheduleMutations();
  const plants = plantsQ.data ?? [];
  const schedules = schedulesQ.data ?? [];
  const now = new Date();
  const slotBanner = currentSlot(catalog?.weatherWidgets ?? [], now.getHours());
  const heroImage = slotBanner?.image || plants[0]?.image || IMG.plants.monstera;

  const tasks = useMemo(() => todaysTasks(schedules).filter((s) => plants.some((p) => p.id === s.plantId)), [schedules, plants]);
  const attention = useMemo(
    () =>
      plants
        .map((p) => ({ p, status: computeEffectiveStatus(p, schedules) }))
        .sort((a, b) => STATUS_PRIORITY.indexOf(a.status) - STATUS_PRIORITY.indexOf(b.status) || b.p.addedAt.localeCompare(a.p.addedAt))
        .slice(0, 4),
    [plants, schedules],
  );
  const suggested = useMemo(() => {
    const species = new Set(plants.map((p) => p.speciesId));
    const sick = plants.some((p) => p.healthStatus === "sick");
    return (handbookQ.data ?? [])
      .map((a) => ({ a, score: a.tags.filter((t) => species.has(t)).length + (sick && a.category === "disease" ? 2 : 0) }))
      .sort((x, y) => y.score - x.score)
      .slice(0, 3)
      .map((x) => x.a);
  }, [handbookQ.data, plants]);

  const dateLabel = new Intl.DateTimeFormat(lang === "vi" ? "vi-VN" : "en-GB", { weekday: "long", day: "numeric", month: "long" }).format(now);
  const gardenName = (id: string) => gardensQ.data?.find((g) => g.id === id)?.name;

  return (
    <PageContainer className="space-y-10">
      {/* Hero */}
      <section className="grid gap-5 lg:grid-cols-[1.6fr_1fr]">
        <div className="relative overflow-hidden rounded-3xl bg-card shadow-card">
          <img src={heroImage} alt="" className="absolute inset-y-0 right-0 hidden h-full w-1/2 object-cover md:block" />
          <div className="absolute inset-y-0 right-0 hidden w-1/2 bg-gradient-to-r from-card via-card/40 to-transparent md:block" />
          <div className="relative max-w-lg p-7 md:p-9">
            <p className="text-sm font-medium capitalize text-muted-foreground">{dateLabel}</p>
            <h1 className="mt-2 text-3xl font-bold tracking-tight md:text-4xl">Chào {user.displayName.split(" ").slice(-1)[0]}, khu vườn đang chờ bạn</h1>
            <p className="mt-3 text-muted-foreground">{QUOTES[now.getDate() % QUOTES.length]}</p>
            <div className="mt-6 flex flex-wrap gap-4 text-sm">
              <Stat value={plants.length} label="cây đang chăm" loading={plantsQ.isLoading} />
              <Stat value={tasks.length} label="việc hôm nay" loading={schedulesQ.isLoading} />
              <Stat value={gardensQ.data?.length ?? 0} label="khu vườn" loading={gardensQ.isLoading} />
            </div>
            <div className="mt-7 flex flex-wrap gap-2">
              <Button asChild size="lg"><Link href="/discovery"><ScanLine /> Quét cây</Link></Button>
              <Button asChild size="lg" variant="outline"><Link href="/garden"><Sprout /> Khu vườn của tôi</Link></Button>
            </div>
          </div>
        </div>
        <WeatherCard />
      </section>

      {/* Tasks + attention */}
      <section className="grid gap-8 lg:grid-cols-[1fr_1.6fr]">
        <div>
          <div className="mb-4 flex items-center justify-between">
            <h2 className="flex items-center gap-2 text-xl font-semibold"><CalendarCheck className="size-5 text-leaf" /> Việc cần làm hôm nay</h2>
            <span className="rounded-full bg-mint px-2.5 py-0.5 text-xs font-semibold text-forest">{tasks.length}</span>
          </div>
          {schedulesQ.isError ? (
            <ErrorState onRetry={() => schedulesQ.refetch()} />
          ) : schedulesQ.isLoading || plantsQ.isLoading ? (
            <div className="space-y-3">{[0, 1, 2].map((i) => <Skeleton key={i} className="h-[74px] rounded-2xl" />)}</div>
          ) : tasks.length === 0 ? (
            <EmptyState icon={<Sparkles />} title="Hoàn thành mọi việc!" description="Không còn việc chăm cây nào cho hôm nay. Hãy tận hưởng khu vườn của bạn." />
          ) : (
            <ul className="space-y-3">
              <AnimatePresence initial={false}>
                {tasks.map((s) => (
                  <CareTaskItem
                    key={s.id}
                    schedule={s}
                    plant={plants.find((p) => p.id === s.plantId)}
                    pending={complete.isPending && complete.variables === s.id}
                    onComplete={() => complete.mutate(s.id, { onSuccess: () => toast.success("Đã đánh dấu hoàn thành") })}
                  />
                ))}
              </AnimatePresence>
            </ul>
          )}
        </div>
        <div>
          <div className="mb-4 flex items-center justify-between">
            <h2 className="text-xl font-semibold">Khu vườn của tôi</h2>
            <Button asChild variant="ghost" size="sm"><Link href="/garden">Xem tất cả <ArrowRight /></Link></Button>
          </div>
          {plantsQ.isError ? (
            <ErrorState onRetry={() => plantsQ.refetch()} />
          ) : plantsQ.isLoading ? (
            <CardGridSkeleton count={2} className="lg:grid-cols-2" />
          ) : plants.length === 0 ? (
            <EmptyState title="Khu vườn còn trống" description="Thêm cây đầu tiên bằng cách quét ảnh hoặc chọn từ bách khoa." action={<Button asChild><Link href="/garden">Thêm cây</Link></Button>} />
          ) : (
            <div className="grid gap-4 sm:grid-cols-2">
              {attention.map(({ p, status }) => (
                <motion.div key={p.id} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
                  <PlantCard plant={p} info={findPlantInfoOrFallback(p.speciesId, p.nickname, p.image)} status={status} next={nextTask(p.id, schedules)} gardenName={gardenName(p.gardenId)} />
                </motion.div>
              ))}
            </div>
          )}
        </div>
      </section>

      {/* Handbook */}
      <section>
        <div className="mb-4 flex items-center justify-between">
          <div>
            <h2 className="text-xl font-semibold">Cẩm nang dành cho khu vườn của bạn</h2>
            <p className="text-sm text-muted-foreground">Gợi ý dựa trên các loài cây bạn đang chăm.</p>
          </div>
          <Button asChild variant="ghost" size="sm"><Link href="/handbook">Cẩm nang <ArrowRight /></Link></Button>
        </div>
        {handbookQ.isLoading ? (
          <CardGridSkeleton count={3} />
        ) : (
          <div className="grid gap-5 md:grid-cols-3">
            {suggested.map((a) => (
              <Link key={a.id} href={`/handbook/${a.slug}`} className="group flex gap-4 rounded-3xl border bg-card p-3 shadow-soft transition-all hover:shadow-card">
                <img src={a.image} alt="" loading="lazy" className="size-24 shrink-0 rounded-2xl object-cover" />
                <div className="min-w-0 py-1">
                  <h3 className="line-clamp-2 text-sm font-semibold leading-snug group-hover:text-leaf">{a.title}</h3>
                  <p className="mt-1 line-clamp-2 text-xs text-muted-foreground">{a.excerpt}</p>
                </div>
              </Link>
            ))}
          </div>
        )}
      </section>
    </PageContainer>
  );
}

function Stat({ value, label, loading }: { value: number; label: string; loading?: boolean }) {
  return (
    <div className="rounded-2xl bg-mint/70 px-4 py-2.5">
      {loading ? <Skeleton className="h-6 w-8" /> : <p className="text-xl font-bold text-forest dark:text-foreground">{value}</p>}
      <p className="text-xs text-muted-foreground">{label}</p>
    </div>
  );
}
