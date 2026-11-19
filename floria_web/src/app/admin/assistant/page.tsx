"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import type { ColumnDef } from "@tanstack/react-table";
import { Bot, Check, Eye, History, Plus, Save, Send, ShieldAlert, Sparkles, Tag, UploadCloud } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Badge } from "@/components/ui/badge";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { PageHeader } from "@/components/shared/page-header";
import { DemoBadge } from "@/components/shared/demo-badge";
import { Field } from "@/components/shared/field";
import { DataTable } from "@/components/shared/data-table";
import { StatusBadge, statusLabel } from "@/components/shared/status-badge";
import { DetailDrawer, DetailSection, InfoGrid } from "@/components/shared/detail-drawer";
import { FormDialog } from "@/components/shared/form-dialog";
import { SearchInput } from "@/components/shared/search-input";
import { FilterSelect } from "@/components/shared/filter-select";
import { useSingleton } from "@/hooks/use-singleton";
import { useResourceList, useResourceMutations } from "@/hooks/use-resource";
import { useAuthStore } from "@/stores/auth-store";
import { usePermission } from "@/stores/rbac-store";
import {
  actionTagsService,
  assistantSettingsService,
  guardrailsService,
  logAudit,
  promptDraftService,
  promptVersionsService,
  reportsService,
} from "@/services";
import { formatDateTime } from "@/lib/format";
import { uid } from "@/lib/id";
import type { ActionTag, AssistantSettings, ConversationReport, Guardrail } from "@/types";

const TABS = ["settings", "prompt", "guardrails", "tags", "sandbox", "reports"] as const;
type Tab = (typeof TABS)[number];

const GUARDRAIL_CAT_LABEL: Record<Guardrail["category"], string> = {
  care: "Chăm sóc & Chẩn đoán",
  toxicity: "Cảnh báo độc tính (Thú cưng / Trẻ em)",
  medical: "Cấm dùng cây cảnh chữa bệnh người",
  scope: "Chặn chủ đề ngoài phạm vi Floria",
};

export default function AssistantPage() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const rawTab = searchParams.get("tab") as Tab | null;
  const tab: Tab = rawTab && TABS.includes(rawTab) ? rawTab : "settings";

  const canEdit = usePermission("assistant", "edit");

  return (
    <>
      <PageHeader
        title="Floria Assistant & Guardrails"
        description="Cấu hình nhân cách trợ lý AI, System Prompt, quy tắc an toàn, Action Tags và kiểm duyệt báo cáo hội thoại."
        badge={<DemoBadge label="Mô phỏng AI" />}
      />

      <Tabs value={tab} onValueChange={(v) => router.replace(`/assistant?tab=${v}`)}>
        <TabsList className="mb-5 h-10 w-full justify-start overflow-x-auto sm:w-auto">
          <TabsTrigger value="settings">Cài đặt chung</TabsTrigger>
          <TabsTrigger value="prompt">System Prompt</TabsTrigger>
          <TabsTrigger value="guardrails">Guardrails</TabsTrigger>
          <TabsTrigger value="tags">Action Tags</TabsTrigger>
          <TabsTrigger value="sandbox">Testing Sandbox</TabsTrigger>
          <TabsTrigger value="reports">Báo cáo hội thoại</TabsTrigger>
        </TabsList>

        <TabsContent value="settings">
          <GeneralSettingsTab canEdit={canEdit} />
        </TabsContent>
        <TabsContent value="prompt">
          <SystemPromptTab canEdit={canEdit} />
        </TabsContent>
        <TabsContent value="guardrails">
          <GuardrailsTab canEdit={canEdit} />
        </TabsContent>
        <TabsContent value="tags">
          <ActionTagsTab canEdit={canEdit} />
        </TabsContent>
        <TabsContent value="sandbox">
          <TestingSandboxTab />
        </TabsContent>
        <TabsContent value="reports">
          <ReportsTab canEdit={canEdit} />
        </TabsContent>
      </Tabs>
    </>
  );
}

function GeneralSettingsTab({ canEdit }: { canEdit: boolean }) {
  const settings = useSingleton(assistantSettingsService);
  const [form, setForm] = useState<AssistantSettings | null>(null);

  useEffect(() => {
    if (settings.data) setForm(settings.data);
  }, [settings.data]);

  if (!form) return null;

  const save = () => {
    settings.save.mutate(form, {
      onSuccess: () => {
        logAudit({
          action: "Cập nhật trợ lý",
          target: "Assistant · Cài đặt chung",
          before: settings.data?.tone ?? "—",
          after: `${form.name} · ${form.language} · ${form.tone}`,
        });
        toast.success("Đã lưu cài đặt chung trợ lý");
      },
    });
  };

  return (
    <div className="card-surface max-w-3xl p-6">
      <div className="mb-5">
        <h3 className="text-base font-semibold">Thông số cơ bản</h3>
        <p className="text-xs text-muted-foreground">Áp dụng cho phản hồi của bác sĩ cây trồng Floria trên ứng dụng di động.</p>
      </div>
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Tên trợ lý">
          <Input value={form.name} disabled={!canEdit} onChange={(e) => setForm({ ...form, name: e.target.value })} />
        </Field>
        <Field label="Ngôn ngữ mặc định">
          <Select value={form.language} disabled={!canEdit} onValueChange={(v) => setForm({ ...form, language: v as "vi" | "en" })}>
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="vi">Tiếng Việt</SelectItem>
              <SelectItem value="en">English</SelectItem>
            </SelectContent>
          </Select>
        </Field>
        <Field label="Giọng điệu phản hồi">
          <Select value={form.tone} disabled={!canEdit} onValueChange={(v) => setForm({ ...form, tone: v as AssistantSettings["tone"] })}>
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="friendly">Thân thiện, gần gũi</SelectItem>
              <SelectItem value="professional">Chuyên gia thực vật học</SelectItem>
              <SelectItem value="concise">Ngắn gọn, súc tích</SelectItem>
            </SelectContent>
          </Select>
        </Field>
        <Field label="Độ dài phản hồi tối đa (ký tự)">
          <Input
            type="number"
            min={150}
            max={2000}
            disabled={!canEdit}
            value={form.maxLength}
            onChange={(e) => setForm({ ...form, maxLength: Math.max(150, Number(e.target.value) || 600) })}
          />
        </Field>
        <Field label="Câu trả lời dự phòng (Fallback)" className="sm:col-span-2">
          <Textarea rows={3} disabled={!canEdit} value={form.fallback} onChange={(e) => setForm({ ...form, fallback: e.target.value })} />
        </Field>
      </div>
      {canEdit && (
        <div className="mt-5 flex justify-end">
          <Button onClick={save} disabled={settings.save.isPending}>
            <Save /> Lưu cài đặt
          </Button>
        </div>
      )}
    </div>
  );
}

function SystemPromptTab({ canEdit }: { canEdit: boolean }) {
  const adminName = useAuthStore((s) => s.session?.name ?? "Admin");
  const draft = useSingleton(promptDraftService);
  const versions = useResourceList(promptVersionsService);
  const { create } = useResourceMutations(promptVersionsService, { entity: "Phiên bản Prompt", silent: true });
  const [content, setContent] = useState("");
  const [previewOpen, setPreviewOpen] = useState(false);

  useEffect(() => {
    if (draft.data) setContent(draft.data.content);
  }, [draft.data]);

  const sorted = useMemo(() => [...(versions.data ?? [])].sort((a, b) => b.version - a.version), [versions.data]);
  const latestVer = sorted[0]?.version ?? 0;

  const saveDraft = () => {
    draft.save.mutate(
      { content },
      {
        onSuccess: () => {
          toast.success("Đã lưu bản nháp System Prompt");
        },
      },
    );
  };

  const publish = () => {
    if (!content.trim()) {
      toast.error("Nội dung prompt không được để trống");
      return;
    }
    draft.save.mutate({ content });
    create.mutate(
      {
        id: uid("pv"),
        version: latestVer + 1,
        status: "published",
        at: new Date().toISOString(),
        by: adminName,
        content,
      },
      {
        onSuccess: () => {
          logAudit({ action: "Xuất bản Prompt", target: `Assistant Prompt v${latestVer + 1}`, before: `v${latestVer}`, after: `v${latestVer + 1}` });
          toast.success(`Đã xuất bản System Prompt v${latestVer + 1}`);
        },
      },
    );
  };

  return (
    <div className="grid gap-5 lg:grid-cols-[1.5fr_1fr]">
      <div className="card-surface p-5">
        <div className="mb-3 flex flex-wrap items-center justify-between gap-2">
          <div>
            <h3 className="text-base font-semibold">System Prompt Editor</h3>
            <p className="text-xs text-muted-foreground">Định hướng hành vi, ngữ khí và quy chuẩn thực vật cho Floria Assistant.</p>
          </div>
          <span className="rounded-md bg-surface-2 px-2.5 py-1 font-mono text-xs text-muted-foreground">{content.length} ký tự</span>
        </div>
        <Textarea rows={14} className="font-mono text-xs leading-relaxed" disabled={!canEdit} value={content} onChange={(e) => setContent(e.target.value)} />
        <div className="mt-4 flex flex-wrap justify-between gap-2">
          <Button type="button" variant="outline" onClick={() => setPreviewOpen(true)}>
            <Eye /> Xem trước
          </Button>
          {canEdit && (
            <div className="flex gap-2">
              <Button type="button" variant="soft" onClick={saveDraft} disabled={draft.save.isPending}>
                <Save /> Lưu nháp
              </Button>
              <Button type="button" onClick={publish} disabled={create.isPending}>
                <UploadCloud /> Xuất bản (v{latestVer + 1})
              </Button>
            </div>
          )}
        </div>
      </div>

      <div className="card-surface p-5">
        <div className="mb-3 flex items-center gap-2">
          <History className="size-4 text-leaf" />
          <h3 className="text-base font-semibold">Lịch sử phiên bản</h3>
        </div>
        <div className="space-y-3">
          {sorted.map((v) => (
            <div key={v.id} className="rounded-xl border bg-surface-2/40 p-3">
              <div className="flex items-center justify-between">
                <span className="font-mono text-xs font-semibold">v{v.version}</span>
                <StatusBadge status={v.status} />
              </div>
              <p className="mt-1 text-xs text-muted-foreground">
                {v.by} · {formatDateTime(v.at)}
              </p>
              <p className="mt-2 line-clamp-3 text-xs text-foreground/80">{v.content}</p>
              {canEdit && (
                <Button
                  size="sm"
                  variant="ghost"
                  className="mt-2 h-7 px-2 text-xs text-leaf"
                  onClick={() => {
                    setContent(v.content);
                    toast.info(`Đã nạp lại nội dung v${v.version} vào trình soạn thảo`);
                  }}
                >
                  Nạp phiên bản này
                </Button>
              )}
            </div>
          ))}
        </div>
      </div>

      <Dialog open={previewOpen} onOpenChange={setPreviewOpen}>
        <DialogContent className="rounded-2xl sm:max-w-xl">
          <DialogHeader>
            <DialogTitle>Xem trước System Prompt</DialogTitle>
          </DialogHeader>
          <pre className="max-h-96 overflow-auto whitespace-pre-wrap rounded-xl border bg-surface-2/60 p-4 font-mono text-xs leading-relaxed">{content}</pre>
        </DialogContent>
      </Dialog>
    </div>
  );
}

function GuardrailsTab({ canEdit }: { canEdit: boolean }) {
  const list = useResourceList(guardrailsService);
  const { update, create } = useResourceMutations(guardrailsService, { entity: "Guardrail" });
  const [editing, setEditing] = useState<Guardrail | null | undefined>(undefined);
  const [form, setForm] = useState<Guardrail>({
    id: "",
    category: "care",
    name: "",
    description: "",
    response: "",
    keywords: [],
    enabled: true,
  });
  const [kwText, setKwText] = useState("");

  useEffect(() => {
    if (editing === undefined) return;
    if (editing) {
      setForm(editing);
      setKwText(editing.keywords.join(", "));
    } else {
      setForm({ id: uid("gr"), category: "care", name: "", description: "", response: "", keywords: [], enabled: true });
      setKwText("");
    }
  }, [editing]);

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.name.trim() || !form.response.trim()) {
      toast.error("Vui lòng nhập tên quy tắc và câu phản hồi");
      return;
    }
    const payload: Guardrail = {
      ...form,
      keywords: kwText
        .split(",")
        .map((s) => s.trim())
        .filter(Boolean),
    };
    if (editing) {
      update.mutate({ id: payload.id, patch: payload, label: payload.name }, { onSuccess: () => setEditing(undefined) });
    } else {
      create.mutate(payload, { onSuccess: () => setEditing(undefined) });
    }
  };

  return (
    <div className="space-y-4">
      <div className="flex justify-end">
        {canEdit && (
          <Button onClick={() => setEditing(null)}>
            <Plus /> Thêm quy tắc Guardrail
          </Button>
        )}
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        {(list.data ?? []).map((g) => (
          <div key={g.id} className="card-surface flex flex-col justify-between p-5">
            <div>
              <div className="flex items-start justify-between gap-3">
                <div>
                  <Badge variant="outline" className="mb-2 text-[11px]">
                    {GUARDRAIL_CAT_LABEL[g.category]}
                  </Badge>
                  <h4 className="font-semibold text-foreground">{g.name}</h4>
                </div>
                <Switch
                  checked={g.enabled}
                  disabled={!canEdit}
                  onCheckedChange={(checked) => update.mutate({ id: g.id, patch: { enabled: checked }, before: String(g.enabled), label: g.name })}
                />
              </div>
              <p className="mt-2 text-xs text-muted-foreground">{g.description}</p>
              <div className="mt-3 rounded-lg bg-surface-2/60 p-3 text-xs">
                <p className="font-medium text-foreground">Phản hồi mẫu:</p>
                <p className="mt-1 text-muted-foreground">{g.response}</p>
              </div>
              <div className="mt-3 flex flex-wrap gap-1.5">
                {g.keywords.map((kw) => (
                  <span key={kw} className="rounded-md border bg-card px-2 py-0.5 text-[11px] text-muted-foreground">
                    {kw}
                  </span>
                ))}
              </div>
            </div>
            {canEdit && (
              <div className="mt-4 flex justify-end border-t pt-3">
                <Button size="sm" variant="outline" onClick={() => setEditing(g)}>
                  Chỉnh sửa
                </Button>
              </div>
            )}
          </div>
        ))}
      </div>

      <FormDialog open={editing !== undefined} onOpenChange={(o) => !o && setEditing(undefined)} title={editing ? `Sửa · ${editing.name}` : "Thêm quy tắc Guardrail"} onSubmit={submit}>
        <div className="grid gap-4">
          <Field label="Nhóm quy tắc">
            <Select value={form.category} onValueChange={(v) => setForm({ ...form, category: v as Guardrail["category"] })}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {Object.entries(GUARDRAIL_CAT_LABEL).map(([k, v]) => (
                  <SelectItem key={k} value={k}>
                    {v}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </Field>
          <Field label="Tên quy tắc">
            <Input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
          </Field>
          <Field label="Mô tả">
            <Textarea rows={2} value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} />
          </Field>
          <Field label="Câu phản hồi khi kích hoạt">
            <Textarea rows={3} value={form.response} onChange={(e) => setForm({ ...form, response: e.target.value })} />
          </Field>
          <Field label="Từ khoá kích hoạt (phân cách bằng dấu phẩy)">
            <Input value={kwText} onChange={(e) => setKwText(e.target.value)} placeholder="mèo, chó, độc tính..." />
          </Field>
        </div>
      </FormDialog>
    </div>
  );
}

function ActionTagsTab({ canEdit }: { canEdit: boolean }) {
  const list = useResourceList(actionTagsService);
  const { update } = useResourceMutations(actionTagsService, { entity: "Action Tag" });
  const [editing, setEditing] = useState<ActionTag | null>(null);
  const [kw, setKw] = useState("");
  const [intent, setIntent] = useState("");
  const [condition, setCondition] = useState("");

  useEffect(() => {
    if (!editing) return;
    setKw(editing.keywords.join(", "));
    setIntent(editing.intent);
    setCondition(editing.condition);
  }, [editing]);

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editing) return;
    update.mutate(
      {
        id: editing.id,
        patch: {
          keywords: kw
            .split(",")
            .map((s) => s.trim())
            .filter(Boolean),
          intent,
          condition,
        },
        label: editing.tag,
      },
      { onSuccess: () => setEditing(null) },
    );
  };

  return (
    <div className="grid gap-4 md:grid-cols-2">
      {(list.data ?? []).map((t) => (
        <div key={t.id} className="card-surface p-5">
          <div className="flex items-start justify-between gap-3">
            <div className="flex items-center gap-2">
              <span className="grid size-9 place-items-center rounded-lg bg-accent text-forest">
                <Tag className="size-4" />
              </span>
              <div>
                <p className="font-mono text-sm font-semibold text-forest">{t.tag}</p>
                <p className="text-xs text-muted-foreground">{t.enabled ? "Đang bật" : "Đã tắt"}</p>
              </div>
            </div>
            <Switch checked={t.enabled} disabled={!canEdit} onCheckedChange={(enabled) => update.mutate({ id: t.id, patch: { enabled }, label: t.tag })} />
          </div>
          <div className="mt-4 space-y-2 text-xs">
            <div>
              <span className="font-semibold text-foreground">Ý định (Intent): </span>
              <span className="text-muted-foreground">{t.intent}</span>
            </div>
            <div>
              <span className="font-semibold text-foreground">Điều kiện kích hoạt: </span>
              <span className="text-muted-foreground">{t.condition}</span>
            </div>
            <div className="flex flex-wrap gap-1.5 pt-1">
              {t.keywords.map((k) => (
                <span key={k} className="rounded-md bg-surface-2 px-2 py-0.5 text-[11px] font-medium text-foreground">
                  {k}
                </span>
              ))}
            </div>
          </div>
          {canEdit && (
            <div className="mt-4 flex justify-end border-t pt-3">
              <Button size="sm" variant="outline" onClick={() => setEditing(t)}>
                Cấu hình
              </Button>
            </div>
          )}
        </div>
      ))}

      <FormDialog open={!!editing} onOpenChange={(o) => !o && setEditing(null)} title={`Cấu hình ${editing?.tag ?? ""}`} onSubmit={submit}>
        <div className="grid gap-4">
          <Field label="Từ khoá kích hoạt (cách nhau dấu phẩy)">
            <Input value={kw} onChange={(e) => setKw(e.target.value)} />
          </Field>
          <Field label="Mô tả ý định (Intent)">
            <Textarea rows={2} value={intent} onChange={(e) => setIntent(e.target.value)} />
          </Field>
          <Field label="Điều kiện kích hoạt">
            <Textarea rows={2} value={condition} onChange={(e) => setCondition(e.target.value)} />
          </Field>
        </div>
      </FormDialog>
    </div>
  );
}

interface SandboxResult {
  userText: string;
  intent: string;
  matchedGuardrails: string[];
  triggeredTags: string[];
  response: string;
}

function TestingSandboxTab() {
  const guardrails = useResourceList(guardrailsService);
  const tags = useResourceList(actionTagsService);
  const settings = useSingleton(assistantSettingsService);
  const [input, setInput] = useState("");
  const [history, setHistory] = useState<SandboxResult[]>([]);

  const SAMPLES = [
    "Mèo nhà mình ăn phải lá Trầu bà có sao không?",
    "Cây bị đốm lá nên mua thuốc hay phân bón nào?",
    "Lá cây trầu bà đắp chữa ho được không?",
    "Tạo lịch tưới nước cho cây Monstera",
    "Giá vàng hôm nay bao nhiêu?",
  ];

  const runTest = (msgText?: string) => {
    const text = (msgText ?? input).trim();
    if (!text) return;
    const lower = text.toLowerCase();

    const activeGr = (guardrails.data ?? []).filter((g) => g.enabled);
    const matchedGr = activeGr.filter((g) => g.keywords.some((k) => lower.includes(k.toLowerCase())));
    const activeTags = (tags.data ?? []).filter((t) => t.enabled);
    const matchedTags = activeTags.filter((t) => t.keywords.some((k) => lower.includes(k.toLowerCase())));

    let intent = "Tư vấn chăm sóc cây tổng quát";
    if (matchedGr.some((g) => g.category === "medical")) intent = "Yêu cầu y tế ngoài phạm vi (Cấm)";
    else if (matchedGr.some((g) => g.category === "scope")) intent = "Chủ đề ngoài phạm vi Floria";
    else if (matchedGr.some((g) => g.category === "toxicity")) intent = "Cảnh báo an toàn thú cưng / trẻ nhỏ";
    else if (matchedTags.some((t) => t.tag === "[RECOMMEND_PRODUCT]")) intent = "Nhu cầu tìm mua vật tư / phân bón";
    else if (matchedTags.some((t) => t.tag === "[CARE_SCHEDULE]")) intent = "Thiết lập lịch chăm sóc cây";

    let response = "";
    const blocked = matchedGr.find((g) => g.category === "medical" || g.category === "scope");
    if (blocked) {
      response = blocked.response;
    } else if (matchedGr.length > 0) {
      response = matchedGr.map((g) => g.response).join(" ");
    } else {
      response = `(${settings.data?.name ?? "Floria"} · Mô phỏng): Dựa trên mô tả "${text}", hãy kiểm tra độ ẩm đất mặt trên 2–3cm trước khi tưới và đảm bảo ánh sáng gián tiếp.`;
    }

    if (!blocked && matchedTags.length > 0) {
      response += ` ${matchedTags.map((t) => t.tag).join(" ")}`;
    }

    setHistory((h) => [
      {
        userText: text,
        intent,
        matchedGuardrails: matchedGr.map((g) => g.name),
        triggeredTags: blocked ? [] : matchedTags.map((t) => t.tag),
        response,
      },
      ...h,
    ]);
    if (!msgText) setInput("");
  };

  return (
    <div className="grid gap-5 lg:grid-cols-[1fr_1.1fr]">
      <div className="card-surface flex flex-col justify-between p-5">
        <div>
          <div className="mb-3 flex items-center justify-between">
            <h3 className="text-base font-semibold">Kiểm thử hội thoại</h3>
            <DemoBadge label="DEMO · Mô phỏng quy tắc" />
          </div>
          <p className="text-xs text-muted-foreground">Kiểm tra cách Guardrails và Action Tags phản ứng với câu hỏi của người dùng dựa trên quy tắc hiện tại.</p>
          <div className="mt-4 flex flex-wrap gap-1.5">
            {SAMPLES.map((s) => (
              <button key={s} type="button" onClick={() => runTest(s)} className="rounded-lg border bg-surface-2/60 px-2.5 py-1.5 text-left text-xs transition hover:border-sage">
                {s}
              </button>
            ))}
          </div>
        </div>

        <form
          onSubmit={(e) => {
            e.preventDefault();
            runTest();
          }}
          className="mt-6 flex gap-2"
        >
          <Input value={input} onChange={(e) => setInput(e.target.value)} placeholder="Nhập câu hỏi thử nghiệm…" />
          <Button type="submit">
            <Send /> Gửi thử
          </Button>
        </form>
      </div>

      <div className="card-surface p-5">
        <h3 className="mb-3 text-base font-semibold">Kết quả phân tích mô phỏng</h3>
        {history.length === 0 ? (
          <div className="rounded-xl border border-dashed bg-surface-2/40 p-8 text-center text-xs text-muted-foreground">
            Chọn một câu hỏi mẫu hoặc nhập nội dung ở khung bên trái để kiểm tra Guardrails & Action Tags.
          </div>
        ) : (
          <div className="max-h-[460px] space-y-4 overflow-y-auto pr-1">
            {history.map((item, idx) => (
              <div key={idx} className="rounded-xl border bg-surface-2/40 p-4 text-xs">
                <p className="font-semibold text-foreground">Người dùng: “{item.userText}”</p>
                <div className="mt-2.5 grid gap-2 sm:grid-cols-3">
                  <div className="rounded-lg bg-card p-2.5">
                    <p className="text-[11px] text-muted-foreground">Intent nhận diện</p>
                    <p className="mt-0.5 font-medium text-foreground">{item.intent}</p>
                  </div>
                  <div className="rounded-lg bg-card p-2.5">
                    <p className="text-[11px] text-muted-foreground">Guardrails khớp</p>
                    <p className="mt-0.5 font-medium text-warning">{item.matchedGuardrails.length ? item.matchedGuardrails.join(", ") : "Không có"}</p>
                  </div>
                  <div className="rounded-lg bg-card p-2.5">
                    <p className="text-[11px] text-muted-foreground">Action Tags</p>
                    <p className="mt-0.5 font-mono font-medium text-leaf">{item.triggeredTags.length ? item.triggeredTags.join(" ") : "Không kích hoạt"}</p>
                  </div>
                </div>
                <div className="mt-2.5 rounded-lg bg-card p-3">
                  <div className="mb-1 flex items-center gap-1.5 font-medium text-forest">
                    <Bot className="size-3.5" /> Phản hồi mô phỏng
                  </div>
                  <p className="text-sm leading-relaxed text-foreground">{item.response}</p>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

function ReportsTab({ canEdit }: { canEdit: boolean }) {
  const list = useResourceList(reportsService);
  const { update } = useResourceMutations(reportsService, { entity: "Báo cáo hội thoại" });
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("all");
  const [selected, setSelected] = useState<ConversationReport | null>(null);
  const [note, setNote] = useState("");

  useEffect(() => {
    setNote(selected?.note ?? "");
  }, [selected]);

  const rows = useMemo(() => {
    const s = search.toLowerCase();
    return (list.data ?? []).filter(
      (r) => (!s || r.userName.toLowerCase().includes(s) || r.preview.toLowerCase().includes(s)) && (status === "all" || r.status === status),
    );
  }, [list.data, search, status]);

  const columns: ColumnDef<ConversationReport, unknown>[] = [
    { accessorKey: "userName", header: "Người dùng", cell: ({ getValue }) => <span className="font-medium">{getValue() as string}</span> },
    { accessorKey: "preview", header: "Nội dung hội thoại", cell: ({ getValue }) => <span className="line-clamp-1 max-w-xs text-xs text-muted-foreground">{getValue() as string}</span> },
    { accessorKey: "reason", header: "Lý do báo cáo" },
    { accessorKey: "at", header: "Thời gian", cell: ({ getValue }) => formatDateTime(getValue() as string) },
    { accessorKey: "status", header: "Trạng thái", cell: ({ getValue }) => <StatusBadge status={getValue() as string} /> },
  ];

  const handleStatus = (next: ConversationReport["status"]) => {
    if (!selected) return;
    update.mutate(
      { id: selected.id, patch: { status: next, note }, before: selected.status, label: selected.userName },
      { onSuccess: (updated) => setSelected(updated) },
    );
  };

  return (
    <>
      <DataTable
        columns={columns}
        data={rows}
        loading={list.isLoading}
        onRowClick={setSelected}
        toolbar={
          <>
            <SearchInput value={search} onChange={setSearch} placeholder="Tìm người dùng hoặc nội dung…" />
            <FilterSelect
              value={status}
              onChange={setStatus}
              allLabel="Mọi trạng thái"
              options={[
                { value: "pending", label: statusLabel("pending") },
                { value: "reviewed", label: statusLabel("reviewed") },
                { value: "dismissed", label: statusLabel("dismissed") },
              ]}
            />
          </>
        }
      />

      <DetailDrawer
        open={!!selected}
        onOpenChange={(o) => !o && setSelected(null)}
        title={selected ? `Báo cáo · ${selected.userName}` : ""}
        description={selected ? `${selected.reason} · ${formatDateTime(selected.at)}` : undefined}
        footer={
          selected && canEdit ? (
            <>
              <Button variant="outline" onClick={() => handleStatus("dismissed")}>
                Bỏ qua
              </Button>
              <Button onClick={() => handleStatus("reviewed")}>
                <Check /> Đánh dấu đã xem xét
              </Button>
            </>
          ) : undefined
        }
      >
        {selected && (
          <>
            <DetailSection title="Trạng thái">
              <InfoGrid items={[{ label: "Trạng thái", value: <StatusBadge status={selected.status} /> }, { label: "Lý do", value: selected.reason }]} />
            </DetailSection>
            <DetailSection title="Đoạn hội thoại">
              <div className="space-y-2.5">
                {selected.transcript.map((m, i) => (
                  <div key={i} className={`rounded-xl p-3 text-sm ${m.from === "user" ? "bg-surface-2/70" : "border bg-card"}`}>
                    <p className="mb-1 flex items-center gap-1.5 text-[11px] font-semibold text-muted-foreground">
                      {m.from === "user" ? "Người dùng" : <><Sparkles className="size-3 text-leaf" /> Floria Assistant</>}
                    </p>
                    <p>{m.text}</p>
                  </div>
                ))}
              </div>
            </DetailSection>
            <DetailSection title="Ghi chú xử lý">
              <Textarea rows={3} disabled={!canEdit} value={note} onChange={(e) => setNote(e.target.value)} placeholder="Ghi chú của botanist / quản trị viên…" />
            </DetailSection>
          </>
        )}
      </DetailDrawer>
    </>
  );
}
