import { getAuth } from "@/lib/auth"
import { database } from "@/lib/db"
import { polar } from "@/lib/billing/polar"

export const runtime = "nodejs"

export async function GET(request: Request) {
  const session = await getAuth().api.getSession({ headers: request.headers })
  if (!session?.user.emailVerified) return Response.redirect(new URL("/auth", request.url))
  const { rows } = await database().query("SELECT 1 FROM billing_customers WHERE account_id = $1 AND provider = 'polar'", [session.user.id])
  if (!rows.length) return Response.redirect(new URL("/pricing", request.url))
  const portal = await polar().customerSessions.create({
    external_customer_id: session.user.id,
    return_url: `${process.env.BETTER_AUTH_URL}/account`,
  })
  return Response.redirect(portal.customer_portal_url)
}
