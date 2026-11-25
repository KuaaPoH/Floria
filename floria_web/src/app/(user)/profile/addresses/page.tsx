"use client";

import { useState } from "react";
import { MapPin, Pencil, Plus, Star, Trash2 } from "lucide-react";
import { toast } from "sonner";
import { ConfirmDialog } from "@/components/layout/ConfirmDialog";
import { PageHeader } from "@/components/layout/PageContainer";
import { CardGridSkeleton, EmptyState, ErrorState } from "@/components/layout/states";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { AddressFormDialog } from "@/features/profile/AddressFormDialog";
import { ProfileShell } from "@/features/profile/ProfileShell";
import { useAddressMutations, useAddresses } from "@/hooks/queries";
import { cn } from "@/lib/utils";
import type { Address } from "@/types/user";

export default function AddressesPage() {
  const addrQ = useAddresses();
  const { remove, setDefault } = useAddressMutations();
  const [dialog, setDialog] = useState<{ open: boolean; editing?: Address }>({ open: false });
  const [deleting, setDeleting] = useState<Address | null>(null);

  const addresses = addrQ.data ?? [];

  return (
    <ProfileShell>
      <div className="space-y-6">
        <PageHeader
          eyebrow="Sổ địa chỉ"
          title="Quản lý địa chỉ & tọa độ"
          description="Địa chỉ mặc định kèm tọa độ GPS giúp giao hàng chính xác và hiển thị thời tiết thực tế trên Tổng quan."
          className="mb-2"
          actions={
            <Button onClick={() => setDialog({ open: true })}><Plus /> Thêm địa chỉ</Button>
          }
        />

        {addrQ.isError ? (
          <ErrorState onRetry={() => addrQ.refetch()} />
        ) : addrQ.isLoading ? (
          <CardGridSkeleton count={2} className="lg:grid-cols-2" />
        ) : addresses.length === 0 ? (
          <EmptyState
            icon={<MapPin />}
            title="Chưa có địa chỉ giao hàng"
            description="Thêm địa chỉ và ghim tọa độ để nhận khuyến nghị chăm sóc cây theo thời tiết."
            action={<Button onClick={() => setDialog({ open: true })}><Plus /> Thêm địa chỉ đầu tiên</Button>}
          />
        ) : (
          <div className="grid gap-4 md:grid-cols-2">
            {addresses.map((a) => (
              <article key={a.id} className={cn("flex flex-col rounded-3xl border bg-card p-5 shadow-soft", a.isDefault && "border-leaf/60 bg-mint/20")}>
                <div className="flex items-start justify-between gap-2">
                  <div className="flex flex-wrap items-center gap-2">
                    <h3 className="font-semibold">{a.recipientName}</h3>
                    {a.isDefault && <Badge variant="success">Mặc định</Badge>}
                    {a.label && <Badge variant="muted">{a.label}</Badge>}
                  </div>
                  <div className="flex gap-1">
                    <Button size="icon-sm" variant="ghost" onClick={() => setDialog({ open: true, editing: a })} aria-label="Sửa"><Pencil /></Button>
                    <Button size="icon-sm" variant="ghost" className="hover:text-danger" onClick={() => setDeleting(a)} aria-label="Xóa"><Trash2 /></Button>
                  </div>
                </div>
                <p className="mt-1 text-sm text-muted-foreground">{a.phone}</p>
                <p className="mt-2 text-sm">{a.street}, {a.wardName}, {a.provinceName}</p>
                <p className="mt-2 inline-flex items-center gap-1.5 text-xs text-muted-foreground">
                  <MapPin className="size-3.5 text-leaf" />
                  {a.latitude !== null && a.longitude !== null
                    ? `GPS: ${a.latitude.toFixed(4)}, ${a.longitude.toFixed(4)}`
                    : "Chưa ghim tọa độ trên bản đồ"}
                </p>
                {!a.isDefault && (
                  <div className="mt-auto pt-4">
                    <Button
                      size="sm"
                      variant="outline"
                      disabled={setDefault.isPending}
                      onClick={() => setDefault.mutate(a.id, { onSuccess: () => toast.success("Đã đặt làm địa chỉ mặc định") })}
                    >
                      <Star /> Đặt mặc định
                    </Button>
                  </div>
                )}
              </article>
            ))}
          </div>
        )}
      </div>

      <AddressFormDialog open={dialog.open} onOpenChange={(o) => setDialog((s) => ({ ...s, open: o }))} address={dialog.editing} />

      <ConfirmDialog
        open={!!deleting}
        onOpenChange={(o) => !o && setDeleting(null)}
        destructive
        loading={remove.isPending}
        title="Xóa địa chỉ này?"
        description={deleting && `${deleting.recipientName} — ${deleting.street}, ${deleting.wardName}, ${deleting.provinceName}`}
        confirmLabel="Xóa địa chỉ"
        onConfirm={async () => {
          await remove.mutateAsync(deleting!.id);
          setDeleting(null);
          toast.success("Đã xóa địa chỉ");
        }}
      />
    </ProfileShell>
  );
}
