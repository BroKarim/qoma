import { database } from "@/lib/db"
import { polar } from "./polar"

export function lifetimeCredit(lastPaidCents: number | null, activeUntil: Date | null, now: Date): number {
  if (!lastPaidCents || !activeUntil || activeUntil <= now) return 0
  return Math.max(0, Math.min(4900, lastPaidCents))
}

export async function drainBillingActions(accountId: string) {
  const { rows } = await database().query<{ id: number; provider_subscription_id: string }>(`
    SELECT id, provider_subscription_id FROM billing_actions
    WHERE account_id = $1 AND provider = 'polar' AND action = 'cancel_subscription' AND completed_at IS NULL
    ORDER BY id LIMIT 10`, [accountId])
  for (const row of rows) {
    try {
      await polar().subscriptions.update(row.provider_subscription_id, { cancel_at_period_end: true })
      await database().query("UPDATE billing_actions SET completed_at = now(), last_error = NULL WHERE id = $1", [row.id])
    } catch (error) {
      await database().query("UPDATE billing_actions SET last_error = $2 WHERE id = $1", [row.id, error instanceof Error ? error.message.slice(0, 500) : "Unknown Polar error"])
      throw error
    }
  }
}
