"use client";

import { useMemo, useState } from "react";
import type { ColumnDef } from "@tanstack/react-table";
import { CheckCircle2, Clock, LifeBuoy, MessageSquarePlus, Send } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { PageHeader } from "@/components/shared/page-header";
import { StatCard } from "@/components/shared/stat-card";
import { DataTable } from "@/components/shared/data-table";
import { SearchInput } from "@/components/shared/search-input";
import { FilterSelect } from "@/components/shared/filter-select";
import { StatusBadge, statusLabel } from "@/components/shared/status-badge";
import { DetailDrawer, DetailSection, InfoGrid } from "@/components/shared/detail-drawer";
import { useResourceList, useResourceMutations } from "@/hooks/use-resource";
import { useAuthStore } from "@/stores/auth-store";
import { usePermission } from "@/stores/rbac-store";
import { ticketsService } from "@/services";
import { formatDateTime } from "@/lib/format";
import type { Ticket, TicketStatus } from "@/types";

const CATEGORY_LABEL: Record<Ticket["category"], string> = {
  app_error: "Lỗi ứng dụng",
  ai_wrong: "AI nhận diện sai",
  order: "Khiếu nại đơn hàng",
  product: "Phản hồi sản phẩm",
  suggestion: "Góp ý chung",
};

export default function SupportPage() {
  const adminName = useAuthStore((s) => s.session?.name ?? "Admin");
  const list = useResourceList(ticketsService);
  const { update } = useResourceMutations(ticketsService, { entity: "Phiếu hỗ trợ" });
  const canEdit = usePermission("support", "edit");

  const [search, setSearch] = useState("");
  const [cat, setCat] = useState("all");
  const [status, setStatus] = useState("all");
  const [prio, setPrio] = useState("all");
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [reply, setReply] = useState("");
  const [note, setNote] = useState("");

  const all = list.data ?? [];
  const selected = all.find((t) => t.id === selectedId) ?? null;

  const rows = useMemo(() => {
    const s = search.toLowerCase();
    return all.filter(
      (t) =>
        (!s || t.code.toLowerCase().includes(s) || t.subject.toLowerCase().includes(s) || t.userName.toLowerCase().includes(s)) &&
        (cat === "all" || t.category === cat) &&
        (status === "all" || t.status === status) &&
        (prio === "all" || t.priority === prio),
    );
  }, [all, search, cat, status, prio]);

  const sendReply = () => {
    if (!selected || !reply.trim()) return;
    const nextStatus: TicketStatus = selected.status === "open" ? "in_progress" : selected.status;
    update.mutate(
      {
        id: selected.id,
        patch: {
          status: nextStatus,
          assignee: selected.assignee || adminName,
          messages: [...selected.messages, { from: "admin", text: reply.trim(), at: new Date().toISOString() }],
        },
        label: selected.code,
      },
      { onSuccess: () => setReply("") },
    );
  };

  const addInternalNote = () => {
    if (!selected || !note.trim()) return;
    update.mutate(
      {
        id: selected.id,
        patch: {
          notes: [...selected.notes, { by: adminName, text: note.trim(), at: new Date().toISOString() }],
        },
        label: selected.code,
      },
      {
        onSuccess: () => {
          setNote("");
          toast.success("Đã thêm ghi chú nội bộ");
        },
      },
    );
  };

  const columns: ColumnDef<Ticket, unknown>[] = [
    { accessorKey: "code", header: "Mã phiếu", cell: ({ getValue }) => <span className="font-mono text-xs font-semibold">{getValue() as string}</span> },
    {
      accessorKey: "subject",
      header: "Tiêu đề",
      cell: ({ row }) => (
        <div>
          <p className="font-medium">{row.original.subject}</p>
          <p className="text-xs text-muted-foreground">
            {row.original.userName} · {row.original.email}
          </p>
        </div>
      ),
    },
    { accessorKey: "category", header: "Phân loại", cell: ({ getValue }) => CATEGORY_LABEL[getValue() as Ticket["category"]] },
    { accessorKey: "priority", header: "Ưu tiên", cell: ({ getValue }) => <StatusBadge status={getValue() as string} /> },
    { accessorKey: "assignee", header: "Phụ trách", cell: ({ getValue }) => (getValue() as string) || <span className="text-xs text-muted-foreground">Chưa phân công</span> },
    { accessorKey: "createdAt", header: "Ngày tạo", cell: ({ getValue }) => formatDateTime(getValue() as string) },
    { accessorKey: "status", header: "Trạng thái", cell: ({ getValue }) => <StatusBadge status={getValue() as string} /> },
  ];

  return (
    <>
      <PageHeader title="Trung tâm hỗ trợ" description="Tiếp nhận và xử lý phiếu hỗ trợ từ người dùng ứng dụng Floria." />

      <div className="mb-4 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="Tổng phiếu" value={String(all.length)} icon={LifeBuoy} tone="leaf" />
        <StatCard label="Mới tiếp nhận" value={String(all.filter((t) => t.status === "open").length)} icon={MessageSquarePlus} tone="info" />
        <StatCard label="Đang xử lý" value={String(all.filter((t) => t.status === "in_progress").length)} icon={Clock} tone="warning" />
        <StatCard label="Đã giải quyết" value={String(all.filter((t) => t.status === "resolved").length)} icon={CheckCircle2} tone="sage" />
      </div>

      <DataTable
        columns={columns}
        data={rows}
        loading={list.isLoading}
        onRowClick={(t) => setSelectedId(t.id)}
        toolbar={
          <>
            <SearchInput value={search} onChange={setSearch} placeholder="Mã phiếu, tiêu đề, người gửi…" />
            <FilterSelect
              value={cat}
              onChange={setCat}
              allLabel="Mọi phân loại"
              options={Object.entries(CATEGORY_LABEL).map(([value, label]) => ({ value, label }))}
            />
            <FilterSelect
              value={status}
              onChange={setStatus}
              allLabel="Mọi trạng thái"
              options={["open", "in_progress", "resolved"].map((v) => ({ value: v, label: statusLabel(v) }))}
            />
            <FilterSelect
              value={prio}
              onChange={setPrio}
              allLabel="Mọi mức ưu tiên"
              options={["high", "medium", "low"].map((v) => ({ value: v, label: statusLabel(v) }))}
            />
          </>
        }
      />

      <DetailDrawer
        open={!!selected}
        onOpenChange={(o) => !o && setSelectedId(null)}
        className="sm:max-w-2xl"
        title={selected ? `${selected.code} · ${selected.subject}` : ""}
        description={selected ? `${selected.userName} (${selected.email}) · ${formatDateTime(selected.createdAt)}` : undefined}
        footer={
          selected && canEdit ? (
            <div className="flex w-full flex-wrap items-center justify-between gap-2">
              <Select
                value={selected.status}
                onValueChange={(v) =>
                  update.mutate({
                    id: selected.id,
                    patch: { status: v as TicketStatus, assignee: selected.assignee || adminName },
                    before: selected.status,
                    label: selected.code,
                  })
                }
              >
                <SelectTrigger className="w-44 bg-card">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="open">Mới</SelectItem>
                  <SelectItem value="in_progress">Đang xử lý</SelectItem>
                  <SelectItem value="resolved">Đã giải quyết</SelectItem>
                </SelectContent>
              </Select>
              {selected.status !== "resolved" && (
                <Button onClick={() => update.mutate({ id: selected.id, patch: { status: "resolved", assignee: selected.assignee || adminName }, label: selected.code })}>
                  <CheckCircle2 /> Đánh dấu đã giải quyết
                </Button>
              )}
            </div>
          ) : undefined
        }
      >
        {selected && (
          <>
            <DetailSection title="Thông tin phiếu">
              <InfoGrid
                items={[
                  { label: "Phân loại", value: CATEGORY_LABEL[selected.category] },
                  { label: "Mức ưu tiên", value: <StatusBadge status={selected.priority} /> },
                  { label: "Trạng thái", value: <StatusBadge status={selected.status} /> },
                  { label: "Phụ trách", value: selected.assignee || "Chưa phân công" },
                ]}
              />
            </DetailSection>

            <DetailSection title="Trao đổi với người dùng">
              <div className="space-y-2.5">
                {selected.messages.map((m, i) => (
                  <div key={i} className={`rounded-xl p-3 text-sm ${m.from === "user" ? "bg-surface-2/70" : "border border-leaf/25 bg-success-soft/40"}`}>
                    <div className="mb-1 flex justify-between text-[11px] text-muted-foreground">
                      <span className="font-semibold text-foreground">{m.from === "user" ? selected.userName : "Floria Support"}</span>
                      <span>{formatDateTime(m.at)}</span>
                    </div>
                    <p>{m.text}</p>
                  </div>
                ))}
              </div>
              {canEdit && (
                <div className="mt-3 flex gap-2">
                  <Input value={reply} onChange={(e) => setReply(e.target.value)} placeholder="Nhập phản hồi gửi người dùng…" />
                  <Button type="button" onClick={sendReply}>
                    <Send /> Gửi
                  </Button>
                </div>
              )}
            </DetailSection>

            <DetailSection title="Ghi chú nội bộ">
              <div className="space-y-2">
                {selected.notes.length === 0 ? (
                  <p className="text-xs text-muted-foreground">Chưa có ghi chú nội bộ.</p>
                ) : (
                  selected.notes.map((n, i) => (
                    <div key={i} className="rounded-lg border bg-surface-2/40 p-2.5 text-xs">
                      <p className="font-semibold">
                        {n.by} · <span className="font-normal text-muted-foreground">{formatDateTime(n.at)}</span>
                      </p>
                      <p className="mt-0.5">{n.text}</p>
                    </div>
                  ))
                )}
              </div>
              {canEdit && (
                <div className="mt-2.5 flex gap-2">
                  <Textarea rows={2} value={note} onChange={(e) => setNote(e.target.value)} placeholder="Ghi chú xử lý cho nội bộ team…" />
                  <Button type="button" variant="outline" onClick={addInternalNote}>
                    Lưu
                  </Button>
                </div>
              )}
            </DetailSection>
          </>
        )}
      </DetailDrawer>
    </>
  );
}
