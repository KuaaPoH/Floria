"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { ArrowLeft, MoreHorizontal, Pencil, Plus, Search, Sun, Trash2 } from "lucide-react";
import { toast } from "sonner";
import { LocationChips, PlantCard } from "@/components/botanical";
import { ConfirmDialog } from "@/components/layout/ConfirmDialog";
import { PageContainer } from "@/components/layout/PageContainer";
import { CardGridSkeleton, EmptyState, ErrorState } from "@/components/layout/states";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { AddPlantWizard } from "@/features/garden/AddPlantWizard";
import { GardenFormDialog } from "@/features/garden/GardenFormDialog";
import { computeEffectiveStatus, locationChips, nextTask, STATUS_PRIORITY, type EffectiveStatusKey } from "@/features/garden/logic";
import { useGardenMutations, useGardens, usePlants, useSchedules, useSpecies } from "@/hooks/queries";
import { useT } from "@/i18n";
import { common } from "@/i18n/common";
import { ENV_LABEL, LIGHT_LABEL, STATUS_LABEL } from "@/i18n/labels";
import { cn } from "@/lib/utils";
import { findPlantInfoOrFallback } from "@/mocks/user/plants-info";

type Sort = "status" | "name" | "newest" | "next";

export default function GardenDetailPage() {
  const { gardenId } = useParams<{ gardenId: string }>();
  const t = useT(common);
  const router = useRouter();
  const gardensQ = useGardens();
  const plantsQ = usePlants();
  useSpecies();
  const { data: schedules = [] } = useSchedules();
  const { remove } = useGardenMutations();
  const [loc, setLoc] = useState<string | null>(null);
  const [q, setQ] = useState("");
  const [health, setHealth] = useState<EffectiveStatusKey | "all">("all");
  const [sort, setSort] = useState<Sort>("status");
  const [editOpen, setEditOpen] = useState(false);
  const [delOpen, setDelOpen] = useState(false);
  const [addOpen, setAddOpen] = useState(false);

  const garden = gardensQ.data?.find((g) => g.id === gardenId);
  const gardenPlants = useMemo(() => (plantsQ.data ?? []).filter((p) => p.gardenId === gardenId), [plantsQ.data, gardenId]);
  const chips = useMemo(() => locationChips(gardenPlants), [gardenPlants]);
  const rows = useMemo(() => {
    const needle = q.trim().toLowerCase();
    return gardenPlants
      .map((p) => ({ p, info: findPlantInfoOrFallback(p.speciesId, p.nickname, p.image), status: computeEffectiveStatus(p, schedules), next: nextTask(p.id, schedules) }))
      .filter((r) => (!loc || r.p.location === loc) && (health === "all" || r.status === health))
      .filter((r) => !needle || [r.p.nickname, r.info?.commonName, r.info?.scientificName, r.p.location].some((x) => x?.toLowerCase().includes(needle)))
      .sort((a, b) => {
        if (sort === "name") return a.p.nickname.localeCompare(b.p.nickname, "vi");
        if (sort === "newest") return b.p.addedAt.localeCompare(a.p.addedAt);
        if (sort === "next") return (a.next?.nextDueAt ?? "9").localeCompare(b.next?.nextDueAt ?? "9");
        return STATUS_PRIORITY.indexOf(a.status) - STATUS_PRIORITY.indexOf(b.status);
      });
  }, [gardenPlants, schedules, loc, health, q, sort]);

  if (gardensQ.isLoading || plantsQ.isLoading) return <PageContainer><CardGridSkeleton /></PageContainer>;
  if (gardensQ.isError) return <PageContainer><ErrorState onRetry={() => gardensQ.refetch()} /></PageContainer>;
  if (!garden) return <PageContainer><EmptyState title="Không tìm thấy khu vườn" description="Khu vườn này không tồn tại hoặc đã bị xóa." action={<Button asChild><Link href="/garden">Về danh sách khu vườn</Link></Button>} /></PageContainer>;

  return (
    <div>
      <section className="relative h-[300px] overflow-hidden md:h-[360px]">
        <img src={garden.coverImage} alt={garden.name} className="absolute inset-0 size-full object-cover" />
        <div className="absolute inset-0 bg-image-scrim" />
        <div className="container-floria relative flex h-full flex-col justify-between py-6 text-forest-foreground">
          <div className="flex justify-between">
            <Button asChild variant="glass" size="sm"><Link href="/garden"><ArrowLeft /> Khu vườn</Link></Button>
            <DropdownMenu>
              <DropdownMenuTrigger asChild><Button variant="glass" size="icon-sm" aria-label="Tùy chọn"><MoreHorizontal /></Button></DropdownMenuTrigger>
              <DropdownMenuContent align="end" className="rounded-xl">
                <DropdownMenuItem onClick={() => setEditOpen(true)}><Pencil /> Chỉnh sửa</DropdownMenuItem>
                <DropdownMenuItem className="text-danger focus:text-danger" onClick={() => setDelOpen(true)}><Trash2 /> Xóa khu vườn</DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
          <div className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
            <div>
              <div className="mb-2 flex gap-1.5">
                <Badge variant="glass">{t(ENV_LABEL[garden.environment])}</Badge>
                <Badge variant="glass"><Sun />{t(LIGHT_LABEL[garden.light])}</Badge>
              </div>
              <h1 className="text-3xl font-bold md:text-5xl">{garden.name}</h1>
              <p className="mt-2 max-w-xl text-forest-foreground/80">{garden.description}</p>
            </div>
            <Button variant="cream" size="lg" onClick={() => setAddOpen(true)}><Plus /> Thêm cây</Button>
          </div>
        </div>
      </section>
      {/* Garden switcher */}
      {(gardensQ.data?.length ?? 0) > 1 && (
        <div className="border-b bg-card/60">
          <div className="container-floria scrollbar-none flex gap-1 overflow-x-auto py-2">
            {gardensQ.data!.map((g) => (
              <Link key={g.id} href={`/garden/${g.id}`} className={cn("shrink-0 rounded-full px-4 py-1.5 text-sm font-medium", g.id === gardenId ? "bg-forest text-forest-foreground" : "text-muted-foreground hover:bg-mint")}>{g.name}</Link>
            ))}
          </div>
        </div>
      )}
      <PageContainer>
        <div className="mb-6 space-y-4">
          <LocationChips chips={chips} value={loc} onChange={setLoc} allLabel="Tất cả" />
          <div className="flex flex-col gap-3 sm:flex-row">
            <div className="relative flex-1">
              <Search className="absolute left-3.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
              <Input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Tìm theo tên cây, loài, vị trí…" className="pl-10" />
            </div>
            <Select value={health} onValueChange={(v) => setHealth(v as EffectiveStatusKey | "all")}>
              <SelectTrigger className="h-11 rounded-[10px] sm:w-48"><SelectValue /></SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Mọi trạng thái</SelectItem>
                {STATUS_PRIORITY.map((s) => <SelectItem key={s} value={s}>{t(STATUS_LABEL[s])}</SelectItem>)}
              </SelectContent>
            </Select>
            <Select value={sort} onValueChange={(v) => setSort(v as Sort)}>
              <SelectTrigger className="h-11 rounded-[10px] sm:w-48"><SelectValue /></SelectTrigger>
              <SelectContent>
                <SelectItem value="status">Ưu tiên cần chăm</SelectItem>
                <SelectItem value="next">Lịch gần nhất</SelectItem>
                <SelectItem value="name">Tên A–Z</SelectItem>
                <SelectItem value="newest">Mới thêm</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>
        {gardenPlants.length === 0 ? (
          <EmptyState title="Khu vườn chưa có cây" description="Thêm cây đầu tiên — Floria sẽ gợi ý vị trí phù hợp với ánh sáng của khu vườn." action={<Button onClick={() => setAddOpen(true)}><Plus /> Thêm cây</Button>} />
        ) : rows.length === 0 ? (
          <EmptyState icon={<Search />} title="Không có cây phù hợp" description="Thử bỏ bớt bộ lọc hoặc đổi từ khóa." action={<Button variant="outline" onClick={() => { setLoc(null); setHealth("all"); setQ(""); }}>Xóa bộ lọc</Button>} />
        ) : (
          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            {rows.map((r) => <PlantCard key={r.p.id} plant={r.p} info={r.info} status={r.status} next={r.next} />)}
          </div>
        )}
      </PageContainer>
      <GardenFormDialog open={editOpen} onOpenChange={setEditOpen} garden={garden} />
      <AddPlantWizard open={addOpen} onOpenChange={setAddOpen} defaultGardenId={garden.id} />
      <ConfirmDialog
        open={delOpen}
        onOpenChange={setDelOpen}
        destructive
        loading={remove.isPending}
        title={`Xóa khu vườn "${garden.name}"?`}
        description={`${gardenPlants.length} cây cùng toàn bộ lịch chăm sóc và nhật ký trong khu vườn sẽ bị xóa vĩnh viễn.`}
        confirmLabel="Xóa khu vườn"
        onConfirm={async () => {
          await remove.mutateAsync(garden.id);
          toast.success("Đã xóa khu vườn");
          router.push("/garden");
        }}
      />
    </div>
  );
}
