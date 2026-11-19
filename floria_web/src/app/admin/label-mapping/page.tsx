"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { AlertTriangle, CheckCircle2, CircleDashed, Copy } from "lucide-react";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { PageHeader } from "@/components/shared/page-header";
import { StatCard } from "@/components/shared/stat-card";
import { StatusBadge } from "@/components/shared/status-badge";
import { FilterSelect } from "@/components/shared/filter-select";
import { TableSkeleton } from "@/components/shared/states";
import { useResourceList } from "@/hooks/use-resource";
import { diseasesService, modelsService, plantsService } from "@/services";
import { apiRequest } from "@/lib/api-client";
import { IS_MOCK } from "@/lib/config";
import { DISEASE_CLASSES, SPECIES_CLASSES } from "@/mocks/ai-classes";
import { buildMapping, orphanRecords } from "@/features/botanical/label-mapping";
import { cn } from "@/lib/utils";

export default function LabelMappingPage() {
  const [model, setModel] = useState<"species" | "disease">("species");
  const [filter, setFilter] = useState("all");
  const plants = useResourceList(plantsService);
  const diseases = useResourceList(diseasesService);
  const models = useResourceList(modelsService);
  const aiClasses = useQuery({
    queryKey: ["ai-classes"],
    queryFn: () =>
      apiRequest<{ species: Array<{ id: number; name: string }>; diseases: Array<{ id: number; name: string }> }>("/ai-classes"),
    enabled: !IS_MOCK,
  });
  const version = models.data?.find((m) => m.kind === model)?.version ?? "—";

  const speciesClasses = IS_MOCK ? SPECIES_CLASSES : (aiClasses.data?.species ?? SPECIES_CLASSES);
  const diseaseClasses = IS_MOCK ? DISEASE_CLASSES : (aiClasses.data?.diseases ?? DISEASE_CLASSES);

  const records = useMemo(
    () =>
      model === "species"
        ? (plants.data ?? []).map((p) => ({ id: p.id, name: p.viName, aiClassId: p.aiClassId }))
        : (diseases.data ?? []).map((d) => ({ id: d.id, name: d.name, aiClassId: d.aiClassId })),
    [model, plants.data, diseases.data],
  );
  const rows = useMemo(() => buildMapping(model === "species" ? speciesClasses : diseaseClasses, records), [model, speciesClasses, diseaseClasses, records]);
  const shown = rows.filter((r) => filter === "all" || r.status === filter);
  const orphans = orphanRecords(records);
  const count = (s: string) => rows.filter((r) => r.status === s).length;
  const loading = plants.isLoading || diseases.isLoading || (!IS_MOCK && aiClasses.isLoading);

  return (
    <>
      <PageHeader title="Ánh xạ nhãn AI" description="Mỗi lớp đầu ra của mô hình cần đúng một bản ghi trong từ điển để ứng dụng hiển thị thông tin chính xác." />
      <Tabs value={model} onValueChange={(v) => setModel(v as typeof model)} className="mb-4">
        <TabsList>
          <TabsTrigger value="species">tf_efficientnetv2_b0 · {speciesClasses.length} loài</TabsTrigger>
          <TabsTrigger value="disease">tf_efficientnetv2_b0_disease · {diseaseClasses.length} lớp</TabsTrigger>
        </TabsList>
      </Tabs>
      <div className="mb-4 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="Đã ánh xạ" value={String(count("mapped"))} icon={CheckCircle2} tone="leaf" />
        <StatCard label="Chưa có bản ghi" value={String(count("unmatched"))} icon={CircleDashed} tone="warning" />
        <StatCard label="Trùng ánh xạ" value={String(count("duplicate"))} icon={Copy} tone="danger" />
        <StatCard label="Bản ghi chưa gán lớp" value={String(orphans.length)} icon={AlertTriangle} tone="info" hint={orphans.map((o) => o.name).join(", ") || "Không có"} />
      </div>
      <div className="card-surface overflow-hidden">
        <div className="flex items-center gap-2 border-b p-3">
          <FilterSelect
            value={filter}
            onChange={setFilter}
            allLabel="Mọi trạng thái"
            options={[
              { value: "mapped", label: "Đã ánh xạ" },
              { value: "unmatched", label: "Chưa có bản ghi" },
              { value: "duplicate", label: "Trùng ánh xạ" },
            ]}
          />
          <span className="ml-auto text-xs text-muted-foreground">Phiên bản mô hình v{version}</span>
        </div>
        {loading ? (
          <TableSkeleton />
        ) : (
          <div className="max-h-[640px] overflow-auto">
            <Table>
              <TableHeader>
                <TableRow className="bg-surface-2/60">
                  <TableHead>Class ID</TableHead>
                  <TableHead>Class name</TableHead>
                  <TableHead>Bản ghi từ điển</TableHead>
                  <TableHead>Trạng thái</TableHead>
                  <TableHead>Phiên bản</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {shown.map((r) => (
                  <TableRow key={r.classId} className={cn(r.status === "duplicate" && "bg-danger-soft/50", r.status === "unmatched" && "bg-warning-soft/40")}>
                    <TableCell className="font-mono text-xs">#{r.classId}</TableCell>
                    <TableCell className="font-mono text-xs">{r.className}</TableCell>
                    <TableCell>
                      {r.records.length === 0 ? (
                        <span className="text-xs text-muted-foreground">—</span>
                      ) : (
                        r.records.map((rec) =>
                          model === "species" ? (
                            <Link key={rec.id} href={`/admin/plants/${encodeURIComponent(rec.id)}`} className="mr-2 text-sm font-medium text-leaf hover:underline">
                              {rec.name}
                            </Link>
                          ) : (
                            <Link key={rec.id} href={`/admin/diseases?q=${encodeURIComponent(rec.name)}`} className="mr-2 text-sm font-medium text-leaf hover:underline">
                              {rec.name}
                            </Link>
                          ),
                        )
                      )}
                    </TableCell>
                    <TableCell>
                      <StatusBadge
                        status={r.status === "mapped" ? "approved" : r.status === "duplicate" ? "rejected" : "pending"}
                        label={r.status === "mapped" ? "Đã ánh xạ" : r.status === "duplicate" ? "Trùng ánh xạ" : "Chưa có bản ghi"}
                      />
                    </TableCell>
                    <TableCell className="text-xs text-muted-foreground">v{version}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </div>
    </>
  );
}
