"use client";

import { Suspense, useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { BookOpen, Search } from "lucide-react";
import { PageContainer, PageHeader } from "@/components/layout/PageContainer";
import { CardGridSkeleton, EmptyState, ErrorState, LoadingState } from "@/components/layout/states";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useHandbook, usePlants } from "@/hooks/queries";
import { useLang } from "@/i18n";
import { formatDate } from "@/lib/format";
import { cn } from "@/lib/utils";

function HandbookContent() {
  const searchParams = useSearchParams();
  const initialQ = searchParams.get("q") ?? "";
  const lang = useLang();
  const handbookQ = useHandbook();
  const { data: userPlants = [] } = usePlants();
  const [q, setQ] = useState(initialQ);
  const [category, setCategory] = useState<string>("all");

  useEffect(() => {
    if (initialQ) setQ(initialQ);
  }, [initialQ]);

  const categories = useMemo(() => {
    const unique = new Set<string>();
    for (const a of handbookQ.data ?? []) {
      const cat = a.category?.trim();
      if (cat) unique.add(cat);
    }
    return [
      { value: "all", label: "Tất cả" },
      ...Array.from(unique).map((c) => ({ value: c, label: c })),
    ];
  }, [handbookQ.data]);

  const articles = useMemo(() => {
    const needle = q.trim().toLowerCase();
    return (handbookQ.data ?? [])
      .filter((a) => category === "all" || a.category === category)
      .filter((a) => !needle || [a.title, a.excerpt, ...a.tags].some((s) => s.toLowerCase().includes(needle)));
  }, [handbookQ.data, category, q]);

  const suggested = useMemo(() => {
    if (!userPlants.length || !handbookQ.data?.length) return [];
    const ids = new Set(userPlants.map((p) => p.speciesId));
    return handbookQ.data.filter((a) => a.tags.some((t) => ids.has(t))).slice(0, 2);
  }, [userPlants, handbookQ.data]);

  return (
    <PageContainer>
      <PageHeader
        eyebrow="Cẩm nang Floria"
        title="Cẩm nang chăm sóc cây cùng Floria"
        description="Bài viết thực hành theo mùa, kinh nghiệm tưới bón và hướng dẫn phòng trị bệnh lá từ đội ngũ Floria."
      />

      <div className="mb-8 flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div className="relative max-w-md flex-1">
          <Search className="absolute left-3.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
          <Input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Tìm bài viết, chủ đề chăm cây…" className="pl-10" />
        </div>
        <p className="text-sm text-muted-foreground">{articles.length} bài viết cẩm nang</p>
      </div>

      {suggested.length > 0 && !q && category === "all" && (
        <section className="mb-10 rounded-3xl bg-mint/40 p-5 md:p-6">
          <p className="eyebrow mb-3">Gợi ý theo khu vườn của bạn</p>
          <div className="grid gap-4 md:grid-cols-2">
            {suggested.map((a) => (
              <Link key={a.id} href={`/handbook/${a.slug}`} className="group flex gap-4 rounded-2xl border bg-card p-3 shadow-soft transition-all hover:shadow-card">
                <img src={a.image} alt={a.title} className="size-24 shrink-0 rounded-xl object-cover" />
                <div className="min-w-0">
                  <Badge variant="success">{a.category}</Badge>
                  <h3 className="mt-1.5 line-clamp-2 font-semibold group-hover:text-leaf">{a.title}</h3>
                  <p className="mt-1 text-xs text-muted-foreground">{formatDate(a.publishedAt, lang)}</p>
                </div>
              </Link>
            ))}
          </div>
        </section>
      )}

      <div className="space-y-6">
        <div className="scrollbar-none -mx-1 flex gap-2 overflow-x-auto px-1 pb-1">
          {categories.map((c) => {
            const active = category === c.value;
            return (
              <button
                key={c.value}
                onClick={() => setCategory(c.value)}
                className={cn("shrink-0 rounded-full border px-4 py-2 text-sm font-medium transition-colors", active ? "border-forest bg-forest text-forest-foreground" : "bg-card hover:border-leaf/50")}
              >
                {c.label}
              </button>
            );
          })}
        </div>

        {handbookQ.isError ? (
          <ErrorState onRetry={() => handbookQ.refetch()} />
        ) : handbookQ.isLoading ? (
          <CardGridSkeleton count={6} />
        ) : articles.length === 0 ? (
          <EmptyState icon={<BookOpen />} title="Không tìm thấy bài viết phù hợp" description="Thử đổi danh mục hoặc từ khóa tìm kiếm." action={<Button variant="outline" onClick={() => { setQ(""); setCategory("all"); }}>Xóa bộ lọc</Button>} />
        ) : (
          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {articles.map((a) => (
              <Link key={a.id} href={`/handbook/${a.slug}`} className="group flex flex-col overflow-hidden rounded-3xl border bg-card shadow-soft transition-all hover:-translate-y-1 hover:shadow-card">
                <div className="relative aspect-[16/10] overflow-hidden bg-mint">
                  <img src={a.image} alt={a.title} loading="lazy" className="size-full object-cover transition-transform duration-700 group-hover:scale-105" />
                  <Badge variant="glass" className="absolute left-3 top-3">{a.category}</Badge>
                </div>
                <div className="flex flex-1 flex-col p-5">
                  <div className="flex items-center gap-3 text-xs text-muted-foreground">
                    <span>{formatDate(a.publishedAt, lang)}</span>
                  </div>
                  <h2 className="mt-2 text-lg font-semibold leading-snug group-hover:text-leaf">{a.title}</h2>
                  <p className="mt-2 line-clamp-3 text-sm text-muted-foreground">{a.excerpt}</p>
                  <span className="mt-auto pt-4 text-sm font-semibold text-leaf">Đọc bài viết →</span>
                </div>
              </Link>
            ))}
          </div>
        )}
      </div>
    </PageContainer>
  );
}

export default function HandbookPage() {
  return (
    <Suspense fallback={<LoadingState className="min-h-[60vh]" />}>
      <HandbookContent />
    </Suspense>
  );
}
