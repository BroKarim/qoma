import { describe, it } from "node:test"
import assert from "node:assert/strict"
import { newCheckoutPlan } from "./polar"

describe("new checkout plans", () => {
  it("allows the one-time lifetime product only", () => {
    assert.equal(newCheckoutPlan("lifetime"), "lifetime")
    assert.equal(newCheckoutPlan("monthly"), null)
    assert.equal(newCheckoutPlan("annual"), null)
    assert.equal(newCheckoutPlan(null), null)
  })
})
