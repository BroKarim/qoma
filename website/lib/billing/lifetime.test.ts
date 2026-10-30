import { describe, it } from "node:test"
import assert from "node:assert/strict"
import { lifetimeCredit } from "./lifetime"

describe("lifetime upgrade credit", () => {
  const now = new Date("2026-10-25T00:00:00Z")
  it("trial or expired subscription gets no credit", () => {
    assert.equal(lifetimeCredit(null, null, now), 0)
    assert.equal(lifetimeCredit(2900, new Date("2026-10-24T23:59:59Z"), now), 0)
  })
  it("last paid period only, bounded by lifetime price", () => {
    const future = new Date("2026-11-01T00:00:00Z")
    assert.equal(lifetimeCredit(399, future, now), 399)
    assert.equal(lifetimeCredit(2900, future, now), 2900)
    assert.equal(lifetimeCredit(6000, future, now), 4900)
  })
})
