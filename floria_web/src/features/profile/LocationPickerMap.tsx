"use client";

import { useEffect, useRef } from "react";
import L from "leaflet";

const DEFAULT_CENTER: [number, number] = [21.0285, 105.8542]; // Hà Nội viewport fallback only (does not save until user picks)

const PIN_ICON = L.divIcon({
  className: "",
  html: `<div style="width:28px;height:28px;border-radius:9999px;background:#174B35;border:3px solid #ffffff;box-shadow:0 4px 12px rgba(0,0,0,0.28);display:flex;align-items:center;justify-content:center;"><div style="width:8px;height:8px;border-radius:9999px;background:#A8C99A;"></div></div>`,
  iconSize: [28, 28],
  iconAnchor: [14, 14],
});

export function LocationPickerMap({
  latitude,
  longitude,
  onChange,
}: {
  latitude: number | null;
  longitude: number | null;
  onChange: (lat: number, lng: number) => void;
}) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<L.Map | null>(null);
  const markerRef = useRef<L.Marker | null>(null);
  const onChangeRef = useRef(onChange);
  onChangeRef.current = onChange;

  useEffect(() => {
    const el = containerRef.current;
    if (!el || mapRef.current) return;

    const initial: [number, number] =
      latitude !== null && longitude !== null ? [latitude, longitude] : DEFAULT_CENTER;

    const map = L.map(el, {
      center: initial,
      zoom: latitude !== null && longitude !== null ? 15 : 12,
      scrollWheelZoom: true,
    });

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap",
      maxZoom: 19,
    }).addTo(map);

    const placeMarker = (lat: number, lng: number) => {
      if (markerRef.current) {
        markerRef.current.setLatLng([lat, lng]);
      } else {
        const marker = L.marker([lat, lng], { draggable: true, icon: PIN_ICON }).addTo(map);
        marker.on("dragend", () => {
          const pos = marker.getLatLng();
          onChangeRef.current(Number(pos.lat.toFixed(6)), Number(pos.lng.toFixed(6)));
        });
        markerRef.current = marker;
      }
    };

    if (latitude !== null && longitude !== null) {
      placeMarker(latitude, longitude);
    }

    map.on("click", (ev: L.LeafletMouseEvent) => {
      const lat = Number(ev.latlng.lat.toFixed(6));
      const lng = Number(ev.latlng.lng.toFixed(6));
      placeMarker(lat, lng);
      onChangeRef.current(lat, lng);
    });

    mapRef.current = map;

    return () => {
      map.remove();
      mapRef.current = null;
      markerRef.current = null;
    };
  }, []);

  useEffect(() => {
    const map = mapRef.current;
    if (!map) return;
    if (latitude === null || longitude === null) {
      if (markerRef.current) {
        markerRef.current.remove();
        markerRef.current = null;
      }
      return;
    }
    if (markerRef.current) {
      markerRef.current.setLatLng([latitude, longitude]);
    } else {
      const marker = L.marker([latitude, longitude], { draggable: true, icon: PIN_ICON }).addTo(map);
      marker.on("dragend", () => {
        const pos = marker.getLatLng();
        onChangeRef.current(Number(pos.lat.toFixed(6)), Number(pos.lng.toFixed(6)));
      });
      markerRef.current = marker;
    }
    map.setView([latitude, longitude], Math.max(map.getZoom(), 14));
  }, [latitude, longitude]);

  return (
    <div
      ref={containerRef}
      className="h-60 w-full overflow-hidden rounded-2xl border bg-muted"
      aria-label="Bản đồ chọn tọa độ"
    />
  );
}
