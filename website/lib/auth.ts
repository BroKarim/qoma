import { betterAuth } from "better-auth"
import { importPKCS8, SignJWT } from "jose"
import { database } from "@/lib/db"

function createAuth() {
  const secret = process.env.BETTER_AUTH_SECRET
  if (!secret || secret.length < 32) throw new Error("BETTER_AUTH_SECRET must contain at least 32 characters")
  const googleId = process.env.GOOGLE_CLIENT_ID
  const googleSecret = process.env.GOOGLE_CLIENT_SECRET
  const appleClientId = process.env.APPLE_CLIENT_ID
  const appleTeamId = process.env.APPLE_TEAM_ID
  const appleKeyId = process.env.APPLE_KEY_ID
  const applePrivateKey = process.env.APPLE_PRIVATE_KEY?.replace(/\\n/g, "\n")
  const appleConfig = [appleClientId, appleTeamId, appleKeyId, applePrivateKey]
  if (appleConfig.some(Boolean) && appleConfig.some(value => !value)) {
    throw new Error("Apple sign-in requires APPLE_CLIENT_ID, APPLE_TEAM_ID, APPLE_KEY_ID, and APPLE_PRIVATE_KEY")
  }
  return betterAuth({
    baseURL: process.env.BETTER_AUTH_URL ?? "https://qyube.brokarim.com",
    secret,
    database: database(),
    emailAndPassword: { enabled: false },
    account: { accountLinking: { enabled: true } },
    socialProviders: {
      ...(googleId && googleSecret ? {
        google: { clientId: googleId, clientSecret: googleSecret },
      } : {}),
      ...(appleClientId && appleTeamId && appleKeyId && applePrivateKey ? {
        apple: async () => {
          const key = await importPKCS8(applePrivateKey, "ES256")
          const now = Math.floor(Date.now() / 1000)
          const clientSecret = await new SignJWT({})
            .setProtectedHeader({ alg: "ES256", kid: appleKeyId })
            .setIssuer(appleTeamId)
            .setSubject(appleClientId)
            .setAudience("https://appleid.apple.com")
            .setIssuedAt(now)
            .setExpirationTime(now + 180 * 24 * 60 * 60)
            .sign(key)
          return { clientId: appleClientId, clientSecret }
        },
      } : {}),
    },
    trustedOrigins: ["https://appleid.apple.com"],
  })
}

let instance: ReturnType<typeof createAuth> | undefined

export function getAuth(): ReturnType<typeof createAuth> {
  return instance ??= createAuth()
}
