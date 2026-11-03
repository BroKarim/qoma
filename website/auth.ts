// Loaded by the Better Auth CLI after production environment variables are configured.
import { getAuth } from "./lib/auth"

if (process.env.DATABASE_MIGRATION_URL) process.env.DATABASE_URL = process.env.DATABASE_MIGRATION_URL
export const auth = getAuth()
