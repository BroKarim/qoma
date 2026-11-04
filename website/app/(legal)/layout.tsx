import Link from "next/link"
import { LegalFooter } from "@/components/legal-footer"

export default function LegalLayout({ children }: { children: React.ReactNode }) {
  return <div className="min-h-screen bg-[#f8fbfc] text-[#203744]"><header className="mx-auto max-w-5xl px-6 py-6"><Link className="text-2xl font-bold tracking-tight" href="/">qyube</Link></header>{children}<LegalFooter /></div>
}
