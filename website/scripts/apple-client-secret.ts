import { importPKCS8, SignJWT } from "jose"
import { daysUntilExpiry } from "../lib/auth/apple-secret"

const checkOnly = process.argv.includes("--check")
if (checkOnly) {
  const token = process.env.APPLE_CLIENT_SECRET
  if (!token) throw new Error("APPLE_CLIENT_SECRET is not configured")
  const days = daysUntilExpiry(token)
  console.log(`Apple client secret expires in ${days} days`)
  if (days < 30) {
    console.error("WARNING: rotate APPLE_CLIENT_SECRET and restart the website service")
    process.exitCode = 1
  }
} else {
  const clientId = process.env.APPLE_CLIENT_ID
  const teamId = process.env.APPLE_TEAM_ID
  const keyId = process.env.APPLE_KEY_ID
  const privateKey = process.env.APPLE_PRIVATE_KEY?.replace(/\\n/g, "\n")
  if (!clientId || !teamId || !keyId || !privateKey) throw new Error("Set APPLE_CLIENT_ID, APPLE_TEAM_ID, APPLE_KEY_ID, and APPLE_PRIVATE_KEY")
  const now = Math.floor(Date.now() / 1000)
  const key = await importPKCS8(privateKey, "ES256")
  const clientSecret = await new SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: keyId })
    .setIssuer(teamId)
    .setSubject(clientId)
    .setAudience("https://appleid.apple.com")
    .setIssuedAt(now)
    .setExpirationTime(now + 90 * 24 * 60 * 60)
    .sign(key)
  console.log(`Expires at: ${new Date((now + 90 * 24 * 60 * 60) * 1000).toISOString()}`)
  console.log(`APPLE_CLIENT_SECRET=${clientSecret}`)
}
