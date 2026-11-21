import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { DEFAULT_PERMISSIONS, MODULES, type ModuleId, type PermAction, type PermissionMatrix } from "@/lib/rbac";
import type { RoleId } from "@/types";

const CONFIG_DOC_PATH = "SystemConfig";
const RBAC_DOC_ID = "rbac_matrix";
const ROLES_LIST: RoleId[] = ["super_admin", "botanist", "operations"];

function sanitizeMatrix(raw: unknown): PermissionMatrix {
  const input = (raw && typeof raw === "object" ? raw : {}) as Record<string, Record<string, unknown>>;
  const result = structuredClone(DEFAULT_PERMISSIONS);

  for (const role of ROLES_LIST) {
    if (role === "super_admin") {
      result.super_admin = structuredClone(DEFAULT_PERMISSIONS.super_admin);
      continue;
    }
    const roleObj = input[role];
    if (!roleObj || typeof roleObj !== "object") continue;

    for (const mod of MODULES) {
      const mId = mod.id as ModuleId;
      const acts = roleObj[mId];
      if (Array.isArray(acts)) {
        result[role][mId] = acts.filter((a): a is PermAction => typeof a === "string");
      }
    }
  }
  return result;
}

export async function GET(req: Request) {
  try {
    await verifyAdminRequest(req);
    const snap = await getAdminDb().collection(CONFIG_DOC_PATH).doc(RBAC_DOC_ID).get();
    if (!snap.exists) {
      return NextResponse.json(DEFAULT_PERMISSIONS);
    }
    const data = snap.data() ?? {};
    return NextResponse.json(sanitizeMatrix(data.matrix ?? data));
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tải ma trận phân quyền" }, { status: 500 });
  }
}

export async function PUT(req: Request) {
  try {
    const current = await verifyAdminRequest(req);
    if (current.role !== "super_admin") {
      return NextResponse.json({ error: "Chỉ Super Admin mới được cập nhật ma trận phân quyền" }, { status: 403 });
    }

    const body = (await req.json()) as { matrix?: unknown };
    const matrix = sanitizeMatrix(body.matrix ?? body);

    await getAdminDb().collection(CONFIG_DOC_PATH).doc(RBAC_DOC_ID).set(
      {
        matrix,
        updatedAt: new Date().toISOString(),
        updatedBy: current.email || current.name,
      },
      { merge: true },
    );

    return NextResponse.json(matrix);
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể lưu ma trận phân quyền" }, { status: 500 });
  }
}
