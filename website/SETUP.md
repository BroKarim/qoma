# Qyube account and billing setup

The website is the only component that holds payment, OAuth, email, database, and signing secrets. The Mac app calls the website API; it never connects directly to PostgreSQL or Polar.

## Required before a live test

1. Create a PostgreSQL 17 database on Dokploy with TLS/private-network access and backups. Set `DATABASE_URL` on the website service; do not expose PostgreSQL publicly.
2. Set `BETTER_AUTH_URL=https://qyube.brokarim.com` and a random `BETTER_AUTH_SECRET` of at least 32 characters. Run `bun run auth:migrate`, then `bun run db:migrate`. Better Auth migration must be checked against its installed version before applying to production.
3. Add Google OAuth credentials with callback `https://qyube.brokarim.com/api/auth/callback/google`. Configure Resend with a verified sending subdomain, SPF, DKIM, and preferably DMARC; set `RESEND_API_KEY` and `RESEND_FROM`.
4. Create the **USD Qyube Pro lifetime** Polar product at $49 one-time and disable Polar trials. Set `POLAR_LIFETIME_PRODUCT_ID` and the organization access token. New recurring checkout is disabled. Keep old monthly/annual product IDs configured only while historical subscription webhooks or paid subscriptions still need recognition; do not delete their Polar products until the subscription ledger and pending jobs have been checked. Keep `POLAR_ENVIRONMENT=sandbox` until end-to-end tests pass; production requires a different Polar token, product ID, and webhook secret. Verify price and tax behavior in Polar before offering checkout.
5. Create a Polar webhook at `https://qyube.brokarim.com/api/billing/webhook/polar`. Subscribe to `order.paid` and `order.refunded`; keep `subscription.*` events while old subscriptions or their paid periods remain. Set `POLAR_WEBHOOK_SECRET`. Enable one-time orders and invoices in the customer portal and verify them in sandbox. QRIS is **not** advertised.
   Set a random `BILLING_JOB_TOKEN` (at least 32 characters) and keep the Dokploy cron calling `POST /api/internal/billing/retry` with `Authorization: Bearer <token>` while legacy lifetime upgrades may have queued subscription cancellation actions. Remove that cron only after the ledger confirms no active legacy subscriptions and no pending cancellation actions.
6. Generate an Ed25519 key pair outside the repository. Put the private PEM in `ENTITLEMENT_SIGNING_PRIVATE_KEY` (encoded with `\n` where your env UI requires a single line). Put only the raw 32-byte public key, Base64-encoded, into `Qoma/Info.plist`'s `QyubeEntitlementPublicKey`. A blank key intentionally prevents the Mac app from accepting a grant. Never commit the private key.
7. Build, sign, notarize, and distribute the Mac app with its public key and `qyube://auth/callback` URL scheme. The API URL is `https://qyube.brokarim.com` in Release; `QYUBE_API_URL` is only a Debug override.

`ENTITLEMENT_SIGNING_PUBLIC_KEY` in `.env.example` is documentation for the matching public value; the server signs with the private key only. Keep every other secret in Dokploy environment variables, not in Git or a `NEXT_PUBLIC_*` variable.

## Flow

Mac installation ID (Keychain) → one-time PKCE browser handoff → Better Auth Google/email OTP → trial/device transaction → device credential (Keychain) → signed entitlement snapshot. Trial starts on the first completed native login, not when visiting the website. There is no card or auto-charge during trial.

Checkout requires a verified website session. The server fixes the product ID and account ID; new checkout accepts `lifetime` only. The webhook still recognizes configured historical recurring products for their paid access. A return from Polar is never proof of payment. The signed webhook updates the billing ledger and recomputes `entitlements`; the Mac refreshes from that API. Full refund removes lifetime access but never deletes local sessions or catches.

For an account with an existing paid subscription, the lifetime upgrade discount is created with one redemption, a lifetime-product restriction, and a short expiry. It credits the most recent non-refunded paid order, excluding tax. An account whose latest invoice is a plan-change proration remains blocked from this upgrade path until the final credit rule is verified in Polar sandbox. Subscription cancellation is queued only after lifetime `order.paid`; Polar retries the webhook when that follow-up API call fails. Remove this compatibility path only after confirming no active subscriptions or pending cancellation jobs.

## Mandatory sandbox acceptance checks

- Google-first, OTP-first, verified same-email linking, unverified email rejection; OTP replay/rate limits and wrong PKCE state/verifier.
- Account and installation trial once each, 2 active Macs, third Mac rejected, old Mac removal, revoked credential refused.
- Trial expiration, offline subscription through paid end + 3 days, lifetime 30 days since last server check, device removal while offline.
- Monthly/annual checkout requests are rejected; failed/canceled lifetime checkout grants nothing; verified paid lifetime grants only its owner; duplicate/out-of-order events and full/partial refunds.
- Existing subscription access still honors paid-through dates and revocation; legacy lifetime upgrade discount, cancellation retry and proration conflict paths remain covered until production ledger audit clears them.
- Stripe/Xendit are not wired in MVP. Polar payment methods and tax behavior must be verified in its dashboard per market.

No live PostgreSQL, OAuth, Resend, or Polar request has been exercised while credentials remain blank. Typecheck/build/unit tests do not replace these gates.
