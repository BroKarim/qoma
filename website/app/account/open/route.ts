import { NextResponse } from "next/server"
import { SignJWT } from "jose"
import { digest } from "@/lib/access/crypto"
import { database } from "@/lib/db"

export async function GET(request: Request) {
  const code = new URL(request.url).searchParams.get("code") ?? ""
  const secret = process.env.BETTER_AUTH_SECRET
  if (!secret || !/^[A-Za-z0-9_-]{43}$/.test(code)) return new Response("Invalid link", { status: 400 })
  const { rows } = await database().query<{ account_id: string }>(`DELETE FROM account_links l
    USING devices d WHERE l.token_hash=$1 AND l.expires_at>now() AND d.id=l.device_id
    AND d.account_id=l.account_id AND d.revoked_at IS NULL RETURNING l.account_id`, [digest(code)])
  if (!rows[0]) return new Response("Link expired. Open Account & purchases again from Qyube.", { status: 410 })
  const context = await new SignJWT({ accountId: rows[0].account_id }).setProtectedHeader({ alg: "HS256" })
    .setAudience("qyube-account-context").setExpirationTime("10m").sign(new TextEncoder().encode(secret))
  const response = NextResponse.redirect(new URL(new URL(request.url).searchParams.get("checkout") === "1" ? "/account?checkout=app" : "/account", request.url))
  response.cookies.set("qyube-account-context", context, { httpOnly: true, secure: process.env.NODE_ENV === "production", sameSite: "lax", path: "/", maxAge: 600 })
  response.headers.set("Referrer-Policy", "no-referrer")
  response.headers.set("Cache-Control", "no-store")
  return response
}
