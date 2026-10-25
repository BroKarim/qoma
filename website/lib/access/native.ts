import { randomUUID } from "node:crypto"
import type { PoolClient } from "pg"
import { database } from "@/lib/db"
import { digest, pkceMatches, token } from "./crypto"
import { activateInstallation } from "./trial"
import { recomputeEntitlement } from "./entitlements"

const origin = () => process.env.BETTER_AUTH_URL ?? "https://qyube.brokarim.com"

export async function startNativeLogin(input: { installationId: string; deviceName: string; challenge: string; state: string }) {
  if (!input || typeof input.installationId !== "string" || typeof input.deviceName !== "string" ||
      typeof input.challenge !== "string" || typeof input.state !== "string" ||
      !/^[a-f0-9-]{36}$/i.test(input.installationId) ||
      !/^[A-Za-z0-9_-]{43}$/.test(input.challenge) ||
      !/^[A-Za-z0-9_-]{22,128}$/.test(input.state) ||
      !input.deviceName.trim() || input.deviceName.length > 80) throw new Error("INVALID_REQUEST")
  const id = randomUUID()
  await database().query(`
    INSERT INTO native_login_attempts(id, installation_hash, device_name, challenge, state, expires_at)
    VALUES($1, $2, $3, $4, $5, now() + interval '10 minutes')`,
    [id, digest(input.installationId), input.deviceName, input.challenge, input.state],
  )
  return { requestId: id, url: `${origin()}/auth?request=${id}` }
}

export async function completeNativeLogin(requestId: string, accountId: string) {
  if (typeof requestId !== "string" || !/^[a-f0-9-]{36}$/i.test(requestId)) throw new Error("INVALID_REQUEST")
  const client = await database().connect()
  try {
    await client.query("BEGIN")
    const { rows } = await client.query<{
      installation_hash: string; device_name: string; challenge: string; state: string
    }>(`SELECT installation_hash, device_name, challenge, state FROM native_login_attempts
      WHERE id = $1 AND expires_at > now() AND completed_at IS NULL FOR UPDATE`, [requestId])
    if (!rows[0]) throw new Error("LOGIN_EXPIRED")
    const code = token()
    await client.query(`
      INSERT INTO native_handoffs(code_hash, attempt_id, account_id, installation_hash,
        challenge, state, device_name, expires_at)
      VALUES($1,$2,$3,$4,$5,$6,$7,now() + interval '2 minutes')`,
      [digest(code), requestId, accountId, rows[0].installation_hash,
        rows[0].challenge, rows[0].state, rows[0].device_name],
    )
    await client.query("UPDATE native_login_attempts SET completed_at = now() WHERE id = $1", [requestId])
    await client.query("COMMIT")
    const callback = new URL("qyube://auth/callback")
    callback.searchParams.set("code", code)
    callback.searchParams.set("state", rows[0].state)
    return callback.toString()
  } catch (error) {
    await client.query("ROLLBACK")
    throw error
  } finally { client.release() }
}

export async function exchangeNativeCode(code: string, verifier: string, installationId: string) {
  if (typeof code !== "string" || typeof verifier !== "string" || typeof installationId !== "string" ||
      !/^[A-Za-z0-9_-]{43}$/.test(code) || !/^[a-f0-9-]{36}$/i.test(installationId)) throw new Error("INVALID_REQUEST")
  const client = await database().connect()
  try {
    await client.query("BEGIN")
    const { rows } = await client.query<{
      account_id: string; installation_hash: string; challenge: string; device_name: string
    }>(`SELECT account_id, installation_hash, challenge, device_name FROM native_handoffs
      WHERE code_hash = $1 AND expires_at > now() AND consumed_at IS NULL FOR UPDATE`, [digest(code)])
    const handoff = rows[0]
    if (!handoff || handoff.installation_hash !== digest(installationId) ||
        !pkceMatches(verifier, handoff.challenge)) throw new Error("INVALID_CODE")
    const { deviceId } = await activateInstallation(client, handoff.account_id, handoff.installation_hash, handoff.device_name)
    await recomputeEntitlement(handoff.account_id, client)
    const credential = token()
    await client.query(`
      INSERT INTO device_credentials(token_hash, device_id, account_id, expires_at)
      VALUES($1,$2,$3,now() + interval '90 days')`,
      [digest(credential), deviceId, handoff.account_id],
    )
    await client.query("UPDATE native_handoffs SET consumed_at = now(), device_id = $2 WHERE code_hash = $1", [digest(code), deviceId])
    await client.query("COMMIT")
    return { credential, accountId: handoff.account_id, deviceId }
  } catch (error) {
    await client.query("ROLLBACK")
    throw error
  } finally { client.release() }
}

export async function authenticatedDevice(request: Request): Promise<{ accountId: string; deviceId: string } | null> {
  const value = request.headers.get("authorization")
  if (!value?.startsWith("Bearer ")) return null
  const credential = value.slice(7)
  if (!/^[A-Za-z0-9_-]{43}$/.test(credential)) return null
  const { rows } = await database().query<{ account_id: string; device_id: string }>(`
    SELECT c.account_id, c.device_id FROM device_credentials c
    JOIN devices d ON d.id = c.device_id AND d.account_id = c.account_id
    WHERE c.token_hash = $1 AND c.expires_at > now() AND c.revoked_at IS NULL
      AND d.revoked_at IS NULL`, [digest(credential)])
  return rows[0] ? { accountId: rows[0].account_id, deviceId: rows[0].device_id } : null
}

export async function rotateDeviceCredential(credential: string) {
  if (typeof credential !== "string" || !/^[A-Za-z0-9_-]{43}$/.test(credential)) throw new Error("INVALID_CREDENTIAL")
  const client = await database().connect()
  try {
    await client.query("BEGIN")
    const { rows } = await client.query<{ account_id: string; device_id: string }>(`
      SELECT c.account_id, c.device_id FROM device_credentials c
      JOIN devices d ON d.id = c.device_id AND d.revoked_at IS NULL
      WHERE c.token_hash = $1 AND c.expires_at > now() AND c.revoked_at IS NULL FOR UPDATE OF c`, [digest(credential)])
    if (!rows[0]) throw new Error("INVALID_CREDENTIAL")
    const next = token()
    await client.query("UPDATE device_credentials SET revoked_at = now() WHERE token_hash = $1", [digest(credential)])
    await client.query("INSERT INTO device_credentials(token_hash, device_id, account_id, expires_at) VALUES($1,$2,$3,now() + interval '90 days')",
      [digest(next), rows[0].device_id, rows[0].account_id])
    await client.query("COMMIT")
    return { credential: next, accountId: rows[0].account_id, deviceId: rows[0].device_id }
  } catch (error) {
    await client.query("ROLLBACK")
    throw error
  } finally { client.release() }
}

export async function revokeDevice(client: PoolClient, accountId: string, deviceId: string) {
  const result = await client.query("UPDATE devices SET revoked_at = now() WHERE id = $1 AND account_id = $2 AND revoked_at IS NULL", [deviceId, accountId])
  if (result.rowCount) {
    await client.query("UPDATE device_credentials SET revoked_at = now() WHERE device_id = $1 AND revoked_at IS NULL", [deviceId])
  }
  return Boolean(result.rowCount)
}
