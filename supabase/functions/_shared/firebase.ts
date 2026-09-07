import { cert, getApps, initializeApp } from "npm:firebase-admin@13.4.0/app";
import { getFirestore } from "npm:firebase-admin@13.4.0/firestore";
import { getMessaging } from "npm:firebase-admin@13.4.0/messaging";
import { createRemoteJWKSet, jwtVerify } from "npm:jose@5.10.0";
import { HttpError } from "./http.ts";

export type VerifiedFirebaseUser = {
  uid: string;
  sub: string;
  email?: string;
  name?: string;
  [key: string]: unknown;
};

const firebaseJwks = createRemoteJWKSet(new URL(
  "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
));

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

let firestore: ReturnType<typeof getFirestore> | undefined;

function firebaseFirestore() {
  if (firestore) return firestore;
  firestore = getFirestore(firebaseApp());
  // Supabase Edge Functions run on Deno Deploy, where the Firestore gRPC
  // transport can stall. Force the supported HTTP/1.1 REST transport.
  firestore.settings({ preferRest: true });
  return firestore;
}

export const firebase = {
  db: firebaseFirestore,
  messaging: () => getMessaging(firebaseApp()),
};

export async function verifyFirebaseUser(request: Request): Promise<VerifiedFirebaseUser> {
  const value = request.headers.get("authorization") ?? "";
  const match = /^Bearer\s+(.+)$/i.exec(value);
  if (!match?.[1]) throw new HttpError(401, "unauthenticated", "Sign in again to continue.");
  try {
    const projectId = Deno.env.get("FIREBASE_PROJECT_ID") ?? "cie-connect";
    const { payload } = await jwtVerify(match[1], firebaseJwks, {
      algorithms: ["RS256"],
      audience: projectId,
      issuer: `https://securetoken.google.com/${projectId}`,
      clockTolerance: 5,
    });
    if (!payload.sub || payload.sub.length > 128) throw new Error("Invalid Firebase subject");
    return {
      ...payload,
      uid: payload.sub,
      sub: payload.sub,
      email: typeof payload.email === "string" ? payload.email : undefined,
      name: typeof payload.name === "string" ? payload.name : undefined,
    };
  } catch (error) {
    console.error("Firebase ID token verification failed", {
      name: error instanceof Error ? error.name : "unknown",
      code: (error as { code?: string })?.code ?? "unknown",
    });
    throw new HttpError(401, "unauthenticated", "Your session expired. Sign in again.");
  }
}
