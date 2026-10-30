"use client"

import { useState } from "react"

type Device = { id: string; name: string; last_seen_at: string }

export function DeviceList({ initial }: { initial: Device[] }) {
  const [devices, setDevices] = useState(initial)
  const [error, setError] = useState("")
  async function remove(id: string) {
    setError("")
    const response = await fetch(`/api/me/devices/${encodeURIComponent(id)}`, { method: "DELETE" })
    if (response.ok) setDevices((current) => current.filter((device) => device.id !== id))
    else setError("Could not remove this Mac. Please try again.")
  }
  return <section>
    <h2 className="text-xl font-semibold">Connected Macs ({devices.length}/2)</h2>
    <p className="mt-1 text-sm text-gray-600">Remove an old Mac to make room for a new one.</p>
    <ul className="mt-4 space-y-3">{devices.map((device) => <li key={device.id} className="flex items-center justify-between gap-4 rounded-xl border p-3">
      <span>{device.name} <small className="block text-gray-500">Last seen {new Date(device.last_seen_at).toLocaleDateString()}</small></span>
      <button onClick={() => remove(device.id)} className="text-sm underline">Remove</button>
    </li>)}</ul>
    {error && <p role="alert" className="mt-2 text-sm text-red-700">{error}</p>}
  </section>
}
