import type { AdminAccount, AuditLog, BackupRecord, ServiceHealth } from "@/types";
import { daysAgo } from "@/lib/id";

export function seedAdmins(): AdminAccount[] {
  return [
    { id: "adm_1", name: "Phạm Minh Đức", email: "duc.pham@floria.vn", role: "super_admin", status: "active", lastLogin: daysAgo(0, 8), twoFA: true },
    { id: "adm_2", name: "TS. Nguyễn Thảo", email: "thao.nguyen@floria.vn", role: "botanist", status: "active", lastLogin: daysAgo(0, 10), twoFA: true },
    { id: "adm_3", name: "Lý Bảo Châu", email: "chau.ly@floria.vn", role: "botanist", status: "active", lastLogin: daysAgo(3, 14), twoFA: false },
    { id: "adm_4", name: "Ngô Thanh Tú", email: "tu.ngo@floria.vn", role: "operations", status: "active", lastLogin: daysAgo(0, 9), twoFA: true },
    { id: "adm_5", name: "Hồ Gia Linh", email: "linh.ho@floria.vn", role: "operations", status: "active", lastLogin: daysAgo(1, 16), twoFA: false },
    { id: "adm_6", name: "Trịnh Văn Nam", email: "nam.trinh@floria.vn", role: "operations", status: "disabled", lastLogin: daysAgo(48, 11), twoFA: false },
  ];
}

export function seedAuditLogs(): AuditLog[] {
  const rows: Omit<AuditLog, "id" | "at" | "ip">[] = [
    { admin: "Phạm Minh Đức", role: "super_admin", action: "Cập nhật giá", target: "Sản phẩm · Chậu gốm men mờ Sage 16cm", before: "185.000 ₫", after: "159.000 ₫" },
    { admin: "TS. Nguyễn Thảo", role: "botanist", action: "Duyệt nhãn AI", target: "Active Learning · lbl_2014", before: "pending", after: "approved · Trầu bà vàng" },
    { admin: "Ngô Thanh Tú", role: "operations", action: "Đổi trạng thái đơn", target: "Đơn hàng · FL26110407", before: "confirmed", after: "shipping" },
    { admin: "Phạm Minh Đức", role: "super_admin", action: "Cập nhật cấu hình AI", target: "AI Config · confidenceThreshold", before: "0.60", after: "0.65" },
    { admin: "Hồ Gia Linh", role: "operations", action: "Xuất bản cấu hình", target: "Remote UI · v12", before: "v11", after: "v12" },
    { admin: "TS. Nguyễn Thảo", role: "botanist", action: "Cập nhật từ điển", target: "Cây · Lan hồ điệp", before: "watering: 2 lần/tuần", after: "watering: 1 lần/tuần" },
    { admin: "Ngô Thanh Tú", role: "operations", action: "Ẩn đánh giá", target: "Đánh giá · rvw_8", before: "approved", after: "hidden" },
    { admin: "Phạm Minh Đức", role: "super_admin", action: "Khoá tài khoản", target: "Người dùng · usr_1006", before: "active", after: "locked" },
    { admin: "Phạm Minh Đức", role: "super_admin", action: "Rollout mô hình", target: "AI Model · Disease Detection 1.6.1", before: "50%", after: "80%" },
    { admin: "Hồ Gia Linh", role: "operations", action: "Gửi chiến dịch", target: "Push · Nhắc tưới cuối tuần", before: "scheduled", after: "sent" },
  ];
  return rows.map((r, i) => ({ ...r, id: `aud_${i + 1}`, at: daysAgo(Math.floor(i / 2), 15 - i), ip: `10.0.${i % 4}.${20 + i}` }));
}

export function seedBackups(): BackupRecord[] {
  return [
    { id: "bk_1", name: "firestore-auto-2026-11-15", type: "auto", size: "2,41 GB", at: daysAgo(0, 2), status: "success", scope: "Firestore + Storage metadata" },
    { id: "bk_2", name: "firestore-auto-2026-11-14", type: "auto", size: "2,39 GB", at: daysAgo(1, 2), status: "success", scope: "Firestore + Storage metadata" },
    { id: "bk_3", name: "pre-release-ai-2.4.0", type: "manual", size: "880 MB", at: daysAgo(6, 15), status: "success", scope: "AI models + config" },
    { id: "bk_4", name: "firestore-auto-2026-11-08", type: "auto", size: "—", at: daysAgo(7, 2), status: "failed", scope: "Firestore + Storage metadata" },
  ];
}

export function seedServices(): ServiceHealth[] {
  const now = new Date().toISOString();
  return [
    { id: "svc_api", name: "Spring Boot API", description: "REST API chính", status: "operational", latencyMs: 84, uptime: 99.98, checkedAt: now },
    { id: "svc_ai", name: "Python AI Engine (ONNX)", description: "Suy luận mô hình", status: "degraded", latencyMs: 412, uptime: 99.42, checkedAt: now },
    { id: "svc_fs", name: "Firestore", description: "Cơ sở dữ liệu", status: "operational", latencyMs: 46, uptime: 99.99, checkedAt: now },
    { id: "svc_storage", name: "Firebase Storage", description: "Lưu trữ ảnh", status: "operational", latencyMs: 112, uptime: 99.95, checkedAt: now },
    { id: "svc_zalopay", name: "ZaloPay", description: "Cổng thanh toán (sandbox)", status: "operational", latencyMs: 238, uptime: 99.7, checkedAt: now },
  ];
}
