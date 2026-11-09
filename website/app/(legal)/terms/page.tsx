export const metadata = { title: "Terms · Qyube", description: "Terms for the Qyube macOS app and account." }

export default function TermsPage() {
  return <main className="mx-auto max-w-3xl px-6 pb-20">
    <h1 className="mb-2 text-4xl font-semibold">Terms of use</h1><p className="mb-8 text-sm text-gray-600">Draft · last updated November 3, 2026</p>
    <div className="mb-8 rounded-xl border border-amber-300 bg-amber-50 p-4 text-sm">Owner review required before launch: confirm legal seller, refund policy, how long lifetime purchases receive updates, liability terms, and governing jurisdiction.</div>
    <div className="space-y-7 text-[15px] leading-7">
      <section><h2 className="mb-2 text-xl font-semibold">The service</h2><p>Qyube is a focus application for macOS. You need a Qyube account to activate the app and manage connected Macs. Keep your account secure and use the app lawfully.</p></section>
      <section><h2 className="mb-2 text-xl font-semibold">Trial and purchase</h2><p>A seven-day trial begins when you first sign in to Qyube from a Mac and activate that installation. No payment card is required and the trial does not automatically convert to a paid purchase. After the trial, Qyube Pro is offered as a one-time USD $11 purchase through Polar. Taxes and the final amount are shown at checkout.</p></section>
      <section><h2 className="mb-2 text-xl font-semibold">Access and devices</h2><p>A Qyube Pro purchase grants lifetime access to the macOS version of Qyube for the purchasing account, subject to these terms. Up to two Macs can be active at once. Manage or remove Macs through your account page. A refund may revoke the associated paid access.</p></section>
      <section><h2 className="mb-2 text-xl font-semibold">Updates and availability</h2><p>Qyube may provide fixes and updates. The period during which feature updates are included with a lifetime purchase is <strong>[TODO: owner to define update policy and duration]</strong>. Service availability, compatibility, and future features may change.</p></section>
      <section><h2 className="mb-2 text-xl font-semibold">Seller and legal terms</h2><p>Seller: <strong>[TODO: legal business/person name and address]</strong>. Governing law and dispute venue: <strong>[TODO: owner to confirm jurisdiction]</strong>. Contact: <strong>[TODO: support email]</strong>.</p></section>
    </div>
  </main>
}
