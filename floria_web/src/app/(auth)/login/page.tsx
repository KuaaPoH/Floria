"use client";

import { Suspense, useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { zodResolver } from "@hookform/resolvers/zod";
import { Controller, useForm } from "react-hook-form";
import { Eye, EyeOff, Info, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { LoadingState } from "@/components/layout/states";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { Field } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { AuthShell, GoogleIcon } from "@/features/auth/AuthShell";
import { safeRedirect } from "@/features/auth/redirect";
import { loginSchema, type LoginValues } from "@/features/auth/schemas";
import { isMock } from "@/config/env";
import { DEMO_EMAIL, DEMO_PASSWORD } from "@/mocks/user/seed";
import { authService } from "@/services/auth.service";
import { useAuth } from "@/stores/auth";

function LoginForm() {
  const searchParams = useSearchParams();
  const redirect = searchParams.get("redirect") ?? undefined;
  const router = useRouter();
  const setUser = useAuth((s) => s.setUser);
  const [show, setShow] = useState(false);
  const [googleLoading, setGoogleLoading] = useState(false);
  const form = useForm<LoginValues>({ resolver: zodResolver(loginSchema), defaultValues: { email: "", password: "", remember: true } });
  const { register, handleSubmit, formState, control, setValue } = form;

  const done = (u: Awaited<ReturnType<typeof authService.login>>) => {
    setUser(u);
    toast.success(`Chào mừng trở lại, ${u.displayName}!`);
    router.push(safeRedirect(redirect));
  };

  const onSubmit = handleSubmit(async (v) => {
    try {
      done(await authService.login(v.email, v.password, v.remember));
    } catch (e) {
      toast.error((e as Error).message);
    }
  });

  return (
    <AuthShell title="Chào mừng trở lại" subtitle="Đăng nhập để tiếp tục chăm sóc khu vườn của bạn.">
      {isMock() && (
        <button
          type="button"
          onClick={() => {
            setValue("email", DEMO_EMAIL);
            setValue("password", DEMO_PASSWORD);
          }}
          className="mb-6 flex w-full items-start gap-3 rounded-2xl border border-leaf/25 bg-mint/60 p-3 text-left text-sm transition-colors hover:bg-mint"
        >
          <Info className="mt-0.5 size-4 shrink-0 text-leaf" />
          <span>
            Tài khoản dùng thử: <b>{DEMO_EMAIL}</b> / <b>{DEMO_PASSWORD}</b>
            <span className="block text-xs text-muted-foreground">Bấm để điền nhanh</span>
          </span>
        </button>
      )}
      <form onSubmit={onSubmit} className="space-y-4" noValidate>
        <Field label="Email" htmlFor="email" error={formState.errors.email?.message}>
          <Input id="email" type="email" autoComplete="email" placeholder="ban@email.com" aria-invalid={!!formState.errors.email} {...register("email")} />
        </Field>
        <Field
          label="Mật khẩu"
          htmlFor="password"
          error={formState.errors.password?.message}
          hint={<Link href="/forgot-password" className="text-xs font-semibold text-leaf hover:underline">Quên mật khẩu?</Link>}
        >
          <div className="relative">
            <Input id="password" type={show ? "text" : "password"} autoComplete="current-password" placeholder="••••••••" aria-invalid={!!formState.errors.password} className="pr-11" {...register("password")} />
            <button type="button" onClick={() => setShow((s) => !s)} className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground" aria-label={show ? "Ẩn mật khẩu" : "Hiện mật khẩu"}>
              {show ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
            </button>
          </div>
        </Field>
        <label className="flex items-center gap-2 text-sm">
          <Controller control={control} name="remember" render={({ field }) => <Checkbox checked={field.value} onCheckedChange={(c) => field.onChange(c === true)} />} />
          Ghi nhớ đăng nhập
        </label>
        <Button type="submit" size="lg" className="w-full" disabled={formState.isSubmitting}>
          {formState.isSubmitting && <Loader2 className="animate-spin" />} Đăng nhập
        </Button>
      </form>
      <div className="my-6 flex items-center gap-3 text-xs text-muted-foreground"><span className="h-px flex-1 bg-border" />hoặc<span className="h-px flex-1 bg-border" /></div>
      <Button
        variant="outline"
        size="lg"
        className="w-full"
        disabled={googleLoading}
        onClick={async () => {
          setGoogleLoading(true);
          try {
            done(await authService.loginWithGoogle());
          } catch (e) {
            toast.error((e as Error).message);
          } finally {
            setGoogleLoading(false);
          }
        }}
      >
        {googleLoading ? <Loader2 className="animate-spin" /> : <GoogleIcon />} Tiếp tục với Google
      </Button>
      <p className="mt-8 text-center text-sm text-muted-foreground">
        Chưa có tài khoản? <Link href={redirect ? `/register?redirect=${encodeURIComponent(redirect)}` : "/register"} className="font-semibold text-leaf hover:underline">Đăng ký ngay</Link>
      </p>
    </AuthShell>
  );
}

export default function LoginPage() {
  return (
    <Suspense fallback={<LoadingState className="min-h-screen" />}>
      <LoginForm />
    </Suspense>
  );
}
