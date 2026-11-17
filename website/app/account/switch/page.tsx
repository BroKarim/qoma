"use client"
import { authClient } from "@/lib/auth-client"
import { useState } from "react"
import styles from "../account.module.css"
export default function SwitchAccount() {
  const [error, setError] = useState("")
  return <main className={styles.page}><div className={styles.wrap}><h1>Switch browser account</h1><p className="my-5">This signs out of the website. Your Mac stays signed in.</p><button className={styles.primary} onClick={async () => { const result = await authClient.signOut(); if (result.error) setError("Could not sign out. Try again."); else window.location.assign(window.location.search === "?checkout=app" ? "/auth?next=checkout-app" : window.location.search === "?checkout=start" ? "/auth?next=checkout" : "/auth") }}>Sign out and continue</button><p role="alert">{error}</p></div></main>
}
