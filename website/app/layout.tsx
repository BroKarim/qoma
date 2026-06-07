import { Geist, Geist_Mono } from "next/font/google"
import type { Metadata } from "next"
import "./globals.css"
import { ThemeProvider } from "@/components/theme-provider"
import { cn } from "@/lib/utils"
import { syne } from "@/lib/fonts"

const geist = Geist({ subsets: ["latin"], variable: "--font-geist-sans" })

const fontMono = Geist_Mono({
  subsets: ["latin"],
  variable: "--font-geist-mono",
})

export const metadata: Metadata = {
  title: "Dzenn - Not your ordinary linktree",
  description:
    "A nonchalant link-in-bio that hits different. No cap, just vibes. Your main character era starts here – slay your links, bestie. 💅✨",
  openGraph: {
    title: "Dzenn - Not your ordinary linktree",
    description:
      "A nonchalant link-in-bio that hits different. No cap, just vibes. Your main character era starts here – slay your links, bestie. 💅✨",
    siteName: "Dzenn",
    images: [
      {
        url: "/og.png",
        width: 1200,
        height: 630,
        alt: "Dzenn - Not your ordinary linktree",
      },
    ],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Dzenn - Not your ordinary linktree",
    description:
      "A nonchalant link-in-bio that hits different. No cap, just vibes. Your main character era starts here – slay your links, bestie.",
    images: ["/og.png"],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html
      lang="en"
      suppressHydrationWarning
      className={cn(
        "antialiased",
        fontMono.variable,
        "font-sans",
        geist.variable,
        syne.variable
      )}
    >
      <body>
        <ThemeProvider>{children}</ThemeProvider>
      </body>
    </html>
  )
}
