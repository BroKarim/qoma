import { useState, useEffect, useRef, useCallback } from "react"

export function useTimer() {
  const [minutes, setMinutes] = useState(25)
  const [isActive, setIsActive] = useState(false)
  const [isPaused, setIsPaused] = useState(false)
  const [remainingSeconds, setRemainingSeconds] = useState(0)
  const intervalRef = useRef<NodeJS.Timeout | null>(null)

  const clearTimer = useCallback(() => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current)
      intervalRef.current = null
    }
  }, [])

  const start = useCallback(() => {
    const totalSeconds = minutes * 60
    setRemainingSeconds(totalSeconds)
    setIsActive(true)
    setIsPaused(false)
    clearTimer()
    intervalRef.current = setInterval(() => {
      setRemainingSeconds((prev) => {
        if (prev <= 1) {
          return 0
        }
        return prev - 1
      })
    }, 1000)
  }, [minutes, clearTimer])

  const pause = useCallback(() => {
    setIsPaused(true)
    clearTimer()
  }, [clearTimer])

  const resume = useCallback(() => {
    setIsPaused(false)
    clearTimer()
    intervalRef.current = setInterval(() => {
      setRemainingSeconds((prev) => {
        if (prev <= 1) {
          return 0
        }
        return prev - 1
      })
    }, 1000)
  }, [clearTimer])

  const cancel = useCallback(() => {
    setIsActive(false)
    setIsPaused(false)
    setRemainingSeconds(0)
    clearTimer()
  }, [clearTimer])

  const handlePrimaryAction = useCallback(() => {
    if (!isActive) {
      start()
      return
    }
    if (isPaused) {
      resume()
    } else {
      pause()
    }
  }, [isActive, isPaused, start, resume, pause])

  useEffect(() => {
    return () => clearTimer()
  }, [clearTimer])

  const primaryButtonTitle = !isActive
    ? "start"
    : isPaused
      ? "resume"
      : "pause"

  return {
    minutes,
    setMinutes,
    isActive,
    isPaused,
    remainingSeconds,
    start,
    pause,
    resume,
    cancel,
    handlePrimaryAction,
    primaryButtonTitle,
  }
}
