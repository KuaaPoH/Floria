import Link from "next/link";
import { ArrowRight, Leaf, ShieldCheck } from "lucide-react";
import { Button } from "@/components/ui/button";

export default function HomePage() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-background px-4 py-12">
      <div className="w-full max-w-lg rounded-2xl border bg-card p-8 text-center shadow-sm">
        <div className="mx-auto mb-4 flex size-14 items-center justify-center rounded-2xl bg-primary/10 text-primary">
          <Leaf className="size-7" />
        </div>
        <p className="text-xs font-semibold uppercase tracking-[0.22em] text-primary">Floria Platform</p>
        <h1 className="mt-2 text-2xl font-bold tracking-tight text-foreground">
          Cổng người dùng Web đang được chuẩn bị
        </h1>
        <p className="mt-2 text-sm text-muted-foreground">
          Không gian trang chủ (/) được dành riêng cho giao diện Web người dùng Floria. Hệ thống quản trị đã sẵn sàng tại đường dẫn <code className="rounded bg-muted px-1.5 py-0.5 text-xs">/admin</code>.
        </p>
        <div className="mt-6 flex flex-col justify-center gap-3 sm:flex-row">
          <Button asChild>
            <Link href="/admin/overview">
              <ShieldCheck />
              Vào Floria Admin
              <ArrowRight />
            </Link>
          </Button>
        </div>
      </div>
    </main>
  );
}
