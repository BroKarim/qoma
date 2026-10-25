import { betterAuth } from "better-auth"
import { emailOTP } from "better-auth/plugins"
import { database } from "@/lib/db"
import { sendLoginCode } from "@/lib/email"

function createAuth() {
  const secret = process.env.BETTER_AUTH_SECRET
  if (!secret || secret.length < 32) throw new Error("BETTER_AUTH_SECRET must contain at least 32 characters")
  const googleId = process.env.GOOGLE_CLIENT_ID
  const googleSecret = process.env.GOOGLE_CLIENT_SECRET
  return betterAuth({
    baseURL: process.env.BETTER_AUTH_URL ?? "https://qyube.brokarim.com",
    secret,
    database: database(),
    emailAndPassword: { enabled: false },
    account: { accountLinking: { enabled: true } },
    socialProviders: googleId && googleSecret ? {
      google: { clientId: googleId, clientSecret: googleSecret },
    } : {},
    rateLimit: {
      enabled: true,
      storage: "database",
      customRules: {
        "/email-otp/send-verification-otp": { window: 60, max: 3 },
        "/sign-in/email-otp": { window: 60, max: 5 },
      },
    },
    plugins: [emailOTP({
      otpLength: 6,
      expiresIn: 300,
      async sendVerificationOTP({ email, otp }) { await sendLoginCode(email, otp) },
    })],
  })
}

let instance: ReturnType<typeof createAuth> | undefined

export function getAuth(): ReturnType<typeof createAuth> {
  return instance ??= createAuth()
}
