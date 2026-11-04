import { headers } from "next/headers"
import Link from "next/link"
import { getAuth } from "@/lib/auth"
import { CheckoutButton } from "./checkout-button"
import { LegalFooter } from "@/components/legal-footer"
import { formatUSD, prices } from "@/lib/billing/polar"

export const dynamic = "force-dynamic"

export default async function PricingPage() {
  const session = await getAuth().api.getSession({ headers: await headers() })
  return <main className="mx-auto max-w-3xl px-6 py-20 text-black">
    <h1 className="text-4xl font-semibold">Qyube Pro for macOS</h1>
    <p className="mt-4">Your seven-day trial starts when you connect the Mac app. No card or automatic charge.</p>
    <div className="mt-10 max-w-md">
      <section className="rounded-2xl border border-gray-200 bg-white p-6 shadow-sm">
        <h2 className="font-semibold">Lifetime access</h2><p className="mt-3 text-3xl font-semibold">{formatUSD(prices.lifetime)}</p><p className="mb-6 text-sm text-gray-600">One payment · Qyube for macOS</p>
        {session ? <CheckoutButton plan="lifetime" /> : <Link href="/auth" className="underline">Sign in to purchase</Link>}
      </section>
    </div>
    <p className="mt-6 text-sm text-gray-600">Taxes and final charge are shown by Polar before confirmation. Lifetime access is for Qyube on macOS.</p>
    <LegalFooter />
  </main>
}
