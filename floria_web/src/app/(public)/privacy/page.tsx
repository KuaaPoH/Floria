import Link from "next/link";
import { ShieldCheck } from "lucide-react";
import { PageContainer, PageHeader } from "@/components/layout/PageContainer";
import { Button } from "@/components/ui/button";

const SECTIONS = [
  {
    title: "1. Dữ liệu chúng tôi thu thập",
    body: "Floria lưu trữ thông tin tài khoản (họ tên, email, ảnh đại diện), dữ liệu khu vườn cá nhân (tên vườn, danh sách cây, lịch chăm sóc, nhật ký), địa chỉ giao hàng và lịch sử quét ảnh cây/lá nhằm cá nhân hóa trải nghiệm chăm sóc cây.",
  },
  {
    title: "2. Xử lý hình ảnh AI & quyền riêng tư",
    body: "Ảnh bạn tải lên để nhận diện loài cây hoặc chẩn đoán bệnh lá chỉ được dùng để phân tích mô hình AI và lưu vào lịch sử quét của chính tài khoản bạn. Chúng tôi không bán hay chia sẻ hình ảnh cá nhân cho bên thứ ba vì mục đích quảng cáo.",
  },
  {
    title: "3. Dữ liệu vị trí & thời tiết",
    body: "Tọa độ GPS bạn ghim trong Sổ địa chỉ chỉ được dùng để giao hàng chính xác và truy vấn dự báo thời tiết khu vực qua Open-Meteo API nhằm đưa ra khuyến nghị chăm sóc cây phù hợp.",
  },
  {
    title: "4. Thanh toán & bảo mật",
    body: "Các giao dịch ZaloPay được điều phối qua cổng thanh toán chính thức và máy chủ bảo mật của Floria. Frontend không bao giờ lưu trữ khóa bí mật thanh toán hay thông tin thẻ ngân hàng.",
  },
  {
    title: "5. Quyền kiểm soát của người dùng",
    body: "Bạn có thể chỉnh sửa hồ sơ, xóa ảnh nhật ký, xóa cây hoặc xóa địa chỉ giao hàng bất cứ lúc nào trong phần Hồ sơ cá nhân.",
  },
];

export default function PrivacyPage() {
  return (
    <PageContainer className="max-w-3xl">
      <PageHeader
        eyebrow="Pháp lý"
        title="Chính sách bảo mật"
        description="Cập nhật lần cuối: 11/2026 — Cách Floria bảo vệ dữ liệu khu vườn và tài khoản của bạn."
      />
      <div className="space-y-4">
        {SECTIONS.map((s) => (
          <section key={s.title} className="rounded-3xl border bg-card p-6 shadow-soft">
            <h2 className="flex items-center gap-2 text-lg font-semibold text-forest dark:text-foreground">
              <ShieldCheck className="size-4 text-leaf" /> {s.title}
            </h2>
            <p className="mt-2 text-sm leading-relaxed text-muted-foreground">{s.body}</p>
          </section>
        ))}
      </div>
      <div className="mt-8 flex gap-3">
        <Button asChild variant="outline"><Link href="/terms">Xem Điều khoản sử dụng</Link></Button>
        <Button asChild variant="ghost"><Link href="/">Về trang chủ</Link></Button>
      </div>
    </PageContainer>
  );
}
