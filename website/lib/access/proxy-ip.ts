import { isIP } from "node:net"

export function trustedClientIp(forwardedFor: string | null, trustedProxyCount = 1): string | null {
  if (!Number.isInteger(trustedProxyCount) || trustedProxyCount < 1 || trustedProxyCount > 5 || !forwardedFor) return null
  const chain = forwardedFor.split(",").map(value => value.trim())
  if (!chain.length || chain.length < trustedProxyCount) return null
  // The proxy must overwrite or sanitize client-supplied forwarding headers.
  const candidate = chain[Math.max(0, chain.length - trustedProxyCount - 1)]
  return isIP(candidate) ? candidate : null
}
