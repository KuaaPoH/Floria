"use client";

import { useEffect, useState, type ReactNode } from "react";
import { usePathname, useRouter } from "next/navigation";
import { LoadingState } from "@/components/layout/states";
import { ensureAuth, useAuth } from "@/stores/auth";

export function UserAuthGuard({ children }: { children: ReactNode }) {
  const router = useRouter();
  const pathname = usePathname() ?? "/";
  const user = useAuth((s) => s.user);
  const status = useAuth((s) => s.status);
  const [checked, setChecked] = useState(false);

  useEffect(() => {
    let active = true;
    void ensureAuth().then((u) => {
      if (!active) return;
      setChecked(true);
      if (!u) {
        const search = typeof window !== "undefined" ? window.location.search : "";
        const target = `${pathname}${search}`;
        router.replace(`/login?redirect=${encodeURIComponent(target)}`);
      }
    });
    return () => {
      active = false;
    };
  }, [pathname, router]);

  useEffect(() => {
    if (checked && status === "anonymous" && !user) {
      const search = typeof window !== "undefined" ? window.location.search : "";
      router.replace(`/login?redirect=${encodeURIComponent(`${pathname}${search}`)}`);
    }
  }, [checked, status, user, pathname, router]);

  if (!checked || !user) {
    return <LoadingState className="min-h-[60vh]" />;
  }

  return <>{children}</>;
}
