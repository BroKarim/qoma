export const metadata = { title: "Refunds · Qyube", description: "Draft refund information for Qyube purchases." }

export default function RefundPage() {
  return <main className="mx-auto max-w-3xl px-6 pb-20">
    <h1 className="mb-2 text-4xl font-semibold">Refunds</h1><p className="mb-8 text-sm text-gray-600">Draft · last updated November 3, 2026</p>
    <div className="mb-8 rounded-xl border border-amber-300 bg-amber-50 p-4 text-sm">Owner decision required before selling: choose the voluntary refund window and conditions, and confirm how local consumer law applies. Do not publish this page as final until completed.</div>
    <div className="space-y-7 text-[15px] leading-7">
      <section><h2 className="mb-2 text-xl font-semibold">Requesting a refund</h2><p>Qyube Pro is a one-time USD $11 purchase processed by Polar. To request help with a charge or ask for a refund, contact <strong>[TODO: support email]</strong> with the purchase email and order receipt. Do not send card details by email.</p></section>
      <section><h2 className="mb-2 text-xl font-semibold">Draft voluntary policy</h2><p><strong>[TODO: set refund window, eligibility, and any exclusions.]</strong> Applicable statutory consumer rights are not limited by any voluntary policy. Polar may return funds to the original payment method and timing depends on the payment provider.</p></section>
      <section><h2 className="mb-2 text-xl font-semibold">What happens to access</h2><p>When a full refund is confirmed, Qyube may revoke the paid entitlement associated with that order. A refund does not delete locally stored focus sessions. Partial refunds and their effect on access must be confirmed with support.</p></section>
    </div>
  </main>
}
