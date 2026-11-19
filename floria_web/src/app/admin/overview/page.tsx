"use client";

import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Activity, Bot, CalendarRange, Download, Leaf, Microscope, ScanLine, ShoppingBag, Target, Users, Wallet } from "lucide-react";
import { Button } from "@/components/ui/button";
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Input } from "@/components/ui/input";
import { PageHeader } from "@/components/shared/page-header";
import { StatCard } from "@/components/shared/stat-card";
import { ChartCard } from "@/components/shared/chart-card";
import { DemoBadge } from "@/components/shared/demo-badge";
import { ActivityTimeline } from "@/components/shared/activity-timeline";
import { ServiceHealthGrid } from "@/features/system/service-health-grid";
import { OrderStatusChart, RecognitionChart, RevenueChart, TopDiseasesChart, UserGrowthChart } from "@/features/overview/overview-charts";
import { overviewSeries } from "@/mocks/analytics";
type DailyMetric = ReturnType<typeof overviewSeries>[number];
import { auditService, ordersService } from "@/services";
import { apiRequest } from "@/lib/api-client";
import { IS_MOCK } from "@/lib/config";
import { useAuthStore } from "@/stores/auth-store";
import { exportCsv } from "@/lib/export";
import { formatDate, formatNumber, formatRelative, formatVND } from "@/lib/format";
import { toast } from "sonner";

type Range = "7" | "30" | "90" | "custom";

const sum = (a: number[]) => a.reduce((s, v) => s + v, 0);
const pct = (cur: number, prev: number) => (prev ? ((cur - prev) / prev) * 100 : 0);

export default function OverviewPage() {
  const session = useAuthStore((s) => s.session);
  const [range, setRange] = useState<Range>("30");
  const [customDays, setCustomDays] = useState(45);
  const days = range === "custom" ? customDays : Number(range);

  const mockSeries = useMemo(() => overviewSeries(days * 2), [days]);
  const realOverview = useQuery({
    queryKey: ["overview", days],
    queryFn: () =>
      apiRequest<{
        totals: {
          users: number;
          dau: number;
          mau: number;
          gardenPlants: number;
          plantScans: number;
          diseaseScans: number;
          scanSuccessRate: number;
          chatSessions: number;
          orders: number;
          revenue: number;
        };
        topDiseases: { name: string; value: number }[];
        series: DailyMetric[];
      }>(`/overview?days=${days}`),
    enabled: !IS_MOCK,
  });

  const cur = IS_MOCK ? mockSeries.slice(days) : (realOverview.data?.series ?? []);
  const prev = IS_MOCK ? mockSeries.slice(0, days) : [];

  const orders = useQuery({ queryKey: [ordersService.key], queryFn: () => ordersService.list() });
  const audit = useQuery({ queryKey: [auditService.key], queryFn: () => auditService.list(), staleTime: 0 });

  const k = (key: keyof DailyMetric) => [sum(cur.map((d) => d[key] as number)), sum(prev.map((d) => d[key] as number))] as const;
  const [scans, scansPrev] = IS_MOCK ? k("plantScans") : [realOverview.data?.totals.plantScans ?? 0, 0];
  const [dis, disPrev] = IS_MOCK ? k("diseaseScans") : [realOverview.data?.totals.diseaseScans ?? 0, 0];
  const [rev, revPrev] = IS_MOCK ? k("revenue") : [realOverview.data?.totals.revenue ?? 0, 0];
  const [ord, ordPrev] = IS_MOCK ? k("orders") : [realOverview.data?.totals.orders ?? 0, 0];
  const [ses, sesPrev] = IS_MOCK ? k("sessions") : [realOverview.data?.totals.chatSessions ?? 0, 0];
  const totalUsers = IS_MOCK ? (cur.at(-1)?.users ?? 0) : (realOverview.data?.totals.users ?? 0);
  const prevUsers = IS_MOCK ? (prev.at(-1)?.users ?? 1) : 0;
  const dau = realOverview.data?.totals.dau ?? 0;
  const mau = realOverview.data?.totals.mau ?? 0;
  const dauMauRatio = IS_MOCK ? "28,4%" : mau > 0 ? `${((dau / mau) * 100).toFixed(1).replace(".", ",")}%` : "0%";
  const dauMauHint = IS_MOCK ? "8.940 DAU · 31.480 MAU" : `${formatNumber(dau)} DAU · ${formatNumber(mau)} MAU`;
  const successRateStr = IS_MOCK ? "91,6%" : `${String(realOverview.data?.totals.scanSuccessRate ?? 0).replace(".", ",")}%`;
  const trend = (key: keyof DailyMetric) => cur.slice(-14).map((d) => d[key] as number);

  const exportReport = () => {
    exportCsv(
      `floria-bao-cao-${days}-ngay`,
      cur.map((d) => ({
        ngay: formatDate(d.date),
        tong_nguoi_dung: d.users,
        nhan_dien_cay: d.plantScans,
        chan_doan_benh: d.diseaseScans,
        don_hang: d.orders,
        doanh_thu_vnd: d.revenue,
      })),
    );
    toast.success("Đã xuất báo cáo CSV");
  };

  const today = new Intl.DateTimeFormat("vi-VN", { weekday: "long", day: "2-digit", month: "2-digit", year: "numeric" }).format(new Date());

  return (
    <>
      <PageHeader
        title="Chào mừng trở lại, Admin!"
        description={`${session?.name ?? ""} · ${today.charAt(0).toUpperCase() + today.slice(1)}`}
        badge={IS_MOCK ? <DemoBadge label="Số liệu demo" /> : undefined}
        actions={
          <>
            <ToggleGroup type="single" value={range} onValueChange={(v) => v && setRange(v as Range)} className="rounded-lg border bg-card p-1">
              {(["7", "30", "90"] as const).map((r) => (
                <ToggleGroupItem key={r} value={r} className="h-8 rounded-md px-3 text-xs data-[state=on]:bg-primary data-[state=on]:text-primary-foreground">
                  {r} ngày
                </ToggleGroupItem>
              ))}
              <Popover>
                <PopoverTrigger asChild>
                  <ToggleGroupItem value="custom" className="h-8 rounded-md px-3 text-xs data-[state=on]:bg-primary data-[state=on]:text-primary-foreground">
                    <CalendarRange className="size-3.5" /> Tuỳ chọn
                  </ToggleGroupItem>
                </PopoverTrigger>
                <PopoverContent className="w-64" align="end">
                  <p className="mb-2 text-sm font-medium">Số ngày gần nhất</p>
                  <Input
                    type="number"
                    min={7}
                    max={180}
                    value={customDays}
                    onChange={(e) => setCustomDays(Math.min(180, Math.max(7, Number(e.target.value) || 7)))}
                  />
                  <p className="mt-2 text-xs text-muted-foreground">Từ 7 đến 180 ngày, so sánh với kỳ trước tương ứng.</p>
                </PopoverContent>
              </Popover>
            </ToggleGroup>
            <Button onClick={exportReport}>
              <Download /> Xuất báo cáo
            </Button>
          </>
        }
      />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="Tổng người dùng" value={formatNumber(totalUsers)} change={pct(totalUsers, prevUsers)} icon={Users} tone="leaf" trend={trend("users")} />
        <StatCard label="DAU / MAU" value={dauMauRatio} change={IS_MOCK ? 2.1 : 0} icon={Activity} tone="info" hint={dauMauHint} trend={trend("sessions")} />
        <StatCard label="Lượt nhận diện cây" value={formatNumber(scans)} change={pct(scans, scansPrev)} icon={ScanLine} tone="sage" trend={trend("plantScans")} />
        <StatCard label="Lượt chẩn đoán bệnh" value={formatNumber(dis)} change={pct(dis, disPrev)} icon={Microscope} tone="warning" trend={trend("diseaseScans")} />
        <StatCard label="Tỉ lệ nhận diện thành công" value={successRateStr} change={IS_MOCK ? 1.4 : 0} icon={Target} tone="leaf" hint="Độ tin cậy ≥ 50%" />
        <StatCard label="Tổng đơn hàng" value={formatNumber(ord)} change={pct(ord, ordPrev)} icon={ShoppingBag} tone="info" trend={trend("orders")} />
        <StatCard label="Doanh thu" value={formatVND(rev)} change={pct(rev, revPrev)} icon={Wallet} tone="sage" trend={trend("revenue")} />
        <StatCard label="Phiên trợ lý AI" value={formatNumber(ses)} change={pct(ses, sesPrev)} icon={Bot} tone="danger" trend={trend("sessions")} />
      </div>

      <div className="mt-6 grid gap-4 xl:grid-cols-2">
        <UserGrowthChart data={cur} />
        <RecognitionChart data={cur} />
      </div>
      <div className="mt-4 grid gap-4 lg:grid-cols-3">
        <div className="lg:col-span-2">
          <RevenueChart data={cur} />
        </div>
        {orders.data && <OrderStatusChart orders={orders.data} />}
      </div>

      <div className="mt-4 grid gap-4 lg:grid-cols-3">
        <ChartCard title="Tình trạng hệ thống" description={IS_MOCK ? "Giám sát dịch vụ backend (mô phỏng)" : "Giám sát dịch vụ backend thực tế"} className="lg:col-span-2">
          <ServiceHealthGrid compact />
        </ChartCard>
        <ChartCard title="Hoạt động gần đây" description="Thao tác của quản trị viên">
          <ActivityTimeline
            items={(audit.data ?? []).slice(0, 6).map((a) => ({
              id: a.id,
              title: `${a.admin} · ${a.action}`,
              description: a.target,
              time: formatRelative(a.at),
              icon: a.role === "botanist" ? Leaf : a.role === "operations" ? ShoppingBag : Activity,
              tone: a.role === "botanist" ? "leaf" : a.role === "operations" ? "info" : "warning",
            }))}
          />
        </ChartCard>
      </div>
      <div className="mt-4">
        <TopDiseasesChart data={IS_MOCK ? undefined : realOverview.data?.topDiseases} />
      </div>
    </>
  );
}
