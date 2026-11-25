/**
 * Floria data models. Names mirror the backend collections
 * (Users, UserGardens, UserPlants, plants_info, DiseasesInfo, ...).
 * All dates are ISO strings.
 */

export type ID = string;
export type Lang = "vi" | "en";

// ---------- Users ----------
export interface CartItemRef {
  productId: ID;
  quantity: number;
  selected: boolean;
  addedAt: string;
}

export interface User {
  uid: ID;
  displayName: string;
  email: string;
  avatarId: string | null; // one of BOTANICAL_AVATARS ids
  avatarUrl: string | null; // uploaded avatar (Cloudinary url when backend exists)
  phone?: string;
  bio?: string;
  joinedAt: string;
  provider: "password" | "google";
  cartItems?: CartItemRef[];
}

// ---------- Gardens & plants ----------
export type GardenEnvironment = "indoor" | "balcony" | "yard" | "rooftop";
export type LightCondition = "low" | "indirect" | "bright" | "direct";

export interface UserGarden {
  id: ID;
  userId: ID;
  name: string;
  coverImage: string;
  environment: GardenEnvironment;
  light: LightCondition;
  description: string;
  createdAt: string;
}

export type HealthStatus = "healthy" | "sick" | "recovering";

export interface UserPlant {
  id: ID;
  userId: ID;
  gardenId: ID;
  speciesId: ID; // -> PlantInfo.id
  nickname: string;
  location: string; // free text e.g. "Phòng khách" -> drives dynamic location chips
  image: string;
  healthStatus: HealthStatus;
  activeDiseaseId: ID | null; // -> DiseaseInfo.id when sick
  addedAt: string;
}

export interface PlantInfo {
  id: ID;
  commonName: string;
  commonNameEn: string;
  scientificName: string;
  family: string;
  image: string;
  description: string;
  wikiDetail?: string;
  origin: string;
  environment: string;
  light: string;
  water: string;
  difficulty?: string;
  identification?: string;
  soil: string;
  temperature: string;
  humidity: string;
  toxicity: string | null;
  careTips: string[];
  idealLight: LightCondition[];
  idealEnvironments: GardenEnvironment[];
  wateringDays: number;
  fertilizingDays: number;
  inspectionDays: number;
}

// ---------- Care schedules (3 independent schedules per plant) ----------
export type CareType = "watering" | "fertilizing" | "inspection";

export interface CareLog {
  id: ID;
  doneAt: string;
  note?: string;
}

export interface CareSchedule {
  id: ID;
  plantId: ID;
  type: CareType;
  intervalDays: number;
  preferredTime: string; // "07:00"
  lastDoneAt: string | null;
  nextDueAt: string;
  enabled: boolean;
  history: CareLog[];
}

// ---------- Diary ----------
export type DiaryCategory = "general" | "health" | "growth" | "care";

export interface DiaryNote {
  id: ID;
  plantId: ID;
  userId: ID;
  category: DiaryCategory;
  title?: string;
  content: string;
  images: string[];
  diagnosisId?: ID | null; // link to ScanHistory entry when category === "health"
  createdAt: string;
  updatedAt: string;
}

// ---------- Diseases ----------
export type DiseaseSeverity = "none" | "low" | "medium" | "high";

export interface DiseaseInfo {
  id: ID;
  name: string;
  nameEn: string;
  isHealthy: boolean;
  severity: DiseaseSeverity;
  agent: string; // tác nhân
  mechanism: string;
  outbreakConditions: string;
  symptoms: string;
  prevention: string[];
  treatment: string[];
  relatedProductIds: ID[];
}

// ---------- Scans ----------
export type ScanType = "identify" | "diagnose";

export interface SpeciesPrediction {
  speciesId: ID;
  confidence: number; // 0..1
  nameVi?: string;
  scientificName?: string;
  matchedDatabase?: boolean;
}

export interface ScanHistoryItem {
  id: ID;
  userId: ID | null;
  type: ScanType;
  image: string;
  createdAt: string;
  isValidPlant: boolean;
  // identify
  predictions?: SpeciesPrediction[];
  // diagnose
  plantId?: ID;
  diseaseId?: ID;
  confidence?: number;
  appliedToRecord?: boolean;
}

// ---------- Assistant ----------
export interface ChatSession {
  id: ID;
  userId: ID;
  title: string;
  createdAt: string;
  updatedAt: string;
}

export type ChatRole = "user" | "assistant";

export interface ChatMessage {
  id: ID;
  sessionId: ID;
  role: ChatRole;
  content: string; // raw content; assistant content may contain action tags
  images: string[];
  createdAt: string;
  status?: "sent" | "error";
}

export interface CareScheduleSuggestion {
  plantName: string;
  speciesId?: ID;
  careType: CareType;
  intervalDays: number;
  preferredTime: string;
  reason: string;
}

export interface ProductSuggestion {
  productId: ID;
  reason?: string;
}

export type AssistantBlock =
  | { kind: "text"; text: string }
  | { kind: "care_schedule"; data: CareScheduleSuggestion }
  | { kind: "product"; data: ProductSuggestion };

// ---------- Handbook ----------
export interface HandbookArticle {
  id: ID;
  slug: string;
  title: string;
  excerpt: string;
  category: string;
  image: string;
  readMinutes: number;
  tags: string[]; // speciesIds or weather tags like "rain", "hot"
  body: string[]; // paragraphs
  publishedAt: string;
}

// ---------- Shop ----------
export type ProductCategory = "fertilizer" | "soil" | "pots" | "tools" | "treatment" | "plants";

export interface ShopProduct {
  id: ID;
  name: string;
  slug: string;
  category: ProductCategory;
  images: string[];
  price: number; // VND
  salePrice: number | null;
  rating: number;
  reviewCount: number;
  sold: number;
  stock: number;
  shortDescription: string;
  description: string;
  ingredients: string;
  usage: string[];
  benefits: string[]; // công dụng, searchable
  tags: ("featured" | "bestseller" | "new")[];
  createdAt: string;
}

export interface ProductReview {
  id: ID;
  productId: ID;
  orderId: ID | null;
  userId: ID;
  userName: string;
  userAvatar: string | null;
  rating: number;
  content: string;
  images: string[];
  reply?: string | null;
  repliedAt?: string | null;
  createdAt: string;
}

export interface SystemNotificationItem {
  id: ID;
  title: string;
  body: string;
  image?: string;
  deepLink?: string;
  sentAt: string;
}

export type CartItem = CartItemRef;

export type VoucherType = "percent" | "fixed";

export interface Voucher {
  code: string;
  title: string;
  type: VoucherType;
  value: number; // percent (0-100) or VND
  maxDiscount?: number;
  minOrder: number;
  expiresAt: string;
  active: boolean;
}

export interface Address {
  id: ID;
  userId: ID;
  recipientName: string;
  phone: string;
  provinceCode: string;
  provinceName: string;
  wardCode: string;
  wardName: string;
  street: string;
  latitude: number | null;
  longitude: number | null;
  isDefault: boolean;
  label?: string;
}

// Backend enum. UI labels map from these values; never invent new ones.
export type OrderStatus = "pending" | "processing" | "shipping" | "delivered" | "cancelled";
export type PaymentMethod = "zalopay" | "cod";
export type PaymentStatus = "unpaid" | "awaiting_gateway" | "paid" | "failed" | "refunded";

export interface OrderItem {
  productId: ID;
  name: string;
  image: string;
  unitPrice: number;
  quantity: number;
  reviewed?: boolean;
}

export interface Order {
  id: ID;
  code: string;
  userId: ID;
  items: OrderItem[];
  addressSnapshot: Omit<Address, "id" | "userId" | "isDefault">;
  subtotal: number;
  shippingFee: number;
  discount: number;
  total: number;
  voucherCode: string | null;
  paymentMethod: PaymentMethod;
  paymentStatus: PaymentStatus;
  status: OrderStatus;
  createdAt: string;
  updatedAt: string;
}

// ---------- Reminders & settings ----------
export interface ReminderSettings {
  userId: ID;
  pushEnabled: boolean;
  watering: boolean;
  fertilizing: boolean;
  inspection: boolean;
  dndEnabled: boolean;
  dndStart: string; // "22:00"
  dndEnd: string; // "06:30"
}

// ---------- Weather ----------
export interface HomeWeatherWidget {
  id: ID;
  slot: "morning" | "afternoon" | "evening" | "night";
  fromHour: number;
  toHour: number;
  greeting: string;
  greetingEn: string;
  message: string;
  messageEn: string;
  image?: string;
}

export interface WeatherSnapshot {
  temperature: number;
  humidity: number;
  windSpeed: number;
  weatherCode: number;
  isDay: boolean;
  fetchedAt: string;
}

export interface WeatherAdviceRuleItem {
  id: string;
  title: string;
  badgeText: string;
  advice: string;
  conditionType: string;
  minTemp: number | null;
  maxTemp: number | null;
  minHumidity: number | null;
  maxHumidity: number | null;
  minWindSpeed: number | null;
  weatherCodes: number[];
  priority: number;
  active: boolean;
}

export interface SupportFaqItem {
  id: string;
  category: string;
  categoryVi: string;
  categoryEn: string;
  questionVi: string;
  questionEn: string;
  answerVi: string;
  answerEn: string;
  order: number;
}
