import Link from "next/link"

export function LegalFooter() {
  return <footer className="mx-auto flex max-w-5xl justify-center flex-wrap gap-x-6 gap-y-2 border-t border-gray-200 px-6 py-5 text-sm text-gray-600">
    <Link href="/privacy">Privacy</Link><Link href="/terms">Terms</Link><Link href="/refund">Refunds</Link><Link href="/support">Support</Link>
  </footer>
}
