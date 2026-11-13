"use client"

import Image from "next/image"
import Link from "next/link"
import { useEffect, useRef, useState } from "react"
import styles from "./hero.module.css"

const letters = [
  ["01110", "11011", "11011", "01111", "00011", "00011", "00001"],
  ["11011", "11011", "01111", "00011", "00011", "01110", "11000"],
  ["00000", "00000", "11011", "11011", "11011", "11011", "01110"],
  ["11000", "11000", "11110", "11011", "11011", "11011", "11110"],
  ["00000", "00000", "01110", "11011", "11111", "11000", "01111"],
]

export default function MarketingPageClient() {
  const section = useRef<HTMLElement>(null)
  const [animated, setAnimated] = useState(false)
  const [status, setStatus] = useState<"idle" | "busy" | "success" | "error">(
    "idle"
  )
  const [message, setMessage] = useState("")
  useEffect(() => {
    const observer = new IntersectionObserver(([entry]) =>
      setAnimated(entry.isIntersecting && !document.hidden)
    )
    if (section.current) observer.observe(section.current)
    const visibility = () =>
      setAnimated(
        !document.hidden &&
          Boolean(
            section.current &&
            section.current.getBoundingClientRect().bottom > 0
          )
      )
    document.addEventListener("visibilitychange", visibility)
    return () => {
      observer.disconnect()
      document.removeEventListener("visibilitychange", visibility)
    }
  }, [])

  return (
    <section
      ref={section}
      id="top"
      className={`${styles.hero} ${animated ? styles.live : ""}`}
      aria-label="Qyube island and launch waitlist"
    >
      <div className={styles.aurora} aria-hidden="true" />
      <div className={styles.grain} aria-hidden="true" />
      <header className={styles.header}>
        <Link href="/" aria-label="Qyube home">
          qyube
        </Link>
      </header>
      <h1 className={styles.wordmark}>
        <span className={styles.srOnly}>qyube</span>
        <svg aria-hidden="true" viewBox="0 0 29 7" shapeRendering="crispEdges">
          {letters.flatMap((letter, l) =>
            letter.flatMap((row, y) =>
              [...row].map((pixel, x) =>
                pixel === "1" ? (
                  <rect
                    key={`${l}-${x}-${y}`}
                    x={l * 6 + x}
                    y={y}
                    width="1"
                    height="1"
                  />
                ) : null
              )
            )
          )}
        </svg>
      </h1>
      <div className={styles.island}>
        <Image
          src="/hero/midnight-aurora/island.webp"
          alt="A pixel ice cove with turquoise water, fish in a bucket and a seabird resting on the snowy cliffs."
          width={1536}
          height={1024}
          sizes="(max-width: 760px) 110vw, 76vw"
          priority
        />
      </div>
      <div className={styles.bottom}>
        <div className={styles.copy}>
          <h2>
            A tiny penguin island
            <br />
            on your desktop.
          </h2>
          <p>
            Stay focused. Go fishing.
            <br className={styles.mobileBreak} /> Collect your catches.
          </p>
        </div>
        <form
          className={styles.form}
          onSubmit={async (event) => {
            event.preventDefault()
            if (status === "busy") return
            const form = new FormData(event.currentTarget)
            setStatus("busy")
            setMessage("")
            try {
              const response = await fetch("/api/waitlist", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                  email: form.get("email"),
                  consent: form.get("consent") === "on",
                  website: form.get("website"),
                }),
              })
              if (!response.ok)
                throw new Error(
                  response.status === 429
                    ? "Too many attempts. Please try again later."
                    : "Could not join. Please check your email and try again."
                )
              setStatus("success")
              setMessage(
                "You’re on the list. We’ll let you know when Qyube is ready."
              )
            } catch (error) {
              setStatus("error")
              setMessage(
                error instanceof Error ? error.message : "Please try again."
              )
            }
          }}
        >
          <p className={styles.soon}>Coming soon to macOS.</p>
          <label htmlFor="waitlist-email" className={styles.srOnly}>
            Email address
          </label>
          <div className={styles.inputRow}>
            <input
              id="waitlist-email"
              type="email"
              name="email"
              autoComplete="email"
              maxLength={254}
              placeholder="Your email address"
              required
              disabled={status === "success"}
            />
            <button disabled={status === "busy" || status === "success"}>
              {status === "busy"
                ? "Joining…"
                : status === "success"
                  ? "You’re on the list ✓"
                  : "Join the waitlist"}
            </button>
          </div>
          <div className={styles.honey} aria-hidden="true">
            <label>
              Website
              <input name="website" tabIndex={-1} autoComplete="off" />
            </label>
          </div>
          <label className={styles.consent}>
            <input
              type="checkbox"
              name="consent"
              required
              disabled={status === "success"}
            />{" "}
            Email me Qyube launch updates.
          </label>
          <p className={styles.privacy}>
            Your email is used for launch updates.{" "}
            <Link href="/privacy">Privacy policy</Link>.
          </p>
          <p className={styles.message} role="status" aria-live="polite">
            {message}
          </p>
        </form>
      </div>
    </section>
  )
}
