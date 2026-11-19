import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getDiseaseClasses, getSpeciesClasses } from "@/lib/server/ai-labels";

export async function GET(req: Request) {
  try {
    await verifyAdminRequest(req);
    return NextResponse.json({
      species: getSpeciesClasses(),
      diseases: getDiseaseClasses(),
    });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tải danh sách nhãn AI" }, { status: 500 });
  }
}
