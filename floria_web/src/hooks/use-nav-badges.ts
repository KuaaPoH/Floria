"use client";

import { useQuery } from "@tanstack/react-query";
import { labelReviewsService, ordersService, reviewsService, ticketsService } from "@/services";
import type { BadgeKey } from "@/components/layout/nav-config";

/** Live counters shown as sidebar badges. */
export function useNavBadges(): Record<BadgeKey, number> {
  const labels = useQuery({ queryKey: [labelReviewsService.key], queryFn: () => labelReviewsService.list() });
  const orders = useQuery({ queryKey: [ordersService.key], queryFn: () => ordersService.list() });
  const tickets = useQuery({ queryKey: [ticketsService.key], queryFn: () => ticketsService.list() });
  const reviews = useQuery({ queryKey: [reviewsService.key], queryFn: () => reviewsService.list() });
  return {
    labelReviews: labels.data?.filter((x) => x.status === "pending").length ?? 0,
    pendingOrders: orders.data?.filter((x) => x.fulfillment === "pending").length ?? 0,
    openTickets: tickets.data?.filter((x) => x.status === "open").length ?? 0,
    pendingReviews: reviews.data?.filter((x) => x.status === "pending").length ?? 0,
  };
}
