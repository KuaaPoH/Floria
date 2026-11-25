import Link from "next/link";
import { FileText } from "lucide-react";
import { PageContainer, PageHeader } from "@/components/layout/PageContainer";
import { Button } from "@/components/ui/button";

const TERMS = [
  {
    title: "1. Phạm vi dịch vụ Floria",
    body: "Floria cung cấp công cụ nhận diện loài cây bằng AI, chẩn đoán bệnh lá, quản lý lịch chăm sóc cây, trợ lý tư vấn Floria và cửa hàng vật tư làm vườn.",
  },
  {
    title: "2. Khuyến nghị miễn trừ trách nhiệm AI",
    body: "Kết quả nhận diện loài cây, chẩn đoán bệnh lá và gợi ý sản phẩm từ AI chỉ mang tính tham khảo hỗ trợ quyết định. Việc cập nhật bệnh án hay sử dụng chế phẩm chăm sóc luôn cần sự xác nhận chủ động của người trồng.",
  },
  {
    title: "3. Quy định tài khoản",
    body: "Người dùng chịu trách nhiệm bảo mật thông tin đăng nhập, cung cấp thông tin địa chỉ nhận hàng chính xác và không sử dụng hệ thống cho nội dung vi phạm pháp luật.",
  },
  {
    title: "4. Đặt hàng & Thanh toán",
    body: "Đơn hàng COD và ZaloPay tuân theo quy trình xác nhận trạng thái từ hệ thống. Bạn chỉ có thể hủy đơn khi đơn hàng đang ở trạng thái Chờ xác nhận và chỉ đánh giá sản phẩm sau khi đơn đã được giao.",
  },
];

export default function TermsPage() {
  return (
    <PageContainer className="max-w-3xl">
      <PageHeader
        eyebrow="Pháp lý"
        title="Điều khoản sử dụng"
        description="Cập nhật lần cuối: 11/2026 — Quy định khi sử dụng nền tảng Floria."
      />
      <div className="space-y-4">
        {TERMS.map((t) => (
          <section key={t.title} className="rounded-3xl border bg-card p-6 shadow-soft">
            <h2 className="flex items-center gap-2 text-lg font-semibold text-forest dark:text-foreground">
              <FileText className="size-4 text-leaf" /> {t.title}
            </h2>
            <p className="mt-2 text-sm leading-relaxed text-muted-foreground">{t.body}</p>
          </section>
        ))}
      </div>
      <div className="mt-8 flex gap-3">
        <Button asChild variant="outline"><Link href="/privacy">Xem Chính sách bảo mật</Link></Button>
        <Button asChild variant="ghost"><Link href="/">Về trang chủ</Link></Button>
      </div>
    </PageContainer>
  );
}
