import assert from "node:assert/strict"
import { randomUUID } from "node:crypto"
import { jwtVerify } from "jose"
import { database } from "../lib/db"
import { digest } from "../lib/access/crypto"
import { POST as join } from "../app/api/waitlist/route"
import { POST as link } from "../app/api/me/account-link/route"
import { GET as open } from "../app/account/open/route"

if (process.env.QYUBE_TEST_DATABASE !== "1")
  throw new Error("Use an isolated test database and set QYUBE_TEST_DATABASE=1")
const testURL = new URL(process.env.DATABASE_URL ?? "")
if (testURL.hostname !== "127.0.0.1" || testURL.port !== "55439")
  throw new Error("Test database must use isolated localhost port 55439")
const db = database()
const id = randomUUID()
const account = `integration-${id}`
const credential = "a".repeat(43)
const origin = process.env.BETTER_AUTH_URL!
try {
  await db.query(
    "INSERT INTO devices(id, account_id, installation_hash, name) VALUES($1,$2,$3,'Test Mac')",
    [id, account, id]
  )
  await db.query(
    "INSERT INTO device_credentials(token_hash,device_id,account_id,expires_at) VALUES($1,$2,$3,now()+interval '1 hour')",
    [digest(credential), id, account]
  )
  const request = () =>
    new Request(`${origin}/api/me/account-link`, {
      method: "POST",
      headers: { authorization: `Bearer ${credential}` },
    })
  assert.equal(
    (
      await link(
        new Request(`${origin}/api/me/account-link`, { method: "POST" })
      )
    ).status,
    401
  )
  const result = await link(request())
  assert.equal(result.status, 200)
  const { url } = await result.json()
  const opened = await open(new Request(url))
  assert.equal(opened.status, 307)
  const cookie = opened.headers.get("set-cookie")!.split(";")[0].split("=")[1]
  const verified = await jwtVerify(
    cookie,
    new TextEncoder().encode(process.env.BETTER_AUTH_SECRET),
    { audience: "qyube-account-context" }
  )
  assert.equal(verified.payload.accountId, account)
  assert.equal((await open(new Request(url))).status, 410)
  await db.query(`INSERT INTO account_links(token_hash, account_id, device_id, expires_at)
    VALUES($1,$2,$3,now()-interval '1 minute')`, [digest("expired integration link"), account, id])
  const concurrentLinks = await Promise.all(
    Array.from({ length: 12 }, () => link(request()))
  )
  assert.equal(concurrentLinks.filter(response => response.status === 200).length, 10)
  assert.equal(concurrentLinks.filter(response => response.status === 429).length, 2)
  assert.equal(
    (await db.query("SELECT count(*)::int AS count FROM account_links WHERE device_id=$1 AND expires_at <= now()", [id])).rows[0].count,
    0
  )
  const other = await concurrentLinks.find(response => response.status === 200)!.json()
  await db.query("UPDATE devices SET revoked_at=now() WHERE id=$1", [id])
  assert.equal((await open(new Request(other.url))).status, 410)
  const email = `${id}@example.com`
  const post = (consent = true) =>
    join(
      new Request(`${origin}/api/waitlist`, {
        method: "POST",
        headers: { origin, "x-forwarded-for": "192.0.2.25" },
        body: JSON.stringify({ email, consent, website: "" }),
      })
    )
  assert.equal((await post(false)).status, 400)
  for (let i = 0; i < 5; i++) assert.equal((await post()).status, 200)
  assert.equal((await post()).status, 429)
  assert.equal(
    (
      await db.query(
        "SELECT count(*)::int AS count FROM waitlist WHERE email=$1",
        [email]
      )
    ).rows[0].count,
    1
  )
  assert.equal(
    (
      await db.query(
        "SELECT relrowsecurity FROM pg_class WHERE relname='waitlist'"
      )
    ).rows[0].relrowsecurity,
    true
  )
  console.log(
    "PASS: authenticated account handoff, replay/revocation, consent, deduplication, rate limit, RLS"
  )
} finally {
  await db.query("DELETE FROM account_links WHERE account_id=$1", [account])
  await db.query("DELETE FROM device_credentials WHERE account_id=$1", [
    account,
  ])
  await db.query("DELETE FROM devices WHERE id=$1", [id])
  await db.query("DELETE FROM waitlist WHERE email=$1", [`${id}@example.com`])
  await db.query("DELETE FROM waitlist_attempts")
  await db.end()
}
