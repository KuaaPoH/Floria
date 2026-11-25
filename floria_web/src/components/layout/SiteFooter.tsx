"use client";

import Link from "next/link";
import { Facebook, Instagram, Youtube } from "lucide-react";
import { Logo } from "@/components/brand/Logo";
import { useT } from "@/i18n";
import { common } from "@/i18n/common";

export function SiteFooter() {
  const t = useT(common);
  const linkCls = "text-sm text-forest-foreground/70 transition-colors hover:text-forest-foreground";
  return (
    <footer className="mt-20 bg-forest-gradient text-forest-foreground">
      <div className="container-floria grid gap-10 py-14 md:grid-cols-2 lg:grid-cols-[1.4fr_1fr_1fr_1fr]">
        <div className="max-w-sm">
          <Logo inverted />
          <p className="mt-4 text-sm leading-relaxed text-forest-foreground/70">{t("footerAbout")}</p>
          <div className="mt-5 flex gap-2">
            {[
              { Icon: Facebook, href: "https://facebook.com", label: "Facebook" },
              { Icon: Instagram, href: "https://instagram.com", label: "Instagram" },
              { Icon: Youtube, href: "https://youtube.com", label: "YouTube" },
            ].map(({ Icon, href, label }) => (
              <a key={label} href={href} target="_blank" rel="noreferrer" aria-label={label} className="grid size-9 place-items-center rounded-full border border-forest-foreground/20 transition-colors hover:bg-forest-foreground/10">
                <Icon className="size-4" />
              </a>
            ))}
          </div>
        </div>
        <div>
          <p className="mb-3 text-sm font-semibold">{t("footerExplore")}</p>
          <ul className="space-y-2">
            <li><Link href="/discovery" className={linkCls}>{t("navDiscovery")}</Link></li>
            <li><Link href="/shop" className={linkCls}>{t("navShop")}</Link></li>
            <li><Link href="/assistant" className={linkCls}>{t("navAssistant")}</Link></li>
            <li><Link href="/garden" className={linkCls}>{t("myGarden")}</Link></li>
          </ul>
        </div>
        <div>
          <p className="mb-3 text-sm font-semibold">{t("navHandbook")}</p>
          <ul className="space-y-2">
            <li><Link href="/handbook" className={linkCls}>{t("navHandbook")}</Link></li>
            <li><Link href="/handbook/tuoi-cay-dung-cach" className={linkCls}>Tưới cây đúng cách</Link></li>
            <li><Link href="/handbook/nhan-biet-dom-la" className={linkCls}>Bệnh đốm lá</Link></li>
          </ul>
        </div>
        <div>
          <p className="mb-3 text-sm font-semibold">{t("footerSupport")}</p>
          <ul className="space-y-2">
            <li><Link href="/profile/support" className={linkCls}>{t("faq")}</Link></li>
            <li><Link href="/orders" className={linkCls}>{t("orders")}</Link></li>
            <li><Link href="/privacy" className={linkCls}>{t("privacy")}</Link></li>
            <li><Link href="/terms" className={linkCls}>{t("terms")}</Link></li>
          </ul>
        </div>
      </div>
      <div className="border-t border-forest-foreground/10">
        <div className="container-floria flex flex-col gap-2 py-5 text-xs text-forest-foreground/60 sm:flex-row sm:justify-between">
          <span>© 2026 Floria. {t("rights")}</span>
        </div>
      </div>
    </footer>
  );
}
