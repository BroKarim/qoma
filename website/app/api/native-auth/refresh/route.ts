import { rotateDeviceCredential } from "@/lib/access/native"

export const runtime = "nodejs"

export async function POST(request: Request) {
  const credential = request.headers.get("authorization")?.replace(/^Bearer /, "") ?? ""
  try {
    return Response.json(await rotateDeviceCredential(credential))
  } catch (error) {
    if (error instanceof Error && error.message === "INVALID_CREDENTIAL") {
      return Response.json({ error: "Sign in again" }, { status: 401 })
    }
    throw error
  }
}
