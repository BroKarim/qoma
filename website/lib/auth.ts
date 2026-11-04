import { betterAuth } from "better-auth"
import { database } from "@/lib/db"

function createAuth() {
  const secret = process.env.BETTER_AUTH_SECRET
  if (!secret || secret.length < 32) throw new Error("BETTER_AUTH_SECRET must contain at least 32 characters")
  const googleId = process.env.GOOGLE_CLIENT_ID
  const googleSecret = process.env.GOOGLE_CLIENT_SECRET
  const appleClientId = process.env.APPLE_CLIENT_ID
  const appleClientSecret = process.env.APPLE_CLIENT_SECRET
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
      ...(appleClientId && appleClientSecret ? { apple: { clientId: appleClientId, clientSecret: appleClientSecret } } : {}),
    },
    trustedOrigins: ["https://appleid.apple.com"],
  })
}

let instance: ReturnType<typeof createAuth> | undefined

export function getAuth(): ReturnType<typeof createAuth> {
  return instance ??= createAuth()
}
