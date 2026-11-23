"use client";

import { useEffect, useMemo, useState } from "react";
import {
  ArrowRight,
  Clock,
  Image as ImageIcon,
  Pencil,
  Plus,
  Trash2,
  CloudSun,
  Flame,
  Snowflake,
  CloudRain,
  Wind,
  Zap,
} from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Switch } from "@/components/ui/switch";
import { Textarea } from "@/components/ui/textarea";
import { PageHeader } from "@/components/shared/page-header";
import { SmartImage } from "@/components/shared/smart-image";
import { StatusBadge } from "@/components/shared/status-badge";
import { FormDialog } from "@/components/shared/form-dialog";
import { ConfirmDialog } from "@/components/shared/confirm-dialog";
import { Field } from "@/components/shared/field";
import { ImageUploader } from "@/components/shared/image-uploader";
import { useResourceList, useResourceMutations } from "@/hooks/use-resource";
import { usePermission } from "@/stores/rbac-store";
import { bannersService, weatherRulesService } from "@/services";
import { IMAGES } from "@/mocks/images";
import { uid } from "@/lib/id";
import type { Banner, WeatherRule } from "@/types";

export default function BannersPage() {
  const [activeTab, setActiveTab] = useState<"time_widgets" | "weather_rules">("time_widgets");

  // Resource 1: Banners (HomeWeatherWidgets) - Giữ nguyên gốc
  const listBanners = useResourceList(bannersService);
  const bannerMutations = useResourceMutations(bannersService, { entity: "Banner" });

  // Resource 2: Weather Advice Rules (WeatherAdviceRules) - Tab 2
  const listRules = useResourceList(weatherRulesService);
  const ruleMutations = useResourceMutations(weatherRulesService, { entity: "Quy tắc vi khí hậu" });

  const canCreate = usePermission("content", "create");
  const canEdit = usePermission("content", "edit");
  const canDelete = usePermission("content", "delete");

  // State Banner dialog (giữ nguyên gốc)
  const [editingBanner, setEditingBanner] = useState<Banner | null | undefined>(undefined);
  const [delBanner, setDelBanner] = useState<Banner | null>(null);
  const [bannerForm, setBannerForm] = useState<Banner>({
    id: "",
    title: "",
    subtitle: "",
    cta: "Khám phá",
    deepLink: "floria://shop",
    image: IMAGES.bannerHome,
    startDate: new Date().toISOString().slice(0, 10),
    endDate: new Date(Date.now() + 1000 * 60 * 60 * 24 * 30).toISOString().slice(0, 10),
    active: true,
    order: 1,
    startHour: 6,
    endHour: 10,
  });

  // State Rule dialog (Tab 2)
  const [editingRule, setEditingRule] = useState<WeatherRule | null | undefined>(undefined);
  const [delRule, setDelRule] = useState<WeatherRule | null>(null);
  const [ruleForm, setRuleForm] = useState<WeatherRule>({
    id: "",
    name: "",
    title: "",
    badgeText: "",
    advice: "",
    tip: "",
    condition: "hot",
    conditionType: "temperature_high",
    minTemp: 33,
    maxTemp: null,
    tempMin: 33,
    tempMax: 45,
    minHumidity: null,
    maxHumidity: null,
    humidityMin: 40,
    humidityMax: 80,
    minWindSpeed: null,
    iconName: "thermostat",
    active: true,
    priority: 80,
    order: 1,
  });

  useEffect(() => {
    if (editingBanner === undefined) return;
    if (editingBanner) {
      setBannerForm({
        ...editingBanner,
        startDate: editingBanner.startDate?.slice(0, 10) ?? "",
        endDate: editingBanner.endDate?.slice(0, 10) ?? "",
      });
    } else {
      setBannerForm({
        id: uid("bnr"),
        title: "",
        subtitle: "",
        cta: "Xem ngay",
        deepLink: "floria://shop",
        image: IMAGES.bannerHome,
        startDate: new Date().toISOString().slice(0, 10),
        endDate: new Date(Date.now() + 1000 * 60 * 60 * 24 * 30).toISOString().slice(0, 10),
        active: true,
        order: (listBanners.data?.length ?? 0) + 1,
        startHour: 6,
        endHour: 10,
      });
    }
  }, [editingBanner, listBanners.data?.length]);

  useEffect(() => {
    if (editingRule === undefined) return;
    if (editingRule) {
      setRuleForm({
        ...editingRule,
        title: editingRule.title ?? editingRule.name ?? "",
        advice: editingRule.advice ?? editingRule.tip ?? "",
      });
    } else {
      setRuleForm({
        id: uid("rule"),
        name: "",
        title: "",
        badgeText: "Khuyến nghị vi khí hậu",
        advice: "",
        tip: "",
        condition: "hot",
        conditionType: "temperature_high",
        minTemp: 33,
        maxTemp: null,
        tempMin: 33,
        tempMax: 45,
        minHumidity: null,
        maxHumidity: null,
        humidityMin: 40,
        humidityMax: 80,
        minWindSpeed: null,
        iconName: "thermostat",
        active: true,
        priority: 70,
        order: (listRules.data?.length ?? 0) + 1,
      });
    }
  }, [editingRule, listRules.data?.length]);

  const sortedBanners = useMemo(() => [...(listBanners.data ?? [])].sort((a, b) => a.order - b.order), [listBanners.data]);
  const activeBanners = useMemo(() => sortedBanners.filter((b) => b.active), [sortedBanners]);

  const sortedRules = useMemo(
    () => [...(listRules.data ?? [])].sort((a, b) => (b.priority ?? 0) - (a.priority ?? 0)),
    [listRules.data]
  );

  const submitBanner = (e: React.FormEvent) => {
    e.preventDefault();
    if (!bannerForm.title.trim()) {
      toast.error("Vui lòng nhập tiêu đề banner");
      return;
    }
    const payload: Banner = {
      ...bannerForm,
      startDate: new Date(bannerForm.startDate).toISOString(),
      endDate: new Date(bannerForm.endDate).toISOString(),
    };
    if (editingBanner) {
      bannerMutations.update.mutate(
        { id: payload.id, patch: payload, label: payload.title },
        { onSuccess: () => setEditingBanner(undefined) }
      );
    } else {
      bannerMutations.create.mutate(payload, { onSuccess: () => setEditingBanner(undefined) });
    }
  };

  const submitRule = (e: React.FormEvent) => {
    e.preventDefault();
    const finalTitle = ruleForm.title?.trim() || ruleForm.name?.trim();
    if (!finalTitle) {
      toast.error("Vui lòng nhập tên quy tắc vi khí hậu");
      return;
    }
    if (!ruleForm.advice?.trim()) {
      toast.error("Vui lòng nhập nội dung lời khuyên chăm sóc");
      return;
    }
    const payload: WeatherRule = {
      ...ruleForm,
      name: finalTitle,
      title: finalTitle,
      tip: ruleForm.advice,
    };
    if (editingRule) {
      ruleMutations.update.mutate(
        { id: payload.id, patch: payload, label: finalTitle },
        { onSuccess: () => setEditingRule(undefined) }
      );
    } else {
      ruleMutations.create.mutate(payload, { onSuccess: () => setEditingRule(undefined) });
    }
  };

  const getRuleIcon = (condType?: string) => {
    switch (condType) {
      case "temperature_high":
        return <Flame className="size-4 text-amber-500" />;
      case "temperature_low":
        return <Snowflake className="size-4 text-sky-400" />;
      case "rain":
        return <CloudRain className="size-4 text-blue-500" />;
      case "humidity_low":
        return <Wind className="size-4 text-orange-400" />;
      case "storm_wind":
        return <Zap className="size-4 text-rose-500" />;
      default:
        return <CloudSun className="size-4 text-emerald-500" />;
    }
  };

  const getConditionDescription = (r: WeatherRule) => {
    switch (r.conditionType) {
      case "temperature_high":
        return `Nhiệt độ ≥ ${r.minTemp ?? 33}°C`;
      case "temperature_low":
        return `Nhiệt độ < ${r.maxTemp ?? 18}°C`;
      case "rain":
        return `Độ ẩm ≥ ${r.minHumidity ?? 85}% hoặc có mưa`;
      case "humidity_low":
        return `Độ ẩm ≤ ${r.maxHumidity ?? 50}%`;
      case "storm_wind":
        return `Mã dông sét hoặc gió ≥ ${r.minWindSpeed ?? 25} km/h`;
      default:
        return "Điều kiện thời tiết tùy chỉnh";
    }
  };

  return (
    <>
      <PageHeader
        title={activeTab === "time_widgets" ? "Banner trang chủ" : "Mẹo vi khí hậu thích ứng"}
        description={
          activeTab === "time_widgets"
            ? "Quản lý carousel banner hiển thị trên màn hình Trang chủ của ứng dụng Floria."
            : "Quản lý hệ thống quy tắc thích ứng vi khí hậu thông minh khi thời tiết có biến động."
        }
        actions={
          canCreate && (
            <Button
              onClick={() => {
                if (activeTab === "time_widgets") setEditingBanner(null);
                else setEditingRule(null);
              }}
            >
              <Plus /> {activeTab === "time_widgets" ? "Thêm banner" : "Thêm quy tắc vi khí hậu"}
            </Button>
          )
        }
      />

      {/* Tabs chuyển đổi: Tab 1 (Banner gốc) & Tab 2 (Quy tắc vi khí hậu) */}
      <div className="mb-6 flex gap-2 border-b border-border/60 pb-3">
        <button
          onClick={() => setActiveTab("time_widgets")}
          className={`flex items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-semibold transition-all ${
            activeTab === "time_widgets"
              ? "bg-forest text-white shadow-sm"
              : "bg-surface-2 text-muted-foreground hover:bg-surface-3 hover:text-foreground"
          }`}
        >
          <Clock className="size-4" />
          <span>Banner trang chủ ({sortedBanners.length})</span>
        </button>
        <button
          onClick={() => setActiveTab("weather_rules")}
          className={`flex items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-semibold transition-all ${
            activeTab === "weather_rules"
              ? "bg-forest text-white shadow-sm"
              : "bg-surface-2 text-muted-foreground hover:bg-surface-3 hover:text-foreground"
          }`}
        >
          <CloudSun className="size-4" />
          <span>Mẹo vi khí hậu thích ứng ({sortedRules.length})</span>
        </button>
      </div>

      {/* TAB 1: BANNER TRANG CHỦ (GIỮ Y NGUYÊN GIAO DIỆN GỐC) */}
      {activeTab === "time_widgets" && (
        <>
          <div className="card-surface mb-6 p-5">
            <div className="mb-3 flex items-center justify-between">
              <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                Xem trước banner đang hoạt động ({activeBanners.length})
              </p>
            </div>
            <div className="grid gap-4 md:grid-cols-2">
              {activeBanners.map((b) => (
                <div key={b.id} className="relative overflow-hidden rounded-2xl border bg-forest-deep text-white">
                  <SmartImage
                    src={b.image}
                    alt={b.title}
                    className="h-44 w-full opacity-75"
                    fallback={<div className="h-44 w-full bg-forest-deep" />}
                  />
                  <div className="absolute inset-0 bg-gradient-to-r from-forest-deep/90 via-forest-deep/50 to-transparent p-5 flex flex-col justify-end">
                    <p className="text-lg font-semibold">{b.title}</p>
                    <p className="mt-1 text-xs text-white/85">{b.subtitle}</p>
                    <span className="mt-3 inline-flex w-fit items-center gap-1 rounded-lg bg-white px-3 py-1.5 text-xs font-semibold text-forest">
                      {b.cta} <ArrowRight className="size-3" />
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
            {sortedBanners.map((b) => (
              <div key={b.id} className="card-surface overflow-hidden">
                <div className="relative aspect-[2/1] bg-surface-2">
                  <SmartImage
                    src={b.image}
                    alt={b.title}
                    className="size-full"
                    fallback={
                      <div className="grid size-full place-items-center bg-surface-2">
                        <ImageIcon className="size-8 text-muted-foreground" />
                      </div>
                    }
                  />
                  <span className="absolute left-2 top-2 rounded-md bg-card/90 px-2 py-0.5 font-mono text-[11px] font-semibold">
                    {String(b.startHour ?? b.order).padStart(2, "0")}:00 – {String(b.endHour ?? ((b.order + 4) % 24)).padStart(2, "0")}:00
                  </span>
                  <span className="absolute right-2 top-2">
                    <StatusBadge status={b.active ? "visible" : "hidden"} />
                  </span>
                </div>
                <div className="p-4">
                  <div className="mb-1 flex items-center gap-1.5 text-[11px] font-medium text-primary">
                    <Clock className="size-3" /> {b.cta}
                  </div>
                  <h4 className="font-semibold">{b.title}</h4>
                  <p className="mt-0.5 text-xs text-muted-foreground">{b.subtitle}</p>
                  <div className="mt-4 flex items-center justify-between border-t pt-3">
                    <div className="flex items-center gap-2">
                      <Switch
                        checked={b.active}
                        disabled={!canEdit}
                        onCheckedChange={(active) =>
                          bannerMutations.update.mutate({ id: b.id, patch: { active }, label: b.title })
                        }
                      />
                      <span className="text-xs text-muted-foreground">{b.active ? "Đang bật" : "Đang tắt"}</span>
                    </div>
                    <div className="flex gap-1">
                      {canEdit && (
                        <Button size="icon-sm" variant="ghost" onClick={() => setEditingBanner(b)}>
                          <Pencil />
                        </Button>
                      )}
                      {canDelete && (
                        <Button
                          size="icon-sm"
                          variant="ghost"
                          className="text-danger"
                          onClick={() => setDelBanner(b)}
                        >
                          <Trash2 />
                        </Button>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </>
      )}

      {/* TAB 2: QUY TẮC MẸO VI KHÍ HẬU THÍCH ỨNG (GIỮ NGUYÊN) */}
      {activeTab === "weather_rules" && (
        <>
          <div className="mb-4 flex items-center justify-between">
            <div>
              <h3 className="text-sm font-semibold text-foreground">Hệ thống thích ứng vi khí hậu thông minh</h3>
              <p className="text-xs text-muted-foreground">
                Khi thời tiết có biến động (nắng gắt, rét lạnh, mưa ẩm, khô hanh, bão gió), app tự động ưu tiên thay thế câu thoại giờ giấc bằng mẹo bảo vệ cây tương ứng.
              </p>
            </div>
          </div>

          <div className="grid gap-3.5 md:grid-cols-2 xl:grid-cols-3">
            {sortedRules.map((r) => (
              <div
                key={r.id}
                className={`card-surface flex flex-col justify-between p-4 transition-all ${
                  r.active ? "border-forest/40 bg-surface-1" : "opacity-65 bg-surface-2"
                }`}
              >
                <div>
                  <div className="flex items-start justify-between gap-2 mb-2.5">
                    <div className="flex items-center gap-2">
                      <div className="grid size-8 place-items-center rounded-xl bg-surface-2 border border-border/60">
                        {getRuleIcon(r.conditionType)}
                      </div>
                      <div>
                        <h4 className="font-bold text-sm text-foreground leading-tight">{r.title || r.name}</h4>
                        <span className="text-[11px] font-semibold text-primary">{r.badgeText}</span>
                      </div>
                    </div>
                    <span className="rounded-md bg-forest/10 px-2 py-0.5 text-[10.5px] font-bold text-forest border border-forest/20 shrink-0">
                      Ưu tiên: {r.priority ?? 50}
                    </span>
                  </div>

                  {/* Khung điều kiện kích hoạt */}
                  <div className="mb-3 rounded-lg bg-surface-2/80 px-2.5 py-1.5 text-xs flex items-center justify-between border border-border/50">
                    <span className="text-muted-foreground text-[11px]">Điều kiện kích hoạt:</span>
                    <span className="font-semibold text-foreground text-[11px]">{getConditionDescription(r)}</span>
                  </div>

                  {/* Lời khuyên chăm sóc */}
                  <div className="rounded-xl bg-surface-2 p-2.5 border border-border/40">
                    <p className="text-xs text-foreground/90 italic leading-relaxed">"{r.advice || r.tip}"</p>
                  </div>
                </div>

                <div className="mt-3.5 flex items-center justify-between border-t border-border/60 pt-2.5">
                  <div className="flex items-center gap-2">
                    <Switch
                      checked={r.active}
                      disabled={!canEdit}
                      onCheckedChange={(active) =>
                        ruleMutations.update.mutate({ id: r.id, patch: { active }, label: r.title ?? r.name })
                      }
                    />
                    <span className="text-[11px] text-muted-foreground">{r.active ? "Kích hoạt" : "Tạm ngưng"}</span>
                  </div>
                  <div className="flex gap-1">
                    {canEdit && (
                      <Button size="icon-sm" variant="ghost" onClick={() => setEditingRule(r)}>
                        <Pencil />
                      </Button>
                    )}
                    {canDelete && (
                      <Button size="icon-sm" variant="ghost" className="text-danger" onClick={() => setDelRule(r)}>
                        <Trash2 />
                      </Button>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </>
      )}

      {/* FORM DIALOG: SỬA/THÊM BANNER (GIỮ NGUYÊN GỐC) */}
      <FormDialog
        open={editingBanner !== undefined}
        onOpenChange={(o) => !o && setEditingBanner(undefined)}
        title={editingBanner ? `Sửa banner · ${editingBanner.title}` : "Thêm banner mới"}
        onSubmit={submitBanner}
      >
        <div className="grid gap-4">
          <Field label="Ảnh banner">
            <ImageUploader
              value={bannerForm.image}
              aspect="wide"
              onChange={(image) => setBannerForm({ ...bannerForm, image })}
            />
          </Field>
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label="Tiêu đề chính (mainTitle)">
              <Input
                value={bannerForm.title}
                onChange={(e) => setBannerForm({ ...bannerForm, title: e.target.value })}
              />
            </Field>
            <Field label="Nhãn khung giờ (badgeText)">
              <Input
                value={bannerForm.cta}
                onChange={(e) => setBannerForm({ ...bannerForm, cta: e.target.value })}
                placeholder="VD: Khung giờ chiều mát"
              />
            </Field>
            <Field label="Lời khuyên chăm sóc (advice)" className="sm:col-span-2">
              <Input
                value={bannerForm.subtitle}
                onChange={(e) => setBannerForm({ ...bannerForm, subtitle: e.target.value })}
              />
            </Field>
            <Field label="Giờ bắt đầu (startHour: 0–23)">
              <Input
                type="number"
                min={0}
                max={23}
                value={bannerForm.startHour ?? 6}
                onChange={(e) => {
                  const h = Math.min(23, Math.max(0, Number(e.target.value) || 0));
                  setBannerForm({ ...bannerForm, startHour: h, order: h });
                }}
              />
            </Field>
            <Field label="Giờ kết thúc (endHour: 0–23)">
              <Input
                type="number"
                min={0}
                max={23}
                value={bannerForm.endHour ?? 10}
                onChange={(e) =>
                  setBannerForm({
                    ...bannerForm,
                    endHour: Math.min(23, Math.max(0, Number(e.target.value) || 0)),
                  })
                }
              />
            </Field>
          </div>
        </div>
      </FormDialog>

      {/* FORM DIALOG: SỬA/THÊM QUY TẮC MẸO VI KHÍ HẬU (TAB 2) */}
      <FormDialog
        open={editingRule !== undefined}
        onOpenChange={(o) => !o && setEditingRule(undefined)}
        title={
          editingRule
            ? `Sửa quy tắc vi khí hậu · ${editingRule.title || editingRule.name}`
            : "Thêm quy tắc vi khí hậu mới"
        }
        onSubmit={submitRule}
      >
        <div className="grid gap-3.5">
          <Field label="Tên quy tắc">
            <Input
              value={ruleForm.title || ruleForm.name}
              onChange={(e) => setRuleForm({ ...ruleForm, title: e.target.value, name: e.target.value })}
              placeholder="VD: Nắng nóng gay gắt, Thời tiết trở lạnh..."
            />
          </Field>

          <div className="grid gap-3 sm:grid-cols-2">
            <Field label="Loại điều kiện vi khí hậu">
              <select
                className="w-full rounded-lg border border-border bg-surface-1 px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-1 focus:ring-primary"
                value={ruleForm.conditionType}
                onChange={(e) =>
                  setRuleForm({
                    ...ruleForm,
                    conditionType: e.target.value as WeatherRule["conditionType"],
                  })
                }
              >
                <option value="temperature_high">Nhiệt độ cao (Nắng nóng)</option>
                <option value="temperature_low">Nhiệt độ thấp (Trời rét lạnh)</option>
                <option value="rain">Mưa dầm & Độ ẩm cao</option>
                <option value="humidity_low">Độ ẩm thấp (Khô hanh)</option>
                <option value="storm_wind">Dông lốc & Gió mạnh</option>
              </select>
            </Field>

            <Field label="Độ ưu tiên (Priority 0–100)">
              <Input
                type="number"
                min={0}
                max={100}
                value={ruleForm.priority ?? 50}
                onChange={(e) => setRuleForm({ ...ruleForm, priority: Number(e.target.value) || 0 })}
              />
            </Field>
          </div>

          {/* Các trường ngưỡng số phụ thuộc loại điều kiện */}
          {ruleForm.conditionType === "temperature_high" && (
            <Field label="Ngưỡng nhiệt độ tối thiểu (°C) kích hoạt mẹo">
              <Input
                type="number"
                value={ruleForm.minTemp ?? 33}
                onChange={(e) => setRuleForm({ ...ruleForm, minTemp: Number(e.target.value) || 33 })}
                placeholder="VD: 33 (khi nhiệt độ ≥ 33°C sẽ hiện mẹo)"
              />
            </Field>
          )}

          {ruleForm.conditionType === "temperature_low" && (
            <Field label="Ngưỡng nhiệt độ tối đa (°C) kích hoạt mẹo">
              <Input
                type="number"
                value={ruleForm.maxTemp ?? 18}
                onChange={(e) => setRuleForm({ ...ruleForm, maxTemp: Number(e.target.value) || 18 })}
                placeholder="VD: 18 (khi nhiệt độ < 18°C sẽ hiện mẹo)"
              />
            </Field>
          )}

          {ruleForm.conditionType === "rain" && (
            <Field label="Ngưỡng độ ẩm cao (%)">
              <Input
                type="number"
                value={ruleForm.minHumidity ?? 85}
                onChange={(e) => setRuleForm({ ...ruleForm, minHumidity: Number(e.target.value) || 85 })}
                placeholder="VD: 85 (khi độ ẩm ≥ 85% hoặc có mưa)"
              />
            </Field>
          )}

          {ruleForm.conditionType === "humidity_low" && (
            <Field label="Ngưỡng độ ẩm thấp (%)">
              <Input
                type="number"
                value={ruleForm.maxHumidity ?? 50}
                onChange={(e) => setRuleForm({ ...ruleForm, maxHumidity: Number(e.target.value) || 50 })}
                placeholder="VD: 50 (khi độ ẩm ≤ 50% sẽ hiện mẹo)"
              />
            </Field>
          )}

          {ruleForm.conditionType === "storm_wind" && (
            <Field label="Ngưỡng tốc độ gió tối thiểu (km/h)">
              <Input
                type="number"
                value={ruleForm.minWindSpeed ?? 25}
                onChange={(e) => setRuleForm({ ...ruleForm, minWindSpeed: Number(e.target.value) || 25 })}
                placeholder="VD: 25"
              />
            </Field>
          )}

          <Field label="Nhãn cảnh báo (badgeText)">
            <Input
              value={ruleForm.badgeText}
              onChange={(e) => setRuleForm({ ...ruleForm, badgeText: e.target.value })}
              placeholder="VD: Nhiệt độ cao • Chống sốc nhiệt"
            />
          </Field>

          <Field label="Nội dung lời khuyên vi khí hậu (advice)">
            <Textarea
              rows={3}
              value={ruleForm.advice || ruleForm.tip}
              onChange={(e) => setRuleForm({ ...ruleForm, advice: e.target.value, tip: e.target.value })}
              placeholder="Nội dung hướng dẫn xử lý cây khi thời tiết chạm ngưỡng..."
            />
          </Field>
        </div>
      </FormDialog>

      {/* CONFIRM DIALOG: XOÁ BANNER (GIỮ NGUYÊN GỐC) */}
      <ConfirmDialog
        open={!!delBanner}
        onOpenChange={(o) => !o && setDelBanner(null)}
        title={`Xoá banner "${delBanner?.title}"?`}
        tone="danger"
        confirmLabel="Xoá"
        onConfirm={() => delBanner && bannerMutations.remove.mutate({ id: delBanner.id, label: delBanner.title })}
      />

      {/* CONFIRM DIALOG: XOÁ RULE (TAB 2) */}
      <ConfirmDialog
        open={!!delRule}
        onOpenChange={(o) => !o && setDelRule(null)}
        title={`Xoá quy tắc "${delRule?.title || delRule?.name}"?`}
        tone="danger"
        confirmLabel="Xoá"
        onConfirm={() =>
          delRule &&
          ruleMutations.remove.mutate({ id: delRule.id, label: delRule.title ?? delRule.name })
        }
      />
    </>
  );
}
