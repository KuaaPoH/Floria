"use client";

import { useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import type { ColumnDef } from "@tanstack/react-table";
import { DatabaseBackup, Plus, RotateCcw } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { PageHeader } from "@/components/shared/page-header";
import { DataTable } from "@/components/shared/data-table";
import { StatusBadge } from "@/components/shared/status-badge";
import { ConfirmDialog } from "@/components/shared/confirm-dialog";
import { InfoGrid } from "@/components/shared/detail-drawer";
import { useResourceList, useResourceMutations } from "@/hooks/use-resource";
import { usePermission } from "@/stores/rbac-store";
import { backupsService, logAudit } from "@/services";
import { API_URL, DATA_MODE } from "@/lib/config";
import { resetMockDb } from "@/lib/mock-db";
import { formatDateTime } from "@/lib/format";
import { uid } from "@/lib/id";
import type { BackupRecord } from "@/types";

export default function BackupSettingsPage() {
  const qc = useQueryClient();
  const list = useResourceList(backupsService);
  const { create } = useResourceMutations(backupsService, { entity: "Bản sao lưu", silent: true });
  const canConfigure = usePermission("system", "configure");
  const [confirmReset, setConfirmReset] = useState(false);

  const createManualBackup = () => {
    const stamp = new Date().toISOString().slice(0, 10);
    create.mutate(
      {
        id: uid("bk"),
        name: `manual-snapshot-${stamp}-${Math.floor(10 + Math.random() * 89)}`,
        type: "manual",
        size: "2,43 GB",
        at: new Date().toISOString(),
        status: "success",
        scope: "Firestore + AI config + Remote UI",
      },
      {
        onSuccess: (bk) => {
          logAudit({ action: "Tạo bản sao lưu", target: bk.name, before: "—", after: bk.size });
          toast.success("Đã tạo bản sao lưu thủ công (mô phỏng)");
        },
      },
    );
  };

  const handleResetDemo = () => {
    resetMockDb();
    qc.invalidateQueries();
    toast.success("Đã khôi phục toàn bộ dữ liệu demo về trạng thái ban đầu");
  };

  const columns: ColumnDef<BackupRecord, unknown>[] = [
    {
      accessorKey: "name",
      header: "Tên bản sao lưu",
      cell: ({ getValue }) => (
        <span className="flex items-center gap-2 font-mono text-xs font-medium">
          <DatabaseBackup className="size-4 text-leaf" />
          {getValue() as string}
        </span>
      ),
    },
    { accessorKey: "type", header: "Loại", cell: ({ getValue }) => (getValue() === "auto" ? "Tự động" : "Thủ công") },
    { accessorKey: "scope", header: "Phạm vi" },
    { accessorKey: "size", header: "Dung lượng", cell: ({ getValue }) => <span className="tabular">{getValue() as string}</span> },
    { accessorKey: "at", header: "Thời gian", cell: ({ getValue }) => formatDateTime(getValue() as string) },
    { accessorKey: "status", header: "Trạng thái", cell: ({ getValue }) => <StatusBadge status={getValue() as string} /> },
  ];

  return (
    <>
      <PageHeader
        title="Sao lưu & Cấu hình"
        description="Quản lý bản sao lưu dữ liệu hệ thống và thông số kết nối môi trường."
        actions={
          canConfigure && (
            <div className="flex gap-2">
              <Button variant="outline" onClick={() => setConfirmReset(true)}>
                <RotateCcw /> Khôi phục dữ liệu demo
              </Button>
              <Button onClick={createManualBackup} disabled={create.isPending}>
                <Plus /> Sao lưu ngay
              </Button>
            </div>
          )
        }
      />

      <div className="card-surface mb-6 p-5">
        <h3 className="mb-3 text-base font-semibold">Cấu hình môi trường hiện tại</h3>
        <InfoGrid
          items={[
            { label: "Chế độ dữ liệu (NEXT_PUBLIC_DATA_MODE)", value: <span className="font-mono">{DATA_MODE.toUpperCase()}</span> },
            { label: "Spring Boot REST API (NEXT_PUBLIC_API_URL)", value: <span className="font-mono">{API_URL}</span> },
            { label: "Cổng thanh toán", value: "ZaloPay Sandbox" },
            { label: "Lưu trữ cục bộ (Demo)", value: "Browser localStorage (floria.mock.*)" },
          ]}
        />
      </div>

      <DataTable columns={columns} data={list.data ?? []} loading={list.isLoading} />

      <ConfirmDialog
        open={confirmReset}
        onOpenChange={setConfirmReset}
        title="Khôi phục toàn bộ dữ liệu mẫu?"
        description="Mọi thay đổi bạn đã thêm/sửa/xoá trong chế độ DEMO trên trình duyệt sẽ được đặt lại về dữ liệu gốc."
        tone="danger"
        confirmLabel="Khôi phục ngay"
        onConfirm={handleResetDemo}
      />
    </>
  );
}
