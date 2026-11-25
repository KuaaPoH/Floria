"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { ArrowRight, Minus, Plus, ShoppingBag, Trash2 } from "lucide-react";
import { PageContainer, PageHeader } from "@/components/layout/PageContainer";
import { EmptyState } from "@/components/layout/states";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { cartLines, selectedSubtotal, unitPrice } from "@/features/ecommerce/logic";
import { formatVND } from "@/lib/format";
import { useAuth } from "@/stores/auth";
import { useCart } from "@/stores/cart";
import { useProducts } from "@/hooks/queries";

export default function CartPage() {
  const router = useRouter();
  const authed = useAuth((s) => s.status === "authenticated");
  const { data: products = [] } = useProducts();
  const items = useCart((s) => s.items);
  const toggle = useCart((s) => s.toggle);
  const setAllSelected = useCart((s) => s.setAllSelected);
  const setQuantity = useCart((s) => s.setQuantity);
  const remove = useCart((s) => s.remove);
  const setCheckoutIds = useCart((s) => s.setCheckoutIds);

  const lines = cartLines(items, products);
  const selectedLines = lines.filter((l) => l.item.selected);
  const allSelected = lines.length > 0 && selectedLines.length === lines.length;
  const subtotal = selectedSubtotal(items, products);

  const proceedCheckout = () => {
    const ids = selectedLines.map((l) => l.item.productId);
    if (!ids.length) return;
    setCheckoutIds(ids);
    if (!authed) {
      router.push("/login?redirect=/checkout");
      return;
    }
    router.push("/checkout");
  };

  return (
    <PageContainer className="max-w-6xl">
      <PageHeader
        eyebrow="Mua sắm"
        title="Giỏ hàng của bạn"
        description="Chọn sản phẩm bạn muốn thanh toán. Các mặt hàng chưa chọn sẽ được giữ lại trong giỏ."
      />

      {lines.length === 0 ? (
        <EmptyState
          icon={<ShoppingBag />}
          title="Giỏ hàng đang trống"
          description="Khám phá phân bón, giá thể, dụng cụ và cây cảnh tuyển chọn tại cửa hàng Floria."
          action={<Button asChild size="lg"><Link href="/shop">Khám phá cửa hàng</Link></Button>}
        />
      ) : (
        <div className="grid gap-8 lg:grid-cols-[1.5fr_1fr] lg:items-start">
          <div className="space-y-3">
            <div className="flex items-center justify-between rounded-2xl border bg-card px-4 py-3 shadow-soft">
              <label className="flex cursor-pointer items-center gap-3 text-sm font-semibold">
                <Checkbox checked={allSelected} onCheckedChange={(c) => setAllSelected(c === true)} />
                Chọn tất cả ({lines.length} sản phẩm)
              </label>
              <span className="text-xs text-muted-foreground">Đã chọn {selectedLines.length}</span>
            </div>

            {lines.map(({ item, product, lineTotal }) => (
              <div key={item.productId} className="flex flex-col gap-4 rounded-3xl border bg-card p-4 shadow-soft sm:flex-row sm:items-center">
                <div className="flex items-center gap-3">
                  <Checkbox
                    checked={item.selected}
                    onCheckedChange={() => toggle(item.productId)}
                    aria-label={`Chọn ${product.name}`}
                  />
                  <Link href={`/products/${product.id}`} className="size-20 shrink-0 overflow-hidden rounded-2xl bg-mint">
                    <img src={product.images[0]} alt={product.name} className="size-full object-cover" />
                  </Link>
                </div>

                <div className="min-w-0 flex-1">
                  <Link href={`/products/${product.id}`} className="line-clamp-2 font-semibold hover:text-leaf">
                    {product.name}
                  </Link>
                  <p className="mt-1 text-sm text-muted-foreground">{formatVND(unitPrice(product))}</p>
                </div>

                <div className="flex items-center justify-between gap-4 sm:justify-end">
                  <div className="inline-flex items-center rounded-xl border bg-background p-0.5">
                    <Button variant="ghost" size="icon-sm" disabled={item.quantity <= 1} onClick={() => setQuantity(item.productId, item.quantity - 1)} aria-label="Giảm">
                      <Minus />
                    </Button>
                    <span className="w-8 text-center text-sm font-semibold">{item.quantity}</span>
                    <Button variant="ghost" size="icon-sm" disabled={item.quantity >= product.stock} onClick={() => setQuantity(item.productId, item.quantity + 1)} aria-label="Tăng">
                      <Plus />
                    </Button>
                  </div>
                  <p className="min-w-24 text-right font-bold text-forest dark:text-foreground">{formatVND(lineTotal)}</p>
                  <Button variant="ghost" size="icon-sm" className="text-muted-foreground hover:text-danger" onClick={() => remove(item.productId)} aria-label="Xóa sản phẩm">
                    <Trash2 />
                  </Button>
                </div>
              </div>
            ))}
          </div>

          <aside className="rounded-3xl border bg-card p-6 shadow-card lg:sticky lg:top-24">
            <h2 className="text-lg font-semibold">Tóm tắt đơn hàng</h2>
            <dl className="mt-5 space-y-3 text-sm">
              <div className="flex justify-between">
                <dt className="text-muted-foreground">Sản phẩm đã chọn</dt>
                <dd className="font-medium">{selectedLines.length} mặt hàng</dd>
              </div>
              <div className="flex justify-between border-t pt-3 text-base">
                <dt className="font-semibold">Tạm tính</dt>
                <dd className="text-xl font-bold text-forest dark:text-foreground">{formatVND(subtotal)}</dd>
              </div>
            </dl>
            <Button size="lg" className="mt-6 w-full" disabled={selectedLines.length === 0} onClick={proceedCheckout}>
              Tiến hành thanh toán <ArrowRight />
            </Button>
            <Button asChild variant="ghost" className="mt-2 w-full">
              <Link href="/shop">Tiếp tục mua sắm</Link>
            </Button>
          </aside>
        </div>
      )}
    </PageContainer>
  );
}
