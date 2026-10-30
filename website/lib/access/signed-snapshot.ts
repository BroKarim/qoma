import { createPrivateKey, sign } from "node:crypto"
import type { Access } from "./entitlements"

export type Snapshot = {
  account_id: string
  device_id: string
  scope: "macos"
  plan: Access["plan"]
  status: Access["status"]
  access_until: string | null
  offline_until: string | null
  trial_ends_at: string | null
  issued_at: string
  version: number
}

export function signSnapshot(snapshot: Snapshot, privateKeyPem: string): string {
  const header = Buffer.from(JSON.stringify({ alg: "EdDSA", typ: "JWT", kid: "v1" })).toString("base64url")
  const payload = Buffer.from(JSON.stringify(snapshot)).toString("base64url")
  const input = `${header}.${payload}`
  const signature = sign(null, Buffer.from(input), createPrivateKey(privateKeyPem.replaceAll("\\n", "\n")))
  return `${input}.${signature.toString("base64url")}`
}
