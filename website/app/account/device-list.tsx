"use client"

import { useState } from "react"

type Device = { id: string; name: string; last_seen_at: string }

export function DeviceList({ initial }: { initial: Device[] }) {
  const [devices, setDevices] = useState(initial)
  const [confirming, setConfirming] = useState<string | null>(null)
  const [removing, setRemoving] = useState<string | null>(null)
  const [error, setError] = useState("")
  async function remove(id: string) {
    setError("")
    setRemoving(id)
    try {
      const response = await fetch(`/api/me/devices/${encodeURIComponent(id)}`, { method: "DELETE" })
      if (!response.ok) throw new Error()
      setDevices((current) => current.filter((device) => device.id !== id))
      setConfirming(null)
    } catch { setError("Could not remove this Mac. Please try again.") }
    finally { setRemoving(null) }
  }
  return <section>
    <p className="mb-2 text-sm text-gray-600">Remove a Mac to make room for another one.</p>
    <ul>{devices.map((device) => <li key={device.id} className="flex flex-col gap-2 border-t border-gray-100 py-3 first:border-0">
      <div className="flex items-center justify-between gap-4"><span>{device.name} <small className="block text-gray-500">Last seen {new Date(device.last_seen_at).toLocaleDateString()}</small></span>
      <button disabled={removing !== null} onClick={() => { setError(""); setConfirming(device.id) }} className="rounded-md border border-gray-300 bg-white px-3 py-2 text-sm text-[#203744] disabled:opacity-50">Remove</button></div>
      {confirming === device.id && <div className="flex flex-wrap items-center justify-between gap-2 rounded-lg bg-sky-50 p-3 text-sm" role="group" aria-label={`Confirm removing ${device.name}`}>
        <span>Remove {device.name} from your account?</span><span className="flex gap-2"><button disabled={removing !== null} onClick={() => setConfirming(null)} className="underline">Keep Mac</button><button disabled={removing !== null} onClick={() => void remove(device.id)} className="font-semibold text-red-800 underline">{removing === device.id ? "Removing…" : "Remove Mac"}</button></span>
      </div>}
    </li>)}</ul>
    {error && <p role="alert" className="mt-2 text-sm text-red-700">{error}</p>}
  </section>
}
