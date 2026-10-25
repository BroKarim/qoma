import Link from "next/link"
import { headers } from "next/headers"
import { redirect } from "next/navigation"
import { getAuth } from "@/lib/auth"

export const dynamic = "force-dynamic"

export default async function AccountPage() {
  const session = await getAuth().api.getSession({ headers: await headers() })
  if (!session) redirect("/auth")

  return <main className="mx-auto flex min-h-screen max-w-lg flex-col gap-5 px-6 py-20 text-black">
    <h1 className="text-3xl font-semibold">Your Qyube account</h1>
    <p>Signed in as {session.user.email}</p>
    <p>To start your seven-day trial, finish connecting the Qyube Mac app.</p>
    <p>Returning from checkout? Your access updates after Polar confirms payment, which may take a moment. Reopen Qyube to refresh.</p>
    <Link href="/pricing" className="underline">View plans</Link>
    <Link href="/api/billing/portal" className="underline">Manage subscription and invoices in Polar</Link>
  </main>
}
