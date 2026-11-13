import { test } from "node:test"
import assert from "node:assert/strict"
import { waitlistEmail } from "./waitlist"

test("waitlist normalizes email and requires explicit consent", () => {
  assert.equal(
    waitlistEmail({ email: " Test@Example.com ", consent: true, website: "" }),
    "test@example.com"
  )
  for (const input of [
    null,
    {},
    { email: "test@example.com", consent: false },
    { email: "bad", consent: true },
    { email: "x@y.com", consent: true, website: "spam" },
  ])
    assert.equal(waitlistEmail(input), null)
})
