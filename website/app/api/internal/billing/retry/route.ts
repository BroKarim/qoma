import { timingSafeEqual } from "node:crypto"
import { database } from "@/lib/db"
import { drainBillingActions } from "@/lib/billing/lifetime"

export const runtime = "nodejs"

export async function POST(request: Request) {
  const configured = process.env.BILLING_JOB_TOKEN
  const supplied = request.headers.get("authorization")?.replace(/^Bearer /, "")
  if (!configured || configured.length < 32 || !supplied ||
      Buffer.byteLength(configured) !== Buffer.byteLength(supplied) ||
      !timingSafeEqual(Buffer.from(configured), Buffer.from(supplied))) {
    return Response.json({ error: "Unauthorized" }, { status: 401 })
  }
  const { rows } = await database().query<{ account_id: string }>(`
    SELECT DISTINCT account_id FROM billing_actions WHERE completed_at IS NULL ORDER BY account_id LIMIT 50`)
  const failed: string[] = []
  for (const row of rows) {
    try { await drainBillingActions(row.account_id) }
    catch { failed.push(row.account_id) }
  }
  return Response.json({ attempted: rows.length, failed: failed.length }, { status: failed.length ? 503 : 200 })
}
