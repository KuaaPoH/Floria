"use client";

import type { ReactNode } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { History, LifeBuoy, MapPin, Package, Settings, User as UserIcon } from "lucide-react";
import { UserAvatar } from "@/components/botanical/BotanicalAvatar";
import { PageContainer } from "@/components/layout/PageContainer";
import { useT } from "@/i18n";
import { common } from "@/i18n/common";
import { cn } from "@/lib/utils";
import { useAuth } from "@/stores/auth";

const PROFILE_LINKS = [
  { href: "/profile", key: "profile" as const, icon: UserIcon, exact: true },
  { href: "/profile/addresses", key: "addresses" as const, icon: MapPin },
  { href: "/profile/scan-history", key: "scanHistory" as const, icon: History },
  { href: "/profile/support", key: "support" as const, icon: LifeBuoy },
  { href: "/profile/settings", key: "settings" as const, icon: Settings },
];

export function ProfileShell({ children }: { children: ReactNode }) {
  const pathname = usePathname() ?? "/profile";
  const user = useAuth((s) => s.user);
  const t = useT(common);

  return (
    <PageContainer className="max-w-6xl">
      <div className="grid gap-8 lg:grid-cols-[260px_1fr] lg:items-start">
        <aside className="space-y-4 lg:sticky lg:top-24">
          {user && (
            <div className="hidden items-center gap-3 rounded-3xl border bg-card p-4 shadow-soft lg:flex">
              <UserAvatar user={user} className="size-12 shrink-0" />
              <div className="min-w-0">
                <p className="truncate font-semibold">{user.displayName}</p>
                <p className="truncate text-xs text-muted-foreground">{user.email}</p>
              </div>
            </div>
          )}
          <nav className="scrollbar-none -mx-1 flex gap-1.5 overflow-x-auto px-1 pb-1 lg:mx-0 lg:flex-col lg:rounded-3xl lg:border lg:bg-card lg:p-2 lg:shadow-soft">
            {PROFILE_LINKS.map((item) => {
              const active = item.exact ? pathname === item.href : pathname === item.href || pathname.startsWith(item.href + "/");
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={cn(
                    "inline-flex shrink-0 items-center gap-2.5 rounded-2xl px-3.5 py-2.5 text-sm font-medium transition-colors",
                    active ? "bg-forest text-forest-foreground shadow-soft" : "text-muted-foreground hover:bg-mint/70 hover:text-forest dark:hover:text-foreground",
                  )}
                >
                  <item.icon className="size-4 shrink-0" />
                  <span>{t(item.key)}</span>
                </Link>
              );
            })}
            <Link
              href="/orders"
              className="inline-flex shrink-0 items-center gap-2.5 rounded-2xl px-3.5 py-2.5 text-sm font-medium text-muted-foreground transition-colors hover:bg-mint/70 hover:text-forest dark:hover:text-foreground lg:mt-1 lg:border-t lg:pt-3"
            >
              <Package className="size-4 shrink-0" />
              <span>{t("orders")}</span>
            </Link>
          </nav>
        </aside>
        <div className="min-w-0">{children}</div>
      </div>
    </PageContainer>
  );
}
