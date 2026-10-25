import { test } from "node:test"
import assert from "node:assert/strict"
import { generateKeyPairSync, verify } from "node:crypto"
import { signSnapshot } from "./signed-snapshot"

test("signed entitlement cannot be altered", () => {
  const { privateKey, publicKey } = generateKeyPairSync("ed25519")
  const jws = signSnapshot({
    account_id: "user", device_id: "mac", scope: "macos", plan: "trial", status: "active",
    access_until: "2026-11-01T00:00:00Z", offline_until: "2026-11-01T00:00:00Z",
    trial_ends_at: "2026-11-01T00:00:00Z", issued_at: "2026-10-25T00:00:00Z", version: 1,
  }, privateKey.export({ format: "pem", type: "pkcs8" }).toString())
  const [header, body, signature] = jws.split(".")
  assert.equal(verify(null, Buffer.from(`${header}.${body}`), publicKey, Buffer.from(signature, "base64url")), true)
  assert.equal(verify(null, Buffer.from(`${header}.${body}x`), publicKey, Buffer.from(signature, "base64url")), false)
})
