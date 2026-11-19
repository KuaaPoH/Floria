"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import type { SingletonService } from "@/services/singleton";

export function useSingleton<T>(service: SingletonService<T>) {
  const qc = useQueryClient();
  const query = useQuery({ queryKey: [service.key], queryFn: () => service.get() });
  const save = useMutation({
    mutationFn: (value: T) => service.save(value),
    onSuccess: (value) => qc.setQueryData([service.key], value),
    onError: (e: Error) => toast.error(e.message),
  });
  return { ...query, save };
}
