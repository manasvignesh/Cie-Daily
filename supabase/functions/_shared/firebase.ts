import { cert, getApps, initializeApp } from "npm:firebase-admin@13.4.0/app";
import { getAuth, type DecodedIdToken } from "npm:firebase-admin@13.4.0/auth";
import { getFirestore } from "npm:firebase-admin@13.4.0/firestore";
import { getMessaging } from "npm:firebase-admin@13.4.0/messaging";
import { HttpError } from "./http.ts";

function serviceAccount(): Record<string, string> {
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  if (!raw) throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON is not configured");
  const parsed = JSON.parse(raw) as Record<string, string>;
  if (!parsed.project_id || !parsed.client_email || !parsed.private_key) {
    throw new Error("Firebase service account is incomplete");
  }
  parsed.private_key = parsed.private_key.replace(/\\n/g, "\n");
  return parsed;
}

function firebaseApp() {
  if (getApps().length) return getApps()[0];
  const account = serviceAccount();
  const expectedProject = Deno.env.get("FIREBASE_PROJECT_ID") ?? "cie-connect";
  if (account.project_id !== expectedProject) throw new Error("Firebase project mismatch");
  return initializeApp({
    credential: cert({
      projectId: account.project_id,
      clientEmail: account.client_email,
      privateKey: account.private_key,
    }),
  });
}

export const firebase = {
  auth: () => getAuth(firebaseApp()),
  db: () => getFirestore(firebaseApp()),
  messaging: () => getMessaging(firebaseApp()),
};

export async function verifyFirebaseUser(request: Request): Promise<DecodedIdToken> {
  const value = request.headers.get("authorization") ?? "";
  const match = /^Bearer\s+(.+)$/i.exec(value);
  if (!match?.[1]) throw new HttpError(401, "unauthenticated", "Sign in again to continue.");
  try {
    return await firebase.auth().verifyIdToken(match[1], true);
  } catch {
    throw new HttpError(401, "unauthenticated", "Your session expired. Sign in again.");
  }
}
