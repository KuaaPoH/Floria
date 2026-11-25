import { env, isMock } from "@/config/env";

/**
 * Upload adapter. Mock mode: downscale to a compact data URL kept in local storage.
 * API mode: Cloudinary unsigned upload (cloud "vbiltn75", preset "ml_default") — đồng bộ với App Floria.
 */
export const ACCEPTED_IMAGE_TYPES = ["image/jpeg", "image/png", "image/webp", "image/heic", "image/heif"];
export const MAX_IMAGE_BYTES = 10 * 1024 * 1024;

export function validateImageFile(file: File): "type" | "size" | null {
  if (!ACCEPTED_IMAGE_TYPES.includes(file.type)) return "type";
  if (file.size > MAX_IMAGE_BYTES) return "size";
  return null;
}

export async function fileToDataUrl(file: Blob, maxSize = 900, quality = 0.82): Promise<string> {
  const url = URL.createObjectURL(file);
  try {
    const img = await new Promise<HTMLImageElement>((resolve, reject) => {
      const i = new Image();
      i.onload = () => resolve(i);
      i.onerror = reject;
      i.src = url;
    });
    const scale = Math.min(1, maxSize / Math.max(img.width, img.height));
    const canvas = document.createElement("canvas");
    canvas.width = Math.round(img.width * scale);
    canvas.height = Math.round(img.height * scale);
    canvas.getContext("2d")!.drawImage(img, 0, 0, canvas.width, canvas.height);
    return canvas.toDataURL("image/jpeg", quality);
  } finally {
    URL.revokeObjectURL(url);
  }
}

function dataUrlToBlob(dataUrl: string): Blob {
  const [header, base64] = dataUrl.split(",");
  const mime = header?.match(/:(.*?);/)?.[1] || "image/jpeg";
  const bin = atob(base64 || "");
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return new Blob([bytes], { type: mime });
}

export const uploadService = {
  async uploadImage(file: Blob, folder = "floria"): Promise<string> {
    if (isMock()) return fileToDataUrl(file);
    const form = new FormData();
    form.append("file", file);
    form.append("upload_preset", process.env.NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET ?? "ml_default");
    if (folder) form.append("folder", folder);
    const res = await fetch(`https://api.cloudinary.com/v1_1/${env.cloudinaryCloudName}/image/upload`, {
      method: "POST",
      body: form,
    });
    if (!res.ok) {
      const errText = await res.text().catch(() => "");
      throw new Error(errText || "upload_failed");
    }
    const body = (await res.json()) as { secure_url: string };
    return body.secure_url;
  },
  async uploadMany(files: Blob[], folder?: string) {
    return Promise.all(files.map((f) => uploadService.uploadImage(f, folder)));
  },
  /** Nếu ảnh đang là data URL (base64), tự upload lên Cloudinary để lưu link vĩnh viễn vào Firestore. */
  async ensureUploadedUrl(src: string, folder = "floria"): Promise<string> {
    if (!src.startsWith("data:") || isMock()) return src;
    const blob = dataUrlToBlob(src);
    return uploadService.uploadImage(blob, folder);
  },
};
