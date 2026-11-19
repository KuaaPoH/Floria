"use client";

import { useEffect, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import {
  Bell,
  Bug,
  Calendar,
  ChevronDown,
  ChevronRight,
  Droplets,
  Leaf,
  Lock,
  MapPin,
  Microscope,
  Package,
  ScanLine,
  ShoppingBag,
  Sparkles,
  Sprout,
  Star,
  Sun,
  Unlock,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { DetailDrawer, DetailSection, InfoGrid } from "@/components/shared/detail-drawer";
import { SmartImage } from "@/components/shared/smart-image";
import { StatusBadge } from "@/components/shared/status-badge";
import { UserAvatar } from "@/components/shared/user-avatar";
import { ActivityTimeline } from "@/components/shared/activity-timeline";
import { ordersService } from "@/services";
import { apiRequest } from "@/lib/api-client";
import { IS_MOCK } from "@/lib/config";
import { SPECIES_CLASSES, DISEASE_CLASSES } from "@/mocks/ai-classes";
import { formatDate, formatDateTime, formatVND } from "@/lib/format";
import { seeded } from "@/lib/id";
import { cn } from "@/lib/utils";
import type { AppUser } from "@/types";
import { PROVIDER_LABEL } from "./provider";

interface Props {
  user: AppUser | null;
  onOpenChange: (o: boolean) => void;
  onToggleLock: (u: AppUser) => void;
  canEdit: boolean;
}

interface GardenPlantDetail {
  id: string;
  gardenId: string;
  nameVi: string;
  scientificName: string;
  nickname: string;
  zone: string;
  imageUrl: string | null;
  plantType: string;
  healthStatus: string;
  statusTags?: string[];
  notes: string;
  waterFrequencyDays: number;
  reminderTime: string;
  lastWatered: string;
  nextWatering: string;
  fertilizeFrequencyDays: number;
  lastFertilized: string;
  nextFertilizing: string;
  checkPestFrequencyDays: number;
  lastCleaned: string;
  nextCheckPest: string;
  createdAt: string;
}

interface UserGardenItem {
  id: string;
  name: string;
  environment: string;
  lightCondition: string;
  createdAt: string;
  plants: GardenPlantDetail[];
}

interface RealOrderItem {
  productId: string;
  name: string;
  imageUrl: string;
  category: string;
  price: number;
  quantity: number;
}

interface RealOrder {
  id: string;
  code: string;
  total: number;
  fulfillment: string;
  createdAt: string;
  itemCount: number;
  items: RealOrderItem[];
  recipientName: string;
  recipientPhone: string;
  shippingAddress: string;
  addressLabel: string;
  paymentMethod: string;
  paymentLabel: string;
  isReviewed: boolean;
  rating: number | null;
  reviewNote: string | null;
}

interface RealRecog {
  id: string;
  species: string;
  rawPrediction?: string;
  conf: number;
  modelUsed?: string;
  imageUrl?: string | null;
  at: string;
}

interface RealDiag {
  id: string;
  disease: string;
  plantName?: string;
  severity?: string;
  severityVi?: string;
  cause?: string;
  treatmentSteps?: string[];
  conf: number;
  modelUsed?: string;
  imageUrl?: string | null;
  at: string;
}

interface RealUserDetail {
  gardens: UserGardenItem[];
  totalPlants: number;
  dist: Array<{ name: string; count: number }>;
  recog: RealRecog[];
  diag: RealDiag[];
  orders: RealOrder[];
  diaryCount: number;
  activities: Array<{
    id: string;
    kind: "scan" | "disease" | "order" | "plant" | "diary";
    title: string;
    description: string;
    at: string;
  }>;
}

/** Garden and activity details are derived deterministically from the user id in demo mode. */
function useMockGarden(user: AppUser) {
  const r = seeded(Number(user.id.replace(/\D/g, "")) || 1);
  const species = Array.from({ length: 5 }, () => SPECIES_CLASSES[Math.floor(r() * 14)].vi);
  const dist = [...new Set(species)].map((name) => ({ name, count: 1 + Math.floor(r() * Math.max(1, user.plants / 3)) }));
  const recog = Array.from({ length: 5 }, (_, i) => ({
    id: `r${i}`,
    species: SPECIES_CLASSES[Math.floor(r() * 20)].vi,
    conf: 0.6 + r() * 0.38,
    at: new Date(Date.now() - i * 86400000 * (1 + r() * 3)).toISOString(),
  }));
  const diag = Array.from({ length: 3 }, (_, i) => ({
    id: `d${i}`,
    disease: DISEASE_CLASSES[Math.floor(r() * 6)].vi,
    conf: 0.55 + r() * 0.4,
    at: new Date(Date.now() - i * 86400000 * (2 + r() * 4)).toISOString(),
  }));
  const mockPlants: GardenPlantDetail[] = dist.map((d, i) => ({
    id: `mp_${i}`,
    gardenId: "mg_1",
    nameVi: d.name,
    scientificName: "",
    nickname: d.name,
    zone: ["Ban công", "Phòng khách", "Cửa sổ"][i % 3],
    imageUrl: null,
    plantType: "Cây cảnh",
    healthStatus: "Khỏe mạnh",
    notes: "",
    waterFrequencyDays: 3,
    reminderTime: "07:00",
    lastWatered: new Date().toISOString(),
    nextWatering: new Date(Date.now() + (i + 1) * 86400000).toISOString(),
    fertilizeFrequencyDays: 20,
    lastFertilized: new Date().toISOString(),
    nextFertilizing: new Date(Date.now() + 14 * 86400000).toISOString(),
    checkPestFrequencyDays: 3,
    lastCleaned: new Date().toISOString(),
    nextCheckPest: new Date(Date.now() + 3 * 86400000).toISOString(),
    createdAt: new Date().toISOString(),
  }));
  const gardens: UserGardenItem[] = [
    {
      id: "mg_1",
      name: "Khu vườn mẫu",
      environment: "Trong nhà",
      lightCondition: "Sáng gián tiếp",
      createdAt: user.registeredAt,
      plants: mockPlants,
    },
  ];
  return { dist, gardens, recog, diag };
}

export function UserDetailDrawer({ user, onOpenChange, onToggleLock, canEdit }: Props) {
  return (
    <DetailDrawer
      open={!!user}
      onOpenChange={onOpenChange}
      className="sm:max-w-2xl"
      title={
        user ? (
          <span className="flex items-center gap-3">
            <UserAvatar name={user.fullName} src={user.avatar} className="size-10 text-sm" />
            <span>
              <span className="block">{user.fullName}</span>
              <span className="block text-xs font-normal text-muted-foreground">{user.email}</span>
            </span>
          </span>
        ) : (
          ""
        )
      }
      footer={
        user && canEdit ? (
          <Button variant={user.status === "locked" ? "success" : "danger-soft"} onClick={() => onToggleLock(user)}>
            {user.status === "locked" ? (
              <>
                <Unlock /> Mở khoá tài khoản
              </>
            ) : (
              <>
                <Lock /> Khoá tài khoản
              </>
            )}
          </Button>
        ) : undefined
      }
    >
      {user && <Body user={user} />}
    </DetailDrawer>
  );
}

function Body({ user }: { user: AppUser }) {
  const mockG = useMockGarden(user);
  const realDetail = useQuery({
    queryKey: ["user-detail", user.id],
    queryFn: () => apiRequest<RealUserDetail>(`/users/${user.id}`),
    enabled: !IS_MOCK,
  });
  const mockOrdersQuery = useQuery({
    queryKey: [ordersService.key],
    queryFn: () => ordersService.list(),
    enabled: IS_MOCK,
  });

  const gardens = IS_MOCK ? mockG.gardens : (realDetail.data?.gardens ?? []);
  const dist = IS_MOCK ? mockG.dist : (realDetail.data?.dist ?? []);
  const recog: RealRecog[] = IS_MOCK ? mockG.recog : (realDetail.data?.recog ?? []);
  const diag: RealDiag[] = IS_MOCK ? mockG.diag : (realDetail.data?.diag ?? []);

  const userOrders: RealOrder[] = IS_MOCK
    ? (mockOrdersQuery.data ?? []).slice(0, Math.min(user.orders, 4)).map((o) => ({
      id: o.id,
      code: o.code,
      total: o.total,
      fulfillment: o.fulfillment,
      createdAt: o.createdAt,
      itemCount: o.items.reduce((s, it) => s + it.qty, 0),
      items: o.items.map((it) => ({
        productId: it.productId,
        name: it.name,
        imageUrl: "",
        category: "Vật tư",
        price: it.price,
        quantity: it.qty,
      })),
      recipientName: o.customerName,
      recipientPhone: o.phone,
      shippingAddress: o.address,
      addressLabel: "Nhà riêng",
      paymentMethod: o.paymentMethod,
      paymentLabel: o.paymentMethod === "ZALOPAY" ? "Ví ZaloPay" : "COD",
      isReviewed: false,
      rating: null,
      reviewNote: null,
    }))
    : (realDetail.data?.orders ?? []);

  const [selectedGardenId, setSelectedGardenId] = useState<string>("");
  const [selectedPlantId, setSelectedPlantId] = useState<string | null>(null);
  const [expandedOrderId, setExpandedOrderId] = useState<string | null>(null);
  const [previewImg, setPreviewImg] = useState<{ src: string; title: string } | null>(null);

  useEffect(() => {
    setSelectedGardenId("");
    setSelectedPlantId(null);
    setExpandedOrderId(null);
  }, [user.id]);

  const activeGarden = gardens.find((g) => g.id === selectedGardenId) ?? gardens[0] ?? null;
  const activePlant = activeGarden?.plants.find((p) => p.id === selectedPlantId) ?? null;

  return (
    <>
    <Tabs defaultValue="info">
      <TabsList className="mb-4 w-full justify-start overflow-x-auto">
        <TabsTrigger value="info">Thông tin</TabsTrigger>
        <TabsTrigger value="garden">Khu vườn</TabsTrigger>
        <TabsTrigger value="history">Lịch sử AI</TabsTrigger>
        <TabsTrigger value="orders">Đơn hàng</TabsTrigger>
        <TabsTrigger value="activity">Hoạt động</TabsTrigger>
      </TabsList>

      <TabsContent value="info">
        <DetailSection title="Thông tin cá nhân">
          <InfoGrid
            items={[
              { label: "Họ tên", value: user.fullName },
              { label: "Số điện thoại", value: user.phone || "Chưa cập nhật" },
              { label: "Email", value: user.email },
              { label: "Thành phố", value: user.city },
            ]}
          />
        </DetailSection>
        <DetailSection title="Tài khoản">
          <InfoGrid
            items={[
              { label: "Trạng thái", value: <StatusBadge status={user.status} /> },
              { label: "Đăng nhập bằng", value: PROVIDER_LABEL[user.provider] },
              { label: "Ngày đăng ký", value: formatDate(user.registeredAt) },
              { label: "Hoạt động gần nhất", value: formatDateTime(user.lastActiveAt) },
            ]}
          />
        </DetailSection>
        <div className="grid grid-cols-4 gap-2">
          {[
            [Leaf, "Cây", user.plants],
            [ScanLine, "Lượt quét", user.scans],
            [Microscope, "Chẩn đoán", user.diseaseScans],
            [ShoppingBag, "Đơn hàng", user.orders],
          ].map(([Icon, l, v]) => {
            const I = Icon as typeof Leaf;
            return (
              <div key={l as string} className="rounded-xl border p-3 text-center">
                <I className="mx-auto size-4 text-leaf" />
                <p className="mt-1 text-lg font-semibold tabular">{v as number}</p>
                <p className="text-[11px] text-muted-foreground">{l as string}</p>
              </div>
            );
          })}
        </div>
      </TabsContent>

      <TabsContent value="garden">
        {!IS_MOCK && realDetail.isLoading ? (
          <p className="py-8 text-center text-sm text-muted-foreground">Đang tải thông tin khu vườn...</p>
        ) : gardens.length === 0 ? (
          <p className="py-8 text-center text-sm text-muted-foreground">Người dùng chưa tạo khu vườn nào.</p>
        ) : (
          <div className="space-y-4">
            <DetailSection title={`Đang sở hữu ${gardens.length} khu vườn · ${user.plants} cây`}>
              <div className="grid gap-2 sm:grid-cols-2">
                {gardens.map((g) => {
                  const isActive = activeGarden?.id === g.id;
                  return (
                    <button
                      key={g.id}
                      type="button"
                      onClick={() => {
                        setSelectedGardenId(g.id);
                        setSelectedPlantId(null);
                      }}
                      className={cn(
                        "flex flex-col rounded-xl border p-3 text-left transition-all",
                        isActive ? "border-primary bg-accent/40 ring-1 ring-primary/30" : "hover:bg-muted/50",
                      )}
                    >
                      <div className="flex w-full items-center justify-between gap-2">
                        <span className="truncate text-sm font-semibold text-foreground">{g.name}</span>
                        <span className="shrink-0 rounded-full bg-primary/10 px-2 py-0.5 text-[11px] font-medium text-primary">
                          {g.plants.length} cây
                        </span>
                      </div>
                      <div className="mt-1.5 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground">
                        <span className="inline-flex items-center gap-1">
                          <MapPin className="size-3" /> {g.environment}
                        </span>
                        <span className="inline-flex items-center gap-1">
                          <Sun className="size-3" /> {g.lightCondition}
                        </span>
                      </div>
                    </button>
                  );
                })}
              </div>
            </DetailSection>

            {activeGarden && (
              <DetailSection title={`Cây trong "${activeGarden.name}" (${activeGarden.plants.length})`}>
                {activeGarden.plants.length === 0 ? (
                  <p className="rounded-xl border border-dashed py-6 text-center text-xs text-muted-foreground">
                    Khu vườn này chưa có cây nào.
                  </p>
                ) : (
                  <div className="space-y-2">
                    {activeGarden.plants.map((plant) => {
                      const isPicked = activePlant?.id === plant.id;
                      return (
                        <div key={plant.id} className="overflow-hidden rounded-xl border">
                          <button
                            type="button"
                            onClick={() => setSelectedPlantId(isPicked ? null : plant.id)}
                            className={cn(
                              "flex w-full items-center gap-3 p-3 text-left transition-colors",
                              isPicked ? "bg-accent/35" : "hover:bg-muted/40",
                            )}
                          >
                            {plant.imageUrl ? (
                              <span
                                role="button"
                                tabIndex={0}
                                title="Bấm để xem ảnh lớn"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  setPreviewImg({ src: plant.imageUrl!, title: plant.nickname || plant.nameVi });
                                }}
                                onKeyDown={(e) => {
                                  if (e.key === "Enter" || e.key === " ") {
                                    e.stopPropagation();
                                    setPreviewImg({ src: plant.imageUrl!, title: plant.nickname || plant.nameVi });
                                  }
                                }}
                                className="shrink-0 cursor-zoom-in rounded-lg transition hover:opacity-90"
                              >
                                <SmartImage
                                  src={plant.imageUrl}
                                  alt={plant.nameVi}
                                  className="size-11 rounded-lg border"
                                  fallback={
                                    <span className="grid size-11 place-items-center rounded-lg bg-accent text-forest">
                                      <Leaf className="size-5" />
                                    </span>
                                  }
                                />
                              </span>
                            ) : (
                              <span className="grid size-11 shrink-0 place-items-center rounded-lg bg-accent text-forest">
                                <Leaf className="size-5" />
                              </span>
                            )}
                            <div className="min-w-0 flex-1">
                              <div className="flex items-center gap-2">
                                <p className="truncate text-sm font-semibold text-foreground">{plant.nickname || plant.nameVi}</p>
                                <span className="shrink-0 rounded-md bg-muted px-1.5 py-0.5 text-[10px] font-medium text-muted-foreground">
                                  {plant.zone}
                                </span>
                              </div>
                              <p className="truncate text-xs text-muted-foreground">
                                {plant.nameVi}
                                {plant.scientificName ? ` · ${plant.scientificName}` : ""}
                              </p>
                            </div>
                            <div className="flex shrink-0 items-center gap-2">
                              <div className="flex max-w-[240px] flex-wrap justify-end gap-1">
                                {(plant.statusTags && plant.statusTags.length > 0 ? plant.statusTags : [plant.healthStatus]).map((tag) => (
                                  <span
                                    key={tag}
                                    className={cn(
                                      "rounded-full px-2 py-0.5 text-[11px] font-medium",
                                      tag === "Khỏe mạnh"
                                        ? "bg-success-soft text-success"
                                        : tag === "Cần tưới nước"
                                          ? "bg-info-soft text-info"
                                          : tag.startsWith("Bị") || tag === "Cần điều trị"
                                            ? "bg-danger-soft text-danger"
                                            : "bg-warning-soft text-warning",
                                    )}
                                  >
                                    {tag}
                                  </span>
                                ))}
                              </div>
                              {isPicked ? <ChevronDown className="size-4 text-muted-foreground" /> : <ChevronRight className="size-4 text-muted-foreground" />}
                            </div>
                          </button>

                          {isPicked && (
                            <div className="border-t bg-muted/20 p-3.5 text-xs">
                              <p className="mb-2.5 font-semibold text-foreground">Lịch chăm sóc & nhắc nhở của cây</p>
                              <div className="grid gap-2 sm:grid-cols-3">
                                <div className="rounded-lg border bg-card p-2.5">
                                  <div className="flex items-center gap-1.5 font-medium text-info">
                                    <Droplets className="size-3.5" /> Tưới nước
                                  </div>
                                  <p className="mt-1 text-foreground">Mỗi {plant.waterFrequencyDays} ngày · {plant.reminderTime}</p>
                                  <p className="mt-0.5 text-[11px] text-muted-foreground">Gần nhất: {formatDate(plant.lastWatered)}</p>
                                  <p className="text-[11px] font-medium text-primary">Lần tới: {formatDate(plant.nextWatering)}</p>
                                </div>
                                <div className="rounded-lg border bg-card p-2.5">
                                  <div className="flex items-center gap-1.5 font-medium text-success">
                                    <Sprout className="size-3.5" /> Bón phân
                                  </div>
                                  <p className="mt-1 text-foreground">Mỗi {plant.fertilizeFrequencyDays} ngày</p>
                                  <p className="mt-0.5 text-[11px] text-muted-foreground">Gần nhất: {formatDate(plant.lastFertilized)}</p>
                                  <p className="text-[11px] font-medium text-primary">Lần tới: {formatDate(plant.nextFertilizing)}</p>
                                </div>
                                <div className="rounded-lg border bg-card p-2.5">
                                  <div className="flex items-center gap-1.5 font-medium text-warning">
                                    <Bug className="size-3.5" /> Kiểm tra sâu bệnh
                                  </div>
                                  <p className="mt-1 text-foreground">Mỗi {plant.checkPestFrequencyDays} ngày</p>
                                  <p className="mt-0.5 text-[11px] text-muted-foreground">Gần nhất: {formatDate(plant.lastCleaned)}</p>
                                  <p className="text-[11px] font-medium text-primary">Lần tới: {formatDate(plant.nextCheckPest)}</p>
                                </div>
                              </div>
                              <div className="mt-2.5 flex flex-wrap items-center gap-4 text-[11px] text-muted-foreground">
                                <span className="inline-flex items-center gap-1">
                                  <Calendar className="size-3" /> Thêm ngày: {formatDate(plant.createdAt)}
                                </span>
                                <span>Loại: {plant.plantType}</span>
                                {plant.notes && <span>Ghi chú: {plant.notes}</span>}
                              </div>
                            </div>
                          )}
                        </div>
                      );
                    })}
                  </div>
                )}
              </DetailSection>
            )}
          </div>
        )}
      </TabsContent>

      <TabsContent value="history">
        {!IS_MOCK && realDetail.isLoading ? (
          <p className="py-8 text-center text-sm text-muted-foreground">Đang tải lịch sử quét AI...</p>
        ) : (
          <>
            <DetailSection title={`Lịch sử nhận diện cây (${recog.length})`}>
              {recog.length === 0 ? (
                <p className="rounded-xl border border-dashed py-6 text-center text-xs text-muted-foreground">
                  Chưa có lượt quét nhận diện loài cây nào.
                </p>
              ) : (
                <HistoryList
                  rows={recog.map((r) => ({
                    id: r.id,
                    label: r.species,
                    sub: r.modelUsed ? `Model: ${r.modelUsed}` : undefined,
                    conf: r.conf,
                    at: r.at,
                  }))}
                />
              )}
            </DetailSection>
            <DetailSection title={`Lịch sử chẩn đoán bệnh (${diag.length})`}>
              {diag.length === 0 ? (
                <p className="rounded-xl border border-dashed py-6 text-center text-xs text-muted-foreground">
                  Chưa có lượt chẩn đoán bệnh lá nào.
                </p>
              ) : (
                <HistoryList
                  rows={diag.map((r) => ({
                    id: r.id,
                    label: r.disease,
                    sub: [r.plantName ? `Cây: ${r.plantName}` : "", r.severityVi ? `Mức độ: ${r.severityVi}` : ""].filter(Boolean).join(" · "),
                    conf: r.conf,
                    at: r.at,
                  }))}
                />
              )}
            </DetailSection>
          </>
        )}
      </TabsContent>

      <TabsContent value="orders">
        {!IS_MOCK && realDetail.isLoading ? (
          <p className="py-8 text-center text-sm text-muted-foreground">Đang tải danh sách đơn hàng...</p>
        ) : userOrders.length === 0 ? (
          <p className="py-8 text-center text-sm text-muted-foreground">Người dùng chưa có đơn hàng.</p>
        ) : (
          <ul className="space-y-2.5">
            {userOrders.map((o) => {
              const isOpen = expandedOrderId === o.id;
              return (
                <li key={o.id} className="overflow-hidden rounded-xl border">
                  <button
                    type="button"
                    onClick={() => setExpandedOrderId(isOpen ? null : o.id)}
                    className={cn(
                      "flex w-full items-center justify-between gap-3 p-3 text-left transition-colors",
                      isOpen ? "bg-accent/35" : "hover:bg-muted/40",
                    )}
                  >
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-2">
                        <p className="text-sm font-semibold text-foreground">{o.code}</p>
                        {isOpen ? (
                          <ChevronDown className="size-4 text-muted-foreground" />
                        ) : (
                          <ChevronRight className="size-4 text-muted-foreground" />
                        )}
                      </div>
                      <p className="text-xs text-muted-foreground">
                        {formatDate(o.createdAt)} · {o.itemCount} sản phẩm · {o.paymentLabel}
                      </p>
                    </div>
                    <div className="shrink-0 text-right">
                      <p className="text-sm font-semibold tabular">{formatVND(o.total)}</p>
                      <StatusBadge status={o.fulfillment} />
                    </div>
                  </button>

                  {isOpen && (
                    <div className="space-y-3 border-t bg-muted/20 p-3.5 text-xs">
                      <div className="space-y-2">
                        <p className="font-semibold text-foreground">Sản phẩm trong đơn ({o.items.length} mặt hàng)</p>
                        {o.items.length === 0 ? (
                          <p className="text-muted-foreground">Không có dữ liệu chi tiết sản phẩm.</p>
                        ) : (
                          <ul className="divide-y rounded-lg border bg-card">
                            {o.items.map((item, idx) => (
                              <li key={`${item.productId}_${idx}`} className="flex items-center gap-3 p-2.5">
                                <SmartImage
                                  src={item.imageUrl}
                                  alt={item.name}
                                  className="size-10 shrink-0 rounded-md border"
                                  fallback={
                                    <span className="grid size-10 shrink-0 place-items-center rounded-md bg-muted text-muted-foreground">
                                      <Package className="size-4" />
                                    </span>
                                  }
                                />
                                <div className="min-w-0 flex-1">
                                  <p className="truncate font-medium text-foreground">{item.name}</p>
                                  <p className="text-[11px] text-muted-foreground">
                                    {item.category} · SL: {item.quantity} × {formatVND(item.price)}
                                  </p>
                                </div>
                                <span className="shrink-0 font-semibold tabular text-foreground">
                                  {formatVND(item.price * item.quantity)}
                                </span>
                              </li>
                            ))}
                          </ul>
                        )}
                      </div>

                      <div className="grid gap-2 rounded-lg border bg-card p-3 sm:grid-cols-2">
                        <div>
                          <p className="text-[11px] text-muted-foreground">Người nhận</p>
                          <p className="font-medium text-foreground">
                            {o.recipientName || user.fullName} {o.recipientPhone ? `· ${o.recipientPhone}` : ""}
                          </p>
                        </div>
                        <div>
                          <p className="text-[11px] text-muted-foreground">Thanh toán</p>
                          <p className="font-medium text-foreground">{o.paymentLabel}</p>
                        </div>
                        <div className="sm:col-span-2">
                          <p className="text-[11px] text-muted-foreground">Địa chỉ giao hàng ({o.addressLabel})</p>
                          <p className="font-medium text-foreground">{o.shippingAddress || "Chưa có địa chỉ"}</p>
                        </div>
                      </div>

                      {o.isReviewed && (
                        <div className="rounded-lg border bg-card p-3">
                          <div className="flex items-center gap-1.5 font-medium text-warning">
                            <Star className="size-3.5 fill-current" /> Đánh giá: {o.rating ?? 5}/5 sao
                          </div>
                          {o.reviewNote && <p className="mt-1 text-muted-foreground">{o.reviewNote}</p>}
                        </div>
                      )}
                    </div>
                  )}
                </li>
              );
            })}
          </ul>
        )}
      </TabsContent>

      <TabsContent value="activity">
        {IS_MOCK ? (
          <ActivityTimeline
            items={[
              {
                id: "a1",
                title: "Quét nhận diện cây",
                description: recog[0]?.species,
                time: formatDateTime(recog[0]?.at ?? user.lastActiveAt),
                icon: ScanLine,
                tone: "leaf",
              },
              {
                id: "a2",
                title: "Hoàn thành nhắc tưới",
                description: gardens[0]?.plants[0]?.nameVi,
                time: formatDateTime(user.lastActiveAt),
                icon: Bell,
                tone: "info",
              },
              {
                id: "a3",
                title: "Chẩn đoán bệnh",
                description: diag[0]?.disease,
                time: formatDateTime(diag[0]?.at ?? user.lastActiveAt),
                icon: Microscope,
                tone: "warning",
              },
              {
                id: "a4",
                title: "Đăng ký tài khoản",
                description: PROVIDER_LABEL[user.provider],
                time: formatDateTime(user.registeredAt),
                tone: "neutral",
              },
            ]}
          />
        ) : realDetail.isLoading ? (
          <p className="py-8 text-center text-sm text-muted-foreground">Đang tải hoạt động...</p>
        ) : (
          <ActivityTimeline
            items={[
              ...(realDetail.data?.activities ?? []).map((act) => ({
                id: act.id,
                title: act.title,
                description: act.description,
                time: formatDateTime(act.at),
                icon:
                  act.kind === "scan"
                    ? ScanLine
                    : act.kind === "disease"
                      ? Microscope
                      : act.kind === "order"
                        ? ShoppingBag
                        : act.kind === "plant"
                          ? Leaf
                          : Sparkles,
                tone: (act.kind === "disease" ? "warning" : act.kind === "order" ? "info" : "leaf") as
                  | "leaf"
                  | "info"
                  | "warning"
                  | "neutral",
              })),
              {
                id: "reg",
                title: "Đăng ký tài khoản",
                description: PROVIDER_LABEL[user.provider],
                time: formatDateTime(user.registeredAt),
                tone: "neutral" as const,
              },
            ]}
          />
        )}
      </TabsContent>
    </Tabs>
    <Dialog open={!!previewImg} onOpenChange={(o) => !o && setPreviewImg(null)}>
      <DialogContent className="max-w-lg p-4">
        <DialogHeader>
          <DialogTitle>{previewImg?.title}</DialogTitle>
        </DialogHeader>
        {previewImg && (
          <img
            src={previewImg.src}
            alt={previewImg.title}
            referrerPolicy="no-referrer"
            className="max-h-[70vh] w-full rounded-xl object-contain bg-muted"
          />
        )}
      </DialogContent>
    </Dialog>
    </>
  );
}

function HistoryList({ rows }: { rows: { id: string; label: string; sub?: string; conf: number; at: string }[] }) {
  return (
    <ul className="divide-y rounded-xl border">
      {rows.map((r) => (
        <li key={r.id} className="flex items-center justify-between gap-3 px-3 py-2.5 text-sm">
          <div className="min-w-0">
            <p className="truncate font-medium text-foreground">{r.label}</p>
            {r.sub && <p className="truncate text-xs text-muted-foreground">{r.sub}</p>}
          </div>
          <span className="flex shrink-0 items-center gap-3 text-xs text-muted-foreground">
            <span className="tabular font-medium text-foreground">{(r.conf * 100).toFixed(1).replace(".", ",")}%</span>
            {formatDate(r.at)}
          </span>
        </li>
      ))}
    </ul>
  );
}
