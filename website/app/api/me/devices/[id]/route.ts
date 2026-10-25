import { getAuth } from "@/lib/auth"
import { database } from "@/lib/db"
import { revokeDevice } from "@/lib/access/native"

export const runtime = "nodejs"

export async function DELETE(request: Request, context: { params: Promise<{ id: string }> }) {
  if (request.headers.get("origin") !== (process.env.BETTER_AUTH_URL ?? "https://qyube.brokarim.com")) {
    return Response.json({ error: "Invalid origin" }, { status: 403 })
  }
  const session = await getAuth().api.getSession({ headers: request.headers })
  if (!session) return Response.json({ error: "Sign in required" }, { status: 401 })
  const { id } = await context.params
  if (!/^[a-f0-9-]{36}$/i.test(id)) return Response.json({ error: "Invalid device" }, { status: 400 })
  const client = await database().connect()
  try {
    await client.query("BEGIN")
    const found = await revokeDevice(client, session.user.id, id)
    await client.query("COMMIT")
    return Response.json({ removed: found })
  } catch (error) {
    await client.query("ROLLBACK")
    throw error
  } finally { client.release() }
}
