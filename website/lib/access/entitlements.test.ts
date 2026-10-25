import { describe, it } from "node:test"
import assert from "node:assert/strict"
import { resolveAccess } from "./entitlements"

const now = new Date("2026-10-25T00:00:00Z")

describe("effective access", () => {
  it("trial expires exactly at its deadline", () => {
    const result = resolveAccess({ trialEndsAt: now, lifetimePaid: false, subscription: null }, now)
    assert.equal(result.status, "expired")
  })

  it("paid subscription outranks trial and stays offline until paid end plus three days", () => {
    const paidUntil = new Date("2026-11-01T00:00:00Z")
    const result = resolveAccess({ trialEndsAt: new Date("2026-10-28T00:00:00Z"), lifetimePaid: false, subscription: { plan: "monthly", paidUntil } }, now)
    assert.equal(result.plan, "monthly")
    assert.equal(result.offlineUntil?.toISOString(), "2026-11-04T00:00:00.000Z")
  })

  it("lifetime outranks a still active subscription", () => {
    const result = resolveAccess({ trialEndsAt: null, lifetimePaid: true, subscription: { plan: "annual", paidUntil: new Date("2027-01-01T00:00:00Z") } }, now)
    assert.equal(result.plan, "lifetime")
    assert.equal(result.offlineUntil?.toISOString(), "2026-11-24T00:00:00.000Z")
  })
})
