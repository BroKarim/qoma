"use client"
import { authClient } from "@/lib/auth-client"
import { useState } from "react"
export default function SwitchAccount() {
  const [error, setError] = useState("")
  return <main className="mx-auto max-w-lg p-12"><h1>Switch browser account</h1><p>This signs out of the website. Your Mac stays signed in.</p><button onClick={async () => { const result = await authClient.signOut(); if (result.error) setError("Could not sign out. Try again."); else window.location.assign("/auth") }}>Sign out and continue</button><p role="alert">{error}</p></main>
}
