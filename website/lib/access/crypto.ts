import { createHash, randomBytes, timingSafeEqual } from "node:crypto"

export function token(): string { return randomBytes(32).toString("base64url") }
export function digest(value: string): string { return createHash("sha256").update(value).digest("hex") }
export function pkceMatches(verifier: string, challenge: string): boolean {
  if (!/^[A-Za-z0-9._~-]{43,128}$/.test(verifier)) return false
  const actual = createHash("sha256").update(verifier).digest("base64url")
  if (actual.length !== challenge.length) return false
  return timingSafeEqual(Buffer.from(actual), Buffer.from(challenge))
}
