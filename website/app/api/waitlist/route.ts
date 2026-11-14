import { createHmac } from "node:crypto"
import type { PoolClient } from "pg"
import { database } from "@/lib/db"
import { trustedClientIp } from "@/lib/access/proxy-ip"
import { waitlistEmail } from "@/lib/waitlist"

export const runtime = "nodejs"
export async function POST(request: Request) {
  const expected = new URL(
    process.env.BETTER_AUTH_URL ?? "https://qyube.brokarim.com"
  ).origin
  if (request.headers.get("origin") !== expected)
    return Response.json({ error: "Invalid origin" }, { status: 403 })
  const body = await request.text()
  if (body.length > 2048)
    return Response.json({ error: "Invalid request" }, { status: 413 })
  let email: string | null
  try {
    email = waitlistEmail(JSON.parse(body))
  } catch {
    email = null
  }
  if (!email)
    return Response.json(
      { error: "A valid email is required" },
      { status: 400 }
    )
  const ip = trustedClientIp(
    request.headers.get("x-forwarded-for"),
    Number(process.env.TRUSTED_PROXY_COUNT ?? "1")
  )
  const secret = process.env.BETTER_AUTH_SECRET
  if (!ip || !secret) {
    console.error("[waitlist] request configuration unavailable", {
      hasClientIp: Boolean(ip),
      hasSecret: Boolean(secret),
    })
    return Response.json(
      { error: "Waitlist temporarily unavailable" },
      { status: 503 }
    )
  }
  const hash = createHmac("sha256", secret).update(ip).digest("hex")
  let client: PoolClient | undefined
  try {
    client = await database().connect()
    await client.query("BEGIN")
    await client.query(
      "SELECT pg_advisory_xact_lock(hashtextextended($1, 2))",
      [hash]
    )
    await client.query(
      "DELETE FROM waitlist_attempts WHERE created_at < now() - interval '1 day'"
    )
    const { rows } = await client.query<{ count: string }>(
      "SELECT count(*) FROM waitlist_attempts WHERE ip_hash=$1 AND created_at > now() - interval '1 hour'",
      [hash]
    )
    if (Number(rows[0].count) >= 5) {
      await client.query("ROLLBACK")
      return Response.json({ error: "Try again later" }, { status: 429 })
    }
    await client.query("INSERT INTO waitlist_attempts(ip_hash) VALUES($1)", [
      hash,
    ])
    await client.query(
      "INSERT INTO waitlist(email,consent_version) VALUES($1,'launch-updates-v1') ON CONFLICT(email) DO NOTHING",
      [email]
    )
    await client.query("COMMIT")
    return Response.json(
      { ok: true },
      { headers: { "Cache-Control": "no-store" } }
    )
  } catch (error) {
    await client?.query("ROLLBACK").catch(() => {})
    const reason =
      error instanceof Error &&
      error.message === "DATABASE_URL is not configured"
        ? error.message
        : error && typeof error === "object" && "code" in error
          ? String(error.code)
          : "unknown"
    console.error("[waitlist] database operation failed", { reason })
    return Response.json(
      { error: "Waitlist temporarily unavailable" },
      { status: 503 }
    )
  } finally {
    client?.release()
  }
}
