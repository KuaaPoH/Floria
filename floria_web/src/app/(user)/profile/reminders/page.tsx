"use client";

import { useMemo } from "react";
import Link from "next/link";
import { Bell, Check, Clock, MoonStar } from "lucide-react";
import { toast } from "sonner";
import { CARE_ICON, CARE_TONE } from "@/components/botanical";
import { PageHeader } from "@/components/layout/PageContainer";
import { EmptyState, ErrorState, LoadingState } from "@/components/layout/states";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Switch } from "@/components/ui/switch";
import { ProfileShell } from "@/features/profile/ProfileShell";
import { usePlants, useReminders, useScheduleMutations, useSchedules, useUpdateReminders } from "@/hooks/queries";
import { useLang, useT } from "@/i18n";
import { common } from "@/i18n/common";
import { CARE_SHORT_LABEL } from "@/i18n/labels";
import { formatRelativeDays } from "@/lib/format";
import { cn } from "@/lib/utils";
import type { ReminderSettings } from "@/types/user";

export default function RemindersPage() {
  const t = useT(common);
  const lang = useLang();
  const remQ = useReminders();
  const updateRem = useUpdateReminders();
  const { data: schedules = [] } = useSchedules();
  const { data: plants = [] } = usePlants();
  const { complete } = useScheduleMutations();

  const upcoming = useMemo(
    () =>
      schedules
        .filter((s) => s.enabled && plants.some((p) => p.id === s.plantId))
        .sort((a, b) => new Date(a.nextDueAt).getTime() - new Date(b.nextDueAt).getTime())
        .slice(0, 12),
    [schedules, plants],
  );

  const patch = (p: Partial<Omit<ReminderSettings, "userId">>) => {
    updateRem.mutate(p, { onSuccess: () => toast.success("Đã lưu thiết lập nhắc nhở") });
  };

  return (
    <ProfileShell>
      <div className="space-y-8">
        <PageHeader eyebrow="Nhắc nhở" title="Trung tâm nhắc nhở" description="Bật tắt thông báo chăm cây, thiết lập khung giờ Không làm phiền (DND) và xem lịch sắp tới." className="mb-2" />

        {remQ.isError ? (
          <ErrorState onRetry={() => remQ.refetch()} />
        ) : remQ.isLoading || !remQ.data ? (
          <LoadingState />
        ) : (
          <div className="grid gap-6 md:grid-cols-2">
            {/* Channels */}
            <section className="space-y-4 rounded-3xl border bg-card p-6 shadow-soft">
              <h2 className="flex items-center gap-2 text-lg font-semibold"><Bell className="size-5 text-leaf" /> Kênh & loại nhắc nhở</h2>
              <label className="flex cursor-pointer items-center justify-between rounded-2xl bg-mint/40 p-4">
                <div>
                  <p className="font-semibold">Bật thông báo đẩy</p>
                  <p className="text-xs text-muted-foreground">Nhận thông báo khi tới hạn chăm sóc cây.</p>
                </div>
                <Switch checked={remQ.data.pushEnabled} onCheckedChange={(v) => patch({ pushEnabled: v })} />
              </label>
              {[
                { key: "watering" as const, title: "Nhắc tưới nước", desc: "Thông báo theo chu kỳ tưới của từng cây" },
                { key: "fertilizing" as const, title: "Nhắc bón phân", desc: "Thông báo định kỳ bổ sung dinh dưỡng" },
                { key: "inspection" as const, title: "Nhắc kiểm tra & lau lá", desc: "Kiểm tra sâu bệnh mặt dưới lá" },
              ].map((item) => (
                <label key={item.key} className="flex cursor-pointer items-center justify-between rounded-2xl border p-3.5">
                  <div>
                    <p className="text-sm font-semibold">{item.title}</p>
                    <p className="text-xs text-muted-foreground">{item.desc}</p>
                  </div>
                  <Switch
                    checked={remQ.data[item.key]}
                    disabled={!remQ.data.pushEnabled}
                    onCheckedChange={(v) => patch({ [item.key]: v })}
                  />
                </label>
              ))}
            </section>

            {/* DND */}
            <section className="space-y-4 rounded-3xl border bg-card p-6 shadow-soft">
              <h2 className="flex items-center gap-2 text-lg font-semibold"><MoonStar className="size-5 text-leaf" /> Không làm phiền (DND)</h2>
              <label className="flex cursor-pointer items-center justify-between rounded-2xl border p-4">
                <div>
                  <p className="font-semibold">Bật khung giờ yên tĩnh</p>
                  <p className="text-xs text-muted-foreground">Tạm hoãn thông báo vào ban đêm hoặc giờ nghỉ ngơi.</p>
                </div>
                <Switch checked={remQ.data.dndEnabled} onCheckedChange={(v) => patch({ dndEnabled: v })} />
              </label>
              <div className={cn("grid grid-cols-2 gap-4 rounded-2xl border p-4", !remQ.data.dndEnabled && "opacity-50")}>
                <div>
                  <label htmlFor="dnd-start" className="text-xs font-semibold text-muted-foreground">Bắt đầu</label>
                  <Input id="dnd-start" type="time" disabled={!remQ.data.dndEnabled} value={remQ.data.dndStart} onChange={(e) => patch({ dndStart: e.target.value })} className="mt-1.5" />
                </div>
                <div>
                  <label htmlFor="dnd-end" className="text-xs font-semibold text-muted-foreground">Kết thúc</label>
                  <Input id="dnd-end" type="time" disabled={!remQ.data.dndEnabled} value={remQ.data.dndEnd} onChange={(e) => patch({ dndEnd: e.target.value })} className="mt-1.5" />
                </div>
              </div>
              <p className="text-xs text-muted-foreground">
                Khi chế độ DND bật từ {remQ.data.dndStart} đến {remQ.data.dndEnd}, thông báo sẽ được giữ lại đến sáng hôm sau.
              </p>
            </section>
          </div>
        )}

        {/* Upcoming schedule list */}
        <section className="rounded-3xl border bg-card p-6 shadow-soft">
          <h2 className="mb-4 flex items-center gap-2 text-lg font-semibold"><Clock className="size-5 text-leaf" /> Lịch chăm sóc sắp tới</h2>
          {upcoming.length === 0 ? (
            <EmptyState title="Chưa có lịch chăm sóc nào" description="Thêm cây vào khu vườn để Floria tạo lịch tưới, bón phân và kiểm tra tự động." action={<Button asChild variant="outline"><Link href="/garden">Mở Khu vườn</Link></Button>} />
          ) : (
            <ul className="divide-y">
              {upcoming.map((s) => {
                const plant = plants.find((p) => p.id === s.plantId);
                if (!plant) return null;
                const Icon = CARE_ICON[s.type];
                return (
                  <li key={s.id} className="flex flex-wrap items-center justify-between gap-3 py-3 first:pt-0 last:pb-0">
                    <Link href={`/garden/${plant.gardenId}/plants/${plant.id}`} className="flex min-w-0 items-center gap-3 hover:opacity-85">
                      <img src={plant.image} alt={plant.nickname} className="size-12 shrink-0 rounded-xl object-cover" />
                      <div className="min-w-0">
                        <p className="truncate font-semibold">{plant.nickname}</p>
                        <div className="flex items-center gap-2 text-xs text-muted-foreground">
                          <span className={cn("inline-flex items-center gap-1 rounded-full px-2 py-0.5 font-medium", CARE_TONE[s.type])}>
                            <Icon className="size-3" /> {t(CARE_SHORT_LABEL[s.type])}
                          </span>
                          <span>{s.preferredTime}</span>
                          <span>· {formatRelativeDays(s.nextDueAt, lang)}</span>
                        </div>
                      </div>
                    </Link>
                    <Button
                      size="sm"
                      variant="outline"
                      disabled={complete.isPending}
                      onClick={() => complete.mutate(s.id, { onSuccess: () => toast.success(`Đã hoàn thành ${t(CARE_SHORT_LABEL[s.type]).toLowerCase()}`) })}
                    >
                      <Check /> Hoàn thành
                    </Button>
                  </li>
                );
              })}
            </ul>
          )}
        </section>
      </div>
    </ProfileShell>
  );
}
