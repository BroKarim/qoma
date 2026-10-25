import { authenticatedDevice } from "@/lib/access/native"
import { recomputeEntitlement } from "@/lib/access/entitlements"
import { signSnapshot } from "@/lib/access/signed-snapshot"
import { database } from "@/lib/db"

export const runtime = "nodejs"

export async function GET(request: Request) {
  const device = await authenticatedDevice(request)
  if (!device) return Response.json({ error: "Sign in again" }, { status: 401 })
  const key = process.env.ENTITLEMENT_SIGNING_PRIVATE_KEY
  if (!key) return Response.json({ error: "Entitlement signing is not configured" }, { status: 503 })
  const access = await recomputeEntitlement(device.accountId)
  const { rows } = await database().query<{ version: string; now: Date }>(
    "SELECT version::text, now() AS now FROM entitlements WHERE account_id = $1", [device.accountId],
  )
  const snapshot = {
    account_id: device.accountId,
    device_id: device.deviceId,
    scope: "macos" as const,
    plan: access.plan,
    status: access.status,
    access_until: access.accessUntil?.toISOString() ?? null,
    offline_until: access.offlineUntil?.toISOString() ?? null,
    trial_ends_at: access.trialEndsAt?.toISOString() ?? null,
    issued_at: rows[0].now.toISOString(),
    version: Number(rows[0].version),
  }
  await database().query("UPDATE devices SET last_seen_at = now() WHERE id = $1", [device.deviceId])
  return Response.json({ snapshot: signSnapshot(snapshot, key), server_time: snapshot.issued_at }, {
    headers: { "Cache-Control": "no-store" },
  })
}
