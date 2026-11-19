import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getSpeciesClasses } from "@/lib/server/ai-labels";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { toIsoString } from "@/lib/server/firestore-utils";
import type { Plant } from "@/types";

export function mapPlantDoc(
  id: string,
  d: Record<string, unknown>,
  speciesIndex: Map<string, { id: number; name: string }>,
): Plant {
  const sciName = String(d.scientific_name ?? d.sciName ?? id);
  const matched =
    speciesIndex.get(id.toLowerCase()) ??
    speciesIndex.get(sciName.toLowerCase()) ??
    null;

  const aiClassId = typeof d.aiClassId === "number" ? d.aiClassId : (matched?.id ?? null);
  const aiClassName = String(d.aiClassName ?? matched?.name ?? "");
  const toxicityStr = String(d.toxicity ?? d.toxicityNote ?? "");
  const petToxic =
    typeof d.petToxic === "boolean"
      ? d.petToxic
      : Boolean(toxicityStr && !/không độc|an toàn/i.test(toxicityStr));

  const careTips = Array.isArray(d.careTips)
    ? d.careTips.map((x) => String(x))
    : d.difficulty
      ? [String(d.difficulty)]
      : [];

  return {
    id,
    viName: String(d.name_vi ?? d.viName ?? id),
    sciName,
    enName: String(d.en_name ?? d.enName ?? sciName),
    category: String(d.plant_type ?? d.category ?? "Cây cảnh"),
    family: String(d.family ?? ""),
    origin: String(d.origin ?? ""),
    identification: String(d.identification ?? ""),
    image: String(d.image ?? d.imageUrl ?? d.wiki_image ?? ""),
    description: String(d.short_desc ?? d.description ?? ""),
    wikiDetail: String(d.wiki_detail ?? ""),
    light: String(d.light ?? ""),
    watering: String(d.water_frequency ?? d.watering ?? ""),
    soil: String(d.root_type ?? d.soil ?? ""),
    humidity: String(d.humidity ?? ""),
    temperature: String(d.temperature ?? ""),
    difficulty: String(d.difficulty ?? ""),
    placements: Array.isArray(d.placements) ? d.placements.map((x) => String(x)) : [],
    petToxic,
    toxicityNote: toxicityStr,
    aiClassId,
    aiClassName,
    relatedDiseaseIds: Array.isArray(d.relatedDiseaseIds) ? d.relatedDiseaseIds.map((x) => String(x)) : [],
    careTips,
    status: d.status === "draft" ? "draft" : "published",
    updatedAt: toIsoString(d.updatedAt),
  };
}

export async function GET(req: Request) {
  try {
    await verifyAdminRequest(req);
    const db = getAdminDb();
    const snap = await db.collection("plants_info").get();
    const species = getSpeciesClasses();
    const speciesIndex = new Map(species.map((c) => [c.name.toLowerCase(), c]));

    const plants = snap.docs
      .map((doc) => mapPlantDoc(doc.id, doc.data(), speciesIndex))
      .sort((a, b) => {
        const ia = a.aiClassId ?? Number.MAX_SAFE_INTEGER;
        const ib = b.aiClassId ?? Number.MAX_SAFE_INTEGER;
        if (ia !== ib) return ia - ib;
        return a.viName.localeCompare(b.viName, "vi");
      });

    return NextResponse.json(plants);
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tải từ điển cây" }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    await verifyAdminRequest(req);
    const body = (await req.json()) as Partial<Plant>;
    const sciName = (body.sciName ?? "").trim();
    const docId = (sciName || body.id || "").trim();
    if (!docId || !body.viName?.trim()) {
      return NextResponse.json({ error: "Thiếu tên tiếng Việt hoặc tên khoa học" }, { status: 400 });
    }

    const db = getAdminDb();
    const now = new Date().toISOString();
    const payload = {
      name_vi: body.viName.trim(),
      scientific_name: sciName || docId,
      en_name: body.enName?.trim() || sciName || docId,
      plant_type: body.category?.trim() || "Cây cảnh",
      family: body.family?.trim() || "",
      origin: body.origin?.trim() || "",
      identification: body.identification?.trim() || "",
      image: body.image?.trim() || "",
      imageUrl: body.image?.trim() || "",
      wiki_image: body.image?.trim() || "",
      short_desc: body.description?.trim() || "",
      wiki_detail: body.wikiDetail?.trim() || "",
      light: body.light?.trim() || "",
      water_frequency: body.watering?.trim() || "",
      root_type: body.soil?.trim() || "",
      humidity: body.humidity?.trim() || "",
      temperature: body.temperature?.trim() || "",
      difficulty: body.difficulty?.trim() || "",
      placements: body.placements ?? [],
      petToxic: Boolean(body.petToxic),
      toxicity: body.toxicityNote?.trim() || "",
      aiClassId: body.aiClassId ?? null,
      aiClassName: body.aiClassName ?? "",
      relatedDiseaseIds: body.relatedDiseaseIds ?? [],
      careTips: body.careTips ?? [],
      status: body.status === "draft" ? "draft" : "published",
      updatedAt: now,
    };

    await db.collection("plants_info").doc(docId).set(payload, { merge: true });
    const species = getSpeciesClasses();
    const speciesIndex = new Map(species.map((c) => [c.name.toLowerCase(), c]));
    return NextResponse.json(mapPlantDoc(docId, payload, speciesIndex), { status: 201 });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tạo loài cây mới" }, { status: 500 });
  }
}
