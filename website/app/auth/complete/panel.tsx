"use client"

import { useEffect, useRef, useState } from "react"
import Link from "next/link"
import { Check, ExternalLink, LoaderCircle } from "lucide-react"
import styles from "../account-auth.module.css"

type Stage = "connecting" | "ready" | "expired" | "error"

export default function CompleteLoginPanel({ requestId, invalidRequest }: { requestId: string | null; invalidRequest: boolean }) {
  const [stage, setStage] = useState<Stage>(invalidRequest ? "expired" : "connecting")
  const [message, setMessage] = useState(invalidRequest ? "This sign-in link is invalid. Start again from Qyube on your Mac." : "Preparing the secure handoff to your Mac…")
  const [callback, setCallback] = useState<string>()
  const started = useRef(false)

  useEffect(() => {
    if (started.current || invalidRequest || !requestId) return
    started.current = true
    let expiryTimer: number | undefined
    void fetch("/api/native-auth/complete", {
      method: "POST", headers: { "content-type": "application/json" },
      body: JSON.stringify({ requestId }),
    }).then(async response => {
      const data = await response.json()
      if (!response.ok) {
        if (response.status === 400) throw new Error("expired")
        throw new Error("failed")
      }
      if (typeof data.url !== "string" || !data.url.startsWith("qyube://auth/callback?")) throw new Error("failed")
      setCallback(data.url)
      setStage("ready")
      setMessage("Return to Qyube on your Mac to finish signing in.")
      expiryTimer = window.setTimeout(() => {
        setCallback(undefined)
        setStage("expired")
        setMessage("This sign-in link expired. Start again from Qyube on your Mac.")
      }, 2 * 60 * 1000)
      window.location.assign(data.url)
    }).catch(error => {
      const expired = error instanceof Error && error.message === "expired"
      setStage(expired ? "expired" : "error")
      setMessage(expired ? "This sign-in request expired. Start again from Qyube on your Mac." : "We couldn’t reach Qyube. Check your connection, then try again from your Mac.")
    })
    return () => {
      if (expiryTimer !== undefined) window.clearTimeout(expiryTimer)
    }
  }, [invalidRequest, requestId])

  return <main className={styles.scene} style={{ backgroundImage: "url('/account/account-calm.webp')" }}>
    <Link href="/" className={styles.brand} aria-label="Qyube home">qyube</Link>
    <div className={styles.center}><section className={`${styles.card} ${styles.complete}`} aria-labelledby="complete-title">
      <span className={styles.check} aria-hidden="true">{stage === "ready" ? <Check size={25} strokeWidth={3} /> : <LoaderCircle size={23} className={stage === "connecting" ? "animate-spin" : ""} />}</span>
      <h1 id="complete-title">{stage === "ready" ? "You’re ready to focus." : stage === "connecting" ? "Connecting to your Mac…" : "Let’s try that again."}</h1>
      <p className={styles.intro} role="status" aria-live="polite">{message}</p>
      {stage === "ready" && callback && <>
        <a className={styles.primary} href={callback}>Open Qyube <ExternalLink size={16} /></a>
        <p className={styles.helper}>You can close this tab after Qyube opens.</p>
        <p className={styles.helper}>App didn’t open? <a className={styles.inlineLink} href={callback}>Try again</a></p>
      </>}
      {stage === "connecting" && <p className={styles.helper}>Keep this tab open for a moment.</p>}
      {(stage === "expired" || stage === "error") && <>
        <p className={styles.helper}>Go back to Qyube on your Mac and choose Sign in to create a fresh secure link.</p>
        <Link className={styles.secondary} href="/auth">Return to sign in</Link>
      </>}
    </section></div>
  </main>
}
