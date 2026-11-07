import { database } from "../lib/db"
import { drainBillingActions } from "../lib/billing/lifetime"
import { processPolarEvent } from "../lib/billing/webhook"

type StoredEvent = { event_id: string; payload: { type: string; timestamp: string; data: unknown } }
const db = database()
try {
  const { rows } = await db.query<StoredEvent>(`SELECT event_id, payload FROM webhook_events
    WHERE provider = 'polar' AND status IN ('failed', 'received') ORDER BY received_at LIMIT 100`)
  let failed = 0
  for (const event of rows) {
    try {
      const accountId = await processPolarEvent(event.event_id, event.payload)
      if (accountId) await drainBillingActions(accountId)
      console.info(`Polar event ${event.event_id} (${event.payload.type}) processed`)
    } catch (error) {
      failed++
      console.error(`Polar event ${event.event_id} (${event.payload.type}) failed:`, error)
    }
  }
  console.info(`Retry complete: ${rows.length - failed} processed, ${failed} failed`)
  if (failed) process.exitCode = 1
} finally {
  await db.end()
}
