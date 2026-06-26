"use client";

import { motion } from "motion/react";
import { useState, useRef } from "react";
import Image from "next/image";

export default function AIAssistantPage() {
  const [messages, setMessages] = useState([
    {
      id: 1,
      role: "ai",
      text: "Xin chào! Tôi là Floria AI. Tôi có thể giúp gì cho khu vườn của bạn hôm nay?",
    },
    {
      id: 2,
      role: "user",
      text: "Cây bàng Singapore của tôi dạo này bị rụng lá dưới gốc khá nhiều, lá hơi ngả vàng. Nguyên nhân là gì vậy?",
    },
    {
      id: 3,
      role: "ai",
      text: "Hiện tượng bàng Singapore rụng lá dưới gốc và ngả vàng thường do 2 nguyên nhân chính:\n\n1. Thiếu ánh sáng: Nếu cây đặt ở nơi quá tối, lá ở dưới không quang hợp được sẽ rụng.\n2. Tưới quá nhiều nước: Rễ bị úng khiến lá vàng và rụng dần từ dưới lên.\n\nBạn có đang tưới nước hàng ngày không? Hãy thử kiểm tra độ ẩm đất nhé.",
    }
  ]);

  const textareaRef = useRef<HTMLTextAreaElement>(null);

  const handleInput = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
      textareaRef.current.style.height = `${Math.min(textareaRef.current.scrollHeight, 400)}px`;
    }
  };

  return (
    <main className="w-full h-[calc(100vh-80px)] flex bg-background">
      {/* Sidebar - History */}
      <motion.aside 
        initial={{ opacity: 0, x: -20 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ duration: 0.5 }}
        className="hidden lg:flex w-64 bg-surface-container-low border-r border-outline-variant/30 flex-col overflow-hidden shrink-0"
      >
        <div className="p-4 border-b border-outline-variant/30 mt-2">
          <button className="w-full bg-primary hover:bg-primary/90 text-white py-2.5 rounded-xl font-semibold text-sm flex items-center justify-center gap-2 transition-all active:scale-[0.98] shadow-sm">
            <span className="material-symbols-outlined text-[18px]">add_comment</span>
            Hội thoại mới
          </button>
        </div>
        <div className="flex-1 overflow-y-auto p-3 flex flex-col gap-1.5 hide-scrollbar">
          <span className="text-[11px] font-bold text-on-surface-variant uppercase tracking-wider px-2 mb-1">Hôm nay</span>
          <button className="text-left px-3 py-2 rounded-xl bg-primary/10 text-primary font-semibold text-[13px] border border-primary/20 line-clamp-1">
            Bàng Singapore bị rụng lá
          </button>
          <button className="text-left px-3 py-2 rounded-xl hover:bg-black/5 text-on-surface-variant hover:text-on-surface font-medium text-[13px] transition-colors line-clamp-1">
            Cách bón phân NPK
          </button>
          
          <span className="text-[11px] font-bold text-on-surface-variant uppercase tracking-wider px-2 mt-4 mb-1">Hôm qua</span>
          <button className="text-left px-3 py-2 rounded-xl hover:bg-black/5 text-on-surface-variant hover:text-on-surface font-medium text-[13px] transition-colors line-clamp-1">
            Lịch tưới nước cho sen đá
          </button>
        </div>
      </motion.aside>

      {/* Main Chat Area */}
      <motion.section 
        initial={{ opacity: 0, opacity: 1 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.5 }}
        className="flex-1 bg-white flex flex-col overflow-hidden relative"
      >
        {/* Header */}
        <header className="h-16 border-b border-outline-variant/30 flex items-center justify-between px-6 bg-white/40 backdrop-blur-md z-10 shrink-0">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-primary-container text-primary flex items-center justify-center shadow-inner">
              <span className="material-symbols-outlined text-[20px]">psychology</span>
            </div>
            <div>
              <h2 className="font-bold text-base text-on-surface leading-tight">Floria AI</h2>
              <p className="text-[12px] text-on-surface-variant flex items-center gap-1.5 mt-0.5">
                <span className="w-1.5 h-1.5 rounded-full bg-primary inline-block"></span>
                Sẵn sàng chẩn đoán
              </p>
            </div>
          </div>
          
          <div className="flex items-center gap-4">
            {/* Model Selector */}
            <div className="relative hidden md:block">
              <select className="appearance-none bg-surface-container rounded-full pl-4 pr-10 py-1.5 text-[13px] font-semibold text-on-surface border border-outline-variant/50 focus:ring-2 focus:ring-primary focus:border-primary outline-none cursor-pointer">
                <option>FloraGPT-4 (Tiêu chuẩn)</option>
                <option>BotaniVision (Nhận diện ảnh)</option>
              </select>
              <span className="material-symbols-outlined absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none text-on-surface-variant text-[18px]">expand_more</span>
            </div>
          </div>
        </header>

        {/* Chat Messages */}
        <div className="flex-1 overflow-y-auto p-4 md:px-8 md:py-6 flex flex-col hide-scrollbar relative">
          <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[600px] h-[600px] bg-primary/5 rounded-full blur-[120px] pointer-events-none"></div>
          
          <div className="w-full max-w-4xl mx-auto flex flex-col gap-6 pb-4">
            {messages.map((msg) => (
              <motion.div 
                initial={{ opacity: 0, y: 5 }}
                animate={{ opacity: 1, y: 0 }}
                key={msg.id} 
                className={`flex w-full ${msg.role === "user" ? "justify-end" : "justify-start gap-3"}`}
              >
                {msg.role === "user" ? (
                  <div className="bg-surface-container-high text-on-surface px-4 py-2.5 rounded-[1.5rem] rounded-tr-sm max-w-[80%] md:max-w-[70%] text-[14px] leading-relaxed">
                    {msg.text.split('\n').map((line, i) => (
                      <span key={i}>
                        {line}
                        {i !== msg.text.split('\n').length - 1 && <br/>}
                      </span>
                    ))}
                  </div>
                ) : (
                  <>
                    <div className="w-8 h-8 shrink-0 rounded-full bg-primary-container text-primary flex items-center justify-center mt-0.5 border border-primary/10">
                      <span className="material-symbols-outlined text-[16px]">psychology</span>
                    </div>
                    <div className="flex-1 max-w-[95%] text-on-surface text-[14px] leading-relaxed pt-1">
                      {msg.text.split('\n').map((line, i) => (
                        <span key={i}>
                          {line}
                          {i !== msg.text.split('\n').length - 1 && <br/>}
                        </span>
                      ))}
                    </div>
                  </>
                )}
              </motion.div>
            ))}
          </div>
        </div>

        {/* Chat Input */}
        <div className="px-4 py-3 bg-white/60 backdrop-blur-xl border-t border-outline-variant/30 shrink-0">
          <div className="relative max-w-4xl mx-auto flex items-end gap-3 bg-white rounded-3xl p-1.5 shadow-[0_2px_12px_rgba(0,0,0,0.04)] border border-surface-variant focus-within:border-primary focus-within:ring-2 focus-within:ring-primary/20 transition-all">
            <button className="p-2.5 text-on-surface-variant hover:text-primary transition-colors rounded-full hover:bg-surface-container shrink-0">
              <span className="material-symbols-outlined text-[20px]">add_photo_alternate</span>
            </button>
            <textarea 
              ref={textareaRef}
              onChange={handleInput}
              placeholder="Nhập câu hỏi về cây trồng của bạn..." 
              className="flex-grow resize-none bg-transparent border-none focus:ring-0 text-[14px] py-2.5 px-1 text-on-surface max-h-[400px] overflow-y-auto [&::-webkit-scrollbar]:hidden [-ms-overflow-style:none] [scrollbar-width:none] outline-none"
              rows={1}
            ></textarea>
            <button className="p-2 bg-primary text-white rounded-full hover:bg-primary/90 transition-colors shadow-md transform active:scale-95 flex items-center justify-center shrink-0 mb-0.5 mr-0.5">
              <span className="material-symbols-outlined text-[16px]">arrow_upward</span>
            </button>
          </div>
          <div className="text-center mt-1.5">
            <span className="text-[11px] text-on-surface-variant">Floria AI có thể cung cấp thông tin không chính xác. Hãy kiểm tra lại.</span>
          </div>
        </div>
      </motion.section>
    </main>
  );
}
