"use client";

import { useState } from "react";
import { Plus, Sprout } from "lucide-react";
import { GardenCard } from "@/components/botanical";
import { PageContainer, PageHeader } from "@/components/layout/PageContainer";
import { CardGridSkeleton, EmptyState, ErrorState } from "@/components/layout/states";
import { Button } from "@/components/ui/button";
import { AddPlantWizard } from "@/features/garden/AddPlantWizard";
import { GardenFormDialog } from "@/features/garden/GardenFormDialog";
import { computeEffectiveStatus, gardenStats } from "@/features/garden/logic";
import { useGardens, usePlants, useSchedules } from "@/hooks/queries";

export default function GardensPage() {
  const gardensQ = useGardens();
  const { data: plants = [] } = usePlants();
  const { data: schedules = [] } = useSchedules();
  const [createOpen, setCreateOpen] = useState(false);
  const [addOpen, setAddOpen] = useState(false);
  const stats = gardenStats(plants, schedules);

  return (
    <PageContainer>
      <PageHeader
        eyebrow="Khu vườn"
        title="Những khu vườn của bạn"
        description="Mỗi khu vườn có môi trường và ánh sáng riêng — Floria dùng chúng để gợi ý vị trí và lịch chăm sóc phù hợp."
        actions={
          <>
            <Button variant="outline" onClick={() => setAddOpen(true)} disabled={!gardensQ.data?.length}><Sprout /> Thêm cây</Button>
            <Button onClick={() => setCreateOpen(true)}><Plus /> Tạo khu vườn</Button>
          </>
        }
      />
      <div className="mb-8 grid grid-cols-3 gap-3 sm:max-w-lg">
        {[
          { v: stats.caring, l: "Đang chăm" },
          { v: stats.needWater, l: "Cần tưới" },
          { v: stats.healthy, l: "Khỏe mạnh" },
        ].map((s) => (
          <div key={s.l} className="rounded-2xl border bg-card px-4 py-3 shadow-soft">
            <p className="text-2xl font-bold text-forest dark:text-foreground">{s.v}</p>
            <p className="text-xs text-muted-foreground">{s.l}</p>
          </div>
        ))}
      </div>
      {gardensQ.isError ? (
        <ErrorState onRetry={() => gardensQ.refetch()} />
      ) : gardensQ.isLoading ? (
        <CardGridSkeleton count={3} />
      ) : !gardensQ.data?.length ? (
        <EmptyState title="Bạn chưa có khu vườn nào" description="Tạo khu vườn đầu tiên — ví dụ phòng khách, ban công hay sân thượng." action={<Button onClick={() => setCreateOpen(true)}><Plus /> Tạo khu vườn</Button>} />
      ) : (
        <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {gardensQ.data.map((g) => {
            const gp = plants.filter((p) => p.gardenId === g.id);
            return <GardenCard key={g.id} garden={g} plantCount={gp.length} attention={gp.filter((p) => computeEffectiveStatus(p, schedules) !== "healthy").length} />;
          })}
          <button onClick={() => setCreateOpen(true)} className="flex aspect-[16/11] flex-col items-center justify-center gap-3 rounded-3xl border-2 border-dashed border-sage/70 text-muted-foreground transition-colors hover:border-leaf hover:bg-mint/40 hover:text-leaf">
            <Plus className="size-7" /><span className="font-semibold">Khu vườn mới</span>
          </button>
        </div>
      )}
      <GardenFormDialog open={createOpen} onOpenChange={setCreateOpen} />
      <AddPlantWizard open={addOpen} onOpenChange={setAddOpen} />
    </PageContainer>
  );
}
