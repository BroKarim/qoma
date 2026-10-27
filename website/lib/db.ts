import { Pool, type PoolClient } from "pg"
import { drizzle } from "drizzle-orm/node-postgres"
import * as schema from "../db/schema"

let pool: Pool | undefined

export function database(): Pool {
  if (!pool) {
    const connectionString = process.env.DATABASE_URL
    if (!connectionString) throw new Error("DATABASE_URL is not configured")
    pool = new Pool({ connectionString, max: 5, connectionTimeoutMillis: 10_000, idleTimeoutMillis: 30_000 })
  }
  return pool
}

// Share the pool with Better Auth and the SQL transactions that enforce billing locks.
export function orm(client?: PoolClient) {
  return drizzle(client ?? database(), { schema })
}
