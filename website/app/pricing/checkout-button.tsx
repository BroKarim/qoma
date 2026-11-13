"use client"

import { useEffect, useRef, useState } from "react"
import Link from "next/link"

export function CheckoutButton() {
  const started = useRef(false)
  const [error, setError] = useState("")
  async function checkout() {
    setError("")
    try {
      const response = await fetch("/api/billing/checkout", {
        method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ plan: "lifetime" }),
      })
      const result = await response.json().catch(() => ({}))
      if (!response.ok || typeof result.url !== "string" || !result.url.startsWith("https://")) {
        const messages: Record<string, string> = {
          ALREADY_LIFETIME: "You already have Qyube Pro. Open your account to see your access.",
          CHANGE_IN_PORTAL: "Manage your current plan in your account before purchasing.",
          CHECKOUT_PENDING: "Your checkout is being confirmed. Check your account shortly.",
          PRORATION_REVIEW_REQUIRED: "We can’t calculate this upgrade automatically. Please contact support.",
        }
        throw new Error(messages[result.error] ?? "Checkout is unavailable. Please try again.")
      }
      window.location.replace(result.url)
    } catch (cause) { setError(cause instanceof Error ? cause.message : "Checkout unavailable") }
  }
  useEffect(() => { if (!started.current) { started.current = true; void checkout() } }, [])
  return <main className="checkout-loading"><div className="checkout-loading__content">
    <div className="checkout-loading__spark" aria-hidden="true">✦</div>
    <h1>{error ? "Checkout unavailable" : "Preparing your checkout"}</h1>
    <p role={error ? "alert" : "status"}>{error || "Taking you securely to Polar…"}</p>
    {error && <button type="button" onClick={() => void checkout()}>Try again</button>}
    <Link href="/account">Back to account</Link>
  </div></main>
}
