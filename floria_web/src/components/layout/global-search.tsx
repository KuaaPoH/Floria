"use client";

import { useEffect, useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { Flower2, Microscope, Package, ShoppingBag, User, BookOpen } from "lucide-react";
import { CommandDialog, CommandEmpty, CommandGroup, CommandInput, CommandItem, CommandList, CommandSeparator } from "@/components/ui/command";
import { articlesService, diseasesService, ordersService, plantsService, productsService, usersService } from "@/services";
import { useUiStore } from "@/stores/ui-store";
import { formatVND } from "@/lib/format";
import { NAV_LEAVES } from "./nav-config";

/** ⌘K search across users, orders, products, plants, diseases and articles (mock data). */
export function GlobalSearch() {
  const { searchOpen, setSearchOpen } = useUiStore();
  const router = useRouter();
  const enabled = searchOpen;
  const users = useQuery({ queryKey: [usersService.key], queryFn: () => usersService.list(), enabled });
  const orders = useQuery({ queryKey: [ordersService.key], queryFn: () => ordersService.list(), enabled });
  const products = useQuery({ queryKey: [productsService.key], queryFn: () => productsService.list(), enabled });
  const plants = useQuery({ queryKey: [plantsService.key], queryFn: () => plantsService.list(), enabled });
  const diseases = useQuery({ queryKey: [diseasesService.key], queryFn: () => diseasesService.list(), enabled });
  const articles = useQuery({ queryKey: [articlesService.key], queryFn: () => articlesService.list(), enabled });

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        setSearchOpen(!useUiStore.getState().searchOpen);
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [setSearchOpen]);

  const close = () => setSearchOpen(false);
  const go = (href: string) => {
    close();
    router.push(href);
  };

  const pages = useMemo(() => NAV_LEAVES, []);

  return (
    <CommandDialog open={searchOpen} onOpenChange={setSearchOpen}>
      <CommandInput placeholder="Tìm người dùng, đơn hàng, sản phẩm, cây, bệnh…" />
      <CommandList className="max-h-[420px]">
        <CommandEmpty>Không tìm thấy kết quả.</CommandEmpty>
        <CommandGroup heading="Trang">
          {pages.map((p) => (
            <CommandItem key={p.to} value={`trang ${p.title}`} onSelect={() => go(p.to)}>
              <p.icon /> {p.title}
            </CommandItem>
          ))}
        </CommandGroup>
        <CommandSeparator />
        <CommandGroup heading="Người dùng">
          {users.data?.slice(0, 64).map((u) => (
            <CommandItem key={u.id} value={`user ${u.fullName} ${u.email}`} onSelect={() => go(`/users?q=${encodeURIComponent(u.email)}`)}>
              <User /> {u.fullName} <span className="ml-auto text-xs text-muted-foreground">{u.email}</span>
            </CommandItem>
          ))}
        </CommandGroup>
        <CommandGroup heading="Đơn hàng">
          {orders.data?.map((o) => (
            <CommandItem key={o.id} value={`order ${o.code} ${o.customerName}`} onSelect={() => go(`/orders?q=${encodeURIComponent(o.code)}`)}>
              <ShoppingBag /> {o.code} · {o.customerName} <span className="ml-auto text-xs text-muted-foreground">{formatVND(o.total)}</span>
            </CommandItem>
          ))}
        </CommandGroup>
        <CommandGroup heading="Sản phẩm">
          {products.data?.map((p) => (
            <CommandItem key={p.id} value={`product ${p.name} ${p.sku}`} onSelect={() => go(`/products?q=${encodeURIComponent(p.name)}`)}>
              <Package /> {p.name} <span className="ml-auto text-xs text-muted-foreground">{p.sku}</span>
            </CommandItem>
          ))}
        </CommandGroup>
        <CommandGroup heading="Cây">
          {plants.data?.map((p) => (
            <CommandItem key={p.id} value={`plant ${p.viName} ${p.sciName}`} onSelect={() => go(`/plants/${p.id}`)}>
              <Flower2 /> {p.viName} <span className="ml-auto text-xs italic text-muted-foreground">{p.sciName}</span>
            </CommandItem>
          ))}
        </CommandGroup>
        <CommandGroup heading="Bệnh">
          {diseases.data?.map((d) => (
            <CommandItem key={d.id} value={`disease ${d.name} ${d.enName}`} onSelect={() => go(`/diseases?q=${encodeURIComponent(d.name)}`)}>
              <Microscope /> {d.name}
            </CommandItem>
          ))}
        </CommandGroup>
        <CommandGroup heading="Cẩm nang">
          {articles.data?.map((a) => (
            <CommandItem key={a.id} value={`article ${a.title}`} onSelect={() => go(`/handbook?id=${encodeURIComponent(a.id)}`)}>
              <BookOpen /> {a.title}
            </CommandItem>
          ))}
        </CommandGroup>
      </CommandList>
    </CommandDialog>
  );
}
