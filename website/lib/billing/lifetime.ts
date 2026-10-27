import { and, eq, isNull, sql } from "drizzle-orm"
import { orm } from "@/lib/db"
import { billingActions } from "@/db/schema"
import { polar } from "./polar"

export function lifetimeCredit(lastPaidCents: number | null, activeUntil: Date | null, now: Date): number {
  if (!lastPaidCents || !activeUntil || activeUntil <= now) return 0
  return Math.max(0, Math.min(4900, lastPaidCents))
}

export async function drainBillingActions(accountId: string) {
  const db = orm()
  const rows = await db.select().from(billingActions).where(and(
    eq(billingActions.accountId, accountId), eq(billingActions.provider, "polar"),
    eq(billingActions.action, "cancel_subscription"), isNull(billingActions.completedAt),
  )).orderBy(billingActions.id).limit(10)
  for (const row of rows) {
    try {
      await polar().subscriptions.update(row.providerSubscriptionId, { cancel_at_period_end: true })
      await db.update(billingActions).set({ completedAt: sql`now()`, lastError: null }).where(eq(billingActions.id, row.id))
    } catch (error) {
      await db.update(billingActions).set({ lastError: error instanceof Error ? error.message.slice(0, 500) : "Unknown Polar error" }).where(eq(billingActions.id, row.id))
      throw error
    }
  }
}
