import type { PoolClient } from "pg"
import { and, desc, eq, gt, isNull, sql } from "drizzle-orm"
import { database, orm } from "@/lib/db"
import { billingOrders, billingSubscriptions, trialClaims } from "@/db/schema"

export type Plan = "trial" | "monthly" | "annual" | "lifetime"
export type Access = {
  plan: Plan | null
  status: "active" | "expired" | "revoked"
  accessUntil: Date | null
  offlineUntil: Date | null
  trialEndsAt: Date | null
}

type Sources = {
  trialEndsAt: Date | null
  lifetimePaid: boolean
  subscription: { plan: "monthly" | "annual"; paidUntil: Date } | null
}

const days = (count: number) => count * 24 * 60 * 60 * 1000

export function resolveAccess(sources: Sources, now: Date): Access {
  if (sources.lifetimePaid) {
    return {
      plan: "lifetime", status: "active", accessUntil: null,
      offlineUntil: new Date(now.getTime() + days(30)), trialEndsAt: sources.trialEndsAt,
    }
  }
  if (sources.subscription && sources.subscription.paidUntil > now) {
    const { plan, paidUntil } = sources.subscription
    return {
      plan, status: "active", accessUntil: paidUntil,
      offlineUntil: new Date(paidUntil.getTime() + days(3)), trialEndsAt: sources.trialEndsAt,
    }
  }
  if (sources.trialEndsAt && sources.trialEndsAt > now) {
    return {
      plan: "trial", status: "active", accessUntil: sources.trialEndsAt,
      offlineUntil: sources.trialEndsAt, trialEndsAt: sources.trialEndsAt,
    }
  }
  return {
    plan: null, status: "expired", accessUntil: null,
    offlineUntil: null, trialEndsAt: sources.trialEndsAt,
  }
}

export async function recomputeEntitlement(accountId: string, client?: PoolClient): Promise<Access> {
  const owned = client ?? await database().connect()
  try {
    if (!client) await owned.query("BEGIN")
    await owned.query("SELECT pg_advisory_xact_lock(hashtextextended($1, 0))", [accountId])
    const db = orm(owned)
    const trials = await db.select({ endsAt: trialClaims.endsAt }).from(trialClaims).where(eq(trialClaims.accountId, accountId))
    const lifetimes = await db.select({ id: billingOrders.providerOrderId }).from(billingOrders).where(and(
      eq(billingOrders.accountId, accountId), eq(billingOrders.plan, "lifetime"), eq(billingOrders.status, "paid"),
    )).limit(1)
    const subscriptions = await db.select({ plan: billingSubscriptions.plan, paidUntil: billingSubscriptions.paidUntil })
      .from(billingSubscriptions).where(and(eq(billingSubscriptions.accountId, accountId),
        gt(billingSubscriptions.paidUntil, sql`now()`), isNull(billingSubscriptions.revokedAt)))
      .orderBy(desc(billingSubscriptions.paidUntil)).limit(1)
    const { rows: clock } = await owned.query<{ now: Date }>("SELECT now() AS now")
    const access = resolveAccess({
      trialEndsAt: trials[0]?.endsAt ?? null,
      lifetimePaid: lifetimes.length > 0,
      subscription: subscriptions[0] ?? null,
    }, clock[0].now)
    await owned.query(`
      INSERT INTO entitlements (account_id, plan, status, access_until, trial_ends_at, version)
      VALUES ($1, $2, $3, $4, $5, 1)
      ON CONFLICT (account_id) DO UPDATE SET
        plan = EXCLUDED.plan, status = EXCLUDED.status,
        access_until = EXCLUDED.access_until, trial_ends_at = EXCLUDED.trial_ends_at,
        version = CASE WHEN (entitlements.plan, entitlements.status, entitlements.access_until, entitlements.trial_ends_at)
          IS DISTINCT FROM (EXCLUDED.plan, EXCLUDED.status, EXCLUDED.access_until, EXCLUDED.trial_ends_at)
          THEN entitlements.version + 1 ELSE entitlements.version END,
        updated_at = now()`,
      [accountId, access.plan, access.status, access.accessUntil, access.trialEndsAt],
    )
    if (!client) await owned.query("COMMIT")
    return access
  } catch (error) {
    if (!client) await owned.query("ROLLBACK")
    throw error
  } finally {
    if (!client) owned.release()
  }
}
