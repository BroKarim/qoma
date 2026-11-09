import { startNativeLogin } from "@/lib/access/native"
import { trustedClientIp } from "@/lib/access/proxy-ip"

export const runtime = "nodejs"

export async function POST(request: Request) {
  try {
    const body = await request.json()
    const trustedProxyCount = Number(process.env.TRUSTED_PROXY_COUNT ?? "1")
    const sourceIp = trustedClientIp(request.headers.get("x-forwarded-for"), trustedProxyCount)
    if (!sourceIp) return Response.json({ error: "Unable to identify client address" }, { status: 400 })
    return Response.json(await startNativeLogin({ ...body, sourceIp }))
  } catch (error) {
    if (error instanceof Error && error.message === "INVALID_REQUEST") return Response.json({ error: "Invalid request" }, { status: 400 })
    if (error instanceof Error && error.message === "RATE_LIMITED") return Response.json({ error: "Too many login attempts" }, { status: 429 })
    throw error
  }
}
