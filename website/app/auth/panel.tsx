"use client"

import { useEffect, useState } from "react"
import Link from "next/link"
import { useRouter } from "next/navigation"
import { authClient } from "@/lib/auth-client"
import { Apple } from "lucide-react"
import styles from "./account-auth.module.css"
import { LegalFooter } from "@/components/legal-footer"

function GoogleMark() {
  return <svg aria-hidden="true" viewBox="0 0 48 48" width="19" height="19"><path fill="#FFC107" d="M43.6 24.5c0-1.4-.1-2.8-.4-4.1H24v7.8h11a9.4 9.4 0 0 1-4.1 6.2v5.1h6.6c3.9-3.6 6.1-8.9 6.1-15Z"/><path fill="#FF3D00" d="M24 44c5.5 0 10.1-1.8 13.5-4.8l-6.6-5.1c-1.8 1.2-4.1 2-6.9 2-5.3 0-9.8-3.6-11.4-8.4H5.8v5.3A20 20 0 0 0 24 44Z"/><path fill="#4CAF50" d="M12.6 27.7a12 12 0 0 1 0-7.5v-5.3H5.8a20 20 0 0 0 0 18.1l6.8-5.3Z"/><path fill="#1976D2" d="M24 12c3 0 5.7 1 7.8 3.1l5.8-5.8A19.4 19.4 0 0 0 24 4 20 20 0 0 0 5.8 14.9l6.8 5.3C14.2 15.6 18.7 12 24 12Z"/></svg>
}

export default function AuthPanel({ requestId, invalidRequest }: { requestId: string | null; invalidRequest: boolean }) {
  const router = useRouter()
  const [busyProvider, setBusyProvider] = useState<"google" | "apple" | null>(null)
  const [message, setMessage] = useState("")
  const [providers, setProviders] = useState<{ google: boolean; apple: boolean } | null>(null)
  const { data: session, isPending } = authClient.useSession()
  const destination = requestId ? `/auth/complete?request=${encodeURIComponent(requestId)}` : "/account"

  useEffect(() => {
    fetch("/api/auth/providers", { cache: "no-store" }).then(response => response.json()).then(setProviders).catch(() => setProviders({ google: false, apple: false }))
  }, [])

  useEffect(() => {
    if (!invalidRequest && !isPending && session) router.replace(destination)
  }, [destination, invalidRequest, isPending, router, session])

  async function socialSignIn(provider: "google" | "apple") {
    setBusyProvider(provider)
    setMessage(`Opening ${provider === "google" ? "Google" : "Apple"} sign-in…`)
    try {
      const { error } = await authClient.signIn.social({ provider, callbackURL: destination })
      if (error) throw error
    } catch {
      setBusyProvider(null)
      setMessage(`${provider === "google" ? "Google" : "Apple"} sign-in is unavailable. Please try again.`)
    }
  }

  return <main className={styles.scene} style={{ backgroundImage: "url('/account/signin-fishing.webp')" }}>
    <Link href="/" className={styles.brand} aria-label="Qyube home">qyube</Link>
    <div className={styles.center}><section className={styles.card} aria-labelledby="signin-title">
      <h1 id="signin-title">A little closer to focus.</h1>
      <p className={styles.intro}>Sign in to connect Qyube on your Mac.</p>
      {invalidRequest && <p className={`${styles.status} ${styles.error}`} role="alert">This sign-in request is invalid. Return to Qyube on your Mac and start again.</p>}
      {!invalidRequest && !isPending && !session && providers?.google && <>
        <button type="button" className={styles.google} disabled={busyProvider !== null} onClick={() => socialSignIn("google")}>
          <GoogleMark />{busyProvider === "google" ? "Opening Google…" : "Continue with Google"}
        </button>
      </>}
      {!invalidRequest && !isPending && !session && providers?.apple && <>
        <button type="button" className={styles.apple} disabled={busyProvider !== null} onClick={() => socialSignIn("apple")}>
          <Apple size={19} fill="currentColor" aria-hidden="true" />{busyProvider === "apple" ? "Opening Apple…" : "Continue with Apple"}
        </button>
      </>}
      {!invalidRequest && !isPending && !session && providers === null && <p className={styles.status} role="status">Checking sign-in options…</p>}
      {!invalidRequest && !isPending && !session && providers && !providers.google && !providers.apple && <p className={`${styles.status} ${styles.error}`} role="alert">Sign-in is temporarily unavailable. Please try again later.</p>}
      {!invalidRequest && !isPending && !session && providers && (providers.google || providers.apple) && <>
        <p className={`${styles.status} ${message.includes("unavailable") ? styles.error : ""}`} role="status" aria-live="polite">{message}</p>
        <p className={styles.helper}>Your 7-day trial starts when you connect the app. No card required.</p>
      </>}
      {!invalidRequest && (isPending || session) && <p className={styles.status} role="status" aria-live="polite">{session ? "You’re signed in. Continuing…" : "Checking your sign-in…"}</p>}
      <div className={styles.terms}><Link href="/">Qyube for Mac</Link></div>
      <LegalFooter />
    </section></div>
  </main>
}
