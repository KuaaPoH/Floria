"use client";

import { useEffect, useMemo, useState } from "react";
import { useSearchParams } from "next/navigation";
import type { ColumnDef } from "@tanstack/react-table";
import {
  AlertTriangle,
  ArrowDown,
  ArrowLeft,
  ArrowUp,
  BookOpen,
  CloudRain,
  Eye,
  Info,
  Pencil,
  Plus,
  Quote,
  Save,
  Sun,
  Trash2,
  UploadCloud,
} from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { PageHeader } from "@/components/shared/page-header";
import { SmartImage } from "@/components/shared/smart-image";
import { DataTable } from "@/components/shared/data-table";
import { SearchInput } from "@/components/shared/search-input";
import { FilterSelect } from "@/components/shared/filter-select";
import { StatusBadge, statusLabel } from "@/components/shared/status-badge";
import { FormDialog } from "@/components/shared/form-dialog";
import { ConfirmDialog } from "@/components/shared/confirm-dialog";
import { Field } from "@/components/shared/field";
import { ImageUploader } from "@/components/shared/image-uploader";
import { useResourceList, useResourceMutations } from "@/hooks/use-resource";
import { useAuthStore } from "@/stores/auth-store";
import { usePermission } from "@/stores/rbac-store";
import { articlesService, weatherRulesService } from "@/services";
import { ARTICLE_CATEGORIES } from "@/mocks/content";
import { IMAGES } from "@/mocks/images";
import { formatDate, formatNumber } from "@/lib/format";
import { uid } from "@/lib/id";
import type { Article, ArticleBlock, BlockType, WeatherRule } from "@/types";

const BLOCK_LABELS: Record<BlockType, string> = {
  heading: "Tiêu đề mục",
  paragraph: "Đoạn văn",
  image: "Hình ảnh",
  quote: "Trích dẫn",
  bullets: "Danh sách gạch đầu dòng",
  numbered: "Danh sách đánh số",
  info: "Hộp thông tin",
  warning: "Hộp cảnh báo",
};

const WEATHER_CONDITIONS: Record<WeatherRule["condition"], string> = {
  rain: "Trời mưa",
  sunny: "Nắng đẹp",
  humid: "Nồm ẩm",
  cold: "Rét đậm",
  hot: "Nắng gắt",
};

export default function HandbookPage() {
  const searchParams = useSearchParams();
  const initialArticleId = searchParams.get("id");
  const [tab, setTab] = useState("articles");
  const canCreate = usePermission("content", "create");
  const canEdit = usePermission("content", "edit");
  const canDelete = usePermission("content", "delete");
  const canPublish = usePermission("content", "publish");

  return (
    <>
      <PageHeader title="Cẩm nang & Mẹo thời tiết" description="Biên tập bài viết cẩm nang theo khối (block-based) và cấu hình mẹo chăm sóc cây theo thời tiết." />
      <Tabs value={tab} onValueChange={setTab}>
        <TabsList className="mb-5">
          <TabsTrigger value="articles">Bài viết cẩm nang</TabsTrigger>
          <TabsTrigger value="weather">Mẹo theo thời tiết</TabsTrigger>
        </TabsList>
        <TabsContent value="articles">
          <ArticlesTab initialArticleId={initialArticleId} canCreate={canCreate} canEdit={canEdit} canDelete={canDelete} canPublish={canPublish} />
        </TabsContent>
        <TabsContent value="weather">
          <WeatherTipsTab canCreate={canCreate} canEdit={canEdit} canDelete={canDelete} />
        </TabsContent>
      </Tabs>
    </>
  );
}

function ArticlesTab({
  initialArticleId,
  canCreate,
  canEdit,
  canDelete,
  canPublish,
}: {
  initialArticleId: string | null;
  canCreate: boolean;
  canEdit: boolean;
  canDelete: boolean;
  canPublish: boolean;
}) {
  const adminName = useAuthStore((s) => s.session?.name ?? "TS. Nguyễn Thảo");
  const list = useResourceList(articlesService);
  const { create, update, remove } = useResourceMutations(articlesService, { entity: "Bài viết" });

  const [search, setSearch] = useState("");
  const [cat, setCat] = useState("all");
  const [status, setStatus] = useState("all");
  const [editing, setEditing] = useState<Article | null>(null);
  const [preview, setPreview] = useState<Article | null>(null);
  const [del, setDel] = useState<Article | null>(null);

  useEffect(() => {
    if (!initialArticleId || !list.data) return;
    const found = list.data.find((a) => a.id === initialArticleId);
    if (found) setEditing(found);
  }, [initialArticleId, list.data]);

  const rows = useMemo(() => {
    const s = search.toLowerCase();
    return (list.data ?? []).filter(
      (a) => (!s || a.title.toLowerCase().includes(s) || a.author.toLowerCase().includes(s)) && (cat === "all" || a.category === cat) && (status === "all" || a.status === status),
    );
  }, [list.data, search, cat, status]);

  const createNew = () => {
    setEditing({
      id: "",
      title: "",
      excerpt: "",
      category: ARTICLE_CATEGORIES[0],
      cover: IMAGES.bannerHome,
      author: adminName,
      status: "draft",
      publishedAt: "",
      updatedAt: new Date().toISOString(),
      views: 0,
      blocks: [{ id: uid("blk"), type: "paragraph", text: "" }],
    });
  };

  const columns: ColumnDef<Article, unknown>[] = [
    {
      accessorKey: "title",
      header: "Bài viết",
      cell: ({ row }) => (
        <div className="flex items-center gap-3">
          <SmartImage
            src={row.original.cover}
            alt={row.original.title}
            className="h-10 w-14 shrink-0 rounded-lg border"
            fallback={
              <span className="grid h-10 w-14 shrink-0 place-items-center rounded-lg bg-accent text-forest">
                <BookOpen className="size-4" />
              </span>
            }
          />
          <div>
            <p className="font-medium">{row.original.title}</p>
            <p className="text-xs text-muted-foreground">
              {row.original.category} · {row.original.author}
            </p>
          </div>
        </div>
      ),
    },
    { accessorKey: "views", header: "Lượt xem", cell: ({ getValue }) => <span className="tabular">{formatNumber(getValue() as number)}</span> },
    { accessorKey: "updatedAt", header: "Cập nhật", cell: ({ getValue }) => formatDate(getValue() as string) },
    { accessorKey: "status", header: "Trạng thái", cell: ({ getValue }) => <StatusBadge status={getValue() as string} /> },
    {
      id: "a",
      header: "",
      enableSorting: false,
      cell: ({ row }) => (
        <div className="flex justify-end gap-1" onClick={(e) => e.stopPropagation()}>
          <Button size="icon-sm" variant="ghost" onClick={() => setPreview(row.original)} title="Xem trước">
            <Eye />
          </Button>
          {canEdit && (
            <Button size="icon-sm" variant="ghost" onClick={() => setEditing(row.original)} title="Biên tập">
              <Pencil />
            </Button>
          )}
          {canDelete && (
            <Button size="icon-sm" variant="ghost" className="text-danger" onClick={() => setDel(row.original)} title="Xoá">
              <Trash2 />
            </Button>
          )}
        </div>
      ),
    },
  ];

  const saveArticle = (art: Article, nextStatus: "draft" | "published") => {
    if (!art.title.trim()) {
      toast.error("Vui lòng nhập tiêu đề bài viết");
      return;
    }
    const now = new Date().toISOString();
    const payload: Article = {
      ...art,
      id: art.id || uid("art"),
      status: nextStatus,
      publishedAt: nextStatus === "published" ? art.publishedAt || now : art.publishedAt,
      updatedAt: now,
    };
    if (art.id) {
      update.mutate({ id: payload.id, patch: payload, label: payload.title }, { onSuccess: () => setEditing(null) });
    } else {
      create.mutate(payload, { onSuccess: () => setEditing(null) });
    }
  };

  const categories = useMemo(() => {
    const set = new Set<string>(ARTICLE_CATEGORIES);
    for (const a of list.data ?? []) {
      if (a.category) set.add(a.category);
    }
    return Array.from(set);
  }, [list.data]);

  if (editing) {
    return (
      <>
        <ArticleEditor
          article={editing}
          canPublish={canPublish}
          onCancel={() => setEditing(null)}
          onPreview={(a) => setPreview(a)}
          onSave={(a, st) => saveArticle(a, st)}
        />
        <ArticlePreviewDialog article={preview} onClose={() => setPreview(null)} />
      </>
    );
  }

  return (
    <>
      <DataTable
        columns={columns}
        data={rows}
        loading={list.isLoading}
        onRowClick={(a) => (canEdit ? setEditing(a) : setPreview(a))}
        toolbar={
          <>
            <SearchInput value={search} onChange={setSearch} placeholder="Tìm tiêu đề hoặc tác giả…" />
            <FilterSelect value={cat} onChange={setCat} allLabel="Mọi chuyên mục" options={categories.map((c) => ({ value: c, label: c }))} />
            <FilterSelect
              value={status}
              onChange={setStatus}
              allLabel="Mọi trạng thái"
              options={[
                { value: "published", label: statusLabel("published") },
                { value: "draft", label: statusLabel("draft") },
              ]}
            />
            {canCreate && (
              <Button className="ml-auto" onClick={createNew}>
                <Plus /> Viết bài mới
              </Button>
            )}
          </>
        }
      />

      <ArticlePreviewDialog article={preview} onClose={() => setPreview(null)} />
      <ConfirmDialog
        open={!!del}
        onOpenChange={(o) => !o && setDel(null)}
        title={`Xoá "${del?.title}"?`}
        tone="danger"
        confirmLabel="Xoá"
        onConfirm={() => del && remove.mutate({ id: del.id, label: del.title })}
      />
    </>
  );
}

function ArticleEditor({
  article,
  canPublish,
  onCancel,
  onPreview,
  onSave,
}: {
  article: Article;
  canPublish: boolean;
  onCancel: () => void;
  onPreview: (a: Article) => void;
  onSave: (a: Article, status: "draft" | "published") => void;
}) {
  const [form, setForm] = useState<Article>(article);

  const addBlock = (type: BlockType) => {
    const blk: ArticleBlock = {
      id: uid("blk"),
      type,
      text: "",
      ...(type === "bullets" || type === "numbered" ? { items: ["Mục 1"] } : {}),
      ...(type === "image" ? { src: IMAGES.monstera } : {}),
    };
    setForm((f) => ({ ...f, blocks: [...f.blocks, blk] }));
  };

  const updateBlock = (id: string, patch: Partial<ArticleBlock>) => {
    setForm((f) => ({ ...f, blocks: f.blocks.map((b) => (b.id === id ? { ...b, ...patch } : b)) }));
  };

  const moveBlock = (idx: number, dir: -1 | 1) => {
    const target = idx + dir;
    if (target < 0 || target >= form.blocks.length) return;
    const next = [...form.blocks];
    [next[idx], next[target]] = [next[target], next[idx]];
    setForm({ ...form, blocks: next });
  };

  const removeBlock = (id: string) => {
    setForm((f) => ({ ...f, blocks: f.blocks.filter((b) => b.id !== id) }));
  };

  return (
    <div className="grid gap-5 lg:grid-cols-[1.6fr_1fr]">
      <div className="card-surface p-5">
        <div className="mb-4 flex items-center justify-between border-b pb-3">
          <div className="flex items-center gap-2">
            <BookOpen className="size-4 text-leaf" />
            <h3 className="text-base font-semibold">{form.id ? "Chỉnh sửa bài viết" : "Soạn bài viết mới"}</h3>
          </div>
          <Button type="button" variant="outline" size="sm" onClick={onCancel}>
            <ArrowLeft className="size-4" /> Quay lại
          </Button>
        </div>

        <div className="space-y-4">
          <Field label="Tiêu đề bài viết">
            <Input value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} placeholder="VD: Cách tưới cây trong nhà mùa mưa" />
          </Field>
          <Field label="Tóm tắt ngắn">
            <Textarea rows={2} value={form.excerpt} onChange={(e) => setForm({ ...form, excerpt: e.target.value })} />
          </Field>

          <div className="pt-2">
            <div className="mb-2 flex flex-wrap items-center justify-between gap-2">
              <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">Nội dung theo khối ({form.blocks.length} khối)</p>
              <Select onValueChange={(v) => addBlock(v as BlockType)}>
                <SelectTrigger className="h-8 w-48 text-xs">
                  <SelectValue placeholder="+ Thêm khối nội dung" />
                </SelectTrigger>
                <SelectContent>
                  {Object.entries(BLOCK_LABELS).map(([k, label]) => (
                    <SelectItem key={k} value={k}>
                      + {label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-3">
              {form.blocks.map((b, idx) => (
                <div key={b.id} className="rounded-xl border bg-surface-2/40 p-3.5">
                  <div className="mb-2 flex items-center justify-between">
                    <span className="text-xs font-semibold text-forest">{BLOCK_LABELS[b.type]}</span>
                    <div className="flex gap-1">
                      <Button type="button" size="icon-sm" variant="ghost" disabled={idx === 0} onClick={() => moveBlock(idx, -1)}>
                        <ArrowUp className="size-3.5" />
                      </Button>
                      <Button type="button" size="icon-sm" variant="ghost" disabled={idx === form.blocks.length - 1} onClick={() => moveBlock(idx, 1)}>
                        <ArrowDown className="size-3.5" />
                      </Button>
                      <Button type="button" size="icon-sm" variant="ghost" className="text-danger" onClick={() => removeBlock(b.id)}>
                        <Trash2 className="size-3.5" />
                      </Button>
                    </div>
                  </div>
                  {b.type === "image" ? (
                    <div className="space-y-2">
                      <ImageUploader value={b.src} aspect="wide" onChange={(src) => updateBlock(b.id, { src })} />
                      <Input value={b.text} onChange={(e) => updateBlock(b.id, { text: e.target.value })} placeholder="Chú thích ảnh…" />
                    </div>
                  ) : b.type === "bullets" || b.type === "numbered" ? (
                    <Textarea
                      rows={3}
                      value={(b.items ?? []).join("\n")}
                      onChange={(e) => updateBlock(b.id, { items: e.target.value.split("\n") })}
                      placeholder="Mỗi dòng là một mục…"
                    />
                  ) : (
                    <Textarea rows={b.type === "heading" ? 1 : 3} value={b.text} onChange={(e) => updateBlock(b.id, { text: e.target.value })} placeholder={`Nhập ${BLOCK_LABELS[b.type].toLowerCase()}…`} />
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      <div className="space-y-4">
        <div className="card-surface space-y-4 p-5">
          <Field label="Ảnh bìa">
            <ImageUploader value={form.cover} aspect="wide" onChange={(cover) => setForm({ ...form, cover })} />
          </Field>
          <Field label="Chuyên mục">
            <Input
              value={form.category}
              onChange={(e) => setForm({ ...form, category: e.target.value })}
              placeholder="VD: Mẹo tưới cây, Sâu bệnh, Ánh sáng..."
            />
          </Field>
          <Field label="Tác giả">
            <Input value={form.author} onChange={(e) => setForm({ ...form, author: e.target.value })} />
          </Field>
          <div className="flex flex-col gap-2 pt-2">
            <Button type="button" variant="outline" onClick={() => onPreview(form)}>
              <Eye /> Xem trước bài viết
            </Button>
            <Button type="button" variant="soft" onClick={() => onSave(form, "draft")}>
              <Save /> Lưu nháp
            </Button>
            {canPublish && (
              <Button type="button" onClick={() => onSave(form, "published")}>
                <UploadCloud /> Xuất bản
              </Button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function ArticlePreviewDialog({ article, onClose }: { article: Article | null; onClose: () => void }) {
  return (
    <Dialog open={!!article} onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="max-h-[85vh] overflow-y-auto rounded-2xl sm:max-w-2xl">
        {article && (
          <>
            <DialogHeader>
              <DialogTitle>{article.title}</DialogTitle>
            </DialogHeader>
            <p className="text-xs text-muted-foreground">
              {article.category} · {article.author}
            </p>
            {article.cover && <img src={article.cover} alt="" className="mt-2 aspect-[2/1] w-full rounded-xl object-cover" />}
            <p className="mt-3 text-sm italic text-muted-foreground">{article.excerpt}</p>
            <div className="mt-4 space-y-3">
              {article.blocks.map((b) => {
                if (b.type === "heading") return <h3 key={b.id} className="text-lg font-semibold">{b.text}</h3>;
                if (b.type === "quote")
                  return (
                    <blockquote key={b.id} className="flex gap-2 border-l-4 border-leaf bg-surface-2/60 p-3 text-sm italic">
                      <Quote className="size-4 shrink-0 text-leaf" />
                      {b.text}
                    </blockquote>
                  );
                if (b.type === "info")
                  return (
                    <div key={b.id} className="flex gap-2 rounded-xl bg-info-soft p-3 text-sm text-info">
                      <Info className="size-4 shrink-0" />
                      {b.text}
                    </div>
                  );
                if (b.type === "warning")
                  return (
                    <div key={b.id} className="flex gap-2 rounded-xl bg-warning-soft p-3 text-sm text-warning">
                      <AlertTriangle className="size-4 shrink-0" />
                      {b.text}
                    </div>
                  );
                if (b.type === "image")
                  return (
                    <figure key={b.id}>
                      {b.src && <img src={b.src} alt="" className="w-full rounded-xl object-cover" />}
                      {b.text && <figcaption className="mt-1 text-center text-xs text-muted-foreground">{b.text}</figcaption>}
                    </figure>
                  );
                if (b.type === "bullets")
                  return (
                    <ul key={b.id} className="list-disc space-y-1 pl-5 text-sm">
                      {(b.items ?? []).filter(Boolean).map((it, i) => <li key={i}>{it}</li>)}
                    </ul>
                  );
                if (b.type === "numbered")
                  return (
                    <ol key={b.id} className="list-decimal space-y-1 pl-5 text-sm">
                      {(b.items ?? []).filter(Boolean).map((it, i) => <li key={i}>{it}</li>)}
                    </ol>
                  );
                return <p key={b.id} className="text-sm leading-relaxed">{b.text}</p>;
              })}
            </div>
          </>
        )}
      </DialogContent>
    </Dialog>
  );
}

function WeatherTipsTab({ canCreate, canEdit, canDelete }: { canCreate: boolean; canEdit: boolean; canDelete: boolean }) {
  const list = useResourceList(weatherRulesService);
  const { create, update, remove } = useResourceMutations(weatherRulesService, { entity: "Mẹo thời tiết" });
  const [editing, setEditing] = useState<WeatherRule | null | undefined>(undefined);
  const [del, setDel] = useState<WeatherRule | null>(null);
  const [form, setForm] = useState<WeatherRule>({
    id: "",
    name: "",
    condition: "rain",
    tempMin: 20,
    tempMax: 32,
    humidityMin: 70,
    humidityMax: 100,
    tip: "",
    active: true,
  });

  useEffect(() => {
    if (editing === undefined) return;
    setForm(
      editing ?? {
        id: uid("wr"),
        name: "",
        condition: "rain",
        tempMin: 20,
        tempMax: 32,
        humidityMin: 70,
        humidityMax: 100,
        tip: "",
        active: true,
      },
    );
  }, [editing]);

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.name.trim() || !form.tip.trim()) {
      toast.error("Vui lòng nhập tên quy tắc và nội dung lời khuyên");
      return;
    }
    if (editing) update.mutate({ id: form.id, patch: form, label: form.name }, { onSuccess: () => setEditing(undefined) });
    else create.mutate(form, { onSuccess: () => setEditing(undefined) });
  };

  return (
    <>
      {canCreate && (
        <div className="mb-4 flex justify-end">
          <Button onClick={() => setEditing(null)}>
            <Plus /> Thêm quy tắc thời tiết
          </Button>
        </div>
      )}
      <div className="grid gap-4 md:grid-cols-2">
        {(list.data ?? []).map((r) => (
          <div key={r.id} className="card-surface p-5">
            <div className="flex items-start justify-between gap-2">
              <div className="flex items-center gap-2.5">
                <span className="grid size-9 place-items-center rounded-lg bg-info-soft text-info">
                  {r.condition === "sunny" || r.condition === "hot" ? <Sun className="size-4" /> : <CloudRain className="size-4" />}
                </span>
                <div>
                  <h4 className="font-semibold">{r.name}</h4>
                  <p className="text-xs text-muted-foreground">
                    {WEATHER_CONDITIONS[r.condition]} · {r.tempMin}°–{r.tempMax}°C · Độ ẩm {r.humidityMin}%–{r.humidityMax}%
                  </p>
                </div>
              </div>
              <Switch checked={r.active} disabled={!canEdit} onCheckedChange={(active) => update.mutate({ id: r.id, patch: { active }, label: r.name })} />
            </div>
            <p className="mt-3 rounded-xl bg-surface-2/60 p-3 text-sm">{r.tip}</p>
            {(canEdit || canDelete) && (
              <div className="mt-3 flex justify-end gap-1">
                {canEdit && (
                  <Button size="sm" variant="ghost" onClick={() => setEditing(r)}>
                    <Pencil /> Sửa
                  </Button>
                )}
                {canDelete && (
                  <Button size="sm" variant="ghost" className="text-danger" onClick={() => setDel(r)}>
                    <Trash2 /> Xoá
                  </Button>
                )}
              </div>
            )}
          </div>
        ))}
      </div>

      <FormDialog open={editing !== undefined} onOpenChange={(o) => !o && setEditing(undefined)} title={editing ? `Sửa · ${editing.name}` : "Thêm quy tắc thời tiết"} onSubmit={submit}>
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Tên quy tắc" className="sm:col-span-2">
            <Input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
          </Field>
          <Field label="Điều kiện thời tiết">
            <Select value={form.condition} onValueChange={(v) => setForm({ ...form, condition: v as WeatherRule["condition"] })}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {Object.entries(WEATHER_CONDITIONS).map(([k, v]) => (
                  <SelectItem key={k} value={k}>
                    {v}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </Field>
          <div className="grid grid-cols-2 gap-2">
            <Field label="Nhiệt độ min (°C)">
              <Input type="number" value={form.tempMin} onChange={(e) => setForm({ ...form, tempMin: Number(e.target.value) })} />
            </Field>
            <Field label="Nhiệt độ max (°C)">
              <Input type="number" value={form.tempMax} onChange={(e) => setForm({ ...form, tempMax: Number(e.target.value) })} />
            </Field>
          </div>
          <Field label="Độ ẩm min (%)">
            <Input type="number" value={form.humidityMin} onChange={(e) => setForm({ ...form, humidityMin: Number(e.target.value) })} />
          </Field>
          <Field label="Độ ẩm max (%)">
            <Input type="number" value={form.humidityMax} onChange={(e) => setForm({ ...form, humidityMax: Number(e.target.value) })} />
          </Field>
          <Field label="Lời khuyên chăm cây" className="sm:col-span-2">
            <Textarea rows={3} value={form.tip} onChange={(e) => setForm({ ...form, tip: e.target.value })} />
          </Field>
        </div>
      </FormDialog>

      <ConfirmDialog
        open={!!del}
        onOpenChange={(o) => !o && setDel(null)}
        title={`Xoá quy tắc "${del?.name}"?`}
        tone="danger"
        confirmLabel="Xoá"
        onConfirm={() => del && remove.mutate({ id: del.id, label: del.name })}
      />
    </>
  );
}
