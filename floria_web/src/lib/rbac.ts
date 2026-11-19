import type { RoleId } from "@/types";

export const ROLES: { id: RoleId; name: string; description: string }[] = [
  { id: "super_admin", name: "Super Admin", description: "Toàn quyền hệ thống, cấu hình AI và phân quyền." },
  { id: "botanist", name: "Botanist", description: "Quản lý dữ liệu thực vật, duyệt nhãn AI, nội dung cẩm nang." },
  { id: "operations", name: "Vận hành / CSKH", description: "Đơn hàng, sản phẩm, kho, đánh giá và hỗ trợ khách hàng." },
];

export const ACTIONS = ["view", "create", "edit", "delete", "approve", "publish", "configure"] as const;
export type PermAction = (typeof ACTIONS)[number];

export const ACTION_LABELS: Record<PermAction, string> = {
  view: "Xem",
  create: "Tạo",
  edit: "Sửa",
  delete: "Xoá",
  approve: "Duyệt",
  publish: "Xuất bản",
  configure: "Cấu hình",
};

export const MODULES = [
  { id: "overview", name: "Tổng quan" },
  { id: "users", name: "Người dùng" },
  { id: "ai_lab", name: "AI Lab" },
  { id: "assistant", name: "Floria Assistant" },
  { id: "botanical", name: "Từ điển thực vật" },
  { id: "orders", name: "Đơn hàng" },
  { id: "products", name: "Sản phẩm & Kho" },
  { id: "reviews", name: "Đánh giá" },
  { id: "content", name: "Nội dung & Banner" },
  { id: "remote_config", name: "Remote UI Config" },
  { id: "notifications", name: "Thông báo đẩy" },
  { id: "support", name: "Hỗ trợ khách hàng" },
  { id: "system", name: "Cài đặt hệ thống" },
] as const;
export type ModuleId = (typeof MODULES)[number]["id"];

export type PermissionMatrix = Record<RoleId, Record<ModuleId, PermAction[]>>;

const ALL = [...ACTIONS];
const allModules = (acts: PermAction[]) =>
  Object.fromEntries(MODULES.map((m) => [m.id, [...acts]])) as Record<ModuleId, PermAction[]>;

export const DEFAULT_PERMISSIONS: PermissionMatrix = {
  super_admin: allModules(ALL),
  botanist: {
    ...allModules([]),
    overview: ["view"],
    ai_lab: ["view", "edit", "approve"],
    assistant: ["view", "edit"],
    botanical: ["view", "create", "edit", "delete", "approve", "publish"],
    content: ["view", "create", "edit", "publish"],
    support: ["view"],
  },
  operations: {
    ...allModules([]),
    overview: ["view"],
    users: ["view", "edit"],
    orders: ["view", "edit", "approve"],
    products: ["view", "create", "edit"],
    reviews: ["view", "approve", "edit"],
    notifications: ["view", "create"],
    support: ["view", "edit"],
    content: ["view"],
  },
};

export function can(matrix: PermissionMatrix, role: RoleId, module: ModuleId, action: PermAction = "view") {
  return matrix[role]?.[module]?.includes(action) ?? false;
}
