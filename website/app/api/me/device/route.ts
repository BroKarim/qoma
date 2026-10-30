import { database } from "@/lib/db"
import { authenticatedDevice, revokeDevice } from "@/lib/access/native"

export const runtime = "nodejs"

export async function DELETE(request: Request) {
  const device = await authenticatedDevice(request)
  if (!device) return Response.json({ error: "Unauthorized" }, { status: 401 })
  const client = await database().connect()
  try {
    await client.query("BEGIN")
    await revokeDevice(client, device.accountId, device.deviceId)
    await client.query("COMMIT")
    return Response.json({ revoked: true })
  } catch (error) {
    await client.query("ROLLBACK")
    throw error
  } finally { client.release() }
}
