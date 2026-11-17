import { redirect } from "next/navigation"
export const metadata = { title: "Checkout · Qyube", robots: { index: false, follow: false } }

export default function PricingPage() { redirect("/account?checkout=start") }
