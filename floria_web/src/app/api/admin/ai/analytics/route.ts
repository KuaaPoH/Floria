import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";

const ANALYTICS_CACHE_TTL_MS = 5 * 60_000;
let cachedAnalytics: { data: unknown; expiresAt: number } | null = null;

export async function GET(req: Request) {
  try {
    await verifyAdminRequest(req);
    const url = new URL(req.url);
    const forceRefresh = url.searchParams.get("refresh") === "1";

    if (!forceRefresh && cachedAnalytics && cachedAnalytics.expiresAt > Date.now()) {
      return NextResponse.json(cachedAnalytics.data);
    }

    const db = getAdminDb();
    const [scansSnap, requestsSnap] = await Promise.all([
      db.collection("ScanHistory").orderBy("timestamp", "desc").limit(400).get(),
      db.collection("PlantRequests").orderBy("createdAt", "desc").limit(200).get(),
    ]);

    const buckets = [
      { bucket: "< 50%", count: 0 },
      { bucket: "50–70%", count: 0 },
      { bucket: "70–85%", count: 0 },
      { bucket: "85–100%", count: 0 },
    ];
    const modelMap = new Map<string, number>();
    const typeMap = new Map<string, number>([
      ["Nhận diện loài", 0],
      ["Chẩn đoán bệnh", 0],
    ]);
    const scannedMap = new Map<string, number>();

    for (const doc of scansSnap.docs) {
      const d = doc.data() ?? {};
      const rawConf = typeof d.confidence === "number" ? d.confidence : null;
      if (rawConf !== null) {
        const pct = rawConf <= 1 ? rawConf * 100 : rawConf;
        if (pct < 50) buckets[0].count++;
        else if (pct < 70) buckets[1].count++;
        else if (pct < 85) buckets[2].count++;
        else buckets[3].count++;
      }

      const model = String(d.modelUsed || "unknown");
      modelMap.set(model, (modelMap.get(model) ?? 0) + 1);

      const scanType = String(d.type ?? "");
      if (scanType === "disease_diagnosis") {
        typeMap.set("Chẩn đoán bệnh", (typeMap.get("Chẩn đoán bệnh") ?? 0) + 1);
      } else {
        typeMap.set("Nhận diện loài", (typeMap.get("Nhận diện loài") ?? 0) + 1);
      }

      const label = String(d.predictionVi || d.prediction || "").trim();
      if (label && label !== "Không phải cây" && label !== "Không hợp lệ") {
        scannedMap.set(label, (scannedMap.get(label) ?? 0) + 1);
      }
    }

    const reportedMap = new Map<string, number>();
    let pendingRequests = 0;
    for (const doc of requestsSnap.docs) {
      const d = doc.data() ?? {};
      if (String(d.status ?? "pending") === "pending") pendingRequests++;
      const label = String(d.predictedNameVi || d.predictedLabel || d.suggestedName || "").trim();
      if (label) {
        reportedMap.set(label, (reportedMap.get(label) ?? 0) + 1);
      }
    }

    const toTop = (m: Map<string, number>, limit = 7) =>
      Array.from(m.entries())
        .sort((a, b) => b[1] - a[1])
        .slice(0, limit)
        .map(([label, count]) => ({ label, count }));

    const payload = {
      generatedAt: new Date().toISOString(),
      sampleSize: scansSnap.size,
      totalRequests: requestsSnap.size,
      pendingRequests,
      confidenceBuckets: buckets,
      modelUsage: Array.from(modelMap.entries())
        .sort((a, b) => b[1] - a[1])
        .map(([model, count]) => ({ model, count })),
      scanTypes: Array.from(typeMap.entries()).map(([name, count]) => ({ name, count })),
      topScanned: toTop(scannedMap),
      topReported: toTop(reportedMap),
    };

    cachedAnalytics = { data: payload, expiresAt: Date.now() + ANALYTICS_CACHE_TTL_MS };
    return NextResponse.json(payload);
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    const msg = err instanceof Error ? err.message : "Lỗi thống kê AI";
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
