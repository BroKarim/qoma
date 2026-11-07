export const dynamic = "force-dynamic"

export function GET() {
  return Response.json({
    google: Boolean(process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET),
    apple: Boolean(process.env.APPLE_CLIENT_ID && process.env.APPLE_CLIENT_SECRET),
  }, { headers: { "Cache-Control": "no-store" } })
}
