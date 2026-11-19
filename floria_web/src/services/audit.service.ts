import type { AuditLog } from "@/types";
import { seedAuditLogs } from "@/mocks/system";
import { uid } from "@/lib/id";
import { useAuthStore } from "@/stores/auth-store";
import { createResourceService } from "./resource";

export const auditService = createResourceService<AuditLog>("audit-logs", seedAuditLogs, { forceMock: true });

/** Append an audit trail entry for the signed-in administrator. Fire-and-forget. */
export function logAudit(entry: { action: string; target: string; before: string; after: string }) {
  const session = useAuthStore.getState().session;
  void auditService.create({
    id: uid("aud"),
    admin: session?.name ?? "Hệ thống",
    role: session?.role ?? "super_admin",
    at: new Date().toISOString(),
    ip: "127.0.0.1",
    ...entry,
  });
}
