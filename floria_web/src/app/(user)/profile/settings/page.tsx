"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Globe, Info, KeyRound, LogOut, Moon, RotateCcw, Sun } from "lucide-react";
import { toast } from "sonner";
import { ConfirmDialog } from "@/components/layout/ConfirmDialog";
import { PageHeader } from "@/components/layout/PageContainer";
import { Button } from "@/components/ui/button";
import { isMock } from "@/config/env";
import { ProfileShell } from "@/features/profile/ProfileShell";
import { cn } from "@/lib/utils";
import { resetDb } from "@/mocks/user/db";
import { authService } from "@/services/auth.service";
import { useAuth } from "@/stores/auth";
import { useSettings } from "@/stores/settings";

export default function SettingsPage() {
  const router = useRouter();
  const user = useAuth((s) => s.user)!;
  const logout = useAuth((s) => s.logout);
  const theme = useSettings((s) => s.theme);
  const lang = useSettings((s) => s.lang);
  const setTheme = useSettings((s) => s.setTheme);
  const setLang = useSettings((s) => s.setLang);
  const [sendingReset, setSendingReset] = useState(false);
  const [resetOpen, setResetOpen] = useState(false);

  const sendPasswordEmail = async () => {
    setSendingReset(true);
    try {
      await authService.sendPasswordReset(user.email);
      toast.success(`Đã ghi nhận yêu cầu đổi mật khẩu tới ${user.email}`);
    } catch (e) {
      toast.error((e as Error).message);
    } finally {
      setSendingReset(false);
    }
  };

  return (
    <ProfileShell>
      <div className="space-y-6">
        <PageHeader eyebrow="Cài đặt" title="Tùy chỉnh & bảo mật" description="Giao diện sáng/tối, ngôn ngữ hiển thị và bảo mật tài khoản Floria." className="mb-2" />

        {/* Appearance */}
        <section className="rounded-3xl border bg-card p-6 shadow-soft">
          <h2 className="text-lg font-semibold">Giao diện hiển thị</h2>
          <p className="mt-1 text-sm text-muted-foreground">Chuyển đổi giữa chế độ Sáng dịu mắt ban ngày và Tối êm dịu ban đêm.</p>
          <div className="mt-4 grid gap-3 sm:grid-cols-2">
            {[
              { value: "light" as const, label: "Light Mode", desc: "Nền kem vườn cây thoáng sáng", icon: Sun },
              { value: "dark" as const, label: "Dark Mode", desc: "Tông xanh rừng sâu dịu mắt", icon: Moon },
            ].map((item) => {
              const active = theme === item.value;
              return (
                <button
                  key={item.value}
                  type="button"
                  onClick={() => setTheme(item.value)}
                  className={cn("flex items-center gap-3 rounded-2xl border p-4 text-left transition-all", active ? "border-leaf bg-mint/40 ring-2 ring-leaf/25" : "hover:border-leaf/40")}
                >
                  <span className="grid size-10 place-items-center rounded-xl bg-mint text-forest"><item.icon className="size-5" /></span>
                  <div>
                    <p className="font-semibold">{item.label}</p>
                    <p className="text-xs text-muted-foreground">{item.desc}</p>
                  </div>
                </button>
              );
            })}
          </div>
        </section>

        {/* Language */}
        <section className="rounded-3xl border bg-card p-6 shadow-soft">
          <h2 className="flex items-center gap-2 text-lg font-semibold"><Globe className="size-5 text-leaf" /> Ngôn ngữ</h2>
          <p className="mt-1 text-sm text-muted-foreground">Áp dụng đồng bộ cho thanh điều hướng, trạng thái cây, lịch chăm sóc và nhãn đơn hàng.</p>
          <div className="mt-4 flex flex-wrap gap-3">
            {[
              { value: "vi" as const, label: "Tiếng Việt" },
              { value: "en" as const, label: "English" },
            ].map((l) => (
              <button
                key={l.value}
                type="button"
                onClick={() => setLang(l.value)}
                className={cn("rounded-2xl border px-5 py-2.5 text-sm font-semibold transition-all", lang === l.value ? "border-forest bg-forest text-forest-foreground" : "bg-background hover:border-leaf/40")}
              >
                {l.label}
              </button>
            ))}
          </div>
        </section>

        {/* Security */}
        <section className="rounded-3xl border bg-card p-6 shadow-soft">
          <h2 className="text-lg font-semibold">Bảo mật tài khoản</h2>
          <div className="mt-4 flex flex-wrap gap-3">
            <Button variant="outline" disabled={sendingReset} onClick={sendPasswordEmail}>
              <KeyRound /> Đổi mật khẩu qua email
            </Button>
            <Button
              variant="danger-soft"
              onClick={async () => {
                await logout();
                router.push("/");
              }}
            >
              <LogOut /> Đăng xuất
            </Button>
          </div>
        </section>

        {/* About */}
        <section className="rounded-3xl border bg-card p-6 shadow-soft">
          <h2 className="flex items-center gap-2 text-lg font-semibold"><Info className="size-5 text-leaf" /> Về Floria</h2>
          <p className="mt-2 text-sm text-muted-foreground">
            Floria — Nền tảng nhận diện loài cây, chẩn đoán bệnh lá và quản lý khu vườn thông minh.
          </p>
          <div className="mt-4 flex flex-wrap items-center gap-3">
            <Button asChild variant="link"><Link href="/terms">Điều khoản sử dụng</Link></Button>
            <Button asChild variant="link"><Link href="/privacy">Chính sách bảo mật</Link></Button>
            {isMock() && (
              <Button variant="ghost" size="sm" className="ml-auto" onClick={() => setResetOpen(true)}>
                <RotateCcw /> Khôi phục dữ liệu demo
              </Button>
            )}
          </div>
        </section>
      </div>

      <ConfirmDialog
        open={resetOpen}
        onOpenChange={setResetOpen}
        title="Khôi phục dữ liệu demo gốc?"
        description="Mọi thay đổi bạn đã thêm/sửa trên trình duyệt ở chế độ demo sẽ được đặt lại về dữ liệu mẫu ban đầu."
        confirmLabel="Khôi phục"
        onConfirm={() => {
          resetDb();
          setResetOpen(false);
          toast.success("Đã khôi phục dữ liệu demo");
          window.location.reload();
        }}
      />
    </ProfileShell>
  );
}
