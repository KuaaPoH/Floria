"use client";

import { useState } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { ArrowLeft, CheckCircle2, Minus, Plus, ShoppingBag, Sparkles, Star } from "lucide-react";
import { UserAvatar } from "@/components/botanical/BotanicalAvatar";
import { PageContainer } from "@/components/layout/PageContainer";
import { EmptyState, LoadingState } from "@/components/layout/states";
import { PriceTag, ProductCard, ProductRating, useAddToCart } from "@/components/products";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { useProduct, useProducts, useReviews } from "@/hooks/queries";
import { useLang } from "@/i18n";
import { formatDate } from "@/lib/format";
import { cn } from "@/lib/utils";
import { useCart } from "@/stores/cart";

export default function ProductDetailPage() {
  const { productId } = useParams<{ productId: string }>();
  const lang = useLang();
  const router = useRouter();
  const productQ = useProduct(productId);
  const reviewsQ = useReviews(productId);
  const allQ = useProducts();
  const addToCart = useAddToCart();
  const addDirect = useCart((s) => s.add);
  const setCheckoutIds = useCart((s) => s.setCheckoutIds);

  const [imgIdx, setImgIdx] = useState(0);
  const [qty, setQty] = useState(1);

  if (productQ.isLoading) return <LoadingState className="min-h-[60vh]" />;
  const product = productQ.data;
  if (!product) {
    return (
      <PageContainer>
        <EmptyState icon={<ShoppingBag />} title="Không tìm thấy sản phẩm" action={<Button asChild><Link href="/shop">Về cửa hàng</Link></Button>} />
      </PageContainer>
    );
  }

  const outOfStock = product.stock <= 0;
  const reviews = reviewsQ.data ?? [];
  const related = (allQ.data ?? []).filter((p) => p.id !== product.id && p.category === product.category).slice(0, 4);
  const mainImg = product.images[imgIdx] ?? product.images[0];

  const buyNow = () => {
    if (outOfStock) return;
    addDirect(product.id, qty);
    setCheckoutIds([product.id]);
    router.push("/checkout");
  };

  return (
    <PageContainer className="space-y-14">
      <div>
        <Button asChild variant="ghost" size="sm" className="mb-6"><Link href="/shop"><ArrowLeft /> Cửa hàng Floria</Link></Button>

        <div className="grid gap-10 lg:grid-cols-[1fr_1.1fr]">
          {/* Gallery */}
          <div className="space-y-3">
            <div className="relative aspect-square overflow-hidden rounded-[2rem] border bg-mint shadow-card">
              <img data-product-img={product.id} src={mainImg} alt={product.name} className="size-full object-cover" />
              {outOfStock && (
                <div className="absolute inset-0 grid place-items-center bg-background/60 backdrop-blur-[2px]">
                  <Badge variant="muted" className="text-base">Tạm hết hàng</Badge>
                </div>
              )}
            </div>
            {product.images.length > 1 && (
              <div className="flex gap-2.5 overflow-x-auto pb-1">
                {product.images.map((src, i) => (
                  <button
                    key={src + i}
                    onClick={() => setImgIdx(i)}
                    className={cn("size-20 shrink-0 overflow-hidden rounded-2xl border transition-all", i === imgIdx ? "border-leaf ring-2 ring-leaf/30" : "opacity-75 hover:opacity-100")}
                  >
                    <img src={src} alt="" className="size-full object-cover" />
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Info */}
          <div className="flex flex-col">
            <div className="flex flex-wrap gap-2">
              {product.tags.includes("bestseller") && <Badge variant="warning">Bán chạy</Badge>}
              {product.tags.includes("new") && <Badge variant="success">Mới</Badge>}
            </div>
            <h1 className="mt-3 text-3xl font-bold tracking-tight md:text-4xl">{product.name}</h1>
            <div className="mt-3 flex flex-wrap items-center gap-4 text-sm">
              <ProductRating rating={product.rating} count={reviews.length || product.reviewCount} />
              <span className="text-muted-foreground">Đã bán {product.sold.toLocaleString("vi-VN")}</span>
              <span className={cn("font-medium", outOfStock ? "text-danger" : "text-success")}>
                {outOfStock ? "Hết hàng" : `Còn ${product.stock} sản phẩm`}
              </span>
            </div>

            <div className="mt-5 rounded-2xl bg-mint/40 p-4">
              <PriceTag product={product} className="[&>span:first-child]:text-3xl" />
            </div>

            <p className="mt-5 text-base leading-relaxed text-muted-foreground">{product.shortDescription}</p>

            <div className="mt-4 flex flex-wrap gap-2">
              {product.benefits.map((b) => (
                <Badge key={b} variant="secondary" className="capitalize">{b}</Badge>
              ))}
            </div>

            <div className="mt-7 flex flex-wrap items-center gap-3">
              <div className="inline-flex items-center rounded-xl border bg-card p-1">
                <Button variant="ghost" size="icon-sm" disabled={outOfStock || qty <= 1} onClick={() => setQty((q) => Math.max(1, q - 1))} aria-label="Giảm"><Minus /></Button>
                <span className="w-10 text-center text-sm font-semibold">{qty}</span>
                <Button variant="ghost" size="icon-sm" disabled={outOfStock || qty >= product.stock} onClick={() => setQty((q) => Math.min(product.stock, q + 1))} aria-label="Tăng"><Plus /></Button>
              </div>
              <Button
                size="lg"
                variant="outline"
                disabled={outOfStock}
                onClick={() => {
                  const imgEl = document.querySelector<HTMLElement>(`[data-product-img="${product.id}"]`);
                  addToCart(product, qty, imgEl);
                }}
              >
                <ShoppingBag /> Thêm vào giỏ hàng
              </Button>
              <Button size="lg" disabled={outOfStock} onClick={buyNow}>
                <Sparkles /> Mua ngay
              </Button>
            </div>

            <div className="mt-8 grid gap-4 border-t pt-6">
              <div>
                <h2 className="text-sm font-semibold uppercase tracking-wider text-leaf">Mô tả chi tiết</h2>
                <p className="mt-1.5 text-sm leading-relaxed text-muted-foreground">{product.description}</p>
              </div>
              <div>
                <h2 className="text-sm font-semibold uppercase tracking-wider text-leaf">Thành phần / Chất liệu</h2>
                <p className="mt-1.5 text-sm leading-relaxed text-muted-foreground">{product.ingredients}</p>
              </div>
              <div>
                <h2 className="text-sm font-semibold uppercase tracking-wider text-leaf">Hướng dẫn sử dụng</h2>
                <ul className="mt-2 space-y-1.5 text-sm text-muted-foreground">
                  {product.usage.map((u) => (
                    <li key={u} className="flex items-start gap-2"><CheckCircle2 className="mt-0.5 size-4 shrink-0 text-leaf" /> {u}</li>
                  ))}
                </ul>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Reviews */}
      <section className="rounded-3xl border bg-card p-6 shadow-soft md:p-8">
        <div className="mb-6 flex flex-wrap items-center justify-between gap-4">
          <div>
            <h2 className="text-2xl font-bold">Đánh giá từ người trồng cây</h2>
            <p className="mt-1 text-sm text-muted-foreground">Chỉ khách hàng đã nhận đơn hàng mới có thể gửi đánh giá.</p>
          </div>
          <div className="flex items-center gap-2 rounded-2xl bg-mint/60 px-4 py-2">
            <Star className="size-5 fill-warning text-warning" />
            <span className="text-xl font-bold">{product.rating.toFixed(1)}</span>
            <span className="text-xs text-muted-foreground">({reviews.length} đánh giá)</span>
          </div>
        </div>

        {reviews.length === 0 ? (
          <EmptyState title="Chưa có đánh giá nào" description="Hãy là người đầu tiên chia sẻ trải nghiệm sử dụng sản phẩm này." />
        ) : (
          <div className="grid gap-4 md:grid-cols-2">
            {reviews.map((rv) => (
              <article key={rv.id} className="rounded-2xl border bg-background/60 p-4">
                <div className="flex items-center justify-between gap-3">
                  <div className="flex items-center gap-3">
                    <UserAvatar user={{ avatarUrl: rv.userAvatar, avatarId: "sprout", displayName: rv.userName }} className="size-9" />
                    <div>
                      <p className="text-sm font-semibold">{rv.userName}</p>
                      <p className="text-xs text-muted-foreground">{formatDate(rv.createdAt, lang)}</p>
                    </div>
                  </div>
                  <div className="flex">
                    {[1, 2, 3, 4, 5].map((i) => (
                      <Star key={i} className={cn("size-3.5", i <= rv.rating ? "fill-warning text-warning" : "text-border")} />
                    ))}
                  </div>
                </div>
                <p className="mt-3 text-sm leading-relaxed">{rv.content}</p>
                {rv.images.length > 0 && (
                  <div className="mt-3 flex gap-2">
                    {rv.images.map((src, i) => (
                      <img key={i} src={src} alt="Ảnh đánh giá" className="size-16 rounded-xl object-cover" />
                    ))}
                  </div>
                )}
                {rv.reply && (
                  <div className="mt-3 rounded-xl border border-leaf/20 bg-mint/40 p-3 text-xs">
                    <p className="font-semibold text-forest dark:text-foreground">Phản hồi từ Floria</p>
                    <p className="mt-1 leading-relaxed text-muted-foreground">{rv.reply}</p>
                  </div>
                )}
              </article>
            ))}
          </div>
        )}
      </section>

      {related.length > 0 && (
        <section>
          <h2 className="mb-5 text-2xl font-bold">Sản phẩm cùng danh mục</h2>
          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
            {related.map((p) => <ProductCard key={p.id} product={p} />)}
          </div>
        </section>
      )}
    </PageContainer>
  );
}
