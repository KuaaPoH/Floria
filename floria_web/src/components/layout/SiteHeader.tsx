"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { Bell, BookOpen, ChevronDown, Leaf, LogOut, Megaphone, Menu, Package, ScanLine, Search, Settings, ShoppingBag, Sprout, User as UserIcon } from "lucide-react";
import { Logo } from "@/components/brand/Logo";
import { UserAvatar } from "@/components/botanical/BotanicalAvatar";
import { Button } from "@/components/ui/button";
import { CommandDialog, CommandEmpty, CommandGroup, CommandInput, CommandItem, CommandList } from "@/components/ui/command";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel, DropdownMenuSeparator, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetTrigger } from "@/components/ui/sheet";
import { computeEffectiveStatus, todaysTasks } from "@/features/garden/logic";
import { useCatalog, useHandbook, useOrders, usePlants, useProducts, useSchedules } from "@/hooks/queries";
import { useLang, useT } from "@/i18n";
import { common } from "@/i18n/common";
import { ORDER_STATUS_LABEL } from "@/i18n/labels";
import { cn } from "@/lib/utils";
import { useAuth } from "@/stores/auth";
import { cartCount, useCart } from "@/stores/cart";
import { DemoBadge } from "./DemoBadge";

type StaticNavItem = { to: string; key: keyof typeof common.vi; exact?: boolean };
type ResolvedNavItem = { to: string; label: string; exact?: boolean };

const PUBLIC_NAV: StaticNavItem[] = [
  { to: "/", key: "navHome", exact: true },
  { to: "/discovery", key: "navDiscovery" },
  { to: "/handbook", key: "navHandbook" },
  { to: "/shop", key: "navShop" },
  { to: "/assistant", key: "navAssistant" },
];
const USER_NAV: StaticNavItem[] = [
  { to: "/dashboard", key: "navDashboard" },
  { to: "/garden", key: "navGarden" },
  { to: "/discovery", key: "navDiscovery" },
  { to: "/handbook", key: "navHandbook" },
  { to: "/shop", key: "navShop" },
  { to: "/assistant", key: "navAssistant" },
];

function NavLinks({ items, onNavigate, vertical = false }: { items: ResolvedNavItem[]; onNavigate?: () => void; vertical?: boolean }) {
  const pathname = usePathname() ?? "/";
  return (
    <nav className={cn(vertical ? "flex flex-col gap-1" : "hidden items-center gap-1 lg:flex")}>
      {items.map((item) => {
        const active = item.exact ? pathname === item.to : pathname === item.to || pathname.startsWith(item.to + "/");
        return (
          <Link
            key={item.to}
            href={item.to}
            onClick={onNavigate}
            className={cn(
              "rounded-full px-3.5 py-2 text-sm font-medium transition-colors",
              vertical && "rounded-xl px-4 py-3 text-base",
              active ? "bg-mint text-forest dark:text-foreground" : "text-muted-foreground hover:bg-mint/60 hover:text-forest dark:hover:text-foreground",
            )}
          >
            {item.label}
          </Link>
        );
      })}
    </nav>
  );
}

function SearchCommand() {
  const t = useT(common);
  const [open, setOpen] = useState(false);
  const router = useRouter();
  const { data: productsData = [] } = useProducts();
  const { data: handbookData = [] } = useHandbook();
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        setOpen((o) => !o);
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);
  const go = (href: string) => {
    setOpen(false);
    router.push(href);
  };
  return (
    <>
      <button
        onClick={() => setOpen(true)}
        className="hidden h-10 items-center gap-2 rounded-full border bg-card px-3.5 text-sm text-muted-foreground transition-colors hover:border-leaf/40 md:flex xl:w-56"
        aria-label={t("search")}
      >
        <Search className="size-4" />
        <span className="hidden xl:inline">{t("search")}</span>
        <kbd className="ml-auto hidden rounded-md border bg-muted px-1.5 text-[10px] font-semibold xl:inline">⌘K</kbd>
      </button>
      <Button variant="ghost" size="icon" className="md:hidden" onClick={() => setOpen(true)} aria-label={t("search")}>
        <Search />
      </Button>
      <CommandDialog open={open} onOpenChange={setOpen}>
        <CommandInput placeholder={t("searchPlaceholder")} />
        <CommandList>
          <CommandEmpty>—</CommandEmpty>
          <CommandGroup heading={t("navDiscovery")}>
            <CommandItem value="nhận diện cây quét ảnh ai" onSelect={() => go("/discovery")}>
              <ScanLine className="text-leaf" /> Quét ảnh nhận diện cây bằng AI
            </CommandItem>
          </CommandGroup>
          <CommandGroup heading={t("navShop")}>
            {productsData.map((p) => (
              <CommandItem key={p.id} value={`${p.name} ${p.benefits.join(" ")}`} onSelect={() => go(`/products/${p.id}`)}>
                <ShoppingBag className="text-leaf" /> {p.name}
              </CommandItem>
            ))}
          </CommandGroup>
          <CommandGroup heading={t("navHandbook")}>
            {handbookData.map((a) => (
              <CommandItem key={a.id} value={a.title} onSelect={() => go(`/handbook/${a.slug}`)}>
                <BookOpen className="text-leaf" /> {a.title}
              </CommandItem>
            ))}
          </CommandGroup>
        </CommandList>
      </CommandDialog>
    </>
  );
}

function Notifications() {
  const t = useT(common);
  const { data: schedules = [] } = useSchedules();
  const { data: plants = [] } = usePlants();
  const { data: orders = [] } = useOrders();
  const { data: catalog } = useCatalog();
  const tasks = useMemo(() => todaysTasks(schedules), [schedules]);
  const sick = plants.filter((p) => computeEffectiveStatus(p, schedules) === "sick");
  const activeOrders = useMemo(
    () => orders.filter((o) => o.status === "pending" || o.status === "processing" || o.status === "shipping").slice(0, 3),
    [orders],
  );
  const campaigns = useMemo(() => (catalog?.notifications ?? []).slice(0, 3), [catalog?.notifications]);
  const count = (tasks.length ? 1 : 0) + sick.length + activeOrders.length + campaigns.length;
  return (
    <Popover>
      <PopoverTrigger asChild>
        <Button variant="ghost" size="icon" className="relative" aria-label={t("notifications")}>
          <Bell />
          {count > 0 && <span className="absolute right-2 top-2 size-2 rounded-full bg-danger ring-2 ring-background" />}
        </Button>
      </PopoverTrigger>
      <PopoverContent align="end" className="w-80 rounded-2xl p-2">
        <p className="px-2 py-1.5 text-sm font-semibold">{t("notifications")}</p>
        {count === 0 ? (
          <p className="px-2 py-4 text-sm text-muted-foreground">{t("noNotifications")}</p>
        ) : (
          <div className="flex max-h-96 flex-col overflow-y-auto">
            {tasks.length > 0 && (
              <Link href="/dashboard" className="flex items-start gap-3 rounded-xl px-2 py-2.5 hover:bg-mint/60">
                <span className="grid size-8 shrink-0 place-items-center rounded-full bg-info-soft text-info"><Leaf className="size-4" /></span>
                <span className="text-sm">{t("notifTasks", { count: tasks.length })}</span>
              </Link>
            )}
            {sick.map((p) => (
              <Link key={p.id} href={`/garden/${p.gardenId}/plants/${p.id}`} className="flex items-start gap-3 rounded-xl px-2 py-2.5 hover:bg-mint/60">
                <img src={p.image} alt="" className="size-8 shrink-0 rounded-full object-cover" />
                <span className="text-sm">{t("notifSick", { name: p.nickname })}</span>
              </Link>
            ))}
            {activeOrders.map((o) => (
              <Link key={o.id} href="/orders" className="flex items-start gap-3 rounded-xl px-2 py-2.5 hover:bg-mint/60">
                <span className="grid size-8 shrink-0 place-items-center rounded-full bg-mint text-forest"><Package className="size-4" /></span>
                <span className="min-w-0 text-sm">
                  <b className="block truncate font-mono text-xs">{o.code}</b>
                  <span className="text-xs text-muted-foreground">{t(ORDER_STATUS_LABEL[o.status])}</span>
                </span>
              </Link>
            ))}
            {campaigns.map((c) => (
              <Link key={c.id} href="/shop" className="flex items-start gap-3 rounded-xl px-2 py-2.5 hover:bg-mint/60">
                <span className="grid size-8 shrink-0 place-items-center rounded-full bg-warning-soft text-warning"><Megaphone className="size-4" /></span>
                <span className="min-w-0 text-sm">
                  <b className="block truncate">{c.title}</b>
                  {c.body && <span className="line-clamp-2 text-xs text-muted-foreground">{c.body}</span>}
                </span>
              </Link>
            ))}
          </div>
        )}
      </PopoverContent>
    </Popover>
  );
}

function CartButton() {
  const t = useT(common);
  const items = useCart((s) => s.items);
  const count = cartCount(items);
  return (
    <Button asChild variant="ghost" size="icon" className="relative" aria-label={t("cart")}>
      <Link href="/cart" id="floria-cart-anchor">
        <ShoppingBag />
        {count > 0 && (
          <span className="absolute -right-0.5 -top-0.5 grid min-w-5 place-items-center rounded-full bg-primary px-1 text-[10px] font-bold leading-5 text-primary-foreground ring-2 ring-background">
            {count > 99 ? "99+" : count}
          </span>
        )}
      </Link>
    </Button>
  );
}

function UserMenu() {
  const t = useT(common);
  const user = useAuth((s) => s.user)!;
  const logout = useAuth((s) => s.logout);
  const router = useRouter();
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <button className="flex items-center gap-1.5 rounded-full p-0.5 pr-2 transition-colors hover:bg-mint/60" aria-label={t("profile")}>
          <UserAvatar user={user} className="size-9" />
          <ChevronDown className="hidden size-3.5 text-muted-foreground sm:block" />
        </button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-60 rounded-2xl p-1.5">
        <DropdownMenuLabel className="flex items-center gap-3 py-2">
          <UserAvatar user={user} className="size-10" />
          <div className="min-w-0">
            <p className="truncate text-sm font-semibold">{user.displayName}</p>
            <p className="truncate text-xs font-normal text-muted-foreground">{user.email}</p>
          </div>
        </DropdownMenuLabel>
        <DropdownMenuSeparator />
        <DropdownMenuItem asChild><Link href="/profile"><UserIcon /> {t("profile")}</Link></DropdownMenuItem>
        <DropdownMenuItem asChild><Link href="/garden"><Sprout /> {t("myGarden")}</Link></DropdownMenuItem>
        <DropdownMenuItem asChild><Link href="/orders"><Package /> {t("orders")}</Link></DropdownMenuItem>
        <DropdownMenuItem asChild><Link href="/profile/settings"><Settings /> {t("settings")}</Link></DropdownMenuItem>
        <DropdownMenuSeparator />
        <DropdownMenuItem
          className="text-danger focus:text-danger"
          onClick={async () => {
            await logout();
            router.push("/");
          }}
        >
          <LogOut /> {t("logout")}
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

/** PublicHeader and UserHeader share this shell; the variant follows the auth state. */
export function SiteHeader() {
  const t = useT(common);
  const lang = useLang();
  const status = useAuth((s) => s.status);
  const authed = status === "authenticated";
  const { data: catalog } = useCatalog();
  const [scrolled, setScrolled] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 8);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const nav = useMemo<ResolvedNavItem[]>(() => {
    const remote = catalog?.webMenus;
    if (remote && remote.length > 0) {
      return remote
        .filter((item) => {
          if (item.module === "public_only") return !authed;
          if (item.module === "auth_only") return authed;
          return true;
        })
        .map((item) => ({
          to: item.route,
          label: lang === "en" && item.titleEn ? item.titleEn : item.title,
          exact: item.route === "/",
        }));
    }
    return (authed ? USER_NAV : PUBLIC_NAV).map((item) => ({
      to: item.to,
      label: t(item.key),
      exact: item.exact,
    }));
  }, [authed, catalog?.webMenus, lang, t]);

  return (
    <header className={cn("sticky top-0 z-40 transition-all duration-300", scrolled ? "border-b bg-background/85 backdrop-blur-xl" : "bg-background/60 backdrop-blur-sm")}>
      <div className="container-floria flex h-16 items-center gap-3 md:h-[72px]">
        <Sheet open={menuOpen} onOpenChange={setMenuOpen}>
          <SheetTrigger asChild>
            <Button variant="ghost" size="icon" className="lg:hidden" aria-label="Menu">
              <Menu />
            </Button>
          </SheetTrigger>
          <SheetContent side="left" className="w-[300px] bg-background">
            <SheetHeader>
              <SheetTitle asChild><div><Logo /></div></SheetTitle>
            </SheetHeader>
            <div className="mt-6 px-2">
              <NavLinks items={nav} vertical onNavigate={() => setMenuOpen(false)} />
            </div>
          </SheetContent>
        </Sheet>
        <div className="flex items-center gap-2">
          <Logo />
          <DemoBadge className="hidden sm:inline-flex" />
        </div>
        <div className="mx-auto">
          <NavLinks items={nav} />
        </div>
        <div className="ml-auto flex items-center gap-1 lg:ml-0">
          <SearchCommand />
          {authed && <Notifications />}
          <CartButton />
          {status === "idle" || status === "loading" ? (
            <div className="size-9 rounded-full bg-muted" />
          ) : authed ? (
            <UserMenu />
          ) : (
            <div className="ml-1 flex items-center gap-1.5">
              <Button asChild variant="ghost" className="hidden sm:inline-flex"><Link href="/login">{t("login")}</Link></Button>
              <Button asChild><Link href="/register">{t("register")}</Link></Button>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
