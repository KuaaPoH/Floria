"use client";

import type { ReactNode } from "react";
import { Logo } from "@/components/brand/Logo";
import { DemoBadge } from "@/components/layout/DemoBadge";
import { IMG } from "@/mocks/user/images";

export function AuthShell({ title, subtitle, children, quote }: { title: string; subtitle: string; children: ReactNode; quote?: string }) {
  return (
    <div className="grid min-h-screen lg:grid-cols-[1.05fr_1fr]">
      <div className="relative hidden overflow-hidden lg:block">
        <img src={IMG.authLeaves} alt="" className="absolute inset-0 size-full object-cover" />
        <div className="absolute inset-0 bg-gradient-to-t from-forest via-forest/30 to-transparent" />
        <div className="absolute inset-x-0 bottom-0 p-12 text-forest-foreground">
          <p className="max-w-md text-3xl font-semibold leading-tight">{quote ?? "“Khu vườn là nơi thời gian chậm lại — và Floria giúp bạn không bỏ lỡ chiếc lá nào.”"}</p>
        </div>
      </div>
      <div className="flex flex-col bg-background">
        <div className="flex items-center justify-between p-6 md:p-8">
          <Logo />
          <DemoBadge />
        </div>
        <div className="flex flex-1 items-center justify-center px-6 pb-12">
          <div className="w-full max-w-md">
            <h1 className="text-3xl font-bold tracking-tight">{title}</h1>
            <p className="mt-2 text-muted-foreground">{subtitle}</p>
            <div className="mt-8">{children}</div>
          </div>
        </div>
      </div>
    </div>
  );
}

export function GoogleIcon() {
  return (
    <svg viewBox="0 0 24 24" className="size-4" aria-hidden>
      <path fill="#4285F4" d="M23.5 12.3c0-.8-.1-1.6-.2-2.3H12v4.4h6.5a5.6 5.6 0 0 1-2.4 3.6v3h3.9c2.2-2.1 3.5-5.1 3.5-8.7Z" />
      <path fill="#34A853" d="M12 24c3.2 0 6-1.1 7.9-2.9l-3.9-3c-1 .7-2.4 1.1-4 1.1-3.1 0-5.7-2.1-6.6-4.9h-4v3.1A12 12 0 0 0 12 24Z" />
      <path fill="#FBBC05" d="M5.4 14.3a7.2 7.2 0 0 1 0-4.6V6.6h-4a12 12 0 0 0 0 10.8l4-3.1Z" />
      <path fill="#EA4335" d="M12 4.8c1.8 0 3.3.6 4.6 1.8l3.4-3.4A12 12 0 0 0 1.4 6.6l4 3.1C6.3 6.9 8.9 4.8 12 4.8Z" />
    </svg>
  );
}
