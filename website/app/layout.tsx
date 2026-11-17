import { Geist_Mono } from "next/font/google"
import type { Metadata } from "next"
import "./globals.css"
import { ThemeProvider } from "@/components/theme-provider"
import { cn } from "@/lib/utils"

const fontMono = Geist_Mono({
  subsets: ["latin"],
  variable: "--font-geist-mono",
})

export const metadata: Metadata = {
  title: "Qyube — A cozy focus timer for Mac",
  metadataBase: new URL("https://qyube.brokarim.com"),
  description: "Stay focused with a tiny penguin island on your Mac. Set a timer, go fishing, and collect discoveries as you work.",
  keywords: ["focus timer", "macOS focus app", "pomodoro timer Mac", "desktop companion", "penguin fishing"],
  openGraph: {
    title: "Qyube — A cozy focus timer for Mac",
    description: "Stay focused with a tiny penguin island on your Mac. Set a timer, go fishing, and collect discoveries as you work.",
    siteName: "Qyube",
    images: [
      {
        url: "/og.jpg",
        width: 1200,
        height: 630,
        alt: "Qyube — A cozy focus timer for Mac",
      },
    ],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Qyube — A cozy focus timer for Mac",
    description: "Stay focused with a tiny penguin island on your Mac. Set a timer, go fishing, and collect discoveries as you work.",
    images: ["/og.jpg"],
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
        "font-sans"
      )}
    >
      <body>
        <ThemeProvider>{children}</ThemeProvider>
      </body>
    </html>
  )
}
