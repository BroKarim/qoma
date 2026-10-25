import type { PoolClient } from "pg"
import { randomUUID } from "node:crypto"

export type Activation = { deviceId: string; trialEndsAt: Date | null }

export async function activateInstallation(
  client: PoolClient, accountId: string, installationHash: string, deviceName: string,
): Promise<Activation> {
  // Serialize activation for this account and this installation across concurrent logins.
  await client.query("SELECT pg_advisory_xact_lock(hashtextextended($1, 1))", [accountId])
  await client.query("SELECT pg_advisory_xact_lock(hashtextextended($1, 2))", [installationHash])
  const existing = await client.query<{ id: string; revoked_at: Date | null }>(
    "SELECT id, revoked_at FROM devices WHERE account_id = $1 AND installation_hash = $2",
    [accountId, installationHash],
  )
  let deviceId = existing.rows[0]?.id
  if (!deviceId || existing.rows[0].revoked_at) {
    const count = await client.query<{ count: string }>(
      "SELECT count(*)::text AS count FROM devices WHERE account_id = $1 AND revoked_at IS NULL", [accountId],
    )
    if (Number(count.rows[0].count) >= 2) throw new Error("DEVICE_LIMIT")
    if (deviceId) {
      await client.query("UPDATE devices SET name = $2, activated_at = now(), revoked_at = NULL WHERE id = $1", [deviceId, deviceName.slice(0, 80)])
    } else {
      deviceId = randomUUID()
      await client.query("INSERT INTO devices(id, account_id, installation_hash, name) VALUES($1, $2, $3, $4)",
        [deviceId, accountId, installationHash, deviceName.slice(0, 80)])
    }
  }

  const { rows: oldTrial } = await client.query<{ ends_at: Date }>(
    "SELECT ends_at FROM trial_claims WHERE account_id = $1", [accountId],
  )
  const { rows: oldDevice } = await client.query<{ first_account_id: string }>(
    "SELECT first_account_id FROM trial_devices WHERE installation_hash = $1", [installationHash],
  )
  if (!oldTrial[0] && !oldDevice[0]) {
    await client.query(`
      INSERT INTO trial_claims(account_id, installation_hash, ends_at)
      VALUES($1, $2, now() + interval '7 days')`, [accountId, installationHash],
    )
  }
  const { rows: trial } = await client.query<{ ends_at: Date; active: boolean }>(
    "SELECT ends_at, ends_at > now() AS active FROM trial_claims WHERE account_id = $1", [accountId],
  )
  if (trial[0]?.active) {
    await client.query(`
      INSERT INTO trial_devices(installation_hash, first_account_id)
      VALUES($1, $2) ON CONFLICT (installation_hash) DO NOTHING`, [installationHash, accountId],
    )
  }
  return { deviceId, trialEndsAt: trial[0]?.ends_at ?? null }
}
