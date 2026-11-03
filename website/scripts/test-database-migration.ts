import assert from "node:assert/strict"
import { spawnSync, type SpawnSyncReturns } from "node:child_process"
import { randomUUID } from "node:crypto"
import { readFileSync, readdirSync } from "node:fs"
import { eq } from "drizzle-orm"
import { getTableConfig } from "drizzle-orm/pg-core"
import { database, orm } from "../lib/db"
import * as schema from "../db/schema"

const url = process.env.DATABASE_URL
if (!url || !["127.0.0.1", "localhost"].includes(new URL(url).hostname) || process.env.QYUBE_ALLOW_LOCAL_INTEGRATION_TEST !== "1") {
  throw new Error("This test requires an explicitly approved, empty local PostgreSQL database")
}
const pool = database()
try {
  const existing = await pool.query("SELECT 1 FROM pg_tables WHERE schemaname = 'public'")
  assert.equal(existing.rowCount, 0, "Use a fresh disposable test database")
  const legacy = process.env.QYUBE_TEST_LEGACY === "1"
  if (legacy) {
    for (const file of readdirSync("db").filter(name => /^\d+_.*\.sql$/.test(name)).sort()) {
      await pool.query(readFileSync(`db/${file}`, "utf8"))
    }
    await pool.query("INSERT INTO entitlements(account_id,plan,status,version) VALUES('migration-sentinel','lifetime','active',7)")
  }
  for (let attempt = 0; attempt < 2; attempt++) {
    const result: SpawnSyncReturns<string> = spawnSync(process.execPath, ["scripts/migrate.ts"], {
      env: { ...process.env, DATABASE_MIGRATION_URL: url }, encoding: "utf8",
    })
    assert.equal(result.status, 0, result.stderr)
  }
  for (const table of Object.values(schema)) {
    const config = getTableConfig(table)
    const columns = await pool.query<{ column_name: string }>(
      "SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = $1", [config.name])
    assert.deepEqual(columns.rows.map(row => row.column_name).sort(), config.columns.map(column => column.name).sort(), config.name)
    const secured = await pool.query<{ relrowsecurity: boolean }>(
      "SELECT relrowsecurity FROM pg_class WHERE oid = $1::regclass", [`public.${config.name}`])
    assert.equal(secured.rows[0].relrowsecurity, true, `${config.name} must use RLS`)
    const constraints = await pool.query<{ conname: string }>("SELECT conname FROM pg_constraint WHERE conrelid = $1::regclass", [`public.${config.name}`])
    const names = new Set(constraints.rows.map(row => row.conname))
    for (const key of config.foreignKeys) assert.ok(names.has(key.getName()), key.getName())
    for (const key of config.primaryKeys) assert.ok(names.has(key.getName()), key.getName())
    for (const key of config.uniqueConstraints) {
      const name = key.getName()
      assert.ok(name)
      assert.ok(names.has(name), name)
    }
  }
  if (!legacy) await pool.query("INSERT INTO entitlements(account_id,plan,status,version) VALUES('migration-sentinel','lifetime','active',7)")
  const [sentinel] = await orm().select().from(schema.entitlements).where(eq(schema.entitlements.accountId, "migration-sentinel"))
  assert.equal(sentinel.version, BigInt(7))
  assert.equal(sentinel.plan, "lifetime")

  const client = await pool.connect()
  try {
    const role = `qyube_rls_${randomUUID().replaceAll("-", "")}`
    await client.query("BEGIN")
    await client.query(`CREATE ROLE "${role}" NOLOGIN`)
    await client.query(`GRANT USAGE ON SCHEMA public TO "${role}"`)
    await client.query(`GRANT SELECT ON entitlements TO "${role}"`)
    await client.query(`SET LOCAL ROLE "${role}"`)
    const hidden = await client.query("SELECT * FROM entitlements")
    assert.equal(hidden.rowCount, 0, "Unprivileged roles must not read entitlement rows")
  } finally {
    await client.query("ROLLBACK")
    client.release()
  }
  process.stdout.write(`${legacy ? "Legacy" : "Fresh"} migration, rerun, Drizzle schema, preserved rows and RLS checks passed\n`)
} finally {
  await pool.end()
}
