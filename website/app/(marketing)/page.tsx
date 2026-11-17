import type { Metadata } from "next"
import MarketingPageClient from "./page.client"
// import MarketingInformation from "./marketing-information"

export const metadata: Metadata = {
  title: "Qyube — A cozy focus timer for Mac",
  description:
    "Stay focused with a tiny penguin island on your Mac. Set a timer, go fishing, and collect discoveries as you work.",
  alternates: { canonical: "/" },
}

export default function MarketingPage() {
  return (
    <main className="font-sans text-[#202020]">
      <MarketingPageClient />
      {/*<MarketingInformation />*/}
    </main>
  )
}
