import { database } from "../lib/db"
import { cleanupExpiredNativeAuth } from "../lib/access/native-cleanup"

const db = database()
try {
  const removed = await cleanupExpiredNativeAuth(db)
  console.log(`Removed ${removed} expired native login attempts`)
} finally {
  await db.end()
}
