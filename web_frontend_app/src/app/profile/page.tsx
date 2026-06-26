"use client";
import Image from "next/image";
import Link from "next/link";
import { motion } from "motion/react";

export default function ProfilePage() {
  return (
    <main className="flex-grow flex flex-col relative w-full min-h-[calc(100vh-80px)] bg-surface-bright py-8 md:py-12 overflow-hidden">
      {/* Background with abstract shapes/gradients */}
      <div className="absolute inset-0 bg-white/60 backdrop-blur-3xl z-0 pointer-events-none"></div>
      <div className="absolute top-[5%] right-[10%] w-[500px] h-[500px] bg-primary/5 rounded-full blur-[100px] pointer-events-none"></div>

      <div className="relative z-10 w-full max-w-max-width mx-auto px-4 md:px-8">
        
        {/* Profile Header & Banner Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 mb-12">
          
          {/* Profile Info Card */}
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="lg:col-span-4 glass-panel bg-white/80 border border-outline-variant/30 rounded-[2rem] p-8 flex flex-col items-center text-center shadow-sm relative overflow-hidden"
          >
            <div className="absolute top-0 w-full h-32 bg-gradient-to-b from-primary-container/20 to-transparent"></div>
            
            <div className="relative w-32 h-32 rounded-full overflow-hidden mb-6 border-4 border-white shadow-md z-10">
              <Image 
                width={128} height={128} unoptimized
                alt="User Profile Avatar" 
                className="w-full h-full object-cover" 
                src="https://lh3.googleusercontent.com/aida-public/AB6AXuBV33OwAYVKKpxQbjvA7qzum-cXBWCwVBeuexLd8JQnDqB40vm-D9wjLSBoDIDzP4Q9aFWc8nubSb9CdKdAOnlCNnjn3HJs9Rp3NiausZnhoPDC_E0kQS3gGKlbFihEBG3b4kxhXYB9MUcs_qlQEZZ1l2YUBqlp23mDAXF3d9gQPHuFrTKJ1FIwh_lU6z3zQipRKT7H-CEvj8SbfEOK44QQGUx4zBwXc1WdslU6ur7uWbUodyyxfmlRpEZ_XGiPYA97lEDBHA66DOY"
              />
            </div>
            
            <h1 className="font-bold text-[28px] text-on-surface mb-1 z-10">Tuấn Nguyễn</h1>
            <p className="font-medium text-[15px] text-on-surface-variant mb-6 z-10">tuan.nguyen@example.com</p>
            
            <button className="bg-surface-container hover:bg-surface-container-high text-on-surface font-semibold text-[14px] py-2.5 px-6 rounded-full transition-colors w-full mb-6 z-10 border border-outline-variant/50">
              Chỉnh sửa hồ sơ
            </button>
            
            <div className="flex gap-4 w-full justify-center z-10">
              <div className="text-center px-4">
                <p className="font-bold text-[24px] text-primary">12</p>
                <p className="font-semibold text-[12px] text-on-surface-variant">Cây trồng</p>
              </div>
              <div className="w-px bg-outline-variant/30"></div>
              <div className="text-center px-4">
                <p className="font-bold text-[24px] text-primary">45</p>
                <p className="font-semibold text-[12px] text-on-surface-variant">Chẩn đoán</p>
              </div>
            </div>
          </motion.div>

          {/* PRO Banner & Quick Stats */}
          <div className="lg:col-span-8 flex flex-col gap-8">
            
            {/* PRO Banner */}
            <motion.div 
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.1 }}
              className="relative rounded-[2rem] p-8 text-white shadow-lg flex flex-col sm:flex-row items-start sm:items-center justify-between gap-6 overflow-hidden bg-gradient-to-br from-primary-container to-primary"
            >
              {/* Shine effect overlay using Tailwind */}
              <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent -translate-x-full animate-[shimmer_3s_infinite] skew-x-[-20deg]"></div>
              
              <div className="relative z-10">
                <div className="flex items-center gap-2 mb-2">
                  <span className="material-symbols-outlined text-[#FFD700] text-[28px]" style={{ fontVariationSettings: "'FILL' 1" }}>workspace_premium</span>
                  <h2 className="font-bold text-[24px] text-[#FFD700]">BotaniScan PRO</h2>
                </div>
                <p className="font-medium text-[15px] text-white/90 max-w-md">Mở khóa chẩn đoán không giới hạn và nhận tư vấn chuyên sâu từ chuyên gia thực vật học.</p>
              </div>
              <button className="relative z-10 bg-white text-primary font-bold text-[14px] py-3.5 px-8 rounded-full hover:shadow-lg hover:scale-105 transition-all duration-300 whitespace-nowrap shrink-0">
                Nâng cấp ngay
              </button>
            </motion.div>

            {/* Recent Activity Mini Bento */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-8 flex-grow">
              
              <motion.div 
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.2 }}
                className="glass-panel bg-white/60 rounded-[1.5rem] p-6 flex flex-col justify-between border border-outline-variant/30 shadow-sm hover:bg-white/80 transition-colors cursor-pointer group"
              >
                <div className="flex items-center gap-3 mb-6">
                  <div className="w-12 h-12 rounded-full bg-primary-container/20 flex items-center justify-center text-primary group-hover:scale-110 transition-transform">
                    <span className="material-symbols-outlined">local_florist</span>
                  </div>
                  <h3 className="font-bold text-[16px] text-on-surface">Cây vừa quét</h3>
                </div>
                <div>
                  <p className="font-bold text-[18px] text-on-surface">Monstera Deliciosa</p>
                  <p className="font-medium text-[14px] text-primary mt-1">2 giờ trước - Khỏe mạnh</p>
                </div>
              </motion.div>

              <motion.div 
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.3 }}
                className="glass-panel bg-white/60 rounded-[1.5rem] p-6 flex flex-col justify-between border border-outline-variant/30 shadow-sm hover:bg-white/80 transition-colors cursor-pointer group"
              >
                <div className="flex items-center gap-3 mb-6">
                  <div className="w-12 h-12 rounded-full bg-error-container/40 flex items-center justify-center text-error group-hover:scale-110 transition-transform">
                    <span className="material-symbols-outlined">warning</span>
                  </div>
                  <h3 className="font-bold text-[16px] text-on-surface">Cần chú ý</h3>
                </div>
                <div>
                  <p className="font-bold text-[18px] text-on-surface">Lan Hồ Điệp</p>
                  <p className="font-medium text-[14px] text-error mt-1 flex items-center gap-1">
                    <span className="material-symbols-outlined text-[16px]">error</span> Phát hiện đốm lá
                  </p>
                </div>
              </motion.div>

            </div>
          </div>
        </div>

        {/* Settings Groups Grid */}
        <h2 className="font-bold text-[24px] text-on-surface mb-8">Cài đặt & Tùy chỉnh</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          
          {/* Account Settings */}
          <div className="glass-panel bg-white/70 rounded-[2rem] p-6 border border-outline-variant/30 shadow-sm">
            <div className="flex items-center gap-3 mb-6 border-b border-outline-variant/30 pb-4">
              <span className="material-symbols-outlined text-primary text-[24px]">manage_accounts</span>
              <h3 className="font-bold text-[18px] text-on-surface">Tài khoản</h3>
            </div>
            <ul className="space-y-1">
              <li>
                <button className="w-full flex items-center justify-between p-3 rounded-xl hover:bg-white transition-colors group">
                  <span className="font-semibold text-[15px] text-on-surface group-hover:text-primary transition-colors">Thông tin cá nhân</span>
                  <span className="material-symbols-outlined text-on-surface-variant group-hover:text-primary transition-colors">chevron_right</span>
                </button>
              </li>
              <li>
                <button className="w-full flex items-center justify-between p-3 rounded-xl hover:bg-white transition-colors group">
                  <span className="font-semibold text-[15px] text-on-surface group-hover:text-primary transition-colors">Bảo mật & Mật khẩu</span>
                  <span className="material-symbols-outlined text-on-surface-variant group-hover:text-primary transition-colors">chevron_right</span>
                </button>
              </li>
              <li>
                <button className="w-full flex items-center justify-between p-3 rounded-xl hover:bg-white transition-colors group">
                  <span className="font-semibold text-[15px] text-on-surface group-hover:text-primary transition-colors">Quản lý gói PRO</span>
                  <span className="material-symbols-outlined text-on-surface-variant group-hover:text-primary transition-colors">chevron_right</span>
                </button>
              </li>
            </ul>
          </div>

          {/* Preferences Settings */}
          <div className="glass-panel bg-white/70 rounded-[2rem] p-6 border border-outline-variant/30 shadow-sm">
            <div className="flex items-center gap-3 mb-6 border-b border-outline-variant/30 pb-4">
              <span className="material-symbols-outlined text-primary text-[24px]">settings_suggest</span>
              <h3 className="font-bold text-[18px] text-on-surface">Tùy chỉnh</h3>
            </div>
            <ul className="space-y-2">
              <li className="flex items-center justify-between p-3">
                <div>
                  <p className="font-semibold text-[15px] text-on-surface">Thông báo đẩy</p>
                  <p className="text-[13px] font-medium text-on-surface-variant">Lịch tưới nước, bón phân</p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input defaultChecked className="sr-only peer" type="checkbox" />
                  <div className="w-11 h-6 bg-surface-variant peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                </label>
              </li>
              <li className="flex items-center justify-between p-3">
                <div>
                  <p className="font-semibold text-[15px] text-on-surface">Giao diện tối</p>
                  <p className="text-[13px] font-medium text-on-surface-variant">Tự động theo hệ thống</p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input className="sr-only peer" type="checkbox" />
                  <div className="w-11 h-6 bg-surface-variant peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                </label>
              </li>
              <li>
                <button className="w-full flex items-center justify-between p-3 rounded-xl hover:bg-white transition-colors group mt-2">
                  <span className="font-semibold text-[15px] text-on-surface group-hover:text-primary transition-colors">Ngôn ngữ (Tiếng Việt)</span>
                  <span className="material-symbols-outlined text-on-surface-variant group-hover:text-primary transition-colors">chevron_right</span>
                </button>
              </li>
            </ul>
          </div>

          {/* Support & About */}
          <div className="glass-panel bg-white/70 rounded-[2rem] p-6 border border-outline-variant/30 shadow-sm">
            <div className="flex items-center gap-3 mb-6 border-b border-outline-variant/30 pb-4">
              <span className="material-symbols-outlined text-primary text-[24px]">support_agent</span>
              <h3 className="font-bold text-[18px] text-on-surface">Hỗ trợ & Ứng dụng</h3>
            </div>
            <ul className="space-y-1">
              <li>
                <button className="w-full flex items-center justify-between p-3 rounded-xl hover:bg-white transition-colors group">
                  <span className="font-semibold text-[15px] text-on-surface group-hover:text-primary transition-colors">Trung tâm trợ giúp</span>
                  <span className="material-symbols-outlined text-on-surface-variant group-hover:text-primary transition-colors">open_in_new</span>
                </button>
              </li>
              <li>
                <button className="w-full flex items-center justify-between p-3 rounded-xl hover:bg-white transition-colors group">
                  <span className="font-semibold text-[15px] text-on-surface group-hover:text-primary transition-colors">Gửi phản hồi</span>
                  <span className="material-symbols-outlined text-on-surface-variant group-hover:text-primary transition-colors">chat</span>
                </button>
              </li>
              <li>
                <button className="w-full flex items-center justify-between p-3 rounded-xl hover:bg-white transition-colors group">
                  <span className="font-semibold text-[15px] text-on-surface group-hover:text-primary transition-colors">Điều khoản dịch vụ</span>
                  <span className="material-symbols-outlined text-on-surface-variant group-hover:text-primary transition-colors">description</span>
                </button>
              </li>
              <li className="mt-4 pt-4 border-t border-outline-variant/30">
                <button className="w-full flex items-center justify-center gap-2 p-3 rounded-xl hover:bg-error/10 text-error transition-colors group">
                  <span className="material-symbols-outlined">logout</span>
                  <span className="font-bold text-[15px]">Đăng xuất</span>
                </button>
              </li>
            </ul>
          </div>

        </div>
      </div>
    </main>
  );
}
