"use client";

import Image from "next/image";
import { motion } from "motion/react";

const products = [
  {
    id: 1,
    name: "Phân bón hữu cơ NPK",
    category: "Dinh dưỡng",
    price: "120.000đ",
    image: "https://lh3.googleusercontent.com/aida-public/AB6AXuBKSPO51JX2wODk_N2gyq9OM2tR0QjskM42koRXGjOlRy6zxKjHY4gCv4z-ItZeFyjaJSYBCll9iAO919vaE8URseMRRRK_SSiM4MQaVKjxeKoya3vKEIPWs7YBsByYM3eyVAROUJgGjc9Qw0n8F4BfznIGFBlvTLl-yUFfQbvFiAxlUdRbUrjj4wdi-LNhwaSccUw5jEagQJ9XvpX8QzGdI-5CIQnvWIzIZ6wabPEgf8v5F35bK9vmfiO8ZWGVH_Nv34BVfrgmm7o",
    badge: "Bán chạy"
  },
  {
    id: 2,
    name: "Bình xịt phun sương 2L",
    category: "Dụng cụ",
    price: "85.000đ",
    image: "https://lh3.googleusercontent.com/aida-public/AB6AXuDJ71GFo9Hnsj7gQ8gWqRnKo5-bW0IhON8i7M5e_QufveNIkXpIQvT-I5RWXSJf-9ANgeIKJx4GVgtmyh4jVWcVR0kV-5ywEWTbPHm3ih4GV_lv3Wk8_130L4q_ceIaaS72LxMbg1bzbMGG40LE2vRm1FNtgJkvSCrck5D9nOYLC5mU_HhHrnMDe_XDtB_o_LoRUnnnriN8uRsvQMndnCjqGVomb-u1yM4VuZ10P0Z6wb5XxIwQBQCXKvvFWvACMhEX8XXhD0i-Wck",
  },
  {
    id: 3,
    name: "Bộ 3 dụng cụ làm vườn mini",
    category: "Dụng cụ",
    price: "150.000đ",
    image: "https://lh3.googleusercontent.com/aida/AP1WRLuRARSgnzFowzmnBzIsItc1sM0H3F2I2wUAg4dknFiQg_5J_0PuayAGF5NybhF3Qs8d6vN-1GyQ3zvLcxuy72Xtiwzr0hBIa8RJWOsXnJjfJER5ARCPwZwPX1VuFKjLl2w5TYSLsqdj1YhquKHt_IeyOEIoq7iUAySzfoFVAO8IbKcQPVYX_Is1TnB4O0nnsXYaP4uhalSw08kjF6OnQ6Oj6_16CcwyZJLycU3GA3ItW4l6RB0f6QYryQ",
  },
  {
    id: 4,
    name: "Thuốc trừ sâu sinh học Neem",
    category: "Bảo vệ cây",
    price: "95.000đ",
    image: "https://lh3.googleusercontent.com/aida-public/AB6AXuBaiaK79hwEiHBLniGMplVbRdz3ZtVH3yhovsCOssk_Og3qOA7z6mu_SASZGHEiizX2rCDpQdowSCfK0gP0f7BMSkiv_IN0fDxCL-7OmO7xRVtbygYm-Bs6XUl7bUd3vq7-nm-hcax2FhgX6j0YQ_l2FEKLjIaCwDviQwUGNxUvhzWB2TLl4auKFgksT2-_wEVS9nOdbsx2kE9PN2cHe91zmTC85ZjPISHNiCeEVSJxwn4QhUzZ44YsV7vG-7THPKDl_32s7GT1msE",
    badge: "Mới"
  }
];

export default function ShopPage() {
  const container = {
    hidden: { opacity: 0 },
    show: {
      opacity: 1,
      transition: { staggerChildren: 0.1 },
    },
  };

  const item = {
    hidden: { opacity: 0, y: 20 },
    show: { opacity: 1, y: 0, transition: { type: "spring", stiffness: 100, damping: 20 } },
  };

  return (
    <main className="max-w-max-width mx-auto px-margin py-8 flex flex-col gap-10">
      {/* Hero Section */}
      <motion.section 
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
        className="glass-panel relative flex flex-col md:flex-row items-center justify-between overflow-hidden rounded-[2rem] py-10 px-10 border border-white/60 shadow-[inset_0_1px_0_rgba(255,255,255,0.6),0_8px_32px_rgba(0,109,53,0.05)] bg-gradient-to-r from-primary/5 to-transparent"
      >
        <div className="absolute top-0 right-0 w-[400px] h-[400px] bg-primary/10 rounded-full blur-[100px] pointer-events-none"></div>
        <div className="text-left relative z-10">
          <h1 className="font-headline-lg text-3xl md:text-4xl text-on-surface tracking-tight leading-tight max-w-xl font-extrabold">
            Chăm sóc cây <br/>
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary to-[#00a859]">chưa bao giờ dễ dàng đến thế</span>
          </h1>
          <p className="font-body-md text-on-surface-variant max-w-[50ch] leading-relaxed mt-4">
            Tuyển chọn những công cụ, phân bón và sản phẩm chăm sóc tốt nhất.
          </p>
        </div>
        <div className="mt-6 md:mt-0 relative z-10 shrink-0">
          <button className="bg-primary hover:bg-primary/90 text-white px-6 py-3 rounded-full font-label-md flex items-center gap-2 transition-all duration-300 shadow-sm hover:shadow-md active:scale-[0.98]">
            <span className="material-symbols-outlined text-[18px]">shopping_bag</span>
            Khám phá
          </button>
        </div>
      </motion.section>

      {/* Categories */}
      <div className="flex gap-4 overflow-x-auto pb-4 hide-scrollbar">
        {["Tất cả", "Dụng cụ", "Dinh dưỡng", "Bảo vệ cây", "Chậu trồng", "Đất & Giá thể"].map((cat, i) => (
          <button key={cat} className={`px-6 py-2.5 rounded-full font-semibold text-sm whitespace-nowrap transition-colors border ${i === 0 ? "bg-on-surface text-white border-on-surface" : "bg-white border-outline-variant/50 text-on-surface-variant hover:border-primary hover:text-primary"}`}>
            {cat}
          </button>
        ))}
      </div>

      {/* Product Grid */}
      <motion.section 
        variants={container}
        initial="hidden"
        animate="show"
        className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6"
      >
        {products.map((product) => (
          <motion.div 
            key={product.id}
            variants={item}
            className="group glass-panel rounded-[1.5rem] p-4 hover:-translate-y-2 hover:shadow-[0_20px_40px_rgba(0,109,53,0.08)] transition-all duration-500 border border-white/50 cursor-pointer flex flex-col"
          >
            <div className="w-full aspect-square rounded-[1rem] overflow-hidden relative bg-surface-container-low mb-4">
              {product.badge && (
                <div className="absolute top-3 left-3 z-10 bg-white/90 backdrop-blur-md text-on-surface text-[11px] font-bold uppercase tracking-wider px-3 py-1.5 rounded-full shadow-sm">
                  {product.badge}
                </div>
              )}
              <Image 
                src={product.image}
                alt={product.name}
                fill
                className="object-cover group-hover:scale-110 transition-transform duration-700 ease-out"
                unoptimized
              />
              <div className="absolute bottom-3 right-3 translate-y-10 opacity-0 group-hover:translate-y-0 group-hover:opacity-100 transition-all duration-300">
                <button className="w-10 h-10 bg-primary text-white rounded-full flex items-center justify-center shadow-lg hover:scale-110 active:scale-95 transition-transform">
                  <span className="material-symbols-outlined text-[20px]">add_shopping_cart</span>
                </button>
              </div>
            </div>
            <div className="flex flex-col flex-1">
              <span className="text-[12px] font-semibold text-primary uppercase tracking-wider mb-1">{product.category}</span>
              <h3 className="font-bold text-lg text-on-surface line-clamp-2 leading-snug group-hover:text-primary transition-colors">{product.name}</h3>
              <div className="mt-auto pt-4 flex items-center justify-between">
                <span className="font-extrabold text-xl text-on-surface">{product.price}</span>
              </div>
            </div>
          </motion.div>
        ))}
      </motion.section>
    </main>
  );
}
