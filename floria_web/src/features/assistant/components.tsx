"use client";

import type * as React from "react";
import { Fragment, useState } from "react";
import Link from "next/link";
import { AlertCircle, CalendarPlus, Check, Clock, Loader2, RotateCw, ShoppingBag } from "lucide-react";
import { toast } from "sonner";
import { UserAvatar } from "@/components/botanical/BotanicalAvatar";
import { CARE_ICON, CARE_TONE } from "@/components/botanical";
import { PriceTag, useAddToCart } from "@/components/products";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { usePlants, useProducts, useScheduleMutations } from "@/hooks/queries";
import { useLang, useT } from "@/i18n";
import { common } from "@/i18n/common";
import { CARE_LABEL } from "@/i18n/labels";
import { formatTime } from "@/lib/format";
import { cn } from "@/lib/utils";
import { findProduct } from "@/mocks/user/shop";
import { useAuth } from "@/stores/auth";
import type { CareScheduleSuggestion, ChatMessage, ProductSuggestion } from "@/types/user";
import { parseAssistantContent } from "./parser";

function inline(text: string): React.ReactNode[] {
  const cleaned = text.replace(/^#{1,6}\s+/, "");
  return cleaned
    .split(/(\*\*[^*]+\*\*)/g)
    .map((part, i) =>
      part.startsWith("**") && part.endsWith("**") ? (
        <strong key={i}>{part.slice(2, -2)}</strong>
      ) : (
        <Fragment key={i}>{part.replaceAll("**", "")}</Fragment>
      ),
    );
}

/** Minimal markdown: headings (without #), paragraphs, bullet and numbered lists, bold. */
export function RichText({ text }: { text: string }) {
  const lines = text.split("\n");
  const out: React.ReactNode[] = [];
  let list: { ordered: boolean; items: string[] } | null = null;
  const flush = () => {
    if (!list) return;
    const L = list.ordered ? "ol" : "ul";
    out.push(<L key={out.length} className={cn("my-2 space-y-1 pl-5", list.ordered ? "list-decimal" : "list-disc")}>{list.items.map((it, i) => <li key={i}>{inline(it)}</li>)}</L>);
    list = null;
  };
  for (const line of lines) {
    const heading = line.match(/^\s*#{1,6}\s+(.*)/);
    const ul = line.match(/^\s*[-*•]\s+(.*)/);
    const ol = line.match(/^\s*\d+\.\s+(.*)/);
    if (heading) {
      flush();
      out.push(<p key={out.length} className="mt-3 mb-1 font-semibold text-foreground">{inline(heading[1])}</p>);
    } else if (ul || ol) {
      const ordered = !!ol;
      if (!list || list.ordered !== ordered) {
        flush();
        list = { ordered, items: [] };
      }
      list.items.push((ul ?? ol)![1]);
    } else {
      flush();
      if (line.trim()) out.push(<p key={out.length} className="my-1.5">{inline(line)}</p>);
    }
  }
  flush();
  return <div className="text-sm leading-relaxed">{out}</div>;
}

export function AssistantAvatar({ className }: { className?: string }) {
  return (
    <img
      src="/mascot_avatar_chatbot.png"
      alt="Trợ lý Floria"
      className={cn("size-8 shrink-0 rounded-full object-cover shadow-soft", className)}
    />
  );
}

export function AssistantTypingIndicator() {
  return (
    <div className="flex items-end gap-3">
      <AssistantAvatar className="size-8" />
      <div className="flex gap-1 rounded-2xl rounded-bl-md bg-card px-4 py-3 shadow-soft">
        {[0, 1, 2].map((i) => <span key={i} className="animate-typing-dot size-2 rounded-full bg-leaf" style={{ animationDelay: `${i * 0.15}s` }} />)}
      </div>
    </div>
  );
}

export function AssistantCareScheduleCard({ data }: { data: CareScheduleSuggestion }) {
  const t = useT(common);
  const { data: plants = [] } = usePlants();
  const { apply } = useScheduleMutations();
  const candidates = plants.filter((p) => !data.speciesId || p.speciesId === data.speciesId);
  const list = candidates.length ? candidates : plants;
  const guess = list.find((p) => p.nickname.toLowerCase() === data.plantName.toLowerCase()) ?? (candidates.length === 1 ? candidates[0] : undefined);
  const [plantId, setPlantId] = useState(guess?.id ?? "");
  const [done, setDone] = useState(false);
  const Icon = CARE_ICON[data.careType];
  return (
    <div className="my-2 overflow-hidden rounded-2xl border border-leaf/25 bg-mint/40">
      <div className="flex items-center gap-3 border-b border-leaf/15 bg-card/60 px-4 py-3">
        <span className={cn("grid size-9 place-items-center rounded-xl", CARE_TONE[data.careType])}><Icon className="size-4" /></span>
        <div className="min-w-0">
          <p className="text-xs font-semibold uppercase tracking-wider text-leaf">Đề xuất lịch chăm sóc</p>
          <p className="truncate font-semibold">{data.plantName}</p>
        </div>
      </div>
      <dl className="grid grid-cols-3 gap-3 px-4 py-3 text-sm">
        <div><dt className="text-xs text-muted-foreground">Loại</dt><dd className="font-medium">{t(CARE_LABEL[data.careType])}</dd></div>
        <div><dt className="text-xs text-muted-foreground">Chu kỳ</dt><dd className="font-medium">{t("everyNDays", { n: data.intervalDays })}</dd></div>
        <div><dt className="text-xs text-muted-foreground">Thời gian</dt><dd className="flex items-center gap-1 font-medium"><Clock className="size-3" />{data.preferredTime}</dd></div>
      </dl>
      {data.reason && <p className="px-4 pb-3 text-xs text-muted-foreground">Lý do: {data.reason}</p>}
      <div className="flex flex-wrap items-center gap-2 border-t border-leaf/15 bg-card/60 px-4 py-3">
        {plants.length === 0 ? (
          <p className="text-xs text-muted-foreground">Thêm cây vào vườn để áp dụng lịch này.</p>
        ) : done ? (
          <span className="inline-flex items-center gap-1.5 text-sm font-semibold text-success"><Check className="size-4" /> Đã áp dụng</span>
        ) : (
          <>
            <Select value={plantId} onValueChange={setPlantId}>
              <SelectTrigger className="h-9 min-w-40 flex-1 rounded-[9px] bg-card text-sm"><SelectValue placeholder="Chọn cây" /></SelectTrigger>
              <SelectContent>{list.map((p) => <SelectItem key={p.id} value={p.id}>{p.nickname}</SelectItem>)}</SelectContent>
            </Select>
            <Button size="sm" disabled={!plantId || apply.isPending} onClick={() => apply.mutate({ plantId, suggestion: data }, {
              onSuccess: () => { setDone(true); toast.success("Đã cập nhật lịch chăm sóc"); },
              onError: (e) => toast.error(`Không thể áp dụng: ${(e as Error).message}`),
            })}>
              {apply.isPending ? <Loader2 className="animate-spin" /> : <CalendarPlus />} Áp dụng vào cây
            </Button>
          </>
        )}
      </div>
    </div>
  );
}

export function AssistantProductCard({ data }: { data: ProductSuggestion }) {
  const { data: liveProducts = [] } = useProducts();
  const product = liveProducts.find((p) => p.id === data.productId || p.slug === data.productId) ?? findProduct(data.productId);
  const add = useAddToCart();
  if (!product) return null;
  return (
    <div className="my-2 flex gap-3 rounded-2xl border bg-card p-3">
      <img src={product.images[0]} alt="" className="size-20 shrink-0 rounded-xl object-cover" />
      <div className="flex min-w-0 flex-1 flex-col">
        <p className="text-[11px] font-semibold uppercase tracking-wider text-leaf">Sản phẩm gợi ý</p>
        <p className="line-clamp-1 font-semibold">{product.name}</p>
        <p className="line-clamp-2 text-xs text-muted-foreground">{data.reason ?? product.shortDescription}</p>
        <div className="mt-auto flex flex-wrap items-center justify-between gap-2 pt-1.5">
          <PriceTag product={product} className="[&>span:first-child]:text-base" />
          <div className="flex gap-1.5">
            <Button asChild size="sm" variant="outline"><Link href={`/products/${product.id}`}>Xem</Link></Button>
            <Button size="sm" disabled={product.stock <= 0} onClick={() => add(product, 1)}><ShoppingBag /> {product.stock <= 0 ? "Hết hàng" : "Thêm"}</Button>
          </div>
        </div>
      </div>
    </div>
  );
}

export function AIChatMessage({ message, onRetry }: { message: ChatMessage & { pending?: boolean }; onRetry?: () => void }) {
  const lang = useLang();
  const user = useAuth((s) => s.user);
  const mine = message.role === "user";
  const blocks = mine ? [{ kind: "text" as const, text: message.content }] : parseAssistantContent(message.content);
  return (
    <div className={cn("flex items-end gap-3", mine && "flex-row-reverse")}>
      {mine ? <UserAvatar user={user} className="size-8" /> : <AssistantAvatar className="size-8" />}
      <div className={cn("flex max-w-[85%] flex-col gap-1 md:max-w-[75%]", mine && "items-end")}>
        {message.images.length > 0 && (
          <div className="flex flex-wrap gap-2">{message.images.map((src, i) => <img key={i} src={src} alt="Ảnh đính kèm" className="size-32 rounded-2xl object-cover" />)}</div>
        )}
        {(message.content || !mine) && (
          <div className={cn("rounded-2xl px-4 py-2.5 shadow-soft", mine ? "rounded-br-md bg-forest text-forest-foreground" : "rounded-bl-md bg-card")}>
            {blocks.map((b, i) =>
              b.kind === "text" ? (mine ? <p key={i} className="whitespace-pre-wrap text-sm">{b.text}</p> : <RichText key={i} text={b.text} />) : b.kind === "care_schedule" ? <AssistantCareScheduleCard key={i} data={b.data} /> : <AssistantProductCard key={i} data={b.data} />,
            )}
          </div>
        )}
        <div className="flex items-center gap-2 px-1 text-[11px] text-muted-foreground">
          {formatTime(message.createdAt, lang)}
          {message.status === "error" && (
            <span className="inline-flex items-center gap-1 text-danger"><AlertCircle className="size-3" /> Gửi thất bại {onRetry && <button onClick={onRetry} className="inline-flex items-center gap-0.5 font-semibold underline"><RotateCw className="size-3" />Thử lại</button>}</span>
          )}
        </div>
      </div>
    </div>
  );
}
