import { webhooks } from "@polar-sh/sdk/2026-10"
import { processPolarEvent } from "@/lib/billing/webhook"

export const runtime = "nodejs"

export async function POST(request: Request) {
  const secret = process.env.POLAR_WEBHOOK_SECRET
  if (!secret) return Response.json({ error: "Webhook not configured" }, { status: 503 })
  const id = request.headers.get("webhook-id")
  if (!id) return Response.json({ error: "Missing webhook id" }, { status: 400 })
  let event: Awaited<ReturnType<typeof webhooks.validateEvent>>
  try {
    event = await webhooks.validateEvent(new Uint8Array(await request.arrayBuffer()), {
      "webhook-id": id,
      "webhook-timestamp": request.headers.get("webhook-timestamp") ?? "",
      "webhook-signature": request.headers.get("webhook-signature") ?? "",
    }, secret)
  } catch (error) {
    if (error instanceof webhooks.PolarWebhookVerificationError) return Response.json({ error: "Invalid signature" }, { status: 403 })
    if (error instanceof webhooks.PolarWebhookError) return Response.json({ error: "Invalid event" }, { status: 400 })
    throw error
  }
  await processPolarEvent(id, event)
  return Response.json({ received: true })
}
