import { getApp, getApps, initializeApp, type FirebaseOptions } from "firebase/app";
import { getAuth, GoogleAuthProvider } from "firebase/auth";

function resolveAuthDomain(): string {
  if (process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN) {
    return process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN;
  }
  if (typeof window !== "undefined") {
    const host = window.location.hostname;
    if (host === "localhost" || host === "127.0.0.1") {
      return "floria-71734.firebaseapp.com";
    }
    return host;
  }
  return "floria.id.vn";
}

const firebaseConfig: FirebaseOptions = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY ?? "AIzaSyCglRzctd1gZ_XixaWzBJWiUrZ8y-C6lzY",
  authDomain: resolveAuthDomain(),
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID ?? "floria-71734",
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET ?? "floria-71734.firebasestorage.app",
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID ?? "896398806405",
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID ?? "1:896398806405:web:3780a39824439810e148ec",
};

export function getFirebaseClientApp() {
  return getApps().length > 0 ? getApp() : initializeApp(firebaseConfig);
}

export function getFirebaseClientAuth() {
  return getAuth(getFirebaseClientApp());
}

export const googleAuthProvider = new GoogleAuthProvider();

export async function getFirebaseIdToken(forceRefresh = false): Promise<string | null> {
  if (typeof window === "undefined") return null;
  const auth = getFirebaseClientAuth();
  await auth.authStateReady();
  const user = auth.currentUser;
  if (!user) return null;
  return user.getIdToken(forceRefresh);
}
