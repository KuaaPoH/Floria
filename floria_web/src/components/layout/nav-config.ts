import type { LucideIcon } from "lucide-react";
import {
  Activity,
  BellRing,
  BookOpen,
  Bot,
  BrainCircuit,
  FileClock,
  Flower2,
  LayoutDashboard,
  LayoutTemplate,
  Leaf,
  LifeBuoy,
  Menu,
  MessageSquareHeart,
  Microscope,
  Package,
  ShieldCheck,
  ShoppingBag,
  Sparkles,
  Star,
  Tags,
  Users,
  Warehouse,
  Image as ImageIcon,
  Settings2,
  Store,
  Megaphone,
  Workflow,
} from "lucide-react";
import type { ModuleId } from "@/lib/rbac";

export type AppPath = string;

export type BadgeKey = "labelReviews" | "pendingOrders" | "pendingReviews";

export interface NavLeaf {
  title: string;
  to: AppPath;
  icon: LucideIcon;
  module: ModuleId;
  badge?: BadgeKey;
}

export interface NavItem {
  title: string;
  icon: LucideIcon;
  module?: ModuleId;
  to?: AppPath;
  badge?: BadgeKey;
  children?: NavLeaf[];
}

export interface NavGroup {
  label: string;
  items: NavItem[];
}

export const NAV: NavGroup[] = [
  {
    label: "Workspace",
    items: [
      { title: "Tổng quan", to: "/admin/overview", icon: LayoutDashboard, module: "overview" },
      { title: "Người dùng", to: "/admin/users", icon: Users, module: "users" },
      {
        title: "AI & Trợ lý",
        icon: BrainCircuit,
        children: [
          { title: "AI Lab", to: "/admin/ai-lab", icon: Sparkles, module: "ai_lab", badge: "labelReviews" },
          { title: "Floria Assistant", to: "/admin/assistant", icon: Bot, module: "assistant" },
        ],
      },
      {
        title: "Dữ liệu thực vật",
        icon: Leaf,
        children: [
          { title: "Từ điển cây", to: "/admin/plants", icon: Flower2, module: "botanical" },
          { title: "Từ điển bệnh", to: "/admin/diseases", icon: Microscope, module: "botanical" },
          { title: "Ánh xạ nhãn AI", to: "/admin/label-mapping", icon: Workflow, module: "botanical" },
        ],
      },
      {
        title: "Thương mại",
        icon: Store,
        children: [
          { title: "Đơn hàng", to: "/admin/orders", icon: ShoppingBag, module: "orders", badge: "pendingOrders" },
          { title: "Sản phẩm", to: "/admin/products", icon: Package, module: "products" },
          { title: "Kho hàng", to: "/admin/inventory", icon: Warehouse, module: "products" },
          { title: "Đánh giá", to: "/admin/reviews", icon: Star, module: "reviews", badge: "pendingReviews" },
        ],
      },
      {
        title: "Nội dung & Trải nghiệm",
        icon: LayoutTemplate,
        children: [
          { title: "Cẩm nang", to: "/admin/handbook", icon: BookOpen, module: "content" },
          { title: "Banner trang chủ", to: "/admin/banners", icon: ImageIcon, module: "content" },
        ],
      },
      {
        title: "Truyền thông",
        icon: Megaphone,
        children: [
          { title: "Thông báo đẩy", to: "/admin/notifications", icon: BellRing, module: "notifications" },
          { title: "Trung tâm hỗ trợ", to: "/admin/support", icon: LifeBuoy, module: "support" },
        ],
      },
    ],
  },
  {
    label: "Hệ thống",
    items: [
      {
        title: "Cài đặt hệ thống",
        icon: Settings2,
        children: [
          { title: "Quản trị & Phân quyền", to: "/admin/settings/roles", icon: ShieldCheck, module: "system" },
          { title: "Tình trạng hệ thống", to: "/admin/settings/health", icon: Activity, module: "system" },
          { title: "Nhật ký hoạt động", to: "/admin/settings/audit", icon: FileClock, module: "system" },
          { title: "Quản lý Menu", to: "/admin/settings/menus", icon: Menu, module: "system" },
        ],
      },
    ],
  },
];

/** Flat list of every navigable leaf, used by breadcrumbs, search and route guards. */
export const NAV_LEAVES: (NavLeaf & { parent?: string })[] = NAV.flatMap((g) =>
  g.items.flatMap<NavLeaf & { parent?: string }>((it) =>
    it.children
      ? it.children.map((c) => ({ ...c, parent: it.title }))
      : [{ title: it.title, to: it.to!, icon: it.icon, module: it.module!, badge: it.badge }],
  ),
);

export function findLeaf(pathname: string) {
  return [...NAV_LEAVES].sort((a, b) => b.to.length - a.to.length).find((l) => pathname === l.to || pathname.startsWith(l.to + "/"));
}

export { Tags, MessageSquareHeart };
