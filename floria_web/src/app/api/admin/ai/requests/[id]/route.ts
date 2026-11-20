import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";

export async function PATCH(
  req: Request,
  context: { params: Promise<{ id: string }> },
) {
  try {
    const admin = await verifyAdminRequest(req);
    const { id } = await context.params;
    const body = (await req.json()) as {
      status?: "pending" | "approved" | "rejected";
      finalLabel?: string;
      adminNotes?: string;
    };

    const ref = getAdminDb().collection("PlantRequests").doc(id);
    const snap = await ref.get();
    if (!snap.exists) {
      return NextResponse.json({ error: "Không tìm thấy yêu cầu này." }, { status: 404 });
    }

    const patch: Record<string, unknown> = {
      reviewedBy: admin.name,
      reviewedAt: new Date().toISOString(),
    };
    if (body.status && ["pending", "approved", "rejected"].includes(body.status)) {
      patch.status = body.status;
    }
    if (typeof body.finalLabel === "string") {
      patch.finalLabel = body.finalLabel.trim();
    }
    if (typeof body.adminNotes === "string") {
      patch.adminNotes = body.adminNotes.trim();
    }

    await ref.update(patch);
    return NextResponse.json({ id, ...patch });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    const msg = err instanceof Error ? err.message : "Lỗi cập nhật PlantRequest";
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
