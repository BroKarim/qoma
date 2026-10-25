"use client"

import { FormEvent, useState } from "react"
import { authClient } from "@/lib/auth-client"

export default function AuthPage() {
  const [email, setEmail] = useState("")
  const [otp, setOtp] = useState("")
  const [sent, setSent] = useState(false)
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState("")
  const { data: session } = authClient.useSession()
  const requestId = typeof window === "undefined" ? null : new URLSearchParams(window.location.search).get("request")
  const destination = requestId && /^[a-f0-9-]{36}$/i.test(requestId)
    ? `/auth/complete?request=${encodeURIComponent(requestId)}` : "/account"

  async function requestCode(event: FormEvent) {
    event.preventDefault()
    setBusy(true)
    setMessage("")
    try {
      const { error } = await authClient.emailOtp.sendVerificationOtp({ email, type: "sign-in" })
      if (error) throw error
      setSent(true)
      setMessage("Check your email for a six-digit code.")
    } catch {
      setMessage("Could not send a code. Please try again shortly.")
    } finally { setBusy(false) }
  }

  async function verifyCode(event: FormEvent) {
    event.preventDefault()
    setBusy(true)
    setMessage("")
    try {
      const { error } = await authClient.signIn.emailOtp({ email, otp })
      if (error) throw error
      window.location.assign(destination)
    } catch {
      setMessage("That code is invalid or expired.")
    } finally { setBusy(false) }
  }

  return <main className="mx-auto flex min-h-screen max-w-sm flex-col justify-center gap-5 px-6 text-black">
    <h1 className="text-3xl font-semibold">Sign in to Qyube</h1>
    <p>Sign in to start your free seven-day trial. No card is needed.</p>
    {session ? <a href={destination} className="underline">Continue to Qyube</a> : <>
      <button className="rounded-lg border p-3" disabled={busy} onClick={async () => {
        setBusy(true)
        const { error } = await authClient.signIn.social({ provider: "google", callbackURL: destination })
        if (error) { setBusy(false); setMessage("Google sign-in is unavailable.") }
      }}>Continue with Google</button>
      <form className="flex flex-col gap-3" onSubmit={sent ? verifyCode : requestCode}>
        <label htmlFor="email">Email</label>
        <input id="email" type="email" autoComplete="email" required value={email} onChange={event => setEmail(event.target.value)} className="rounded-lg border p-3" />
        {sent && <><label htmlFor="otp">Code</label><input id="otp" inputMode="numeric" autoComplete="one-time-code" pattern="[0-9]{6}" required value={otp} onChange={event => setOtp(event.target.value)} className="rounded-lg border p-3" /></>}
        <button className="rounded-lg bg-black p-3 text-white" disabled={busy}>{sent ? "Verify code" : "Send code"}</button>
      </form>
      {sent && <button className="text-left underline" disabled={busy} onClick={() => setSent(false)}>Use a different email</button>}
      <p role="status">{message}</p>
    </>}
  </main>
}
