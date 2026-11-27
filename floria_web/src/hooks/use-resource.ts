"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";

import type { ResourceService } from "@/services/resource";
import { logAudit } from "@/services/audit.service";

export function useResourceList<T extends { id: string }>(service: ResourceService<T>) {
  return useQuery({ queryKey: [service.key], queryFn: () => service.list() });
}

export function useResourceItem<T extends { id: string }>(service: ResourceService<T>, id: string) {
  return useQuery({ queryKey: [service.key, id], queryFn: () => service.get(id) });
}

interface MutationOpts {
  entity: string;
  silent?: boolean;
}

/** CRUD mutations that refresh the list, toast the result and append an audit log entry. */
export function useResourceMutations<T extends { id: string }>(
  service: ResourceService<T>,
  { entity, silent }: MutationOpts,
) {
  const qc = useQueryClient();
  const invalidate = () => qc.invalidateQueries({ queryKey: [service.key] });

  const create = useMutation({
    mutationFn: (item: T) => service.create(item),
    onSuccess: (item) => {
      invalidate();
      logAudit({ action: "Tạo mới", target: `${entity} · ${labelOf(item)}`, before: "—", after: labelOf(item) });
      if (!silent) toast.success(`Đã tạo ${entity.toLowerCase()}`);
    },
    onError: (e: Error) => toast.error(e.message),
  });

  const update = useMutation({
    mutationFn: ({ id, patch, before }: { id: string; patch: Partial<T>; before?: string; label?: string }) =>
      service.update(id, patch),
    onSuccess: (item, vars) => {
      qc.setQueryData<T[]>([service.key], (old) =>
        Array.isArray(old) ? old.map((x) => (x.id === item.id ? { ...x, ...item } : x)) : old,
      );
      invalidate();
      logAudit({
        action: "Cập nhật",
        target: `${entity} · ${vars.label ?? labelOf(item)}`,
        before: vars.before ?? "—",
        after: summarize(vars.patch),
      });
      if (!silent) toast.success(`Đã cập nhật ${entity.toLowerCase()}`);
    },
    onError: (e: Error) => toast.error(e.message),
  });

  const remove = useMutation({
    mutationFn: ({ id }: { id: string; label?: string }) => service.remove(id),
    onSuccess: (_r, vars) => {
      invalidate();
      logAudit({ action: "Xoá", target: `${entity} · ${vars.label ?? vars.id}`, before: vars.label ?? vars.id, after: "—" });
      if (!silent) toast.success(`Đã xoá ${entity.toLowerCase()}`);
    },
    onError: (e: Error) => toast.error(e.message),
  });

  return { create, update, remove };
}

function labelOf(item: unknown): string {
  const o = item as Record<string, unknown>;
  return String(o.name ?? o.title ?? o.code ?? o.fullName ?? o.viName ?? o.id ?? "");
}

function summarize(patch: unknown): string {
  return Object.entries(patch as Record<string, unknown>)
    .slice(0, 3)
    .map(([k, v]) => `${k}: ${typeof v === "object" ? "…" : String(v)}`)
    .join(", ");
}
