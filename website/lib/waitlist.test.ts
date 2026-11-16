import { test } from "node:test"
import assert from "node:assert/strict"
import { waitlistEmail } from "./waitlist"

test("waitlist normalizes email without a consent checkbox", () => {
  assert.equal(
    waitlistEmail({ email: " Test@Example.com ", website: "" }),
    "test@example.com"
  )
  for (const input of [
    null,
    {},
    { email: "bad" },
    { email: "x@y.com", website: "spam" },
  ])
    assert.equal(waitlistEmail(input), null)
})
