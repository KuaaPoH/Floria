"use client";

import { useState } from "react";
import Link from "next/link";
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";
import { AlertCircle, ArrowLeft, Loader2, MailCheck } from "lucide-react";
import { DemoNotice } from "@/components/layout/DemoBadge";
import { Button } from "@/components/ui/button";
import { Field } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { AuthShell } from "@/features/auth/AuthShell";
import { forgotSchema } from "@/features/auth/schemas";
import { authService } from "@/services/auth.service";

export default function ForgotPasswordPage() {
  const [state, setState] = useState<{ kind: "idle" } | { kind: "sent"; email: string } | { kind: "error"; message: string }>({ kind: "idle" });
  const { register, handleSubmit, formState } = useForm<{ email: string }>({ resolver: zodResolver(forgotSchema), defaultValues: { email: "" } });
  const onSubmit = handleSubmit(async ({ email }) => {
    try {
      await authService.sendPasswordReset(email);
      setState({ kind: "sent", email });
    } catch (e) {
      setState({ kind: "error", message: (e as Error).message });
    }
  });
  return (
    <AuthShell title="Quên mật khẩu?" subtitle="Nhập email đã đăng ký, chúng tôi sẽ gửi liên kết đặt lại mật khẩu.">
      {state.kind === "sent" ? (
        <div className="rounded-3xl border bg-card p-6 text-center shadow-soft">
          <div className="mx-auto grid size-14 place-items-center rounded-2xl bg-success-soft text-success"><MailCheck className="size-6" /></div>
          <h2 className="mt-4 text-lg font-semibold">Yêu cầu đã được ghi nhận</h2>
          <p className="mt-1 text-sm text-muted-foreground">Liên kết đặt lại mật khẩu sẽ được gửi tới <b>{state.email}</b>.</p>
          <DemoNotice className="mt-4 text-left">Chế độ demo chưa kết nối Firebase nên không có email thật được gửi đi.</DemoNotice>
          <Button asChild variant="outline" className="mt-5"><Link href="/login"><ArrowLeft /> Về đăng nhập</Link></Button>
        </div>
      ) : (
        <form onSubmit={onSubmit} className="space-y-4" noValidate>
          {state.kind === "error" && (
            <div className="flex items-center gap-2 rounded-xl border border-danger/30 bg-danger-soft/60 px-3 py-2 text-sm text-danger"><AlertCircle className="size-4" />{state.message}</div>
          )}
          <Field label="Email" htmlFor="email" error={formState.errors.email?.message}>
            <Input id="email" type="email" placeholder="ban@email.com" aria-invalid={!!formState.errors.email} {...register("email")} />
          </Field>
          <Button type="submit" size="lg" className="w-full" disabled={formState.isSubmitting}>
            {formState.isSubmitting && <Loader2 className="animate-spin" />} Gửi yêu cầu đặt lại
          </Button>
          <Button asChild variant="ghost" className="w-full"><Link href="/login"><ArrowLeft /> Quay lại đăng nhập</Link></Button>
        </form>
      )}
    </AuthShell>
  );
}
