"use client";

import Link from "next/link";
import { motion } from "framer-motion";
import { ArrowRight, BookOpen, CalendarCheck, MessageCircleHeart, ScanLine, ShieldCheck, Stethoscope } from "lucide-react";
import { UserAppShell } from "@/components/layout/UserAppShell";
import { Button } from "@/components/ui/button";
import { useHandbook } from "@/hooks/queries";
import { isMock } from "@/config/env";
import { IMG } from "@/mocks/user/images";
import { PLANT_HANDBOOK } from "@/mocks/user/handbook";
import { useAuth } from "@/stores/auth";

const FEATURES = [
  { icon: ScanLine, title: "Nhận diện loài cây", body: "Chụp một tấm ảnh — Floria nhận diện loài cây và mở ngay hồ sơ bách khoa.", to: "/discovery" },
  { icon: Stethoscope, title: "Chẩn đoán bệnh lá", body: "Phát hiện đốm lá, phấn trắng, gỉ sắt, cháy lá và gợi ý hướng xử lý.", to: "/garden" },
  { icon: CalendarCheck, title: "Ba lịch chăm sóc riêng", body: "Tưới nước, bón phân, kiểm tra & lau lá — mỗi lịch một nhịp riêng cho từng cây.", to: "/dashboard" },
  { icon: MessageCircleHeart, title: "Trợ lý Floria", body: "Hỏi chuyên gia cây trồng Floria bất cứ lúc nào, nhận lịch chăm sóc áp dụng chỉ một chạm.", to: "/assistant" },
] as const;

export default function LandingPage() {
  const authed = useAuth((s) => s.status === "authenticated");
  const { data: handbookData } = useHandbook();
  const handbookList = (handbookData ?? (isMock() ? PLANT_HANDBOOK : [])).slice(0, 3);

  return (
    <UserAppShell>
      <div>
        {/* Hero */}
        <section className="container-floria pt-4 md:pt-6">
          <div className="relative overflow-hidden rounded-[2rem] md:rounded-[2.5rem]">
            <img src={IMG.heroGarden} alt="Phòng khách tràn ngập cây xanh" width={1920} height={1088} className="absolute inset-0 size-full object-cover" />
            <div className="absolute inset-0 bg-gradient-to-r from-forest/90 via-forest/55 to-transparent" />
            <div className="relative grid min-h-[560px] items-end gap-10 p-7 md:min-h-[640px] md:p-14 lg:grid-cols-[1.2fr_1fr]">
              <motion.div initial={{ opacity: 0, y: 18 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.7 }} className="max-w-xl text-forest-foreground">
                <h1 className="text-4xl font-bold leading-[1.05] tracking-tight md:text-6xl">
                  Mỗi chiếc lá đều có câu chuyện. <span className="text-sage">Floria</span> giúp bạn lắng nghe.
                </h1>
                <p className="mt-5 max-w-md text-base text-forest-foreground/80 md:text-lg">
                  Nhận diện cây nhanh chóng, theo dõi sức khỏe từng chậu cây và chăm sóc cả khu vườn chỉ trong một ứng dụng.
                </p>
                <div className="mt-8 flex flex-wrap gap-3">
                  <Button asChild size="lg" variant="cream"><Link href="/discovery"><ScanLine /> Quét cây ngay</Link></Button>
                  <Button asChild size="lg" variant="glass">
                    {authed ? <Link href="/dashboard">Vào khu vườn của tôi <ArrowRight /></Link> : <Link href="/register">Tạo khu vườn miễn phí <ArrowRight /></Link>}
                  </Button>
                </div>
              </motion.div>
              <motion.div initial={{ opacity: 0, y: 24 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.8, delay: 0.2 }} className="hidden items-end justify-end lg:flex">
                <img
                  src="/mascot_chao_mung.png"
                  alt="Mascot Floria chào mừng"
                  className="animate-float max-h-[340px] w-auto object-contain drop-shadow-2xl"
                />
              </motion.div>
            </div>
          </div>
        </section>

        {/* Features */}
        <section className="container-floria py-20">
          <div className="mb-10 max-w-2xl">
            <p className="eyebrow">Hệ sinh thái chăm cây</p>
            <h2 className="mt-2 text-3xl font-bold md:text-4xl">Từ một tấm ảnh đến một khu vườn khỏe mạnh</h2>
          </div>
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
            {FEATURES.map((f, i) => (
              <motion.div key={f.title} initial={{ opacity: 0, y: 16 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ delay: i * 0.08 }}>
                <Link href={f.to} className="group flex h-full flex-col rounded-3xl border bg-card p-6 shadow-soft transition-all hover:-translate-y-1 hover:shadow-card">
                  <div className="grid size-12 place-items-center rounded-2xl bg-mint text-leaf transition-colors group-hover:bg-leaf group-hover:text-primary-foreground"><f.icon className="size-5" /></div>
                  <h3 className="mt-5 text-lg font-semibold">{f.title}</h3>
                  <p className="mt-2 text-sm leading-relaxed text-muted-foreground">{f.body}</p>
                  <span className="mt-auto pt-5 text-sm font-semibold text-leaf">Khám phá <ArrowRight className="inline size-4 transition-transform group-hover:translate-x-1" /></span>
                </Link>
              </motion.div>
            ))}
          </div>
        </section>

        {/* Split story */}
        <section className="bg-mint/50 py-20">
          <div className="container-floria grid items-center gap-12 lg:grid-cols-2">
            <div className="grid grid-cols-2 gap-4">
              <img src={IMG.gardens.balcony} alt="Ban công nhiều cây" loading="lazy" className="aspect-[3/4] w-full rounded-3xl object-cover shadow-card" />
              <div className="flex flex-col gap-4 pt-10">
                <img src={IMG.plants.calathea} alt="Đuôi công" loading="lazy" className="aspect-square w-full rounded-3xl object-cover shadow-card" />
                <div className="rounded-3xl bg-forest p-5 text-forest-foreground">
                  <p className="text-3xl font-bold">3</p>
                  <p className="text-sm text-forest-foreground/75">lịch chăm sóc độc lập cho mỗi cây</p>
                </div>
              </div>
            </div>
            <div>
              <p className="eyebrow">Nhiều khu vườn · Một nơi quản lý</p>
              <h2 className="mt-2 text-3xl font-bold md:text-4xl">Căn hộ, ban công hay sân thượng — mỗi khu vườn một nhịp sống</h2>
              <p className="mt-4 text-muted-foreground">Floria gợi ý vị trí đặt cây theo môi trường và ánh sáng của từng khu vườn, nhắc bạn việc cần làm mỗi ngày và ghi lại hành trình lớn lên của từng chậu cây trong nhật ký.</p>
              <ul className="mt-6 space-y-3 text-sm">
                {["Bộ lọc vị trí tự động theo nơi bạn đặt cây", "Nhật ký cây kèm ảnh, theo dõi bệnh án", "Thời tiết thực tế và khuyến nghị chăm sóc"].map((x) => (
                  <li key={x} className="flex items-center gap-3"><ShieldCheck className="size-4 text-leaf" /> {x}</li>
                ))}
              </ul>
              <Button asChild size="lg" className="mt-8"><Link href={authed ? "/garden" : "/register"}>Bắt đầu khu vườn của bạn <ArrowRight /></Link></Button>
            </div>
          </div>
        </section>

        {/* Handbook */}
        <section className="container-floria py-16 pb-4">
          <div className="mb-8 flex items-end justify-between gap-4">
            <div>
              <p className="eyebrow">Cẩm nang</p>
              <h2 className="mt-2 text-3xl font-bold">Kiến thức để cây luôn xanh tốt</h2>
            </div>
            <Button asChild variant="ghost"><Link href="/handbook"><BookOpen /> Tất cả bài viết</Link></Button>
          </div>
          <div className="grid gap-5 md:grid-cols-3">
            {handbookList.map((a) => (
              <Link key={a.id} href={`/handbook/${a.slug}`} className="group overflow-hidden rounded-3xl border bg-card shadow-soft transition-all hover:shadow-card">
                <div className="aspect-[16/10] overflow-hidden"><img src={a.image} alt={a.title} loading="lazy" className="size-full object-cover transition-transform duration-700 group-hover:scale-105" /></div>
                <div className="p-5">
                  <h3 className="font-semibold leading-snug group-hover:text-leaf">{a.title}</h3>
                  <p className="mt-2 line-clamp-2 text-sm text-muted-foreground">{a.excerpt}</p>
                </div>
              </Link>
            ))}
          </div>
        </section>
      </div>
    </UserAppShell>
  );
}
