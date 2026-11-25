"use client";

import { Suspense, useEffect, useMemo, useRef, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { useQueryClient } from "@tanstack/react-query";
import { ImagePlus, Loader2, MessageSquarePlus, MoreHorizontal, PanelLeft, Pencil, Search, Send, Trash2, X } from "lucide-react";
import { toast } from "sonner";
import { UserAvatar } from "@/components/botanical/BotanicalAvatar";
import { ConfirmDialog } from "@/components/layout/ConfirmDialog";
import { DemoNotice } from "@/components/layout/DemoBadge";
import { LoadingState } from "@/components/layout/states";
import { Button } from "@/components/ui/button";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { Input } from "@/components/ui/input";
import { Sheet, SheetContent, SheetTitle } from "@/components/ui/sheet";
import { Skeleton } from "@/components/ui/skeleton";
import { Textarea } from "@/components/ui/textarea";
import { AIChatMessage, AssistantAvatar, AssistantTypingIndicator } from "@/features/assistant/components";
import { qk, useChatMessages, useChatSessions } from "@/hooks/queries";
import { cn } from "@/lib/utils";
import { assistantService } from "@/services/assistant.service";
import { fileToDataUrl } from "@/services/upload.service";
import { useAuth } from "@/stores/auth";
import type { ChatMessage, ChatSession } from "@/types/user";

const SUGGESTIONS = [
  "Cây của tôi đang bị vàng lá, phải làm sao?",
  "Tôi nên tưới cây bao nhiêu lần một tuần?",
  "Hãy giúp tôi chăm sóc cây vào mùa mưa.",
  "Gợi ý cây phù hợp với ban công ít ánh sáng.",
];

function SessionList({ sessions, loading, activeId, onSelect, onNew, onRename, onDelete }: { sessions: ChatSession[]; loading: boolean; activeId: string | null; onSelect: (id: string) => void; onNew: () => void; onRename: (s: ChatSession) => void; onDelete: (s: ChatSession) => void }) {
  const user = useAuth((s) => s.user);
  const [q, setQ] = useState("");
  const list = sessions.filter((s) => s.title.toLowerCase().includes(q.trim().toLowerCase()));
  return (
    <div className="flex h-full flex-col">
      <div className="flex items-center gap-2 p-4">
        <AssistantAvatar className="size-9" />
        <div><p className="font-semibold leading-tight">Floria</p><p className="text-xs text-muted-foreground">Bác sĩ cây trồng</p></div>
      </div>
      <div className="space-y-2 px-4">
        <Button className="w-full" onClick={onNew}><MessageSquarePlus /> Cuộc trò chuyện mới</Button>
        <div className="relative"><Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" /><Input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Tìm hội thoại" className="h-9 pl-9 text-sm" /></div>
      </div>
      <div className="mt-3 flex-1 space-y-1 overflow-y-auto px-2 pb-2">
        {loading ? [0, 1, 2].map((i) => <Skeleton key={i} className="mx-2 h-10 rounded-xl" />) : list.length === 0 ? (
          <p className="px-3 py-6 text-center text-xs text-muted-foreground">{q ? "Không tìm thấy hội thoại" : "Chưa có hội thoại"}</p>
        ) : list.map((s) => (
          <div key={s.id} className={cn("group flex items-center rounded-xl", activeId === s.id ? "bg-mint" : "hover:bg-mint/50")}>
            <button onClick={() => onSelect(s.id)} className="min-w-0 flex-1 truncate px-3 py-2.5 text-left text-sm font-medium">{s.title}</button>
            <DropdownMenu>
              <DropdownMenuTrigger asChild><Button variant="ghost" size="icon-sm" className="mr-1 opacity-60 group-hover:opacity-100" aria-label="Tùy chọn"><MoreHorizontal /></Button></DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuItem onClick={() => onRename(s)}><Pencil /> Đổi tên</DropdownMenuItem>
                <DropdownMenuItem className="text-danger focus:text-danger" onClick={() => onDelete(s)}><Trash2 /> Xóa</DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        ))}
      </div>
      <div className="flex items-center gap-3 border-t p-4">
        <UserAvatar user={user} className="size-8" />
        <div className="min-w-0"><p className="truncate text-sm font-semibold">{user?.displayName}</p><p className="truncate text-xs text-muted-foreground">{user?.email}</p></div>
      </div>
    </div>
  );
}

function AssistantContent() {
  const searchParams = useSearchParams();
  const initialQ = searchParams.get("q") ?? "";
  const initialS = searchParams.get("s") ?? null;
  const router = useRouter();
  const qc = useQueryClient();
  const user = useAuth((s) => s.user)!;
  const sessionsQ = useChatSessions();
  const [activeId, setActiveId] = useState<string | null>(initialS);
  const messagesQ = useChatMessages(activeId);
  const [input, setInput] = useState(initialQ);
  const [images, setImages] = useState<string[]>([]);
  const [sending, setSending] = useState(false);
  const [optimistic, setOptimistic] = useState<(ChatMessage & { pending?: boolean })[]>([]);
  const [drawer, setDrawer] = useState(false);
  const [renaming, setRenaming] = useState<ChatSession | null>(null);
  const [renameValue, setRenameValue] = useState("");
  const [deleting, setDeleting] = useState<ChatSession | null>(null);
  const fileRef = useRef<HTMLInputElement>(null);
  const endRef = useRef<HTMLDivElement>(null);
  const autoSentRef = useRef(false);

  const sessions = useMemo(() => sessionsQ.data ?? [], [sessionsQ.data]);
  const messages = [...(messagesQ.data ?? []), ...optimistic];
  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages.length, sending]);

  // Tự động tạo phiên chat mới và gửi ngay khi đi từ trang Chi tiết cây / Quét bệnh (?q=...)
  useEffect(() => {
    if (!initialQ.trim() || autoSentRef.current) return;
    autoSentRef.current = true;
    const text = initialQ.trim();
    router.replace("/assistant");
    void (async () => {
      try {
        const s = await assistantService.createSession();
        setActiveId(s.id);
        setInput("");
        setSending(true);
        setOptimistic([{ id: "tmp", sessionId: s.id, role: "user", content: text, images: [], createdAt: new Date().toISOString(), pending: true }]);
        await assistantService.sendMessage(s.id, text, []);
        await qc.invalidateQueries({ queryKey: qk.chatMessages(s.id) });
        setOptimistic([]);
        void qc.invalidateQueries({ queryKey: qk.chatSessions(user.uid) });
      } catch (e) {
        setOptimistic((o) => o.map((m) => ({ ...m, status: "error" as const })));
        toast.error((e as Error).message || "Trợ lý tạm thời không phản hồi");
      } finally {
        setSending(false);
      }
    })();
  }, [initialQ, qc, router, user.uid]);

  const refreshSessions = () => qc.invalidateQueries({ queryKey: qk.chatSessions(user.uid) });

  const send = async (text = input, imgs = images) => {
    if ((!text.trim() && !imgs.length) || sending) return;
    let sid = activeId;
    try {
      if (!sid) {
        const s = await assistantService.createSession();
        sid = s.id;
        setActiveId(s.id);
      }
      setInput("");
      setImages([]);
      setSending(true);
      setOptimistic([{ id: "tmp", sessionId: sid, role: "user", content: text.trim(), images: imgs, createdAt: new Date().toISOString(), pending: true }]);
      await assistantService.sendMessage(sid, text.trim(), imgs);
      await qc.invalidateQueries({ queryKey: qk.chatMessages(sid) });
      setOptimistic([]);
      void refreshSessions();
    } catch (e) {
      setOptimistic((o) => o.map((m) => ({ ...m, status: "error" as const })));
      toast.error((e as Error).message || "Trợ lý tạm thời không phản hồi");
    } finally {
      setSending(false);
    }
  };

  const select = (id: string) => {
    setActiveId(id);
    setOptimistic([]);
    setDrawer(false);
    router.replace(`/assistant?s=${encodeURIComponent(id)}`);
  };
  const newChat = () => {
    setActiveId(null);
    setOptimistic([]);
    setDrawer(false);
    router.replace("/assistant");
  };

  const sidebar = (
    <SessionList sessions={sessions} loading={sessionsQ.isLoading} activeId={activeId} onSelect={select} onNew={newChat}
      onRename={(s) => { setRenaming(s); setRenameValue(s.title); }} onDelete={setDeleting} />
  );

  return (
    <div className="container-floria py-4">
      <div className="flex h-[calc(100vh-7rem)] overflow-hidden rounded-3xl border bg-card shadow-card">
        <aside className="hidden w-72 shrink-0 border-r bg-muted/40 md:block">{sidebar}</aside>
        <Sheet open={drawer} onOpenChange={setDrawer}><SheetContent side="left" className="w-80 p-0"><SheetTitle className="sr-only">Lịch sử hội thoại</SheetTitle>{sidebar}</SheetContent></Sheet>
        <section className="flex min-w-0 flex-1 flex-col bg-mist-gradient">
          <header className="flex items-center gap-3 border-b bg-card/80 px-4 py-3 backdrop-blur">
            <Button variant="ghost" size="icon-sm" className="md:hidden" onClick={() => setDrawer(true)} aria-label="Lịch sử"><PanelLeft /></Button>
            <AssistantAvatar className="size-9" />
            <div className="min-w-0 flex-1">
              <p className="font-semibold leading-tight">Trợ lý Floria</p>
              <p className="flex items-center gap-1.5 text-xs text-muted-foreground"><span className="size-1.5 rounded-full bg-success" /> {sending ? "Đang soạn trả lời…" : "Đang hoạt động"}</p>
            </div>
          </header>
          <div className="flex-1 space-y-5 overflow-y-auto px-4 py-6 md:px-8">
            {!activeId && messages.length === 0 ? (
              <div className="mx-auto flex max-w-xl flex-col items-center pt-8 text-center">
                <AssistantAvatar className="size-16" />
                <h1 className="mt-4 text-2xl font-bold">Chào {user.displayName.split(" ").slice(-1)[0]}, mình có thể giúp gì cho khu vườn?</h1>
                <p className="mt-2 text-sm text-muted-foreground">Mình tư vấn về thực vật, chăm sóc cây, sâu bệnh, môi trường trồng và làm vườn.</p>
                <div className="mt-6 grid w-full gap-2 sm:grid-cols-2">
                  {SUGGESTIONS.map((s) => <button key={s} onClick={() => send(s, [])} className="rounded-2xl border bg-card p-3 text-left text-sm transition-all hover:border-leaf hover:shadow-soft">{s}</button>)}
                </div>
                <DemoNotice className="mt-6 text-left">Chế độ demo: câu trả lời được tạo sẵn ngoại tuyến. Kết nối máy chủ Gemini (có model dự phòng) để trò chuyện thật.</DemoNotice>
              </div>
            ) : messagesQ.isLoading ? (
              <div className="space-y-4">{[0, 1].map((i) => <Skeleton key={i} className="h-16 w-2/3 rounded-2xl" />)}</div>
            ) : (
              messages.map((m) => <AIChatMessage key={m.id} message={m} onRetry={m.status === "error" ? () => { setOptimistic([]); void send(m.content, m.images); } : undefined} />)
            )}
            {sending && <AssistantTypingIndicator />}
            <div ref={endRef} />
          </div>
          <div className="border-t bg-card/90 p-3 backdrop-blur md:p-4">
            {images.length > 0 && (
              <div className="mb-2 flex gap-2">{images.map((src, i) => (
                <div key={i} className="relative"><img src={src} alt="" className="size-16 rounded-xl object-cover" /><button onClick={() => setImages(images.filter((_, j) => j !== i))} className="absolute -right-1.5 -top-1.5 grid size-5 place-items-center rounded-full bg-forest text-forest-foreground" aria-label="Bỏ ảnh"><X className="size-3" /></button></div>
              ))}</div>
            )}
            <form onSubmit={(e) => { e.preventDefault(); void send(); }} className="flex items-end gap-2">
              <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={async (e) => { const f = e.target.files?.[0]; if (f) setImages([...images, await fileToDataUrl(f, 800)].slice(0, 3)); e.target.value = ""; }} />
              <Button type="button" variant="ghost" size="icon" onClick={() => fileRef.current?.click()} disabled={images.length >= 3} aria-label="Đính kèm ảnh"><ImagePlus /></Button>
              <Textarea value={input} onChange={(e) => setInput(e.target.value)} rows={1} maxLength={2000} placeholder="Hỏi Floria về cây của bạn…" className="max-h-40 min-h-11 resize-none rounded-2xl"
                onKeyDown={(e) => { if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); void send(); } }} />
              <Button type="submit" size="icon" className="rounded-full" disabled={sending || (!input.trim() && !images.length)} aria-label="Gửi">{sending ? <Loader2 className="animate-spin" /> : <Send />}</Button>
            </form>
          </div>
        </section>
      </div>
      <ConfirmDialog open={!!renaming} onOpenChange={(o) => !o && setRenaming(null)} title="Đổi tên hội thoại" confirmLabel="Lưu"
        onConfirm={async () => { if (!renameValue.trim()) return; await assistantService.renameSession(renaming!.id, renameValue.trim()); setRenaming(null); void refreshSessions(); }}>
        <Input value={renameValue} onChange={(e) => setRenameValue(e.target.value)} maxLength={60} autoFocus />
      </ConfirmDialog>
      <ConfirmDialog open={!!deleting} onOpenChange={(o) => !o && setDeleting(null)} destructive title="Xóa hội thoại này?" description="Toàn bộ tin nhắn trong hội thoại sẽ bị xóa." confirmLabel="Xóa"
        onConfirm={async () => { await assistantService.deleteSession(deleting!.id); if (activeId === deleting!.id) newChat(); setDeleting(null); void refreshSessions(); toast.success("Đã xóa hội thoại"); }} />
    </div>
  );
}

export default function AssistantPage() {
  return (
    <Suspense fallback={<LoadingState className="min-h-[60vh]" />}>
      <AssistantContent />
    </Suspense>
  );
}
