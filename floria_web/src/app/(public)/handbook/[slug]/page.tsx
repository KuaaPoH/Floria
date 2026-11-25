"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { ArrowLeft, BookOpen, Calendar, Sprout } from "lucide-react";
import { PageContainer } from "@/components/layout/PageContainer";
import { EmptyState, LoadingState } from "@/components/layout/states";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { useArticle, useHandbook } from "@/hooks/queries";
import { useLang } from "@/i18n";
import { formatDate } from "@/lib/format";
import { findPlantInfo } from "@/mocks/user/plants-info";

export default function HandbookArticlePage() {
  const { slug } = useParams<{ slug: string }>();
  const lang = useLang();
  const articleQ = useArticle(slug);
  const allQ = useHandbook();

  if (articleQ.isLoading) return <LoadingState className="min-h-[60vh]" />;
  const article = articleQ.data;
  if (!article) {
    return (
      <PageContainer>
        <EmptyState icon={<BookOpen />} title="Không tìm thấy bài viết" description="Bài viết có thể đã được di chuyển hoặc không tồn tại." action={<Button asChild><Link href="/handbook">Về Cẩm nang</Link></Button>} />
      </PageContainer>
    );
  }

  const relatedPlants = article.tags.map(findPlantInfo).filter((p): p is NonNullable<typeof p> => !!p);
  const relatedArticles = (allQ.data ?? []).filter((a) => a.id !== article.id).slice(0, 3);

  return (
    <PageContainer className="max-w-4xl">
      <Button asChild variant="ghost" size="sm" className="mb-6">
        <Link href="/handbook"><ArrowLeft /> Tất cả bài viết</Link>
      </Button>

      <article>
        <div className="flex flex-wrap items-center gap-3 text-sm text-muted-foreground">
          <Badge variant="success">{article.category}</Badge>
          <span className="inline-flex items-center gap-1"><Calendar className="size-3.5" /> {formatDate(article.publishedAt, lang)}</span>
        </div>

        <h1 className="mt-4 text-3xl font-bold leading-tight tracking-tight md:text-5xl">{article.title}</h1>
        <p className="mt-4 text-lg text-muted-foreground">{article.excerpt}</p>

        <div className="mt-8 overflow-hidden rounded-[2rem] bg-mint shadow-card">
          <img src={article.image} alt={article.title} className="aspect-[16/9] w-full object-cover" />
        </div>

        <div className="mt-8 space-y-5 text-base leading-relaxed text-foreground/90">
          {article.body.map((p, idx) => {
            const trimmed = p.trim();
            const isImgUrl =
              /^https?:\/\/\S+\.(?:png|jpe?g|webp|gif|avif)(?:\?\S*)?$/i.test(trimmed) ||
              /^https?:\/\/i\.ibb\.co\/\S+$/i.test(trimmed) ||
              trimmed.startsWith("data:image/");
            if (isImgUrl) {
              return (
                <figure key={idx} className="overflow-hidden rounded-2xl border bg-card shadow-soft">
                  <img src={trimmed} alt={article.title} loading="lazy" className="max-h-[480px] w-full object-cover" />
                </figure>
              );
            }
            return (
              <p key={idx} className="whitespace-pre-line rounded-2xl border bg-card/70 p-5 shadow-soft">{p}</p>
            );
          })}
        </div>

        {relatedPlants.length > 0 && (
          <section className="mt-10 rounded-3xl bg-mint/40 p-6">
            <h2 className="flex items-center gap-2 text-lg font-semibold"><Sprout className="size-5 text-leaf" /> Loài cây liên quan</h2>
            <div className="mt-4 grid gap-3 sm:grid-cols-2">
              {relatedPlants.map((p) => (
                <Link key={p.id} href={`/handbook?q=${encodeURIComponent(p.commonName)}`} className="flex items-center gap-3 rounded-2xl border bg-card p-3 transition-all hover:shadow-soft">
                  <img src={p.image} alt={p.commonName} className="size-14 rounded-xl object-cover" />
                  <div className="min-w-0">
                    <p className="truncate font-semibold">{p.commonName}</p>
                    <p className="truncate text-xs italic text-muted-foreground">{p.scientificName}</p>
                  </div>
                </Link>
              ))}
            </div>
          </section>
        )}
      </article>

      {relatedArticles.length > 0 && (
        <section className="mt-14 border-t pt-10">
          <h2 className="mb-5 text-xl font-semibold">Bài viết khác bạn có thể thích</h2>
          <div className="grid gap-5 md:grid-cols-3">
            {relatedArticles.map((a) => (
              <Link key={a.id} href={`/handbook/${a.slug}`} className="group overflow-hidden rounded-3xl border bg-card shadow-soft transition-all hover:shadow-card">
                <div className="aspect-[16/10] overflow-hidden"><img src={a.image} alt={a.title} className="size-full object-cover transition-transform duration-700 group-hover:scale-105" /></div>
                <div className="p-4">
                  <h3 className="line-clamp-2 font-semibold group-hover:text-leaf">{a.title}</h3>
                </div>
              </Link>
            ))}
          </div>
        </section>
      )}
    </PageContainer>
  );
}
