"use client"

import { useState, useEffect, useRef, useCallback } from "react"
import { MoreHorizontal } from "lucide-react"
import { Button } from "@/components/ui/button"

const MIN_MINUTES = 1
const MAX_MINUTES = 60
const PRESETS = [5, 10, 25]

function formatTime(totalSeconds: number) {
  const m = Math.floor(totalSeconds / 60)
  const s = totalSeconds % 60
  return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`
}

function RulerPicker({
  value,
  onChange,
}: {
  value: number
  onChange: (v: number) => void
}) {
  const trackRef = useRef<HTMLDivElement>(null)
  const totalRange = MAX_MINUTES - MIN_MINUTES

  const handleInteraction = useCallback(
    (clientX: number) => {
      if (!trackRef.current) return
      const rect = trackRef.current.getBoundingClientRect()
      const percent = Math.max(0, Math.min(1, (clientX - rect.left) / rect.width))
      const newValue = Math.round(MIN_MINUTES + percent * totalRange)
      onChange(newValue)
    },
    [onChange, totalRange]
  )

  const handlePointerDown = (e: React.PointerEvent) => {
    handleInteraction(e.clientX)
    const onMove = (ev: PointerEvent) => handleInteraction(ev.clientX)
    const onUp = () => {
      window.removeEventListener("pointermove", onMove)
      window.removeEventListener("pointerup", onUp)
    }
    window.addEventListener("pointermove", onMove)
    window.addEventListener("pointerup", onUp)
  }

  const ticks = Array.from({ length: totalRange + 1 }, (_, i) => i + MIN_MINUTES)

  return (
    <div
      ref={trackRef}
      className="relative h-[30px] cursor-pointer select-none"
      onPointerDown={handlePointerDown}
    >
      <div className="flex h-full items-end justify-between px-[1px]">
        {ticks.map((tick) => (
          <div
            key={tick}
            className={`w-[1px] ${tick % 5 === 0 ? "h-5 bg-white/50" : "h-2.5 bg-white/20"}`}
          />
        ))}
      </div>
      <div
        className="absolute top-1/2 h-7 w-0.5 -translate-y-1/2 rounded-full bg-white shadow-[0_0_4px_rgba(255,255,255,0.5)]"
        style={{
          left: `${((value - MIN_MINUTES) / totalRange) * 100}%`,
        }}
      />
    </div>
  )
}

interface MenuBarPopupProps {
  minutes: number
  setMinutes: (v: number) => void
  isActive: boolean
  isPaused: boolean
  remainingSeconds: number
  start: () => void
  cancel: () => void
  handlePrimaryAction: () => void
  primaryButtonTitle: string
}

export function MenuBarPopup({
  minutes,
  setMinutes,
  isActive,
  remainingSeconds,
  start,
  cancel,
  handlePrimaryAction,
  primaryButtonTitle,
}: MenuBarPopupProps) {
  const [showSettings, setShowSettings] = useState(false)
  const settingsRef = useRef<HTMLDivElement>(null)

  // Close settings when clicking outside of it (but inside popup is fine)
  useEffect(() => {
    if (!showSettings) return
    const handleClick = (e: MouseEvent) => {
      if (!settingsRef.current?.contains(e.target as Node)) {
        setShowSettings(false)
      }
    }
    document.addEventListener("click", handleClick)
    return () => document.removeEventListener("click", handleClick)
  }, [showSettings])

  return (
    <div className="w-full">
      {/* Ruler Picker */}
      <div className="px-2.5 pt-3 pb-1">
        <RulerPicker value={minutes} onChange={setMinutes} />
      </div>

      {/* Presets or Cancel/Restart */}
      <div className="flex items-center gap-2 px-4 h-8">
        {isActive ? (
          <>
            <Button
              variant="ghost"
              size="sm"
              onClick={cancel}
              className="h-auto px-0 py-0 text-[13px] font-normal text-white/50 hover:text-white/80 hover:bg-transparent"
            >
              cancel
            </Button>
            <Button
              variant="ghost"
              size="sm"
              onClick={start}
              className="h-auto px-0 py-0 text-[13px] font-normal text-white/90 hover:text-white hover:bg-transparent"
            >
              restart
            </Button>
            {remainingSeconds > 0 && (
              <span className="ml-auto text-[13px] tabular-nums text-white/90">
                {formatTime(remainingSeconds)}
              </span>
            )}
          </>
        ) : (
          PRESETS.map((preset) => (
            <Button
              key={preset}
              variant="ghost"
              size="sm"
              onClick={() => setMinutes(preset)}
              className={`h-auto min-w-[30px] px-0 py-0 text-[13px] font-normal hover:bg-transparent ${
                minutes === preset ? "text-white" : "text-white/50 hover:text-white/80"
              }`}
            >
              {preset}m
            </Button>
          ))
        )}
      </div>

      {/* Bottom row */}
      <div className="flex items-center justify-between px-4 pb-3 pt-2">
        <Button
          variant="ghost"
          size="sm"
          onClick={handlePrimaryAction}
          className="h-auto px-0 py-0 text-[13px] font-normal text-white/90 hover:text-white hover:bg-transparent"
        >
          {primaryButtonTitle}
        </Button>

        <div className="relative" ref={settingsRef}>
          <Button
            variant="ghost"
            size="icon-sm"
            onClick={() => setShowSettings((s) => !s)}
            className="h-auto w-auto p-0 text-white/50 hover:text-white/80 hover:bg-transparent"
          >
            <MoreHorizontal size={16} />
          </Button>

          {showSettings && (
            <div
              className="absolute right-0 top-full mt-1 w-36 overflow-hidden rounded-lg bg-black/50 py-1 text-[13px] text-white/90 z-50"
              style={{
                backdropFilter: "blur(20px)",
                WebkitBackdropFilter: "blur(20px)",
              }}
            >
               <button
                type="button"
                onClick={() => {
                  setShowSettings(false)
                  alert("Settings — (demo)")
                }}
                className="block w-full px-3 py-1.5 text-left hover:bg-white/10 transition-colors"
              >
                Settings...
              </button>
              <button
                type="button"
                onClick={() => {
                  setShowSettings(false)
                  alert("Contact Us — (demo)")
                }}
                className="block w-full px-3 py-1.5 text-left hover:bg-white/10 transition-colors"
              >
                Contact Us
              </button>
              <div className="my-1 h-px bg-white/10" />
              <button
                onClick={() => {
                  setShowSettings(false)
                  alert("Quit — (demo)")
                }}
                className="block w-full px-3 py-1.5 text-left hover:bg-white/10 transition-colors"
              >
                Quit
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
