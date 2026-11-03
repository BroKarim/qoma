import { generateKeyPairSync } from "node:crypto"
import { resolve } from "node:path"
import { fileURLToPath } from "node:url"

export function generateEntitlementKeys() {
  const { privateKey, publicKey } = generateKeyPairSync("ed25519")
  const pem = privateKey.export({ type: "pkcs8", format: "pem" }).toString()
  const jwk = publicKey.export({ format: "jwk" })
  if (!jwk.x) throw new Error("Ed25519 public key is missing")
  return { privateKey: pem.replaceAll("\n", "\\n"), publicKey: Buffer.from(jwk.x, "base64url").toString("base64") }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const keys = generateEntitlementKeys()
  process.stdout.write(`ENTITLEMENT_SIGNING_PRIVATE_KEY=${keys.privateKey}\nENTITLEMENT_SIGNING_PUBLIC_KEY=${keys.publicKey}\n`)
}
