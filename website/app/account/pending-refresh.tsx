"use client"

import { useEffect } from "react"
import { useRouter } from "next/navigation"

export function PendingRefresh() {
  const router = useRouter()
  useEffect(() => {
    const timer = window.setInterval(() => router.refresh(), 4000)
    const stop = window.setTimeout(() => window.clearInterval(timer), 60_000)
    return () => { window.clearInterval(timer); window.clearTimeout(stop) }
  }, [router])
  return null
}
