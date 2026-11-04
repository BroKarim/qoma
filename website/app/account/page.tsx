import Link from "next/link"
import { headers } from "next/headers"
import { redirect } from "next/navigation"
import { Check, CreditCard, Laptop, Monitor, Sparkles } from "lucide-react"
import { getAuth } from "@/lib/auth"
import { database } from "@/lib/db"
import { recomputeEntitlement } from "@/lib/access/entitlements"
import { accountAccessState, showCheckoutPending } from "@/lib/account/status"
import { DeviceList } from "./device-list"
import { PendingRefresh } from "./pending-refresh"
import { LegalFooter } from "@/components/legal-footer"
import { formatUSD, prices } from "@/lib/billing/polar"
import styles from "./account.module.css"

export const dynamic = "force-dynamic"

export default async function AccountPage({ searchParams }: { searchParams: Promise<{ checkout?: string; portal?: string }> }) {
  const session = await getAuth().api.getSession({ headers: await headers() })
  if (!session) redirect("/auth")
  const query = await searchParams
  const currentAccess = await recomputeEntitlement(session.user.id)
  const [entitlement, devices, orders] = await Promise.all([
    database().query<{ plan: string | null; status: string; trial_ends_at: Date | null; access_until: Date | null }>(
      "SELECT plan, status, trial_ends_at, access_until FROM entitlements WHERE account_id = $1", [session.user.id]),
    database().query<{ id: string; name: string; last_seen_at: Date }>(
      "SELECT id, name, last_seen_at FROM devices WHERE account_id = $1 AND revoked_at IS NULL ORDER BY activated_at DESC", [session.user.id]),
    database().query<{ id: string; plan: string; status: string; refunded_cents: number; paid_at: Date; total_cents: number; currency: string }>(
      "SELECT provider_order_id AS id, plan, status, refunded_cents, paid_at, COALESCE(total_cents, amount_cents) AS total_cents, currency FROM billing_orders WHERE account_id = $1 AND status IN ('paid', 'refunded') ORDER BY paid_at DESC", [session.user.id]),
  ])
  const access = { ...currentAccess, ...(entitlement.rows[0] ?? {}) }
  const state = accountAccessState({ plan: access.plan, status: access.status, accessUntil: access.accessUntil, trialEndsAt: access.trialEndsAt })
  const lifetime = state.lifetime
  const trial = state.trial
  const active = state.active
  const checkout = await database().query<{ final: boolean }>(`
    SELECT EXISTS (SELECT 1 FROM checkout_attempts
      WHERE account_id = $1 AND plan = 'lifetime' AND completed_at IS NOT NULL
        AND created_at > now() - interval '24 hours') AS final`, [session.user.id])
  const checkoutPending = showCheckoutPending(query.checkout === "returned", checkout.rows[0].final)

  return <main className={styles.page}>
    <div className={styles.wrap}>
      <Link href="/" className={styles.brand}>qyube</Link>
      <h1 className={styles.heading}>Your Qyube account</h1>
      <p className={`${styles.muted} mb-7`}>Signed in as {session.user.email}</p>
      {checkoutPending && <><PendingRefresh /><p className={`${styles.notice} mb-5`} role="status">Payment is being confirmed by Polar. This page will update automatically.</p></>}
      {query.portal === "unavailable" && <p className={`${styles.alert} mb-5`} role="alert">Purchases and invoices are temporarily unavailable. Please try again shortly.</p>}

      <section className={`${styles.card} mb-4`} aria-labelledby="access-heading">
        <div className={styles.row}>
          <div className="flex items-center gap-3"><span className="grid size-11 place-items-center rounded-full bg-sky-100 text-sky-700"><Sparkles size={20} /></span><div><h2 id="access-heading" className="font-semibold">{lifetime ? "Qyube Pro" : trial ? "Free trial" : "Qyube access"}</h2><p className={`${styles.muted} text-sm`}>{lifetime ? "One payment. Yours to keep." : trial && access.trial_ends_at ? `Trial ends ${access.trial_ends_at.toLocaleDateString()}.` : active && access?.access_until ? `Access through ${access.access_until.toLocaleDateString()}.` : access?.status === "revoked" ? "Access was revoked." : devices.rows.length ? "Your trial has ended." : "Connect your Mac to start your 7-day trial."}</p></div></div>
          <span className={styles.badge}>{lifetime ? "Lifetime access" : active ? "Active" : "No active access"}</span>
        </div>
        {!lifetime && <div className="mt-5"><Link href="/pricing" className={styles.primary}><Sparkles size={15} /> Get Qyube Pro · {formatUSD(prices.lifetime)}</Link></div>}
      </section>

      <section className={`${styles.card} mb-4`} aria-labelledby="macs-heading">
        <div className={`${styles.row} mb-2`}><h2 id="macs-heading" className="font-semibold">Your Macs</h2><span className={`${styles.muted} text-sm`}>{devices.rows.length}/2 connected</span></div>
        {devices.rows.length ? <DeviceList initial={devices.rows.map(device => ({ ...device, last_seen_at: device.last_seen_at.toISOString() }))} /> : <p className={`${styles.muted} py-3 text-sm`}>Your connected Macs will appear here after you sign in from the app.</p>}
      </section>

      <section className={styles.card} aria-labelledby="purchases-heading">
        <h2 id="purchases-heading" className="mb-3 font-semibold">Purchases & invoices</h2>
        {orders.rows.length ? <ul className="mb-4 divide-y divide-gray-100">{orders.rows.map(order => <li key={order.id} className={`${styles.row} py-2 text-sm`}><span><Check className="mr-2 inline text-emerald-700" size={15} />{order.plan === "lifetime" ? "Qyube Pro lifetime" : `Qyube ${order.plan}`} · {order.paid_at.toLocaleDateString()}{order.status === "refunded" ? " · Refunded" : order.refunded_cents > 0 ? " · Partially refunded" : ""}</span><span>{new Intl.NumberFormat("en-US", { style: "currency", currency: order.currency.toUpperCase() }).format(order.total_cents / 100)}</span></li>)}</ul> : <p className={`${styles.muted} mb-4 text-sm`}>Completed purchases and receipts will appear here.</p>}
        <div className={styles.actions}><a href="/api/billing/portal" className={styles.button}><CreditCard size={15} /> Purchases & invoices</a><Link href="/" className={styles.button}><Laptop size={15} /> Download for Mac</Link></div>
      </section>
      <p className={`${styles.muted} mt-4 flex items-center gap-1 text-xs`}><Monitor size={13} /> Manage the Macs connected to your account above.</p>
      <LegalFooter />
    </div>
  </main>
}
