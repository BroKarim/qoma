import { randomUUID } from "node:crypto"
import { database } from "@/lib/db"
import { getAuth } from "@/lib/auth"
import { type PaidPlan, planForProduct, polar, productId } from "@/lib/billing/polar"
import { lifetimeCredit } from "@/lib/billing/lifetime"

export const runtime = "nodejs"

export async function POST(request: Request) {
  if (request.headers.get("origin") !== process.env.BETTER_AUTH_URL) return Response.json({ error: "Invalid origin" }, { status: 403 })
  const session = await getAuth().api.getSession({ headers: request.headers })
  if (!session?.user.emailVerified) return Response.json({ error: "Sign in first" }, { status: 401 })
  let plan: PaidPlan
  try {
    const body = await request.json()
    if (!["monthly", "annual", "lifetime"].includes(body.plan)) throw new Error("INVALID_PLAN")
    plan = body.plan
  } catch { return Response.json({ error: "Invalid plan" }, { status: 400 }) }
  const accountId = session.user.id
  const product = productId(plan)
  if (planForProduct(product) !== plan) throw new Error("Duplicate Polar product configuration")
  const id = randomUUID()
  const base = process.env.BETTER_AUTH_URL!
  const client = await database().connect()
  try {
    await client.query("BEGIN")
    await client.query("SELECT pg_advisory_xact_lock(hashtextextended($1, 0))", [accountId])
    const { rows: existing } = await client.query<{ plan: string; status: string }>("SELECT plan, status FROM entitlements WHERE account_id = $1", [accountId])
    if (existing[0]?.plan === "lifetime" && existing[0].status === "active") throw new Error("ALREADY_LIFETIME")
    if (existing[0]?.status === "active" && ["monthly", "annual"].includes(existing[0].plan) && plan !== "lifetime") throw new Error("CHANGE_IN_PORTAL")
    const { rows: pending } = await client.query("SELECT 1 FROM checkout_attempts WHERE account_id = $1 AND plan = $2 AND completed_at IS NULL AND created_at > now() - interval '15 minutes' LIMIT 1", [accountId, plan])
    if (pending.length) throw new Error("CHECKOUT_PENDING")
    let credit = 0, discountId: string | null = null, priorSubscriptionId: string | null = null
    if (plan === "lifetime") {
      const { rows } = await client.query<{ provider_subscription_id: string; paid_until: Date; amount_cents: number | null }>(`
        SELECT s.provider_subscription_id, s.paid_until, (
          SELECT o.amount_cents FROM billing_orders o WHERE o.provider = 'polar'
            AND o.subscription_id = s.provider_subscription_id AND o.status = 'paid'
          ORDER BY o.paid_at DESC LIMIT 1) AS amount_cents
        FROM billing_subscriptions s WHERE s.account_id = $1 AND s.provider = 'polar'
          AND s.revoked_at IS NULL AND s.paid_until > now()
        ORDER BY s.paid_until DESC LIMIT 1`, [accountId])
      if (rows[0]) {
        priorSubscriptionId = rows[0].provider_subscription_id
        credit = lifetimeCredit(rows[0].amount_cents, rows[0].paid_until, new Date())
      }
      if (credit > 0) {
        const discount = await polar().discounts.create({ name: "Qyube lifetime upgrade credit", type: "fixed", duration: "once",
          amounts: { usd: credit }, max_redemptions: 1, products: [product],
          ends_at: new Date(Date.now() + 15 * 60_000).toISOString(),
          metadata: { qyube_checkout_id: id, qyube_account_id: accountId },
        })
        discountId = discount.id
      }
    }
    await client.query("INSERT INTO checkout_attempts(id, account_id, plan, product_id, credit_cents, discount_id, prior_subscription_id) VALUES($1,$2,$3,$4,$5,$6,$7)",
      [id, accountId, plan, product, credit, discountId, priorSubscriptionId])
    const checkout = await polar().checkouts.create({
      products: [product], external_customer_id: accountId, customer_email: session.user.email,
      currency: "usd", allow_trial: false, allow_discount_codes: false,
      discount_id: discountId,
      metadata: { qyube_checkout_id: id, qyube_account_id: accountId },
      success_url: `${base}/account?checkout=returned`, return_url: `${base}/pricing`,
    })
    await client.query("UPDATE checkout_attempts SET provider_checkout_id = $2 WHERE id = $1", [id, checkout.id])
    await client.query("COMMIT")
    return Response.json({ url: checkout.url, creditCents: credit })
  } catch (error) {
    await client.query("ROLLBACK")
    if (error instanceof Error && ["ALREADY_LIFETIME", "CHANGE_IN_PORTAL", "CHECKOUT_PENDING"].includes(error.message)) {
      return Response.json({ error: error.message }, { status: 409 })
    }
    throw error
  } finally { client.release() }
}
