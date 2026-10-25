"use client"

import { useEffect, useRef, useState } from "react"

export default function CompleteLoginPage() {
  const [message, setMessage] = useState("Connecting Qyube…")
  const [callback, setCallback] = useState<string>()
  const started = useRef(false)

  useEffect(() => {
    if (started.current) return
    started.current = true
    const requestId = new URLSearchParams(window.location.search).get("request")
    if (!requestId) { setMessage("This login request is missing. Start again in the Mac app."); return }
    void fetch("/api/native-auth/complete", {
      method: "POST", headers: { "content-type": "application/json" },
      body: JSON.stringify({ requestId }),
    }).then(async response => {
      if (!response.ok) throw new Error()
      const data = await response.json()
      setCallback(data.url)
      setMessage("Qyube is ready. Open the Mac app to finish signing in.")
      window.location.assign(data.url)
    }).catch(() => setMessage("Could not finish login. Return to the Mac app and try again."))
  }, [])

  return <main className="mx-auto flex min-h-screen max-w-md flex-col justify-center gap-5 px-6 text-black">
    <h1 className="text-3xl font-semibold">Finish Qyube sign-in</h1>
    <p role="status">{message}</p>
    {callback && <a href={callback} className="rounded-lg bg-black p-3 text-center text-white">Open Qyube</a>}
  </main>
}
