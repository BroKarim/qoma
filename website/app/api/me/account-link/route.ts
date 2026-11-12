import { authenticatedDevice } from "@/lib/access/native"
import { digest, token } from "@/lib/access/crypto"
import { database } from "@/lib/db"

export async function POST(request: Request) {
  const device = await authenticatedDevice(request)
  if (!device) return Response.json({ error: "Sign in again" }, { status: 401 })
  const value = token()
  const { rowCount } = await database().query(`INSERT INTO account_links(token_hash, account_id, device_id, expires_at)
    SELECT $1,$2,$3,now() + interval '10 minutes'
    WHERE (SELECT count(*) FROM account_links WHERE device_id=$3 AND created_at > now() - interval '10 minutes') < 10`,
    [digest(value), device.accountId, device.deviceId])
  if (!rowCount) return Response.json({ error: "Try again later" }, { status: 429 })
  return Response.json({ url: `${process.env.BETTER_AUTH_URL ?? "https://qyube.brokarim.com"}/account/open?code=${value}` }, { headers: { "Cache-Control": "no-store" } })
}
