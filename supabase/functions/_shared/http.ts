export class HttpError extends Error {
  constructor(public status: number, public code: string, message: string) {
    super(message);
  }
}

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

export function errorResponse(error: unknown): Response {
  if (error instanceof HttpError) {
    return json({ error: error.code, message: error.message }, error.status);
  }
  console.error("Edge function failed", {
    name: error instanceof Error ? error.name : "unknown",
  });
  return json({
    error: "service_unavailable",
    message: "The service is temporarily unavailable. Please try again.",
  }, 500);
}

export function bearerToken(request: Request): string {
  const value = request.headers.get("authorization") ?? "";
  const match = /^Bearer\s+(.+)$/i.exec(value);
  if (!match?.[1]) throw new HttpError(401, "unauthenticated", "Sign in again to continue.");
  return match[1];
}

export async function readJson(request: Request): Promise<Record<string, unknown>> {
  if (request.method !== "POST") throw new HttpError(405, "method_not_allowed", "Use POST for this request.");
  const size = Number(request.headers.get("content-length") ?? "0");
  if (size > 1_000_000) throw new HttpError(413, "payload_too_large", "That request is too large.");
  try {
    const body = await request.json();
    if (!body || Array.isArray(body) || typeof body !== "object") throw new Error("invalid");
    return body as Record<string, unknown>;
  } catch {
    throw new HttpError(400, "invalid_request", "The request could not be read.");
  }
}

export function requiredString(
  body: Record<string, unknown>, key: string, maxLength: number,
): string {
  const value = typeof body[key] === "string" ? body[key].trim() : "";
  if (!value || value.length > maxLength) {
    throw new HttpError(400, "invalid_request", `${key} is missing or invalid.`);
  }
  return value;
}
