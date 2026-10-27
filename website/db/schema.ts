import { sql } from "drizzle-orm"
import { bigint, bigserial, boolean, check, foreignKey, index, integer, jsonb, pgTable, primaryKey, text, timestamp, unique, uuid } from "drizzle-orm/pg-core"

const time = (name: string) => timestamp(name, { withTimezone: true })
const paidPlans = ["monthly", "annual", "lifetime"] as const

// Better Auth owns its tables and migrations; these are Qyube's domain tables.
export const trialClaims = pgTable("trial_claims", {
  accountId: text("account_id").primaryKey(),
  installationHash: text("installation_hash").notNull().unique("trial_claims_installation_hash_key"),
  startedAt: time("started_at").notNull().defaultNow(),
  endsAt: time("ends_at").notNull(),
}).enableRLS()

export const trialDevices = pgTable("trial_devices", {
  installationHash: text("installation_hash").primaryKey(),
  firstAccountId: text("first_account_id").notNull(),
  claimedAt: time("claimed_at").notNull().defaultNow(),
}).enableRLS()

export const devices = pgTable("devices", {
  id: uuid("id").primaryKey(),
  accountId: text("account_id").notNull(),
  installationHash: text("installation_hash").notNull(),
  name: text("name").notNull(),
  activatedAt: time("activated_at").notNull().defaultNow(),
  lastSeenAt: time("last_seen_at").notNull().defaultNow(),
  revokedAt: time("revoked_at"),
}, table => [
  unique("devices_account_id_installation_hash_key").on(table.accountId, table.installationHash),
  index("devices_active_by_account").on(table.accountId).where(sql`${table.revokedAt} IS NULL`),
]).enableRLS()

export const nativeLoginAttempts = pgTable("native_login_attempts", {
  id: uuid("id").primaryKey(),
  installationHash: text("installation_hash").notNull(),
  deviceName: text("device_name").notNull(),
  challenge: text("challenge").notNull(),
  state: text("state").notNull(),
  createdAt: time("created_at").notNull().defaultNow(),
  expiresAt: time("expires_at").notNull(),
  completedAt: time("completed_at"),
}, table => [index("native_attempt_expiry").on(table.expiresAt)]).enableRLS()

export const nativeHandoffs = pgTable("native_handoffs", {
  codeHash: text("code_hash").primaryKey(),
  accountId: text("account_id").notNull(),
  installationHash: text("installation_hash").notNull(),
  challenge: text("challenge").notNull(),
  state: text("state").notNull(),
  deviceName: text("device_name").notNull(),
  expiresAt: time("expires_at").notNull(),
  consumedAt: time("consumed_at"),
  attemptId: uuid("attempt_id").unique("native_handoffs_attempt_id_key"),
  deviceId: uuid("device_id"),
}, table => [
  index("native_handoff_expiry").on(table.expiresAt),
  foreignKey({ name: "native_handoffs_attempt_id_fkey", columns: [table.attemptId], foreignColumns: [nativeLoginAttempts.id] }),
]).enableRLS()

export const deviceCredentials = pgTable("device_credentials", {
  tokenHash: text("token_hash").primaryKey(),
  deviceId: uuid("device_id").notNull(),
  accountId: text("account_id").notNull(),
  expiresAt: time("expires_at").notNull(),
  revokedAt: time("revoked_at"),
  graceUntil: time("grace_until"),
}, table => [
  index("credentials_by_device").on(table.deviceId),
  foreignKey({ name: "device_credentials_device_id_fkey", columns: [table.deviceId], foreignColumns: [devices.id] }),
]).enableRLS()

export const billingCustomers = pgTable("billing_customers", {
  accountId: text("account_id").notNull(),
  provider: text("provider").notNull(),
  providerCustomerId: text("provider_customer_id").notNull(),
}, table => [
  primaryKey({ name: "billing_customers_pkey", columns: [table.accountId, table.provider] }),
  unique("billing_customers_provider_provider_customer_id_key").on(table.provider, table.providerCustomerId),
]).enableRLS()

export const billingSubscriptions = pgTable("billing_subscriptions", {
  provider: text("provider").notNull(),
  providerSubscriptionId: text("provider_subscription_id").notNull(),
  accountId: text("account_id").notNull(),
  plan: text("plan", { enum: ["monthly", "annual"] }).notNull(),
  paidUntil: time("paid_until").notNull(),
  cancelAtPeriodEnd: boolean("cancel_at_period_end").notNull().default(false),
  revokedAt: time("revoked_at"),
  updatedAt: time("updated_at").notNull().defaultNow(),
  providerModifiedAt: time("provider_modified_at"),
}, table => [
  primaryKey({ name: "billing_subscriptions_pkey", columns: [table.provider, table.providerSubscriptionId] }),
  check("billing_subscriptions_plan_check", sql`${table.plan} IN ('monthly', 'annual')`),
  index("subscriptions_by_account").on(table.accountId),
]).enableRLS()

export const billingOrders = pgTable("billing_orders", {
  provider: text("provider").notNull(),
  providerOrderId: text("provider_order_id").notNull(),
  accountId: text("account_id").notNull(),
  plan: text("plan", { enum: paidPlans }).notNull(),
  subscriptionId: text("subscription_id"),
  amountCents: integer("amount_cents").notNull(),
  refundedCents: integer("refunded_cents").notNull().default(0),
  currency: text("currency").notNull(),
  status: text("status", { enum: ["paid", "refunded"] }).notNull(),
  paidAt: time("paid_at").notNull(),
  periodStart: time("period_start"),
  periodEnd: time("period_end"),
  providerModifiedAt: time("provider_modified_at"),
  totalCents: integer("total_cents"),
  billingReason: text("billing_reason"),
}, table => [
  primaryKey({ name: "billing_orders_pkey", columns: [table.provider, table.providerOrderId] }),
  check("billing_orders_plan_check", sql`${table.plan} IN ('monthly', 'annual', 'lifetime')`),
  check("billing_orders_amount_cents_check", sql`${table.amountCents} >= 0`),
  check("billing_orders_refunded_cents_check", sql`${table.refundedCents} >= 0`),
  check("billing_orders_currency_check", sql`${table.currency} = 'usd'`),
  check("billing_orders_status_check", sql`${table.status} IN ('paid', 'refunded')`),
  index("orders_by_account").on(table.accountId, table.paidAt.desc().nullsFirst()),
]).enableRLS()

export const webhookEvents = pgTable("webhook_events", {
  provider: text("provider").notNull(),
  eventId: text("event_id").notNull(),
  payload: jsonb("payload").notNull(),
  receivedAt: time("received_at").notNull().defaultNow(),
  processedAt: time("processed_at"),
  error: text("error"),
}, table => [primaryKey({ name: "webhook_events_pkey", columns: [table.provider, table.eventId] })]).enableRLS()

export const entitlements = pgTable("entitlements", {
  accountId: text("account_id").primaryKey(),
  plan: text("plan", { enum: ["trial", ...paidPlans] }),
  status: text("status", { enum: ["active", "expired", "revoked"] }).notNull(),
  accessUntil: time("access_until"),
  trialEndsAt: time("trial_ends_at"),
  version: bigint("version", { mode: "bigint" }).notNull().default(sql`1`),
  updatedAt: time("updated_at").notNull().defaultNow(),
}, table => [
  check("entitlements_plan_check", sql`${table.plan} IN ('trial', 'monthly', 'annual', 'lifetime')`),
  check("entitlements_status_check", sql`${table.status} IN ('active', 'expired', 'revoked')`),
]).enableRLS()

export const checkoutAttempts = pgTable("checkout_attempts", {
  id: uuid("id").primaryKey(),
  accountId: text("account_id").notNull(),
  plan: text("plan", { enum: paidPlans }).notNull(),
  productId: text("product_id").notNull(),
  providerCheckoutId: text("provider_checkout_id").unique("checkout_attempts_provider_checkout_id_key"),
  createdAt: time("created_at").notNull().defaultNow(),
  completedAt: time("completed_at"),
  creditCents: integer("credit_cents").notNull().default(0),
  discountId: text("discount_id"),
  priorSubscriptionId: text("prior_subscription_id"),
}, table => [check("checkout_attempts_plan_check", sql`${table.plan} IN ('monthly', 'annual', 'lifetime')`)]).enableRLS()

export const polarSubscriptionState = pgTable("polar_subscription_state", {
  subscriptionId: text("subscription_id").primaryKey(),
  accountId: text("account_id").notNull(),
  productId: text("product_id").notNull(),
  revoked: boolean("revoked").notNull(),
  cancelAtPeriodEnd: boolean("cancel_at_period_end").notNull(),
  providerModifiedAt: time("provider_modified_at").notNull(),
}).enableRLS()

export const billingActions = pgTable("billing_actions", {
  id: bigserial("id", { mode: "number" }).primaryKey(),
  provider: text("provider").notNull(),
  action: text("action").notNull(),
  accountId: text("account_id").notNull(),
  providerSubscriptionId: text("provider_subscription_id").notNull(),
  completedAt: time("completed_at"),
  lastError: text("last_error"),
}, table => [unique("billing_actions_provider_action_provider_subscription_id_key").on(table.provider, table.action, table.providerSubscriptionId)]).enableRLS()
