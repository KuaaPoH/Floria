import { NextResponse } from "next/server";
import { getAdminDb, isFirebaseAdminConfigured } from "@/lib/server/firebase-admin";

interface ServiceProbe {
  id: string;
  name: string;
  status: "healthy" | "degraded" | "down";
  latencyMs: number;
  detail?: string;
}

const FIRESTORE_PROBE_TTL_MS = 60_000;
let cachedFirestoreProbe: { probe: ServiceProbe; expiresAt: number } | null = null;

async function probeHttp(
  id: string,
  name: string,
  url: string,
  options?: { method?: string; treat4xxAsHealthy?: boolean; healthyDetail?: string },
): Promise<ServiceProbe> {
  const start = Date.now();
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 3500);
    const res = await fetch(url, {
      method: options?.method ?? "GET",
      signal: controller.signal,
      cache: "no-store",
    });
    clearTimeout(timer);
    const latencyMs = Date.now() - start;
    const isHealthyHttp = res.ok || (options?.treat4xxAsHealthy && res.status < 500);
    return {
      id,
      name,
      status: isHealthyHttp ? (latencyMs > 1500 ? "degraded" : "healthy") : "degraded",
      latencyMs,
      detail: isHealthyHttp && options?.healthyDetail ? options.healthyDetail : `HTTP ${res.status}`,
    };
  } catch (err) {
    return {
      id,
      name,
      status: "down",
      latencyMs: Date.now() - start,
      detail: err instanceof Error ? err.message : "Không thể kết nối",
    };
  }
}

export async function GET() {
  const probes: ServiceProbe[] = [];

  // 1. Firebase Firestore (cache 60s để tránh tốn quota đọc lặp lại)
  const fbStart = Date.now();
  if (!isFirebaseAdminConfigured()) {
    probes.push({
      id: "firestore",
      name: "Cloud Firestore",
      status: "down",
      latencyMs: Date.now() - fbStart,
      detail: "Chưa cấu hình serviceAccountKey.json",
    });
  } else if (cachedFirestoreProbe && cachedFirestoreProbe.expiresAt > Date.now()) {
    probes.push(cachedFirestoreProbe.probe);
  } else {
    try {
      await getAdminDb().collection("plants_info").limit(1).get();
      const latencyMs = Date.now() - fbStart;
      const probe: ServiceProbe = {
        id: "firestore",
        name: "Cloud Firestore",
        status: latencyMs > 1200 ? "degraded" : "healthy",
        latencyMs,
      };
      cachedFirestoreProbe = { probe, expiresAt: Date.now() + FIRESTORE_PROBE_TTL_MS };
      probes.push(probe);
    } catch (err) {
      probes.push({
        id: "firestore",
        name: "Cloud Firestore",
        status: "down",
        latencyMs: Date.now() - fbStart,
        detail: err instanceof Error ? err.message : "Lỗi truy vấn Firestore",
      });
    }
  }

  // 2. AI Engine, Spring Boot Gateway, Cloudinary CDN & ZaloPay Sandbox
  const aiUrl = process.env.AI_ENGINE_URL ?? "http://localhost:8000";
  const springUrl = process.env.SPRING_BACKEND_URL ?? "http://localhost:8080";
  const cloudinaryCloud = process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME ?? "vbiltn75";

  const [aiProbe, springProbe, cloudinaryProbe, zalopayProbe] = await Promise.all([
    probeHttp("ai-engine", "AI Engine (FastAPI)", `${aiUrl}/docs`),
    probeHttp("spring-backend", "Spring Boot Gateway", `${springUrl}/api/ping`),
    probeHttp(
      "cloudinary",
      "Cloudinary CDN",
      `https://res.cloudinary.com/${cloudinaryCloud}/image/upload/sample.jpg`,
      { method: "HEAD", treat4xxAsHealthy: true, healthyDetail: `Cloud: ${cloudinaryCloud}` },
    ),
    probeHttp(
      "zalopay",
      "ZaloPay Sandbox",
      "https://sb-openapi.zalopay.vn/v2/query",
      { method: "POST", treat4xxAsHealthy: true, healthyDetail: "OpenAPI v2 (Sandbox)" },
    ),
  ]);

  probes.push(aiProbe, springProbe, cloudinaryProbe, zalopayProbe);

  return NextResponse.json({
    ok: probes.every((p) => p.status !== "down"),
    checkedAt: new Date().toISOString(),
    services: probes,
  });
}
