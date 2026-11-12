export const metadata = { title: "Privacy · Qyube", description: "How Qyube handles account, device, and purchase information." }

export default function PrivacyPage() {
  return <main className="mx-auto max-w-3xl px-6 pb-20">
    <h1 className="mb-2 text-4xl font-semibold">Privacy</h1><p className="mb-8 text-sm text-gray-600">Draft · last updated November 12, 2026</p>
    <div className="mb-8 rounded-xl border border-amber-300 bg-amber-50 p-4 text-sm">Owner review required: confirm the legal entity, contact email, retention periods, and governing jurisdiction before launch.</div>
    <div className="space-y-7 text-[15px] leading-7">
      <section><h2 className="mb-2 text-xl font-semibold">Information Qyube uses</h2><p>When you sign in with Google or Apple, Qyube receives account details the provider shares, such as your email address and provider account identifier. Qyube stores your account, sign-in session, connected Mac names, installation identifiers, and access status so it can secure sign-in, enforce the two-Mac limit, and manage purchases.</p></section>
      <section><h2 className="mb-2 text-xl font-semibold">Launch waitlist</h2><p>If you join the launch waitlist, we store your email address and the time and version of your consent to receive Qyube launch updates. A hashed IP address is used to limit signup abuse; records older than one day are removed when signups are processed. To leave the list or request deletion, email <a href="mailto:brokariim@gmail.com">brokariim@gmail.com</a>. Joining does not create an account or purchase.</p></section>
      <section><h2 className="mb-2 text-xl font-semibold">Focus data</h2><p>Your focus sessions and related app data are stored locally on your Mac. Qyube does not upload session titles or focus history to its website as part of sign-in or purchase management.</p></section>
      <section><h2 className="mb-2 text-xl font-semibold">Payments and service providers</h2><p>Polar processes checkout and payment details. Qyube receives payment and order information needed to confirm or refund access; Qyube does not receive or store full card numbers. Supabase hosts account and entitlement records, and Google or Apple handles authentication under its own privacy terms.</p></section>
      <section><h2 className="mb-2 text-xl font-semibold">Retention and choices</h2><p>Account and purchase records are retained while needed to provide access, prevent fraud, support refunds, meet accounting obligations, and resolve disputes. You can remove a connected Mac from your account. To request account deletion or ask about data, contact <a href="mailto:brokariim@gmail.com">brokariim@gmail.com</a>; some transaction records may need to be retained where required by law.</p></section>
      <section><h2 className="mb-2 text-xl font-semibold">Contact and jurisdiction</h2><p>Privacy contact: <a href="mailto:brokariim@gmail.com">brokariim@gmail.com</a>. Applicable privacy law and governing jurisdiction: <strong>[TODO: owner to confirm]</strong>.</p></section>
    </div>
  </main>
}
