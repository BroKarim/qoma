import type { PoolClient } from "pg"
import { database } from "@/lib/db"
import { recomputeEntitlement } from "@/lib/access/entitlements"
import { planForProduct, polar } from "./polar"

type Event = { type: string; timestamp: string; data: unknown }
type PolarData = Record<string, unknown>
const object = (value: unknown): PolarData => value && typeof value === "object" && !Array.isArray(value) ? value as PolarData : {}
const string = (value: unknown): string | null => typeof value === "string" && value.length > 0 ? value : null
const number = (value: unknown): number => typeof value === "number" && Number.isFinite(value) ? value : 0
const date = (value: unknown): Date | null => {
  const raw = string(value)
  if (!raw) return null
  const result = new Date(raw)
  return Number.isFinite(result.getTime()) ? result : null
}

async function accountFor(client: PoolClient, data: PolarData): Promise<string> {
  const checkoutId = string(data.checkout_id)
  if (checkoutId) {
    const { rows } = await client.query<{ account_id: string }>(
      "SELECT account_id FROM checkout_attempts WHERE provider_checkout_id = $1", [checkoutId])
    if (rows[0]) return rows[0].account_id
  }
  const customerId = string(data.customer_id)
  if (customerId) {
    const { rows } = await client.query<{ account_id: string }>(
      "SELECT account_id FROM billing_customers WHERE provider = 'polar' AND provider_customer_id = $1", [customerId])
    if (rows[0]) return rows[0].account_id
  }
  throw new Error("Unknown Polar checkout/customer; retry after checkout or paid order is recorded")
}

async function applyPaidOrder(client: PoolClient, data: PolarData) {
  const id = string(data.id), product = string(data.product_id), customer = string(data.customer_id)
  const plan = product && planForProduct(product)
  if (!id || !product || !customer || !plan || data.paid !== true || data.currency !== "usd") throw new Error("Invalid or unconfigured paid order")
  const accountId = await accountFor(client, data)
  const checkoutId = string(data.checkout_id)
  if (checkoutId) {
    const { rows } = await client.query<{ product_id: string; account_id: string }>(
      "SELECT product_id, account_id FROM checkout_attempts WHERE provider_checkout_id = $1", [checkoutId])
    if (rows[0] && (rows[0].product_id !== product || rows[0].account_id !== accountId)) throw new Error("Checkout product/account mismatch")
  }
  await client.query(`INSERT INTO billing_customers(account_id, provider, provider_customer_id) VALUES($1,'polar',$2)
    ON CONFLICT (account_id, provider) DO UPDATE SET provider_customer_id = EXCLUDED.provider_customer_id`, [accountId, customer])
  let subscription = object(data.subscription)
  const subscriptionId = string(data.subscription_id)
  if (subscriptionId && !date(subscription.current_period_end)) {
    subscription = object(await polar().subscriptions.get(subscriptionId))
  }
  const periodStart = date(subscription.current_period_start)
  const periodEnd = date(subscription.current_period_end)
  if (plan !== "lifetime" && (!subscriptionId || !periodEnd)) throw new Error("Paid subscription has no period")
  const paidAt = date(data.created_at) ?? new Date()
  const modifiedAt = date(data.modified_at) ?? paidAt
  await client.query(`INSERT INTO billing_orders(provider, provider_order_id, account_id, plan, subscription_id,
      amount_cents, refunded_cents, total_cents, billing_reason, currency, status,
      paid_at, period_start, period_end, provider_modified_at)
    VALUES('polar',$1,$2,$3,$4,$5,$6,$7,$8,'usd',$9,$10,$11,$12,$13)
    ON CONFLICT (provider, provider_order_id) DO UPDATE SET
      refunded_cents = EXCLUDED.refunded_cents, status = EXCLUDED.status,
      provider_modified_at = EXCLUDED.provider_modified_at
    WHERE billing_orders.provider_modified_at IS NULL OR billing_orders.provider_modified_at <= EXCLUDED.provider_modified_at`,
    [id, accountId, plan, subscriptionId, number(data.net_amount),
      Math.max(0, number(data.refunded_amount) - number(data.refunded_tax_amount)),
      number(data.total_amount), string(data.billing_reason),
      number(data.refunded_amount) > 0 && number(data.refunded_amount) >= number(data.total_amount) ? "refunded" : "paid",
      paidAt, periodStart, periodEnd, modifiedAt])
  if (subscriptionId && periodEnd && plan !== "lifetime") {
    const { rows: states } = await client.query<{ revoked: boolean; cancel_at_period_end: boolean; provider_modified_at: Date }>(
      "SELECT revoked, cancel_at_period_end, provider_modified_at FROM polar_subscription_state WHERE subscription_id = $1 AND account_id = $2", [subscriptionId, accountId])
    const state = states[0]
    await client.query(`INSERT INTO billing_subscriptions(provider, provider_subscription_id, account_id, plan,
        paid_until, cancel_at_period_end, revoked_at, provider_modified_at)
      VALUES('polar',$1,$2,$3,$4,$5,$6,$7)
      ON CONFLICT (provider, provider_subscription_id) DO UPDATE SET
        plan = EXCLUDED.plan, paid_until = GREATEST(billing_subscriptions.paid_until, EXCLUDED.paid_until),
        updated_at = now()
      WHERE billing_subscriptions.account_id = EXCLUDED.account_id`,
      [subscriptionId, accountId, plan, periodEnd, state?.cancel_at_period_end ?? subscription.cancel_at_period_end === true,
        state?.revoked || subscription.status === "unpaid" || subscription.ended_at ? (state?.provider_modified_at ?? modifiedAt) : null,
        state?.provider_modified_at ?? modifiedAt])
  }
  if (checkoutId) await client.query("UPDATE checkout_attempts SET completed_at = now() WHERE provider_checkout_id = $1", [checkoutId])
  if (plan === "lifetime" && (number(data.refunded_amount) === 0 || number(data.refunded_amount) < number(data.total_amount))) {
    const { rows: previous } = await client.query<{ provider_subscription_id: string }>(`
      SELECT s.provider_subscription_id FROM billing_subscriptions s
      WHERE s.account_id = $1 AND s.provider = 'polar' AND s.revoked_at IS NULL AND s.paid_until > now()
      ORDER BY s.paid_until DESC LIMIT 1`, [accountId])
    if (previous[0]) await client.query(`INSERT INTO billing_actions(provider, action, account_id, provider_subscription_id)
      VALUES('polar','cancel_subscription',$1,$2) ON CONFLICT DO NOTHING`, [accountId, previous[0].provider_subscription_id])
  }
  return accountId
}

async function applyRefund(client: PoolClient, data: PolarData) {
  const id = string(data.id)
  if (!id) throw new Error("Refund missing order ID")
  const { rows } = await client.query<{ account_id: string; total_cents: number; subscription_id: string | null }>(
    "SELECT account_id, total_cents, subscription_id FROM billing_orders WHERE provider = 'polar' AND provider_order_id = $1 FOR UPDATE", [id])
  if (!rows[0]) throw new Error("Refund arrived before paid order")
  const amount = number(data.refunded_amount)
  await client.query(`UPDATE billing_orders SET refunded_cents = $2,
      status = CASE WHEN $3 > 0 AND $3 >= total_cents THEN 'refunded' ELSE 'paid' END,
      provider_modified_at = $4 WHERE provider = 'polar' AND provider_order_id = $1 AND
      (provider_modified_at IS NULL OR provider_modified_at <= $4)`,
    [id, Math.max(0, amount - number(data.refunded_tax_amount)), amount, date(data.modified_at) ?? new Date()])
  if (amount > 0 && amount >= rows[0].total_cents && rows[0].subscription_id) {
    const { rows: paid } = await client.query<{ paid_until: Date | null }>(`
      SELECT max(period_end) AS paid_until FROM billing_orders
      WHERE provider = 'polar' AND subscription_id = $1 AND status = 'paid'`, [rows[0].subscription_id])
    await client.query(`UPDATE billing_subscriptions SET paid_until = COALESCE($2, now()),
      revoked_at = CASE WHEN $2 IS NULL THEN now() ELSE NULL END, updated_at = now()
      WHERE provider = 'polar' AND provider_subscription_id = $1`,
    [rows[0].subscription_id, paid[0].paid_until])
  }
  return rows[0].account_id
}

async function applySubscription(client: PoolClient, type: string, data: PolarData) {
  const id = string(data.id), product = string(data.product_id)
  const plan = product && planForProduct(product)
  if (!id || (plan !== "monthly" && plan !== "annual")) return null
  const accountId = await accountFor(client, data)
  const modifiedAt = date(data.modified_at) ?? date(data.created_at) ?? new Date()
  const revoked = type === "subscription.revoked" || data.status === "unpaid" || data.status === "revoked"
  await client.query(`INSERT INTO polar_subscription_state(subscription_id, account_id, product_id, revoked,
      cancel_at_period_end, provider_modified_at) VALUES($1,$2,$3,$4,$5,$6)
    ON CONFLICT (subscription_id) DO UPDATE SET product_id = EXCLUDED.product_id,
      revoked = EXCLUDED.revoked, cancel_at_period_end = EXCLUDED.cancel_at_period_end,
      provider_modified_at = EXCLUDED.provider_modified_at
    WHERE polar_subscription_state.account_id = EXCLUDED.account_id
      AND polar_subscription_state.provider_modified_at <= EXCLUDED.provider_modified_at`,
    [id, accountId, product, revoked, data.cancel_at_period_end === true, modifiedAt])
  const { rows } = await client.query<{ plan: string }>("SELECT plan FROM billing_orders WHERE provider = 'polar' AND subscription_id = $1 AND status = 'paid' ORDER BY paid_at DESC LIMIT 1", [id])
  if (!rows.length) return null // Subscription creation is not proof of payment.
  await client.query(`UPDATE billing_subscriptions SET plan = $2,
      cancel_at_period_end = $3, revoked_at = CASE WHEN $4 THEN now() ELSE NULL END,
      provider_modified_at = $5, updated_at = now()
    WHERE provider = 'polar' AND provider_subscription_id = $1 AND account_id = $6
      AND (provider_modified_at IS NULL OR provider_modified_at <= $5)`,
    [id, rows[0].plan, data.cancel_at_period_end === true, revoked, modifiedAt, accountId])
  return accountId
}

export async function processPolarEvent(id: string, event: Event): Promise<string | null> {
  if (!/^[A-Za-z0-9_-]{1,128}$/.test(id)) throw new Error("Invalid webhook id")
  const client = await database().connect()
  try {
    await client.query("BEGIN")
    const claim = await client.query(`INSERT INTO webhook_events(provider, event_id, payload)
      VALUES('polar',$1,$2) ON CONFLICT DO NOTHING`, [id, JSON.stringify(event)])
    if (!claim.rowCount) {
      const orderId = string(object(event.data).id)
      const { rows } = orderId ? await client.query<{ account_id: string }>(
        "SELECT account_id FROM billing_orders WHERE provider = 'polar' AND provider_order_id = $1", [orderId]) : { rows: [] }
      await client.query("COMMIT")
      return rows[0]?.account_id ?? null
    }
    const data = object(event.data)
    let accountId: string | null = null
    if (event.type === "order.paid") accountId = await applyPaidOrder(client, data)
    else if (event.type === "order.refunded") accountId = await applyRefund(client, data)
    else if (event.type.startsWith("subscription.")) accountId = await applySubscription(client, event.type, data)
    if (accountId) await recomputeEntitlement(accountId, client)
    await client.query("UPDATE webhook_events SET processed_at = now() WHERE provider = 'polar' AND event_id = $1", [id])
    await client.query("COMMIT")
    return accountId
  } catch (error) {
    await client.query("ROLLBACK")
    throw error
  } finally { client.release() }
}
