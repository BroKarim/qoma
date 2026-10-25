import { getAuth } from "@/lib/auth"
import { database } from "@/lib/db"

export const runtime = "nodejs"

export async function GET(request: Request) {
  const session = await getAuth().api.getSession({ headers: request.headers })
  if (!session) return Response.json({ error: "Sign in required" }, { status: 401 })
  const { rows } = await database().query(
    "SELECT id, name, activated_at, last_seen_at FROM devices WHERE account_id = $1 AND revoked_at IS NULL ORDER BY activated_at DESC",
    [session.user.id],
  )
  return Response.json({ devices: rows })
}
