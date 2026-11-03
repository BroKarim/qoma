import { test } from "node:test"
import assert from "node:assert/strict"
import { createPrivateKey, createPublicKey, generateKeyPairSync, sign, verify } from "node:crypto"
import { signSnapshot } from "./signed-snapshot"
import { generateEntitlementKeys } from "../../scripts/generate-entitlement-keys"

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

test("setup keys produce the raw Base64 Ed25519 key expected by the Mac app", () => {
  const keys = generateEntitlementKeys()
  const raw = Buffer.from(keys.publicKey, "base64")
  assert.equal(raw.length, 32)
  const privateKey = createPrivateKey(keys.privateKey.replaceAll("\\n", "\n"))
  const publicKey = createPublicKey({ key: { kty: "OKP", crv: "Ed25519", x: raw.toString("base64url") }, format: "jwk" })
  const message = Buffer.from("Qyube key setup check")
  assert.equal(verify(null, message, publicKey, sign(null, message, privateKey)), true)
})
