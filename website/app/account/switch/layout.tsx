import type { Metadata } from "next"
import type { ReactNode } from "react"

export const metadata: Metadata = {
  title: "Switch account · Qyube",
  robots: { index: false, follow: false },
}

export default function SwitchAccountLayout({ children }: { children: ReactNode }) {
  return children
}
