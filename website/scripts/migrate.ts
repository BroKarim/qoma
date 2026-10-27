import { fileURLToPath } from "node:url"
import { Pool } from "pg"
import { drizzle } from "drizzle-orm/node-postgres"
import { migrate } from "drizzle-orm/node-postgres/migrator"

const connectionString = process.env.DATABASE_MIGRATION_URL || process.env.DATABASE_URL
if (!connectionString) throw new Error("DATABASE_MIGRATION_URL or DATABASE_URL is required")
const url = new URL(connectionString)
if (url.hostname.endsWith(".supabase.com") || url.hostname.endsWith(".supabase.co")) {
  if (url.port === "6543") throw new Error("Migrations require a direct or session-pooler connection on port 5432")
}
const pool = new Pool({ connectionString, max: 1, connectionTimeoutMillis: 10_000 })
const client = await pool.connect()
try {
  await client.query("SELECT pg_advisory_lock(917381)")
  await migrate(drizzle(client), { migrationsFolder: fileURLToPath(new URL("../db/drizzle", import.meta.url)) })
  process.stdout.write("Drizzle migrations applied\n")
} finally {
  try {
    await client.query("SELECT pg_advisory_unlock(917381)")
  } finally {
    client.release()
    await pool.end()
  }
}
