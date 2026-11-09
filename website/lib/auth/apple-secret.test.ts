import { describe, test } from "node:test"
import assert from "node:assert/strict"
import { daysUntilExpiry } from "./apple-secret"

describe("Apple client secret expiry", () => {
  test("reads remaining lifetime and rejects malformed JWTs", () => {
    const payload = Buffer.from(JSON.stringify({ exp: 1_800_000_000 })).toString("base64url")
    assert.equal(daysUntilExpiry(`header.${payload}.signature`, 1_797_408_000_000), 30)
    assert.throws(() => daysUntilExpiry("not-a-jwt"))
  })
})
