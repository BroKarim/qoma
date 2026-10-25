import { headers } from "next/headers"
import Link from "next/link"
import { getAuth } from "@/lib/auth"
import { CheckoutButton } from "./checkout-button"

export const dynamic = "force-dynamic"

export default async function PricingPage() {
  const session = await getAuth().api.getSession({ headers: await headers() })
  return <main className="mx-auto max-w-3xl px-6 py-20 text-black">
    <h1 className="text-4xl font-semibold">Qyube for macOS</h1>
    <p className="mt-4">Your seven-day trial starts when you connect the Mac app. No card or automatic charge. You may buy a plan at any time.</p>
    <div className="mt-10 grid gap-4 sm:grid-cols-3">
      {([['monthly', '$3.99', 'per month'], ['annual', '$29', 'per year'], ['lifetime', '$49', 'one-time · macOS only']] as const).map(([plan, price, cadence]) =>
        <section key={plan} className="rounded-2xl border border-gray-200 p-6">
          <h2 className="capitalize">{plan}</h2><p className="mt-3 text-3xl font-semibold">{price}</p><p className="mb-6 text-sm text-gray-600">{cadence}</p>
          {session ? <CheckoutButton plan={plan} /> : <Link href="/auth" className="underline">Sign in to purchase</Link>}
        </section>)}
    </div>
    <p className="mt-6 text-sm text-gray-600">Taxes and final charge are shown by Polar before confirmation. Lifetime applies only to the macOS app.</p>
  </main>
}
