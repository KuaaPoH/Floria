"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { useSearchParams } from "next/navigation";
import type { ColumnDef } from "@tanstack/react-table";
import { Flower2, LayoutGrid, List, Pencil, Plus, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group";
import { PageHeader } from "@/components/shared/page-header";
import { DataTable } from "@/components/shared/data-table";
import { SearchInput } from "@/components/shared/search-input";
import { FilterSelect } from "@/components/shared/filter-select";
import { SmartImage } from "@/components/shared/smart-image";
import { StatusBadge } from "@/components/shared/status-badge";
import { ConfirmDialog } from "@/components/shared/confirm-dialog";
import { CardGridSkeleton, EmptyState } from "@/components/shared/states";
import { PlantFormDialog } from "@/features/botanical/plant-form";
import { useResourceList, useResourceMutations } from "@/hooks/use-resource";
import { usePermission } from "@/stores/rbac-store";
import { plantsService } from "@/services";
import { PLANT_CATEGORIES } from "@/mocks/plants";
import { formatDate } from "@/lib/format";
import type { Plant } from "@/types";

const PAGE = 8;

export default function PlantsPage() {
  const searchParams = useSearchParams();
  const q = searchParams.get("q") ?? "";
  const list = useResourceList(plantsService);
  const { create, update, remove } = useResourceMutations(plantsService, { entity: "Cây" });
  const canCreate = usePermission("botanical", "create");
  const canEdit = usePermission("botanical", "edit");
  const canDelete = usePermission("botanical", "delete");
  const [view, setView] = useState<"grid" | "table">("grid");
  const [search, setSearch] = useState(q);
  const [cat, setCat] = useState("all");
  const [page, setPage] = useState(0);
  const [editing, setEditing] = useState<Plant | null | undefined>(undefined);
  const [del, setDel] = useState<Plant | null>(null);

  useEffect(() => {
    if (q) setSearch(q);
  }, [q]);

  const rows = useMemo(() => {
    const s = search.toLowerCase();
    return (list.data ?? []).filter(
      (p) => (!s || [p.viName, p.sciName, p.enName].some((x) => x.toLowerCase().includes(s))) && (cat === "all" || p.category === cat),
    );
  }, [list.data, search, cat]);
  const pages = Math.max(1, Math.ceil(rows.length / PAGE));
  const pageRows = rows.slice(page * PAGE, page * PAGE + PAGE);

  function RowActions({ p }: { p: Plant }) {
    return (
      <div className="flex justify-end gap-1">
        {canEdit && (
          <Button size="icon-sm" variant="ghost" onClick={() => setEditing(p)} aria-label="Sửa">
            <Pencil />
          </Button>
        )}
        {canDelete && (
          <Button size="icon-sm" variant="ghost" className="text-danger" onClick={() => setDel(p)} aria-label="Xoá">
            <Trash2 />
          </Button>
        )}
      </div>
    );
  }

  const columns: ColumnDef<Plant, unknown>[] = [
    {
      accessorKey: "viName",
      header: "Cây",
      cell: ({ row }) => (
        <Link href={`/admin/plants/${encodeURIComponent(row.original.id)}`} className="flex items-center gap-3">
          <SmartImage
            src={row.original.image}
            alt={row.original.viName}
            className="size-10 shrink-0 rounded-lg border"
            fallback={
              <span className="grid size-10 shrink-0 place-items-center rounded-lg bg-accent text-forest">
                <Flower2 className="size-4" />
              </span>
            }
          />
          <div>
            <p className="font-medium hover:underline">{row.original.viName}</p>
            <p className="text-xs italic text-muted-foreground">{row.original.sciName}</p>
          </div>
        </Link>
      ),
    },
    { accessorKey: "category", header: "Loại cây" },
    { accessorKey: "watering", header: "Tưới" },
    {
      accessorKey: "aiClassId",
      header: "AI class",
      cell: ({ row }) => (row.original.aiClassId === null ? <StatusBadge status="pending" label="Chưa ánh xạ" /> : <span className="font-mono text-xs">#{row.original.aiClassId} {row.original.aiClassName}</span>),
    },
    { accessorKey: "status", header: "Trạng thái", cell: ({ getValue }) => <StatusBadge status={getValue() as string} /> },
    { id: "a", header: "", enableSorting: false, cell: ({ row }) => <RowActions p={row.original} /> },
  ];

  const categories = useMemo(() => {
    const set = new Set<string>(PLANT_CATEGORIES);
    for (const p of list.data ?? []) {
      if (p.category) set.add(p.category);
    }
    return Array.from(set);
  }, [list.data]);

  const filters = (
    <>
      <SearchInput
        value={search}
        onChange={(v) => {
          setSearch(v);
          setPage(0);
        }}
        placeholder="Tên Việt, khoa học, tiếng Anh…"
      />
      <FilterSelect
        value={cat}
        onChange={(v) => {
          setCat(v);
          setPage(0);
        }}
        allLabel="Mọi danh mục"
        options={categories.map((c) => ({ value: c, label: c }))}
      />
      <ToggleGroup type="single" value={view} onValueChange={(v) => v && setView(v as typeof view)} className="ml-auto rounded-lg border bg-card p-1">
        <ToggleGroupItem value="grid" className="h-8 w-8 p-0" aria-label="Lưới">
          <LayoutGrid className="size-4" />
        </ToggleGroupItem>
        <ToggleGroupItem value="table" className="h-8 w-8 p-0" aria-label="Bảng">
          <List className="size-4" />
        </ToggleGroupItem>
      </ToggleGroup>
    </>
  );

  return (
    <>
      <PageHeader
        title="Từ điển cây"
        description={`${list.data?.length ?? 0} loài cây trong cơ sở dữ liệu Floria (bao gồm mô hình nhận diện & loài bổ sung).`}
        actions={
          canCreate && (
            <Button onClick={() => setEditing(null)}>
              <Plus /> Thêm cây
            </Button>
          )
        }
      />
      {view === "table" ? (
        <DataTable columns={columns} data={rows} loading={list.isLoading} toolbar={filters} />
      ) : (
        <>
          <div className="card-surface mb-4 flex flex-col gap-2 p-3 sm:flex-row sm:flex-wrap sm:items-center">{filters}</div>
          {list.isLoading ? (
            <CardGridSkeleton />
          ) : rows.length === 0 ? (
            <div className="card-surface">
              <EmptyState title="Không tìm thấy cây phù hợp" />
            </div>
          ) : (
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
              {pageRows.map((p) => (
                <div key={p.id} className="card-surface group overflow-hidden">
                  <Link href={`/admin/plants/${encodeURIComponent(p.id)}`} className="block">
                    <div className="relative aspect-[4/3] overflow-hidden bg-surface-2">
                      <SmartImage
                        src={p.image}
                        alt={p.viName}
                        className="size-full transition duration-300 group-hover:scale-105"
                        fallback={
                          <div className="grid size-full place-items-center bg-accent/50 text-forest/70">
                            <Flower2 className="size-10" />
                          </div>
                        }
                      />
                      {p.status === "draft" && (
                        <span className="absolute right-2 top-2">
                          <StatusBadge status="draft" />
                        </span>
                      )}
                    </div>
                    <div className="p-3">
                      <p className="font-semibold">{p.viName}</p>
                      <p className="text-xs italic text-muted-foreground">{p.sciName}</p>
                      <div className="mt-2 flex items-center justify-between text-[11px] text-muted-foreground">
                        <span>{p.category}</span>
                        <span className="font-mono">{p.aiClassId === null ? "—" : `#${p.aiClassId}`}</span>
                      </div>
                    </div>
                  </Link>
                  {(canEdit || canDelete) && (
                    <div className="flex items-center justify-between border-t px-3 py-1.5 text-[11px] text-muted-foreground">
                      <span>Cập nhật {formatDate(p.updatedAt)}</span>
                      <RowActions p={p} />
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
          {pages > 1 && (
            <div className="mt-4 flex items-center justify-center gap-2 text-sm">
              <Button variant="outline" size="sm" disabled={page === 0} onClick={() => setPage(page - 1)}>
                Trước
              </Button>
              <span className="tabular text-muted-foreground">
                {page + 1} / {pages}
              </span>
              <Button variant="outline" size="sm" disabled={page >= pages - 1} onClick={() => setPage(page + 1)}>
                Sau
              </Button>
            </div>
          )}
        </>
      )}
      <PlantFormDialog
        open={editing !== undefined}
        onOpenChange={(o) => !o && setEditing(undefined)}
        plant={editing}
        pending={create.isPending || update.isPending}
        onSubmit={(p) =>
          editing ? update.mutate({ id: p.id, patch: p, label: p.viName }, { onSuccess: () => setEditing(undefined) }) : create.mutate(p, { onSuccess: () => setEditing(undefined) })
        }
      />
      <ConfirmDialog
        open={!!del}
        onOpenChange={(o) => !o && setDel(null)}
        title={`Xoá ${del?.viName}?`}
        description="Bản ghi sẽ bị xoá khỏi từ điển và không còn hiển thị trong ứng dụng."
        tone="danger"
        confirmLabel="Xoá"
        onConfirm={() => del && remove.mutate({ id: del.id, label: del.viName })}
      />
    </>
  );
}
