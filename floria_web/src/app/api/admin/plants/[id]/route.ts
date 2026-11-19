import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getSpeciesClasses } from "@/lib/server/ai-labels";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { mapPlantDoc } from "../route";
import type { Plant } from "@/types";

export async function GET(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await verifyAdminRequest(req);
    const { id } = await params;
    const docId = decodeURIComponent(id);
    const doc = await getAdminDb().collection("plants_info").doc(docId).get();
    if (!doc.exists) {
      return NextResponse.json({ error: "Không tìm thấy loài cây" }, { status: 404 });
    }
    const species = getSpeciesClasses();
    const speciesIndex = new Map(species.map((c) => [c.name.toLowerCase(), c]));
    return NextResponse.json(mapPlantDoc(doc.id, doc.data() ?? {}, speciesIndex));
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tải chi tiết cây" }, { status: 500 });
  }
}

export async function PATCH(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await verifyAdminRequest(req);
    const { id } = await params;
    const docId = decodeURIComponent(id);
    const patch = (await req.json()) as Partial<Plant>;

    const update: Record<string, unknown> = { updatedAt: new Date().toISOString() };
    if (patch.viName !== undefined) update.name_vi = patch.viName;
    if (patch.sciName !== undefined) update.scientific_name = patch.sciName;
    if (patch.enName !== undefined) update.en_name = patch.enName;
    if (patch.category !== undefined) update.plant_type = patch.category;
    if (patch.family !== undefined) update.family = patch.family;
    if (patch.origin !== undefined) update.origin = patch.origin;
    if (patch.identification !== undefined) update.identification = patch.identification;
    if (patch.image !== undefined) {
      update.image = patch.image;
      update.imageUrl = patch.image;
      update.wiki_image = patch.image;
    }
    if (patch.description !== undefined) update.short_desc = patch.description;
    if (patch.wikiDetail !== undefined) update.wiki_detail = patch.wikiDetail;
    if (patch.light !== undefined) update.light = patch.light;
    if (patch.watering !== undefined) update.water_frequency = patch.watering;
    if (patch.soil !== undefined) update.root_type = patch.soil;
    if (patch.humidity !== undefined) update.humidity = patch.humidity;
    if (patch.temperature !== undefined) update.temperature = patch.temperature;
    if (patch.difficulty !== undefined) update.difficulty = patch.difficulty;
    if (patch.placements !== undefined) update.placements = patch.placements;
    if (patch.petToxic !== undefined) update.petToxic = patch.petToxic;
    if (patch.toxicityNote !== undefined) update.toxicity = patch.toxicityNote;
    if (patch.aiClassId !== undefined) update.aiClassId = patch.aiClassId;
    if (patch.aiClassName !== undefined) update.aiClassName = patch.aiClassName;
    if (patch.relatedDiseaseIds !== undefined) update.relatedDiseaseIds = patch.relatedDiseaseIds;
    if (patch.careTips !== undefined) update.careTips = patch.careTips;
    if (patch.status !== undefined) update.status = patch.status;

    const ref = getAdminDb().collection("plants_info").doc(docId);
    await ref.set(update, { merge: true });
    const doc = await ref.get();
    const species = getSpeciesClasses();
    const speciesIndex = new Map(species.map((c) => [c.name.toLowerCase(), c]));
    return NextResponse.json(mapPlantDoc(doc.id, doc.data() ?? {}, speciesIndex));
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể cập nhật loài cây" }, { status: 500 });
  }
}

export async function DELETE(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await verifyAdminRequest(req);
    const { id } = await params;
    await getAdminDb().collection("plants_info").doc(decodeURIComponent(id)).delete();
    return NextResponse.json({ ok: true });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể xoá loài cây" }, { status: 500 });
  }
}
