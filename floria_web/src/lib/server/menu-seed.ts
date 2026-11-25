export type MenuTarget = "admin_sidebar" | "mobile_app" | "web_user";

export interface MenuItemDoc {
  id: string;
  target: MenuTarget;
  parentId: string | null;
  title: string;
  titleEn: string;
  route: string;
  icon: string;
  module?: string;
  badgeKey?: string;
  order: number;
  visible: boolean;
  updatedAt: string;
}

export const DEFAULT_ADMIN_MENU_SEED: Omit<MenuItemDoc, "updatedAt">[] = [
  // Cấp cha (Group headers)
  { id: "grp_workspace", target: "admin_sidebar", parentId: null, title: "Workspace", titleEn: "Workspace", route: "", icon: "FolderTree", module: "", order: 1, visible: true },
  { id: "grp_system", target: "admin_sidebar", parentId: null, title: "Hệ thống", titleEn: "System", route: "", icon: "Settings2", module: "", order: 2, visible: true },

  // Con của Workspace
  { id: "adm_overview", target: "admin_sidebar", parentId: "grp_workspace", title: "Tổng quan", titleEn: "Overview", route: "/admin/overview", icon: "LayoutDashboard", module: "overview", order: 1, visible: true },
  { id: "adm_users", target: "admin_sidebar", parentId: "grp_workspace", title: "Người dùng", titleEn: "Users", route: "/admin/users", icon: "Users", module: "users", order: 2, visible: true },
  { id: "adm_ai_group", target: "admin_sidebar", parentId: "grp_workspace", title: "AI & Trợ lý", titleEn: "AI & Assistant", route: "", icon: "BrainCircuit", module: "", order: 3, visible: true },
  { id: "adm_botanical_group", target: "admin_sidebar", parentId: "grp_workspace", title: "Dữ liệu thực vật", titleEn: "Botanical Data", route: "", icon: "Leaf", module: "", order: 4, visible: true },
  { id: "adm_commerce_group", target: "admin_sidebar", parentId: "grp_workspace", title: "Thương mại", titleEn: "Commerce", route: "", icon: "Store", module: "", order: 5, visible: true },
  { id: "adm_content_group", target: "admin_sidebar", parentId: "grp_workspace", title: "Nội dung & Trải nghiệm", titleEn: "Content & UX", route: "", icon: "LayoutTemplate", module: "", order: 6, visible: true },
  { id: "adm_comms_group", target: "admin_sidebar", parentId: "grp_workspace", title: "Truyền thông", titleEn: "Communications", route: "", icon: "Megaphone", module: "", order: 7, visible: true },

  // Con của AI & Trợ lý
  { id: "adm_ai_lab", target: "admin_sidebar", parentId: "adm_ai_group", title: "AI Lab", titleEn: "AI Lab", route: "/admin/ai-lab", icon: "Sparkles", module: "ai_lab", badgeKey: "labelReviews", order: 1, visible: true },
  { id: "adm_assistant", target: "admin_sidebar", parentId: "adm_ai_group", title: "Floria Assistant", titleEn: "Floria Assistant", route: "/admin/assistant", icon: "Bot", module: "assistant", order: 2, visible: true },

  // Con của Dữ liệu thực vật
  { id: "adm_plants", target: "admin_sidebar", parentId: "adm_botanical_group", title: "Từ điển cây", titleEn: "Plant Wiki", route: "/admin/plants", icon: "Flower2", module: "botanical", order: 1, visible: true },
  { id: "adm_diseases", target: "admin_sidebar", parentId: "adm_botanical_group", title: "Từ điển bệnh", titleEn: "Disease Wiki", route: "/admin/diseases", icon: "Microscope", module: "botanical", order: 2, visible: true },
  { id: "adm_label_map", target: "admin_sidebar", parentId: "adm_botanical_group", title: "Ánh xạ nhãn AI", titleEn: "AI Label Mapping", route: "/admin/label-mapping", icon: "Workflow", module: "botanical", order: 3, visible: true },

  // Con của Thương mại
  { id: "adm_orders", target: "admin_sidebar", parentId: "adm_commerce_group", title: "Đơn hàng", titleEn: "Orders", route: "/admin/orders", icon: "ShoppingBag", module: "orders", badgeKey: "pendingOrders", order: 1, visible: true },
  { id: "adm_products", target: "admin_sidebar", parentId: "adm_commerce_group", title: "Sản phẩm", titleEn: "Products", route: "/admin/products", icon: "Package", module: "products", order: 2, visible: true },
  { id: "adm_inventory", target: "admin_sidebar", parentId: "adm_commerce_group", title: "Kho hàng", titleEn: "Inventory", route: "/admin/inventory", icon: "Warehouse", module: "products", order: 3, visible: true },
  { id: "adm_reviews", target: "admin_sidebar", parentId: "adm_commerce_group", title: "Đánh giá", titleEn: "Reviews", route: "/admin/reviews", icon: "Star", module: "reviews", badgeKey: "pendingReviews", order: 4, visible: true },

  // Con của Nội dung & Trải nghiệm
  { id: "adm_handbook", target: "admin_sidebar", parentId: "adm_content_group", title: "Cẩm nang", titleEn: "Handbook", route: "/admin/handbook", icon: "BookOpen", module: "content", order: 1, visible: true },
  { id: "adm_banners", target: "admin_sidebar", parentId: "adm_content_group", title: "Banner trang chủ", titleEn: "Home Banners", route: "/admin/banners", icon: "Image", module: "content", order: 2, visible: true },

  // Con của Truyền thông
  { id: "adm_notifications", target: "admin_sidebar", parentId: "adm_comms_group", title: "Thông báo đẩy", titleEn: "Push Notifications", route: "/admin/notifications", icon: "BellRing", module: "notifications", order: 1, visible: true },
  { id: "adm_support", target: "admin_sidebar", parentId: "adm_comms_group", title: "Trung tâm hỗ trợ", titleEn: "Support Center", route: "/admin/support", icon: "LifeBuoy", module: "support", order: 2, visible: true },

  // Con của Hệ thống
  { id: "adm_settings_group", target: "admin_sidebar", parentId: "grp_system", title: "Cài đặt hệ thống", titleEn: "System Settings", route: "", icon: "Settings2", module: "", order: 1, visible: true },
  { id: "adm_roles", target: "admin_sidebar", parentId: "adm_settings_group", title: "Quản trị & Phân quyền", titleEn: "Roles & RBAC", route: "/admin/settings/roles", icon: "ShieldCheck", module: "system", order: 1, visible: true },
  { id: "adm_health", target: "admin_sidebar", parentId: "adm_settings_group", title: "Tình trạng hệ thống", titleEn: "System Health", route: "/admin/settings/health", icon: "Activity", module: "system", order: 2, visible: true },
  { id: "adm_audit", target: "admin_sidebar", parentId: "adm_settings_group", title: "Nhật ký hoạt động", titleEn: "Audit Log", route: "/admin/settings/audit", icon: "FileClock", module: "system", order: 3, visible: true },
  { id: "adm_menus", target: "admin_sidebar", parentId: "adm_settings_group", title: "Quản lý Menu", titleEn: "Menu Management", route: "/admin/settings/menus", icon: "Menu", module: "system", order: 4, visible: true },
];

export const DEFAULT_MOBILE_MENU_SEED: Omit<MenuItemDoc, "updatedAt">[] = [
  { id: "mob_home", target: "mobile_app", parentId: null, title: "Trang chủ", titleEn: "Home", route: "home", icon: "Home", order: 1, visible: true },
  { id: "mob_garden", target: "mobile_app", parentId: null, title: "Khu vườn", titleEn: "Garden", route: "garden", icon: "Eco", order: 2, visible: true },
  { id: "mob_scan", target: "mobile_app", parentId: null, title: "Camera", titleEn: "Scan", route: "scan", icon: "CameraAlt", order: 3, visible: true },
  { id: "mob_shop", target: "mobile_app", parentId: null, title: "Cửa hàng", titleEn: "Shop", route: "shop", icon: "ShoppingBag", order: 4, visible: true },
  { id: "mob_profile", target: "mobile_app", parentId: null, title: "Cá nhân", titleEn: "Profile", route: "profile", icon: "Person", order: 5, visible: true },
];

export const DEFAULT_WEB_USER_MENU_SEED: Omit<MenuItemDoc, "updatedAt">[] = [
  { id: "web_home", target: "web_user", parentId: null, title: "Trang chủ", titleEn: "Home", route: "/", icon: "Home", module: "public_only", order: 1, visible: true },
  { id: "web_dashboard", target: "web_user", parentId: null, title: "Tổng quan", titleEn: "Overview", route: "/dashboard", icon: "LayoutDashboard", module: "auth_only", order: 2, visible: true },
  { id: "web_garden", target: "web_user", parentId: null, title: "Khu vườn", titleEn: "Gardens", route: "/garden", icon: "Sprout", module: "auth_only", order: 3, visible: true },
  { id: "web_discovery", target: "web_user", parentId: null, title: "Khám phá cây", titleEn: "Discover", route: "/discovery", icon: "ScanLine", module: "", order: 4, visible: true },
  { id: "web_handbook", target: "web_user", parentId: null, title: "Cẩm nang", titleEn: "Handbook", route: "/handbook", icon: "BookOpen", module: "", order: 5, visible: true },
  { id: "web_shop", target: "web_user", parentId: null, title: "Cửa hàng", titleEn: "Shop", route: "/shop", icon: "ShoppingBag", module: "", order: 6, visible: true },
  { id: "web_assistant", target: "web_user", parentId: null, title: "Trợ lý Floria", titleEn: "Floria Assistant", route: "/assistant", icon: "Bot", module: "", order: 7, visible: true },
];
