export function expectedLifetimeAmountCents() {
  const amount = Number(process.env.EXPECTED_LIFETIME_AMOUNT_CENTS ?? "1100")
  if (!Number.isSafeInteger(amount) || amount <= 0) throw new Error("EXPECTED_LIFETIME_AMOUNT_CENTS must be a positive integer")
  return amount
}

export function minimumLifetimeAmountCents() {
  const amount = Number(process.env.MIN_LIFETIME_AMOUNT_CENTS ?? "500")
  if (!Number.isSafeInteger(amount) || amount < 0 || amount >= expectedLifetimeAmountCents()) throw new Error("MIN_LIFETIME_AMOUNT_CENTS must be a non-negative integer below the lifetime price")
  return amount
}

export function validateLifetimeOrderAmount(input: {
  amountCents: number
  currency: string
  expectedCents: number
  checkoutCreditCents: number
  hasConfiguredDiscount: boolean
  minimumDiscountedCents: number
}) {
  if (input.currency !== "usd") return false
  const expected = input.expectedCents - input.checkoutCreditCents
  const discountValid = input.checkoutCreditCents > 0 && input.hasConfiguredDiscount &&
    input.amountCents >= input.minimumDiscountedCents && input.amountCents === expected
  return input.checkoutCreditCents === 0
    ? input.amountCents === input.expectedCents
    : discountValid
}
