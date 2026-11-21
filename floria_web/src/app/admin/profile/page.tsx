"use client";

import { useEffect, useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { EmailAuthProvider, reauthenticateWithCredential, updatePassword } from "firebase/auth";
import { KeyRound, Mail, Save, ShieldCheck, UserCheck } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { PageHeader } from "@/components/shared/page-header";
import { Field } from "@/components/shared/field";
import { ImageUploader } from "@/components/shared/image-uploader";
import { UserAvatar } from "@/components/shared/user-avatar";
import { useAuthStore } from "@/stores/auth-store";
import { adminsService } from "@/services";
import { apiRequest } from "@/lib/api-client";
import { getFirebaseClientAuth } from "@/lib/firebase-client";
import { ROLES } from "@/lib/rbac";

export default function AdminProfilePage() {
  const qc = useQueryClient();
  const session = useAuthStore((s) => s.session);
  const updateSession = useAuthStore((s) => s.updateSession);

  const [name, setName] = useState(session?.name ?? "");
  const [avatar, setAvatar] = useState(session?.avatar ?? "");
  const [savingProfile, setSavingProfile] = useState(false);

  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [savingPassword, setSavingPassword] = useState(false);
  const [isPasswordAccount, setIsPasswordAccount] = useState(true);

  useEffect(() => {
    if (session) {
      setName(session.name);
      setAvatar(session.avatar ?? "");
    }
  }, [session]);

  useEffect(() => {
    const auth = getFirebaseClientAuth();
    void auth.authStateReady().then(() => {
      const providers = auth.currentUser?.providerData.map((p) => p.providerId) ?? [];
      if (providers.length > 0) {
        setIsPasswordAccount(providers.includes("password"));
      }
    });
  }, []);

  const roleName = ROLES.find((r) => r.id === session?.role)?.name ?? session?.role ?? "";

  const handleSaveProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) {
      toast.error("Vui lòng nhập họ và tên");
      return;
    }
    setSavingProfile(true);
    try {
      const updated = await apiRequest<{ name: string; avatar?: string }>("/profile", {
        method: "PATCH",
        body: JSON.stringify({ name: name.trim(), avatar: avatar.trim() }),
      });
      updateSession({ name: updated.name, avatar: updated.avatar });
      void qc.invalidateQueries({ queryKey: [adminsService.key] });
      toast.success("Đã cập nhật hồ sơ quản trị viên");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Không thể cập nhật hồ sơ");
    } finally {
      setSavingProfile(false);
    }
  };

  const handleChangePassword = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentPassword || !newPassword || !confirmPassword) {
      toast.error("Vui lòng nhập đầy đủ các trường mật khẩu");
      return;
    }
    if (newPassword.length < 6) {
      toast.error("Mật khẩu mới phải có ít nhất 6 ký tự");
      return;
    }
    if (newPassword !== confirmPassword) {
      toast.error("Mật khẩu xác nhận không khớp");
      return;
    }

    const auth = getFirebaseClientAuth();
    const user = auth.currentUser;
    if (!user || !user.email) {
      toast.error("Không tìm thấy phiên đăng nhập Firebase hiện tại");
      return;
    }

    setSavingPassword(true);
    try {
      const credential = EmailAuthProvider.credential(user.email, currentPassword);
      await reauthenticateWithCredential(user, credential);
      await updatePassword(user, newPassword);
      setCurrentPassword("");
      setNewPassword("");
      setConfirmPassword("");
      toast.success("Đã đổi mật khẩu thành công");
    } catch (err: unknown) {
      const code = (err as { code?: string })?.code ?? "";
      if (code === "auth/wrong-password" || code === "auth/invalid-credential") {
        toast.error("Mật khẩu hiện tại không chính xác");
      } else if (code === "auth/too-many-requests") {
        toast.error("Bạn thao tác quá nhiều lần, vui lòng thử lại sau");
      } else {
        toast.error(err instanceof Error ? err.message : "Không thể đổi mật khẩu");
      }
    } finally {
      setSavingPassword(false);
    }
  };

  return (
    <>
      <PageHeader
        title="Hồ sơ cá nhân"
        description="Cập nhật ảnh đại diện, thông tin hiển thị và mật khẩu đăng nhập của tài khoản quản trị."
      />

      <div className="grid gap-6 lg:grid-cols-[1.2fr_1fr]">
        <form onSubmit={handleSaveProfile} className="card-surface space-y-5 p-6">
          <div className="flex flex-wrap items-center gap-4 border-b pb-5">
            <UserAvatar name={name || session?.name || "Admin"} src={avatar || undefined} className="size-16 text-lg" />
            <div className="min-w-0 flex-1">
              <p className="truncate text-lg font-semibold text-foreground">{name || session?.name}</p>
              <div className="mt-1 flex flex-wrap items-center gap-3 text-xs text-muted-foreground">
                <span className="inline-flex items-center gap-1">
                  <Mail className="size-3.5" /> {session?.email}
                </span>
                <span className="inline-flex items-center gap-1 rounded-full bg-forest/10 px-2.5 py-0.5 font-medium text-forest">
                  <ShieldCheck className="size-3.5" /> {roleName}
                </span>
              </div>
            </div>
          </div>

          <Field label="Ảnh đại diện">
            <ImageUploader value={avatar} aspect="square" onChange={setAvatar} />
          </Field>

          <div className="grid gap-4 sm:grid-cols-2">
            <Field label="Họ và tên *">
              <Input value={name} onChange={(e) => setName(e.target.value)} placeholder="Nhập họ và tên" />
            </Field>
            <Field label="Email đăng nhập">
              <Input value={session?.email ?? ""} disabled />
            </Field>
          </div>

          <div className="flex justify-end pt-2">
            <Button type="submit" disabled={savingProfile}>
              <Save /> {savingProfile ? "Đang lưu..." : "Lưu thông tin hồ sơ"}
            </Button>
          </div>
        </form>

        <div className="space-y-6">
          <form onSubmit={handleChangePassword} className="card-surface space-y-4 p-6">
            <div className="flex items-center gap-2 border-b pb-3">
              <KeyRound className="size-4 text-forest" />
              <h3 className="text-base font-semibold">Đổi mật khẩu</h3>
            </div>

            {!isPasswordAccount ? (
              <div className="rounded-xl border bg-surface-2/60 p-4 text-sm text-muted-foreground">
                <p className="font-medium text-foreground">Đăng nhập qua Google</p>
                <p className="mt-1 text-xs">
                  Tài khoản này đang xác thực bằng Google Sign-In, mật khẩu được quản lý trực tiếp bởi tài khoản Google của bạn.
                </p>
              </div>
            ) : (
              <>
                <Field label="Mật khẩu hiện tại *">
                  <Input
                    type="password"
                    value={currentPassword}
                    onChange={(e) => setCurrentPassword(e.target.value)}
                    placeholder="Nhập mật khẩu đang dùng"
                  />
                </Field>
                <Field label="Mật khẩu mới (tối thiểu 6 ký tự) *">
                  <Input
                    type="password"
                    minLength={6}
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    placeholder="Tối thiểu 6 ký tự"
                  />
                </Field>
                <Field label="Xác nhận mật khẩu mới *">
                  <Input
                    type="password"
                    minLength={6}
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    placeholder="Nhập lại mật khẩu mới (tối thiểu 6 ký tự)"
                  />
                </Field>
                <div className="flex justify-end pt-2">
                  <Button type="submit" variant="outline" disabled={savingPassword}>
                    <UserCheck /> {savingPassword ? "Đang cập nhật..." : "Cập nhật mật khẩu"}
                  </Button>
                </div>
              </>
            )}
          </form>
        </div>
      </div>
    </>
  );
}
