import { database } from "../lib/db"

// Better Auth migrates separately; deny Supabase Data API access to its tables too.
if (process.env.DATABASE_MIGRATION_URL) process.env.DATABASE_URL = process.env.DATABASE_MIGRATION_URL
const client = await database().connect()
try {
  await client.query("BEGIN")
  for (const name of ["user", "session", "account", "verification", "rateLimit"]) {
    const { rows } = await client.query("SELECT to_regclass($1) AS name", [`public."${name}"`])
    if (rows[0].name) await client.query(`ALTER TABLE public."${name}" ENABLE ROW LEVEL SECURITY`)
  }
  await client.query("COMMIT")
} catch (error) {
  await client.query("ROLLBACK")
  throw error
} finally {
  client.release()
  await database().end()
}
