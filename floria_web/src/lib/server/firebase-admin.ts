import fs from "node:fs";
import path from "node:path";
import { cert, getApp, getApps, initializeApp, type App, type ServiceAccount } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

function loadServiceAccount(): ServiceAccount | null {
  const inlineJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (inlineJson) {
    try {
      return JSON.parse(inlineJson) as ServiceAccount;
    } catch {
      return null;
    }
  }

  const candidates = [
    process.env.FIREBASE_SERVICE_ACCOUNT_PATH,
    path.resolve(process.cwd(), "serviceAccountKey.json"),
    path.resolve(process.cwd(), "../AI_Engine/serviceAccountKey.json"),
    path.resolve(process.cwd(), "../Backend/serviceAccountKey.json"),
  ].filter((p): p is string => Boolean(p));

  for (const filePath of candidates) {
    if (fs.existsSync(filePath)) {
      try {
        const raw = fs.readFileSync(filePath, "utf-8");
        return JSON.parse(raw) as ServiceAccount;
      } catch {
        // Thử ứng viên tiếp theo nếu file lỗi định dạng
      }
    }
  }
  return null;
}

export function isFirebaseAdminConfigured(): boolean {
  return getApps().length > 0 || loadServiceAccount() !== null;
}

export function getAdminApp(): App {
  if (getApps().length > 0) return getApp();
  const sa = loadServiceAccount();
  if (!sa) {
    throw new Error(
      "Thiếu cấu hình Firebase Admin (serviceAccountKey.json hoặc FIREBASE_SERVICE_ACCOUNT_JSON).",
    );
  }
  return initializeApp({ credential: cert(sa) });
}

export function getAdminAuth() {
  return getAuth(getAdminApp());
}

export function getAdminDb() {
  return getFirestore(getAdminApp());
}

export function getAdminMessaging() {
  return getMessaging(getAdminApp());
}
