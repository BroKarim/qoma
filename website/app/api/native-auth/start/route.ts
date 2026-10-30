import { startNativeLogin } from "@/lib/access/native"

export const runtime = "nodejs"

export async function POST(request: Request) {
  try {
    const body = await request.json()
    return Response.json(await startNativeLogin(body))
  } catch (error) {
    if (error instanceof Error && error.message === "INVALID_REQUEST") return Response.json({ error: "Invalid request" }, { status: 400 })
    if (error instanceof Error && error.message === "RATE_LIMITED") return Response.json({ error: "Too many login attempts" }, { status: 429 })
    throw error
  }
}
