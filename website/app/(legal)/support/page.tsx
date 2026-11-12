export const metadata = { title: "Support · Qyube", description: "Get help with Qyube sign-in, devices, and purchases." }

export default function SupportPage() {
  return <main className="mx-auto max-w-3xl px-6 pb-20">
    <h1 className="mb-2 text-4xl font-semibold">Qyube support</h1><p className="mb-8 text-sm text-gray-600">Help with your Mac app, account, and purchases.</p>
    <div className="space-y-7 text-[15px] leading-7">
      <section><h2 className="mb-2 text-xl font-semibold">Sign-in and devices</h2><p>Use the same Google or Apple account on the website and your Mac. You can view connected Macs and remove an old installation from your account page. Removing a Mac frees a device slot; it does not restart your seven-day trial.</p></section>
      <section><h2 className="mb-2 text-xl font-semibold">Purchases</h2><p>Qyube Pro is a one-time purchase. Open your account page to see recorded purchases and invoices. Polar may take a short time to confirm an order. If your purchase is still missing after a few minutes, contact <a href="mailto:brokariim@gmail.com">brokariim@gmail.com</a> and include your order receipt.</p></section>
      <section><h2 className="mb-2 text-xl font-semibold">Contact</h2><p>Email: <a href="mailto:brokariim@gmail.com">brokariim@gmail.com</a>. Include your Qyube account email, macOS version, and a short description. Never include passwords, sign-in codes, or payment card numbers.</p></section>
    </div>
  </main>
}
