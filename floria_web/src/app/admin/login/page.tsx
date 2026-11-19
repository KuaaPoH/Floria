"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { Eye, EyeOff, Loader2, ShieldCheck } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/shared/field";
import { FloriaMark } from "@/components/shared/floria-logo";
import { DemoBadge } from "@/components/shared/demo-badge";
import { DEMO_ACCOUNTS, useAuthStore } from "@/stores/auth-store";
import { IS_MOCK } from "@/lib/config";
import { ROLES } from "@/lib/rbac";

const schema = z.object({
  email: z.string().min(1, "Vui lòng nhập email").email("Email không hợp lệ"),
  password: z.string().min(6, "Mật khẩu tối thiểu 6 ký tự"),
});
type FormValues = z.infer<typeof schema>;

export default function LoginPage() {
  const session = useAuthStore((s) => s.session);
  const login = useAuthStore((s) => s.login);
  const loginWithFirebase = useAuthStore((s) => s.loginWithFirebase);
  const loginWithGoogle = useAuthStore((s) => s.loginWithGoogle);
  const router = useRouter();
  const [mounted, setMounted] = useState(false);
  const [show, setShow] = useState(false);
  const [googleLoading, setGoogleLoading] = useState(false);
  const form = useForm<FormValues>({ resolver: zodResolver(schema), defaultValues: { email: "", password: "" } });

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    if (mounted && session) {
      router.replace("/admin/overview");
    }
  }, [mounted, session, router]);

  const onSubmit = form.handleSubmit(async (v) => {
    if (IS_MOCK) {
      await new Promise((r) => setTimeout(r, 350));
      const s = login(v.email, v.password);
      if (!s) {
        form.setError("password", { message: "Email hoặc mật khẩu không đúng" });
        return;
      }
      toast.success(`Chào mừng trở lại, ${s.name}!`);
      router.push("/admin/overview");
      return;
    }

    try {
      const s = await loginWithFirebase(v.email, v.password);
      toast.success(`Chào mừng trở lại, ${s.name}!`);
      router.push("/admin/overview");
    } catch (err) {
      const msg = err instanceof Error ? err.message : "Đăng nhập thất bại";
      form.setError("password", { message: msg });
    }
  });

  const handleGoogleLogin = async () => {
    setGoogleLoading(true);
    try {
      const s = await loginWithGoogle();
      toast.success(`Chào mừng trở lại, ${s.name}!`);
      router.push("/admin/overview");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Đăng nhập Google thất bại");
    } finally {
      setGoogleLoading(false);
    }
  };

  if (mounted && session) return null;

  return (
    <div className="grid min-h-screen lg:grid-cols-[1.05fr_1fr]">
      <div className="relative hidden overflow-hidden bg-forest-deep lg:block">
        <img src="/assets/login-botanical.jpg" alt="" className="absolute inset-0 size-full object-cover opacity-90" />
        <div className="absolute inset-0 bg-gradient-to-t from-forest-deep via-forest-deep/30 to-transparent" />
        <div className="relative flex h-full flex-col justify-between p-12 text-sidebar-accent-foreground">
          <div className="flex items-center gap-3">
            <FloriaMark className="size-10" />
            <div className="leading-tight">
              <p className="text-lg font-bold tracking-[0.2em]">FLORIA</p>
              <p className="text-[11px] tracking-[0.24em] text-sidebar-muted">ADMIN PORTAL</p>
            </div>
          </div>
          <div className="max-w-md">
            <p className="text-xs font-semibold tracking-[0.3em] text-sidebar-primary">GROW SMARTER. MANAGE GREENER.</p>
            <h1 className="mt-4 text-4xl font-semibold leading-tight">Nền tảng quản trị thực vật thông minh.</h1>
            <p className="mt-4 text-sm leading-relaxed text-sidebar-foreground/80">
              Quản lý mô hình AI nhận diện cây và bệnh, từ điển thực vật, cửa hàng làm vườn và trải nghiệm ứng dụng Floria — tất cả ở một nơi.
            </p>
          </div>
        </div>
      </div>

      <div className="flex items-center justify-center p-6 sm:p-12">
        <div className="w-full max-w-sm">
          <div className="mb-8 flex items-center gap-3 lg:hidden">
            <FloriaMark className="size-10" />
            <p className="text-lg font-bold tracking-[0.2em] text-forest">FLORIA</p>
          </div>
          <h2 className="text-2xl font-semibold tracking-tight">Đăng nhập</h2>
          <p className="mt-1 text-sm text-muted-foreground">Dành cho quản trị viên, botanist và nhân viên CSKH.</p>

          <form onSubmit={onSubmit} className="mt-8 space-y-4" noValidate>
            <Field label="Email" htmlFor="email" error={form.formState.errors.email?.message}>
              <Input id="email" type="email" autoComplete="email" placeholder="ten@floria.vn" {...form.register("email")} />
            </Field>
            <Field label="Mật khẩu" htmlFor="password" error={form.formState.errors.password?.message}>
              <div className="relative">
                <Input id="password" type={show ? "text" : "password"} autoComplete="current-password" className="pr-10" {...form.register("password")} />
                <button
                  type="button"
                  onClick={() => setShow(!show)}
                  className="absolute right-2 top-1/2 grid size-7 -translate-y-1/2 place-items-center rounded text-muted-foreground hover:bg-muted"
                  aria-label="Hiện mật khẩu"
                >
                  {show ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
                </button>
              </div>
            </Field>
            <Button type="submit" size="lg" className="w-full" disabled={form.formState.isSubmitting || googleLoading}>
              {form.formState.isSubmitting ? <Loader2 className="animate-spin" /> : <ShieldCheck />}
              Đăng nhập
            </Button>
            {!IS_MOCK && (
              <Button
                type="button"
                variant="outline"
                size="lg"
                className="w-full"
                disabled={form.formState.isSubmitting || googleLoading}
                onClick={handleGoogleLogin}
              >
                {googleLoading && <Loader2 className="animate-spin" />}
                Đăng nhập bằng Google (Firebase Auth)
              </Button>
            )}
          </form>

          {IS_MOCK && (
            <div className="mt-8 rounded-xl border bg-surface-2/60 p-4">
              <div className="mb-3 flex items-center justify-between">
                <p className="text-xs font-semibold text-foreground">Tài khoản demo</p>
                <DemoBadge label="Demo" />
              </div>
              <div className="space-y-1.5">
                {DEMO_ACCOUNTS.map((a) => (
                  <button
                    key={a.email}
                    type="button"
                    onClick={() => {
                      form.setValue("email", a.email);
                      form.setValue("password", a.password);
                      form.clearErrors();
                    }}
                    className="flex w-full items-center justify-between rounded-lg bg-card px-3 py-2 text-left text-xs shadow-xs ring-1 ring-border transition hover:ring-sage"
                  >
                    <span className="font-medium text-foreground">{ROLES.find((r) => r.id === a.role)?.name}</span>
                    <span className="text-muted-foreground">{a.email}</span>
                  </button>
                ))}
              </div>
              <p className="mt-2 text-[11px] text-muted-foreground">Mật khẩu chung: floria123</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
