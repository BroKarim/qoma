import { describe, test } from "node:test"
import assert from "node:assert/strict"
import { cleanupExpiredNativeAuth } from "./native-cleanup"

describe("expired native auth cleanup", () => {
  test("removes expired handoffs before the attempts they reference", async () => {
    const statements: string[] = []
    const removed = await cleanupExpiredNativeAuth({
      async query(sql) { statements.push(sql); return { rowCount: 3 } },
    })
    assert.deepEqual(statements, [
      "DELETE FROM native_handoffs WHERE expires_at <= now()",
      "DELETE FROM native_login_attempts WHERE expires_at <= now()",
    ])
    assert.equal(removed, 3)
  })
})
