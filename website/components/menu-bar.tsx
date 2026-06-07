"use client"

import { useState, useEffect } from "react"
import Image from "next/image"
import {
  Popover,
  PopoverTrigger,
  PopoverContent,
} from "@/components/ui/popover"
import { MenuBarPopup } from "@/components/menu-bar-popup"
import type { useTimer } from "@/lib/use-timer"

export function MenuBar({
  timer,
}: {
  timer: ReturnType<typeof useTimer>
}) {
  const [now, setNow] = useState<Date>(() => new Date())

  useEffect(() => {
    setNow(new Date())
    const id = setInterval(() => setNow(new Date()), 30_000)
    return () => clearInterval(id)
  }, [])

  const time =
    now?.toLocaleTimeString("en-US", {
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    }) ?? "--:--"
  const date =
    now?.toLocaleDateString("en-US", {
      weekday: "long",
      month: "short",
      day: "numeric",
    }) ?? "—"

  return (
    <div
      className="absolute top-0 right-0 left-0 z-20 flex h-7 items-center justify-between rounded-t-[28px] px-4 text-xs font-medium text-white/90"
      style={{
        backgroundColor: "rgba(255,255,255,0.06)",
        backdropFilter: "blur(10px)",
      }}
    >
      <div className="flex items-center gap-3">
        <span className="text-base leading-none"></span>
        <span>Nonchalant</span>
      </div>
      <div className="flex items-center gap-3 tabular-nums">
        <Popover>
          <PopoverTrigger asChild>
             <button type="button" className="relative cursor-pointer opacity-70 transition-opacity hover:opacity-100">
               <Image src="/icon1.png" alt="Menu" width={16} height={16} className="object-contain" />
             </button>
          </PopoverTrigger>
          <PopoverContent
            className="shadow-qoma w-52 overflow-hidden rounded-xl border-0 bg-black/30 p-0 text-white/90"
            style={{
              backdropFilter: "blur(40px) saturate(180%)",
              WebkitBackdropFilter: "blur(40px) saturate(180%)",
            }}
            align="end"
            sideOffset={8}
          >
            <MenuBarPopup
              minutes={timer.minutes}
              setMinutes={timer.setMinutes}
              isActive={timer.isActive}
              isPaused={timer.isPaused}
              remainingSeconds={timer.remainingSeconds}
              start={timer.start}
              cancel={timer.cancel}
              handlePrimaryAction={timer.handlePrimaryAction}
              primaryButtonTitle={timer.primaryButtonTitle}
            />
          </PopoverContent>
        </Popover>
        <span>{date}</span>
        <span>{time}</span>
      </div>
    </div>
  )
}
