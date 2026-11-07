export type AccountAccessState = {
  lifetime: boolean
  trial: boolean
  active: boolean
  expired: boolean
}

export function accountAccessState(access: {
  plan: string | null
  status: string
  accessUntil: Date | null
  trialEndsAt: Date | null
}, now = new Date()): AccountAccessState {
  const withinWindow = !access.accessUntil || access.accessUntil > now
  const active = access.status === "active" && withinWindow
  const lifetime = active && access.plan === "lifetime"
  const trial = active && access.plan === "trial" && !!access.trialEndsAt && access.trialEndsAt > now
  return { lifetime, trial, active, expired: !active && access.status !== "revoked" }
}

export function showCheckoutPending(checkoutReturned: boolean, paymentFinal: boolean) {
  return checkoutReturned && !paymentFinal
}
