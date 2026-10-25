import { exchangeNativeCode } from "@/lib/access/native"

export const runtime = "nodejs"

export async function POST(request: Request) {
  try {
    const body = await request.json()
    return Response.json(await exchangeNativeCode(body.code, body.verifier, body.installationId))
  } catch (error) {
    if (error instanceof Error && error.message === "DEVICE_LIMIT") {
      return Response.json({ error: "Two Macs are already active. Remove one at qyube.brokarim.com/account." }, { status: 409 })
    }
    if (error instanceof Error && ["INVALID_REQUEST", "INVALID_CODE"].includes(error.message)) {
      return Response.json({ error: "Invalid or expired login code" }, { status: 400 })
    }
    throw error
  }
}
