"use client";

import {
  AlertTriangle,
  BookOpen,
  Droplets,
  Leaf,
  MapPin,
  Sprout,
  Sun,
  Thermometer,
  Trees,
} from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import type { PlantInfo } from "@/types/user";

interface PlantProfileDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  info: PlantInfo;
  onSaveToGarden?: () => void;
}

export function PlantProfileDialog({ open, onOpenChange, info, onSaveToGarden }: PlantProfileDialogProps) {
  const bioProfile = info.wikiDetail?.trim() || info.description?.trim() || "Đang cập nhật thông tin sinh học cho loài cây này.";

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="flex max-h-[92vh] w-[calc(100vw-1.5rem)] max-w-3xl flex-col gap-4 overflow-y-auto overflow-x-hidden rounded-3xl p-4 sm:p-6">
        <DialogHeader className="pr-6">
          <DialogTitle className="flex items-center gap-2 text-base sm:text-lg">
            <BookOpen className="size-5 shrink-0 text-leaf" />
            <span>Hồ sơ cây & Cẩm nang liên quan</span>
          </DialogTitle>
        </DialogHeader>

        <div className="min-w-0 space-y-4">
          {/* Thông tin cơ bản */}
          <div className="flex flex-col gap-3.5 rounded-2xl border bg-mint/40 p-3.5 sm:flex-row sm:items-start">
            <img
              src={info.image}
              alt={info.commonName}
              className="aspect-square w-full max-w-[120px] shrink-0 rounded-2xl object-cover sm:size-24"
            />
            <div className="min-w-0 flex-1 space-y-1.5">
              <div className="flex flex-wrap gap-1.5">
                <Badge variant="success" className="max-w-full whitespace-normal break-words text-left">
                  {info.family}
                </Badge>
                {info.origin && (
                  <Badge variant="outline" className="max-w-full whitespace-normal break-words text-left">
                    <MapPin className="mr-1 size-3 shrink-0" /> {info.origin}
                  </Badge>
                )}
              </div>
              <div>
                <h2 className="text-lg font-bold leading-snug break-words sm:text-xl">{info.commonName}</h2>
                <p className="text-xs italic text-muted-foreground break-words sm:text-sm">{info.scientificName}</p>
              </div>
              {info.environment && (
                <p className="text-xs text-muted-foreground break-words">
                  Môi trường phù hợp: <b className="text-foreground">{info.environment}</b>
                </p>
              )}
              {info.difficulty && (
                <p className="text-xs text-muted-foreground break-words">
                  Chăm sóc: <span className="text-foreground">{info.difficulty}</span>
                </p>
              )}
            </div>
          </div>

          {/* Hồ sơ sinh học (wiki_detail từ bảng plants_info) */}
          <section className="min-w-0">
            <h3 className="mb-1.5 flex items-center gap-1.5 text-xs font-bold uppercase tracking-wider text-forest">
              <BookOpen className="size-3.5 shrink-0 text-leaf" /> Hồ sơ sinh học
            </h3>
            <div className="rounded-2xl border bg-muted/30 p-3.5 text-xs leading-relaxed text-foreground/90 whitespace-pre-line break-words sm:text-sm">
              {bioProfile}
            </div>
          </section>

          {/* Đặc điểm hình thái & Sinh trưởng */}
          <section className="min-w-0">
            <h3 className="mb-2 flex items-center gap-1.5 text-xs font-bold uppercase tracking-wider text-forest">
              <Trees className="size-3.5 shrink-0 text-leaf" /> Đặc điểm hình thái & Sinh trưởng
            </h3>
            <div className="grid grid-cols-1 gap-2.5 sm:grid-cols-2 lg:grid-cols-3">
              <div className="min-w-0 rounded-2xl border bg-card p-3">
                <p className="flex items-center gap-1.5 text-[11px] font-semibold text-leaf">
                  <Leaf className="size-3.5 shrink-0" /> Đặc điểm nhận dạng
                </p>
                <p className="mt-1 text-xs leading-relaxed break-words">
                  {info.identification || info.description || "Đang cập nhật thông tin"}
                </p>
              </div>
              <div className="min-w-0 rounded-2xl border bg-card p-3">
                <p className="flex items-center gap-1.5 text-[11px] font-semibold text-amber-600">
                  <Sun className="size-3.5 shrink-0" /> Ánh sáng
                </p>
                <p className="mt-1 text-xs leading-relaxed break-words">{info.light}</p>
              </div>
              <div className="min-w-0 rounded-2xl border bg-card p-3">
                <p className="flex items-center gap-1.5 text-[11px] font-semibold text-sky-600">
                  <Droplets className="size-3.5 shrink-0" /> Tưới nước
                </p>
                <p className="mt-1 text-xs leading-relaxed break-words">{info.water}</p>
              </div>
              <div className="min-w-0 rounded-2xl border bg-card p-3">
                <p className="flex items-center gap-1.5 text-[11px] font-semibold text-emerald-700">
                  <Sprout className="size-3.5 shrink-0" /> Loại rễ & Giá thể
                </p>
                <p className="mt-1 text-xs leading-relaxed break-words">{info.soil}</p>
              </div>
              <div className="min-w-0 rounded-2xl border bg-card p-3">
                <p className="flex items-center gap-1.5 text-[11px] font-semibold text-orange-600">
                  <Thermometer className="size-3.5 shrink-0" /> Nhiệt độ & Độ ẩm
                </p>
                <p className="mt-1 text-xs leading-relaxed break-words">
                  {info.temperature} · Độ ẩm {info.humidity}
                </p>
              </div>
              <div className="min-w-0 rounded-2xl border bg-card p-3">
                <p className="flex items-center gap-1.5 text-[11px] font-semibold text-warning">
                  <AlertTriangle className="size-3.5 shrink-0" /> Độc tính
                </p>
                <p className="mt-1 text-xs leading-relaxed break-words">
                  {info.toxicity || "An toàn / Chưa ghi nhận độc tính"}
                </p>
              </div>
            </div>
          </section>

          {/* Mẹo chăm sóc chi tiết */}
          {info.careTips && info.careTips.length > 0 && (
            <section className="min-w-0">
              <h3 className="mb-1.5 text-xs font-bold uppercase tracking-wider text-forest">Hướng dẫn chăm sóc</h3>
              <ul className="space-y-1 rounded-2xl border bg-card p-3 text-xs leading-relaxed">
                {info.careTips.map((tip, idx) => (
                  <li key={idx} className="flex items-start gap-2">
                    <span className="mt-1.5 size-1.5 shrink-0 rounded-full bg-leaf" />
                    <span className="break-words">{tip}</span>
                  </li>
                ))}
              </ul>
            </section>
          )}

          {/* Hành động */}
          <div className="flex flex-wrap items-center justify-end gap-2 border-t pt-3">
            <Button size="sm" variant="ghost" onClick={() => onOpenChange(false)}>
              Đóng
            </Button>
            {onSaveToGarden && (
              <Button size="sm" onClick={() => { onOpenChange(false); onSaveToGarden(); }}>
                <Sprout /> Lưu vào vườn
              </Button>
            )}
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
