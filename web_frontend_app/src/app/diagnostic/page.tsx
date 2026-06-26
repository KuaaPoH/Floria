"use client";
import Image from "next/image";
import Link from "next/link";
import { motion } from "motion/react";

export default function DiagnosticPage() {
  return (
    <main className="flex-1 flex flex-col overflow-y-auto w-full max-w-max-width mx-auto px-4 md:px-8 py-8 min-h-[calc(100vh-80px)]">
      {/* TOP HEADER */}
      <div className="w-full mb-8">
        <h1 className="font-bold text-[28px] text-[#333333] mb-2">Chẩn Đoán Bệnh</h1>
        <p className="font-medium text-[15px] text-on-surface-variant">Tải ảnh lá cây bị tổn thương để AI phân tích tức thì.</p>
      </div>

      {/* MAIN CONTENT: SPLIT LAYOUT */}
      <div className="flex-1 flex flex-col lg:flex-row gap-6 w-full pb-4">
        
        {/* LEFT PANEL (Upload & Settings) */}
        <div className="w-full lg:w-3/5 flex flex-col gap-6">
          
          {/* Drag & Drop Zone */}
          <motion.div 
            initial={{ opacity: 0, scale: 0.98 }}
            animate={{ opacity: 1, scale: 1 }}
            className="border-2 border-dashed border-primary/40 bg-[#F1FBEE]/50 rounded-[24px] h-[250px] sm:h-[300px] flex flex-col items-center justify-center cursor-pointer hover:bg-[#F1FBEE] transition-all relative group flex-shrink-0"
          >
            <div className="absolute inset-0 bg-primary-container/5 rounded-[24px] opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none"></div>
            <span className="material-symbols-outlined text-[56px] text-primary-container drop-shadow-[0_0_15px_rgba(0,230,118,0.4)] mb-4 group-hover:-translate-y-2 transition-transform duration-300">cloud_upload</span>
            <h2 className="font-bold text-[18px] text-on-surface mb-2">Kéo thả ảnh vào đây</h2>
            <p className="font-medium text-[14px] text-on-surface-variant mb-2 text-center px-4">
              hoặc click để <span className="text-primary font-semibold hover:underline">Chọn File từ máy tính</span>
            </p>
            <p className="font-medium text-[12px] text-outline">Hỗ trợ JPG, PNG (Tối đa 10MB)</p>
          </motion.div>

          {/* AI Engine Selector */}
          <div className="flex flex-col gap-3">
            <h3 className="font-semibold text-[15px] text-on-surface">Động cơ AI</h3>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              
              {/* Basic Card */}
              <button className="glass-panel rounded-xl p-3 text-left border border-outline-variant hover:border-primary transition-colors focus:ring-2 focus:ring-primary-container outline-none bg-white">
                <span className="material-symbols-outlined text-primary mb-1 block text-[20px]">speed</span>
                <div className="font-bold text-[14px] mb-1">Basic</div>
                <div className="font-medium text-[12px] text-on-surface-variant leading-tight">Nhanh, độ chính xác cơ bản.</div>
              </button>
              
              {/* DeepVision Card (Selected) */}
              <button className="glass-panel rounded-xl p-3 text-left border-2 border-primary bg-primary-container/10 relative overflow-hidden focus:ring-2 focus:ring-primary-container outline-none">
                <div className="absolute top-0 right-0 w-12 h-12 bg-primary/10 rounded-bl-full -mr-6 -mt-6"></div>
                <span className="material-symbols-outlined text-primary mb-1 block text-[20px]" style={{ fontVariationSettings: "'FILL' 1" }}>troubleshoot</span>
                <div className="font-bold text-[14px] text-primary mb-1">DeepVision</div>
                <div className="font-medium text-[12px] text-on-surface-variant leading-tight">Độ chính xác cao, khuyên dùng.</div>
              </button>
              
              {/* Ultra AI (Locked) */}
              <button className="glass-panel rounded-xl p-3 text-left border border-outline-variant/50 bg-surface-container-lowest/50 opacity-80 cursor-not-allowed relative">
                <div className="absolute top-2 right-2 w-5 h-5">
                  <Image width={20} height={20} unoptimized alt="Premium" className="w-full h-full object-contain drop-shadow-sm" src="https://lh3.googleusercontent.com/aida/AP1WRLs-N2eCOgbr8hbZiLfTa4iHszKAJOFUGlZ-9Hsuivs5J83sxXQW9m_4jMa88pJ8YaFs6AyXVCuV-OrMUAyXRSVd_s2ENh4vkYxiUcM1oEUUsiu84ZlHIjCenqVmHFrQ8bFeYxwgDYQAKGUuwLWjRUTqtV9oLpQQL7hJQx_qLYQxWuB6wRJQlswkHiUk33HNqnhWsxsw9Ll_7C6jreAXr0p6HBOtY0p1xAToLA04vsLuvtxAM6SRIm3kEQ"/>
                </div>
                <span className="material-symbols-outlined text-outline mb-1 block text-[20px]">auto_awesome</span>
                <div className="font-bold text-[14px] text-outline mb-1">Ultra AI</div>
                <div className="font-medium text-[12px] text-outline leading-tight">Phân tích sâu. Cần thẻ Pro.</div>
              </button>

            </div>
          </div>

          {/* Action Button */}
          <div className="mt-2 shrink-0">
            <Link href="/diagnostic/result" className="block w-full text-center py-4 rounded-full bg-primary-container text-on-primary-container font-bold text-[16px] shadow-lg shadow-primary-container/20 hover:shadow-xl hover:-translate-y-0.5 transition-all active:scale-[0.98]">
              Bắt Đầu Phân Tích
            </Link>
          </div>

        </div>

        {/* RIGHT PANEL (Guidelines) */}
        <motion.div 
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          className="w-full lg:w-2/5 flex flex-col h-full"
        >
          <div className="glass-panel bg-white/80 rounded-[24px] p-5 sm:p-6 flex flex-col h-full relative overflow-hidden border border-outline-variant/30 shadow-sm">
            {/* Subtle background decoration */}
            <div className="absolute -top-20 -right-20 w-64 h-64 bg-primary-container/10 rounded-full blur-3xl pointer-events-none"></div>
            
            <div className="flex items-center gap-2 mb-4 relative z-10 shrink-0">
              <span className="material-symbols-outlined text-primary text-[22px]">info</span>
              <h2 className="font-bold text-[18px] text-on-surface">Hướng Dẫn Tải Ảnh Chuẩn</h2>
            </div>
            
            {/* Mini Illustration */}
            <div className="w-full h-32 sm:h-40 bg-surface-container-low rounded-xl mb-4 flex items-center justify-center border border-outline-variant/30 overflow-hidden relative shrink-0">
              <Image 
                width={400} height={160} unoptimized 
                alt="Guide illustration" 
                className="w-full h-full object-cover" 
                src="https://lh3.googleusercontent.com/aida/AP1WRLt___mLU2_355fqQTpgOp5ydiaWx40DQq9O220rNYeRGgqO6MTZAVb7Rmtxj7e18YnFrmKyAbHYctZOi6LyO2ovqCQicsKgHovtWLzoM2CDCESvLTXf7ovPYCGDcMCjKXZMZcr_nxpmdMCpV2vnmkWGgQW4NqJZTMpK-lYFo3gWxuYO_QMjwaD-4U6cJuTiE2wVqlqlimV250IktORKUByfI3PRSrlFNe-dQudXXJWiYYYIDcxxFcrAPA0"
              />
            </div>
            
            {/* Guidelines */}
            <div className="space-y-3 flex-1 relative z-10 overflow-y-auto hide-scrollbar">
              {/* Do's */}
              <div className="bg-[#F1FBEE] rounded-xl p-4 border border-[#C8E6C9]">
                <h3 className="font-bold text-[14px] text-primary mb-1.5 flex items-center gap-1.5">
                  <span className="material-symbols-outlined text-[16px]">check_circle</span>
                  Nên làm
                </h3>
                <ul className="font-medium text-[13px] text-on-surface-variant space-y-1 pl-6 list-disc marker:text-primary">
                  <li>Chụp cận cảnh phần lá bị bệnh.</li>
                  <li>Ánh sáng tự nhiên, đủ sáng.</li>
                </ul>
              </div>
              
              {/* Don'ts */}
              <div className="bg-error-container/30 rounded-xl p-4 border border-error-container/50">
                <h3 className="font-bold text-[14px] text-error mb-1.5 flex items-center gap-1.5">
                  <span className="material-symbols-outlined text-[16px]">cancel</span>
                  Tránh làm
                </h3>
                <ul className="font-medium text-[13px] text-on-surface-variant space-y-1 pl-6 list-disc marker:text-error">
                  <li>Ảnh mờ, rung lắc khi chụp.</li>
                  <li>Ngược sáng hoặc lá chồng chéo.</li>
                </ul>
              </div>
            </div>
          </div>
        </motion.div>

      </div>
    </main>
  );
}
