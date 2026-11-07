"use client"

import { useState } from "react"
import type { PaidPlan } from "@/lib/billing/polar"

export function CheckoutButton({ plan }: { plan: PaidPlan }) {
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState("")
  async function checkout() {
    setBusy(true)
    setError("")
    try {
      const response = await fetch("/api/billing/checkout", {
        method: "POST", headers: { "content-type": "application/json" },
        body: JSON.stringify({ plan }),
      })
      const result = await response.json().catch(() => ({}))
      if (!response.ok || typeof result.url !== "string" || !result.url.startsWith("https://")) {
        const messages: Record<string, string> = {
          ALREADY_LIFETIME: "This account already has Qyube Pro lifetime access.",
          CHANGE_IN_PORTAL: "Manage your current plan in your Polar account before purchasing lifetime access.",
          CHECKOUT_PENDING: "A checkout is already being confirmed. Check your account again shortly.",
          PRORATION_REVIEW_REQUIRED: "We can’t calculate this upgrade automatically. Contact support for help.",
        }
        throw new Error(messages[result.error] ?? "Checkout is unavailable. Please try again shortly.")
      }
      window.location.assign(result.url)
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Checkout unavailable")
      setBusy(false)
    }
  }
  return <div>
    <button disabled={busy} onClick={checkout} className="rounded-full bg-black px-5 py-2 text-white disabled:opacity-50">
      {busy ? "Opening checkout…" : "Get Qyube Pro"}
    </button>
    {error && <p role="alert" className="mt-2 text-sm text-red-700">{error}</p>}
  </div>
}
