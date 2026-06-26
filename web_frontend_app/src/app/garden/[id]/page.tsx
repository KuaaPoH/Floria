"use client";
import Image from "next/image";
import Link from "next/link";
import { motion } from "motion/react";
import { useParams } from "next/navigation";

export default function PlantProfilePage() {
  const params = useParams();
  
  return (
    <main className="flex-grow flex flex-col relative w-full min-h-[calc(100vh-80px)] overflow-hidden bg-surface-bright">
      {/* Background with abstract shapes/gradients */}
      <div className="absolute inset-0 bg-white/60 backdrop-blur-3xl z-0"></div>
      <div className="absolute top-[10%] left-[5%] w-[400px] h-[400px] bg-primary/5 rounded-full blur-[100px] pointer-events-none"></div>

      <div className="relative z-10 w-full h-full max-w-max-width mx-auto px-4 md:px-8 py-8 overflow-y-auto hide-scrollbar">
        {/* Page Header */}
        <header className="flex flex-col md:flex-row justify-between items-start md:items-center mb-8 gap-4">
          <div>
            <Link className="text-on-surface-variant hover:text-primary flex items-center gap-1.5 font-semibold text-[14px] mb-3 transition-colors group" href="/garden">
              <span className="material-symbols-outlined text-[18px] group-hover:-translate-x-1 transition-transform">arrow_back</span>
              Quay lại Khu Vườn
            </Link>
            <h1 className="font-bold text-[32px] text-on-surface">Hồ Sơ: Cây Trầu Bà Đế Vương</h1>
          </div>
          <div className="glass-panel px-6 py-3 rounded-full flex items-center gap-3 border border-primary-container/30 bg-primary-container/10">
            <span className="relative flex h-3 w-3">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-primary-container opacity-75"></span>
              <span className="relative inline-flex rounded-full h-3 w-3 bg-primary-container"></span>
            </span>
            <span className="font-semibold text-[14px] text-primary">Sức khỏe: Xuất Sắc (98%)</span>
          </div>
        </header>

        {/* Workspace Grid */}
        <div className="grid grid-cols-12 gap-6 lg:gap-8 relative">
          
          {/* Left Panel (Profile Content) */}
          <div className="col-span-12 lg:col-span-8 flex flex-col gap-6">
            
            {/* Conditions Grid */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <motion.div 
                whileHover={{ y: -4 }}
                className="glass-panel p-6 rounded-[1.5rem] flex flex-col border border-white/60"
              >
                <div className="w-10 h-10 rounded-full bg-tertiary-container/30 flex items-center justify-center mb-4 text-tertiary">
                  <span className="material-symbols-outlined text-[20px]">light_mode</span>
                </div>
                <h3 className="font-semibold text-[14px] text-on-surface-variant mb-1">Ánh sáng</h3>
                <p className="font-medium text-[15px] text-on-surface">Ưa bóng râm / Gián tiếp (40-60%)</p>
              </motion.div>

              <motion.div 
                whileHover={{ y: -4 }}
                className="glass-panel p-6 rounded-[1.5rem] flex flex-col border border-white/60"
              >
                <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center mb-4 text-blue-600">
                  <span className="material-symbols-outlined text-[20px]">water_drop</span>
                </div>
                <h3 className="font-semibold text-[14px] text-on-surface-variant mb-1">Tưới nước</h3>
                <p className="font-medium text-[15px] text-on-surface">Cần tưới sau 2 ngày nữa</p>
              </motion.div>

              <motion.div 
                whileHover={{ y: -4 }}
                className="glass-panel p-6 rounded-[1.5rem] flex flex-col border border-white/60"
              >
                <div className="w-10 h-10 rounded-full bg-orange-100 flex items-center justify-center mb-4 text-orange-600">
                  <span className="material-symbols-outlined text-[20px]">thermostat</span>
                </div>
                <h3 className="font-semibold text-[14px] text-on-surface-variant mb-1">Nhiệt độ & Đất</h3>
                <p className="font-medium text-[15px] text-on-surface">Đất hữu cơ tơi xốp | 22°C - 28°C</p>
              </motion.div>
            </div>

            {/* Today's Alert */}
            <div className="glass-panel rounded-full p-4 pl-6 flex items-center justify-between border-primary-container/30 bg-gradient-to-r from-primary-container/10 to-transparent">
              <div className="flex items-center gap-4">
                <div className="w-6 h-6 rounded-md border-2 border-primary-container flex items-center justify-center cursor-pointer hover:bg-primary-container/20 transition-colors">
                  <span className="material-symbols-outlined text-[14px] text-transparent hover:text-primary-container">check</span>
                </div>
                <span className="font-medium text-[15px] text-on-surface">Cần phun sương làm ẩm lá lúc 16:00 PM hôm nay</span>
              </div>
              <span className="material-symbols-outlined text-primary-container animate-pulse mr-2">notifications_active</span>
            </div>

            {/* Growth Log Timeline */}
            <div className="glass-panel rounded-[2rem] p-6 sm:p-8 mt-2 border border-white/60">
              <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-8">
                <h2 className="font-bold text-[24px] text-on-surface flex items-center gap-2">
                  <span className="material-symbols-outlined text-primary text-[28px]">history</span>
                  Nhật Ký Phát Triển
                </h2>
                <button className="bg-primary-container text-primary-fixed-variant font-semibold text-[14px] px-6 py-2.5 rounded-full hover:shadow-[0_0_15px_rgba(0,230,118,0.3)] transition-shadow flex items-center gap-2">
                  <span className="material-symbols-outlined text-[18px]">add</span>
                  Thêm Nhật Ký Mới
                </button>
              </div>

              <div className="relative pl-8 border-l-2 border-outline-variant/30 space-y-10 ml-2">
                {/* Node 1: Recent */}
                <div className="relative">
                  <div className="absolute -left-[43px] top-1 w-5 h-5 bg-primary-container rounded-full border-4 border-white shadow-sm flex items-center justify-center">
                    <div className="w-1.5 h-1.5 bg-white rounded-full"></div>
                  </div>
                  <span className="font-bold text-[14px] text-primary block mb-2">24/06/2026</span>
                  
                  <div className="bg-white/60 rounded-[1.5rem] p-6 shadow-sm border border-outline-variant/20">
                    <p className="font-medium text-[15px] text-on-surface mb-4">Cây ra thêm 2 lá non mới khỏe mạnh, chiều cao đạt 45cm.</p>
                    <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                      <Image 
                        width={200} height={100} unoptimized
                        alt="Plant photo 1" 
                        className="w-full h-28 object-cover rounded-xl" 
                        src="https://lh3.googleusercontent.com/aida-public/AB6AXuAjHAF0kyW7bep2NhfZmN0VWkivXFkUR_qL2MyR_FXlg8l3RRPMEH1Ktw9t6Qk7JxJ8QFz6_WqqiIOQIZMpRYF4o9o9M2BX5lqOU7F2a8KaozYQTzMhGt5FTB3FUwzqD7bOnLcPJwxtezXyVSAS9WNrWhzoKA71Fj-NgUnC4LzBWlmorK1QnalyonW7mjMX17rRJHtspa4PtjX1DsaL7ZKARufGAg6k4X2xNv7rVJBZBDWtzeODYBqE3Y6BqO_26pR40I7ZaNMm8-Q"
                      />
                      <Image 
                        width={200} height={100} unoptimized
                        alt="Plant photo 2" 
                        className="w-full h-28 object-cover rounded-xl" 
                        src="https://lh3.googleusercontent.com/aida-public/AB6AXuBZdxgbdXEtXq1LOzTFo_LIblyGF-9scAbbjr_MeAbvJ7DYoviofq7F-dJ4iSp_n3d-VeusOt_2y56Q8pCvCV_s5jZl7870lYfCXnPO6-GqeYnZQvRPixm_JCOhOCGnDSn4j69rUeH0M66WaEkAzG5Q1-3FxLYvTh7HykzZ-k737LJnfp1Hl_aGsrZACc3va-prhU9Mosp682m_ep_QiN2hY9dlBZKaWAO2Ex_UQ1ytJ_GvblfYk1u4u59H7CGi3Po64J7VUL1lf30"
                      />
                      <Image 
                        width={200} height={100} unoptimized
                        alt="Plant photo 3" 
                        className="w-full h-28 object-cover rounded-xl" 
                        src="https://lh3.googleusercontent.com/aida-public/AB6AXuCOwGcmCRyawTkbYRPeBeMAjjRXbaA80hvnZwxv4n5rfGk4TcyvWDq4BQHPTXFAfkb1Z5gTg9AXy10aNGGVQ9bKpzXyaOwqVPMPp-Xx_W8E6q9E5Ue_DRMIQ7aVRVI-MUDnOwfmvvC8TGviCR_nb0waPKxQ9o1ZKLyoHG1iJad5zyTk_788BvhZ2X9L18uBXzWpMjhSmBwwNMcrKMYJqR-3KFMVyavXCCGbjQaSKIoHrxDpnHHXhFRLX7zmXz7YE10n3_2RzNZzjiU"
                      />
                    </div>
                  </div>
                </div>

                {/* Node 2: History (Issue) */}
                <div className="relative">
                  <div className="absolute -left-[43px] top-1 w-5 h-5 bg-surface-variant rounded-full border-4 border-white shadow-sm"></div>
                  <span className="font-bold text-[14px] text-on-surface-variant block mb-2">15/05/2026</span>
                  
                  <div className="bg-error-container/20 rounded-[1.5rem] p-6 border border-error/10">
                    <div className="flex flex-col sm:flex-row justify-between sm:items-center gap-2 mb-2">
                      <h4 className="font-bold text-[15px] text-error flex items-center gap-2">
                        <span className="material-symbols-outlined text-[18px]">warning</span>
                        Phát hiện Bệnh Đốm Lá
                      </h4>
                      <span className="text-[11px] font-bold px-2.5 py-1 rounded-md bg-surface-variant text-on-surface-variant uppercase tracking-wide w-fit">Đã Chữa Khỏi</span>
                    </div>
                    <p className="font-medium text-[14px] text-on-surface-variant">Điều trị bằng thuốc chống nấm sinh học trong 2 tuần liên tục.</p>
                  </div>
                </div>
              </div>
            </div>
            
            {/* Pad bottom for scroll */}
            <div className="h-8"></div>
          </div>

          {/* Right Panel (AI Assistant Sidebar) */}
          <div className="col-span-12 lg:col-span-4 h-full hidden lg:block">
            <div className="glass-panel rounded-[2rem] h-[calc(100vh-140px)] sticky top-4 flex flex-col overflow-hidden border border-white/60 shadow-[0_12px_40px_rgba(0,0,0,0.06)]">
              {/* Chat Header */}
              <div className="p-5 border-b border-surface-variant/50 bg-white/40 flex items-center gap-3">
                <div className="w-11 h-11 rounded-full bg-primary-container/30 flex items-center justify-center relative">
                  <span className="material-symbols-outlined text-primary text-[22px]">psychology</span>
                  <span className="absolute bottom-0 right-0 w-3 h-3 bg-primary-container rounded-full border-2 border-white"></span>
                </div>
                <div>
                  <h3 className="font-bold text-[16px] text-on-surface leading-tight">Trợ Lý Floria AI</h3>
                  <p className="font-semibold text-[11px] text-primary mt-0.5 tracking-wide">PHÂN TÍCH: TRẦU BÀ ĐẾ VƯƠNG</p>
                </div>
              </div>

              {/* Chat Thread */}
              <div className="flex-1 overflow-y-auto p-5 flex flex-col gap-5 hide-scrollbar">
                {/* AI Message */}
                <div className="flex items-start gap-3 w-11/12">
                  <div className="w-8 h-8 rounded-full bg-primary-container/30 flex-shrink-0 flex items-center justify-center mt-1">
                    <span className="material-symbols-outlined text-primary text-[16px]">psychology</span>
                  </div>
                  <div className="bg-white/80 rounded-2xl rounded-tl-sm p-4 shadow-sm border border-outline-variant/10">
                    <p className="font-medium text-[14px] text-on-surface leading-relaxed">Xin chào! Tôi đã xem lại hồ sơ bệnh án cũ và trạng thái hiện tại. Cây Trầu Bà của bạn đang phát triển rất tốt. Bạn cần tư vấn về việc đổi chậu không?</p>
                  </div>
                </div>

                {/* User Message */}
                <div className="flex items-start gap-3 w-11/12 ml-auto flex-row-reverse">
                  <Image 
                    width={32} height={32} unoptimized
                    alt="User" 
                    className="w-8 h-8 rounded-full object-cover flex-shrink-0 mt-1" 
                    src="https://lh3.googleusercontent.com/aida-public/AB6AXuA07BAqv9FzT64AvnPEYxvngsPOjjK19tQRMbio6c85H6CwIoTf_8aX2xMuRq6a3srNM6RFVXeDcUePpED3iKi6HfNZpx7IZskb5s1i9gX9oCgI0hdsqJMsj3NQ2FO0CbZ-V3zQEMWgMQUtFgh-VSGMMM7JiPIpC_kGLr9DAZ02oZHDbRgmLOZhbbuBfvWvVgCW72Z1LmpULpKEsWv9p0kGQY3HuZVZehiG52R0oRwgUGF6Wd3QLhYocm7to4YvJlvtF-ohJD1mNVY"
                  />
                  <div className="bg-surface-container-high rounded-2xl rounded-tr-sm p-4 shadow-sm">
                    <p className="font-medium text-[14px] text-on-surface">Có nên đổi chậu lớn hơn vào tháng sau không bot?</p>
                  </div>
                </div>

                {/* Typing indicator */}
                <div className="flex items-center gap-1.5 pl-11 opacity-60 mt-1">
                  <div className="w-1.5 h-1.5 rounded-full bg-primary animate-bounce" style={{ animationDelay: '0s' }}></div>
                  <div className="w-1.5 h-1.5 rounded-full bg-primary animate-bounce" style={{ animationDelay: '0.2s' }}></div>
                  <div className="w-1.5 h-1.5 rounded-full bg-primary animate-bounce" style={{ animationDelay: '0.4s' }}></div>
                </div>
              </div>

              {/* Chat Input */}
              <div className="p-4 bg-white/60 border-t border-surface-variant/30 backdrop-blur-md">
                <div className="relative flex items-center">
                  <input 
                    className="w-full bg-white/80 border border-outline-variant/30 rounded-full py-3.5 pl-5 pr-12 font-medium text-[14px] focus:outline-none focus:border-primary-container focus:ring-1 focus:ring-primary-container shadow-sm transition-all placeholder:text-on-surface-variant/60" 
                    placeholder="Hỏi trợ lý AI..." 
                    type="text"
                  />
                  <button className="absolute right-1.5 w-9 h-9 rounded-full bg-primary-container flex items-center justify-center text-primary-fixed-variant hover:bg-primary hover:text-white transition-colors shadow-sm">
                    <span className="material-symbols-outlined text-[16px]">send</span>
                  </button>
                </div>
              </div>
            </div>
          </div>

        </div>
      </div>
    </main>
  );
}
