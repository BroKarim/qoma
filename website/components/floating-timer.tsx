"use client"

import { useState, useRef, useCallback, useEffect } from "react"

interface FloatingTimerProps {
  remainingSeconds: number
  containerRef: React.RefObject<HTMLDivElement | null>
}

function formatTime(totalSeconds: number) {
  const m = Math.floor(totalSeconds / 60)
  const s = totalSeconds % 60
  return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`
}

const TIMER_W = 86
const TIMER_H = 48
const FONT_SIZE = 22
const MENU_BAR_H = 28

export function FloatingTimer({ remainingSeconds, containerRef }: FloatingTimerProps) {
  const [pos, setPos] = useState({ x: 50, y: 55 })
  const isDragging = useRef(false)
  const offset = useRef({ x: 0, y: 0 })

  const clamp = useCallback(
    (clientX: number, clientY: number) => {
      if (!containerRef.current) return
      const rect = containerRef.current.getBoundingClientRect()
      const x = ((clientX - rect.left - offset.current.x) / rect.width) * 100
      const y = ((clientY - rect.top - offset.current.y) / rect.height) * 100
      const minX = 0
      const maxX = 100 - (TIMER_W / rect.width) * 100
      const minY = (MENU_BAR_H / rect.height) * 100
      const maxY = 100 - (TIMER_H / rect.height) * 100
      setPos({
        x: Math.max(minX, Math.min(maxX, x)),
        y: Math.max(minY, Math.min(maxY, y)),
      })
    },
    [containerRef]
  )

  const onPointerDown = useCallback(
    (e: React.PointerEvent) => {
      isDragging.current = true
      const rect = (e.currentTarget as HTMLElement).getBoundingClientRect()
      offset.current = { x: e.clientX - rect.left, y: e.clientY - rect.top }
      ;(e.currentTarget as HTMLElement).setPointerCapture(e.pointerId)
    },
    []
  )

  const onPointerMove = useCallback(
    (e: React.PointerEvent) => {
      if (!isDragging.current) return
      clamp(e.clientX, e.clientY)
    },
    [clamp]
  )

  const onPointerUp = useCallback(() => {
    isDragging.current = false
  }, [])

  useEffect(() => {
    return () => {
      isDragging.current = false
    }
  }, [])

  return (
    <div
      className="absolute z-10 cursor-grab active:cursor-grabbing select-none"
      style={{
        left: `${pos.x}%`,
        top: `${pos.y}%`,
        transform: "translate(-50%, -50%)",
        width: TIMER_W,
        height: TIMER_H,
      }}
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={onPointerUp}
    >
      <div
        className="flex h-full w-full items-center justify-center overflow-hidden rounded-[14px] shadow-qoma"
        style={{
          backgroundColor: "rgba(0, 0, 0, 0.85)",
        }}
      >
        {/* Subtle top highlight gradient */}
        <div
          className="pointer-events-none absolute inset-0 rounded-[14px]"
          style={{
            background:
              "linear-gradient(to bottom, rgba(255,255,255,0.08) 0%, transparent 15%)",
          }}
        />

        {/* Border overlay */}
        <div
          className="pointer-events-none absolute inset-0 rounded-[14px]"
          style={{
            boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.1)",
          }}
        />

        <span
          className="relative z-10 font-medium leading-none tracking-tight text-white tabular-nums"
          style={{
            fontSize: FONT_SIZE,
            fontFamily:
              '"SF Mono", "Roboto Mono", "Fira Code", "Courier New", monospace',
          }}
        >
          {formatTime(remainingSeconds)}
        </span>
      </div>
    </div>
  )
}
