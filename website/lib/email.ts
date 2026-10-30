import { Resend } from "resend"

export async function sendLoginCode(email: string, otp: string): Promise<void> {
  const key = process.env.RESEND_API_KEY
  const from = process.env.RESEND_FROM
  if (!key || !from) throw new Error("Resend is not configured")
  const { error } = await new Resend(key).emails.send({
    from,
    to: email,
    subject: "Your Qyube sign-in code",
    text: `Your Qyube sign-in code is ${otp}. It expires in 5 minutes. If you did not request this, ignore this email.`,
  })
  if (error) throw new Error(`Could not send sign-in email: ${error.message}`)
}
