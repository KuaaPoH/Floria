"use client";

import { Suspense, useEffect, useState, type ReactNode } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { ShieldOff } from "lucide-react";
import { AppSidebar } from "@/components/layout/app-sidebar";
import { AppHeader } from "@/components/layout/app-header";
import { findLeaf } from "@/components/layout/nav-config";
import { EmptyState, TableSkeleton } from "@/components/shared/states";
import { Button } from "@/components/ui/button";
import { useAuthStore } from "@/stores/auth-store";
import { useRbacStore } from "@/stores/rbac-store";
import { can } from "@/lib/rbac";
import { IS_MOCK } from "@/lib/config";
import { getFirebaseClientAuth } from "@/lib/firebase-client";

export default function AdminLayout({ children }: { children: ReactNode }) {
  const session = useAuthStore((s) => s.session);
  const logout = useAuthStore((s) => s.logout);
  const refreshSession = useAuthStore((s) => s.refreshSession);
  const matrix = useRbacStore((s) => s.matrix);
  const loadMatrix = useRbacStore((s) => s.loadMatrix);
  const path = usePathname() ?? "/";
  const router = useRouter();
  const [mounted, setMounted] = useState(false);
  const isLoginRoute = path === "/admin/login";

  useEffect(() => {
    setMounted(true);
  }, []);

  // 1. Chuyển hướng sang trang đăng nhập nếu chưa có session
  useEffect(() => {
    if (!mounted || isLoginRoute) return;
    if (!session) {
      router.replace("/admin/login");
    }
  }, [mounted, session, isLoginRoute, router]);

  // 2. Xác thực với Firebase đúng 1 lần khi layout được mount (tránh lặp vô tận)
  useEffect(() => {
    if (!mounted || isLoginRoute || IS_MOCK) return undefined;
    let active = true;
    const auth = getFirebaseClientAuth();
    void auth.authStateReady().then(async () => {
      if (!active) return;
      if (!auth.currentUser) {
        await logout();
        if (active) router.replace("/admin/login");
        return;
      }
      await refreshSession();
      await loadMatrix();
    });
    return () => {
      active = false;
    };
  }, [mounted, isLoginRoute, logout, refreshSession, loadMatrix, router]);

  if (isLoginRoute) {
    return <>{children}</>;
  }

  if (!mounted || !session) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background">
        <div className="w-full max-w-md p-6">
          <TableSkeleton rows={4} />
        </div>
      </div>
    );
  }

  const leaf = findLeaf(path);
  const allowed = !leaf || can(matrix, session.role, leaf.module, "view");

  return (
    <div className="flex min-h-screen w-full bg-background">
      <AppSidebar />
      <div className="flex min-w-0 flex-1 flex-col">
        <AppHeader />
        {IS_MOCK && (
          <div className="border-b border-warning/20 bg-warning-soft/60 px-6 py-1.5 text-center text-[11px] font-medium text-warning">
            Chế độ DEMO — dữ liệu mô phỏng lưu trên trình duyệt, chưa kết nối Spring Boot API / AI Engine / Firebase / ZaloPay.
          </div>
        )}
        <main className="mx-auto w-full max-w-[1480px] flex-1 px-4 py-6 md:px-8 md:py-8">
          {allowed ? (
            <Suspense fallback={<TableSkeleton rows={6} />}>{children}</Suspense>
          ) : (
            <div className="card-surface">
              <EmptyState
                icon={ShieldOff}
                title="Bạn không có quyền truy cập trang này"
                description="Vai trò hiện tại không được cấp quyền Xem cho module này. Liên hệ Super Admin để được cấp quyền."
                action={
                  <Button asChild variant="outline">
                    <Link href="/admin/overview">Về Tổng quan</Link>
                  </Button>
                }
              />
            </div>
          )}
        </main>
      </div>
    </div>
  );
}
