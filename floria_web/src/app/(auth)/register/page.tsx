"use client";

import { Suspense, useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { zodResolver } from "@hookform/resolvers/zod";
import { Controller, useForm } from "react-hook-form";
import { Eye, EyeOff, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { LoadingState } from "@/components/layout/states";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { Field } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { AuthShell } from "@/features/auth/AuthShell";
import { safeRedirect } from "@/features/auth/redirect";
import { registerSchema, type RegisterValues } from "@/features/auth/schemas";
import { authService } from "@/services/auth.service";
import { useAuth } from "@/stores/auth";

function RegisterForm() {
  const searchParams = useSearchParams();
  const redirect = searchParams.get("redirect") ?? undefined;
  const router = useRouter();
  const setUser = useAuth((s) => s.setUser);
  const [show, setShow] = useState(false);
  const { register, handleSubmit, formState, control } = useForm<RegisterValues>({
    resolver: zodResolver(registerSchema),
    defaultValues: { displayName: "", email: "", password: "", confirmPassword: "", acceptTerms: false as unknown as true },
  });
  const e = formState.errors;
  const onSubmit = handleSubmit(async (v) => {
    try {
      const u = await authService.register(v);
      setUser(u);
      toast.success("Tạo tài khoản thành công. Hãy tạo khu vườn đầu tiên!");
      router.push(safeRedirect(redirect, "/garden"));
    } catch (err) {
      toast.error((err as Error).message);
    }
  });
  return (
    <AuthShell title="Tạo khu vườn của bạn" subtitle="Miễn phí. Chỉ mất chưa đến một phút." quote="“Người trồng cây là người tin vào ngày mai.”">
      <form onSubmit={onSubmit} className="space-y-4" noValidate>
        <Field label="Họ tên" htmlFor="displayName" error={e.displayName?.message}>
          <Input id="displayName" autoComplete="name" placeholder="Nguyễn Minh Anh" aria-invalid={!!e.displayName} {...register("displayName")} />
        </Field>
        <Field label="Email" htmlFor="email" error={e.email?.message}>
          <Input id="email" type="email" autoComplete="email" placeholder="ban@email.com" aria-invalid={!!e.email} {...register("email")} />
        </Field>
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Mật khẩu" htmlFor="password" error={e.password?.message}>
            <div className="relative">
              <Input id="password" type={show ? "text" : "password"} autoComplete="new-password" aria-invalid={!!e.password} className="pr-10" {...register("password")} />
              <button type="button" onClick={() => setShow((s) => !s)} className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground" aria-label="Hiện/ẩn mật khẩu">
                {show ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
              </button>
            </div>
          </Field>
          <Field label="Xác nhận mật khẩu" htmlFor="confirmPassword" error={e.confirmPassword?.message}>
            <Input id="confirmPassword" type={show ? "text" : "password"} autoComplete="new-password" aria-invalid={!!e.confirmPassword} {...register("confirmPassword")} />
          </Field>
        </div>
        <p className="text-xs text-muted-foreground">Tối thiểu 8 ký tự, gồm chữ và số.</p>
        <div>
          <label className="flex items-start gap-2 text-sm">
            <Controller control={control} name="acceptTerms" render={({ field }) => <Checkbox className="mt-0.5" checked={field.value === true} onCheckedChange={(c) => field.onChange(c === true)} />} />
            <span>Tôi đồng ý với <Link href="/terms" className="font-semibold text-leaf hover:underline">Điều khoản sử dụng</Link> và <Link href="/privacy" className="font-semibold text-leaf hover:underline">Chính sách bảo mật</Link></span>
          </label>
          {e.acceptTerms && <p className="mt-1 text-xs font-medium text-danger">{e.acceptTerms.message}</p>}
        </div>
        <Button type="submit" size="lg" className="w-full" disabled={formState.isSubmitting}>
          {formState.isSubmitting && <Loader2 className="animate-spin" />} Tạo tài khoản
        </Button>
      </form>
      <p className="mt-8 text-center text-sm text-muted-foreground">
        Đã có tài khoản? <Link href={redirect ? `/login?redirect=${encodeURIComponent(redirect)}` : "/login"} className="font-semibold text-leaf hover:underline">Đăng nhập</Link>
      </p>
    </AuthShell>
  );
}

export default function RegisterPage() {
  return (
    <Suspense fallback={<LoadingState className="min-h-screen" />}>
      <RegisterForm />
    </Suspense>
  );
}
