"use client"

import { useState } from "react"
import { Copy, Check } from "lucide-react"

function CopyableCode({ code, label }: { code: string; label: string }) {
  const [copied, setCopied] = useState(false)

  const handleCopy = async () => {
    await navigator.clipboard.writeText(code)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <div className="rounded-lg bg-[#1a1a1a] p-4">
      <div className="mb-2 flex items-center justify-between">
        <span className="text-xs text-gray-400">{label}</span>
         <button
          type="button"
          onClick={handleCopy}
          className="flex items-center gap-1.5 rounded px-2 py-1 text-xs text-gray-400 transition-colors hover:bg-white/10 hover:text-gray-200"
        >
          {copied ? (
            <>
              <Check className="h-3.5 w-3.5 text-emerald-400" />
              <span className="text-emerald-400">Copied</span>
            </>
          ) : (
            <>
              <Copy className="h-3.5 w-3.5" />
              <span>Copy</span>
            </>
          )}
        </button>
      </div>
      <code className="block font-mono text-sm text-gray-100">{code}</code>
    </div>
  )
}

export function DownloadSection() {
  return (
    <section
      id="download-section"
      className="mx-auto w-full max-w-4xl border-b border-primary/20"
    >
      <div className="flex flex-col justify-center px-4 py-10 sm:px-8 sm:py-14">
        <h3 className="mb-4 text-2xl font-medium tracking-tight text-white md:text-3xl">
          Download qoma for macOS
        </h3>
        <p className="mb-8 max-w-2xl text-sm leading-relaxed text-gray-400">
          qoma is safe to use, but since we don&apos;t have an Apple Developer
          account (yet 👀), macOS will warn you that it&apos;s from an
          unidentified developer. You only need to bypass this once.
        </p>

        <div className="flex flex-col gap-4">
          <CopyableCode
            label="Install via Homebrew"
            code="brew install --cask qoma"
          />
          <CopyableCode
            label="Remove quarantine flag"
            code="xattr -dr com.apple.quarantine /Applications/qoma.app"
          />
        </div>
      </div>
    </section>
  )
}
