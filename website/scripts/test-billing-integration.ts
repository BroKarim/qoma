import assert from "node:assert/strict"
import { randomUUID } from "node:crypto"
import { database } from "../lib/db"
import { processPolarEvent } from "../lib/billing/webhook"

const url = process.env.DATABASE_URL
if (!url || !["127.0.0.1", "localhost"].includes(new URL(url).hostname) || process.env.QYUBE_ALLOW_LOCAL_INTEGRATION_TEST !== "1") {
  throw new Error("This test only runs against an explicitly approved local PostgreSQL database")
}
process.env.POLAR_MONTHLY_PRODUCT_ID = "monthly-test-product"
process.env.POLAR_ANNUAL_PRODUCT_ID = "annual-test-product"
process.env.POLAR_LIFETIME_PRODUCT_ID = "lifetime-test-product"

const account = randomUUID()
const checkout = randomUUID()
const subscription = randomUUID()
const customer = randomUUID()
const order = randomUUID()
const paidAt = new Date()
const periodEnd = new Date(paidAt.getTime() + 30 * 86_400_000)

try {
  await database().query(`INSERT INTO checkout_attempts(id, account_id, plan, product_id, provider_checkout_id)
    VALUES($1,$2,'monthly',$3,$4)`, [randomUUID(), account, "monthly-test-product", checkout])
  const paid = {
    type: "order.paid", timestamp: paidAt.toISOString(), data: {
      id: order, created_at: paidAt.toISOString(), modified_at: paidAt.toISOString(),
      paid: true, currency: "usd", billing_reason: "subscription_create",
      total_amount: 431, net_amount: 399, refunded_amount: 0, refunded_tax_amount: 0,
      product_id: "monthly-test-product", checkout_id: checkout, customer_id: customer,
      subscription_id: subscription, subscription: {
        current_period_start: paidAt.toISOString(), current_period_end: periodEnd.toISOString(),
      },
    },
  }
  const eventId = randomUUID()
  await processPolarEvent(eventId, paid)
  await processPolarEvent(eventId, paid) // idempotent duplicate
  const first = await database().query<{ plan: string; status: string }>(
    "SELECT plan, status FROM entitlements WHERE account_id = $1", [account])
  assert.deepEqual(first.rows[0], { plan: "monthly", status: "active" })
  const orders = await database().query<{ amount_cents: number; total_cents: number }>(
    "SELECT amount_cents, total_cents FROM billing_orders WHERE provider_order_id = $1", [order])
  assert.equal(orders.rows[0].amount_cents, 399) // excludes tax for lifetime credit
  assert.equal(orders.rows[0].total_cents, 431)

  const refunded = { ...paid, type: "order.refunded", data: {
    ...paid.data, modified_at: new Date(paidAt.getTime() + 1000).toISOString(),
    refunded_amount: 431, refunded_tax_amount: 32,
  } }
  await processPolarEvent(randomUUID(), refunded)
  const after = await database().query<{ status: string }>(
    "SELECT status FROM billing_orders WHERE provider_order_id = $1", [order])
  assert.equal(after.rows[0].status, "refunded")
  const access = await database().query<{ status: string }>(
    "SELECT status FROM entitlements WHERE account_id = $1", [account])
  assert.equal(access.rows[0].status, "expired")
  process.stdout.write("Local billing integration checks passed\n")
} finally {
  await database().end()
}
