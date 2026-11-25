"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { assistantService } from "@/services/assistant.service";
import { commerceService, type PlaceOrderInput } from "@/services/commerce.service";
import { fetchUserCatalog, handbookService, regionService, reminderService, supportService } from "@/services/content.service";
import { gardenService, type DiaryInput, type GardenInput, type PlantInput } from "@/services/garden.service";
import { scanService } from "@/services/scan.service";
import { isMock } from "@/config/env";
import { getAllDiseasesInfo } from "@/mocks/user/diseases";
import { useAuth } from "@/stores/auth";
import type { CareSchedule, CareScheduleSuggestion, DiaryNote, ReminderSettings, UserPlant } from "@/types/user";

export const qk = {
  gardens: (u?: string | null) => ["gardens", u] as const,
  plants: (u?: string | null) => ["plants", u] as const,
  schedules: (u?: string | null) => ["schedules", u] as const,
  diary: (plantId?: string) => ["diary", plantId ?? "all"] as const,
  species: ["species"] as const,
  diseases: ["diseases"] as const,
  support: ["support"] as const,
  catalog: ["catalog"] as const,
  scans: (u?: string | null) => ["scans", u] as const,
  scan: (id: string) => ["scan", id] as const,
  products: ["products"] as const,
  product: (id: string) => ["product", id] as const,
  reviews: (id: string) => ["reviews", id] as const,
  vouchers: ["vouchers"] as const,
  orders: (u?: string | null) => ["orders", u] as const,
  addresses: (u?: string | null) => ["addresses", u] as const,
  handbook: ["handbook"] as const,
  article: (slug: string) => ["article", slug] as const,
  reminders: (u?: string | null) => ["reminders", u] as const,
  chatSessions: (u?: string | null) => ["chat-sessions", u] as const,
  chatMessages: (id: string) => ["chat-messages", id] as const,
  provinces: ["provinces"] as const,
  wards: (id: string) => ["wards", id] as const,
};

const errMsg = (e: unknown) => (e instanceof Error ? e.message : "Đã có lỗi xảy ra.");
export const toastError = (e: unknown) => toast.error(errMsg(e));

function useUid() {
  return useAuth((s) => s.user?.uid ?? null);
}

// ---------- Garden ----------
export function useGardens() {
  const u = useUid();
  return useQuery({ queryKey: qk.gardens(u), queryFn: () => gardenService.listGardens(), enabled: !!u });
}
export function usePlants() {
  const u = useUid();
  return useQuery({ queryKey: qk.plants(u), queryFn: () => gardenService.listPlants(), enabled: !!u });
}
export function useSchedules() {
  const u = useUid();
  return useQuery({ queryKey: qk.schedules(u), queryFn: () => gardenService.listSchedules(), enabled: !!u });
}
export function useDiary(plantId?: string) {
  const u = useUid();
  return useQuery({ queryKey: qk.diary(plantId), queryFn: () => gardenService.listDiary(plantId), enabled: !!u });
}

function useInvalidate() {
  const qc = useQueryClient();
  return (...keys: string[]) => Promise.all(keys.map((k) => qc.invalidateQueries({ queryKey: [k] })));
}

export function useGardenMutations() {
  const inv = useInvalidate();
  return {
    create: useMutation({ mutationFn: (i: GardenInput) => gardenService.createGarden(i), onSuccess: () => inv("gardens"), onError: toastError }),
    update: useMutation({ mutationFn: ({ id, patch }: { id: string; patch: Partial<GardenInput> }) => gardenService.updateGarden(id, patch), onSuccess: () => inv("gardens"), onError: toastError }),
    remove: useMutation({ mutationFn: (id: string) => gardenService.deleteGarden(id), onSuccess: () => inv("gardens", "plants", "schedules", "diary"), onError: toastError }),
  };
}

export function usePlantMutations() {
  const inv = useInvalidate();
  return {
    add: useMutation({ mutationFn: (i: PlantInput) => gardenService.addPlant(i), onSuccess: () => inv("plants", "schedules"), onError: toastError }),
    update: useMutation({
      mutationFn: ({ id, patch }: { id: string; patch: Partial<PlantInput & Pick<UserPlant, "healthStatus" | "activeDiseaseId">> }) => gardenService.updatePlant(id, patch),
      onSuccess: () => inv("plants"),
      onError: toastError,
    }),
    remove: useMutation({ mutationFn: (id: string) => gardenService.deletePlant(id), onSuccess: () => inv("plants", "schedules", "diary"), onError: toastError }),
  };
}

export function useScheduleMutations() {
  const qc = useQueryClient();
  const u = useUid();
  const inv = useInvalidate();
  return {
    complete: useMutation({
      mutationFn: (id: string) => gardenService.completeSchedule(id),
      onMutate: async (id) => {
        // optimistic: mark as done so the dashboard checkbox reacts instantly
        await qc.cancelQueries({ queryKey: qk.schedules(u) });
        const prev = qc.getQueryData<CareSchedule[]>(qk.schedules(u));
        if (prev) {
          qc.setQueryData<CareSchedule[]>(qk.schedules(u), prev.map((s) => (s.id === id ? { ...s, nextDueAt: new Date(Date.now() + s.intervalDays * 86400000).toISOString(), lastDoneAt: new Date().toISOString() } : s)));
        }
        return { prev };
      },
      onError: (e, _id, ctx) => {
        if (ctx?.prev) qc.setQueryData(qk.schedules(u), ctx.prev);
        toastError(e);
      },
      onSettled: () => inv("schedules"),
    }),
    update: useMutation({
      mutationFn: ({ id, patch }: { id: string; patch: Partial<Pick<CareSchedule, "intervalDays" | "preferredTime" | "enabled">> }) => gardenService.updateSchedule(id, patch),
      onSuccess: () => inv("schedules"),
      onError: toastError,
    }),
    apply: useMutation({
      mutationFn: ({ plantId, suggestion }: { plantId: string; suggestion: CareScheduleSuggestion }) => gardenService.applySuggestion(plantId, suggestion),
      onSuccess: () => inv("schedules"),
    }),
  };
}

export function useDiaryMutations() {
  const inv = useInvalidate();
  return {
    create: useMutation({ mutationFn: (i: DiaryInput) => gardenService.createDiary(i), onSuccess: () => inv("diary"), onError: toastError }),
    update: useMutation({ mutationFn: ({ id, patch }: { id: string; patch: Partial<Pick<DiaryNote, "content" | "images" | "category">> }) => gardenService.updateDiary(id, patch), onSuccess: () => inv("diary"), onError: toastError }),
    remove: useMutation({ mutationFn: (id: string) => gardenService.deleteDiary(id), onSuccess: () => inv("diary"), onError: toastError }),
  };
}

// ---------- Scans ----------
export function useScanHistory() {
  const u = useUid();
  return useQuery({ queryKey: qk.scans(u), queryFn: () => scanService.listHistory(), enabled: !!u });
}
export function useScan(id: string) {
  return useQuery({ queryKey: qk.scan(id), queryFn: () => scanService.getScan(id) });
}
export function useApplyDiagnosis() {
  const inv = useInvalidate();
  return useMutation({ mutationFn: (scanId: string) => scanService.applyDiagnosis(scanId), onSuccess: () => inv("plants", "diary", "scans", "scan") });
}

// ---------- Commerce ----------
export function useProducts() {
  return useQuery({ queryKey: qk.products, queryFn: () => commerceService.listProducts(), staleTime: 60_000 });
}
export function useProduct(id: string) {
  return useQuery({ queryKey: qk.product(id), queryFn: () => commerceService.getProduct(id) });
}
export function useReviews(productId: string) {
  return useQuery({ queryKey: qk.reviews(productId), queryFn: () => commerceService.listReviews(productId) });
}
export function useVouchers() {
  return useQuery({ queryKey: qk.vouchers, queryFn: () => commerceService.listVouchers() });
}
export function useOrders() {
  const u = useUid();
  return useQuery({ queryKey: qk.orders(u), queryFn: () => commerceService.listOrders(), enabled: !!u });
}
export function useOrderMutations() {
  const inv = useInvalidate();
  return {
    place: useMutation({ mutationFn: (i: PlaceOrderInput) => commerceService.placeOrder(i), onSuccess: () => inv("orders") }),
    cancel: useMutation({ mutationFn: (id: string) => commerceService.cancelOrder(id), onSuccess: () => inv("orders"), onError: toastError }),
    receive: useMutation({ mutationFn: (id: string) => commerceService.confirmReceived(id), onSuccess: () => inv("orders"), onError: toastError }),
    review: useMutation({
      mutationFn: (i: { productId: string; orderId: string; rating: number; content: string; images: string[] }) => commerceService.createReview(i),
      onSuccess: () => inv("orders", "reviews"),
      onError: toastError,
    }),
  };
}
export function useAddresses() {
  const u = useUid();
  return useQuery({ queryKey: qk.addresses(u), queryFn: () => commerceService.listAddresses(), enabled: !!u });
}
export function useAddressMutations() {
  const inv = useInvalidate();
  return {
    save: useMutation({ mutationFn: commerceService.saveAddress, onSuccess: () => inv("addresses"), onError: toastError }),
    remove: useMutation({ mutationFn: (id: string) => commerceService.deleteAddress(id), onSuccess: () => inv("addresses"), onError: toastError }),
    setDefault: useMutation({ mutationFn: (id: string) => commerceService.setDefaultAddress(id), onSuccess: () => inv("addresses"), onError: toastError }),
  };
}

// ---------- Content ----------
export function useCatalog() {
  return useQuery({ queryKey: qk.catalog, queryFn: () => fetchUserCatalog(), staleTime: 120_000 });
}
export function useSpecies() {
  return useQuery({ queryKey: qk.species, queryFn: () => gardenService.listSpecies(), staleTime: 300_000 });
}
export function useDiseases() {
  return useQuery({
    queryKey: qk.diseases,
    queryFn: async () => {
      if (isMock()) return getAllDiseasesInfo();
      const cat = await fetchUserCatalog();
      return cat?.diseasesInfo ?? [];
    },
    staleTime: 300_000,
  });
}
export function useSupportArticles() {
  return useQuery({ queryKey: qk.support, queryFn: () => supportService.list(), staleTime: 300_000 });
}
export function useHandbook() {
  return useQuery({ queryKey: qk.handbook, queryFn: () => handbookService.list(), staleTime: 300_000 });
}
export function useArticle(slug: string) {
  return useQuery({ queryKey: qk.article(slug), queryFn: () => handbookService.get(slug) });
}
export function useReminders() {
  const u = useUid();
  return useQuery({ queryKey: qk.reminders(u), queryFn: () => reminderService.get(), enabled: !!u });
}
export function useUpdateReminders() {
  const inv = useInvalidate();
  return useMutation({ mutationFn: (p: Partial<Omit<ReminderSettings, "userId">>) => reminderService.update(p), onSuccess: () => inv("reminders"), onError: toastError });
}
export function useProvinces() {
  return useQuery({ queryKey: qk.provinces, queryFn: () => regionService.provinces(), staleTime: Infinity, retry: 1 });
}
export function useWards(provinceId: string | null) {
  return useQuery({ queryKey: qk.wards(provinceId ?? ""), queryFn: () => regionService.wards(provinceId!), enabled: !!provinceId, staleTime: Infinity, retry: 1 });
}

// ---------- Assistant ----------
export function useChatSessions() {
  const u = useUid();
  return useQuery({ queryKey: qk.chatSessions(u), queryFn: () => assistantService.listSessions(), enabled: !!u });
}
export function useChatMessages(sessionId: string | null) {
  return useQuery({ queryKey: qk.chatMessages(sessionId ?? ""), queryFn: () => assistantService.listMessages(sessionId!), enabled: !!sessionId });
}
