import { Pool } from "pg"

let pool: Pool | undefined

export function database(): Pool {
  if (!pool) {
    const connectionString = process.env.DATABASE_URL
    if (!connectionString) throw new Error("DATABASE_URL is not configured")
    pool = new Pool({ connectionString, max: 10 })
  }
  return pool
}
