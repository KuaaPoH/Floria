import type { ReactNode } from "react";
import { UserAppShell } from "@/components/layout/UserAppShell";

export default function PublicLayout({ children }: { children: ReactNode }) {
  return <UserAppShell>{children}</UserAppShell>;
}
