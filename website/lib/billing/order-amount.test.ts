import { describe, test } from "node:test"
import assert from "node:assert/strict"
import { validateLifetimeOrderAmount } from "./order-amount"

describe("lifetime order amount validation", () => {
  const base = { expectedCents: 1100, currency: "usd", checkoutCreditCents: 0, hasConfiguredDiscount: false, minimumDiscountedCents: 500 }

  test("accepts the configured amount and rejects a $4.90 order", () => {
    assert.equal(validateLifetimeOrderAmount({ ...base, amountCents: 1100 }), true)
    assert.equal(validateLifetimeOrderAmount({ ...base, amountCents: 490 }), false)
  })

  test("rejects the wrong currency", () => {
    assert.equal(validateLifetimeOrderAmount({ ...base, amountCents: 1100, currency: "eur" }), false)
  })

  test("accepts only the exact server-recorded checkout discount above the minimum", () => {
    assert.equal(validateLifetimeOrderAmount({ ...base, amountCents: 701, checkoutCreditCents: 399, hasConfiguredDiscount: true }), true)
    assert.equal(validateLifetimeOrderAmount({ ...base, amountCents: 490, checkoutCreditCents: 610, hasConfiguredDiscount: true }), false)
    assert.equal(validateLifetimeOrderAmount({ ...base, amountCents: 701, checkoutCreditCents: 399, hasConfiguredDiscount: false }), false)
    assert.equal(validateLifetimeOrderAmount({ ...base, amountCents: 700, checkoutCreditCents: 399, hasConfiguredDiscount: true }), false)
  })
})
