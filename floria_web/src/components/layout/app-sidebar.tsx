"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { ChevronDown, LogOut, PanelLeftClose, PanelLeftOpen } from "lucide-react";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel, DropdownMenuSeparator, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { Sheet, SheetContent, SheetTitle } from "@/components/ui/sheet";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";
import { FloriaMark } from "@/components/shared/floria-logo";
import { UserAvatar } from "@/components/shared/user-avatar";
import { useAuthStore } from "@/stores/auth-store";
import { useRbacStore } from "@/stores/rbac-store";
import { useUiStore } from "@/stores/ui-store";
import { useNavBadges } from "@/hooks/use-nav-badges";
import { can, ROLES } from "@/lib/rbac";
import { cn } from "@/lib/utils";
import { NAV, type NavItem, type NavLeaf, type BadgeKey } from "./nav-config";

function useVisibleNav() {
  const role = useAuthStore((s) => s.session?.role);
  const matrix = useRbacStore((s) => s.matrix);
  const allowed = (m?: NavLeaf["module"]) => !!role && !!m && can(matrix, role, m, "view");
  return NAV.map((g) => ({
    ...g,
    items: g.items
      .map((it) => (it.children ? { ...it, children: it.children.filter((c) => allowed(c.module)) } : it))
      .filter((it) => (it.children ? it.children.length > 0 : allowed(it.module))),
  })).filter((g) => g.items.length > 0);
}

const isActive = (path: string, to: string) => path === to || path.startsWith(to + "/");

function CountBadge({ value, compact }: { value: number; compact?: boolean }) {
  if (!value) return null;
  return (
    <span
      className={cn(
        "grid place-items-center rounded-full bg-sidebar-primary font-semibold text-sidebar-primary-foreground tabular",
        compact ? "absolute -right-1 -top-1 size-4 text-[9px]" : "ml-auto h-5 min-w-5 px-1.5 text-[10px]",
      )}
    >
      {value > 99 ? "99+" : value}
    </span>
  );
}

function SidebarBody({ collapsed, onNavigate }: { collapsed: boolean; onNavigate?: () => void }) {
  const path = usePathname() ?? "/";
  const groups = useVisibleNav();
  const badges = useNavBadges();
  const session = useAuthStore((s) => s.session);
  const logout = useAuthStore((s) => s.logout);
  const { toggleCollapsed } = useUiStore();

  const [open, setOpen] = useState<Record<string, boolean>>({});
  useEffect(() => {
    // keep the group containing the active route expanded
    const next: Record<string, boolean> = {};
    NAV.forEach((g) => g.items.forEach((it) => it.children?.some((c) => isActive(path, c.to)) && (next[it.title] = true)));
    setOpen((o) => ({ ...o, ...next }));
  }, [path]);

  const sumBadges = (it: NavItem) => it.children?.reduce((s, c) => s + (c.badge ? badges[c.badge] : 0), 0) ?? 0;

  const leafClass = (active: boolean) =>
    cn(
      "group/leaf relative flex h-9 items-center gap-3 rounded-lg px-3 text-[13.5px] font-medium transition-colors",
      active ? "bg-sidebar-accent text-sidebar-accent-foreground" : "text-sidebar-foreground/80 hover:bg-sidebar-accent/60 hover:text-sidebar-accent-foreground",
    );

  return (
    <div className="leaf-pattern flex h-full flex-col bg-sidebar text-sidebar-foreground">
      <div className={cn("flex h-16 shrink-0 items-center gap-3 border-b border-sidebar-border/60", collapsed ? "justify-center px-2" : "px-5")}>
        <FloriaMark className="size-9" />
        {!collapsed && (
          <div className="leading-tight">
            <p className="text-[15px] font-bold tracking-[0.18em] text-sidebar-accent-foreground">FLORIA</p>
            <p className="text-[10px] font-medium tracking-[0.2em] text-sidebar-muted">ADMIN PORTAL</p>
          </div>
        )}
      </div>

      <nav className="sidebar-scroll flex-1 overflow-y-auto px-3 py-4">
        {groups.map((g) => (
          <div key={g.label} className="mb-5">
            {!collapsed ? (
              <p className="mb-2 px-3 text-[10.5px] font-semibold uppercase tracking-[0.16em] text-sidebar-muted">{g.label}</p>
            ) : (
              <div className="mx-auto mb-2 h-px w-6 bg-sidebar-border" />
            )}
            <ul className="space-y-0.5">
              {g.items.map((it) => {
                const Icon = it.icon;
                if (!it.children) {
                  const active = isActive(path, it.to!);
                  return (
                    <li key={it.title}>
                      <CollapsedTip show={collapsed} label={it.title}>
                        <Link href={it.to!} onClick={onNavigate} className={cn(leafClass(active), collapsed && "justify-center px-0")}>
                          {active && <span className="absolute left-0 top-2 h-5 w-[3px] rounded-r bg-sidebar-primary" />}
                          <Icon className="size-[18px] shrink-0" />
                          {!collapsed && <span className="truncate">{it.title}</span>}
                        </Link>
                      </CollapsedTip>
                    </li>
                  );
                }
                const groupActive = it.children.some((c) => isActive(path, c.to));
                const total = sumBadges(it);
                if (collapsed) {
                  return (
                    <li key={it.title}>
                      <DropdownMenu>
                        <DropdownMenuTrigger className={cn(leafClass(groupActive), "w-full justify-center px-0")} aria-label={it.title}>
                          <span className="relative">
                            <Icon className="size-[18px]" />
                            <CountBadge value={total} compact />
                          </span>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent side="right" align="start" className="w-56">
                          <DropdownMenuLabel>{it.title}</DropdownMenuLabel>
                          <DropdownMenuSeparator />
                          {it.children.map((c) => (
                            <DropdownMenuItem key={c.to} asChild>
                              <Link href={c.to} className={cn(isActive(path, c.to) && "bg-accent font-medium")}>
                                <c.icon /> {c.title}
                                {c.badge && badges[c.badge] > 0 && <span className="ml-auto text-xs text-muted-foreground">{badges[c.badge]}</span>}
                              </Link>
                            </DropdownMenuItem>
                          ))}
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </li>
                  );
                }
                const isOpen = open[it.title] ?? false;
                return (
                  <li key={it.title}>
                    <button
                      type="button"
                      onClick={() => setOpen((o) => ({ ...o, [it.title]: !isOpen }))}
                      className={cn(leafClass(false), "w-full", groupActive && "text-sidebar-accent-foreground")}
                      aria-expanded={isOpen}
                    >
                      <Icon className="size-[18px] shrink-0" />
                      <span className="truncate">{it.title}</span>
                      {!isOpen && total > 0 && <CountBadge value={total} />}
                      <ChevronDown className={cn("size-4 shrink-0 opacity-60 transition-transform", total > 0 && !isOpen ? "ml-1" : "ml-auto", isOpen && "rotate-180")} />
                    </button>
                    {isOpen && (
                      <ul className="ml-[21px] mt-0.5 space-y-0.5 border-l border-sidebar-border pl-2.5">
                        {it.children.map((c) => {
                          const active = isActive(path, c.to);
                          return (
                            <li key={c.to}>
                              <Link
                                href={c.to}
                                onClick={onNavigate}
                                className={cn(
                                  "flex h-8 items-center gap-2 rounded-md px-2.5 text-[13px] transition-colors",
                                  active ? "bg-sidebar-accent font-medium text-sidebar-accent-foreground" : "text-sidebar-foreground/75 hover:bg-sidebar-accent/50 hover:text-sidebar-accent-foreground",
                                )}
                              >
                                <span className="truncate">{c.title}</span>
                                {c.badge && <CountBadge value={badges[c.badge as BadgeKey]} />}
                              </Link>
                            </li>
                          );
                        })}
                      </ul>
                    )}
                  </li>
                );
              })}
            </ul>
          </div>
        ))}
      </nav>

      <div className="shrink-0 border-t border-sidebar-border/60 p-3">
        {session && (
          <div className={cn("flex items-center gap-3 rounded-xl bg-sidebar-accent/50 p-2", collapsed && "justify-center bg-transparent p-0")}>
            <UserAvatar name={session.name} className="size-9 bg-sidebar-primary text-sidebar-primary-foreground" />
            {!collapsed && (
              <div className="min-w-0 flex-1 leading-tight">
                <p className="truncate text-[13px] font-semibold text-sidebar-accent-foreground">{session.name}</p>
                <p className="truncate text-[11px] text-sidebar-muted">{ROLES.find((r) => r.id === session.role)?.name}</p>
              </div>
            )}
            {!collapsed && (
              <button onClick={logout} className="grid size-8 place-items-center rounded-lg text-sidebar-muted hover:bg-sidebar-accent hover:text-sidebar-accent-foreground" aria-label="Đăng xuất" title="Đăng xuất">
                <LogOut className="size-4" />
              </button>
            )}
          </div>
        )}
        <button
          onClick={toggleCollapsed}
          className={cn("mt-2 hidden h-8 w-full items-center gap-2 rounded-lg px-3 text-xs text-sidebar-muted hover:bg-sidebar-accent/60 hover:text-sidebar-accent-foreground lg:flex", collapsed && "justify-center px-0")}
          aria-label={collapsed ? "Mở rộng thanh bên" : "Thu gọn thanh bên"}
        >
          {collapsed ? <PanelLeftOpen className="size-4" /> : <><PanelLeftClose className="size-4" /> Thu gọn</>}
        </button>
      </div>
    </div>
  );
}

function CollapsedTip({ show, label, children }: { show: boolean; label: string; children: React.ReactNode }) {
  if (!show) return <>{children}</>;
  return (
    <Tooltip>
      <TooltipTrigger asChild>{children}</TooltipTrigger>
      <TooltipContent side="right">{label}</TooltipContent>
    </Tooltip>
  );
}

export function AppSidebar() {
  const { collapsed, mobileOpen, setMobileOpen } = useUiStore();
  return (
    <TooltipProvider delayDuration={100}>
      <aside
        className={cn("sticky top-0 hidden h-screen shrink-0 transition-[width] duration-200 lg:block", collapsed ? "w-[76px]" : "w-[255px]")}
      >
        <SidebarBody collapsed={collapsed} />
      </aside>
      <Sheet open={mobileOpen} onOpenChange={setMobileOpen}>
        <SheetContent side="left" className="w-[270px] border-0 p-0">
          <SheetTitle className="sr-only">Điều hướng</SheetTitle>
          <SidebarBody collapsed={false} onNavigate={() => setMobileOpen(false)} />
        </SheetContent>
      </Sheet>
    </TooltipProvider>
  );
}
