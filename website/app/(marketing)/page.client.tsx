"use client"

import { useRef, useState, useEffect, type ReactNode } from "react"
import Image from "next/image"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion"

import Link from "next/link"
import { useTimer } from "@/lib/use-timer"
import { MenuBar } from "@/components/menu-bar"
import { FloatingTimer } from "@/components/floating-timer"
import MacOSDock from "@/components/macos-dock"
import { DownloadSection } from "@/components/download-section"

const DOCK_APPS = [
  {
    id: "finder",
    name: "Finder",
    icon: "https://cdn.jim-nielsen.com/macos/1024/finder-2021-09-10.png?rf=1024",
  },
  {
    id: "calculator",
    name: "Calculator",
    icon: "https://cdn.jim-nielsen.com/macos/1024/calculator-2021-04-29.png?rf=1024",
  },
  {
    id: "qoma",
    name: "Qoma",
    icon: "/icon1.png",
    iconScale: 0.8,
  },
  {
    id: "terminal",
    name: "Terminal",
    icon: "https://cdn.jim-nielsen.com/macos/1024/terminal-2021-06-03.png?rf=1024",
  },
  {
    id: "mail",
    name: "Mail",
    icon: "https://cdn.jim-nielsen.com/macos/1024/mail-2021-05-25.png?rf=1024",
  },
  {
    id: "notes",
    name: "Notes",
    icon: "https://cdn.jim-nielsen.com/macos/1024/notes-2021-05-25.png?rf=1024",
  },
  {
    id: "safari",
    name: "Safari",
    icon: "https://cdn.jim-nielsen.com/macos/1024/safari-2021-06-02.png?rf=1024",
  },
  {
    id: "music",
    name: "Music",
    icon: "https://cdn.jim-nielsen.com/macos/1024/music-2021-05-25.png?rf=1024",
  },
  {
    id: "calendar",
    name: "Calendar",
    icon: "https://cdn.jim-nielsen.com/macos/1024/calendar-2021-04-29.png?rf=1024",
  },
]

const HIGHLIGHT_FEATURES = [
  {
    title: "Always on Top",
    desc: "A compact floating timer that stays visible over any app. Never lose track of your focus again.",
  },
  {
    title: "Focus Analytics",
    desc: "Heatmap, daily breakdowns, top apps and websites used during sessions. Know exactly where your time goes.",
  },
  {
    title: "Embarrassingly Free",
    desc: "We felt weird charging for this. Instead, just give us feedback so we can make it better. That's the deal.",
  },
] as const

const FAQ_ITEMS = [
  {
    question: "What is Qoma?",
    answer:
      "Qoma is a minimal floating pomodoro timer for macOS. It stays on top of your windows so you can see your countdown without switching apps.",
  },
  {
    question: "Is Qoma really free?",
    answer:
      "Yes. Every feature is free. No accounts, no subscriptions.",
  },
  {
    question: "How do I install it?",
    answer:
      "Download the DMG from our releases page, drag it to Applications, and run one terminal command to bypass the macOS quarantine. Or use Homebrew.",
  },
  {
    question: "What makes Qoma different from other Pomodoro timers?",
    answer:
      "Qoma floats above all windows so your timer never disappears behind other apps. Plus it tracks what apps and websites you use during focus sessions, giving you an analytics dashboard with heatmaps and breakdowns so you know exactly how productive you were.",
  },
  {
    question: "Is my data collected?",
    answer:
      "No. Qoma runs entirely on your machine. No telemetry, no analytics servers, no accounts. Your focus data stays with you.",
  },
] as const

function useInView(options?: IntersectionObserverInit) {
  const ref = useRef<HTMLDivElement>(null)
  const [isInView, setIsInView] = useState(false)
  const optionsRef = useRef(options)

  useEffect(() => {
    optionsRef.current = options
    const el = ref.current
    if (!el) return

    const observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting) {
        setIsInView(true)
        observer.disconnect()
      }
    }, optionsRef.current)

    observer.observe(el)
    return () => observer.disconnect()
  }, [options])

  return { ref, isInView }
}

function AnimatedSection({
  children,
  className = "",
  threshold = 0.1,
}: {
  children: ReactNode
  className?: string
  threshold?: number
}) {
  const { ref, isInView } = useInView({ threshold })

  return (
    <div
      ref={ref}
      className={`transition-all duration-700 ease-out ${
        isInView ? "translate-y-0 opacity-100" : "translate-y-8 opacity-0"
      } ${className}`}
    >
      {children}
    </div>
  )
}

const shadowClass = "shadow-qoma"

export default function MarketingPageClient() {
  const timer = useTimer()
  const previewRef = useRef<HTMLDivElement>(null)

  return (
    <main className="flex flex-1 flex-col items-center font-sans">
      {/* Hero */}
      <AnimatedSection className="w-full">
        <section className="flex flex-col items-center px-4 pt-10 pb-6 text-center sm:pt-16 sm:pb-8">
          <Badge
            className="mb-4 rounded-full border border-white/15 bg-white/5 px-4 py-1 text-[10px] font-medium text-white/80 backdrop-blur-sm hover:bg-white/10 sm:mb-2"
            style={{
              boxShadow:
                "0 2px 8px rgba(0, 0, 0, 0.3), inset 0 1px 0 rgba(255, 255, 255, 0.1)",
            }}
          >
            Open Source & Free
          </Badge>

          <h1 className="mb-2 max-w-2xl font-sans text-3xl leading-tight font-normal text-white sm:text-5xl md:text-5xl">
            Focus, floating.
          </h1>

          <p className="mb-8 max-w-sm text-sm leading-relaxed text-gray-400 sm:mb-10 sm:max-w-md md:text-base">
            A minimal pomodoro timer that stays on top of your windows.
            <br className="hidden sm:block" />
            Open source, free, built for macOS.
          </p>

          <div className="mb-4 flex items-center gap-3">
            <Button
              onClick={() => {
                document
                  .getElementById("download-section")
                  ?.scrollIntoView({ behavior: "smooth" })
              }}
              className="shadow-qoma shrink-0 gap-2 border-none bg-[#222] px-6 py-2.5 text-sm text-white shadow-none transition-all hover:scale-105 hover:bg-[#222] active:scale-95"
            >
              Download for macOS
            </Button>
          </div>

          <p className="text-[10px] text-gray-400 md:text-sm">
            No account needed · Runs locally
          </p>
        </section>
      </AnimatedSection>

      {/* App Preview */}
      <AnimatedSection className="w-full" threshold={0.05}>
        <section className="mx-auto w-full max-w-4xl">
          <div className="animate-fade-in overflow-hidden px-3 pb-6 sm:px-8 sm:pb-8">
            <div
              ref={previewRef}
              className="relative aspect-[16/9] overflow-hidden rounded-xl shadow-popover sm:rounded-lg"
            >
              <MenuBar timer={timer} />
              {timer.isActive && (
                <FloatingTimer
                  remainingSeconds={timer.remainingSeconds}
                  containerRef={previewRef}
                />
              )}
              <div className="absolute bottom-4 left-1/2 z-10 -translate-x-1/2">
                <MacOSDock
                  apps={DOCK_APPS}
                  onAppClick={() => {}}
                  openApps={["qoma"]}
                />
              </div>
              <div className="absolute inset-0 rounded-[inherit]">
                <Image
                  fill
                  decoding="auto"
                  src="https://framerusercontent.com/images/MR7CyE9DaBgMhReh9Z6oUd4Iec.jpg?width=3840&height=2160"
                  alt="macOS Desktop Preview"
                  className="block h-full w-full rounded-[inherit] object-cover object-center"
                />
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 border-y border-primary/20 md:grid-cols-3">
            {HIGHLIGHT_FEATURES.map((feature, i) => (
              <div
                key={feature.title}
                className={`p-6 sm:p-8 ${i < 2 ? "border-b border-primary/20 md:border-r md:border-b-0" : ""}`}
              >
                <h3 className="mb-2 text-sm font-semibold text-white">
                  {feature.title}
                </h3>
                <p className="text-sm leading-relaxed text-gray-400">
                  {feature.desc}
                </p>
              </div>
            ))}
          </div>
        </section>
      </AnimatedSection>

      {/* Download */}
      <AnimatedSection className="w-full" threshold={0.05}>
        <DownloadSection />
      </AnimatedSection>

      {/* FAQ */}
      <AnimatedSection className="w-full" threshold={0.1}>
        <section className="mx-auto w-full max-w-4xl">
          <div className="px-4 py-12 sm:px-8">
            <span className="text-[10px] font-bold tracking-[0.2em] text-gray-400 uppercase">
              FAQ
            </span>
            <h2 className="mt-2 mb-8 text-2xl font-medium tracking-tight text-white md:text-3xl">
              Questions? Answers.
            </h2>

            <Accordion type="single" collapsible className="w-full">
              {FAQ_ITEMS.map((item, idx) => (
                <AccordionItem
                  key={idx}
                  value={`item-${idx}`}
                  className="border-primary/20"
                >
                  <AccordionTrigger className="text-left text-white hover:text-gray-200 hover:no-underline">
                    {item.question}
                  </AccordionTrigger>
                  <AccordionContent className="text-gray-400">
                    {item.answer}
                  </AccordionContent>
                </AccordionItem>
              ))}
            </Accordion>
          </div>
        </section>
      </AnimatedSection>

      {/* CTA */}
      <AnimatedSection className="w-full" threshold={0.1}>
        <section className="w-full">
          <div className="mx-auto flex max-w-7xl flex-col items-center px-4 py-12 sm:px-6 sm:py-16">
            <h2 className="mb-2 max-w-2xl font-sans text-3xl leading-tight font-normal text-white sm:text-5xl md:text-5xl">
              Start focusing.
            </h2>
            <Button
              onClick={() => {
                document
                  .getElementById("download-section")
                  ?.scrollIntoView({ behavior: "smooth" })
              }}
              className="shadow-qoma shrink-0 gap-2 border-none bg-[#222] px-6 py-2.5 text-sm text-white shadow-none transition-all hover:scale-105 hover:bg-[#222] active:scale-95"
            >
              Get Qoma
            </Button>
          </div>
        </section>
      </AnimatedSection>
    </main>
  )
}
