export function waitlistEmail(input: unknown): string | null {
  if (!input || typeof input !== "object") return null
  const value = input as Record<string, unknown>
  if (
    value.consent !== true ||
    typeof value.email !== "string" ||
    (value.website !== undefined && value.website !== "")
  )
    return null
  const email = value.email.trim().toLowerCase()
  return email.length <= 254 && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
    ? email
    : null
}
