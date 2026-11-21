"use client";

import { useQuery } from "@tanstack/react-query";
import { ordersService, reviewsService } from "@/services";
import { apiRequest } from "@/lib/api-client";
import type { BadgeKey } from "@/components/layout/nav-config";
import type { PlantRequestItem } from "@/app/api/admin/ai/requests/route";

/** Live counters shown as sidebar badges. */
export function useNavBadges(): Record<BadgeKey, number> {
  const plantRequests = useQuery({
    queryKey: ["ai-plant-requests"],
    queryFn: () => apiRequest<PlantRequestItem[]>("/ai/requests"),
  });
  const orders = useQuery({ queryKey: [ordersService.key], queryFn: () => ordersService.list() });
  const reviews = useQuery({ queryKey: [reviewsService.key], queryFn: () => reviewsService.list() });
  return {
    labelReviews: plantRequests.data?.filter((x) => x.status === "pending").length ?? 0,
    pendingOrders: orders.data?.filter((x) => x.fulfillment === "pending").length ?? 0,
    pendingReviews: reviews.data?.filter((x) => x.status === "pending").length ?? 0,
  };
}
