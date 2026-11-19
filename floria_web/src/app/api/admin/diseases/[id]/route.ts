import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getDiseaseClasses } from "@/lib/server/ai-labels";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { mapDiseaseDoc, severityToAppLabel } from "../route";
import type { Disease } from "@/types";

export async function PATCH(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await verifyAdminRequest(req);
    const { id } = await params;
    const docId = decodeURIComponent(id);
    const patch = (await req.json()) as Partial<Disease>;

    const update: Record<string, unknown> = { updatedAt: new Date().toISOString() };
    if (patch.name !== undefined) update.nameVi = patch.name;
    if (patch.enName !== undefined) update.nameEn = patch.enName;
    if (patch.category !== undefined) update.category = patch.category;
    if (patch.agent !== undefined) update.pathogen = patch.agent;
    if (patch.severityLabel !== undefined) {
      update.severity = patch.severityLabel;
    } else if (patch.severity !== undefined) {
      update.severity = severityToAppLabel(patch.severity);
    }
    if (patch.mechanism !== undefined) update.mechanism = patch.mechanism;
    if (patch.favorableConditions !== undefined) update.favorableConditions = patch.favorableConditions;
    if (patch.symptoms !== undefined) update.symptoms = patch.symptoms;
    if (patch.treatment !== undefined) update.treatment = patch.treatment;
    if (patch.prevention !== undefined) update.prevention = patch.prevention.join("\n");
    if (patch.images !== undefined) update.images = patch.images;
    if (patch.aiClassId !== undefined) update.aiClassId = patch.aiClassId;
    if (patch.aiClassName !== undefined) update.aiClassName = patch.aiClassName;

    const ref = getAdminDb().collection("DiseasesInfo").doc(docId);
    await ref.set(update, { merge: true });
    const doc = await ref.get();
    const classes = getDiseaseClasses();
    const index = new Map(classes.map((c) => [c.name.toLowerCase(), c]));
    return NextResponse.json(mapDiseaseDoc(doc.id, doc.data() ?? {}, index));
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể cập nhật bệnh" }, { status: 500 });
  }
}

export async function DELETE(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await verifyAdminRequest(req);
    const { id } = await params;
    await getAdminDb().collection("DiseasesInfo").doc(decodeURIComponent(id)).delete();
    return NextResponse.json({ ok: true });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể xoá bệnh" }, { status: 500 });
  }
}
