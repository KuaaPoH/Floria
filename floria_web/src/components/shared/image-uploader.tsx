"use client";

import { useRef, useState } from "react";
import { ImagePlus, Loader2, RefreshCw, X } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { IS_MOCK } from "@/lib/config";
import { cn } from "@/lib/utils";

const CLOUDINARY_CLOUD_NAME = process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME ?? "vbiltn75";
const CLOUDINARY_UPLOAD_PRESET = process.env.NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET ?? "ml_default";

interface ImageUploaderProps {
  value?: string;
  onChange: (url: string) => void;
  className?: string;
  aspect?: "square" | "wide";
  label?: string;
  /** Chỉ đọc ảnh cục bộ (data URL), không tải lên Cloudinary (dùng cho Sandbox test tạm). */
  localOnly?: boolean;
}

async function uploadToCloudinary(file: File): Promise<string> {
  const formData = new FormData();
  formData.append("file", file);
  formData.append("upload_preset", CLOUDINARY_UPLOAD_PRESET);

  const res = await fetch(`https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD_NAME}/image/upload`, {
    method: "POST",
    body: formData,
  });

  const data = (await res.json()) as { secure_url?: string; error?: { message?: string } };
  if (!res.ok || !data.secure_url) {
    throw new Error(data.error?.message ?? "Tải ảnh lên Cloudinary thất bại");
  }
  return data.secure_url;
}

/** Uploads image to Cloudinary in API mode, or previews via data URL in mock mode. */
export function ImageUploader({ value, onChange, className, aspect = "square", label = "Kéo thả hoặc chọn ảnh", localOnly = false }: ImageUploaderProps) {
  const ref = useRef<HTMLInputElement>(null);
  const [drag, setDrag] = useState(false);
  const [uploading, setUploading] = useState(false);

  const read = async (file?: File) => {
    if (!file || !file.type.startsWith("image/")) return;
    if (file.size > 5 * 1024 * 1024) {
      toast.error("Ảnh vượt quá giới hạn 5MB");
      return;
    }

    if (IS_MOCK || localOnly) {
      const reader = new FileReader();
      reader.onload = () => onChange(String(reader.result));
      reader.readAsDataURL(file);
      return;
    }

    setUploading(true);
    try {
      const url = await uploadToCloudinary(file);
      onChange(url);
      toast.success("Đã tải ảnh lên Cloudinary");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Không thể tải ảnh lên Cloudinary");
    } finally {
      setUploading(false);
    }
  };

  return (
    <div
      className={cn(
        "group relative overflow-hidden rounded-xl border-2 border-dashed bg-surface-2/50 transition-colors",
        drag ? "border-leaf bg-accent" : "border-border",
        aspect === "square" ? "aspect-square" : "aspect-[2/1]",
        className,
      )}
      onDragOver={(e) => {
        e.preventDefault();
        setDrag(true);
      }}
      onDragLeave={() => setDrag(false)}
      onDrop={(e) => {
        e.preventDefault();
        setDrag(false);
        void read(e.dataTransfer.files?.[0]);
      }}
    >
      <input
        ref={ref}
        type="file"
        accept="image/*"
        className="hidden"
        onChange={(e) => {
          void read(e.target.files?.[0]);
          e.target.value = "";
        }}
      />
      {uploading && (
        <div className="absolute inset-0 z-10 flex flex-col items-center justify-center gap-2 bg-background/80 backdrop-blur-xs">
          <Loader2 className="size-6 animate-spin text-primary" />
          <span className="text-xs font-medium text-foreground">Đang tải lên Cloudinary...</span>
        </div>
      )}
      {value ? (
        <>
          <img src={value} alt="Ảnh xem trước" className="size-full object-cover" />
          <div className="absolute inset-x-2 bottom-2 flex justify-end gap-1.5 opacity-0 transition-opacity group-hover:opacity-100">
            <Button type="button" size="sm" variant="secondary" disabled={uploading} onClick={() => ref.current?.click()}>
              <RefreshCw /> Đổi ảnh
            </Button>
            <Button type="button" size="icon-sm" variant="secondary" disabled={uploading} onClick={() => onChange("")} aria-label="Xoá ảnh">
              <X />
            </Button>
          </div>
        </>
      ) : (
        <button
          type="button"
          disabled={uploading}
          onClick={() => ref.current?.click()}
          className="flex size-full flex-col items-center justify-center gap-2 p-4 text-center"
        >
          <span className="grid size-10 place-items-center rounded-full bg-card text-leaf shadow-card">
            <ImagePlus className="size-5" />
          </span>
          <span className="text-sm font-medium text-foreground">{label}</span>
          <span className="text-xs text-muted-foreground">PNG, JPG tối đa 5MB</span>
        </button>
      )}
    </div>
  );
}
