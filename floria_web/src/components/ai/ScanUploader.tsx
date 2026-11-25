"use client";

import { useRef, useState } from "react";
import { ImagePlus, Loader2, RefreshCw, Trash2, Upload } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { uploadService, validateImageFile } from "@/services/upload.service";

/** Drag & drop / file picker with preview, replace and remove. Uploads to Cloudinary and emits URL. */
export function ScanUploader({ value, onChange, disabled, scanning, className, hint }: { value: string | null; onChange: (v: string | null) => void; disabled?: boolean; scanning?: boolean; className?: string; hint?: string }) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [drag, setDrag] = useState(false);
  const [uploading, setUploading] = useState(false);

  const handleFile = async (file: File | undefined) => {
    if (!file) return;
    const err = validateImageFile(file);
    if (err === "type") {
      toast.error("Định dạng không hỗ trợ. Vui lòng chọn ảnh JPG, PNG hoặc WEBP.");
      return;
    }
    if (err === "size") {
      toast.error("Ảnh vượt quá 10MB.");
      return;
    }
    setUploading(true);
    try {
      const url = await uploadService.uploadImage(file, "floria_scans");
      onChange(url);
    } catch {
      toast.error("Tải ảnh lên Cloudinary thất bại.");
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className={cn("relative overflow-hidden rounded-3xl border-2 border-dashed bg-card transition-colors", drag ? "border-leaf bg-mint/60" : "border-sage/60", className)}>
      <input ref={inputRef} type="file" accept="image/jpeg,image/png,image/webp" className="hidden" onChange={(e) => void handleFile(e.target.files?.[0])} />
      {value ? (
        <div className="relative aspect-[4/3] bg-forest">
          <img src={value} alt="Ảnh đã chọn" className="size-full object-contain" />
          {scanning && (
            <div className="pointer-events-none absolute inset-0 overflow-hidden">
              <div className="animate-scan-line absolute inset-x-0 h-1/3 bg-gradient-to-b from-transparent via-sage/50 to-transparent" />
            </div>
          )}
          {!scanning && !disabled && (
            <div className="absolute right-3 top-3 flex gap-2">
              <Button size="sm" variant="glass" onClick={() => inputRef.current?.click()}><RefreshCw /> Thay ảnh</Button>
              <Button size="icon-sm" variant="glass" onClick={() => onChange(null)} aria-label="Xóa ảnh"><Trash2 /></Button>
            </div>
          )}
        </div>
      ) : (
        <div
          onDragOver={(e) => {
            e.preventDefault();
            setDrag(true);
          }}
          onDragLeave={() => setDrag(false)}
          onDrop={(e) => {
            e.preventDefault();
            setDrag(false);
            void handleFile(e.dataTransfer.files?.[0]);
          }}
          className="flex aspect-[4/3] flex-col items-center justify-center gap-4 p-6 text-center"
        >
          <div className="grid size-16 place-items-center rounded-2xl bg-mint text-leaf"><ImagePlus className="size-7" /></div>
          <div>
            <p className="font-semibold">Kéo & thả ảnh vào đây</p>
            <p className="mt-1 text-sm text-muted-foreground">{hint ?? "JPG, PNG hoặc WEBP — tối đa 10MB"}</p>
          </div>
          <Button onClick={() => inputRef.current?.click()} disabled={disabled || uploading}>
            {uploading ? <Loader2 className="animate-spin" /> : <Upload />}
            {uploading ? "Đang tải ảnh..." : "Tải ảnh lên"}
          </Button>
        </div>
      )}
    </div>
  );
}
