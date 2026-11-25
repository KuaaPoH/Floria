"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { CheckCircle2, CreditCard, ImagePlus, Loader2, Package, RotateCw, Star, X, XCircle } from "lucide-react";
import { toast } from "sonner";
import { ConfirmDialog } from "@/components/layout/ConfirmDialog";
import { PageContainer, PageHeader } from "@/components/layout/PageContainer";
import { CardGridSkeleton, EmptyState, ErrorState } from "@/components/layout/states";
import { ZaloPayGatewayDialog, type ZaloPaySessionInfo } from "@/components/products/ZaloPayGatewayDialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Textarea } from "@/components/ui/textarea";
import { orderActions } from "@/features/ecommerce/logic";
import { useOrderMutations, useOrders } from "@/hooks/queries";
import { useLang, useT } from "@/i18n";
import { common } from "@/i18n/common";
import { ORDER_STATUS_LABEL } from "@/i18n/labels";
import { formatDateTime, formatVND } from "@/lib/format";
import { cn } from "@/lib/utils";
import { commerceService } from "@/services/commerce.service";
import { uploadService } from "@/services/upload.service";
import { useCart } from "@/stores/cart";
import type { Order, OrderItem, OrderStatus } from "@/types/user";

const ORDER_TABS: OrderStatus[] = ["pending", "processing", "shipping", "delivered", "cancelled"];

const STATUS_BADGE: Record<OrderStatus, "warning" | "info" | "success" | "danger" | "brand"> = {
  pending: "warning",
  processing: "info",
  shipping: "brand",
  delivered: "success",
  cancelled: "danger",
};

export default function OrdersPage() {
  const t = useT(common);
  const lang = useLang();
  const router = useRouter();
  const ordersQ = useOrders();
  const { cancel, receive, review } = useOrderMutations();
  const addToCart = useCart((s) => s.add);

  const [tab, setTab] = useState<OrderStatus>("pending");

  useEffect(() => {
    if (typeof window === "undefined") return;
    const params = new URLSearchParams(window.location.search);
    const tParam = params.get("tab") as OrderStatus | null;
    if (tParam && ORDER_TABS.includes(tParam)) {
      setTab(tParam);
    }

    // Xử lý khi cổng ZaloPay redirect trực tiếp về /orders?status=1&apptransid=...
    const zpStatus = params.get("status");
    const zpTransId = params.get("apptransid") ?? params.get("app_trans_id");
    const zpOrderId = params.get("orderId") ?? "";
    if (zpTransId && zpStatus === "1") {
      void (async () => {
        try {
          const res = await commerceService.queryZaloPayPayment(zpTransId, zpOrderId);
          if (res.return_code === 1) {
            toast.success("Thanh toán ZaloPay thành công! Đơn hàng đã chuyển sang Đang giao.");
            setTab("shipping");
            await ordersQ.refetch();
          }
        } catch {
          // ignore
        } finally {
          window.history.replaceState({}, "", "/orders?tab=shipping");
        }
      })();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);
  const [cancelling, setCancelling] = useState<Order | null>(null);
  const [reviewTarget, setReviewTarget] = useState<{ order: Order; item: OrderItem } | null>(null);
  const [rating, setRating] = useState(5);
  const [content, setContent] = useState("");
  const [images, setImages] = useState<string[]>([]);
  const [uploading, setUploading] = useState(false);
  const [zaloSession, setZaloSession] = useState<ZaloPaySessionInfo | null>(null);
  const [payingOrderId, setPayingOrderId] = useState<string | null>(null);
  const fileRef = useRef<HTMLInputElement>(null);

  const openZaloPay = async (o: Order) => {
    setPayingOrderId(o.id);
    try {
      const zp = await commerceService.createZaloPayPayment(o.id);
      window.open(zp.order_url, "_blank", "noopener,noreferrer");
      setZaloSession({
        orderId: o.id,
        orderCode: o.code,
        amount: o.total,
        orderUrl: zp.order_url,
        appTransId: zp.app_trans_id,
      });
    } catch (e) {
      toast.error((e as Error).message || "Không thể mở cổng ZaloPay.");
    } finally {
      setPayingOrderId(null);
    }
  };

  const orders = ordersQ.data ?? [];
  const filtered = orders.filter((o) => o.status === tab);

  const openReview = (order: Order) => {
    const firstUnreviewed = order.items.find((i) => !i.reviewed);
    if (!firstUnreviewed) return;
    setRating(5);
    setContent("");
    setImages([]);
    setReviewTarget({ order, item: firstUnreviewed });
  };

  const rebuy = (order: Order) => {
    order.items.forEach((it) => addToCart(it.productId, it.quantity));
    toast.success("Đã thêm lại sản phẩm vào giỏ hàng");
    router.push("/cart");
  };

  return (
    <PageContainer className="max-w-5xl">
      <PageHeader
        eyebrow="Đơn hàng"
        title="Lịch sử đơn hàng"
        description="Theo dõi tiến trình xử lý, xác nhận nhận hàng và đánh giá sản phẩm đã mua."
      />

      <Tabs value={tab} onValueChange={(v) => setTab(v as OrderStatus)} className="mb-6">
        <TabsList className="scrollbar-none h-auto w-full justify-start overflow-x-auto rounded-2xl bg-mint/60 p-1">
          {ORDER_TABS.map((s) => {
            const count = orders.filter((o) => o.status === s).length;
            return (
              <TabsTrigger key={s} value={s} className="rounded-xl px-4 py-2 data-[state=active]:bg-card data-[state=active]:shadow-soft">
                {t(ORDER_STATUS_LABEL[s])}
                {count > 0 && <span className="ml-1.5 rounded-full bg-mint px-1.5 text-[11px] font-bold text-forest">{count}</span>}
              </TabsTrigger>
            );
          })}
        </TabsList>
      </Tabs>

      {ordersQ.isError ? (
        <ErrorState onRetry={() => ordersQ.refetch()} />
      ) : ordersQ.isLoading ? (
        <CardGridSkeleton count={3} className="lg:grid-cols-1" />
      ) : filtered.length === 0 ? (
        <EmptyState
          icon={<Package />}
          title={`Không có đơn hàng "${t(ORDER_STATUS_LABEL[tab])}"`}
          description="Khám phá thêm dụng cụ và cây cảnh tại cửa hàng Floria."
          action={<Button asChild variant="outline"><Link href="/shop">Đi tới cửa hàng</Link></Button>}
        />
      ) : (
        <div className="space-y-5">
          {filtered.map((o) => {
            const act = orderActions(o);
            return (
              <article key={o.id} className="overflow-hidden rounded-3xl border bg-card shadow-soft">
                {/* Header */}
                <div className="flex flex-wrap items-center justify-between gap-3 border-b bg-muted/30 px-5 py-3.5 text-sm">
                  <div className="flex flex-wrap items-center gap-3">
                    <span className="font-mono font-bold">{o.code}</span>
                    <span className="text-xs text-muted-foreground">{formatDateTime(o.createdAt, lang)}</span>
                    <Badge variant="outline">{o.paymentMethod === "zalopay" ? "ZaloPay" : "COD"}</Badge>
                    {o.paymentStatus === "paid" && <Badge variant="success">Đã thanh toán</Badge>}
                  </div>
                  <Badge variant={STATUS_BADGE[o.status]}>{t(ORDER_STATUS_LABEL[o.status])}</Badge>
                </div>

                {/* Items */}
                <ul className="divide-y px-5">
                  {o.items.map((it) => (
                    <li key={it.productId} className="flex items-center gap-4 py-4">
                      <Link href={`/products/${it.productId}`} className="size-16 shrink-0 overflow-hidden rounded-2xl bg-mint">
                        <img src={it.image} alt={it.name} className="size-full object-cover" />
                      </Link>
                      <div className="min-w-0 flex-1">
                        <Link href={`/products/${it.productId}`} className="font-semibold hover:text-leaf">{it.name}</Link>
                        <p className="mt-0.5 text-xs text-muted-foreground">
                          {formatVND(it.unitPrice)} × {it.quantity}
                          {it.reviewed && <span className="ml-2 font-semibold text-success">· Đã đánh giá</span>}
                        </p>
                      </div>
                      <p className="font-semibold">{formatVND(it.unitPrice * it.quantity)}</p>
                    </li>
                  ))}
                </ul>

                {/* Row 1: Payment Summary (separated cleanly from actions) */}
                <div className="flex flex-wrap items-center justify-between gap-2 border-t bg-mint/25 px-5 py-3 text-sm">
                  <span className="text-muted-foreground">
                    Giao tới: {o.addressSnapshot.recipientName} · {o.addressSnapshot.wardName}, {o.addressSnapshot.provinceName}
                  </span>
                  <div className="flex items-baseline gap-2">
                    <span className="text-muted-foreground">Tổng thanh toán:</span>
                    <span className="text-lg font-bold text-forest dark:text-foreground">{formatVND(o.total)}</span>
                  </div>
                </div>

                {/* Row 2: Valid Action Buttons */}
                {(act.cancel || act.receive || act.rebuy || act.review || (o.paymentMethod === "zalopay" && o.status === "pending" && o.paymentStatus !== "paid")) && (
                  <div className="flex flex-wrap justify-end gap-2 border-t px-5 py-3">
                    {o.paymentMethod === "zalopay" && o.status === "pending" && o.paymentStatus !== "paid" && (
                      <Button size="sm" disabled={payingOrderId === o.id} onClick={() => void openZaloPay(o)}>
                        {payingOrderId === o.id ? <Loader2 className="animate-spin" /> : <CreditCard />} Thanh toán ZaloPay
                      </Button>
                    )}
                    {act.cancel && (
                      <Button variant="danger-soft" size="sm" onClick={() => setCancelling(o)}>
                        <XCircle /> Hủy đơn
                      </Button>
                    )}
                    {act.receive && (
                      <Button
                        size="sm"
                        disabled={receive.isPending}
                        onClick={() =>
                          receive.mutate(o.id, {
                            onSuccess: () => toast.success(`Đơn #${o.code} đã hoàn tất! Bạn có thể đánh giá ngay.`),
                          })
                        }
                      >
                        <CheckCircle2 /> Nhận hàng
                      </Button>
                    )}
                    {act.review && (
                      <Button size="sm" variant="outline" onClick={() => openReview(o)}>
                        <Star /> Đánh giá sản phẩm
                      </Button>
                    )}
                    {act.rebuy && (
                      <Button size="sm" variant="secondary" onClick={() => rebuy(o)}>
                        <RotateCw /> Mua lại
                      </Button>
                    )}
                  </div>
                )}
              </article>
            );
          })}
        </div>
      )}

      <ConfirmDialog
        open={!!cancelling}
        onOpenChange={(o) => !o && setCancelling(null)}
        destructive
        loading={cancel.isPending}
        title={`Hủy đơn hàng ${cancelling?.code}?`}
        description="Đơn hàng sẽ chuyển sang trạng thái Đã hủy và không thể khôi phục."
        confirmLabel="Xác nhận hủy đơn"
        onConfirm={async () => {
          await cancel.mutateAsync(cancelling!.id);
          setCancelling(null);
          toast.success("Đã hủy đơn hàng");
        }}
      />

      <Dialog open={!!reviewTarget} onOpenChange={(o) => !o && setReviewTarget(null)}>
        <DialogContent className="rounded-3xl sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>Đánh giá sản phẩm</DialogTitle>
          </DialogHeader>
          {reviewTarget && (
            <div className="space-y-4">
              {reviewTarget.order.items.filter((i) => !i.reviewed).length > 1 && (
                <div className="flex flex-wrap gap-2">
                  {reviewTarget.order.items.filter((i) => !i.reviewed).map((it) => (
                    <button
                      key={it.productId}
                      type="button"
                      onClick={() => setReviewTarget({ ...reviewTarget, item: it })}
                      className={cn("rounded-full border px-3 py-1 text-xs font-medium", reviewTarget.item.productId === it.productId ? "border-forest bg-forest text-forest-foreground" : "bg-card")}
                    >
                      {it.name}
                    </button>
                  ))}
                </div>
              )}

              <div className="flex items-center gap-3 rounded-2xl bg-mint/40 p-3">
                <img src={reviewTarget.item.image} alt="" className="size-12 rounded-xl object-cover" />
                <p className="font-semibold">{reviewTarget.item.name}</p>
              </div>

              <div>
                <p className="mb-2 text-sm font-semibold">Mức độ hài lòng</p>
                <div className="flex gap-1.5">
                  {[1, 2, 3, 4, 5].map((s) => (
                    <button key={s} type="button" onClick={() => setRating(s)} className="p-1" aria-label={`${s} sao`}>
                      <Star className={cn("size-7 transition-colors", s <= rating ? "fill-warning text-warning" : "text-border")} />
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <p className="mb-1.5 text-sm font-semibold">Nhận xét</p>
                <Textarea value={content} onChange={(e) => setContent(e.target.value)} rows={3} maxLength={600} placeholder="Chất lượng sản phẩm, đóng gói, hiệu quả với cây của bạn…" />
              </div>

              <div>
                <input
                  ref={fileRef}
                  type="file"
                  accept="image/*"
                  multiple
                  className="hidden"
                  onChange={async (e) => {
                    const files = Array.from(e.target.files ?? []).slice(0, 4 - images.length);
                    if (!files.length) return;
                    setUploading(true);
                    try {
                      setImages([...images, ...(await uploadService.uploadMany(files, "reviews"))]);
                    } catch {
                      toast.error("Tải ảnh thất bại");
                    } finally {
                      setUploading(false);
                      e.target.value = "";
                    }
                  }}
                />
                <div className="flex flex-wrap items-center gap-2">
                  {images.map((src, i) => (
                    <div key={i} className="relative">
                      <img src={src} alt="" className="size-16 rounded-xl object-cover" />
                      <button type="button" onClick={() => setImages(images.filter((_, j) => j !== i))} className="absolute -right-1.5 -top-1.5 grid size-5 place-items-center rounded-full bg-forest text-forest-foreground"><X className="size-3" /></button>
                    </div>
                  ))}
                  <Button type="button" variant="outline" size="sm" disabled={uploading || images.length >= 4} onClick={() => fileRef.current?.click()}>
                    {uploading ? <Loader2 className="animate-spin" /> : <ImagePlus />} Thêm ảnh ({images.length}/4)
                  </Button>
                </div>
              </div>
            </div>
          )}
          <DialogFooter>
            <Button variant="ghost" onClick={() => setReviewTarget(null)}>Hủy</Button>
            <Button
              disabled={!content.trim() || review.isPending || uploading}
              onClick={async () => {
                await review.mutateAsync({
                  productId: reviewTarget!.item.productId,
                  orderId: reviewTarget!.order.id,
                  rating,
                  content: content.trim(),
                  images,
                });
                toast.success("Cảm ơn bạn đã gửi đánh giá!");
                setReviewTarget(null);
              }}
            >
              {review.isPending && <Loader2 className="animate-spin" />} Gửi đánh giá
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <ZaloPayGatewayDialog
        session={zaloSession}
        onClose={() => setZaloSession(null)}
        onPaid={() => {
          setZaloSession(null);
          void ordersQ.refetch();
        }}
      />
    </PageContainer>
  );
}
