"use client";

import { Suspense, useEffect, useState } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import {
  applyActionCode,
  confirmPasswordReset,
  verifyPasswordResetCode,
} from "firebase/auth";
import {
  AlertCircle,
  ArrowRight,
  CheckCircle2,
  Eye,
  EyeOff,
  KeyRound,
  Loader2,
  Lock,
  MailCheck,
  ShieldCheck,
  Sparkles,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { FloriaMark } from "@/components/shared/floria-logo";
import { getFirebaseClientAuth } from "@/lib/firebase-client";

function ResetPasswordInner() {
  const searchParams = useSearchParams();
  const mode = searchParams.get("mode") ?? "resetPassword";
  const oobCode = searchParams.get("oobCode") ?? "";

  const [loading, setLoading] = useState(true);
  const [verifyingCode, setVerifyingCode] = useState(true);
  const [accountEmail, setAccountEmail] = useState("");
  const [verifyEmailSuccess, setVerifyEmailSuccess] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [success, setSuccess] = useState(false);

  useEffect(() => {
    if (!oobCode) {
      // Hỗ trợ xem trước giao diện khi mở trực tiếp
      setAccountEmail("ban@floria.id.vn");
      setVerifyingCode(false);
      setLoading(false);
      return;
    }

    const auth = getFirebaseClientAuth();

    // Trường hợp 1: Xác thực email (verifyEmail)
    if (mode === "verifyEmail") {
      applyActionCode(auth, oobCode)
        .then(() => {
          setVerifyEmailSuccess(true);
        })
        .catch((err: unknown) => {
          const code = (err as { code?: string })?.code;
          if (code === "auth/invalid-action-code") {
            setErrorMessage("Mã xác thực không hợp lệ hoặc đã được sử dụng trước đó.");
          } else if (code === "auth/expired-action-code") {
            setErrorMessage("Liên kết xác thực đã hết hạn. Vui lòng yêu cầu gửi lại từ ứng dụng.");
          } else {
            setErrorMessage("Không thể xác thực email. Vui lòng thử lại.");
          }
        })
        .finally(() => {
          setVerifyingCode(false);
          setLoading(false);
        });
      return;
    }

    // Trường hợp 2: Đặt lại mật khẩu (resetPassword)
    verifyPasswordResetCode(auth, oobCode)
      .then((email) => {
        setAccountEmail(email);
      })
      .catch((err: unknown) => {
        const code = (err as { code?: string })?.code;
        if (code === "auth/invalid-action-code") {
          setErrorMessage("Liên kết đặt lại mật khẩu không hợp lệ hoặc đã được sử dụng.");
        } else if (code === "auth/expired-action-code") {
          setErrorMessage("Liên kết đặt lại mật khẩu đã hết hạn. Vui lòng yêu cầu cấp lại từ ứng dụng.");
        } else {
          setErrorMessage("Không thể kiểm tra mã xác thực. Vui lòng thử lại.");
        }
      })
      .finally(() => {
        setVerifyingCode(false);
        setLoading(false);
      });
  }, [oobCode, mode]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!password || password.length < 6) {
      setErrorMessage("Mật khẩu phải có ít nhất 6 ký tự.");
      return;
    }
    if (password !== confirmPassword) {
      setErrorMessage("Mật khẩu xác nhận không khớp.");
      return;
    }

    setSubmitting(true);
    setErrorMessage(null);

    try {
      const auth = getFirebaseClientAuth();
      await confirmPasswordReset(auth, oobCode, password);
      setSuccess(true);
    } catch (err: unknown) {
      const code = (err as { code?: string })?.code;
      if (code === "auth/weak-password") {
        setErrorMessage("Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.");
      } else if (code === "auth/invalid-action-code" || code === "auth/expired-action-code") {
        setErrorMessage("Liên kết đã hết hạn hoặc không còn hiệu lực. Vui lòng yêu cầu link mới trên app.");
      } else {
        setErrorMessage((err as Error)?.message || "Không thể cập nhật mật khẩu. Vui lòng thử lại sau.");
      }
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <main className="relative flex min-h-screen flex-col items-center justify-center bg-background px-4 py-12">
      {/* Nền hiệu ứng botanical trang nhã */}
      <div className="pointer-events-none absolute inset-0 overflow-hidden opacity-30">
        <div className="absolute -top-32 left-1/2 size-[500px] -translate-x-1/2 rounded-full bg-forest/15 blur-3xl" />
        <div className="absolute -bottom-32 right-1/4 size-[400px] rounded-full bg-forest/10 blur-3xl" />
      </div>

      <div className="relative w-full max-w-md">
        {/* Header thương hiệu Floria */}
        <div className="mb-6 flex flex-col items-center text-center">
          <div className="mb-3 flex size-14 items-center justify-center rounded-2xl bg-forest/10 text-forest shadow-sm">
            <FloriaMark className="size-8" />
          </div>
          <span className="text-xs font-bold tracking-[0.25em] text-forest">FLORIA PLATFORM</span>
          <p className="text-xs text-muted-foreground mt-0.5">Ứng dụng chăm sóc cây trồng thông minh</p>
        </div>

        {/* Khung nội dung chính */}
        <div className="card-surface overflow-hidden rounded-3xl border bg-card/95 p-7 shadow-xl backdrop-blur-md">
          {verifyingCode ? (
            <div className="flex flex-col items-center justify-center py-10 text-center">
              <Loader2 className="size-9 animate-spin text-forest" />
              <p className="mt-4 text-sm font-medium text-foreground">Đang xác thực liên kết bảo mật...</p>
              <p className="mt-1 text-xs text-muted-foreground">Vui lòng chờ trong giây lát</p>
            </div>
          ) : verifyEmailSuccess ? (
            /* Trạng thái xác thực email thành công */
            <div className="flex flex-col items-center py-6 text-center">
              <div className="flex size-14 items-center justify-center rounded-2xl bg-emerald-500/10 text-emerald-600">
                <MailCheck className="size-8" />
              </div>
              <h1 className="mt-4 text-xl font-bold text-foreground">Xác thực email thành công!</h1>
              <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
                Tài khoản của bạn đã được kích hoạt hoàn tất.
              </p>
            </div>
          ) : success ? (
            /* Trạng thái đổi mật khẩu thành công */
            <div className="flex flex-col items-center py-6 text-center">
              <div className="flex size-14 items-center justify-center rounded-2xl bg-emerald-500/10 text-emerald-600">
                <CheckCircle2 className="size-8" />
              </div>
              <h1 className="mt-4 text-xl font-bold text-foreground">Đã đặt lại mật khẩu!</h1>
              <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
                Mật khẩu mới cho tài khoản <strong className="text-foreground">{accountEmail}</strong> đã được cập nhật thành công.
              </p>
              <p className="mt-1.5 text-xs text-muted-foreground">
                Bây giờ bạn đã có thể đăng nhập bằng mật khẩu mới.
              </p>
            </div>
          ) : errorMessage && !accountEmail ? (
            /* Trạng thái lỗi link không hợp lệ */
            <div className="flex flex-col items-center py-6 text-center">
              <div className="flex size-14 items-center justify-center rounded-2xl bg-destructive/10 text-destructive">
                <AlertCircle className="size-8" />
              </div>
              <h1 className="mt-4 text-xl font-bold text-foreground">Liên kết không hợp lệ</h1>
              <p className="mt-2 text-sm leading-relaxed text-muted-foreground">{errorMessage}</p>
              <p className="mt-1 text-xs text-muted-foreground">
                Mỗi liên kết chỉ sử dụng được 1 lần để đảm bảo an toàn cho tài khoản.
              </p>
            </div>
          ) : (
            /* Form nhập mật khẩu mới */
            <div>
              <div className="text-center">
                <h1 className="text-xl font-bold tracking-tight text-foreground">Thiết lập mật khẩu mới</h1>
                <p className="mt-1.5 text-xs text-muted-foreground">
                  Cho tài khoản: <span className="font-semibold text-foreground">{accountEmail}</span>
                </p>
              </div>

              {errorMessage && (
                <div className="mt-4 flex items-start gap-2.5 rounded-xl border border-destructive/20 bg-destructive/10 p-3 text-xs text-destructive">
                  <AlertCircle className="size-4 shrink-0 mt-0.5" />
                  <span>{errorMessage}</span>
                </div>
              )}

              <form onSubmit={handleSubmit} className="mt-5 space-y-4">
                <div>
                  <label className="mb-1.5 block text-xs font-semibold text-foreground">
                    Mật khẩu mới
                  </label>
                  <div className="relative">
                    <Input
                      type={showPassword ? "text" : "password"}
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      placeholder="Nhập tối thiểu 6 ký tự"
                      className="pr-10 text-sm"
                      required
                      autoFocus
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                      tabIndex={-1}
                    >
                      {showPassword ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
                    </button>
                  </div>
                </div>

                <div>
                  <label className="mb-1.5 block text-xs font-semibold text-foreground">
                    Xác nhận mật khẩu mới
                  </label>
                  <div className="relative">
                    <Input
                      type={showConfirm ? "text" : "password"}
                      value={confirmPassword}
                      onChange={(e) => setConfirmPassword(e.target.value)}
                      placeholder="Nhập lại mật khẩu mới"
                      className="pr-10 text-sm"
                      required
                    />
                    <button
                      type="button"
                      onClick={() => setShowConfirm(!showConfirm)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                      tabIndex={-1}
                    >
                      {showConfirm ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
                    </button>
                  </div>
                </div>

                <Button
                  type="submit"
                  disabled={submitting}
                  className="w-full bg-forest text-white hover:bg-forest/90 h-10 font-semibold shadow-md shadow-forest/20 mt-2"
                >
                  {submitting ? (
                    <>
                      <Loader2 className="size-4 animate-spin mr-2" />
                      Đang cập nhật...
                    </>
                  ) : (
                    <>
                      <KeyRound className="size-4 mr-2" />
                      Cập nhật mật khẩu
                    </>
                  )}
                </Button>
              </form>
            </div>
          )}
        </div>
      </div>
    </main>
  );
}

export default function ResetPasswordPage() {
  return (
    <Suspense
      fallback={
        <main className="flex min-h-screen items-center justify-center bg-background">
          <Loader2 className="size-8 animate-spin text-forest" />
        </main>
      }
    >
      <ResetPasswordInner />
    </Suspense>
  );
}
