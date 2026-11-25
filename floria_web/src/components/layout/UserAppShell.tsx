"use client";

import type { ReactNode } from "react";
import { usePathname } from "next/navigation";
import { AppBootstrap } from "./AppBootstrap";
import { SiteFooter } from "./SiteFooter";
import { SiteHeader } from "./SiteHeader";

const BARE_ROUTES = ["/login", "/register", "/forgot-password"];

export function UserAppShell({ children }: { children: ReactNode }) {
  const pathname = usePathname() ?? "/";
  const isBare = BARE_ROUTES.includes(pathname);
  const noFooter = pathname.startsWith("/assistant");

  return (
    <>
      <AppBootstrap />
      {isBare ? (
        <>{children}</>
      ) : (
        <div className="flex min-h-screen flex-col">
          <SiteHeader />
          <main className="flex-1">{children}</main>
          {!noFooter && <SiteFooter />}
        </div>
      )}
    </>
  );
}
