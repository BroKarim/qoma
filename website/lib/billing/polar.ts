import { createPolar } from "@polar-sh/sdk/2026-10"
import { expectedLifetimeAmountCents } from "./order-amount"

export type PaidPlan = "monthly" | "annual" | "lifetime"

export function newCheckoutPlan(value: unknown): "lifetime" | null {
  return value === "lifetime" ? value : null
}

export const prices: Record<PaidPlan, number> = { monthly: 399, annual: 2900, lifetime: expectedLifetimeAmountCents() }

export function formatUSD(cents: number) {
  return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", minimumFractionDigits: 0, maximumFractionDigits: 2 }).format(cents / 100)
}

export function productId(plan: PaidPlan): string {
  const key = { monthly: "POLAR_MONTHLY_PRODUCT_ID", annual: "POLAR_ANNUAL_PRODUCT_ID", lifetime: "POLAR_LIFETIME_PRODUCT_ID" }[plan]
  const value = process.env[key]
  if (!value) throw new Error(`${key} is not configured`)
  return value
}

export function planForProduct(id: string): PaidPlan | null {
  for (const plan of ["monthly", "annual", "lifetime"] as const) {
    if (process.env[{ monthly: "POLAR_MONTHLY_PRODUCT_ID", annual: "POLAR_ANNUAL_PRODUCT_ID", lifetime: "POLAR_LIFETIME_PRODUCT_ID" }[plan]] === id) return plan
  }
  return null
}

export function polar() {
  if (!process.env.POLAR_ACCESS_TOKEN) throw new Error("POLAR_ACCESS_TOKEN is not configured")
  return createPolar({ accessToken: process.env.POLAR_ACCESS_TOKEN, environment: process.env.POLAR_ENVIRONMENT === "production" ? "production" : "sandbox" })
}
