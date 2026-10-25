import type { PoolClient } from "pg"
import { database } from "@/lib/db"

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
    const { rows: trials } = await owned.query<{ ends_at: Date }>("SELECT ends_at FROM trial_claims WHERE account_id = $1", [accountId])
    const { rows: lifetimes } = await owned.query("SELECT 1 FROM billing_orders WHERE account_id = $1 AND plan = 'lifetime' AND status = 'paid' AND refunded_cents < amount_cents LIMIT 1", [accountId])
    const { rows: subscriptions } = await owned.query<{ plan: "monthly" | "annual"; paid_until: Date }>(
      "SELECT plan, paid_until FROM billing_subscriptions WHERE account_id = $1 AND paid_until > now() AND revoked_at IS NULL ORDER BY paid_until DESC LIMIT 1",
      [accountId],
    )
    const { rows: clock } = await owned.query<{ now: Date }>("SELECT now() AS now")
    const access = resolveAccess({
      trialEndsAt: trials[0]?.ends_at ?? null,
      lifetimePaid: lifetimes.length > 0,
      subscription: subscriptions[0] ? { plan: subscriptions[0].plan, paidUntil: subscriptions[0].paid_until } : null,
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
