export const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY ?? "AIzaSyCglRzctd1gZ_XixaWzBJWiUrZ8y-C6lzY",
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN ?? "floria-71734.firebaseapp.com",
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID ?? "floria-71734",
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID ?? "1:896398806405:web:3780a39824439810e148ec",
};

export const isFirebaseConfigured = () => Boolean(firebaseConfig.apiKey && firebaseConfig.projectId);

/** Firestore document path for user profiles. */
export const userDocPath = (uid: string) => `Users/${uid}`;
