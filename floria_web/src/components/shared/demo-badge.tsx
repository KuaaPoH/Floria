import { FlaskConical } from "lucide-react";
import { Badge } from "@/components/ui/badge";

/** Marks figures and operations that are simulated in demo mode. */
export function DemoBadge({ label = "Demo · Mô phỏng" }: { label?: string }) {
  return (
    <Badge variant="demo" title="Dữ liệu mô phỏng — chưa kết nối hệ thống thật">
      <FlaskConical className="size-3" />
      {label}
    </Badge>
  );
}
