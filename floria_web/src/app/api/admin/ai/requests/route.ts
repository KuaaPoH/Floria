import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { toIsoString } from "@/lib/server/firestore-utils";

export interface PlantRequestItem {
  id: string;
  userId: string;
  userEmail: string;
  userName: string;
  reportType: string;
  suggestedName: string;
  note: string;
  predictedLabel: string;
  predictedNameVi: string;
  confidence: number | null;
  isValidPlant: boolean;
  isDiseaseScan: boolean;
  imageUrl: string;
  status: "pending" | "approved" | "rejected";
  finalLabel?: string;
  adminNotes?: string;
  reviewedBy?: string;
  reviewedAt?: string;
  createdAt: string;
}

export async function GET(req: Request) {
  try {
    await verifyAdminRequest(req);
    const snap = await getAdminDb()
      .collection("PlantRequests")
      .orderBy("createdAt", "desc")
      .limit(120)
      .get();

    const items: PlantRequestItem[] = snap.docs.map((doc) => {
      const d = doc.data() ?? {};
      const statusRaw = String(d.status ?? "pending");
      const status: PlantRequestItem["status"] =
        statusRaw === "approved" || statusRaw === "rejected" ? statusRaw : "pending";

      return {
        id: doc.id,
        userId: String(d.userId ?? ""),
        userEmail: String(d.userEmail ?? ""),
        userName: String(d.userName || d.userEmail || "Người dùng Floria"),
        reportType: String(d.reportType ?? "missing_plant"),
        suggestedName: String(d.suggestedName ?? ""),
        note: String(d.note ?? ""),
        predictedLabel: String(d.predictedLabel ?? ""),
        predictedNameVi: String(d.predictedNameVi ?? ""),
        confidence: typeof d.confidence === "number" ? d.confidence : null,
        isValidPlant: d.isValidPlant !== false,
        isDiseaseScan: Boolean(d.isDiseaseScan),
        imageUrl: String(d.imageUrl ?? ""),
        status,
        finalLabel: typeof d.finalLabel === "string" ? d.finalLabel : undefined,
        adminNotes: typeof d.adminNotes === "string" ? d.adminNotes : undefined,
        reviewedBy: typeof d.reviewedBy === "string" ? d.reviewedBy : undefined,
        reviewedAt: d.reviewedAt ? toIsoString(d.reviewedAt) : undefined,
        createdAt:
          typeof d.createdAtIso === "string" && d.createdAtIso
            ? d.createdAtIso
            : toIsoString(d.createdAt),
      };
    });

    return NextResponse.json(items);
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    const msg = err instanceof Error ? err.message : "Lỗi tải danh sách PlantRequests";
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
