"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { Flame, Search, ShoppingBag, Sparkles, Sprout } from "lucide-react";
import { PageContainer } from "@/components/layout/PageContainer";
import { CardGridSkeleton, EmptyState, ErrorState } from "@/components/layout/states";
import { ProductCard } from "@/components/products";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import { unitPrice } from "@/features/ecommerce/logic";
import { useProducts } from "@/hooks/queries";
import { cn } from "@/lib/utils";
import { IMG } from "@/mocks/user/images";
import type { ProductCategory } from "@/types/user";

const CATEGORIES: { value: "all" | ProductCategory; label: string }[] = [
  { value: "all", label: "Tất cả" },
  { value: "plants", label: "Cây cảnh" },
  { value: "soil", label: "Giá thể & Đất" },
  { value: "fertilizer", label: "Phân bón" },
  { value: "treatment", label: "Phòng trị bệnh" },
  { value: "pots", label: "Chậu gốm" },
  { value: "tools", label: "Dụng cụ" },
];

type PriceRange = "all" | "under150" | "150to350" | "over350";
type RatingFilter = "all" | "4.5" | "4.8";
type SortBy = "popular" | "newest" | "price_asc" | "price_desc" | "rating";

export default function ShopPage() {
  const productsQ = useProducts();
  const products = productsQ.data ?? [];

  const [q, setQ] = useState("");
  const [cat, setCat] = useState<"all" | ProductCategory>("all");
  const [priceRange, setPriceRange] = useState<PriceRange>("all");
  const [rating, setRating] = useState<RatingFilter>("all");
  const [inStockOnly, setInStockOnly] = useState(false);
  const [sort, setSort] = useState<SortBy>("popular");

  const filtered = useMemo(() => {
    const needle = q.trim().toLowerCase();
    return products
      .filter((p) => cat === "all" || p.category === cat)
      .filter((p) => {
        const price = unitPrice(p);
        if (priceRange === "under150") return price < 150_000;
        if (priceRange === "150to350") return price >= 150_000 && price <= 350_000;
        if (priceRange === "over350") return price > 350_000;
        return true;
      })
      .filter((p) => (rating === "all" ? true : p.rating >= Number(rating)))
      .filter((p) => (!inStockOnly ? true : p.stock > 0))
      .filter((p) => {
        if (!needle) return true;
        return [p.name, p.shortDescription, p.category, ...p.benefits].some((s) => s.toLowerCase().includes(needle));
      })
      .sort((a, b) => {
        if (sort === "newest") return b.createdAt.localeCompare(a.createdAt);
        if (sort === "price_asc") return unitPrice(a) - unitPrice(b);
        if (sort === "price_desc") return unitPrice(b) - unitPrice(a);
        if (sort === "rating") return b.rating - a.rating;
        return b.sold - a.sold;
      });
  }, [products, q, cat, priceRange, rating, inStockOnly, sort]);

  const hotProducts = useMemo(() => products.filter((p) => p.tags.includes("featured")), [products]);
  const [hotIdx, setHotIdx] = useState(0);
  useEffect(() => {
    if (hotProducts.length <= 1) return;
    const timer = setInterval(() => {
      setHotIdx((prev) => (prev + 1) % hotProducts.length);
    }, 10_000);
    return () => clearInterval(timer);
  }, [hotProducts.length]);
  const activeHot = hotProducts.length > 0 ? hotProducts[hotIdx % hotProducts.length] : null;

  const isDefaultView = !q && cat === "all" && priceRange === "all" && rating === "all" && !inStockOnly && sort === "popular";

  return (
    <PageContainer className="space-y-12">
      {/* Hero Banner */}
      <section className="relative overflow-hidden rounded-[2rem] bg-forest-gradient p-7 text-forest-foreground shadow-card md:p-12">
        <img
          key={activeHot?.id ?? "default"}
          src={activeHot?.images[0] || IMG.products.pots}
          alt={activeHot?.name ?? ""}
          className="absolute inset-y-0 right-0 hidden h-full w-1/2 object-cover opacity-45 transition-opacity duration-500 md:block"
        />
        <div className="absolute inset-0 bg-gradient-to-r from-forest via-forest/85 to-transparent" />
        <div className="relative max-w-xl">
          {activeHot ? (
            <>
              <Badge variant="glass" className="mb-3"><Flame className="size-3.5" /> Sản phẩm HOT</Badge>
              <h1 className="line-clamp-2 text-3xl font-bold leading-tight md:text-5xl">{activeHot.name}</h1>
              <p className="mt-3 line-clamp-2 text-sm text-forest-foreground/85 md:text-base">
                {activeHot.shortDescription || activeHot.description}
              </p>
              <div className="mt-4 flex items-baseline gap-2.5">
                <span className="text-2xl font-bold text-sage">{unitPrice(activeHot).toLocaleString("vi-VN")}₫</span>
                {activeHot.salePrice !== null && activeHot.salePrice < activeHot.price && (
                  <span className="text-sm text-forest-foreground/60 line-through">{activeHot.price.toLocaleString("vi-VN")}₫</span>
                )}
              </div>
              <div className="mt-6 flex flex-wrap items-center gap-2">
                <Button variant="cream" asChild><Link href={`/products/${activeHot.id}`}><Sparkles /> Xem sản phẩm</Link></Button>
                <Button variant="glass" asChild><Link href="/cart"><ShoppingBag /> Xem giỏ hàng</Link></Button>
              </div>
              {hotProducts.length > 1 && (
                <div className="mt-5 flex items-center gap-1.5">
                  {hotProducts.map((p, idx) => (
                    <button
                      key={p.id}
                      type="button"
                      aria-label={`Xem sản phẩm hot ${idx + 1}`}
                      onClick={() => setHotIdx(idx)}
                      className={cn(
                        "h-1.5 rounded-full transition-all",
                        idx === hotIdx % hotProducts.length ? "w-6 bg-sage" : "w-1.5 bg-forest-foreground/35 hover:bg-forest-foreground/60",
                      )}
                    />
                  ))}
                </div>
              )}
            </>
          ) : (
            <>
              <Badge variant="glass" className="mb-3"><Sprout /> Floria Botanical Store</Badge>
              <h1 className="text-3xl font-bold leading-tight md:text-5xl">Vật tư & cây cảnh tuyển chọn cho khu vườn khỏe mạnh</h1>
              <p className="mt-3 text-sm text-forest-foreground/80 md:text-base">
                Giá thể tơi xốp, phân hữu cơ, chế phẩm sinh học và dụng cụ chuẩn nhà vườn — đồng bộ cùng phác đồ chăm sóc của Floria.
              </p>
              <div className="mt-6 flex flex-wrap gap-2">
                <Button variant="cream" onClick={() => setCat("treatment")}><Sparkles /> Giải pháp trị bệnh lá</Button>
                <Button variant="glass" asChild><Link href="/cart"><ShoppingBag /> Xem giỏ hàng</Link></Button>
              </div>
            </>
          )}
        </div>
      </section>

      {/* Search & Filters */}
      <section className="space-y-4">
        <div className="scrollbar-none -mx-1 flex gap-2 overflow-x-auto px-1 pb-1">
          {CATEGORIES.map((c) => {
            const active = cat === c.value;
            return (
              <button
                key={c.value}
                onClick={() => setCat(c.value)}
                className={cn("shrink-0 rounded-full border px-4 py-2 text-sm font-medium transition-colors", active ? "border-forest bg-forest text-forest-foreground" : "bg-card hover:border-leaf/50")}
              >
                {c.label}
              </button>
            );
          })}
        </div>

        <div className="grid gap-3 rounded-3xl border bg-card p-4 shadow-soft md:grid-cols-[1.5fr_1fr_1fr_1fr_auto] md:items-center">
          <div className="relative">
            <Search className="absolute left-3.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
            <Input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Tìm theo tên, công dụng (đốm lá, kích rễ, thoát nước…)" className="pl-10" />
          </div>
          <Select value={priceRange} onValueChange={(v) => setPriceRange(v as PriceRange)}>
            <SelectTrigger className="h-11 rounded-[10px]"><SelectValue /></SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Mọi mức giá</SelectItem>
              <SelectItem value="under150">Dưới 150.000₫</SelectItem>
              <SelectItem value="150to350">150.000₫ – 350.000₫</SelectItem>
              <SelectItem value="over350">Trên 350.000₫</SelectItem>
            </SelectContent>
          </Select>
          <Select value={rating} onValueChange={(v) => setRating(v as RatingFilter)}>
            <SelectTrigger className="h-11 rounded-[10px]"><SelectValue /></SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Mọi đánh giá</SelectItem>
              <SelectItem value="4.5">Từ 4.5 ★ trở lên</SelectItem>
              <SelectItem value="4.8">Từ 4.8 ★ trở lên</SelectItem>
            </SelectContent>
          </Select>
          <Select value={sort} onValueChange={(v) => setSort(v as SortBy)}>
            <SelectTrigger className="h-11 rounded-[10px]"><SelectValue /></SelectTrigger>
            <SelectContent>
              <SelectItem value="popular">Bán chạy nhất</SelectItem>
              <SelectItem value="newest">Mới nhất</SelectItem>
              <SelectItem value="price_asc">Giá tăng dần</SelectItem>
              <SelectItem value="price_desc">Giá giảm dần</SelectItem>
              <SelectItem value="rating">Đánh giá cao</SelectItem>
            </SelectContent>
          </Select>
          <label className="flex cursor-pointer items-center gap-2 whitespace-nowrap px-1 text-sm font-medium">
            <Switch checked={inStockOnly} onCheckedChange={setInStockOnly} />
            Còn hàng
          </label>
        </div>
      </section>

      {/* Full / Filtered Catalogue */}
      <section>
        <div className="mb-5 flex items-center justify-between">
          <h2 className="text-2xl font-bold">{isDefaultView ? "Tất cả sản phẩm" : `Kết quả (${filtered.length})`}</h2>
          {!isDefaultView && (
            <Button variant="ghost" size="sm" onClick={() => { setQ(""); setCat("all"); setPriceRange("all"); setRating("all"); setInStockOnly(false); setSort("popular"); }}>
              Đặt lại bộ lọc
            </Button>
          )}
        </div>
        {productsQ.isError ? (
          <ErrorState onRetry={() => productsQ.refetch()} />
        ) : productsQ.isLoading ? (
          <CardGridSkeleton count={8} className="lg:grid-cols-4" />
        ) : filtered.length === 0 ? (
          <EmptyState icon={<ShoppingBag />} title="Không tìm thấy sản phẩm phù hợp" description="Thử bỏ bớt điều kiện lọc hoặc tìm theo công dụng khác." action={<Button variant="outline" onClick={() => { setQ(""); setCat("all"); setPriceRange("all"); setRating("all"); setInStockOnly(false); }}>Xem tất cả sản phẩm</Button>} />
        ) : (
          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
            {filtered.map((p) => <ProductCard key={p.id} product={p} />)}
          </div>
        )}
      </section>
    </PageContainer>
  );
}
