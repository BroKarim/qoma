import { describe, test } from "node:test"
import assert from "node:assert/strict"
import { shouldProcessWebhookEvent } from "./webhook"

describe("Polar webhook idempotency", () => {
  test("skips an already processed duplicate but allows failed and deferred retries", () => {
    assert.equal(shouldProcessWebhookEvent("processed"), false)
    assert.equal(shouldProcessWebhookEvent("failed"), true)
    assert.equal(shouldProcessWebhookEvent("deferred"), true)
  })
})
