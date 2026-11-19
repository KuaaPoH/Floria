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

async function probeHttp(id: string, name: string, url: string): Promise<ServiceProbe> {
  const start = Date.now();
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 3000);
    const res = await fetch(url, { signal: controller.signal, cache: "no-store" });
    clearTimeout(timer);
    const latencyMs = Date.now() - start;
    return {
      id,
      name,
      status: res.ok ? (latencyMs > 1000 ? "degraded" : "healthy") : "degraded",
      latencyMs,
      detail: `HTTP ${res.status}`,
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

  // 2. AI Engine & Spring Boot Backend
  const aiUrl = process.env.AI_ENGINE_URL ?? "http://localhost:8000";
  const springUrl = process.env.SPRING_BACKEND_URL ?? "http://localhost:8080";

  const [aiProbe, springProbe] = await Promise.all([
    probeHttp("ai-engine", "AI Engine (FastAPI)", `${aiUrl}/docs`),
    probeHttp("spring-backend", "Spring Boot Gateway", `${springUrl}/api/ping`),
  ]);

  probes.push(aiProbe, springProbe);

  return NextResponse.json({
    ok: probes.every((p) => p.status !== "down"),
    checkedAt: new Date().toISOString(),
    services: probes,
  });
}
