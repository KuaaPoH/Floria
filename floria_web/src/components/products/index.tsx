"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { ShoppingBag, Star } from "lucide-react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { unitPrice } from "@/features/ecommerce/logic";
import { useT } from "@/i18n";
import { common } from "@/i18n/common";
import { formatVND } from "@/lib/format";
import { cn } from "@/lib/utils";
import { useCart } from "@/stores/cart";
import type { ShopProduct } from "@/types/user";

/** Fly-to-Cart: clones the product image and animates it into the header cart icon. */
export function flyToCart(sourceEl: HTMLElement | null) {
  const target = document.getElementById("floria-cart-anchor");
  if (!sourceEl || !target || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
  const from = sourceEl.getBoundingClientRect();
  const to = target.getBoundingClientRect();
  const ghost = sourceEl.cloneNode(true) as HTMLElement;
  Object.assign(ghost.style, {
    position: "fixed", left: `${from.left}px`, top: `${from.top}px`, width: `${from.width}px`, height: `${from.height}px`,
    borderRadius: "20px", zIndex: "100", pointerEvents: "none", objectFit: "cover", transition: "all 700ms cubic-bezier(.6,-0.1,.3,1)", opacity: "0.95",
  });
  document.body.appendChild(ghost);
  requestAnimationFrame(() => {
    Object.assign(ghost.style, { left: `${to.left + to.width / 2 - 12}px`, top: `${to.top + to.height / 2 - 12}px`, width: "24px", height: "24px", opacity: "0.3", borderRadius: "999px" });
  });
  setTimeout(() => {
    ghost.remove();
    target.animate([{ transform: "scale(1)" }, { transform: "scale(1.25)" }, { transform: "scale(1)" }], { duration: 350 });
  }, 720);
}

export function useAddToCart() {
  const add = useCart((s) => s.add);
  const t = useT(common);
  const router = useRouter();
  return (product: ShopProduct, quantity = 1, imgEl?: HTMLElement | null) => {
    if (product.stock <= 0) return;
    add(product.id, quantity);
    flyToCart(imgEl ?? null);
    toast.success(t("addedToCart"), { description: product.name, action: { label: t("cart"), onClick: () => router.push("/cart") } });
  };
}

export function ProductRating({ rating, count, className }: { rating: number; count?: number; className?: string }) {
  return (
    <span className={cn("inline-flex items-center gap-1 text-xs text-muted-foreground", className)}>
      <span className="flex">
        {[1, 2, 3, 4, 5].map((i) => (
          <Star key={i} className={cn("size-3.5", i <= Math.round(rating) ? "fill-warning text-warning" : "text-border")} />
        ))}
      </span>
      <span className="font-semibold text-foreground">{rating.toFixed(1)}</span>
      {count !== undefined && <span>({count})</span>}
    </span>
  );
}

export function PriceTag({ product, className }: { product: Pick<ShopProduct, "price" | "salePrice">; className?: string }) {
  return (
    <div className={cn("flex items-baseline gap-2", className)}>
      <span className="text-lg font-bold text-forest dark:text-foreground">{formatVND(unitPrice(product))}</span>
      {product.salePrice !== null && <span className="text-sm text-muted-foreground line-through">{formatVND(product.price)}</span>}
    </div>
  );
}

export function ProductCard({ product, className }: { product: ShopProduct; className?: string }) {
  const addToCart = useAddToCart();
  const outOfStock = product.stock <= 0;
  const discount = product.salePrice ? Math.round((1 - product.salePrice / product.price) * 100) : 0;
  return (
    <div className={cn("group flex flex-col overflow-hidden rounded-3xl border bg-card shadow-soft transition-all duration-300 hover:-translate-y-1 hover:shadow-card", className)}>
      <Link href={`/products/${product.id}`} className="relative block aspect-square overflow-hidden bg-mint">
        <img data-product-img={product.id} src={product.images[0]} alt={product.name} loading="lazy" className="size-full object-cover transition-transform duration-700 group-hover:scale-105" />
        <div className="absolute left-3 top-3 flex flex-col gap-1">
          {discount > 0 && <Badge variant="danger">-{discount}%</Badge>}
          {product.tags.includes("new") && <Badge variant="success">Mới</Badge>}
        </div>
        {outOfStock && (
          <div className="absolute inset-0 grid place-items-center bg-background/60 backdrop-blur-[2px]">
            <Badge variant="muted" className="text-sm">Hết hàng</Badge>
          </div>
        )}
      </Link>
      <div className="flex flex-1 flex-col gap-2 p-4">
        <Link href={`/products/${product.id}`} className="line-clamp-2 min-h-[2.75rem] font-semibold leading-snug hover:text-leaf">
          {product.name}
        </Link>
        <div className="flex items-center justify-between">
          <ProductRating rating={product.rating} />
          <span className="text-xs text-muted-foreground">Đã bán {product.sold.toLocaleString("vi-VN")}</span>
        </div>
        <div className="mt-auto flex items-end justify-between gap-2 pt-1">
          <PriceTag product={product} />
          <Button
            size="icon"
            className="shrink-0 rounded-full"
            disabled={outOfStock}
            aria-label="Thêm vào giỏ hàng"
            onClick={(e) => {
              const img = (e.currentTarget.closest(".group") as HTMLElement)?.querySelector<HTMLElement>(`[data-product-img="${product.id}"]`);
              addToCart(product, 1, img);
            }}
          >
            <ShoppingBag />
          </Button>
        </div>
        <p className={cn("text-xs", outOfStock ? "text-danger" : product.stock < 10 ? "text-warning" : "text-muted-foreground")}>
          {outOfStock ? "Tạm hết hàng" : product.stock < 10 ? `Chỉ còn ${product.stock} sản phẩm` : "Còn hàng"}
        </p>
      </div>
    </div>
  );
}
