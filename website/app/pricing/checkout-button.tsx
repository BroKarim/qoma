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
      const result = await response.json()
      if (!response.ok || typeof result.url !== "string" || !result.url.startsWith("https://")) throw new Error(result.error ?? "Checkout unavailable")
      window.location.assign(result.url)
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Checkout unavailable")
      setBusy(false)
    }
  }
  return <div>
    <button disabled={busy} onClick={checkout} className="rounded-full bg-black px-5 py-2 text-white disabled:opacity-50">
      {busy ? "Opening checkout…" : "Choose plan"}
    </button>
    {error && <p role="alert" className="mt-2 text-sm text-red-700">{error}</p>}
  </div>
}
