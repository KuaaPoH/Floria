"use client";
import Image from "next/image";
import Link from "next/link";
import { motion } from "motion/react";

export default function DiagnosticResultPage() {
  return (
    <main className="max-w-max-width mx-auto px-4 md:px-8 py-8 md:py-12 w-full flex-grow">
      {/* Header Info */}
      <div className="mb-8">
        <Link className="text-on-surface-variant hover:text-primary flex items-center gap-1.5 font-semibold text-[14px] mb-4 transition-colors group w-fit" href="/diagnostic">
          <span className="material-symbols-outlined text-[18px] group-hover:-translate-x-1 transition-transform">arrow_back</span>
          Tải ảnh khác
        </Link>
        <h1 className="font-bold text-[36px] text-primary mb-2">Báo Cáo Chẩn Đoán</h1>
        <p className="text-on-surface-variant font-medium text-[16px]">Mã báo cáo: #DIA-849201 • Cập nhật: Hôm nay, 10:30 AM</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
        
        {/* Left Column: Image & Stats */}
        <div className="lg:col-span-5 space-y-8">
          
          {/* Main Image Card */}
          <motion.div 
            initial={{ opacity: 0, scale: 0.98 }}
            animate={{ opacity: 1, scale: 1 }}
            className="glass-panel bg-white/60 rounded-[1.5rem] p-4 overflow-hidden relative group border border-outline-variant/30"
          >
            <div className="absolute top-8 left-8 z-10 bg-error text-on-error px-4 py-1.5 rounded-full font-bold text-[13px] shadow-lg uppercase tracking-wide">
              Bệnh Đốm Lá Thán Thư
            </div>
            <div className="w-full h-[400px] md:h-[500px] relative rounded-xl overflow-hidden">
              <Image 
                src="https://lh3.googleusercontent.com/aida-public/AB6AXuC7OmiiLf05nw9U-WzVFzVXARoUTxef8U0D-q8XpKyJDvCA6H2ZZs8GSMrJnsOMJS8Dxw53Ms-9c2ZHMBkiGWFhlKD9EXzdnErWNZRcndTGn8n-58Ht_BQEGDGnrcHcaAqU6pQk_II4pCFY-L_cQdWBQDLxhe-ZUUPTIvxtkxej4roeRQXQRfsFmNKEwrXUT3VG--ccZUEYdu_OiXyIpWl7lADO-GSLeOxu6PJc6V_ZCfbZ0I_WMBP6CJzx_WUcuKelRjzULzf0YTg"
                alt="Ảnh cây bị bệnh"
                fill
                unoptimized
                className="object-cover transition-transform duration-700 group-hover:scale-105"
              />
            </div>
          </motion.div>

          {/* Environmental Stats */}
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="glass-panel rounded-[1.5rem] p-6 sm:p-8 border border-outline-variant/30"
          >
            <h3 className="font-bold text-[20px] text-on-surface mb-6 flex items-center gap-2">
              <span className="material-symbols-outlined text-primary">sensors</span>
              Thông Số Môi Trường
            </h3>
            <div className="grid grid-cols-2 gap-4">
              <div className="bg-surface/50 p-5 rounded-[1rem] border border-outline-variant/20 hover:bg-white/60 transition-colors">
                <div className="text-on-surface-variant font-semibold text-[13px] mb-1 flex items-center gap-1.5">
                  <span className="material-symbols-outlined text-[18px]">water_drop</span> Độ Ẩm Đất
                </div>
                <div className="font-bold text-[36px] text-error">85%</div>
                <div className="text-error font-medium text-[13px] mt-1 flex items-center gap-1">
                  <span className="material-symbols-outlined text-[16px]">arrow_upward</span> Quá cao
                </div>
              </div>
              
              <div className="bg-surface/50 p-5 rounded-[1rem] border border-outline-variant/20 hover:bg-white/60 transition-colors">
                <div className="text-on-surface-variant font-semibold text-[13px] mb-1 flex items-center gap-1.5">
                  <span className="material-symbols-outlined text-[18px]">light_mode</span> Ánh Sáng
                </div>
                <div className="font-bold text-[36px] text-primary">450 <span className="text-[18px] font-medium">lx</span></div>
                <div className="text-primary font-medium text-[13px] mt-1 flex items-center gap-1">
                  <span className="material-symbols-outlined text-[16px]">check</span> Tối ưu
                </div>
              </div>
            </div>
          </motion.div>
        </div>

        {/* Right Column: Details & Treatment */}
        <div className="lg:col-span-7 space-y-8">
          
          <motion.div 
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            className="glass-panel bg-white/60 rounded-[2rem] p-6 sm:p-10 border border-outline-variant/30 shadow-sm"
          >
            {/* Diagnosis Summary */}
            <div className="flex flex-col sm:flex-row justify-between items-start mb-6 gap-4">
              <div>
                <h2 className="font-bold text-[28px] text-on-surface leading-tight">Kết Quả Phân Tích</h2>
                <p className="text-on-surface-variant font-medium text-[16px] mt-2">Mức độ tin cậy của AI: <span className="text-primary font-bold">94.2%</span></p>
              </div>
              <div className="bg-error-container text-on-error-container px-4 py-2 rounded-[0.75rem] font-bold text-[13px] flex items-center gap-2 shrink-0">
                <span className="material-symbols-outlined text-[18px]">warning</span> Nguy cơ lây lan cao
              </div>
            </div>
            
            <p className="text-on-surface-variant font-medium text-[16px] leading-relaxed mb-8">
              Cây của bạn đang có dấu hiệu nhiễm nấm <strong>Colletotrichum</strong> gây ra bệnh thán thư. Nguyên nhân chính thường do môi trường quá ẩm ướt kết hợp với thông gió kém. Các vết đốm sẽ lan rộng nhanh chóng nếu không được xử lý kịp thời.
            </p>

            {/* Treatment Checklist */}
            <h3 className="font-bold text-[22px] text-on-surface mb-5 mt-8 flex items-center gap-2">
              <span className="material-symbols-outlined text-primary text-[24px]">healing</span>
              Phác Đồ Điều Trị
            </h3>
            
            <div className="space-y-4">
              <label className="flex items-start gap-4 p-5 bg-white/80 hover:bg-white rounded-[1rem] border border-outline-variant/30 cursor-pointer transition-all shadow-sm group">
                <div className="relative flex items-center justify-center w-6 h-6 mt-0.5 shrink-0">
                  <input className="peer appearance-none w-6 h-6 border-2 border-outline/50 rounded-md checked:bg-primary checked:border-primary transition-all cursor-pointer" type="checkbox" />
                  <span className="material-symbols-outlined absolute text-white opacity-0 peer-checked:opacity-100 pointer-events-none text-[18px]">check</span>
                </div>
                <div>
                  <h4 className="font-bold text-[16px] text-on-surface group-hover:text-primary transition-colors">Cách ly cây bệnh</h4>
                  <p className="text-on-surface-variant font-medium text-[14px] mt-1.5 leading-relaxed">Ngay lập tức di chuyển cây ra khỏi khu vực có các cây khác để tránh lây nhiễm chéo qua bào tử nấm.</p>
                </div>
              </label>

              <label className="flex items-start gap-4 p-5 bg-white/80 hover:bg-white rounded-[1rem] border border-outline-variant/30 cursor-pointer transition-all shadow-sm group">
                <div className="relative flex items-center justify-center w-6 h-6 mt-0.5 shrink-0">
                  <input className="peer appearance-none w-6 h-6 border-2 border-outline/50 rounded-md checked:bg-primary checked:border-primary transition-all cursor-pointer" type="checkbox" />
                  <span className="material-symbols-outlined absolute text-white opacity-0 peer-checked:opacity-100 pointer-events-none text-[18px]">check</span>
                </div>
                <div>
                  <h4 className="font-bold text-[16px] text-on-surface group-hover:text-primary transition-colors">Cắt bỏ phần lá bệnh</h4>
                  <p className="text-on-surface-variant font-medium text-[14px] mt-1.5 leading-relaxed">Sử dụng kéo đã sát trùng để cắt bỏ toàn bộ những lá có vết đốm nâu. Tiêu hủy rác thải này xa khu vườn.</p>
                </div>
              </label>

              <label className="flex items-start gap-4 p-5 bg-white/80 hover:bg-white rounded-[1rem] border border-outline-variant/30 cursor-pointer transition-all shadow-sm group">
                <div className="relative flex items-center justify-center w-6 h-6 mt-0.5 shrink-0">
                  <input className="peer appearance-none w-6 h-6 border-2 border-outline/50 rounded-md checked:bg-primary checked:border-primary transition-all cursor-pointer" type="checkbox" />
                  <span className="material-symbols-outlined absolute text-white opacity-0 peer-checked:opacity-100 pointer-events-none text-[18px]">check</span>
                </div>
                <div>
                  <h4 className="font-bold text-[16px] text-on-surface group-hover:text-primary transition-colors">Sử dụng thuốc diệt nấm</h4>
                  <p className="text-on-surface-variant font-medium text-[14px] mt-1.5 leading-relaxed">Phun chế phẩm sinh học chứa gốc Đồng (Copper) hoặc thuốc đặc trị thán thư theo đúng liều lượng chỉ định.</p>
                </div>
              </label>
            </div>

            {/* CTA Action */}
            <div className="mt-10 pt-8 border-t border-outline-variant/20 flex flex-col sm:flex-row items-center justify-between gap-6">
              <p className="text-on-surface-variant font-medium text-[14px] max-w-sm text-center sm:text-left">
                Cần hỗ trợ cụ thể hơn cho trường hợp của bạn? BotaniScan AI luôn sẵn sàng.
              </p>
              <Link href="/ai-assistant" className="bg-primary-container text-on-primary-container hover:bg-primary hover:text-white px-8 py-4 rounded-full font-bold text-[15px] shadow-lg shadow-primary-container/30 transition-all active:scale-[0.98] flex items-center gap-2 group shrink-0 w-full sm:w-auto justify-center">
                <span className="material-symbols-outlined group-hover:animate-pulse">smart_toy</span>
                Tư vấn chuyên sâu với AI
              </Link>
            </div>

          </motion.div>
        </div>

      </div>
    </main>
  );
}
