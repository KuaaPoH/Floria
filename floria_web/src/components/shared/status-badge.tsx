import { Badge, type BadgeProps } from "@/components/ui/badge";

type Tone = NonNullable<BadgeProps["variant"]>;

const MAP: Record<string, [string, Tone]> = {
  // accounts
  active: ["Hoạt động", "success"],
  locked: ["Đã khoá", "danger"],
  pending: ["Chờ xử lý", "warning"],
  disabled: ["Vô hiệu", "neutral"],
  // review / moderation
  approved: ["Đã duyệt", "success"],
  rejected: ["Từ chối", "danger"],
  hidden: ["Đã ẩn", "neutral"],
  reviewed: ["Đã xem xét", "success"],
  dismissed: ["Bỏ qua", "neutral"],
  // content
  published: ["Đã xuất bản", "success"],
  draft: ["Bản nháp", "neutral"],
  scheduled: ["Đã lên lịch", "info"],
  sent: ["Đã gửi", "success"],
  failed: ["Thất bại", "danger"],
  running: ["Đang chạy", "info"],
  success: ["Thành công", "success"],
  // orders
  confirmed: ["Đã xác nhận", "info"],
  shipping: ["Đang giao", "brand"],
  delivered: ["Đã giao", "success"],
  completed: ["Đã giao", "success"],
  cancelled: ["Đã huỷ", "danger"],
  unpaid: ["Chưa thanh toán", "warning"],
  paid: ["Đã thanh toán", "success"],
  refund_requested: ["Yêu cầu hoàn tiền", "warning"],
  refunded: ["Đã hoàn tiền", "neutral"],
  // tickets
  open: ["Mới", "info"],
  in_progress: ["Đang xử lý", "warning"],
  resolved: ["Đã giải quyết", "success"],
  // health
  operational: ["Hoạt động", "success"],
  degraded: ["Suy giảm", "warning"],
  offline: ["Ngừng", "danger"],
  // severity / priority
  low: ["Thấp", "info"],
  medium: ["Trung bình", "warning"],
  high: ["Cao", "danger"],
  critical: ["Nghiêm trọng", "danger"],
  inactive: ["Tạm tắt", "neutral"],
  visible: ["Đang hiển thị", "success"],
};

export function StatusBadge({ status, label }: { status: string; label?: string }) {
  const [text, tone] = MAP[status] ?? [status, "neutral" as Tone];
  return (
    <Badge variant={tone}>
      <span className="size-1.5 rounded-full bg-current opacity-80" />
      {label ?? text}
    </Badge>
  );
}

export const statusLabel = (status: string) => MAP[status]?.[0] ?? status;
