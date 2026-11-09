export function daysUntilExpiry(token: string, now = Date.now()) {
  try {
    const payload = JSON.parse(Buffer.from(token.split(".")[1] ?? "", "base64url").toString("utf8")) as { exp?: unknown }
    if (typeof payload.exp !== "number" || !Number.isSafeInteger(payload.exp)) throw new Error()
    return Math.floor((payload.exp * 1000 - now) / 86_400_000)
  } catch {
    throw new Error("APPLE_CLIENT_SECRET must be a valid JWT with an exp claim")
  }
}
