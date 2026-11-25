"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { LifeBuoy, MessageCircle, Search } from "lucide-react";
import { PageContainer, PageHeader } from "@/components/layout/PageContainer";
import { EmptyState } from "@/components/layout/states";
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from "@/components/ui/accordion";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { ProfileShell } from "@/features/profile/ProfileShell";
import { useSupportArticles } from "@/hooks/queries";
import { cn } from "@/lib/utils";
import { useAuth } from "@/stores/auth";

const FAQ_GROUPS = [
  {
    id: "account",
    label: "Tài khoản",
    items: [
      { q: "Làm sao để đổi mật khẩu tài khoản Floria?", a: "Bạn vào Hồ sơ → Cài đặt → Bảo mật và nhấn 'Gửi email đặt lại mật khẩu'. Hoặc chọn 'Quên mật khẩu' ở màn hình đăng nhập." },
      { q: "Tôi có thể chọn avatar thực vật có sẵn không?", a: "Có. Trong trang Hồ sơ cá nhân, bạn có thể chọn 1 trong 6 avatar thực vật đặc trưng của Floria hoặc tải ảnh cá nhân của bạn lên." },
    ],
  },
  {
    id: "discovery",
    label: "Nhận diện cây",
    items: [
      { q: "Chụp ảnh thế nào để AI nhận diện chính xác nhất?", a: "Chụp rõ toàn cây hoặc tập trung vào lá và thân, đặt cây ở giữa khung hình, ánh sáng tự nhiên và không có vật che khuất." },
      { q: "Vì sao ảnh không hợp lệ bị ẩn nút Lưu vào vườn?", a: "Khi bộ lọc CLIP phát hiện ảnh không phải thực vật, Floria tự động ẩn toàn bộ hành động lưu cây để đảm bảo dữ liệu khu vườn chính xác." },
    ],
  },
  {
    id: "care",
    label: "Chăm sóc cây",
    items: [
      { q: "Ba lịch chăm sóc của mỗi cây hoạt động ra sao?", a: "Mỗi cây có 3 lịch độc lập: Tưới nước, Bón phân và Kiểm tra sâu bệnh & lau lá. Hoàn thành hoặc chỉnh sửa chu kỳ của một lịch không ảnh hưởng đến hai lịch còn lại." },
      { q: "Thứ tự ưu tiên trạng thái cây là gì?", a: "Floria tính trạng thái theo thứ tự: Đang có bệnh → Cần tưới nước → Cần bón phân → Cần kiểm tra → Khỏe mạnh." },
    ],
  },
  {
    id: "assistant",
    label: "Trợ lý AI",
    items: [
      { q: "Trợ lý Floria trả lời những chủ đề nào?", a: "Floria là bác sĩ cây trồng chuyên tư vấn thực vật, cách trồng, chăm sóc, sâu bệnh, môi trường cây và làm vườn." },
      { q: "Thẻ đề xuất lịch chăm sóc trong khung chat dùng như thế nào?", a: "Khi Trợ lý Floria gợi ý lịch chăm sóc mới, bạn chỉ cần chọn đúng cây trong vườn và nhấn 'Áp dụng vào cây'." },
    ],
  },
  {
    id: "orders",
    label: "Đơn hàng",
    items: [
      { q: "Khi nào tôi có thể hủy đơn hàng?", a: "Bạn có thể hủy đơn khi đơn hàng đang ở trạng thái 'Chờ xác nhận'. Khi đơn đã chuyển sang 'Đang giao', nút hủy sẽ không còn khả dụng." },
      { q: "Khi nào tôi có thể đánh giá sản phẩm?", a: "Chỉ những đơn hàng ở trạng thái 'Đã giao' mới hiển thị nút đánh giá (1–5 sao kèm nhận xét và ảnh thực tế)." },
    ],
  },
  {
    id: "payment",
    label: "Thanh toán",
    items: [
      { q: "Floria hỗ trợ những phương thức thanh toán nào?", a: "Hiện tại Floria hỗ trợ thanh toán khi nhận hàng (COD) và cổng thanh toán trực tuyến ZaloPay." },
      { q: "Nếu đặt hàng chỉ chọn một phần giỏ hàng thì sao?", a: "Sau khi đặt hàng thành công, Floria chỉ xóa các sản phẩm bạn đã chọn thanh toán; những sản phẩm chưa chọn vẫn được giữ nguyên trong giỏ." },
    ],
  },
  {
    id: "security",
    label: "Bảo mật",
    items: [
      { q: "Dữ liệu vườn và ảnh của tôi có được bảo vệ không?", a: "Tài khoản và dữ liệu cá nhân của bạn được tách biệt theo từng UID. Hình ảnh quét AI và tọa độ địa chỉ chỉ phục vụ trải nghiệm của chính bạn." },
    ],
  },
];

function SupportBody() {
  const [q, setQ] = useState("");
  const [group, setGroup] = useState("all");
  const { data: remoteArticles = [] } = useSupportArticles();

  const groups = useMemo(() => {
    if (remoteArticles.length > 0) {
      const map = new Map<string, { id: string; label: string; items: { q: string; a: string }[] }>();
      for (const art of remoteArticles) {
        const cur = map.get(art.category) ?? { id: art.category, label: art.categoryVi, items: [] };
        cur.items.push({ q: art.questionVi, a: art.answerVi });
        map.set(art.category, cur);
      }
      return [...map.values()];
    }
    return FAQ_GROUPS;
  }, [remoteArticles]);

  const filtered = useMemo(() => {
    const needle = q.trim().toLowerCase();
    return groups
      .filter((g) => group === "all" || g.id === group)
      .map((g) => ({
        ...g,
        items: g.items.filter((it) => !needle || it.q.toLowerCase().includes(needle) || it.a.toLowerCase().includes(needle)),
      }))
      .filter((g) => g.items.length > 0);
  }, [q, group, groups]);

  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow="Hỗ trợ"
        title="Trung tâm hỗ trợ & FAQ"
        description="Giải đáp nhanh về tài khoản, nhận diện AI, lịch chăm sóc cây, đơn hàng và bảo mật."
        className="mb-2"
      />

      <div className="relative max-w-md">
        <Search className="absolute left-3.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
        <Input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Tìm câu hỏi thường gặp…" className="pl-10" />
      </div>

      <div className="scrollbar-none -mx-1 flex gap-2 overflow-x-auto px-1 pb-1">
        <button
          onClick={() => setGroup("all")}
          className={cn("shrink-0 rounded-full border px-3.5 py-1.5 text-sm font-medium transition-colors", group === "all" ? "border-forest bg-forest text-forest-foreground" : "bg-card hover:border-leaf/50")}
        >
          Tất cả ({groups.length} nhóm)
        </button>
        {groups.map((g) => (
          <button
            key={g.id}
            onClick={() => setGroup(g.id)}
            className={cn("shrink-0 rounded-full border px-3.5 py-1.5 text-sm font-medium transition-colors", group === g.id ? "border-forest bg-forest text-forest-foreground" : "bg-card hover:border-leaf/50")}
          >
            {g.label}
          </button>
        ))}
      </div>

      {filtered.length === 0 ? (
        <EmptyState icon={<LifeBuoy />} title="Không tìm thấy câu hỏi phù hợp" description="Thử đổi từ khóa hoặc hỏi trực tiếp Trợ lý Floria." action={<Button variant="outline" onClick={() => { setQ(""); setGroup("all"); }}>Xóa bộ lọc</Button>} />
      ) : (
        <div className="space-y-5">
          {filtered.map((g) => (
            <section key={g.id} className="rounded-3xl border bg-card p-5 shadow-soft">
              <div className="mb-3 flex items-center gap-2">
                <Badge variant="brand">{g.label}</Badge>
                <span className="text-xs text-muted-foreground">{g.items.length} câu hỏi</span>
              </div>
              <Accordion type="multiple" className="w-full">
                {g.items.map((item, idx) => (
                  <AccordionItem key={item.q} value={`${g.id}-${idx}`}>
                    <AccordionTrigger className="text-left text-sm font-semibold hover:no-underline">{item.q}</AccordionTrigger>
                    <AccordionContent className="text-sm leading-relaxed text-muted-foreground">{item.a}</AccordionContent>
                  </AccordionItem>
                ))}
              </Accordion>
            </section>
          ))}
        </div>
      )}

      <div className="flex flex-wrap items-center justify-between gap-4 rounded-3xl bg-mint/50 p-5">
        <div>
          <p className="font-semibold">Vẫn cần tư vấn thêm?</p>
          <p className="text-sm text-muted-foreground">Bác sĩ cây trồng Floria luôn sẵn sàng giải đáp 24/7.</p>
        </div>
        <Button asChild><Link href="/assistant"><MessageCircle /> Trò chuyện với Floria</Link></Button>
      </div>
    </div>
  );
}

export default function SupportPage() {
  const authed = useAuth((s) => s.status === "authenticated");
  if (authed) {
    return (
      <ProfileShell>
        <SupportBody />
      </ProfileShell>
    );
  }
  return (
    <PageContainer className="max-w-4xl">
      <SupportBody />
    </PageContainer>
  );
}
