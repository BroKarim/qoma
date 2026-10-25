import { getAuth } from "@/lib/auth"
import { completeNativeLogin } from "@/lib/access/native"

export const runtime = "nodejs"

export async function POST(request: Request) {
  if (request.headers.get("origin") !== (process.env.BETTER_AUTH_URL ?? "https://qyube.brokarim.com")) {
    return Response.json({ error: "Invalid origin" }, { status: 403 })
  }
  const session = await getAuth().api.getSession({ headers: request.headers })
  if (!session || !session.user.emailVerified) return Response.json({ error: "Verified login required" }, { status: 401 })
  try {
    const { requestId } = await request.json()
    return Response.json({ url: await completeNativeLogin(requestId, session.user.id) })
  } catch (error) {
    if (error instanceof Error && ["INVALID_REQUEST", "LOGIN_EXPIRED"].includes(error.message)) {
      return Response.json({ error: "Login request expired" }, { status: 400 })
    }
    throw error
  }
}
