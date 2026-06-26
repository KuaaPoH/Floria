"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { motion } from "motion/react";

const NAV_LINKS = [
  { path: "/", label: "Trang chủ" },
  { path: "/garden", label: "Khu vườn" },
  { path: "/diagnostic", label: "Chẩn đoán" },
  { path: "/shop", label: "Cửa hàng" },
  { path: "/ai-assistant", label: "Trợ lý AI" },
];

export default function TopNavBar() {
  const pathname = usePathname();

  const isActive = (path: string) => {
    return path === "/" ? pathname === "/" : pathname?.startsWith(path);
  };

  return (
    <nav className="fixed top-0 w-full z-50 bg-white/80 backdrop-blur-xl border-b border-white/40 shadow-[0_8px_32px_rgba(0,0,0,0.04)]">
      <div className="flex justify-between items-center h-20 px-4 md:px-8 max-w-[1440px] mx-auto">
        <div className="flex items-center gap-4">
          <Link href="/" className="font-extrabold text-primary" style={{ fontSize: "32px", lineHeight: "40px" }}>
            Floria
          </Link>
        </div>
        
        <div className="hidden md:flex items-center gap-8">
          {NAV_LINKS.map((link) => {
            const active = isActive(link.path);
            return (
              <Link 
                key={link.path}
                href={link.path} 
                className={`relative pb-1 font-bold text-[14px] transition-colors select-none outline-none ${
                  active ? "text-primary" : "text-on-surface-variant hover:text-primary"
                }`}
              >
                {link.label}
                {active && (
                  <motion.div
                    layoutId="activeNavIndicator"
                    className="absolute left-0 right-0 bottom-[-2px] h-[2px] bg-primary"
                    transition={{ type: "spring", stiffness: 350, damping: 30 }}
                    initial={false}
                  />
                )}
              </Link>
            );
          })}
        </div>

        <div className="flex items-center gap-4">
          <button className="p-2 hover:bg-black/5 rounded-full transition-all active:scale-95 duration-200 text-primary hidden sm:block">
            <span className="material-symbols-outlined text-on-surface">shopping_cart</span>
          </button>
          <button className="p-2 hover:bg-black/5 rounded-full transition-all active:scale-95 duration-200 text-primary hidden sm:block">
            <span className="material-symbols-outlined text-on-surface">notifications</span>
          </button>
          <Link href="/profile" className={`relative w-10 h-10 rounded-full overflow-hidden border-2 transition-colors ml-2 block ${pathname?.startsWith("/profile") ? "border-primary" : "border-white/50 hover:border-primary-container"}`}>
            <img alt="User Profile" className="w-full h-full object-cover" src="https://lh3.googleusercontent.com/aida-public/AB6AXuBV33OwAYVKKpxQbjvA7qzum-cXBWCwVBeuexLd8JQnDqB40vm-D9wjLSBoDIDzP4Q9aFWc8nubSb9CdKdAOnlCNnjn3HJs9Rp3NiausZnhoPDC_E0kQS3gGKlbFihEBG3b4kxhXYB9MUcs_qlQEZZ1l2YUBqlp23mDAXF3d9gQPHuFrTKJ1FIwh_lU6z3zQipRKT7H-CEvj8SbfEOK44QQGUx4zBwXc1WdslU6ur7uWbUodyyxfmlRpEZ_XGiPYA97lEDBHA66DOY"/>
            {/* We could also add a sliding indicator for profile here, but since it's an icon, a border change is usually better */}
          </Link>
        </div>
      </div>
    </nav>
  );
}
