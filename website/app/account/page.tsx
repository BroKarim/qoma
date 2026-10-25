import Link from "next/link"
import { headers } from "next/headers"
import { redirect } from "next/navigation"
import { getAuth } from "@/lib/auth"
import { database } from "@/lib/db"
import { DeviceList } from "./device-list"

export const dynamic = "force-dynamic"

export default async function AccountPage() {
  const session = await getAuth().api.getSession({ headers: await headers() })
  if (!session) redirect("/auth")
  const [entitlement, devices] = await Promise.all([
    database().query<{ plan: string | null; status: string; trial_ends_at: Date | null; access_until: Date | null }>(
      "SELECT plan, status, trial_ends_at, access_until FROM entitlements WHERE account_id = $1", [session.user.id]),
    database().query<{ id: string; name: string; last_seen_at: Date }>(
      "SELECT id, name, last_seen_at FROM devices WHERE account_id = $1 AND revoked_at IS NULL ORDER BY activated_at DESC", [session.user.id]),
  ])
  const access = entitlement.rows[0]

  return <main className="mx-auto flex min-h-screen max-w-lg flex-col gap-5 px-6 py-20 text-black">
    <h1 className="text-3xl font-semibold">Your Qyube account</h1>
    <p>Signed in as {session.user.email}</p>
    <p>Access: {access ? `${access.plan ?? "none"} · ${access.status}` : "Connect the Mac app to start your seven-day trial"}</p>
    {access?.trial_ends_at && <p>Trial ends {access.trial_ends_at.toLocaleDateString()}.</p>}
    <p>Returning from checkout? Your access updates after Polar confirms payment, which may take a moment. Reopen Qyube to refresh.</p>
    <Link href="/pricing" className="underline">View plans</Link>
    <Link href="/api/billing/portal" className="underline">Manage subscription and invoices in Polar</Link>
    <DeviceList initial={devices.rows.map((device) => ({ ...device, last_seen_at: device.last_seen_at.toISOString() }))} />
  </main>
}
