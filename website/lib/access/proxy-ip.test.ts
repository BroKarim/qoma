import { describe, test } from "node:test"
import assert from "node:assert/strict"
import { trustedClientIp } from "./proxy-ip"

describe("trustedClientIp", () => {
  test("selects the first untrusted hop before the configured proxy chain", () => {
    assert.equal(trustedClientIp("198.51.100.8, 10.0.0.2", 1), "198.51.100.8")
    assert.equal(trustedClientIp("198.51.100.8, 10.0.0.2, 10.0.0.3", 2), "198.51.100.8")
    assert.equal(trustedClientIp("198.51.100.8", 1), "198.51.100.8")
  })

  test("rejects missing, short, and malformed proxy chains", () => {
    assert.equal(trustedClientIp(null), null)
    assert.equal(trustedClientIp("10.0.0.2", 2), null)
    assert.equal(trustedClientIp("attacker, 10.0.0.2"), null)
    assert.equal(trustedClientIp("198.51.100.8", 0), null)
  })
})
