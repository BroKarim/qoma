"use client"

import Link from "next/link"

export function MarketingNav() {
  return (
    <header className="flex items-center px-4 py-3 sm:px-8">
      <Link href="/" className="flex items-center gap-2.5">
        {/* <img
          src="/apple-icon.png"
          alt="Qoma"
          className="h-9 w-9 object-contain"
        /> */}
        <span className="text-lg font-semibold tracking-tight text-white">
          Qoma
        </span>
      </Link>
    </header>
  )
}
