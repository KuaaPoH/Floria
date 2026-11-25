"use client";

import { useEffect, useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { CheckCircle2, ExternalLink, Loader2, RefreshCw, ShieldCheck } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogTitle } from "@/components/ui/dialog";
import { formatVND } from "@/lib/format";
import { commerceService } from "@/services/commerce.service";

export interface ZaloPaySessionInfo {
  orderId: string;
  orderCode: string;
  amount: number;
  orderUrl: string;
  appTransId: string;
}

interface ZaloPayGatewayDialogProps {
  session: ZaloPaySessionInfo | null;
  onClose: () => void;
  onPaid: (session: ZaloPaySessionInfo) => void;
}

export function ZaloPayGatewayDialog({ session, onClose, onPaid }: ZaloPayGatewayDialogProps) {
  const queryClient = useQueryClient();
  const [checking, setChecking] = useState(false);
  const [paid, setPaid] = useState(false);

  useEffect(() => {
    if (!session) {
      setPaid(false);
      setChecking(false);
      return;
    }

    let cancelled = false;
    const poll = async () => {
      try {
        const res = await commerceService.queryZaloPayPayment(session.appTransId, session.orderId);
        if (!cancelled && res.return_code === 1) {
          setPaid(true);
          await queryClient.invalidateQueries({ queryKey: ["orders"] });
          toast.success("Thanh toán ZaloPay thành công!");
          setTimeout(() => {
            if (!cancelled) onPaid(session);
          }, 900);
        }
      } catch {
        // Bỏ qua lỗi polling ngầm để không làm phiền người dùng
      }
    };

    const interval = setInterval(poll, 3500);
    return () => {
      cancelled = true;
      clearInterval(interval);
    };
  }, [session, onPaid, queryClient]);

  const handleManualCheck = async () => {
    if (!session || checking || paid) return;
    setChecking(true);
    try {
      const res = await commerceService.queryZaloPayPayment(session.appTransId, session.orderId);
      if (res.return_code === 1) {
        setPaid(true);
        await queryClient.invalidateQueries({ queryKey: ["orders"] });
        toast.success("Thanh toán ZaloPay thành công!");
        setTimeout(() => onPaid(session), 800);
      } else if (res.is_processing) {
        toast.info("Giao dịch đang được xử lý trên ZaloPay. Vui lòng đợi vài giây.");
      } else {
        toast.error("Giao dịch chưa hoàn tất trên cổng ZaloPay.");
      }
    } catch (err) {
      toast.error((err as Error).message || "Không thể kiểm tra trạng thái ZaloPay.");
    } finally {
      setChecking(false);
    }
  };

  return (
    <Dialog open={!!session} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="overflow-hidden rounded-3xl p-0 sm:max-w-md">
        {/* Header mô phỏng giống ZaloPayPaymentScreen trên App */}
        <div className="border-b bg-card px-6 py-4">
          <div className="flex items-center gap-3 pr-6">
            <span className="rounded-md bg-[#0068FF] px-2.5 py-1 text-xs font-extrabold tracking-tight text-white">
              ZaloPay
            </span>
            <div className="min-w-0">
              <DialogTitle className="text-base font-bold">Cổng thanh toán ZaloPay</DialogTitle>
              <DialogDescription className="truncate text-xs">
                Đơn #{session?.orderCode} • {session ? formatVND(session.amount) : ""}
              </DialogDescription>
            </div>
          </div>
        </div>

        <div className="space-y-4 p-6">
          {paid ? (
            <div className="flex flex-col items-center rounded-2xl border border-emerald-200 bg-emerald-50/70 p-6 text-center dark:border-emerald-900 dark:bg-emerald-950/30">
              <CheckCircle2 className="size-12 text-emerald-600" />
              <p className="mt-3 text-base font-bold text-emerald-800 dark:text-emerald-300">
                Thanh toán thành công!
              </p>
              <p className="mt-1 text-xs text-emerald-700/80 dark:text-emerald-400">
                Đang chuyển về chi tiết đơn hàng của bạn...
              </p>
            </div>
          ) : (
            <>
              <div className="rounded-2xl border bg-muted/40 p-4 text-sm">
                <div className="flex items-center justify-between gap-2">
                  <span className="text-muted-foreground">Tổng thanh toán</span>
                  <span className="text-lg font-extrabold text-[#0068FF]">
                    {session ? formatVND(session.amount) : ""}
                  </span>
                </div>
                <div className="mt-2 flex items-center justify-between gap-2 border-t pt-2 text-xs">
                  <span className="text-muted-foreground">Mã giao dịch</span>
                  <span className="font-mono font-semibold">{session?.appTransId}</span>
                </div>
                <div className="mt-2.5 flex items-center gap-2 rounded-xl bg-[#EAF2FF] px-3 py-2 text-xs font-medium text-[#0068FF] dark:bg-[#0068FF]/15">
                  <Loader2 className="size-3.5 shrink-0 animate-spin" />
                  <span>Hệ thống đang tự động kiểm tra trạng thái thanh toán...</span>
                </div>
              </div>

              <Button
                asChild
                size="lg"
                className="w-full bg-[#0068FF] font-semibold text-white hover:bg-[#0055D4]"
              >
                <a href={session?.orderUrl} target="_blank" rel="noopener noreferrer">
                  <ExternalLink className="size-4" /> Mở cổng thanh toán ZaloPay
                </a>
              </Button>

              <div className="flex items-center justify-center gap-1.5 text-[11px] text-muted-foreground">
                <ShieldCheck className="size-3.5 text-[#0068FF]" />
                <span>Kết nối bảo mật qua ZaloPay Sandbox OpenAPI v2</span>
              </div>
            </>
          )}

          {!paid && (
            <div className="flex flex-col-reverse gap-2 border-t pt-4 sm:flex-row sm:justify-between">
              <Button type="button" variant="ghost" onClick={onClose}>
                Thanh toán sau
              </Button>
              <Button type="button" variant="outline" disabled={checking} onClick={handleManualCheck}>
                {checking ? <Loader2 className="size-4 animate-spin" /> : <RefreshCw className="size-4" />}
                Kiểm tra ngay
              </Button>
            </div>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
}
