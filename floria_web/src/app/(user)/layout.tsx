import type { ReactNode } from "react";
import { UserAppShell } from "@/components/layout/UserAppShell";
import { UserAuthGuard } from "@/components/layout/UserAuthGuard";

export default function UserLayout({ children }: { children: ReactNode }) {
  return (
    <UserAppShell>
      <UserAuthGuard>{children}</UserAuthGuard>
    </UserAppShell>
  );
}
