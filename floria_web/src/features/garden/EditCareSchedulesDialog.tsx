"use client";

import { useEffect, useState } from "react";
import { Droplets, Loader2, Minus, Plus, ShieldCheck } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { useScheduleMutations } from "@/hooks/queries";
import { useT } from "@/i18n";
import { common } from "@/i18n/common";
import { cn } from "@/lib/utils";
import type { CareSchedule } from "@/types/user";

interface EditCareSchedulesDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  schedules: CareSchedule[];
  recommendedWater?: string;
}

export function EditCareSchedulesDialog({
  open,
  onOpenChange,
  schedules,
  recommendedWater,
}: EditCareSchedulesDialogProps) {
  const t = useT(common);
  const { update } = useScheduleMutations();

  const waterSch = schedules.find((s) => s.type === "watering");
  const fertSch = schedules.find((s) => s.type === "fertilizing");
  const pestSch = schedules.find((s) => s.type === "inspection");

  const [timesPerWeek, setTimesPerWeek] = useState(2);
  const [waterTime, setWaterTime] = useState("07:00");
  const [enableFertilizer, setEnableFertilizer] = useState(true);
  const [fertilizeDays, setFertilizeDays] = useState(20);
  const [fertTime, setFertTime] = useState("08:30");
  const [checkPestDays, setCheckPestDays] = useState(5);
  const [pestTime, setPestTime] = useState("18:00");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!open) return;
    if (waterSch) {
      setTimesPerWeek(Math.min(14, Math.max(1, Math.round(7 / Math.max(1, waterSch.intervalDays)))));
      setWaterTime(waterSch.preferredTime || "07:00");
    }
    if (fertSch) {
      setEnableFertilizer(fertSch.enabled);
      setFertilizeDays(Math.min(60, Math.max(7, fertSch.intervalDays || 20)));
      setFertTime(fertSch.preferredTime || "08:30");
    }
    if (pestSch) {
      setCheckPestDays(Math.min(14, Math.max(1, pestSch.intervalDays || 5)));
      setPestTime(pestSch.preferredTime || "18:00");
    }
  }, [open, waterSch, fertSch, pestSch]);

  const waterIntervalDays = Math.min(14, Math.max(1, Math.round(7 / timesPerWeek)));

  const handleSave = async () => {
    setSaving(true);
    try {
      const ops: Promise<unknown>[] = [];
      if (waterSch) {
        ops.push(
          update.mutateAsync({
            id: waterSch.id,
            patch: { intervalDays: waterIntervalDays, preferredTime: waterTime, enabled: true },
          }),
        );
      }
      if (fertSch) {
        ops.push(
          update.mutateAsync({
            id: fertSch.id,
            patch: { intervalDays: fertilizeDays, preferredTime: fertTime, enabled: enableFertilizer },
          }),
        );
      }
      if (pestSch) {
        ops.push(
          update.mutateAsync({
            id: pestSch.id,
            patch: { intervalDays: checkPestDays, preferredTime: pestTime, enabled: true },
          }),
        );
      }
      await Promise.all(ops);
      toast.success("Đã cập nhật lịch chăm sóc cây");
      onOpenChange(false);
    } catch (e) {
      toast.error((e as Error).message || "Không thể cập nhật lịch chăm sóc.");
    } finally {
      setSaving(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[92vh] w-[calc(100vw-1.5rem)] max-w-xl overflow-y-auto overflow-x-hidden rounded-3xl p-5 sm:p-6">
        <DialogHeader>
          <DialogTitle>Chỉnh sửa lịch chăm sóc</DialogTitle>
        </DialogHeader>

        <div className="space-y-4">
          {/* 1. Lịch tưới nước */}
          <div className="space-y-2.5 rounded-2xl border bg-card p-3.5">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <span className="flex items-center gap-1.5 text-sm font-semibold">
                <Droplets className="size-4 text-sky-600" /> Lịch tưới nước
              </span>
              {recommendedWater && (
                <span className="rounded-lg bg-mint px-2.5 py-0.5 text-[11px] font-semibold text-forest">
                  Khuyến nghị: {recommendedWater}
                </span>
              )}
            </div>
            <div className="flex flex-wrap gap-2">
              {[
                { label: "1 lần / tuần", val: 1 },
                { label: "2 lần / tuần", val: 2 },
                { label: "3 lần / tuần", val: 3 },
                { label: "Hàng ngày (7 lần)", val: 7 },
              ].map((chip) => (
                <button
                  key={chip.val}
                  type="button"
                  onClick={() => setTimesPerWeek(chip.val)}
                  className={cn(
                    "rounded-full border px-3 py-1 text-xs font-medium transition-all",
                    timesPerWeek === chip.val
                      ? "border-sky-600 bg-sky-600 text-white"
                      : "bg-muted/40 text-foreground hover:border-sky-400",
                  )}
                >
                  {chip.label}
                </button>
              ))}
            </div>
            <div className="flex flex-wrap items-center justify-between gap-3 rounded-xl border bg-muted/30 px-3 py-2">
              <span className="text-xs font-medium text-muted-foreground">
                Tùy chỉnh: <b className="text-foreground">{timesPerWeek} lần/tuần</b> (~mỗi {waterIntervalDays} ngày)
              </span>
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  disabled={timesPerWeek <= 1}
                  onClick={() => setTimesPerWeek((v) => Math.max(1, v - 1))}
                  className="grid size-7 place-items-center rounded-full border bg-card text-foreground disabled:opacity-40"
                  aria-label="Giảm số lần tưới"
                >
                  <Minus className="size-3.5" />
                </button>
                <span className="w-5 text-center text-sm font-bold">{timesPerWeek}</span>
                <button
                  type="button"
                  disabled={timesPerWeek >= 14}
                  onClick={() => setTimesPerWeek((v) => Math.min(14, v + 1))}
                  className="grid size-7 place-items-center rounded-full border bg-card text-foreground disabled:opacity-40"
                  aria-label="Tăng số lần tưới"
                >
                  <Plus className="size-3.5" />
                </button>
              </div>
            </div>
            <div className="flex items-center justify-between gap-3 pt-1 text-xs">
              <span className="text-muted-foreground">Giờ nhắc tưới nước</span>
              <Input type="time" value={waterTime} onChange={(e) => setWaterTime(e.target.value)} className="h-8 w-28" />
            </div>
          </div>

          {/* 2. Yêu cầu bón phân dinh dưỡng */}
          <div className="space-y-2.5 rounded-2xl border bg-card p-3.5">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <span className="text-sm font-semibold">Yêu cầu bón phân dinh dưỡng</span>
              {enableFertilizer && (
                <span className="rounded-lg bg-amber-100 px-2.5 py-0.5 text-xs font-bold text-amber-800">
                  Mỗi {fertilizeDays} ngày / lần
                </span>
              )}
            </div>
            <div className="grid grid-cols-2 gap-2">
              <button
                type="button"
                onClick={() => setEnableFertilizer(true)}
                className={cn(
                  "rounded-xl border px-3 py-2 text-xs font-semibold transition-all",
                  enableFertilizer
                    ? "border-amber-500 bg-amber-50 text-amber-900"
                    : "bg-muted/30 text-muted-foreground",
                )}
              >
                Cần bón phân
              </button>
              <button
                type="button"
                onClick={() => setEnableFertilizer(false)}
                className={cn(
                  "rounded-xl border px-3 py-2 text-xs font-semibold transition-all",
                  !enableFertilizer
                    ? "border-foreground/40 bg-muted text-foreground"
                    : "bg-muted/30 text-muted-foreground",
                )}
              >
                Không cần bón
              </button>
            </div>
            {enableFertilizer ? (
              <div className="space-y-2 pt-1">
                <input
                  type="range"
                  min={7}
                  max={60}
                  step={1}
                  value={fertilizeDays}
                  onChange={(e) => setFertilizeDays(Number(e.target.value))}
                  className="w-full accent-amber-500"
                />
                <div className="flex justify-between text-[11px] text-muted-foreground">
                  <span>7 ngày</span>
                  <span>60 ngày</span>
                </div>
                <div className="flex items-center justify-between gap-3 text-xs">
                  <span className="text-muted-foreground">Giờ nhắc bón phân</span>
                  <Input type="time" value={fertTime} onChange={(e) => setFertTime(e.target.value)} className="h-8 w-28" />
                </div>
              </div>
            ) : (
              <p className="text-xs italic text-muted-foreground">
                Lịch bón phân sẽ được ẩn khỏi danh sách chăm sóc của cây này.
              </p>
            )}
          </div>

          {/* 3. Chu kỳ kiểm tra sâu bệnh & lau lá */}
          <div className="space-y-2 rounded-2xl border bg-card p-3.5">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <span className="flex items-center gap-1.5 text-sm font-semibold">
                <ShieldCheck className="size-4 text-sky-600" /> Chu kỳ kiểm tra sâu bệnh & lau lá
              </span>
              <span className="rounded-lg bg-sky-100 px-2.5 py-0.5 text-xs font-bold text-sky-800">
                Mỗi {checkPestDays} ngày / lần
              </span>
            </div>
            <input
              type="range"
              min={1}
              max={14}
              step={1}
              value={checkPestDays}
              onChange={(e) => setCheckPestDays(Number(e.target.value))}
              className="w-full accent-sky-600"
            />
            <div className="flex justify-between text-[11px] text-muted-foreground">
              <span>Mỗi ngày</span>
              <span>14 ngày</span>
            </div>
            <div className="flex items-center justify-between gap-3 pt-1 text-xs">
              <span className="text-muted-foreground">Giờ nhắc kiểm tra</span>
              <Input type="time" value={pestTime} onChange={(e) => setPestTime(e.target.value)} className="h-8 w-28" />
            </div>
          </div>
        </div>

        <DialogFooter className="pt-2">
          <Button type="button" variant="ghost" onClick={() => onOpenChange(false)}>
            {t("cancel")}
          </Button>
          <Button type="button" disabled={saving} onClick={handleSave}>
            {saving && <Loader2 className="animate-spin" />} {t("save")}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
