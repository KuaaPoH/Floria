"use client";

import Image from "next/image";
import { motion } from "motion/react";

export default function Home() {
  const container = {
    hidden: { opacity: 0 },
    show: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1,
        delayChildren: 0.2,
      },
    },
  };

  const item = {
    hidden: { opacity: 0, y: 20 },
    show: { opacity: 1, y: 0, transition: { type: "spring", stiffness: 100, damping: 20 } },
  };

  return (
    <main className="max-w-max-width mx-auto px-margin py-12 grid grid-cols-12 gap-gutter">
      {/* Main Content Area */}
      <motion.div 
        className="col-span-12 lg:col-span-8 flex flex-col gap-12"
        variants={container}
        initial="hidden"
        animate="show"
      >
        {/* Welcome Banner */}
        <motion.section 
          variants={item}
          className="glass-panel relative flex flex-col md:flex-row items-center gap-8 overflow-hidden rounded-[2rem] p-10 border border-white/60 shadow-[inset_0_1px_0_rgba(255,255,255,0.6),0_8px_32px_rgba(0,109,53,0.05)]"
        >
          <div className="absolute -right-20 -top-20 w-80 h-80 bg-primary/10 rounded-full blur-[80px]"></div>
          <div className="flex-1 z-10 flex flex-col gap-4">
            <h1 className="font-headline-lg text-4xl md:text-5xl text-on-surface tracking-tight leading-tight">
              Chào buổi sáng,<br/>
              <span className="text-primary font-extrabold">Người làm vườn</span>
            </h1>
            <p className="font-body-lg text-on-surface-variant max-w-[40ch] leading-relaxed">
              Khu vườn của bạn đang phát triển rất tốt. Hiện tại có <strong>2 cây</strong> cần được tưới nước và chăm sóc hôm nay.
            </p>
            <div className="mt-4">
              <button className="bg-primary hover:bg-primary/90 text-white px-8 py-3.5 rounded-full font-label-md flex items-center gap-2 w-max transition-all duration-300 shadow-[0_4px_16px_rgba(0,109,53,0.2)] hover:shadow-[0_8px_24px_rgba(0,109,53,0.3)] active:scale-[0.98] active:-translate-y-[1px]">
                <span className="material-symbols-outlined text-[20px]">add</span>
                Thêm cây mới
              </button>
            </div>
          </div>
          <div className="w-56 h-56 md:w-72 md:h-72 shrink-0 z-10 relative">
            <Image 
              src="https://lh3.googleusercontent.com/aida/AP1WRLuRARSgnzFowzmnBzIsItc1sM0H3F2I2wUAg4dknFiQg_5J_0PuayAGF5NybhF3Qs8d6vN-1GyQ3zvLcxuy72Xtiwzr0hBIa8RJWOsXnJjfJER5ARCPwZwPX1VuFKjLl2w5TYSLsqdj1YhquKHt_IeyOEIoq7iUAySzfoFVAO8IbKcQPVYX_Is1TnB4O0nnsXYaP4uhalSw08kjF6OnQ6Oj6_16CcwyZJLycU3GA3ItW4l6RB0f6QYryQ"
              alt="Mầm cây 3D"
              fill
              className="object-contain drop-shadow-[0_20px_30px_rgba(0,109,53,0.2)] hover:scale-105 transition-transform duration-700 ease-out"
              unoptimized
            />
          </div>
        </motion.section>

        {/* Garden Grid */}
        <motion.section variants={item} className="flex flex-col gap-6">
          <div className="flex justify-between items-end">
            <h2 className="text-2xl font-bold text-on-surface tracking-tight">Khu vườn số của bạn</h2>
            <button className="text-primary font-label-md flex items-center gap-1 hover:text-primary/80 transition-colors group">
              Xem tất cả 
              <span className="material-symbols-outlined text-sm group-hover:translate-x-1 transition-transform">arrow_forward</span>
            </button>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Plant Card 1 */}
            <div className="group glass-panel rounded-[1.5rem] p-6 hover:-translate-y-1 hover:shadow-[0_12px_40px_rgba(0,109,53,0.08)] transition-all duration-300 border border-white/50 cursor-pointer">
              <div className="flex gap-5">
                <div className="w-24 h-24 rounded-2xl overflow-hidden shrink-0 relative bg-white/50 shadow-sm">
                  <Image 
                    src="https://lh3.googleusercontent.com/aida-public/AB6AXuBKSPO51JX2wODk_N2gyq9OM2tR0QjskM42koRXGjOlRy6zxKjHY4gCv4z-ItZeFyjaJSYBCll9iAO919vaE8URseMRRRK_SSiM4MQaVKjxeKoya3vKEIPWs7YBsByYM3eyVAROUJgGjc9Qw0n8F4BfznIGFBlvTLl-yUFfQbvFiAxlUdRbUrjj4wdi-LNhwaSccUw5jEagQJ9XvpX8QzGdI-5CIQnvWIzIZ6wabPEgf8v5F35bK9vmfiO8ZWGVH_Nv34BVfrgmm7o"
                    alt="Monstera Deliciosa"
                    fill
                    className="object-cover group-hover:scale-110 transition-transform duration-500 ease-out"
                    unoptimized
                  />
                </div>
                <div className="flex-1 flex flex-col justify-between py-1">
                  <div>
                    <h3 className="font-bold text-lg text-on-surface line-clamp-1">Monstera Deliciosa</h3>
                    <p className="text-sm text-on-surface-variant line-clamp-1">Trầu bà nam mỹ</p>
                  </div>
                  <div className="flex items-center mt-2">
                    <span className="inline-flex items-center gap-1.5 px-3 py-1 bg-surface-container-high rounded-full font-semibold text-[11px] uppercase tracking-wider text-on-surface-variant border border-outline-variant/30">
                      <span className="material-symbols-outlined text-[14px] text-secondary">water_drop</span>
                      Cần nước
                    </span>
                  </div>
                </div>
              </div>
              <div className="mt-6 flex gap-3 opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                <button className="flex-1 py-2.5 bg-white border border-outline-variant/50 hover:border-primary hover:text-primary rounded-xl text-on-surface font-semibold text-sm transition-colors active:scale-[0.98]">Tưới nước</button>
                <button className="flex-1 py-2.5 bg-white border border-outline-variant/50 hover:border-primary hover:text-primary rounded-xl text-on-surface font-semibold text-sm transition-colors active:scale-[0.98]">Chi tiết</button>
              </div>
            </div>

            {/* Plant Card 2 */}
            <div className="group glass-panel rounded-[1.5rem] p-6 hover:-translate-y-1 hover:shadow-[0_12px_40px_rgba(0,109,53,0.08)] transition-all duration-300 border border-white/50 cursor-pointer">
              <div className="flex gap-5">
                <div className="w-24 h-24 rounded-2xl overflow-hidden shrink-0 relative bg-white/50 shadow-sm">
                  <Image 
                    src="https://lh3.googleusercontent.com/aida-public/AB6AXuDJ71GFo9Hnsj7gQ8gWqRnKo5-bW0IhON8i7M5e_QufveNIkXpIQvT-I5RWXSJf-9ANgeIKJx4GVgtmyh4jVWcVR0kV-5ywEWTbPHm3ih4GV_lv3Wk8_130L4q_ceIaaS72LxMbg1bzbMGG40LE2vRm1FNtgJkvSCrck5D9nOYLC5mU_HhHrnMDe_XDtB_o_LoRUnnnriN8uRsvQMndnCjqGVomb-u1yM4VuZ10P0Z6wb5XxIwQBQCXKvvFWvACMhEX8XXhD0i-Wck"
                    alt="Ficus Lyrata"
                    fill
                    className="object-cover group-hover:scale-110 transition-transform duration-500 ease-out"
                    unoptimized
                  />
                </div>
                <div className="flex-1 flex flex-col justify-between py-1">
                  <div>
                    <h3 className="font-bold text-lg text-on-surface line-clamp-1">Ficus Lyrata</h3>
                    <p className="text-sm text-on-surface-variant line-clamp-1">Bàng singapore</p>
                  </div>
                  <div className="flex items-center mt-2">
                    <span className="inline-flex items-center gap-1.5 px-3 py-1 bg-primary/10 rounded-full font-semibold text-[11px] uppercase tracking-wider text-primary border border-primary/20">
                      <span className="material-symbols-outlined text-[14px]">check_circle</span>
                      Khỏe mạnh
                    </span>
                  </div>
                </div>
              </div>
              <div className="mt-6 flex gap-3 opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                <button className="flex-1 py-2.5 bg-white border border-outline-variant/50 hover:border-primary hover:text-primary rounded-xl text-on-surface font-semibold text-sm transition-colors active:scale-[0.98]">Ghi chép</button>
                <button className="flex-1 py-2.5 bg-white border border-outline-variant/50 hover:border-primary hover:text-primary rounded-xl text-on-surface font-semibold text-sm transition-colors active:scale-[0.98]">Chi tiết</button>
              </div>
            </div>
            
            {/* Plant Card 3 */}
            <div className="group glass-panel rounded-[1.5rem] p-6 hover:-translate-y-1 hover:shadow-[0_12px_40px_rgba(0,109,53,0.08)] transition-all duration-300 border border-white/50 cursor-pointer">
              <div className="flex gap-5">
                <div className="w-24 h-24 rounded-2xl overflow-hidden shrink-0 relative bg-white/50 shadow-sm">
                  <Image 
                    src="https://lh3.googleusercontent.com/aida-public/AB6AXuBaiaK79hwEiHBLniGMplVbRdz3ZtVH3yhovsCOssk_Og3qOA7z6mu_SASZGHEiizX2rCDpQdowSCfK0gP0f7BMSkiv_IN0fDxCL-7OmO7xRVtbygYm-Bs6XUl7bUd3vq7-nm-hcax2FhgX6j0YQ_l2FEKLjIaCwDviQwUGNxUvhzWB2TLl4auKFgksT2-_wEVS9nOdbsx2kE9PN2cHe91zmTC85ZjPISHNiCeEVSJxwn4QhUzZ44YsV7vG-7THPKDl_32s7GT1msE"
                    alt="Spathiphyllum"
                    fill
                    className="object-cover group-hover:scale-110 transition-transform duration-500 ease-out"
                    unoptimized
                  />
                </div>
                <div className="flex-1 flex flex-col justify-between py-1">
                  <div>
                    <h3 className="font-bold text-lg text-on-surface line-clamp-1">Spathiphyllum</h3>
                    <p className="text-sm text-on-surface-variant line-clamp-1">Lan ý</p>
                  </div>
                  <div className="flex items-center mt-2">
                    <span className="inline-flex items-center gap-1.5 px-3 py-1 bg-error/10 rounded-full font-semibold text-[11px] uppercase tracking-wider text-error border border-error/20">
                      <span className="material-symbols-outlined text-[14px]">wb_sunny</span>
                      Thiếu sáng
                    </span>
                  </div>
                </div>
              </div>
              <div className="mt-6 flex gap-3 opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                <button className="flex-1 py-2.5 bg-primary border border-transparent hover:bg-primary/90 rounded-xl text-white font-semibold text-sm transition-colors active:scale-[0.98] shadow-sm">Di chuyển</button>
                <button className="flex-1 py-2.5 bg-white border border-outline-variant/50 hover:border-primary hover:text-primary rounded-xl text-on-surface font-semibold text-sm transition-colors active:scale-[0.98]">Chi tiết</button>
              </div>
            </div>
          </div>
        </motion.section>
      </motion.div>

      {/* Sidebar - Care Schedule */}
      <motion.aside 
        initial={{ opacity: 0, x: 20 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ delay: 0.5, type: "spring", stiffness: 100, damping: 20 }}
        className="col-span-12 lg:col-span-4"
      >
        <div className="glass-panel rounded-[2rem] p-8 sticky top-28 border border-white/60 shadow-[inset_0_1px_0_rgba(255,255,255,0.6),0_8px_32px_rgba(0,0,0,0.02)]">
          <div className="flex items-center justify-between mb-8 border-b border-outline-variant/30 pb-5">
            <h2 className="text-xl font-bold text-on-surface flex items-center gap-2">
              <span className="material-symbols-outlined text-primary">calendar_month</span>
              Lịch chăm sóc
            </h2>
            <span className="font-semibold text-[13px] uppercase tracking-wider text-on-surface-variant">Hôm nay</span>
          </div>
          
          <div className="flex flex-col gap-4">
            {/* Task Item 1 */}
            <div className="flex items-start gap-4 p-4 rounded-[1.25rem] bg-white border border-outline-variant/30 hover:border-primary hover:shadow-[0_8px_20px_rgba(0,109,53,0.06)] transition-all duration-300 cursor-pointer group">
              <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center shrink-0 text-primary">
                <span className="material-symbols-outlined">water_drop</span>
              </div>
              <div className="flex-1 pt-1">
                <h4 className="font-bold text-on-surface group-hover:text-primary transition-colors">Tưới nước Monstera</h4>
                <p className="text-[13px] text-on-surface-variant mt-1 leading-snug">200ml nước, tưới đều quanh gốc.</p>
              </div>
              <button className="w-8 h-8 mt-1 rounded-full border-2 border-outline-variant/50 flex items-center justify-center hover:bg-primary hover:border-primary transition-all active:scale-90">
                <span className="material-symbols-outlined text-[16px] text-transparent hover:text-white">check</span>
              </button>
            </div>

            {/* Task Item 2 */}
            <div className="flex items-start gap-4 p-4 rounded-[1.25rem] bg-white border border-outline-variant/30 hover:border-primary hover:shadow-[0_8px_20px_rgba(0,109,53,0.06)] transition-all duration-300 cursor-pointer group">
              <div className="w-12 h-12 rounded-xl bg-[#ffba79]/20 flex items-center justify-center shrink-0 text-[#794810]">
                <span className="material-symbols-outlined">nutrition</span>
              </div>
              <div className="flex-1 pt-1">
                <h4 className="font-bold text-on-surface group-hover:text-[#794810] transition-colors">Bón phân Bàng Singapore</h4>
                <p className="text-[13px] text-on-surface-variant mt-1 leading-snug">Phân bón NPK pha loãng.</p>
              </div>
              <button className="w-8 h-8 mt-1 rounded-full border-2 border-outline-variant/50 flex items-center justify-center hover:bg-primary hover:border-primary transition-all active:scale-90">
                <span className="material-symbols-outlined text-[16px] text-transparent hover:text-white">check</span>
              </button>
            </div>
          </div>
          
          <div className="mt-8 pt-6">
            <button className="w-full py-3.5 rounded-xl border border-dashed border-primary/50 text-primary font-semibold text-sm hover:bg-primary/5 hover:border-primary transition-colors flex items-center justify-center gap-2 active:scale-[0.98]">
              <span className="material-symbols-outlined text-[18px]">add_task</span>
              Thêm lịch trình
            </button>
          </div>
        </div>
      </motion.aside>
    </main>
  );
}
