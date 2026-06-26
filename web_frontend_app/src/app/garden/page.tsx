"use client";
import Image from "next/image";
import Link from "next/link";
import { motion } from "motion/react";

export default function GardenPage() {
  return (
    <main className="flex-grow flex flex-col relative w-full min-h-[calc(100vh-80px)] overflow-hidden bg-surface-bright">
      {/* Background with abstract shapes/gradients */}
      <div className="absolute inset-0 bg-white/60 backdrop-blur-3xl z-0"></div>
      <div className="absolute top-[-10%] right-[-5%] w-[500px] h-[500px] bg-primary/10 rounded-full blur-[100px] pointer-events-none"></div>
      <div className="absolute bottom-[-10%] left-[-5%] w-[400px] h-[400px] bg-tertiary-container/20 rounded-full blur-[80px] pointer-events-none"></div>

      <div className="relative z-10 flex flex-col lg:flex-row w-full h-full max-w-max-width mx-auto px-4 md:px-8 py-8 gap-8">
        {/* Left Panel (Main Garden Grid) */}
        <section className="flex-[3] flex flex-col h-full overflow-y-auto pr-2 hide-scrollbar">
          {/* Header */}
          <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-8">
            <h2 className="font-bold text-[28px] text-on-surface">Khu Vườn Của Bạn</h2>
            <button className="bg-primary-container text-on-primary-fixed font-semibold text-[14px] px-6 py-3 rounded-full flex items-center gap-2 hover:shadow-[0_0_20px_rgba(0,230,118,0.4)] transition-shadow">
              <span className="material-symbols-outlined text-[20px]">add</span>
              Thêm Cây Mới
            </button>
          </div>

          {/* Filter Tabs */}
          <div className="flex flex-wrap gap-3 mb-8">
            <button className="px-5 py-2 rounded-full bg-primary-container/20 text-on-primary-container border border-primary-container font-semibold text-[14px] transition-colors">Tất cả</button>
            <button className="px-5 py-2 rounded-full glass-panel text-on-surface-variant hover:bg-white/80 transition-colors font-semibold text-[14px] border border-white/40">Phòng khách</button>
            <button className="px-5 py-2 rounded-full glass-panel text-on-surface-variant hover:bg-white/80 transition-colors font-semibold text-[14px] border border-white/40">Ban công</button>
            <button className="px-5 py-2 rounded-full glass-panel text-on-surface-variant hover:bg-white/80 transition-colors font-semibold text-[14px] border border-white/40">Bàn làm việc</button>
          </div>

          {/* Plant Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 pb-12">
            
            {/* Card 1 */}
            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4 }}
              className="glass-panel rounded-[1rem] overflow-hidden group relative border border-white/60"
            >
              <div className="relative h-48 w-full overflow-hidden bg-surface-container">
                <Image 
                  src="https://lh3.googleusercontent.com/aida-public/AB6AXuDOOtbVIhTlvQTHj5AwnAwlpSJt8Mz34zVt1jA1lSwgKiclJvbm5riQ9Dui7YyEnjXYS5IP7lhV8BAtZEewmyknFIMzPIUqdoXvcD-_TbM2AgQIIKl96y9Bv_IZLNrbmgZZu1oX8dCad74HlF4zS3zPG_vQZTqysTB0KKjsmD2AoYr19op5sZ3LuLOLUkLYtTZIXO1325k3OY6K6iOvY2pJaT3dy-272VeGEUoabgBFQ2uX-jSlC85-txtOHXrw91lY3_ob2MYMYXw"
                  alt="Cây Trầu Bà"
                  fill
                  unoptimized
                  className="object-cover transition-transform duration-500 group-hover:scale-105"
                />
                {/* Hover Overlay */}
                <div className="absolute inset-0 bg-black/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                  <Link href="/garden/1" className="bg-white text-primary font-semibold text-[14px] px-6 py-2 rounded-full hover:bg-surface-bright transition-colors">
                    Xem Hồ Sơ
                  </Link>
                </div>
                {/* Location Badge */}
                <div className="absolute top-3 left-3 bg-white/80 backdrop-blur-md px-3 py-1 rounded-full text-[11px] font-bold text-on-surface flex items-center gap-1 shadow-sm uppercase tracking-wide">
                  <span className="material-symbols-outlined text-[14px]">chair</span> Phòng khách
                </div>
              </div>
              <div className="p-5">
                <h3 className="font-bold text-[18px] mb-2 text-on-surface">Cây Trầu Bà Đế Vương</h3>
                <div className="flex items-center gap-2">
                  <span className="w-2.5 h-2.5 rounded-full bg-primary-container"></span>
                  <span className="text-[13px] font-medium text-on-surface-variant">Khỏe mạnh</span>
                </div>
              </div>
            </motion.div>

            {/* Card 2 */}
            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4, delay: 0.1 }}
              className="glass-panel rounded-[1rem] overflow-hidden group relative border border-white/60"
            >
              <div className="relative h-48 w-full overflow-hidden bg-surface-container">
                <Image 
                  src="https://lh3.googleusercontent.com/aida-public/AB6AXuBp8Y9rIalWSNnMQThwzHcB0ehj1DkBNE5qEeHwZOl1WKMDaHtfbdEdulp2HBqirFAC-uuq5WUsTpMshA1LgECsd21qaZI4dBZ8NXd3jUTa05YVgAGWOv6SQn6ts1RBs6K1Y5KOkRLG9KuH6KX1Nk1NHjvVMxKdysqEyKHih0U84Te1wRMruYh1mC5PNYsznw6EpUfk8JXpUWv9Qs-QopgCarKlweiTnF6sgBJAZBRtfC4TKkxbFveTmaJyLtwZPz_U0AgCbvDo3Iw"
                  alt="Cây Kim Tiền"
                  fill
                  unoptimized
                  className="object-cover transition-transform duration-500 group-hover:scale-105"
                />
                <div className="absolute inset-0 bg-black/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                  <Link href="/garden/2" className="bg-white text-primary font-semibold text-[14px] px-6 py-2 rounded-full hover:bg-surface-bright transition-colors">
                    Xem Hồ Sơ
                  </Link>
                </div>
                <div className="absolute top-3 left-3 bg-white/80 backdrop-blur-md px-3 py-1 rounded-full text-[11px] font-bold text-on-surface flex items-center gap-1 shadow-sm uppercase tracking-wide">
                  <span className="material-symbols-outlined text-[14px]">desk</span> Bàn làm việc
                </div>
              </div>
              <div className="p-5">
                <h3 className="font-bold text-[18px] mb-2 text-on-surface">Cây Kim Tiền</h3>
                <div className="flex items-center gap-2">
                  <span className="w-2.5 h-2.5 rounded-full bg-tertiary-container"></span>
                  <span className="text-[13px] font-medium text-on-surface-variant">Cần tưới nước</span>
                </div>
              </div>
            </motion.div>

            {/* Card 3 */}
            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4, delay: 0.2 }}
              className="glass-panel rounded-[1rem] overflow-hidden group relative border border-white/60"
            >
              <div className="relative h-48 w-full overflow-hidden bg-surface-container">
                <Image 
                  src="https://lh3.googleusercontent.com/aida-public/AB6AXuDA6IhD8ZJDtevtikxiopsn-F1i_kqaPZRw18JhGy7H_Qd9xXI_fT15gveCM39PyPpRO6omX_iLHCIsaSpaFOoJgr9EddGJmbT1M2-guwG7m6znUNflHg0LIIsnI0JqEC8eLR7N-KAKdb_cIXiBmG8Ud3gzcwyhiMVgEC14e2eM6bRCWpKxN0dHVrI_6Ew-BdvDwViqy-NErjZbK-T-VxKQUMWM0wHV-3-IoCxRX79ek8_UEDzLgOzZFW80fRy0WUwxCy3dka30i5g"
                  alt="Sen Đá"
                  fill
                  unoptimized
                  className="object-cover transition-transform duration-500 group-hover:scale-105"
                />
                <div className="absolute inset-0 bg-black/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                  <Link href="/garden/3" className="bg-white text-primary font-semibold text-[14px] px-6 py-2 rounded-full hover:bg-surface-bright transition-colors">
                    Xem Hồ Sơ
                  </Link>
                </div>
                <div className="absolute top-3 left-3 bg-white/80 backdrop-blur-md px-3 py-1 rounded-full text-[11px] font-bold text-on-surface flex items-center gap-1 shadow-sm uppercase tracking-wide">
                  <span className="material-symbols-outlined text-[14px]">balcony</span> Ban công
                </div>
              </div>
              <div className="p-5">
                <h3 className="font-bold text-[18px] mb-2 text-on-surface">Sen Đá</h3>
                <div className="flex items-center gap-2">
                  <span className="w-2.5 h-2.5 rounded-full bg-error"></span>
                  <span className="text-[13px] font-medium text-on-surface-variant">Đang trị nấm</span>
                </div>
              </div>
            </motion.div>

          </div>
        </section>

        {/* Right Panel (Smart Reminders) */}
        <motion.aside 
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.5 }}
          className="flex-[1] lg:min-w-[320px] lg:max-w-[360px]"
        >
          <div className="glass-panel rounded-2xl p-6 h-full min-h-[500px] flex flex-col border border-white/60 shadow-[0_8px_32px_rgba(0,0,0,0.04)]">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-10 h-10 rounded-full bg-primary-container/30 flex items-center justify-center text-primary">
                <span className="material-symbols-outlined">calendar_month</span>
              </div>
              <h2 className="font-bold text-[20px] text-on-surface">Lịch Chăm Sóc <span className="text-primary">(3)</span></h2>
            </div>
            
            <div className="flex-grow flex flex-col gap-3">
              {/* Task 1: Overdue */}
              <div className="flex gap-4 p-3.5 rounded-xl bg-white/40 hover:bg-white/60 transition-colors group cursor-pointer border border-transparent hover:border-outline-variant/30">
                <div className="pt-1 shrink-0">
                  <div className="w-5 h-5 rounded-full border-2 border-tertiary-container flex items-center justify-center group-hover:bg-tertiary-container/10 transition-colors"></div>
                </div>
                <div>
                  <h4 className="font-semibold text-[14px] text-on-surface">Tưới nước</h4>
                  <p className="text-[13px] text-on-surface-variant mt-0.5">Cây Kim Tiền | 08:00 AM</p>
                  <span className="inline-block mt-2 text-[11px] font-bold text-tertiary-container bg-tertiary-container/10 px-2 py-0.5 rounded-md uppercase tracking-wider">Quá hạn</span>
                </div>
              </div>

              {/* Task 2: Today */}
              <div className="flex gap-4 p-3.5 rounded-xl bg-white/40 hover:bg-white/60 transition-colors group cursor-pointer border border-transparent hover:border-outline-variant/30">
                <div className="pt-1 shrink-0">
                  <div className="w-5 h-5 rounded-full border-2 border-outline flex items-center justify-center group-hover:border-primary-container transition-colors"></div>
                </div>
                <div>
                  <h4 className="font-semibold text-[14px] text-on-surface">Phun thuốc nấm</h4>
                  <p className="text-[13px] text-on-surface-variant mt-0.5">Cây Trầu Bà | Hôm nay</p>
                </div>
              </div>

              {/* Task 3: Done */}
              <div className="flex gap-4 p-3.5 rounded-xl opacity-50 bg-white/20">
                <div className="pt-1 shrink-0">
                  <div className="w-5 h-5 rounded-full bg-primary-container flex items-center justify-center text-on-primary-container">
                    <span className="material-symbols-outlined text-[14px] font-bold">check</span>
                  </div>
                </div>
                <div>
                  <h4 className="font-semibold text-[14px] text-on-surface line-through">Bón phân NPK</h4>
                  <p className="text-[13px] text-on-surface-variant mt-0.5 line-through">Sen Đá | Đã xong</p>
                </div>
              </div>
            </div>

            <div className="pt-5 mt-4 border-t border-outline-variant/20 text-center">
              <a className="font-semibold text-[13px] text-primary hover:text-primary-container transition-colors flex items-center justify-center gap-1 group" href="#">
                Xem lịch sử chăm sóc 
                <span className="material-symbols-outlined text-[16px] group-hover:translate-x-1 transition-transform">arrow_forward</span>
              </a>
            </div>
          </div>
        </motion.aside>
      </div>
    </main>
  );
}
