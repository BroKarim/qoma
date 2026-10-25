import { randomUUID } from "node:crypto"
import { database } from "@/lib/db"
import { getAuth } from "@/lib/auth"
import { type PaidPlan, planForProduct, polar, productId } from "@/lib/billing/polar"

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
  const { rows: existing } = await database().query<{ plan: string; status: string }>("SELECT plan, status FROM entitlements WHERE account_id = $1", [accountId])
  if (existing[0]?.plan === "lifetime" && existing[0].status === "active") return Response.json({ error: "Already owns lifetime" }, { status: 409 })
  if (existing[0]?.status === "active" && ["monthly", "annual"].includes(existing[0].plan) && plan !== "lifetime") {
    return Response.json({ error: "Use change-plan flow for an active subscription" }, { status: 409 })
  }
  const product = productId(plan)
  if (planForProduct(product) !== plan) throw new Error("Duplicate Polar product configuration")
  const id = randomUUID()
  const base = process.env.BETTER_AUTH_URL!
  await database().query("INSERT INTO checkout_attempts(id, account_id, plan, product_id) VALUES($1,$2,$3,$4)", [id, accountId, plan, product])
  const checkout = await polar().checkouts.create({
    products: [product], external_customer_id: accountId, customer_email: session.user.email,
    currency: "usd", allow_trial: false, allow_discount_codes: false,
    metadata: { qyube_checkout_id: id, qyube_account_id: accountId },
    success_url: `${base}/account?checkout=returned`, return_url: `${base}/pricing`,
  })
  await database().query("UPDATE checkout_attempts SET provider_checkout_id = $2 WHERE id = $1", [id, checkout.id])
  return Response.json({ url: checkout.url })
}
