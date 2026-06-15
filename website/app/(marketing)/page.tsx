import type { Metadata } from "next"
import MarketingPageClient from "./page.client"

export const metadata: Metadata = {
  title: "Qoma - A minimalist floating timer with analytics",
  description:
    "Qoma is a floating Pomodoro timer designed specifically for macOS that focuses entirely on simplicity and clean analytics.",
}

export default function MarketingPage() {
  return <MarketingPageClient />
}
