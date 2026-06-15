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
  title: "Qoma - A minimalist floating timer with analytics",
  metadataBase: new URL("https://qoma.app"),
  description:
    "Qoma is a floating Pomodoro timer designed specifically for macOS that focuses entirely on simplicity and clean analytics.",
  openGraph: {
    title: "Qoma - A minimalist floating timer with analytics",
    description:
      "Qoma is a floating Pomodoro timer designed specifically for macOS that focuses entirely on simplicity and clean analytics.",
    siteName: "Qoma",
    images: [
      {
        url: "/og.png",
        width: 1200,
        height: 630,
        alt: "Qoma - A minimalist floating timer with analytics",
      },
    ],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Qoma - A minimalist floating timer with analytics",
    description:
      "Qoma is a floating Pomodoro timer designed specifically for macOS that focuses entirely on simplicity and clean analytics.",
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
