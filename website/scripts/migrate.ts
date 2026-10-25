import { readFileSync } from "node:fs"
import { join } from "node:path"
import { fileURLToPath } from "node:url"
import { database } from "../lib/db"

const sql = readFileSync(join(fileURLToPath(new URL(".", import.meta.url)), "../db/001_access.sql"), "utf8")
const client = await database().connect()
try {
  await client.query("BEGIN")
  await client.query("SELECT pg_advisory_xact_lock(917381)")
  await client.query("CREATE TABLE IF NOT EXISTS schema_migrations (name text PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now())")
  const applied = await client.query("SELECT 1 FROM schema_migrations WHERE name = $1", ["001_access"])
  if (applied.rowCount === 0) {
    await client.query(sql)
    await client.query("INSERT INTO schema_migrations(name) VALUES ($1)", ["001_access"])
  }
  await client.query("COMMIT")
} catch (error) {
  await client.query("ROLLBACK")
  throw error
} finally {
  client.release()
  await database().end()
}
