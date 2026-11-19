"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { Bell, ChevronRight, Command, LogOut, Menu, Search, ShieldCheck, UserCog } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuRadioGroup,
  DropdownMenuRadioItem,
  DropdownMenuSeparator,
  DropdownMenuSub,
  DropdownMenuSubContent,
  DropdownMenuSubTrigger,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { UserAvatar } from "@/components/shared/user-avatar";
import { ordersService, productsService, servicesHealthService } from "@/services";
import { useAuthStore } from "@/stores/auth-store";
import { useUiStore } from "@/stores/ui-store";
import { IS_MOCK } from "@/lib/config";
import { ROLES } from "@/lib/rbac";
import { formatRelative } from "@/lib/format";
import { daysAgo } from "@/lib/id";
import { cn } from "@/lib/utils";
import type { RoleId } from "@/types";
import { findLeaf } from "./nav-config";
import { GlobalSearch } from "./global-search";

type Notif = {
  id: string;
  title: string;
  desc: string;
  at: string;
  read: boolean;
  to: "/admin/settings/health" | "/admin/ai-lab" | "/admin/inventory" | "/admin/orders" | "/admin/support";
  tone: "warning" | "info" | "danger";
};

const INITIAL_NOTIFS: Notif[] = [
  { id: "n1", title: "AI Engine phản hồi chậm", desc: "Độ trễ trung bình vượt 400ms trong 15 phút qua.", at: new Date(Date.now() - 1000 * 60 * 12).toISOString(), read: false, to: "/admin/settings/health", tone: "warning" },
  { id: "n2", title: "10 ảnh chờ duyệt nhãn", desc: "Hàng đợi Active Learning cần botanist xem xét.", at: new Date(Date.now() - 1000 * 60 * 50).toISOString(), read: false, to: "/admin/ai-lab", tone: "info" },
  { id: "n3", title: "Sản phẩm sắp hết hàng", desc: "Bình xịt phun sương 1L chỉ còn 3 sản phẩm.", at: daysAgo(0, 7), read: false, to: "/admin/inventory", tone: "danger" },
  { id: "n4", title: "Phiếu hỗ trợ ưu tiên cao", desc: "HT-2401: Ứng dụng bị thoát khi mở camera.", at: daysAgo(1, 10), read: true, to: "/admin/support", tone: "info" },
];

export function AppHeader() {
  const path = usePathname() ?? "/";
  const leaf = findLeaf(path);
  const router = useRouter();
  const session = useAuthStore((s) => s.session);
  const { logout, switchRole } = useAuthStore();
  const { setMobileOpen, setSearchOpen } = useUiStore();
  const [mockNotifs, setMockNotifs] = useState<Notif[]>(INITIAL_NOTIFS);
  const [readIds, setReadIds] = useState<Set<string>>(new Set());

  const mockHealth = useQuery({
    queryKey: [servicesHealthService.key],
    queryFn: () => servicesHealthService.list(),
    enabled: IS_MOCK,
  });
  const realHealth = useQuery({
    queryKey: ["real-system-health"],
    queryFn: async () => {
      const res = await fetch("/api/admin/health", { cache: "no-store" });
      return (await res.json()) as {
        checkedAt: string;
        services: Array<{ id: string; name: string; status: "healthy" | "degraded" | "down"; detail?: string }>;
      };
    },
    enabled: !IS_MOCK,
    refetchInterval: 15 * 60_000,
  });

  const orders = useQuery({ queryKey: [ordersService.key], queryFn: () => ordersService.list(), enabled: !IS_MOCK });
  const products = useQuery({ queryKey: [productsService.key], queryFn: () => productsService.list(), enabled: !IS_MOCK });

  const degraded = IS_MOCK
    ? (mockHealth.data?.filter((s) => s.status !== "operational").length ?? 0)
    : (realHealth.data?.services.filter((s) => s.status !== "healthy").length ?? 0);

  const realNotifs = useMemo<Notif[]>(() => {
    if (IS_MOCK) return [];
    const list: Notif[] = [];
    const pendingOrders = (orders.data ?? []).filter((o) => o.fulfillment === "pending");
    if (pendingOrders.length > 0) {
      list.push({
        id: "real_orders",
        title: `${pendingOrders.length} đơn hàng chờ xác nhận`,
        desc: `Đơn gần nhất: ${pendingOrders[0].code} (${pendingOrders[0].customerName})`,
        at: pendingOrders[0].createdAt,
        read: readIds.has("real_orders"),
        to: "/admin/orders",
        tone: "info",
      });
    }
    const lowStock = (products.data ?? []).filter((p) => p.stock <= p.lowStockThreshold);
    if (lowStock.length > 0) {
      list.push({
        id: "real_stock",
        title: `${lowStock.length} sản phẩm sắp hết hàng`,
        desc: `${lowStock[0].name} chỉ còn ${lowStock[0].stock} sản phẩm.`,
        at: lowStock[0].updatedAt,
        read: readIds.has("real_stock"),
        to: "/admin/inventory",
        tone: "danger",
      });
    }
    const downSvcs = (realHealth.data?.services ?? []).filter((s) => s.status !== "healthy");
    if (downSvcs.length > 0) {
      list.push({
        id: "real_health",
        title: `${downSvcs.length} dịch vụ chưa kết nối`,
        desc: downSvcs.map((s) => s.name).join(", "),
        at: realHealth.data?.checkedAt ?? new Date().toISOString(),
        read: readIds.has("real_health"),
        to: "/admin/settings/health",
        tone: "warning",
      });
    }
    return list;
  }, [orders.data, products.data, realHealth.data, readIds]);

  const notifs = IS_MOCK ? mockNotifs : realNotifs;
  const unread = notifs.filter((n) => !n.read).length;

  const detail = leaf && path !== leaf.to;

  return (
    <header className="sticky top-0 z-30 flex h-16 shrink-0 items-center gap-3 border-b bg-background/85 px-4 backdrop-blur md:px-6">
      <Button variant="ghost" size="icon" className="lg:hidden" onClick={() => setMobileOpen(true)} aria-label="Mở menu">
        <Menu />
      </Button>

      <div className="min-w-0 flex-1">
        <nav aria-label="Breadcrumb" className="flex items-center gap-1 text-[11px] text-muted-foreground">
          <Link href="/admin/overview" className="hover:text-foreground">Floria</Link>
          {leaf?.parent && (
            <>
              <ChevronRight className="size-3" />
              <span>{leaf.parent}</span>
            </>
          )}
          {leaf && (
            <>
              <ChevronRight className="size-3" />
              {detail ? <Link href={leaf.to} className="hover:text-foreground">{leaf.title}</Link> : <span className="text-foreground/80">{leaf.title}</span>}
            </>
          )}
          {detail && (
            <>
              <ChevronRight className="size-3" />
              <span className="text-foreground/80">Chi tiết</span>
            </>
          )}
        </nav>
        <p className="truncate text-[15px] font-semibold text-foreground">{leaf?.title ?? "Floria Admin"}</p>
      </div>

      <button
        onClick={() => setSearchOpen(true)}
        className="hidden h-10 w-72 items-center gap-2 rounded-lg border bg-card px-3 text-sm text-muted-foreground shadow-xs transition-colors hover:border-sage md:flex"
      >
        <Search className="size-4" />
        <span className="flex-1 text-left">Tìm kiếm toàn hệ thống…</span>
        <kbd className="inline-flex items-center gap-0.5 rounded border bg-muted px-1.5 py-0.5 text-[10px] font-medium">
          <Command className="size-3" />K
        </kbd>
      </button>
      <Button variant="ghost" size="icon" className="md:hidden" onClick={() => setSearchOpen(true)} aria-label="Tìm kiếm">
        <Search />
      </Button>

      <Link
        href="/admin/settings/health"
        className={cn(
          "hidden items-center gap-2 rounded-lg border px-2.5 py-1.5 text-xs font-medium sm:flex",
          degraded ? "border-warning/30 bg-warning-soft text-warning" : "border-success/20 bg-success-soft text-success",
        )}
        title="Tình trạng hệ thống"
      >
        <span className="relative flex size-2">
          <span className="absolute inline-flex size-full animate-ping rounded-full bg-current opacity-50" />
          <span className="relative inline-flex size-2 rounded-full bg-current" />
        </span>
        {degraded ? `${degraded} dịch vụ suy giảm` : "Hệ thống ổn định"}
      </Link>

      <Popover>
        <PopoverTrigger asChild>
          <Button variant="ghost" size="icon" className="relative" aria-label="Thông báo">
            <Bell />
            {unread > 0 && <span className="absolute right-1.5 top-1.5 grid size-4 place-items-center rounded-full bg-danger text-[9px] font-bold text-primary-foreground">{unread}</span>}
          </Button>
        </PopoverTrigger>
        <PopoverContent align="end" className="w-[360px] rounded-xl p-0">
          <div className="flex items-center justify-between border-b px-4 py-3">
            <p className="text-sm font-semibold">Thông báo</p>
            <button
              className="text-xs font-medium text-leaf hover:underline"
              onClick={() => {
                if (IS_MOCK) setMockNotifs((n) => n.map((x) => ({ ...x, read: true })));
                else setReadIds(new Set(notifs.map((n) => n.id)));
              }}
            >
              Đánh dấu đã đọc
            </button>
          </div>
          <ul className="max-h-96 overflow-y-auto">
            {notifs.length === 0 ? (
              <li className="px-4 py-8 text-center text-xs text-muted-foreground">Không có thông báo mới.</li>
            ) : (
              notifs.map((n) => (
                <li key={n.id}>
                  <button
                    className={cn("flex w-full gap-3 px-4 py-3 text-left transition-colors hover:bg-muted/60", !n.read && "bg-accent/40")}
                    onClick={() => {
                      if (IS_MOCK) setMockNotifs((all) => all.map((x) => (x.id === n.id ? { ...x, read: true } : x)));
                      else setReadIds((prev) => new Set(prev).add(n.id));
                      router.push(n.to);
                    }}
                  >
                  <span className={cn("mt-1.5 size-2 shrink-0 rounded-full", n.tone === "warning" ? "bg-warning" : n.tone === "danger" ? "bg-danger" : "bg-info", n.read && "opacity-30")} />
                  <span className="min-w-0">
                    <span className="block text-sm font-medium text-foreground">{n.title}</span>
                    <span className="block text-xs text-muted-foreground">{n.desc}</span>
                    <span className="mt-1 block text-[11px] text-muted-foreground">{formatRelative(n.at)}</span>
                  </span>
                </button>
              </li>
            )))}
          </ul>
        </PopoverContent>
      </Popover>

      {session && (
        <DropdownMenu>
          <DropdownMenuTrigger className="flex items-center gap-2 rounded-lg p-1 hover:bg-muted">
            <UserAvatar name={session.name} className="size-8" />
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-64">
            <DropdownMenuLabel className="font-normal">
              <p className="text-sm font-semibold">{session.name}</p>
              <p className="text-xs text-muted-foreground">{session.email}</p>
            </DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuSub>
              <DropdownMenuSubTrigger>
                <UserCog /> Xem với vai trò (demo)
              </DropdownMenuSubTrigger>
              <DropdownMenuSubContent>
                <DropdownMenuRadioGroup value={session.role} onValueChange={(v) => { switchRole(v as RoleId); router.push("/admin/overview"); }}>
                  {ROLES.map((r) => (
                    <DropdownMenuRadioItem key={r.id} value={r.id}>
                      {r.name}
                    </DropdownMenuRadioItem>
                  ))}
                </DropdownMenuRadioGroup>
              </DropdownMenuSubContent>
            </DropdownMenuSub>
            <DropdownMenuItem onSelect={() => router.push("/admin/settings/roles")}>
              <ShieldCheck /> Quản trị & phân quyền
            </DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem className="text-danger focus:text-danger" onSelect={() => { logout(); router.push("/admin/login"); }}>
              <LogOut /> Đăng xuất
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      )}
      <GlobalSearch />
    </header>
  );
}
