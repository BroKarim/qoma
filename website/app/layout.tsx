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
  title: "Qyube — Focus with intention",
  metadataBase: new URL("https://qyube.brokarim.com"),
  description: "A calm focus timer for macOS, with thoughtful sessions and a little Antarctic companion.",
  openGraph: {
    title: "Qyube — Focus with intention",
    description: "A calm focus timer for macOS, with thoughtful sessions and a little Antarctic companion.",
    siteName: "Qyube",
    images: [
      {
        url: "/og.png",
        width: 1200,
        height: 630,
        alt: "Qyube — Focus with intention",
      },
    ],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Qyube — Focus with intention",
    description: "A calm focus timer for macOS, with thoughtful sessions and a little Antarctic companion.",
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
      <head>
        <style>{`@font-face { font-family: "Qyube Geist Pixel"; src: url("/fonts/geist-pixel-latin.woff2") format("woff2"); font-display: swap; } @font-face { font-family: "Qyube Geist Pixel"; src: url("/fonts/geist-pixel-latin-ext.woff2") format("woff2"); font-display: swap; unicode-range: U+0100-02BA, U+02BD-02FF, U+0304, U+0308, U+0329, U+1D00-1EFF, U+2020, U+20A0-20AB, U+20AD-20C4, U+2113, U+2C60-2C7F, U+A720-A7FF; } body, p, li, a, button, input, select, textarea { font-family: Arial, sans-serif; } h1, h2, h3, h4 { font-family: "Qyube Geist Pixel", monospace; }`}</style>
      </head>
      <body>
        <ThemeProvider>{children}</ThemeProvider>
      </body>
    </html>
  )
}
