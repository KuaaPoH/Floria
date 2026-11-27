"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Bot, ImagePlus, Loader2, MessageSquare, Pencil, Plus, Save, Send, ShieldAlert, Tag, Trash2, X } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { PageHeader } from "@/components/shared/page-header";
import { Field } from "@/components/shared/field";
import { StatusBadge } from "@/components/shared/status-badge";
import { ConfirmDialog } from "@/components/shared/confirm-dialog";
import { FormDialog } from "@/components/shared/form-dialog";
import { EmptyState } from "@/components/shared/states";
import { apiRequest } from "@/lib/api-client";
import { useResourceList } from "@/hooks/use-resource";
import { logAudit, productsService } from "@/services";
import { fileToDataUrl, validateImageFile } from "@/services/upload.service";
import { usePermission } from "@/stores/rbac-store";
import { formatDateTime, formatVND } from "@/lib/format";
import { uid } from "@/lib/id";
import type { AssistantConfig, AssistantGuardrail } from "@/app/api/admin/assistant/config/route";

const TABS = ["settings", "guardrails", "tags", "sandbox", "history"] as const;
type Tab = (typeof TABS)[number];

const SANDBOX_SESSIONS_KEY = "floria_assistant_sandbox_sessions_v1";

interface SandboxMessage {
  id: string;
  role: "user" | "model";
  text: string;
  images?: string[];
  model?: string;
  latencyMs?: number;
  createdAt: string;
}

interface SandboxSession {
  id: string;
  title: string;
  messages: SandboxMessage[];
  updatedAt: string;
}

function loadSandboxSessions(): SandboxSession[] {
  if (typeof window === "undefined") return [];
  try {
    const raw = localStorage.getItem(SANDBOX_SESSIONS_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function saveSandboxSessions(items: SandboxSession[]) {
  if (typeof window === "undefined") return;
  const trimmed = items.slice(0, 30);
  try {
    localStorage.setItem(SANDBOX_SESSIONS_KEY, JSON.stringify(trimmed));
  } catch {
    // Fallback khi vượt quota localStorage: giữ ảnh ở 3 hộp thoại mới nhất
    try {
      const compactWithRecentImages = trimmed.map((s, idx) =>
        idx < 3
          ? s
          : {
              ...s,
              messages: s.messages.map((m) => (m.images ? { ...m, images: undefined } : m)),
            },
      );
      localStorage.setItem(SANDBOX_SESSIONS_KEY, JSON.stringify(compactWithRecentImages));
    } catch {
      // Fallback cuối: chỉ lưu phần văn bản để không mất lịch sử hội thoại
      try {
        const textOnly = trimmed.map((s) => ({
          ...s,
          messages: s.messages.map((m) => (m.images ? { ...m, images: undefined } : m)),
        }));
        localStorage.setItem(SANDBOX_SESSIONS_KEY, JSON.stringify(textOnly));
      } catch {
        // Bỏ qua nếu trình duyệt chặn localStorage
      }
    }
  }
}

function parseAssistantReply(raw: string): {
  cleanText: string;
  productIds: string[];
  careSchedule: { water: string; fertilize: string; clean: string } | null;
} {
  const productIds: string[] = [];
  const prodRegex = /\[RECOMMEND_PRODUCT:\s*([^\]]+)\]/gi;
  let match: RegExpExecArray | null;
  while ((match = prodRegex.exec(raw)) !== null) {
    const id = match[1].trim();
    if (id && !productIds.includes(id)) productIds.push(id);
  }

  let careSchedule: { water: string; fertilize: string; clean: string } | null = null;
  const careMatch = raw.match(/\[CARE_SCHEDULE:\s*water=(\d+)\s*,\s*fertilize=(\d+)\s*,\s*clean=(\d+)\s*\]/i);
  if (careMatch) {
    careSchedule = { water: careMatch[1], fertilize: careMatch[2], clean: careMatch[3] };
  }

  const cleanText = raw
    .replace(/\[RECOMMEND_PRODUCT:\s*[^\]]+\]/gi, "")
    .replace(/\[CARE_SCHEDULE:\s*[^\]]+\]/gi, "")
    .replace(/\n{3,}/g, "\n\n")
    .trim();

  return { cleanText, productIds, careSchedule };
}

function renderInlineMarkdown(line: string) {
  const parts = line.split(/(\*\*[^*]+\*\*|`[^`]+`)/g);
  return parts.map((part, idx) => {
    if (part.startsWith("**") && part.endsWith("**") && part.length > 4) {
      return (
        <strong key={idx} className="font-semibold text-forest">
          {part.slice(2, -2)}
        </strong>
      );
    }
    if (part.startsWith("`") && part.endsWith("`") && part.length > 2) {
      return (
        <code key={idx} className="rounded bg-muted px-1 py-0.5 font-mono text-xs">
          {part.slice(1, -1)}
        </code>
      );
    }
    return <span key={idx}>{part}</span>;
  });
}

function FormattedChatText({ text }: { text: string }) {
  const lines = text.split("\n");
  return (
    <div className="space-y-1.5 leading-relaxed text-foreground">
      {lines.map((line, i) => {
        const trimmed = line.trim();
        if (!trimmed) return <div key={i} className="h-1" />;
        if (/^[-*]\s+/.test(trimmed)) {
          return (
            <div key={i} className="flex gap-2 pl-2">
              <span className="text-forest">•</span>
              <span className="flex-1">{renderInlineMarkdown(trimmed.replace(/^[-*]\s+/, ""))}</span>
            </div>
          );
        }
        return <p key={i}>{renderInlineMarkdown(line)}</p>;
      })}
    </div>
  );
}

const GUARDRAIL_CAT_LABEL: Record<AssistantGuardrail["category"], string> = {
  care: "Chăm sóc & Kê đơn",
  toxicity: "Cảnh báo độc tính",
  medical: "Cấm chữa bệnh người",
  scope: "Chặn ngoài phạm vi",
};

export default function AssistantPage() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const rawTab = searchParams.get("tab") as Tab | null;
  const tab: Tab = rawTab && TABS.includes(rawTab) ? rawTab : "settings";

  const canCreate = usePermission("assistant", "create");
  const canEdit = usePermission("assistant", "edit");
  const canDelete = usePermission("assistant", "delete");
  const canConfigure = usePermission("assistant", "configure");
  const qc = useQueryClient();

  const [sessions, setSessions] = useState<SandboxSession[]>([]);
  const [activeSessionId, setActiveSessionId] = useState<string | null>(null);

  useEffect(() => {
    const loaded = loadSandboxSessions();
    setSessions(loaded);
    if (loaded.length > 0) setActiveSessionId(loaded[0].id);
  }, []);

  const updateSessions = (updater: (prev: SandboxSession[]) => SandboxSession[]) => {
    setSessions((prev) => {
      const next = updater(prev);
      saveSandboxSessions(next);
      return next;
    });
  };

  const createNewSession = () => {
    const newId = uid("chat");
    const fresh: SandboxSession = {
      id: newId,
      title: "Hộp thoại mới",
      messages: [],
      updatedAt: new Date().toISOString(),
    };
    updateSessions((prev) => [fresh, ...prev]);
    setActiveSessionId(newId);
    return newId;
  };

  const deleteSession = (id: string) => {
    updateSessions((prev) => {
      const next = prev.filter((s) => s.id !== id);
      if (activeSessionId === id) {
        setActiveSessionId(next[0]?.id ?? null);
      }
      return next;
    });
    toast.success("Đã xoá hộp thoại");
  };

  const clearAllSessions = () => {
    setSessions([]);
    setActiveSessionId(null);
    saveSandboxSessions([]);
    toast.success("Đã xoá toàn bộ hộp thoại kiểm thử");
  };

  const cfgQuery = useQuery({
    queryKey: ["assistant-real-config"],
    queryFn: () => apiRequest<AssistantConfig>("/assistant/config"),
  });

  const saveMutation = useMutation({
    mutationFn: (payload: AssistantConfig) =>
      apiRequest<AssistantConfig>("/assistant/config", {
        method: "PUT",
        body: JSON.stringify(payload),
      }),
    onSuccess: (res) => {
      qc.setQueryData(["assistant-real-config"], res);
      toast.success("Đã lưu cấu hình Trợ lý Floria lên Firestore");
      logAudit({
        action: "Cập nhật Trợ lý Floria",
        target: "SystemConfig/assistant_config",
        before: "—",
        after: `${res.name} · ${res.guardrails.filter((g) => g.enabled).length} guardrails`,
      });
    },
    onError: (err) => {
      toast.error(err instanceof Error ? err.message : "Không thể lưu cấu hình");
    },
  });

  return (
    <>
      <PageHeader
        title="Floria Assistant & Guardrails"
        description="Cấu hình nhân cách Trợ lý Floria, System Prompt, quy tắc an toàn, Action Tags và kiểm thử trên Sandbox."
      />

      <Tabs value={tab} onValueChange={(v) => router.replace(`/admin/assistant?tab=${v}`)}>
        <TabsList className="mb-5 h-10 w-full justify-start overflow-x-auto sm:w-auto">
          <TabsTrigger value="settings">Cài đặt & Kịch bản</TabsTrigger>
          <TabsTrigger value="guardrails">Quy tắc an toàn</TabsTrigger>
          <TabsTrigger value="tags">Thẻ hành động</TabsTrigger>
          <TabsTrigger value="sandbox">Kiểm thử trợ lý</TabsTrigger>
          <TabsTrigger value="history">Lịch sử kiểm thử ({sessions.length})</TabsTrigger>
        </TabsList>

        <TabsContent value="settings">
          <GeneralAndPromptTab
            config={cfgQuery.data}
            loading={cfgQuery.isLoading}
            canEdit={canEdit}
            canConfigure={canConfigure}
            saving={saveMutation.isPending}
            onSave={(next) => saveMutation.mutate(next)}
          />
        </TabsContent>

        <TabsContent value="guardrails">
          <GuardrailsTab
            config={cfgQuery.data}
            loading={cfgQuery.isLoading}
            canCreate={canCreate}
            canEdit={canEdit}
            canDelete={canDelete}
            saving={saveMutation.isPending}
            onSave={(next) => saveMutation.mutate(next)}
          />
        </TabsContent>

        <TabsContent value="tags">
          <ActionTagsTab
            config={cfgQuery.data}
            canEdit={canEdit}
            saving={saveMutation.isPending}
            onSave={(next) => saveMutation.mutate(next)}
          />
        </TabsContent>

        <TabsContent value="sandbox">
          <TestingSandboxTab
            config={cfgQuery.data}
            sessions={sessions}
            activeSessionId={activeSessionId}
            onSelectSession={setActiveSessionId}
            onCreateSession={createNewSession}
            onDeleteSession={deleteSession}
            onUpdateSessions={updateSessions}
          />
        </TabsContent>

        <TabsContent value="history">
          <SandboxHistoryTab
            sessions={sessions}
            onOpenSession={(id) => {
              setActiveSessionId(id);
              router.replace("/admin/assistant?tab=sandbox");
            }}
            onDeleteSession={deleteSession}
            onClearAll={clearAllSessions}
          />
        </TabsContent>
      </Tabs>
    </>
  );
}

function GeneralAndPromptTab({
  config,
  loading,
  canEdit,
  canConfigure,
  saving,
  onSave,
}: {
  config?: AssistantConfig;
  loading: boolean;
  canEdit: boolean;
  canConfigure: boolean;
  saving: boolean;
  onSave: (next: AssistantConfig) => void;
}) {
  const [name, setName] = useState("");
  const [tone, setTone] = useState("");
  const [defaultModel, setDefaultModel] = useState("gemini-3.8-flash");
  const [systemPrompt, setSystemPrompt] = useState("");
  const canModify = canConfigure || canEdit;

  useEffect(() => {
    if (config) {
      setName(config.name);
      setTone(config.tone);
      setDefaultModel(config.defaultModel || "gemini-3.8-flash");
      setSystemPrompt(config.systemPrompt);
    }
  }, [config]);

  if (loading || !config) return <Skeleton className="h-96 rounded-xl" />;

  return (
    <div className="card-surface max-w-4xl space-y-5 p-6">
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Tên xưng hô của trợ lý">
          <Input value={name} onChange={(e) => setName(e.target.value)} disabled={!canModify || saving} />
        </Field>
        <Field label="Giọng điệu & phong cách">
          <Input value={tone} onChange={(e) => setTone(e.target.value)} disabled={!canModify || saving} />
        </Field>
      </div>

      <Field
        label="System Prompt chính (đồng bộ sang Floria App khi mở lại ứng dụng)"
        hint="Hệ thống tự động ghép thêm các quy tắc Guardrails đang bật và danh sách sản phẩm đang kích hoạt."
      >
        <Textarea
          rows={8}
          value={systemPrompt}
          onChange={(e) => setSystemPrompt(e.target.value)}
          disabled={!canConfigure || saving}
          className="font-mono text-xs leading-relaxed"
        />
      </Field>

      <div className="flex items-center justify-between border-t pt-4">
        <p className="text-xs text-muted-foreground">
          {config.updatedAt
            ? `Cập nhật lần cuối: ${formatDateTime(config.updatedAt)}${config.updatedBy ? ` bởi ${config.updatedBy}` : ""}`
            : "Đang dùng cấu hình mặc định"}
        </p>
        {canModify && (
          <Button
            disabled={saving}
            onClick={() =>
              onSave({
                ...config,
                name,
                tone,
                defaultModel,
                systemPrompt,
              })
            }
          >
            {saving ? <Loader2 className="animate-spin" /> : <Save />} Lưu & Đồng bộ
          </Button>
        )}
      </div>
    </div>
  );
}

function GuardrailsTab({
  config,
  loading,
  canCreate,
  canEdit,
  canDelete,
  saving,
  onSave,
}: {
  config?: AssistantConfig;
  loading: boolean;
  canCreate: boolean;
  canEdit: boolean;
  canDelete: boolean;
  saving: boolean;
  onSave: (next: AssistantConfig) => void;
}) {
  const [formOpen, setFormOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [deletingRule, setDeletingRule] = useState<AssistantGuardrail | null>(null);
  const [name, setName] = useState("");
  const [category, setCategory] = useState<AssistantGuardrail["category"]>("scope");
  const [ruleText, setRuleText] = useState("");

  if (loading || !config) return <Skeleton className="h-72 rounded-xl" />;

  const openCreate = () => {
    setEditingId(null);
    setName("");
    setCategory("scope");
    setRuleText("");
    setFormOpen(true);
  };

  const openEdit = (g: AssistantGuardrail) => {
    setEditingId(g.id);
    setName(g.name);
    setCategory(g.category);
    setRuleText(g.ruleText);
    setFormOpen(true);
  };

  const toggleRule = (id: string) => {
    if (!canEdit) return;
    const nextRules = config.guardrails.map((g) => (g.id === id ? { ...g, enabled: !g.enabled } : g));
    onSave({ ...config, guardrails: nextRules });
  };

  const submitForm = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim() || !ruleText.trim()) return;

    if (editingId) {
      if (!canEdit) return;
      const nextRules = config.guardrails.map((g) =>
        g.id === editingId
          ? { ...g, name: name.trim(), category, ruleText: ruleText.trim() }
          : g,
      );
      onSave({ ...config, guardrails: nextRules });
    } else {
      if (!canCreate) return;
      const nextRule: AssistantGuardrail = {
        id: uid("gr"),
        name: name.trim(),
        category,
        ruleText: ruleText.trim(),
        enabled: true,
      };
      onSave({ ...config, guardrails: [...config.guardrails, nextRule] });
    }
    setFormOpen(false);
  };

  const confirmDelete = () => {
    if (!deletingRule || !canDelete) return;
    const nextRules = config.guardrails.filter((g) => g.id !== deletingRule.id);
    onSave({ ...config, guardrails: nextRules });
    setDeletingRule(null);
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <p className="text-sm text-muted-foreground">
          Các quy tắc an toàn đang bật ({config.guardrails.filter((g) => g.enabled).length}/{config.guardrails.length}) sẽ được ghép vào System Instruction của Trợ lý Floria.
        </p>
        {canCreate && (
          <Button onClick={openCreate}>
            <Plus /> Thêm quy tắc
          </Button>
        )}
      </div>

      <div className="grid gap-3 md:grid-cols-2">
        {config.guardrails.map((g) => (
          <div key={g.id} className="card-surface flex flex-col justify-between gap-3 p-4">
            <div className="flex items-start justify-between gap-4">
              <div className="space-y-1.5">
                <div className="flex flex-wrap items-center gap-2">
                  <ShieldAlert className="size-4 text-forest" />
                  <span className="text-sm font-semibold">{g.name}</span>
                  <Badge variant="outline" className="text-[10px]">
                    {GUARDRAIL_CAT_LABEL[g.category]}
                  </Badge>
                </div>
                <p className="text-xs text-muted-foreground">{g.ruleText}</p>
              </div>
              <Switch
                checked={g.enabled}
                disabled={!canEdit || saving}
                onCheckedChange={() => toggleRule(g.id)}
                aria-label={`Bật/tắt ${g.name}`}
              />
            </div>

            {(canEdit || canDelete) && (
              <div className="flex justify-end gap-1.5 border-t pt-2.5">
                {canEdit && (
                  <Button size="sm" variant="ghost" onClick={() => openEdit(g)} disabled={saving}>
                    <Pencil className="size-3.5" /> Chỉnh sửa
                  </Button>
                )}
                {canDelete && (
                  <Button
                    size="sm"
                    variant="ghost"
                    className="text-danger hover:text-danger"
                    onClick={() => setDeletingRule(g)}
                    disabled={saving}
                  >
                    <Trash2 className="size-3.5" /> Xoá
                  </Button>
                )}
              </div>
            )}
          </div>
        ))}
      </div>

      <FormDialog
        open={formOpen}
        onOpenChange={setFormOpen}
        title={editingId ? "Chỉnh sửa quy tắc Guardrail" : "Thêm quy tắc Guardrail mới"}
        onSubmit={submitForm}
        submitLabel={editingId ? "Cập nhật" : "Lưu quy tắc"}
      >
        <div className="space-y-3">
          <Field label="Tên quy tắc">
            <Input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="VD: Không tư vấn thuốc trừ sâu hóa học mạnh"
            />
          </Field>
          <Field label="Nhóm">
            <Select value={category} onValueChange={(v) => setCategory(v as AssistantGuardrail["category"])}>
              <SelectTrigger><SelectValue /></SelectTrigger>
              <SelectContent>
                {Object.entries(GUARDRAIL_CAT_LABEL).map(([k, label]) => (
                  <SelectItem key={k} value={k}>{label}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </Field>
          <Field label="Nội dung chỉ dẫn gửi cho LLM">
            <Textarea rows={3} value={ruleText} onChange={(e) => setRuleText(e.target.value)} />
          </Field>
        </div>
      </FormDialog>

      <ConfirmDialog
        open={!!deletingRule}
        onOpenChange={(o) => !o && setDeletingRule(null)}
        title={`Xoá quy tắc "${deletingRule?.name}"?`}
        description="Quy tắc này sẽ bị gỡ khỏi System Instruction của Trợ lý Floria."
        tone="danger"
        confirmLabel="Xoá quy tắc"
        onConfirm={confirmDelete}
      />
    </div>
  );
}

function ActionTagsTab({
  config,
  canEdit,
  saving,
  onSave,
}: {
  config?: AssistantConfig;
  canEdit: boolean;
  saving: boolean;
  onSave: (next: AssistantConfig) => void;
}) {
  const products = useResourceList(productsService);
  const disabledIds = new Set(config?.disabledProductIds ?? []);

  const toggleProduct = (productId: string) => {
    if (!config) return;
    const nextSet = new Set(disabledIds);
    if (nextSet.has(productId)) {
      nextSet.delete(productId);
    } else {
      nextSet.add(productId);
    }
    onSave({ ...config, disabledProductIds: Array.from(nextSet) });
  };

  const realTags = [
    {
      tag: "[RECOMMEND_PRODUCT: product_id]",
      title: "Kê đơn sản phẩm từ Cửa hàng Floria",
      desc: "Khi cây bị bệnh nặng hoặc người dùng hỏi mua vật tư, Trợ lý Floria gắn thẻ này để App tự động hiển thị thẻ sản phẩm kèm nút Mua ngay.",
    },
    {
      tag: "[CARE_SCHEDULE: {...}]",
      title: "Đề xuất & Áp dụng Lịch chăm sóc cây",
      desc: "Khi người dùng hỏi lịch tưới/bón phân cho cây cụ thể, App bắt thẻ này để hiện nút 1 chạm áp dụng thẳng vào MyGarden.",
    },
  ];

  const allProducts = products.data ?? [];
  const activeCount = allProducts.filter((p) => !disabledIds.has(p.id)).length;

  return (
    <div className="space-y-5">
      <div className="grid gap-4 md:grid-cols-2">
        {realTags.map((t) => (
          <div key={t.tag} className="card-surface space-y-2 p-5">
            <div className="flex items-center gap-2">
              <Tag className="size-4 text-forest" />
              <h3 className="text-sm font-semibold">{t.title}</h3>
            </div>
            <p className="inline-block rounded-md bg-muted px-2 py-1 font-mono text-xs text-forest">{t.tag}</p>
            <p className="text-xs text-muted-foreground">{t.desc}</p>
          </div>
        ))}
      </div>

      <div className="card-surface p-5">
        <div className="mb-4 flex flex-wrap items-center justify-between gap-2">
          <div>
            <h3 className="text-sm font-semibold">
              Danh sách Product ID hợp lệ trong ShopProducts ({activeCount}/{allProducts.length} đang bật cho AI)
            </h3>
            <p className="text-xs text-muted-foreground">
              Gạt tắt nếu không muốn Trợ lý Floria kê đơn sản phẩm đó (vẫn giữ hiển thị bán bình thường trong Cửa hàng).
            </p>
          </div>
        </div>

        <div className="grid gap-2.5 sm:grid-cols-2 lg:grid-cols-3">
          {allProducts.map((p) => {
            const isEnabled = !disabledIds.has(p.id);
            return (
              <div
                key={p.id}
                className="flex items-center justify-between gap-3 rounded-xl border bg-surface-2/40 px-3 py-2.5 text-xs"
              >
                <div className="min-w-0 flex-1">
                  <p className="truncate font-medium">{p.name}</p>
                  <div className="mt-0.5 flex items-center gap-2 text-[11px] text-muted-foreground">
                    <span className="truncate font-mono">{p.id}</span>
                    <span>·</span>
                    <span className="shrink-0 font-semibold text-forest">{formatVND(p.price)}</span>
                  </div>
                </div>
                <Switch
                  checked={isEnabled}
                  disabled={!canEdit || saving || !config}
                  onCheckedChange={() => toggleProduct(p.id)}
                  aria-label={`Cho phép AI kê đơn ${p.name}`}
                />
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

function TestingSandboxTab({
  config,
  sessions,
  activeSessionId,
  onSelectSession,
  onCreateSession,
  onDeleteSession,
  onUpdateSessions,
}: {
  config?: AssistantConfig;
  sessions: SandboxSession[];
  activeSessionId: string | null;
  onSelectSession: (id: string) => void;
  onCreateSession: () => string;
  onDeleteSession: (id: string) => void;
  onUpdateSessions: (updater: (prev: SandboxSession[]) => SandboxSession[]) => void;
}) {
  const [input, setInput] = useState("");
  const [images, setImages] = useState<string[]>([]);
  const [loading, setLoading] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const products = useResourceList(productsService);
  const productMap = new Map((products.data ?? []).map((p) => [p.id, p]));

  const currentSession = sessions.find((s) => s.id === activeSessionId) ?? null;

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [currentSession?.messages.length, loading]);

  const presets = [
    "Cây trầu bà nhà mình bị đốm vàng lá, cần tưới hay xịt thuốc gì?",
    "Viết giúp mình đoạn code Python sắp xếp mảng tăng dần",
    "Cây kim tiền có độc với mèo không?",
  ];

  const handleAddFiles = async (fileList: FileList | File[]) => {
    const files = Array.from(fileList);
    if (files.length === 0) return;

    const remaining = 3 - images.length;
    if (remaining <= 0) {
      toast.info("Tối đa 3 ảnh cho mỗi tin nhắn kiểm thử.");
      return;
    }

    const candidates = files.slice(0, remaining);
    if (files.length > remaining) {
      toast.info(`Chỉ có thể đính kèm tối đa 3 ảnh/lượt (đã chọn ${remaining} ảnh).`);
    }

    const encoded: string[] = [];
    for (const file of candidates) {
      const err = validateImageFile(file);
      if (err === "type") {
        toast.error(`"${file.name}" không đúng định dạng ảnh (hỗ trợ JPG, PNG, WebP, HEIC).`);
        continue;
      }
      if (err === "size") {
        toast.error(`"${file.name}" vượt quá giới hạn 10MB.`);
        continue;
      }
      try {
        encoded.push(await fileToDataUrl(file, 720, 0.78));
      } catch {
        toast.error(`Không thể đọc ảnh "${file.name}".`);
      }
    }

    if (encoded.length > 0) {
      setImages((prev) => [...prev, ...encoded].slice(0, 3));
    }
  };

  const send = async (text = input, imgs = images) => {
    const q = text.trim();
    if ((!q && imgs.length === 0) || loading) return;

    let targetId = activeSessionId;
    if (!targetId || !sessions.some((s) => s.id === targetId)) {
      targetId = onCreateSession();
    }

    const priorMessages = (sessions.find((s) => s.id === targetId)?.messages ?? []).map((m) => ({
      role: m.role,
      text: m.text,
      images: m.images,
    }));

    const userMsg: SandboxMessage = {
      id: uid("msg"),
      role: "user",
      text: q,
      images: imgs.length > 0 ? imgs : undefined,
      createdAt: new Date().toISOString(),
    };

    const nextTitle = q
      ? q.length > 42
        ? `${q.slice(0, 42)}...`
        : q
      : "Kiểm thử hình ảnh cây trồng";

    onUpdateSessions((prev) =>
      prev.map((s) =>
        s.id === targetId
          ? {
              ...s,
              title: s.messages.length === 0 ? nextTitle : s.title,
              messages: [...s.messages, userMsg],
              updatedAt: new Date().toISOString(),
            }
          : s,
      ),
    );
    setInput("");
    setImages([]);
    setLoading(true);

    try {
      const res = await apiRequest<{
        reply: string;
        model: string;
        latencyMs: number;
      }>("/assistant/sandbox", {
        method: "POST",
        body: JSON.stringify({
          message: q,
          images: imgs,
          history: priorMessages,
          name: config?.name,
          tone: config?.tone,
          defaultModel: config?.defaultModel,
          systemPrompt: config?.systemPrompt,
          guardrails: config?.guardrails,
          disabledProductIds: config?.disabledProductIds,
        }),
      });

      const botMsg: SandboxMessage = {
        id: uid("msg"),
        role: "model",
        text: res.reply,
        model: res.model,
        latencyMs: res.latencyMs,
        createdAt: new Date().toISOString(),
      };

      onUpdateSessions((prev) =>
        prev.map((s) =>
          s.id === targetId
            ? { ...s, messages: [...s.messages, botMsg], updatedAt: new Date().toISOString() }
            : s,
        ),
      );
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Lỗi gọi LLM Sandbox");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="grid gap-4 lg:grid-cols-[300px_1fr]">
      {/* Cột trái: Danh sách hộp thoại & Câu hỏi mẫu */}
      <div className="card-surface flex flex-col gap-4 p-4">
        <Button className="w-full" onClick={onCreateSession} disabled={loading}>
          <Plus className="size-4" /> Tạo hộp thoại mới
        </Button>

        <div className="space-y-1.5">
          <p className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
            Hộp thoại đã lưu ({sessions.length})
          </p>
          {sessions.length === 0 ? (
            <p className="rounded-xl border border-dashed p-3 text-center text-xs text-muted-foreground">
              Chưa có hộp thoại nào. Hãy tạo mới hoặc gửi tin nhắn.
            </p>
          ) : (
            <div className="max-h-64 space-y-1.5 overflow-y-auto pr-1">
              {sessions.map((s) => {
                const isActive = s.id === currentSession?.id;
                return (
                  <div
                    key={s.id}
                    className={`flex items-center justify-between gap-2 rounded-xl border px-3 py-2 text-xs transition ${
                      isActive ? "border-forest bg-accent font-semibold text-forest" : "bg-surface-2/40 hover:bg-muted/60"
                    }`}
                  >
                    <button
                      type="button"
                      onClick={() => onSelectSession(s.id)}
                      className="min-w-0 flex-1 text-left"
                    >
                      <p className="truncate">{s.title}</p>
                      <p className="text-[10px] font-normal text-muted-foreground">
                        {s.messages.length} tin nhắn
                      </p>
                    </button>
                    <button
                      type="button"
                      title="Xoá hộp thoại"
                      onClick={() => onDeleteSession(s.id)}
                      className="rounded-md p-1 text-muted-foreground hover:bg-danger/10 hover:text-danger"
                    >
                      <Trash2 className="size-3.5" />
                    </button>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        <div className="space-y-2 border-t pt-3">
          <p className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">Câu hỏi mẫu</p>
          {presets.map((p) => (
            <button
              key={p}
              type="button"
              onClick={() => send(p, [])}
              disabled={loading}
              className="w-full rounded-xl border bg-surface-2/50 p-2.5 text-left text-xs transition hover:bg-accent"
            >
              {p}
            </button>
          ))}
        </div>
      </div>

      {/* Cột phải: Khung hộp thoại chat liên tục */}
      <div className="card-surface flex h-[640px] flex-col overflow-hidden">
        <div className="flex items-center justify-between border-b px-5 py-3">
          <div className="flex items-center gap-2">
            <Bot className="size-4 text-forest" />
            <h3 className="text-sm font-semibold">{currentSession ? currentSession.title : "Hộp thoại kiểm thử"}</h3>
          </div>
          {currentSession && (
            <Button
              size="sm"
              variant="ghost"
              className="text-danger hover:text-danger"
              onClick={() => onDeleteSession(currentSession.id)}
            >
              <Trash2 className="size-3.5" /> Xoá hộp thoại
            </Button>
          )}
        </div>

        <div className="flex-1 space-y-4 overflow-y-auto p-5">
          {!currentSession || currentSession.messages.length === 0 ? (
            <EmptyState
              title="Bắt đầu cuộc trò chuyện kiểm thử"
              description="Nhập câu hỏi, đính kèm ảnh cây trồng hoặc chọn câu hỏi mẫu ở cột trái. Các câu hỏi tiếp theo trong cùng hộp thoại sẽ giữ nguyên ngữ cảnh."
            />
          ) : (
            currentSession.messages.map((m) => {
              if (m.role === "user") {
                return (
                  <div key={m.id} className="flex justify-end">
                    <div className="max-w-[80%] space-y-2 rounded-2xl rounded-br-sm bg-forest px-4 py-2.5 text-sm text-primary-foreground shadow-xs">
                      {m.images && m.images.length > 0 && (
                        <div className={m.images.length === 1 ? "flex flex-wrap gap-2" : "grid grid-cols-2 gap-1.5"}>
                          {m.images.map((src, idx) => (
                            <img
                              key={idx}
                              src={src}
                              alt={`Ảnh kiểm thử ${idx + 1}`}
                              className="max-h-48 w-full rounded-xl object-cover"
                            />
                          ))}
                        </div>
                      )}
                      {m.text && <p className="whitespace-pre-wrap">{m.text}</p>}
                    </div>
                  </div>
                );
              }

              const parsed = parseAssistantReply(m.text);
              return (
                <div key={m.id} className="flex justify-start">
                  <div className="max-w-[85%] space-y-2.5 rounded-2xl rounded-bl-sm border bg-surface-2/40 px-4 py-3 text-sm">
                    <div className="flex items-center justify-between gap-3">
                      <span className="text-xs font-semibold text-forest">{config?.name || "Trợ lý Floria"}</span>
                      {typeof m.latencyMs === "number" && (
                        <StatusBadge status="active" label={`${m.latencyMs}ms`} />
                      )}
                    </div>

                    <FormattedChatText text={parsed.cleanText} />

                    {/* Hiển thị Thẻ sản phẩm đề xuất có hình ảnh, tên và giá */}
                    {parsed.productIds.length > 0 && (
                      <div className="space-y-2 pt-1">
                        {parsed.productIds.map((pid) => {
                          const prod = productMap.get(pid);
                          if (!prod) {
                            return (
                              <Badge key={pid} variant="secondary" className="font-mono text-[11px]">
                                Sản phẩm đề xuất: {pid}
                              </Badge>
                            );
                          }
                          return (
                            <div
                              key={pid}
                              className="flex items-center gap-3 rounded-xl border bg-card p-2.5 shadow-xs"
                            >
                              {prod.image ? (
                                <img
                                  src={prod.image}
                                  alt={prod.name}
                                  className="size-14 shrink-0 rounded-lg object-cover"
                                />
                              ) : (
                                <div className="grid size-14 shrink-0 place-items-center rounded-lg bg-muted text-[10px] text-muted-foreground">
                                  No img
                                </div>
                              )}
                              <div className="min-w-0 flex-1">
                                <span className="inline-block rounded bg-forest/10 px-1.5 py-0.5 text-[10px] font-semibold text-forest">
                                  Sản phẩm đề xuất
                                </span>
                                <p className="mt-0.5 truncate text-xs font-semibold text-foreground">{prod.name}</p>
                                <p className="text-xs font-bold text-forest">{formatVND(prod.price)}</p>
                              </div>
                            </div>
                          );
                        })}
                      </div>
                    )}

                    {/* Hiển thị Lịch chăm sóc đề xuất nếu có */}
                    {parsed.careSchedule && (
                      <div className="rounded-xl border bg-card p-3 text-xs">
                        <p className="font-semibold text-forest">Lịch chăm sóc đề xuất</p>
                        <p className="mt-1 text-muted-foreground">
                          Tưới mỗi <b>{parsed.careSchedule.water} ngày</b> · Bón phân mỗi{" "}
                          <b>{parsed.careSchedule.fertilize} ngày</b> · Lau lá mỗi{" "}
                          <b>{parsed.careSchedule.clean} ngày</b>
                        </p>
                      </div>
                    )}
                  </div>
                </div>
              );
            })
          )}
          {loading && (
            <div className="flex justify-start">
              <div className="inline-flex items-center gap-2 rounded-2xl border bg-surface-2/40 px-4 py-2.5 text-xs text-muted-foreground">
                <Loader2 className="size-3.5 animate-spin text-forest" /> Trợ lý Floria đang suy nghĩ...
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>

        <div className="border-t bg-card p-3">
          {images.length > 0 && (
            <div className="mb-2.5 flex flex-wrap gap-2">
              {images.map((src, idx) => (
                <div key={idx} className="relative">
                  <img
                    src={src}
                    alt={`Ảnh đính kèm ${idx + 1}`}
                    className="size-16 rounded-xl border object-cover"
                  />
                  <button
                    type="button"
                    onClick={() => setImages((prev) => prev.filter((_, j) => j !== idx))}
                    className="absolute -right-1.5 -top-1.5 grid size-5 place-items-center rounded-full bg-forest text-primary-foreground shadow-xs hover:opacity-90"
                    aria-label="Bỏ ảnh"
                  >
                    <X className="size-3" />
                  </button>
                </div>
              ))}
            </div>
          )}
          <div className="flex items-end gap-2">
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              multiple
              className="hidden"
              onChange={(e) => {
                if (e.target.files) void handleAddFiles(e.target.files);
                e.target.value = "";
              }}
            />
            <Button
              type="button"
              variant="outline"
              size="icon"
              className="h-11 w-11 shrink-0 rounded-xl"
              onClick={() => fileInputRef.current?.click()}
              disabled={loading || images.length >= 3}
              title="Đính kèm ảnh (tối đa 3 ảnh)"
              aria-label="Đính kèm ảnh"
            >
              <ImagePlus className="size-4" />
            </Button>
            <Textarea
              rows={2}
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onPaste={(e) => {
                const pastedFiles = Array.from(e.clipboardData?.files ?? []).filter((f) =>
                  f.type.startsWith("image/"),
                );
                if (pastedFiles.length > 0) {
                  e.preventDefault();
                  void handleAddFiles(pastedFiles);
                }
              }}
              onKeyDown={(e) => {
                if (e.key === "Enter" && !e.shiftKey) {
                  e.preventDefault();
                  void send(input, images);
                }
              }}
              placeholder="Nhập tin nhắn hoặc dán ảnh kiểm thử (Enter để gửi, Shift+Enter xuống dòng)..."
              className="min-h-0 flex-1 resize-none"
            />
            <Button
              className="h-11 px-4"
              disabled={(!input.trim() && images.length === 0) || loading}
              onClick={() => send(input, images)}
            >
              {loading ? <Loader2 className="animate-spin" /> : <Send />}
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}

function SandboxHistoryTab({
  sessions,
  onOpenSession,
  onDeleteSession,
  onClearAll,
}: {
  sessions: SandboxSession[];
  onOpenSession: (id: string) => void;
  onDeleteSession: (id: string) => void;
  onClearAll: () => void;
}) {
  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between rounded-xl border bg-surface-2/40 px-4 py-2.5 text-xs text-muted-foreground">
        <span>Danh sách các hộp thoại đã lưu trên Kiểm thử trợ lý ({sessions.length} hộp thoại).</span>
        {sessions.length > 0 && (
          <Button size="sm" variant="outline" onClick={onClearAll}>
            <Trash2 className="size-3.5" /> Xoá tất cả
          </Button>
        )}
      </div>

      {sessions.length === 0 ? (
        <div className="card-surface">
          <EmptyState
            title="Chưa có hộp thoại kiểm thử nào"
            description="Hãy sang tab Kiểm thử trợ lý và bắt đầu nhắn tin để lưu hộp thoại tại đây."
          />
        </div>
      ) : (
        <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-3">
          {sessions.map((s) => {
            const lastMsg = s.messages[s.messages.length - 1];
            return (
              <div key={s.id} className="card-surface flex flex-col justify-between gap-3 p-4">
                <div>
                  <div className="flex items-center justify-between gap-2">
                    <span className="inline-flex items-center gap-1.5 text-sm font-semibold text-forest">
                      <MessageSquare className="size-3.5 shrink-0" />
                      <span className="truncate">{s.title}</span>
                    </span>
                    <Badge variant="outline" className="shrink-0 text-[10px]">
                      {s.messages.length} tin
                    </Badge>
                  </div>
                  <p className="mt-2 line-clamp-2 text-xs text-muted-foreground">
                    {lastMsg
                      ? parseAssistantReply(lastMsg.text).cleanText ||
                        (lastMsg.images?.length ? `[Đã đính kèm ${lastMsg.images.length} ảnh]` : "Tin nhắn trống")
                      : "Hộp thoại trống"}
                  </p>
                </div>
                <div className="flex items-center justify-between border-t pt-2.5 text-xs">
                  <span className="text-[11px] text-muted-foreground">{formatDateTime(s.updatedAt)}</span>
                  <div className="flex gap-1.5">
                    <Button size="sm" variant="outline" onClick={() => onOpenSession(s.id)}>
                      Mở hộp thoại
                    </Button>
                    <Button
                      size="sm"
                      variant="ghost"
                      className="text-danger hover:text-danger"
                      onClick={() => onDeleteSession(s.id)}
                    >
                      <Trash2 className="size-3.5" />
                    </Button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
