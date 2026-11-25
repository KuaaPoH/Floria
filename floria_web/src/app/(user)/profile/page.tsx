"use client";

import { useRef, useState } from "react";
import { Calendar, Check, Droplets, HeartPulse, Loader2, Sprout, Upload } from "lucide-react";
import { toast } from "sonner";
import { BOTANICAL_AVATARS, BotanicalAvatar, UserAvatar } from "@/components/botanical/BotanicalAvatar";
import { PageHeader } from "@/components/layout/PageContainer";
import { Button } from "@/components/ui/button";
import { Field } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { gardenStats } from "@/features/garden/logic";
import { ProfileShell } from "@/features/profile/ProfileShell";
import { usePlants, useSchedules } from "@/hooks/queries";
import { useLang } from "@/i18n";
import { formatDate } from "@/lib/format";
import { cn } from "@/lib/utils";
import { authService } from "@/services/auth.service";
import { uploadService } from "@/services/upload.service";
import { useAuth } from "@/stores/auth";

export default function ProfilePage() {
  const user = useAuth((s) => s.user)!;
  const setUser = useAuth((s) => s.setUser);
  const lang = useLang();
  const { data: plants = [] } = usePlants();
  const { data: schedules = [] } = useSchedules();
  const stats = gardenStats(plants, schedules);

  const [displayName, setDisplayName] = useState(user.displayName);
  const [phone, setPhone] = useState(user.phone ?? "");
  const [bio, setBio] = useState(user.bio ?? "");
  const [avatarId, setAvatarId] = useState<string | null>(user.avatarId);
  const [avatarUrl, setAvatarUrl] = useState<string | null>(user.avatarUrl);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);

  const saveProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    if (displayName.trim().length < 2) {
      toast.error("Họ tên tối thiểu 2 ký tự");
      return;
    }
    setSaving(true);
    try {
      const updated = await authService.updateProfile(user.uid, {
        displayName: displayName.trim(),
        phone: phone.trim(),
        bio: bio.trim(),
        avatarId,
        avatarUrl,
      });
      setUser(updated);
      toast.success("Đã cập nhật hồ sơ cá nhân");
    } catch (err) {
      toast.error((err as Error).message);
    } finally {
      setSaving(false);
    }
  };

  return (
    <ProfileShell>
      <div className="space-y-8">
        <PageHeader eyebrow="Tài khoản" title="Hồ sơ cá nhân" description="Thông tin cá nhân, avatar thực vật và thống kê sức khỏe khu vườn của bạn." className="mb-2" />

        {/* Overview & 3 Garden Stats */}
        <section className="grid gap-6 rounded-3xl border bg-card p-6 shadow-soft md:grid-cols-[1.2fr_1fr] md:items-center">
          <div className="flex items-center gap-4">
            <UserAvatar user={{ ...user, avatarId, avatarUrl }} className="size-20 shrink-0" />
            <div className="min-w-0">
              <h2 className="truncate text-2xl font-bold">{user.displayName}</h2>
              <p className="truncate text-sm text-muted-foreground">{user.email}</p>
              <p className="mt-1 inline-flex items-center gap-1.5 text-xs text-muted-foreground">
                <Calendar className="size-3.5" /> Tham gia từ {formatDate(user.joinedAt, lang)}
              </p>
            </div>
          </div>

          <div className="grid grid-cols-3 gap-3">
            {[
              { icon: Sprout, value: stats.caring, label: "Đang chăm", tone: "text-forest dark:text-foreground bg-mint/60" },
              { icon: Droplets, value: stats.needWater, label: "Cần tưới", tone: "text-info bg-info-soft" },
              { icon: HeartPulse, value: stats.healthy, label: "Khỏe mạnh", tone: "text-success bg-success-soft" },
            ].map((item) => (
              <div key={item.label} className="rounded-2xl border bg-background/60 p-3 text-center">
                <span className={cn("mx-auto mb-1.5 grid size-8 place-items-center rounded-xl", item.tone)}>
                  <item.icon className="size-4" />
                </span>
                <p className="text-xl font-bold">{item.value}</p>
                <p className="text-[11px] text-muted-foreground">{item.label}</p>
              </div>
            ))}
          </div>
        </section>

        {/* Botanical Avatar Picker + Form */}
        <form onSubmit={saveProfile} className="space-y-6 rounded-3xl border bg-card p-6 shadow-soft">
          <div>
            <p className="text-sm font-semibold">Bộ 6 avatar thực vật Floria hoặc tải ảnh riêng</p>
            <div className="mt-3 flex flex-wrap items-center gap-3">
              {BOTANICAL_AVATARS.map((av) => {
                const selected = !avatarUrl && avatarId === av.id;
                return (
                  <button
                    key={av.id}
                    type="button"
                    onClick={() => { setAvatarUrl(null); setAvatarId(av.id); }}
                    className={cn("relative flex flex-col items-center gap-1 rounded-2xl border p-2 transition-all", selected ? "border-leaf bg-mint/50 ring-2 ring-leaf/30" : "hover:border-leaf/40")}
                  >
                    <BotanicalAvatar id={av.id} className="size-12" />
                    <span className="text-[11px] font-medium">{av.label}</span>
                    {selected && <span className="absolute -right-1 -top-1 grid size-5 place-items-center rounded-full bg-leaf text-primary-foreground"><Check className="size-3" /></span>}
                  </button>
                );
              })}

              <input
                ref={fileRef}
                type="file"
                accept="image/*"
                className="hidden"
                onChange={async (e) => {
                  const f = e.target.files?.[0];
                  if (!f) return;
                  setUploading(true);
                  try {
                    const url = await uploadService.uploadImage(f, "avatars");
                    setAvatarUrl(url);
                  } catch {
                    toast.error("Tải ảnh thất bại");
                  } finally {
                    setUploading(false);
                    e.target.value = "";
                  }
                }}
              />
              <button
                type="button"
                disabled={uploading}
                onClick={() => fileRef.current?.click()}
                className={cn("flex h-[76px] w-20 flex-col items-center justify-center gap-1 rounded-2xl border-2 border-dashed text-xs font-medium text-muted-foreground transition-colors hover:border-leaf hover:text-leaf", avatarUrl && "border-leaf bg-mint/40 text-forest")}
              >
                {uploading ? <Loader2 className="size-4 animate-spin" /> : <Upload className="size-4" />}
                <span>Ảnh riêng</span>
              </button>
            </div>
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <Field label="Họ và tên" htmlFor="pf-name">
              <Input id="pf-name" value={displayName} onChange={(e) => setDisplayName(e.target.value)} maxLength={60} />
            </Field>
            <Field label="Số điện thoại" htmlFor="pf-phone">
              <Input id="pf-phone" value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="0912 345 678" maxLength={20} />
            </Field>
          </div>

          <Field label="Giới thiệu bản thân" htmlFor="pf-bio">
            <Textarea id="pf-bio" rows={3} value={bio} onChange={(e) => setBio(e.target.value)} maxLength={240} placeholder="Chia sẻ ngắn về khu vườn của bạn…" />
          </Field>

          <div className="flex justify-end">
            <Button type="submit" size="lg" disabled={saving || uploading}>
              {saving && <Loader2 className="animate-spin" />} Lưu thay đổi
            </Button>
          </div>
        </form>
      </div>
    </ProfileShell>
  );
}
