import type { Metadata } from "next";
import { Plus_Jakarta_Sans } from "next/font/google";
import Link from "next/link";
import TopNavBar from "@/components/TopNavBar";
import "./globals.css";

const plusJakartaSans = Plus_Jakarta_Sans({
  variable: "--font-plus-jakarta-sans",
  subsets: ["latin", "vietnamese"],
});

export const metadata: Metadata = {
  title: "Floria - Trang chủ & Khu vườn số",
  description: "Dự án nhận diện bệnh cây trồng AI",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="vi" className={`${plusJakartaSans.variable} antialiased light`}>
      <head>
        <link
          href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&display=swap"
          rel="stylesheet"
        />
      </head>
      <body className="bg-background text-on-background font-body-md text-body-md min-h-screen pt-20 flex flex-col">
        {/* TopNavBar */}
        <TopNavBar />
        {children}

        {/* Footer */}
        <footer className="w-full py-12 bg-surface-container border-t border-outline-variant mt-auto">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-gutter px-margin max-w-max-width mx-auto">
            <div className="flex flex-col gap-4">
              <span className="font-headline-sm text-headline-sm font-bold text-primary">
                Floria
              </span>
              <p className="font-body-md text-body-md text-on-surface-variant max-w-xs">
                Giải pháp chăm sóc cây cảnh thông minh bằng AI, mang đến không gian xanh tươi mát cho ngôi nhà của bạn.
              </p>
            </div>
            <div className="flex gap-8 md:col-span-2 md:justify-end">
              <div className="flex flex-col gap-4">
                <h4 className="font-label-md text-label-md text-on-surface font-bold">Liên kết nhanh</h4>
                <div className="flex flex-col gap-2">
                  <a className="text-on-surface-variant hover:text-secondary transition-colors duration-300 font-body-md text-body-md" href="#">Liên hệ</a>
                  <a className="text-on-surface-variant hover:text-secondary transition-colors duration-300 font-body-md text-body-md" href="#">Điều khoản</a>
                  <a className="text-on-surface-variant hover:text-secondary transition-colors duration-300 font-body-md text-body-md" href="#">Bảo mật</a>
                </div>
              </div>
              <div className="flex flex-col gap-4">
                <h4 className="font-label-md text-label-md text-on-surface font-bold">Kết nối với chúng tôi</h4>
                <div className="flex flex-col gap-2">
                  <a className="text-on-surface-variant hover:text-secondary transition-colors duration-300 font-body-md text-body-md" href="#">Facebook</a>
                  <a className="text-on-surface-variant hover:text-secondary transition-colors duration-300 font-body-md text-body-md" href="#">Instagram</a>
                </div>
              </div>
            </div>
          </div>
          <div className="px-margin max-w-max-width mx-auto mt-12 pt-6 border-t border-outline-variant/30 text-center md:text-left">
            <p className="font-body-md text-body-md text-on-surface-variant">© 2024 Floria. All rights reserved.</p>
          </div>
        </footer>
      </body>
    </html>
  );
}
