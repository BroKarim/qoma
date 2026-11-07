import { describe, test } from "node:test"
import assert from "node:assert/strict"
import { accountAccessState, showCheckoutPending } from "./status"

describe("account access status", () => {
  const now = new Date("2026-11-03T00:00:00Z")

  test("treats an ended trial as expired even if stored status is stale", () => {
    assert.deepEqual(accountAccessState({ plan: "trial", status: "active", accessUntil: new Date("2026-11-02T00:00:00Z"), trialEndsAt: new Date("2026-11-02T00:00:00Z") }, now),
      { lifetime: false, trial: false, active: false, expired: true })
  })

  test("only marks payment pending before a final webhook result", () => {
    assert.equal(showCheckoutPending(true, false), true)
    assert.equal(showCheckoutPending(true, true), false)
    assert.equal(showCheckoutPending(false, false), false)
  })
})
