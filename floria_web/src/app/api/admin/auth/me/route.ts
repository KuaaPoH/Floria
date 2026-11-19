import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";

export async function GET(req: Request) {
  try {
    const admin = await verifyAdminRequest(req);
    return NextResponse.json(admin);
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    const message = err instanceof Error ? err.message : "Lỗi xác thực máy chủ";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
