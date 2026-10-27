import type { Metadata } from "next"
import MarketingPageClient from "./page.client"
import MarketingInformation from "./marketing-information"

export const metadata: Metadata = {
  title: "qyube — Focus with a little catch",
  description:
    "A quiet focus timer for Mac, with a penguin who fishes while you work.",
}

export default function MarketingPage() {
  return (
    <main className="font-sans text-[#202020]">
      <MarketingPageClient />
      <MarketingInformation />
    </main>
  )
}
