type Queryable = { query(sql: string): Promise<{ rowCount: number | null }> }

export async function cleanupExpiredNativeAuth(db: Queryable) {
  await db.query("DELETE FROM native_handoffs WHERE expires_at <= now()")
  const attempts = await db.query("DELETE FROM native_login_attempts WHERE expires_at <= now()")
  return attempts.rowCount ?? 0
}
