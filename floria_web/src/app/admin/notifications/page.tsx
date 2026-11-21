"use client";

import { useMemo, useState } from "react";
import type { ColumnDef } from "@tanstack/react-table";
import { BellRing, CheckCircle2, Plus, Send, Users, XCircle } from "lucide-react";
import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { PageHeader } from "@/components/shared/page-header";
import { StatCard } from "@/components/shared/stat-card";
import { ChartCard, chartTheme } from "@/components/shared/chart-card";
import { DataTable } from "@/components/shared/data-table";
import { StatusBadge } from "@/components/shared/status-badge";
import { Field } from "@/components/shared/field";
import { ImageUploader } from "@/components/shared/image-uploader";
import { useResourceList, useResourceMutations } from "@/hooks/use-resource";
import { usePermission } from "@/stores/rbac-store";
import { campaignsService } from "@/services";
import { formatDateTime, formatNumber } from "@/lib/format";
import { uid } from "@/lib/id";
import type { AudienceKind, Campaign } from "@/types";

const AUDIENCE_LABELS: Record<AudienceKind, string> = {
  all: "Tất cả thiết bị đã cài Floria",
  active: "Người dùng hoạt động (30 ngày)",
  inactive: "Người dùng không hoạt động (>30 ngày)",
  species: "Người dùng đang trồng loài cây cụ thể",
  diagnosed: "Người dùng từng chẩn đoán bệnh",
  custom: "Phân khúc tuỳ chỉnh",
};

export default function NotificationsPage() {
  const list = useResourceList(campaignsService);
  const { create } = useResourceMutations(campaignsService, { entity: "Chiến dịch thông báo", silent: true });
  const canCreate = usePermission("notifications", "create");

  const [name, setName] = useState("");
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [image, setImage] = useState("");
  const [deepLink, setDeepLink] = useState("floria://home");
  const [audience, setAudience] = useState<AudienceKind>("all");
  const [audienceDetail, setAudienceDetail] = useState("");
  const [scheduledAt, setScheduledAt] = useState("");

  const all = list.data ?? [];
  const totalSent = all.reduce((s, c) => s + c.success, 0);
  const totalFailed = all.reduce((s, c) => s + c.failed, 0);
  const totalOpened = all.reduce((s, c) => s + c.opened, 0);

  const chartData = useMemo(
    () =>
      all
        .filter((c) => c.status === "sent")
        .slice(0, 8)
        .map((c) => ({
          name: c.name.slice(0, 18),
          thanhCong: c.success,
          daMo: c.opened,
        })),
    [all],
  );

  const submit = (sendNow: boolean) => {
    if (!title.trim() || !body.trim()) {
      toast.error("Vui lòng nhập tiêu đề và nội dung thông báo");
      return;
    }
    const item: Campaign & { sendNow: boolean } = {
      id: uid("cmp"),
      name: name.trim() || title.trim(),
      title: title.trim(),
      body: body.trim(),
      image,
      deepLink: deepLink.trim() || "floria://home",
      audience,
      audienceDetail: audienceDetail.trim() || AUDIENCE_LABELS[audience],
      scheduledAt: sendNow ? new Date().toISOString() : scheduledAt ? new Date(scheduledAt).toISOString() : new Date().toISOString(),
      status: sendNow ? "sent" : "scheduled",
      targeted: 0,
      success: 0,
      failed: 0,
      opened: 0,
      sendNow,
    };
    create.mutate(item, {
      onSuccess: () => {
        toast.success(sendNow ? "Đã gửi thông báo đẩy tới tất cả thiết bị!" : "Đã lên lịch chiến dịch");
        setName("");
        setTitle("");
        setBody("");
        setAudienceDetail("");
      },
      onError: (err) => {
        toast.error(err instanceof Error ? err.message : "Không thể gửi thông báo đẩy");
      },
    });
  };

  const columns: ColumnDef<Campaign, unknown>[] = [
    {
      accessorKey: "name",
      header: "Chiến dịch",
      cell: ({ row }) => (
        <div>
          <p className="font-medium">{row.original.name}</p>
          <p className="text-xs text-muted-foreground">{row.original.title}</p>
        </div>
      ),
    },
    { accessorKey: "audienceDetail", header: "Đối tượng" },
    { accessorKey: "scheduledAt", header: "Thời gian gửi", cell: ({ getValue }) => formatDateTime(getValue() as string) },
    { accessorKey: "success", header: "Thành công", cell: ({ getValue }) => <span className="font-medium text-success tabular">{formatNumber(getValue() as number)}</span> },
    { accessorKey: "failed", header: "Thất bại", cell: ({ getValue }) => <span className="text-danger tabular">{formatNumber(getValue() as number)}</span> },
    { accessorKey: "opened", header: "Đã mở", cell: ({ getValue }) => <span className="tabular">{formatNumber(getValue() as number)}</span> },
    { accessorKey: "status", header: "Trạng thái", cell: ({ getValue }) => <StatusBadge status={getValue() as string} /> },
  ];

  return (
    <>
      <PageHeader title="Thông báo đẩy" description="Gửi Push Notification thực tế qua Firebase Cloud Messaging tới các thiết bị cài đặt Floria." />

      <div className="mb-5 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="Chiến dịch" value={String(all.length)} icon={BellRing} tone="leaf" />
        <StatCard label="Gửi thành công" value={formatNumber(totalSent)} icon={CheckCircle2} tone="info" />
        <StatCard label="Tổng lượt mở" value={formatNumber(totalOpened)} icon={Users} tone="sage" />
        <StatCard label="Gửi thất bại" value={formatNumber(totalFailed)} icon={XCircle} tone="danger" />
      </div>

      <div className="mb-6 grid gap-5 lg:grid-cols-[1.4fr_1fr]">
        <div className="card-surface p-5">
          <h3 className="mb-4 text-base font-semibold">Tạo thông báo mới</h3>
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label="Tên chiến dịch nội bộ (tuỳ chọn)" className="sm:col-span-2">
              <Input value={name} disabled={!canCreate || create.isPending} onChange={(e) => setName(e.target.value)} placeholder="VD: Nhắc chăm cây cuối tuần" />
            </Field>
            <Field label="Tiêu đề thông báo" className="sm:col-span-2">
              <Input value={title} disabled={!canCreate || create.isPending} onChange={(e) => setTitle(e.target.value)} placeholder="VD: Cây của bạn cần kiểm tra độ ẩm!" />
            </Field>
            <Field label="Nội dung thông báo" className="sm:col-span-2">
              <Textarea rows={3} value={body} disabled={!canCreate || create.isPending} onChange={(e) => setBody(e.target.value)} placeholder="Nội dung ngắn gọn hiển thị trên màn hình khoá…" />
            </Field>
            <Field label="Phân khúc đối tượng">
              <Select value={audience} disabled={!canCreate || create.isPending} onValueChange={(v) => setAudience(v as AudienceKind)}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {Object.entries(AUDIENCE_LABELS).map(([k, label]) => (
                    <SelectItem key={k} value={k}>
                      {label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </Field>
            <Field label="Chi tiết phân khúc (tuỳ chọn)">
              <Input value={audienceDetail} disabled={!canCreate || create.isPending} onChange={(e) => setAudienceDetail(e.target.value)} placeholder="VD: Toàn bộ người dùng app…" />
            </Field>
            <Field label="Deep link đích">
              <Input className="font-mono text-xs" value={deepLink} disabled={!canCreate || create.isPending} onChange={(e) => setDeepLink(e.target.value)} />
            </Field>
            <Field label="Thời gian hẹn gửi (nếu lên lịch)">
              <Input type="datetime-local" value={scheduledAt} disabled={!canCreate || create.isPending} onChange={(e) => setScheduledAt(e.target.value)} />
            </Field>
            <Field label="Ảnh đính kèm (tuỳ chọn)" className="sm:col-span-2">
              <ImageUploader value={image} aspect="wide" onChange={setImage} />
            </Field>
          </div>
          {canCreate && (
            <div className="mt-4 flex flex-wrap justify-end gap-2">
              <Button type="button" variant="outline" disabled={create.isPending} onClick={() => submit(false)}>
                <Plus /> Lên lịch gửi
              </Button>
              <Button type="button" disabled={create.isPending} onClick={() => submit(true)}>
                <Send /> {create.isPending ? "Đang gửi..." : "Gửi ngay"}
              </Button>
            </div>
          )}
        </div>

        <div className="space-y-5">
          <div className="card-surface p-5">
            <h3 className="mb-3 text-base font-semibold">Xem trước trên điện thoại</h3>
            <div className="rounded-3xl bg-[#1a221d] p-5 text-white">
              <p className="mb-4 text-center text-xs opacity-60">Màn hình khóa điện thoại</p>
              <div className="rounded-2xl bg-white/95 p-3.5 text-[#26372D] shadow-md">
                <div className="flex items-center justify-between text-[11px] text-[#718074]">
                  <span className="font-semibold text-forest">FLORIA</span>
                  <span>bây giờ</span>
                </div>
                <div className="mt-1.5 flex gap-3">
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-semibold">{title || "Tiêu đề thông báo Floria"}</p>
                    <p className="mt-0.5 text-xs text-[#55635a]">{body || "Nội dung thông báo sẽ hiển thị tại đây và mở ứng dụng khi chạm vào."}</p>
                  </div>
                  {image && <img src={image} alt="" className="size-12 shrink-0 rounded-lg object-cover" />}
                </div>
              </div>
              <p className="mt-3 text-center font-mono text-[11px] opacity-60">Target: {deepLink}</p>
            </div>
          </div>

          <ChartCard title="Hiệu quả các chiến dịch đã gửi" description="So sánh số lượt gửi thành công và lượt mở">
            <div className="h-56">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={chartData}>
                  <CartesianGrid stroke={chartTheme.grid} strokeDasharray="3 3" vertical={false} />
                  <XAxis dataKey="name" tick={chartTheme.axis} />
                  <YAxis tick={chartTheme.axis} />
                  <Tooltip {...chartTheme.tooltip} />
                  <Bar dataKey="thanhCong" name="Thành công" fill="var(--chart-1)" radius={[6, 6, 0, 0]} />
                  <Bar dataKey="daMo" name="Đã mở" fill="var(--chart-2)" radius={[6, 6, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </ChartCard>
        </div>
      </div>

      <DataTable columns={columns} data={all} loading={list.isLoading} />
    </>
  );
}
