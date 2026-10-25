# Qyube account and billing setup

The website is the only component that holds payment, OAuth, email, database, and signing secrets. The Mac app calls the website API; it never connects directly to PostgreSQL or Polar.

## Required before a live test

1. Create a PostgreSQL 17 database on Dokploy with TLS/private-network access and backups. Set `DATABASE_URL` on the website service; do not expose PostgreSQL publicly.
2. Set `BETTER_AUTH_URL=https://qyube.brokarim.com` and a random `BETTER_AUTH_SECRET` of at least 32 characters. Run `bun run auth:migrate`, then `bun run db:migrate`. Better Auth migration must be checked against its installed version before applying to production.
3. Add Google OAuth credentials with callback `https://qyube.brokarim.com/api/auth/callback/google`. Configure Resend with a verified sending subdomain, SPF, DKIM, and preferably DMARC; set `RESEND_API_KEY` and `RESEND_FROM`.
4. Create three **USD** Polar products: monthly $3.99 recurring, annual $29 recurring, lifetime $49 one-time. Disable Polar's own trials. Set the three `POLAR_*_PRODUCT_ID` values and the organization access token. Keep `POLAR_ENVIRONMENT=sandbox` until end-to-end tests pass; production requires a different Polar token, product IDs, and webhook secret. Verify the prices inside Polar before offering checkout; the website's displayed prices are static.
5. Create a Polar webhook at `https://qyube.brokarim.com/api/billing/webhook/polar`. Subscribe to `order.paid`, `order.refunded`, and all `subscription.*` lifecycle events. Set `POLAR_WEBHOOK_SECRET`. Configure the customer portal to permit plan changes and show final prorated totals before confirmation. QRIS is **not** advertised.
   Set a random `BILLING_JOB_TOKEN` (at least 32 characters) and have a Dokploy cron call `POST /api/internal/billing/retry` with `Authorization: Bearer <token>` every few minutes. This retries durable lifetime cancellation actions; it does not replace Polar webhook delivery or full provider reconciliation.
6. Generate an Ed25519 key pair outside the repository. Put the private PEM in `ENTITLEMENT_SIGNING_PRIVATE_KEY` (encoded with `\n` where your env UI requires a single line). Put only the raw 32-byte public key, Base64-encoded, into `Qoma/Info.plist`'s `QyubeEntitlementPublicKey`. A blank key intentionally prevents the Mac app from accepting a grant. Never commit the private key.
7. Build, sign, notarize, and distribute the Mac app with its public key and `qyube://auth/callback` URL scheme. The API URL is `https://qyube.brokarim.com` in Release; `QYUBE_API_URL` is only a Debug override.

`ENTITLEMENT_SIGNING_PUBLIC_KEY` in `.env.example` is documentation for the matching public value; the server signs with the private key only. Keep every other secret in Dokploy environment variables, not in Git or a `NEXT_PUBLIC_*` variable.

## Flow

Mac installation ID (Keychain) → one-time PKCE browser handoff → Better Auth Google/email OTP → trial/device transaction → device credential (Keychain) → signed entitlement snapshot. Trial starts on the first completed native login, not when visiting the website. There is no card or auto-charge during trial.

Checkout requires a verified website session. The server fixes the product ID and account ID; the browser supplies only `monthly`, `annual`, or `lifetime`. A return from Polar is never proof of payment. The signed webhook updates the billing ledger and recomputes `entitlements`; the Mac refreshes from that API. Full refund removes lifetime access but never deletes local sessions or catches.

The lifetime upgrade discount is created with one redemption, a lifetime-product restriction, and a short expiry. It credits the most recent non-refunded paid order for the active subscription, excluding tax. An account whose latest invoice is a plan-change proration is deliberately blocked from this upgrade path until the final credit rule is verified in Polar sandbox. Subscription cancellation is queued only after lifetime `order.paid`; Polar retries the webhook when that follow-up API call fails.

## Mandatory sandbox acceptance checks

- Google-first, OTP-first, verified same-email linking, unverified email rejection; OTP replay/rate limits and wrong PKCE state/verifier.
- Account and installation trial once each, 2 active Macs, third Mac rejected, old Mac removal, revoked credential refused.
- Trial expiration, offline subscription through paid end + 3 days, lifetime 30 days since last server check, device removal while offline.
- Failed/canceled checkout grants nothing; paid monthly/annual/lifetime grants only its owner; duplicate and reordered webhooks; full/partial refunds; renewal, failed renewal, cancellation, and changed plans.
- Lifetime $45.01 after $3.99 monthly, $20 after $29 annual (before tax), full $49 from trial; double-checkout, discount expiry, cancellation retry, renewal race, and proration-adjusted invoices.
- Stripe/Xendit are not wired in MVP. Polar payment methods and tax behavior must be verified in its dashboard per market.

No live PostgreSQL, OAuth, Resend, or Polar request has been exercised while credentials remain blank. Typecheck/build/unit tests do not replace these gates.
