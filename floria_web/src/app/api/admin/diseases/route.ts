import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getDiseaseClasses } from "@/lib/server/ai-labels";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { toIsoString } from "@/lib/server/firestore-utils";
import type { Disease, Severity } from "@/types";

export function mapSeverity(raw: unknown): Severity {
  const s = String(raw ?? "").toLowerCase();
  if (s === "low" || s === "medium" || s === "high" || s === "critical") return s;
  if (s.includes("nghiêm trọng")) return "critical";
  if (s.includes("nguy hiểm") || s.includes("cao")) return "high";
  if (s.includes("cảnh báo") || s.includes("trung bình")) return "medium";
  return "low";
}

export function severityToAppLabel(sev: Severity): string {
  switch (sev) {
    case "critical":
      return "Nghiêm trọng";
    case "high":
      return "Nguy hiểm";
    case "medium":
      return "Cảnh báo";
    default:
      return "Bình thường";
  }
}

export function mapDiseaseDoc(
  id: string,
  d: Record<string, unknown>,
  diseaseIndex: Map<string, { id: number; name: string }>,
): Disease {
  const matched = diseaseIndex.get(id.toLowerCase()) ?? null;
  const pathogen = String(d.pathogen ?? d.agent ?? "");
  const category =
    typeof d.category === "string" && d.category.trim()
      ? d.category.trim()
      : /nấm/i.test(pathogen)
        ? "Bệnh nấm"
        : /vi khuẩn/i.test(pathogen)
          ? "Vi khuẩn"
          : "Sinh lý";

  const severity = mapSeverity(d.severity);
  const severityLabel =
    typeof d.severity === "string" && d.severity.trim()
      ? d.severity.trim()
      : severityToAppLabel(severity);

  const mechanism = String(d.mechanism ?? "");
  const favorableConditions = String(d.favorableConditions ?? "");

  const symptoms = Array.isArray(d.symptoms)
    ? d.symptoms.map((x) => String(x))
    : [mechanism, favorableConditions].filter((x) => x.trim().length > 0);

  const treatment = Array.isArray(d.treatment)
    ? d.treatment.map((x) => String(x))
    : Array.isArray(d.treatmentSteps)
      ? d.treatmentSteps.map((x) => String(x))
      : [];

  const prevention = Array.isArray(d.prevention)
    ? d.prevention.map((x) => String(x))
    : typeof d.prevention === "string" && d.prevention.trim()
      ? [d.prevention.trim()]
      : [];

  return {
    id,
    name: String(d.nameVi ?? d.name ?? id),
    enName: String(d.nameEn ?? d.enName ?? id.replaceAll("_", " ")),
    category,
    agent: pathogen || "Không có tác nhân gây hại",
    severity,
    severityLabel,
    mechanism,
    favorableConditions,
    symptoms,
    treatment,
    prevention,
    images: Array.isArray(d.images) ? d.images.map((x) => String(x)).filter(Boolean) : [],
    aiClassId: typeof d.aiClassId === "number" ? d.aiClassId : (matched?.id ?? null),
    aiClassName: String(d.aiClassName ?? matched?.name ?? id),
    updatedAt: toIsoString(d.updatedAt),
  };
}

export async function GET(req: Request) {
  try {
    await verifyAdminRequest(req);
    const snap = await getAdminDb().collection("DiseasesInfo").get();
    const classes = getDiseaseClasses();
    const index = new Map(classes.map((c) => [c.name.toLowerCase(), c]));

    const rows = snap.docs
      .map((doc) => mapDiseaseDoc(doc.id, doc.data(), index))
      .sort((a, b) => {
        const ia = a.aiClassId ?? Number.MAX_SAFE_INTEGER;
        const ib = b.aiClassId ?? Number.MAX_SAFE_INTEGER;
        if (ia !== ib) return ia - ib;
        return a.name.localeCompare(b.name, "vi");
      });

    return NextResponse.json(rows);
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tải từ điển bệnh" }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    await verifyAdminRequest(req);
    const body = (await req.json()) as Partial<Disease>;
    if (!body.name?.trim()) {
      return NextResponse.json({ error: "Thiếu tên bệnh" }, { status: 400 });
    }
    const docId = (body.aiClassName || body.enName || body.id || body.name).trim().replaceAll(" ", "_");
    const sevLabel = body.severityLabel?.trim() || severityToAppLabel(body.severity ?? "medium");
    const now = new Date().toISOString();

    const payload = {
      nameVi: body.name.trim(),
      nameEn: body.enName?.trim() || docId.replaceAll("_", " "),
      category: body.category?.trim() || "Bệnh nấm",
      pathogen: body.agent?.trim() || "",
      severity: sevLabel,
      mechanism: body.mechanism?.trim() || body.symptoms?.[0] || "",
      favorableConditions: body.favorableConditions?.trim() || body.symptoms?.[1] || "",
      symptoms: body.symptoms ?? [],
      treatment: body.treatment ?? [],
      prevention: (body.prevention ?? []).join("\n"),
      images: body.images ?? [],
      aiClassId: body.aiClassId ?? null,
      aiClassName: body.aiClassName ?? docId,
      updatedAt: now,
    };

    await getAdminDb().collection("DiseasesInfo").doc(docId).set(payload, { merge: true });
    const classes = getDiseaseClasses();
    const index = new Map(classes.map((c) => [c.name.toLowerCase(), c]));
    return NextResponse.json(mapDiseaseDoc(docId, payload, index), { status: 201 });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tạo bệnh mới" }, { status: 500 });
  }
}
