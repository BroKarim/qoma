"use client"

import Image from "next/image"
import Link from "next/link"
import { useEffect, useRef, useState } from "react"
import { Download, Pause, Play, RotateCcw } from "lucide-react"

const DURATIONS = [10, 25, 45, 60]

type SessionState = "setup" | "running" | "paused" | "complete"

function formatTime(seconds: number) {
  const minutes = Math.floor(seconds / 60)
  const remainder = seconds % 60
  return `${String(minutes).padStart(2, "0")}:${String(remainder).padStart(2, "0")}`
}

export default function MarketingPageClient() {
  const [sessionState, setSessionState] = useState<SessionState>("setup")
  const [duration, setDuration] = useState(25)
  const [remaining, setRemaining] = useState(25 * 60)
  const [task, setTask] = useState("")
  const deadline = useRef(0)

  useEffect(() => {
    if (sessionState !== "running") return

    const interval = window.setInterval(() => {
      const seconds = Math.max(0, Math.ceil((deadline.current - Date.now()) / 1000))
      setRemaining(seconds)
      if (seconds === 0) setSessionState("complete")
    }, 1000)

    return () => window.clearInterval(interval)
  }, [sessionState])

  function startSession() {
    const seconds = duration * 60
    setRemaining(seconds)
    deadline.current = Date.now() + seconds * 1000
    setSessionState("running")
  }

  function pauseSession() {
    setRemaining(Math.max(0, Math.ceil((deadline.current - Date.now()) / 1000)))
    setSessionState("paused")
  }

  function resumeSession() {
    deadline.current = Date.now() + remaining * 1000
    setSessionState("running")
  }

  function resetSession() {
    setRemaining(duration * 60)
    setSessionState("setup")
  }

  const isSetup = sessionState === "setup"

  return (
    <section id="top" className="relative isolate min-h-svh overflow-hidden bg-white font-sans text-[#202020]" aria-label="qyube focus demo">
        <Image
          src="/hero/antarctic-background.webp"
          alt=""
          fill
          priority
          sizes="100vw"
          className="pointer-events-none -z-20 object-cover object-center"
        />

        <header className="absolute inset-x-0 top-0 z-30 mx-auto flex h-[76px] max-w-[1440px] items-center justify-between px-5 sm:px-9 lg:px-14">
          <Link href="/" aria-label="qyube home" className="text-[25px] font-semibold tracking-[-0.07em]">
            qyube
          </Link>
          <a
            href="https://github.com/BroKarim/qoma/releases/latest"
            className="inline-flex h-10 items-center gap-2 rounded-full bg-[#202020] px-5 text-[13px] font-medium text-white transition-colors hover:bg-[#3a3a3a] focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-[#202020]"
          >
            <Download size={14} aria-hidden="true" />
            Download for Mac
          </a>
        </header>

        <div className="pointer-events-none absolute inset-0 z-0 overflow-hidden" aria-hidden="true">
          <Image
            src="/hero/water-wash.webp"
            alt=""
            width={2172}
            height={724}
            sizes="100vw"
            className="absolute -bottom-[3%] left-1/2 w-[125%] max-w-none -translate-x-1/2 opacity-75 sm:w-[105%] xl:w-[105%]"
          />
          <Image
            src="/hero/ice-floe.webp"
            alt=""
            width={2172}
            height={724}
            sizes="(max-width: 768px) 125vw, 88vw"
            className="absolute bottom-[5%] left-1/2 w-[125%] max-w-none -translate-x-1/2 sm:w-[100%] xl:w-[90%] xl:max-w-[1180px]"
          />
          <Image
            src="/hero/bucket-empty.webp"
            alt=""
            width={1254}
            height={1254}
            sizes="(max-width: 768px) 22vw, 11vw"
            className="absolute bottom-[19%] left-[43%] w-[15%] max-w-[100px] object-contain sm:bottom-[18%] sm:left-[30%] sm:w-[14%] xl:left-[29%] xl:w-[11%]"
          />
          <Image
            src={sessionState === "paused" ? "/hero/penguin-sleeping.webp" : "/hero/penguin-fishing-integrated.webp"}
            alt={sessionState === "paused" ? "Penguin wearing red and cyan 3D glasses, resting" : "Penguin wearing red and cyan 3D glasses, holding a fishing rod"}
            width={sessionState === "paused" ? 1254 : 1335}
            height={sessionState === "paused" ? 1254 : 1178}
            priority
            sizes="(max-width: 640px) 46vw, (max-width: 1024px) 34vw, 300px"
            className="absolute bottom-[19%] left-[2%] w-[46%] max-w-[260px] object-contain sm:bottom-[19%] sm:left-[4%] sm:w-[38%] xl:bottom-[22%] xl:left-1/2 xl:w-[300px] xl:max-w-[300px] xl:-translate-x-1/2"
          />
        </div>

        <div className="pointer-events-none absolute inset-x-0 top-[104px] z-10 flex justify-center px-5 text-center sm:top-[104px]">
          {!isSetup && (
            <div className="pointer-events-auto">
              <p className="mb-1 text-[11px] tracking-[0.12em] text-[#555] uppercase">
                {sessionState === "complete" ? "Session complete" : task.trim() || "Time to focus"}
              </p>
              <time
                className="block font-light text-[60px] leading-none tracking-[-0.065em] tabular-nums sm:text-[88px] lg:text-[104px]"
                aria-label={`${Math.floor(remaining / 60)} minutes and ${remaining % 60} seconds remaining`}
              >
                {formatTime(remaining)}
              </time>
              <div className="mt-5 flex items-center justify-center gap-3">
                {sessionState === "running" ? (
                  <button
                    type="button"
                    onClick={pauseSession}
                    className="inline-flex h-11 items-center gap-2 rounded-full border border-[#252525] bg-white/70 px-6 text-sm font-medium backdrop-blur-sm transition-colors hover:bg-white focus-visible:outline-2 focus-visible:outline-offset-3 focus-visible:outline-[#202020]"
                  >
                    <Pause size={15} aria-hidden="true" />
                    Pause
                  </button>
                ) : sessionState === "paused" ? (
                  <button
                    type="button"
                    onClick={resumeSession}
                    className="inline-flex h-11 items-center gap-2 rounded-full border border-[#252525] bg-white/70 px-6 text-sm font-medium backdrop-blur-sm transition-colors hover:bg-white focus-visible:outline-2 focus-visible:outline-offset-3 focus-visible:outline-[#202020]"
                  >
                    <Play size={15} aria-hidden="true" />
                    Resume
                  </button>
                ) : null}
                <button
                  type="button"
                  onClick={resetSession}
                  className="inline-flex h-11 items-center gap-2 rounded-full px-5 text-sm text-[#444] transition-colors hover:bg-white/65 focus-visible:outline-2 focus-visible:outline-offset-3 focus-visible:outline-[#202020]"
                >
                  <RotateCcw size={14} aria-hidden="true" />
                  Reset
                </button>
              </div>
            </div>
          )}
        </div>

        {isSetup && (
          <form
            onSubmit={(event) => {
              event.preventDefault()
              startSession()
            }}
            className="absolute top-[84px] right-4 z-20 w-[min(350px,calc(100%-2rem))] rounded-[18px] border border-black/10 bg-white/90 p-5 shadow-[0_16px_48px_rgba(32,32,32,0.12)] backdrop-blur-md sm:w-[min(300px,calc(100%-2rem))] xl:top-[25%] xl:right-[6%] xl:w-[350px] xl:p-6"
          >
            <h1 className="mb-5 text-[20px] font-semibold tracking-[-0.035em]">
              New session
            </h1>
            <label htmlFor="focus-task" className="mb-2 block text-[13px] text-[#656565]">
              What are you working on?
            </label>
            <input
              id="focus-task"
              value={task}
              onChange={(event) => setTask(event.target.value)}
              maxLength={80}
              placeholder="A little time to focus"
              className="mb-5 h-11 w-full rounded-[10px] border border-[#dedede] bg-white px-3 text-sm outline-none transition focus:border-[#777] focus:ring-2 focus:ring-black/5"
            />
            <label htmlFor="focus-duration" className="mb-2 block text-[13px] text-[#656565]">
              Duration
            </label>
            <select
              id="focus-duration"
              value={duration}
              onChange={(event) => setDuration(Number(event.target.value))}
              className="mb-5 h-11 w-full rounded-[10px] border border-[#dedede] bg-white px-3 text-sm outline-none transition focus:border-[#777] focus:ring-2 focus:ring-black/5"
            >
              {DURATIONS.map((minutes) => (
                <option key={minutes} value={minutes}>
                  {minutes} minutes
                </option>
              ))}
            </select>
            <button
              type="submit"
              className="inline-flex h-12 w-full items-center justify-center gap-2 rounded-[10px] bg-[#202020] px-4 text-sm font-medium text-white transition-colors hover:bg-[#3a3a3a] focus-visible:outline-2 focus-visible:outline-offset-3 focus-visible:outline-[#202020]"
            >
              <Play size={15} fill="currentColor" aria-hidden="true" />
              Start session
            </button>
          </form>
        )}

    </section>
  )
}
