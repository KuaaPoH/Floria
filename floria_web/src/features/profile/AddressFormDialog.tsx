"use client";

import { useEffect, useState } from "react";
import dynamic from "next/dynamic";
import { zodResolver } from "@hookform/resolvers/zod";
import { Controller, useForm } from "react-hook-form";
import { Loader2, MapPin, X } from "lucide-react";
import { toast } from "sonner";
import { z } from "zod";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Field } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { useAddressMutations, useProvinces, useWards } from "@/hooks/queries";
import type { Address } from "@/types/user";

const LocationPickerMap = dynamic(
  () => import("./LocationPickerMap").then((m) => m.LocationPickerMap),
  { ssr: false, loading: () => <div className="grid h-60 place-items-center rounded-2xl border bg-muted text-xs text-muted-foreground">Đang tải bản đồ…</div> },
);

const schema = z.object({
  label: z.string().max(30).optional(),
  recipientName: z.string().trim().min(2, "Nhập tên người nhận"),
  phone: z.string().trim().regex(/^[0-9\s+.-]{9,15}$/, "Số điện thoại không hợp lệ"),
  provinceCode: z.string().min(1, "Chọn Tỉnh/Thành phố"),
  wardCode: z.string().min(1, "Chọn Phường/Xã"),
  street: z.string().trim().min(3, "Nhập số nhà, tên đường"),
  isDefault: z.boolean(),
});
type Values = z.infer<typeof schema>;

export function AddressFormDialog({
  open,
  onOpenChange,
  address,
  onSaved,
}: {
  open: boolean;
  onOpenChange: (o: boolean) => void;
  address?: Address;
  onSaved?: (saved: Address) => void;
}) {
  const { save } = useAddressMutations();
  const provincesQ = useProvinces();
  const [selectedProvinceId, setSelectedProvinceId] = useState<string | null>(null);
  const [coords, setCoords] = useState<{ lat: number | null; lng: number | null }>({ lat: null, lng: null });

  const form = useForm<Values>({
    resolver: zodResolver(schema),
    defaultValues: {
      label: "",
      recipientName: "",
      phone: "",
      provinceCode: "",
      wardCode: "",
      street: "",
      isDefault: false,
    },
  });

  const provinceCode = form.watch("provinceCode");
  const wardCode = form.watch("wardCode");
  const provinces = provincesQ.data ?? [];

  useEffect(() => {
    if (!open) return;
    if (address) {
      form.reset({
        label: address.label ?? "",
        recipientName: address.recipientName,
        phone: address.phone,
        provinceCode: address.provinceCode,
        wardCode: address.wardCode,
        street: address.street,
        isDefault: address.isDefault,
      });
      setCoords({ lat: address.latitude, lng: address.longitude });
    } else {
      form.reset({ label: "", recipientName: "", phone: "", provinceCode: "", wardCode: "", street: "", isDefault: false });
      setCoords({ lat: null, lng: null });
    }
  }, [open, address, form]);

  useEffect(() => {
    if (!provinceCode || !provinces.length) {
      setSelectedProvinceId(null);
      return;
    }
    const found = provinces.find((p) => p.code === provinceCode || p.id === provinceCode);
    setSelectedProvinceId(found?.id ?? null);
  }, [provinceCode, provinces]);

  const wardsQ = useWards(selectedProvinceId);
  const wards = wardsQ.data ?? [];

  const onSubmit = form.handleSubmit(async (v) => {
    const prov = provinces.find((p) => p.code === v.provinceCode || p.id === v.provinceCode);
    const ward = wards.find((w) => w.code === v.wardCode || w.id === v.wardCode);
    const saved = await save.mutateAsync({
      id: address?.id,
      label: v.label?.trim() || undefined,
      recipientName: v.recipientName.trim(),
      phone: v.phone.trim(),
      provinceCode: prov?.code ?? v.provinceCode,
      provinceName: prov?.name ?? address?.provinceName ?? "",
      wardCode: ward?.code ?? v.wardCode,
      wardName: ward?.name ?? address?.wardName ?? "",
      street: v.street.trim(),
      latitude: coords.lat,
      longitude: coords.lng,
      isDefault: v.isDefault,
    });
    toast.success(address ? "Đã cập nhật địa chỉ" : "Đã thêm địa chỉ mới");
    onOpenChange(false);
    onSaved?.(saved);
  });

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[92vh] overflow-y-auto rounded-3xl sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>{address ? "Chỉnh sửa địa chỉ" : "Thêm địa chỉ mới"}</DialogTitle>
        </DialogHeader>
        <form onSubmit={onSubmit} className="space-y-4" noValidate>
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label="Người nhận" htmlFor="addr-name" error={form.formState.errors.recipientName?.message}>
              <Input id="addr-name" placeholder="Nguyễn Minh Anh" {...form.register("recipientName")} />
            </Field>
            <Field label="Số điện thoại" htmlFor="addr-phone" error={form.formState.errors.phone?.message}>
              <Input id="addr-phone" placeholder="0912345678" {...form.register("phone")} />
            </Field>
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <Field label="Tỉnh / Thành phố (34 tỉnh/thành)" htmlFor="addr-prov" error={form.formState.errors.provinceCode?.message}>
              <Select
                value={provinceCode}
                onValueChange={(val) => {
                  form.setValue("provinceCode", val, { shouldValidate: true });
                  form.setValue("wardCode", "");
                }}
              >
                <SelectTrigger id="addr-prov" className="h-11 rounded-[10px]">
                  <SelectValue placeholder={provincesQ.isLoading ? "Đang tải tỉnh/thành…" : "Chọn Tỉnh/Thành phố"} />
                </SelectTrigger>
                <SelectContent>
                  {provinces.map((p) => (
                    <SelectItem key={p.id} value={p.code}>{p.name}</SelectItem>
                  ))}
                  {address && !provinces.some((p) => p.code === address.provinceCode) && (
                    <SelectItem value={address.provinceCode}>{address.provinceName}</SelectItem>
                  )}
                </SelectContent>
              </Select>
            </Field>

            <Field label="Phường / Xã" htmlFor="addr-ward" error={form.formState.errors.wardCode?.message}>
              <Select
                value={wardCode}
                disabled={!provinceCode}
                onValueChange={(val) => form.setValue("wardCode", val, { shouldValidate: true })}
              >
                <SelectTrigger id="addr-ward" className="h-11 rounded-[10px]">
                  <SelectValue placeholder={!provinceCode ? "Chọn Tỉnh/Thành trước" : wardsQ.isLoading ? "Đang tải phường/xã…" : "Chọn Phường/Xã"} />
                </SelectTrigger>
                <SelectContent>
                  {wards.map((w) => (
                    <SelectItem key={w.id} value={w.code}>{w.name}</SelectItem>
                  ))}
                  {address && address.provinceCode === provinceCode && !wards.some((w) => w.code === address.wardCode) && (
                    <SelectItem value={address.wardCode}>{address.wardName}</SelectItem>
                  )}
                </SelectContent>
              </Select>
            </Field>
          </div>

          <div className="grid gap-4 sm:grid-cols-[1.4fr_1fr]">
            <Field label="Địa chỉ chi tiết" htmlFor="addr-street" error={form.formState.errors.street?.message}>
              <Input id="addr-street" placeholder="Số nhà, ngõ, tên đường…" {...form.register("street")} />
            </Field>
            <Field label="Nhãn (tùy chọn)" htmlFor="addr-label">
              <Input id="addr-label" placeholder="Nhà riêng, Văn phòng…" {...form.register("label")} />
            </Field>
          </div>

          <div className="space-y-2">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <span className="flex items-center gap-1.5 text-sm font-semibold">
                <MapPin className="size-4 text-leaf" /> Ghim tọa độ GPS (dùng cho WeatherCard & giao hàng)
              </span>
              {coords.lat !== null && coords.lng !== null && (
                <button
                  type="button"
                  onClick={() => setCoords({ lat: null, lng: null })}
                  className="inline-flex items-center gap-1 text-xs font-medium text-muted-foreground hover:text-danger"
                >
                  <X className="size-3.5" /> Xóa ghim
                </button>
              )}
            </div>
            <LocationPickerMap
              latitude={coords.lat}
              longitude={coords.lng}
              onChange={(lat, lng) => setCoords({ lat, lng })}
            />
            <p className="text-xs text-muted-foreground">
              {coords.lat !== null && coords.lng !== null
                ? `Tọa độ đã chọn: ${coords.lat}, ${coords.lng} (kéo marker hoặc bấm lên bản đồ để điều chỉnh)`
                : "Bấm lên bản đồ để ghim tọa độ thực tế. Floria không tự tạo tọa độ GPS giả."}
            </p>
          </div>

          <label className="flex items-center gap-2 text-sm">
            <Controller
              control={form.control}
              name="isDefault"
              render={({ field }) => <Checkbox checked={field.value} onCheckedChange={(c) => field.onChange(c === true)} />}
            />
            Đặt làm địa chỉ mặc định
          </label>

          <DialogFooter>
            <Button type="button" variant="ghost" onClick={() => onOpenChange(false)}>Hủy</Button>
            <Button type="submit" disabled={save.isPending}>
              {save.isPending && <Loader2 className="animate-spin" />} Lưu địa chỉ
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
