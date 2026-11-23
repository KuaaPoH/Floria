/* Domain models shared by mock data, services and UI. Shapes mirror the planned REST contracts. */

export type RoleId = "super_admin" | "botanist" | "operations";
export type AuthProvider = "google" | "email" | "apple" | "facebook";
export type AccountStatus = "active" | "locked" | "pending";

export interface AppUser {
  id: string;
  fullName: string;
  email: string;
  phone: string;
  avatar?: string;
  city: string;
  provider: AuthProvider;
  registeredAt: string;
  lastActiveAt: string;
  plants: number;
  scans: number;
  diseaseScans: number;
  orders: number;
  status: AccountStatus;
}

export interface Plant {
  id: string;
  viName: string;
  sciName: string;
  enName: string;
  category: string;
  family?: string;
  origin?: string;
  identification?: string;
  image: string;
  description: string;
  wikiDetail?: string;
  light: string;
  watering: string;
  soil: string;
  humidity: string;
  temperature: string;
  difficulty?: string;
  placements?: string[];
  petToxic: boolean;
  toxicityNote: string;
  aiClassId: number | null;
  aiClassName: string;
  relatedDiseaseIds: string[];
  careTips: string[];
  status: "published" | "draft";
  updatedAt: string;
}

export type Severity = "low" | "medium" | "high" | "critical";

export interface Disease {
  id: string;
  name: string;
  enName: string;
  category: string;
  agent: string;
  severity: Severity;
  severityLabel?: string;
  mechanism?: string;
  favorableConditions?: string;
  symptoms: string[];
  treatment: string[];
  prevention: string[];
  images: string[];
  aiClassId: number | null;
  aiClassName: string;
  updatedAt: string;
}

export type ModelKind = "gatekeeper" | "species" | "disease";

export interface ModelVersion {
  version: string;
  releasedAt: string;
  accuracy: number;
  f1: number;
  latencyMs: number;
  note: string;
}

export interface AiModel {
  id: string;
  name: string;
  file: string;
  kind: ModelKind;
  description: string;
  version: string;
  versions: ModelVersion[];
  active: boolean;
  accuracy: number;
  precision: number;
  recall: number;
  f1: number;
  latencyMs: number;
  classes: number;
  rollout: number;
  updatedAt: string;
}

export interface AiConfig {
  confidenceThreshold: number;
  gatekeeperThreshold: number;
  topK: number;
  inputSize: number;
  speciesVersion: string;
  diseaseVersion: string;
  executionProvider: "CPUExecutionProvider" | "CUDAExecutionProvider";
  batchSize: number;
  normalize: boolean;
}

export type ReviewStatus = "pending" | "approved" | "rejected";

export interface LabelReview {
  id: string;
  image: string;
  userName: string;
  predictedSpecies: string;
  predictedDisease: string;
  confidence: number;
  submittedAt: string;
  status: ReviewStatus;
  finalSpecies?: string;
  finalDisease?: string;
  notes: string;
  reviewedBy?: string;
}

export type PaymentMethod = "COD" | "ZALOPAY";
export type PaymentStatus = "unpaid" | "paid" | "refund_requested" | "refunded" | "failed";
export type FulfillmentStatus = "pending" | "confirmed" | "shipping" | "delivered" | "cancelled";

export interface OrderItem {
  productId: string;
  name: string;
  qty: number;
  price: number;
}

export interface Order {
  id: string;
  code: string;
  customerName: string;
  customerEmail: string;
  phone: string;
  address: string;
  createdAt: string;
  items: OrderItem[];
  shippingFee: number;
  discount: number;
  voucherCode?: string;
  total: number;
  paymentMethod: PaymentMethod;
  paymentStatus: PaymentStatus;
  fulfillment: FulfillmentStatus;
  timeline: { status: FulfillmentStatus; at: string; by: string }[];
  transaction?: { id: string; at: string; sandbox: boolean };
  notes: string;
}

export const PRODUCT_CATEGORIES = [
  "Phân bón",
  "Đất & giá thể",
  "Chậu cây",
  "Dụng cụ làm vườn",
  "Thuốc trị sâu bệnh",
  "Chăm sóc cây",
] as const;
export type ProductCategory = (typeof PRODUCT_CATEGORIES)[number];

export interface Product {
  id: string;
  name: string;
  sku: string;
  category: string;
  image: string;
  originalPrice: number;
  price: number;
  stock: number;
  lowStockThreshold: number;
  visible: boolean;
  sold: number;
  rating: number;
  shortDesc?: string;
  description: string;
  usageGuide?: string;
  indications?: string[];
  tag?: string;
  updatedAt: string;
}

export interface InventoryTx {
  id: string;
  productId: string;
  productName: string;
  type: "in" | "out" | "adjust";
  qty: number;
  note: string;
  by: string;
  at: string;
}

export interface Voucher {
  id: string;
  code: string;
  type: "percent" | "fixed";
  value: number;
  minOrder: number;
  maxUsage: number;
  used: number;
  expiresAt: string;
  active: boolean;
}

export interface ProductReview {
  id: string;
  productId: string;
  productName: string;
  customer: string;
  rating: number;
  content: string;
  images?: string[];
  createdAt: string;
  status: "pending" | "approved" | "hidden" | "rejected";
  reply?: string;
}

export type BlockType = "heading" | "paragraph" | "image" | "quote" | "bullets" | "numbered" | "info" | "warning";
export interface ArticleBlock {
  id: string;
  type: BlockType;
  text: string;
  items?: string[];
  src?: string;
}

export interface Article {
  id: string;
  title: string;
  excerpt: string;
  category: string;
  cover: string;
  author: string;
  status: "draft" | "published";
  publishedAt: string;
  updatedAt: string;
  views: number;
  blocks: ArticleBlock[];
}

export interface Banner {
  id: string;
  title: string;
  subtitle: string;
  cta: string;
  deepLink: string;
  image: string;
  startHour?: number;
  endHour?: number;
  startDate: string;
  endDate: string;
  active: boolean;
  order: number;
}

export interface WeatherRule {
  id: string;
  name: string;
  title?: string;
  badgeText?: string;
  advice?: string;
  tip: string;
  conditionType?: "temperature_high" | "temperature_low" | "humidity_high" | "humidity_low" | "rain" | "storm_wind";
  condition: "rain" | "sunny" | "humid" | "cold" | "hot";
  minTemp?: number | null;
  maxTemp?: number | null;
  tempMin: number;
  tempMax: number;
  minHumidity?: number | null;
  maxHumidity?: number | null;
  humidityMin: number;
  humidityMax: number;
  weatherCodes?: number[];
  minWindSpeed?: number | null;
  iconName?: string;
  active: boolean;
  priority?: number;
  order?: number;
}

export interface FeatureFlag {
  id: string;
  key: string;
  name: string;
  description: string;
  enabled: boolean;
  updatedAt: string;
  updatedBy: string;
}

export interface HomeSection {
  id: string;
  type: "banner" | "quick_actions" | "weather" | "my_plants" | "shop" | "handbook" | "reminders";
  title: string;
  enabled: boolean;
  layout: "carousel" | "grid" | "list";
}

export interface RemoteConfig {
  sections: HomeSection[];
  theme: { primary: string; accent: string; rounded: boolean };
  banner: { title: string; subtitle: string; cta: string };
}

export interface ConfigVersion {
  id: string;
  version: number;
  status: "published" | "draft";
  at: string;
  by: string;
  note: string;
  snapshot: RemoteConfig;
}

export type AudienceKind = "all" | "active" | "inactive" | "species" | "diagnosed" | "custom";

export interface Campaign {
  id: string;
  name: string;
  title: string;
  body: string;
  image: string;
  deepLink: string;
  audience: AudienceKind;
  audienceDetail: string;
  scheduledAt: string;
  status: "draft" | "scheduled" | "sent" | "failed";
  targeted: number;
  success: number;
  failed: number;
  opened: number;
}

export type TicketStatus = "open" | "in_progress" | "resolved";
export interface Ticket {
  id: string;
  code: string;
  subject: string;
  category: "app_error" | "ai_wrong" | "order" | "product" | "suggestion";
  userName: string;
  email: string;
  status: TicketStatus;
  priority: "low" | "medium" | "high";
  createdAt: string;
  assignee: string;
  messages: { from: "user" | "admin"; text: string; at: string }[];
  notes: { by: string; text: string; at: string }[];
}

export interface AuditLog {
  id: string;
  admin: string;
  role: RoleId;
  action: string;
  target: string;
  before: string;
  after: string;
  at: string;
  ip: string;
}

export interface AdminAccount {
  id: string;
  name: string;
  email: string;
  role: RoleId;
  avatar?: string;
  status: "active" | "disabled";
  lastLogin: string;
  twoFA: boolean;
}

export interface ConversationReport {
  id: string;
  userName: string;
  preview: string;
  reason: string;
  at: string;
  status: "pending" | "reviewed" | "dismissed";
  note: string;
  transcript: { from: "user" | "bot"; text: string }[];
}

export interface Guardrail {
  id: string;
  category: "care" | "toxicity" | "medical" | "scope";
  name: string;
  description: string;
  response: string;
  keywords: string[];
  enabled: boolean;
}

export interface ActionTag {
  id: string;
  tag: string;
  keywords: string[];
  intent: string;
  condition: string;
  enabled: boolean;
}

export interface PromptVersion {
  id: string;
  version: number;
  status: "published" | "draft";
  at: string;
  by: string;
  content: string;
}

export interface AssistantSettings {
  name: string;
  language: "vi" | "en";
  tone: "friendly" | "professional" | "concise";
  maxLength: number;
  fallback: string;
}

export interface BackupRecord {
  id: string;
  name: string;
  type: "auto" | "manual";
  size: string;
  at: string;
  status: "success" | "failed" | "running";
  scope: string;
}

export interface ServiceHealth {
  id: string;
  name: string;
  description: string;
  status: "operational" | "degraded" | "offline";
  latencyMs: number;
  uptime: number;
  checkedAt: string;
}
