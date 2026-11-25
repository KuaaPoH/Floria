import { NextResponse } from "next/server";
import { getAdminDb, isFirebaseAdminConfigured } from "@/lib/server/firebase-admin";
import { toIsoString } from "@/lib/server/firestore-utils";
import { DISEASES_INFO } from "@/mocks/user/diseases";
import { HOME_WEATHER_WIDGETS, PLANT_HANDBOOK } from "@/mocks/user/handbook";
import { IMG } from "@/mocks/user/images";
import { PLANTS_INFO, slugifySpecies } from "@/mocks/user/plants-info";
import { SEED_REVIEWS, SHOP_PRODUCTS, VOUCHERS } from "@/mocks/user/shop";
import type {
  DiseaseInfo,
  DiseaseSeverity,
  GardenEnvironment,
  HandbookArticle,
  HomeWeatherWidget,
  LightCondition,
  PlantInfo,
  ProductCategory,
  ProductReview,
  ShopProduct,
  SupportFaqItem,
  SystemNotificationItem,
  Voucher,
  WeatherAdviceRuleItem,
} from "@/types/user";

function mapProductCategory(d: Record<string, unknown>): ProductCategory {
  const raw = String(d.categoryKey ?? d.category ?? "").toLowerCase();
  if (raw.includes("fertilizer") || raw.includes("phân") || raw.includes("dưỡng")) return "fertilizer";
  if (raw.includes("soil") || raw.includes("đất") || raw.includes("giá thể")) return "soil";
  if (raw.includes("pot") || raw.includes("chậu")) return "pots";
  if (raw.includes("medicine") || raw.includes("treatment") || raw.includes("thuốc") || raw.includes("sinh học") || raw.includes("bảo vệ")) return "treatment";
  if (raw.includes("plant") || raw.includes("cây")) return "plants";
  return "tools";
}

function mapProductFromFirestore(id: string, d: Record<string, unknown>): ShopProduct {
  const priceRaw = Number(d.price ?? 0);
  const originalRaw = Number(d.originalPrice ?? priceRaw);
  const hasDiscount = originalRaw > priceRaw && priceRaw > 0;
  const img = String(d.imageUrl ?? d.image ?? "").trim() || IMG.products.fertilizer;
  const tagRaw = String(d.tag ?? "").toLowerCase();
  const tags: ShopProduct["tags"] = [];
  if (tagRaw.includes("hot") || tagRaw.includes("nổi bật") || tagRaw.includes("featured")) tags.push("featured");
  if (tagRaw.includes("bestseller") || tagRaw.includes("bán chạy") || Number(d.soldCount ?? d.sold ?? 0) > 300) tags.push("bestseller");
  if (tagRaw.includes("new") || tagRaw.includes("mới")) tags.push("new");

  const usageRaw = String(d.usageGuide ?? d.usage ?? "").trim();
  const usage = Array.isArray(d.usage)
    ? d.usage.map((x) => String(x))
    : usageRaw
      ? usageRaw.split(/\n+/).map((s) => s.trim()).filter(Boolean)
      : ["Sử dụng theo hướng dẫn trên bao bì sản phẩm."];

  const stock = typeof d.stock === "number" ? d.stock : d.inStock === false ? 0 : 25;

  return {
    id,
    name: String(d.name ?? "Sản phẩm Floria"),
    slug: String(d.slug ?? id),
    category: mapProductCategory(d),
    images: Array.isArray(d.images) && d.images.length ? d.images.map(String) : [img],
    price: hasDiscount ? originalRaw : priceRaw,
    salePrice: hasDiscount ? priceRaw : null,
    rating: Number(d.rating ?? 4.8),
    reviewCount: Number(d.reviewCount ?? 0),
    sold: Number(d.soldCount ?? d.sold ?? 0),
    stock,
    shortDescription: String(d.shortDesc ?? d.shortDescription ?? ""),
    description: String(d.description ?? d.shortDesc ?? ""),
    ingredients: String(d.ingredients ?? "Thành phần tuyển chọn an toàn cho cây trồng trong nhà."),
    usage,
    benefits: Array.isArray(d.indications) ? d.indications.map(String) : Array.isArray(d.benefits) ? d.benefits.map(String) : [],
    tags,
    createdAt: toIsoString(d.createdAt ?? d.updatedAt),
  };
}

function mapArticleFromFirestore(id: string, d: Record<string, unknown>): HandbookArticle {
  const blocks = Array.isArray(d.blocks) ? d.blocks : [];
  const extractedBody = blocks
    .map((b) => {
      if (typeof b === "string") return b;
      if (typeof b === "object" && b !== null) {
        const rec = b as Record<string, unknown>;
        if (Array.isArray(rec.items) && rec.items.length) {
          return rec.items.map((it) => `• ${String(it)}`).join("\n");
        }
        return String(rec.value ?? rec.text ?? "").trim();
      }
      return "";
    })
    .filter(Boolean);

  const body =
    Array.isArray(d.body) && d.body.length
      ? d.body.map(String)
      : extractedBody.length
        ? extractedBody
        : [String(d.summary ?? d.excerpt ?? "Bài viết hướng dẫn chăm sóc cây từ Floria.")];

  const readTimeMatch = String(d.readTime ?? "").match(/\d+/);
  const readMinutes = typeof d.readMinutes === "number" ? d.readMinutes : readTimeMatch ? Number(readTimeMatch[0]) : 5;
  const cover = String(d.coverImage ?? d.cover ?? d.image ?? "").trim() || IMG.plants.monstera;

  return {
    id,
    slug: String(d.slug ?? id),
    title: String(d.title ?? "Cẩm nang Floria"),
    excerpt: String(d.summary ?? d.excerpt ?? body[0] ?? ""),
    category: String(d.category ?? "").trim() || "Cẩm nang",
    image: cover,
    readMinutes,
    tags: Array.isArray(d.tags) ? d.tags.map(String) : [],
    body,
    publishedAt: toIsoString(d.publishedAt ?? d.createdAt),
  };
}

function parseWateringDays(waterText: string): number {
  const lower = waterText.toLowerCase();
  const match = lower.match(/(\d+)\s*(?:[-–]\s*(\d+))?\s*ngày/);
  if (match) return Number(match[1]) || 5;
  const weekMatch = lower.match(/(\d+)\s*(?:[-–]\s*(\d+))?\s*tuần/);
  if (weekMatch) return (Number(weekMatch[1]) || 1) * 7;
  if (lower.includes("hằng ngày") || lower.includes("mỗi ngày")) return 1;
  return 5;
}

function inferIdealLight(lightText: string): LightCondition[] {
  const lower = lightText.toLowerCase();
  const res: LightCondition[] = [];
  if (lower.includes("yếu") || lower.includes("bóng")) res.push("low");
  if (lower.includes("gián tiếp") || lower.includes("trung bình")) res.push("indirect");
  if (lower.includes("sáng mạnh") || lower.includes("tán xạ")) res.push("bright");
  if (lower.includes("trực tiếp") || lower.includes("nắng gắt")) res.push("direct");
  return res.length ? res : ["indirect", "bright"];
}

function inferIdealEnvironments(placements: string[], category: string): GardenEnvironment[] {
  const joined = `${placements.join(" ")} ${category}`.toLowerCase();
  const res: GardenEnvironment[] = [];
  if (joined.includes("trong nhà") || joined.includes("phòng") || joined.includes("bàn")) res.push("indoor");
  if (joined.includes("ban công") || joined.includes("hiên")) res.push("balcony");
  if (joined.includes("sân vườn") || joined.includes("ngoài trời")) res.push("yard");
  if (joined.includes("sân thượng") || joined.includes("nhà kính")) res.push("rooftop");
  return res.length ? res : ["indoor", "balcony"];
}

function mapPlantInfoFromFirestore(id: string, d: Record<string, unknown>): PlantInfo {
  const sci = String(d.scientific_name ?? d.sciName ?? id);
  const waterStr = String(d.water_frequency ?? d.watering ?? "Tưới khi đất mặt khô 2–3cm");
  const lightStr = String(d.light ?? "Ánh sáng gián tiếp");
  const placements = Array.isArray(d.placements) ? d.placements.map(String) : [];
  const category = String(d.plant_type ?? d.category ?? "Cây cảnh");
  const fallbackImg = PLANTS_INFO.find((p) => p.scientificName.toLowerCase() === sci.toLowerCase())?.image ?? IMG.plants.monstera;

  return {
    id: slugifySpecies(sci) || id,
    commonName: String(d.name_vi ?? d.viName ?? sci),
    commonNameEn: String(d.en_name ?? d.enName ?? sci),
    scientificName: sci,
    family: String(d.family ?? "Thực vật cảnh"),
    image: String(d.image ?? d.imageUrl ?? d.wiki_image ?? "").trim() || fallbackImg,
    description: String(d.short_desc ?? d.description ?? d.wiki_detail ?? ""),
    wikiDetail: String(d.wiki_detail ?? d.description ?? d.short_desc ?? ""),
    origin: String(d.origin ?? "Vùng nhiệt đới"),
    environment: placements.join(", ") || category,
    light: lightStr,
    water: waterStr,
    difficulty: String(d.difficulty ?? "Trung bình"),
    identification: d.identification ? String(d.identification) : undefined,
    soil: String(d.root_type ?? d.soil ?? "Giá thể tơi xốp, thoát nước tốt"),
    temperature: String(d.temperature ?? "18–30°C"),
    humidity: String(d.humidity ?? "50–70%"),
    toxicity: d.toxicity ? String(d.toxicity) : d.toxicityNote ? String(d.toxicityNote) : null,
    careTips: Array.isArray(d.careTips)
      ? d.careTips.map(String)
      : d.identification
        ? [String(d.identification)]
        : ["Kiểm tra độ ẩm đất trước khi tưới."],
    idealLight: inferIdealLight(lightStr),
    idealEnvironments: inferIdealEnvironments(placements, category),
    wateringDays: typeof d.wateringDays === "number" ? d.wateringDays : parseWateringDays(waterStr),
    fertilizingDays: typeof d.fertilizingDays === "number" ? d.fertilizingDays : 20,
    inspectionDays: typeof d.inspectionDays === "number" ? d.inspectionDays : 5,
  };
}

function mapDiseaseFromFirestore(id: string, d: Record<string, unknown>, products: ShopProduct[]): DiseaseInfo {
  const name = String(d.nameVi ?? d.name ?? id);
  const nameEn = String(d.nameEn ?? d.enName ?? id.replaceAll("_", " "));
  const isHealthy = id.toLowerCase() === "healthy" || name.toLowerCase().includes("khỏe");
  const sevRaw = String(d.severity ?? "").toLowerCase();
  let severity: DiseaseSeverity = isHealthy ? "none" : "medium";
  if (!isHealthy) {
    if (sevRaw.includes("nghiêm") || sevRaw.includes("high") || sevRaw.includes("critical") || sevRaw.includes("nguy hiểm")) severity = "high";
    else if (sevRaw.includes("low") || sevRaw.includes("nhẹ") || sevRaw.includes("thấp")) severity = "low";
  }

  const symptoms = Array.isArray(d.symptoms)
    ? d.symptoms.map(String).join(". ")
    : String(d.symptoms ?? d.mechanism ?? "");

  const treatment = Array.isArray(d.treatment)
    ? d.treatment.map(String)
    : Array.isArray(d.treatmentSteps)
      ? d.treatmentSteps.map(String)
      : [];

  const prevention = Array.isArray(d.prevention)
    ? d.prevention.map(String)
    : typeof d.prevention === "string" && d.prevention.trim()
      ? d.prevention.split(/\n+/).map((s) => s.trim()).filter(Boolean)
      : [];

  const relatedProductIds = isHealthy
    ? []
    : Array.isArray(d.relatedProductIds) && d.relatedProductIds.length
      ? d.relatedProductIds.map(String)
      : products
        .filter((p) => p.category === "treatment" || p.category === "soil")
        .slice(0, 2)
        .map((p) => p.id);

  return {
    id,
    name,
    nameEn,
    isHealthy,
    severity,
    agent: String(d.pathogen ?? d.agent ?? (isHealthy ? "Không có tác nhân gây hại" : "Nấm / vi khuẩn gây hại lá")),
    mechanism: String(d.mechanism ?? ""),
    outbreakConditions: String(d.favorableConditions ?? "Độ ẩm cao, ít thông gió"),
    symptoms: symptoms || "Quan sát vết đốm hoặc đổi màu bất thường trên bề mặt lá.",
    prevention,
    treatment,
    relatedProductIds,
  };
}

export async function GET() {
  if (!isFirebaseAdminConfigured()) {
    if (process.env.NEXT_PUBLIC_DATA_MODE === "api") {
      return NextResponse.json(
        { error: "Mất kết nối cơ sở dữ liệu máy chủ (Firebase Admin chưa được cấu hình)." },
        { status: 503 },
      );
    }
    return NextResponse.json({
      source: "mock",
      products: SHOP_PRODUCTS,
      handbook: PLANT_HANDBOOK,
      vouchers: VOUCHERS,
      reviews: SEED_REVIEWS,
      plantsInfo: PLANTS_INFO,
      diseasesInfo: DISEASES_INFO,
      weatherWidgets: HOME_WEATHER_WIDGETS,
      weatherRules: [],
      supportArticles: [],
      notifications: [],
    });
  }

  try {
    const db = getAdminDb();
    const [
      prodSnap,
      artSnap,
      voucherSnap,
      revSnap,
      plantsSnap,
      diseasesSnap,
      widgetsSnap,
      rulesSnap,
      supportSnap,
      campaignSnap,
    ] = await Promise.all([
      db.collection("ShopProducts").get().catch(() => null),
      db.collection("PlantHandbook").get().catch(() => null),
      db.collection("Vouchers").get().catch(() => null),
      db.collection("ProductReviews").get().catch(() => null),
      db.collection("plants_info").get().catch(() => null),
      db.collection("DiseasesInfo").get().catch(() => null),
      db.collection("HomeWeatherWidgets").get().catch(() => null),
      db.collection("WeatherAdviceRules").get().catch(() => null),
      db.collection("SupportArticles").get().catch(() => null),
      db.collection("NotificationCampaigns").get().catch(() => null),
    ]);

    const products = (prodSnap?.docs ?? [])
      .filter((doc) => doc.data().visible !== false)
      .map((doc) => mapProductFromFirestore(doc.id, doc.data()));

    const handbook = (artSnap?.docs ?? [])
      .filter((doc) => doc.data().status !== "draft")
      .map((doc) => mapArticleFromFirestore(doc.id, doc.data()))
      .sort((a, b) => b.publishedAt.localeCompare(a.publishedAt));

    const vouchers: Voucher[] = (voucherSnap?.docs ?? [])
      .filter((doc) => {
        const d = doc.data();
        return d.type !== "shipping" && d.discountType !== "shipping";
      })
      .map((doc) => {
        const d = doc.data();
        const code = String(d.code ?? doc.id).toUpperCase();
        return {
          code,
          title: String(d.description ?? d.title ?? `Mã ưu đãi ${code}`),
          type: d.type === "fixed" || d.discountType === "fixed" ? "fixed" : "percent",
          value: Number(d.value ?? d.discountValue ?? 0),
          maxDiscount: typeof d.maxDiscount === "number" ? d.maxDiscount : undefined,
          minOrder: Number(d.minOrder ?? d.minOrderAmount ?? 0),
          expiresAt: toIsoString(d.expiresAt ?? d.expiryDate, "2027-12-31T23:59:59Z"),
          active: d.active !== false && d.isActive !== false,
        };
      });

    const reviews: ProductReview[] = (revSnap?.docs ?? [])
      .filter((doc) => {
        const st = String(doc.data().status ?? "approved");
        return st !== "hidden" && st !== "rejected";
      })
      .map((doc) => {
        const d = doc.data();
        const rawImages = Array.isArray(d.images) ? d.images : Array.isArray(d.reviewImages) ? d.reviewImages : [];
        return {
          id: doc.id,
          productId: String(d.productId ?? ""),
          orderId: typeof d.orderId === "string" ? d.orderId : null,
          userId: String(d.userId ?? ""),
          userName: String(d.userName ?? d.customer ?? "Khách hàng Floria"),
          userAvatar: typeof d.userAvatar === "string" ? d.userAvatar : null,
          rating: Number(d.rating ?? 5),
          content: String(d.comment ?? d.content ?? ""),
          images: rawImages.map(String).filter(Boolean),
          reply: typeof d.reply === "string" && d.reply.trim() ? d.reply.trim() : null,
          repliedAt: d.repliedAt ? toIsoString(d.repliedAt) : null,
          createdAt: toIsoString(d.createdAt),
        };
      });

    const plantsInfo: PlantInfo[] = (plantsSnap?.docs ?? [])
      .filter((doc) => doc.data().status !== "draft")
      .map((doc) => mapPlantInfoFromFirestore(doc.id, doc.data()))
      .sort((a, b) => a.commonName.localeCompare(b.commonName, "vi"));

    const diseasesInfo: DiseaseInfo[] = (diseasesSnap?.docs ?? []).map((doc) =>
      mapDiseaseFromFirestore(doc.id, doc.data(), products),
    );

    const weatherWidgets: HomeWeatherWidget[] = (widgetsSnap?.docs ?? [])
      .filter((doc) => doc.data().active !== false)
      .map((doc, idx) => {
        const d = doc.data();
        const fromHour = typeof d.startHour === "number" ? d.startHour : 6;
        const toHour = typeof d.endHour === "number" ? d.endHour : 11;
        const slot: HomeWeatherWidget["slot"] =
          fromHour >= 5 && fromHour < 11 ? "morning" : fromHour >= 11 && fromHour < 17 ? "afternoon" : fromHour >= 17 && fromHour < 21 ? "evening" : "night";
        return {
          id: doc.id,
          slot,
          fromHour,
          toHour,
          greeting: String(d.mainTitle ?? "Khu vườn Floria").replace(/\n/g, " "),
          greetingEn: String(d.mainTitleEn ?? d.mainTitle ?? "Floria Garden").replace(/\n/g, " "),
          message: String(d.advice ?? d.badgeText ?? ""),
          messageEn: String(d.adviceEn ?? d.advice ?? ""),
          image: String(d.heroImageUrl ?? d.image ?? d.imageUrl ?? "").trim() || undefined,
          order: typeof d.order === "number" ? d.order : idx,
        };
      })
      .sort((a, b) => a.order - b.order)
      .map(({ order: _o, ...rest }) => rest);

    const weatherRules: WeatherAdviceRuleItem[] = (rulesSnap?.docs ?? [])
      .filter((doc) => doc.data().active !== false)
      .map((doc) => {
        const d = doc.data();
        return {
          id: doc.id,
          title: String(d.title ?? d.name ?? ""),
          badgeText: String(d.badgeText ?? "Khuyến nghị thời tiết"),
          advice: String(d.advice ?? d.tip ?? ""),
          conditionType: String(d.conditionType ?? "temperature_high"),
          minTemp: typeof d.minTemp === "number" ? d.minTemp : null,
          maxTemp: typeof d.maxTemp === "number" ? d.maxTemp : null,
          minHumidity: typeof d.minHumidity === "number" ? d.minHumidity : null,
          maxHumidity: typeof d.maxHumidity === "number" ? d.maxHumidity : null,
          minWindSpeed: typeof d.minWindSpeed === "number" ? d.minWindSpeed : null,
          weatherCodes: Array.isArray(d.weatherCodes) ? d.weatherCodes.map(Number) : [],
          priority: typeof d.priority === "number" ? d.priority : 50,
          active: true,
        };
      })
      .sort((a, b) => b.priority - a.priority);

    const supportArticles: SupportFaqItem[] = (supportSnap?.docs ?? [])
      .filter((doc) => doc.data().visible !== false)
      .map((doc) => {
        const d = doc.data();
        return {
          id: doc.id,
          category: String(d.category ?? "other"),
          categoryVi: String(d.categoryVi ?? "Hỗ trợ chung"),
          categoryEn: String(d.categoryEn ?? "General Support"),
          questionVi: String(d.questionVi ?? ""),
          questionEn: String(d.questionEn ?? ""),
          answerVi: String(d.answerVi ?? ""),
          answerEn: String(d.answerEn ?? ""),
          order: Number(d.order ?? 0),
        };
      })
      .filter((s) => s.questionVi.trim().length > 0)
      .sort((a, b) => a.order - b.order);

    const notifications: SystemNotificationItem[] = (campaignSnap?.docs ?? [])
      .filter((doc) => doc.data().status === "sent")
      .map((doc) => {
        const d = doc.data();
        return {
          id: doc.id,
          title: String(d.title ?? d.name ?? "Thông báo Floria"),
          body: String(d.body ?? ""),
          image: typeof d.image === "string" && d.image ? d.image : undefined,
          deepLink: typeof d.deepLink === "string" ? d.deepLink : undefined,
          sentAt: toIsoString(d.sentAt ?? d.scheduledAt ?? d.createdAt),
        };
      })
      .filter((n) => n.title.trim().length > 0)
      .sort((a, b) => b.sentAt.localeCompare(a.sentAt))
      .slice(0, 8);

    return NextResponse.json({
      source: "firestore",
      products,
      handbook,
      vouchers,
      reviews,
      plantsInfo,
      diseasesInfo,
      weatherWidgets,
      weatherRules,
      supportArticles,
      notifications,
    });
  } catch (err) {
    return NextResponse.json(
      { error: (err as Error).message || "Không thể tải dữ liệu từ Firestore" },
      { status: 500 },
    );
  }
}
