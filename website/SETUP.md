# Qyube account and billing setup

The website is the only component that holds payment, OAuth, email, database, and signing secrets. The Mac app calls the website API; it never connects directly to PostgreSQL or Polar.

## Required before a live test

1. Create a dedicated Supabase PostgreSQL project and follow [SUPABASE_SETUP.md](SUPABASE_SETUP.md). The website stays on Dokploy. Set the session-pooler connection URI in `DATABASE_URL`; `DATABASE_MIGRATION_URL` can override it for migrations. Disable the project's Data API because clients use the website API.
2. Set `BETTER_AUTH_URL=https://qyube.brokarim.com` and a random `BETTER_AUTH_SECRET` of at least 32 characters. Run `bun run auth:migrate`, then `bun run db:migrate`. Better Auth migration must be checked against its installed version before applying to production.
3. Add Google OAuth credentials with callback `https://qyube.brokarim.com/api/auth/callback/google`. For Apple, create an App ID with **Sign in with Apple**, a matching Service ID, and a Sign in with Apple key in the Apple Developer portal. Generate a 90-day client secret with `bun run apple:secret` and store the printed value as `APPLE_CLIENT_SECRET`; configure `APPLE_CLIENT_ID` to the Service ID. Keep `APPLE_TEAM_ID`, `APPLE_KEY_ID`, and `APPLE_PRIVATE_KEY` only in the trusted secret environment used to generate the JWT; never commit the `.p8` key or JWT. Run `bun run apple:secret:check` daily; rotate the JWT and restart the website service when the warning says fewer than 30 days remain. Better Auth 1.7.12 resolves its async provider factory once while creating its cached auth context, so runtime regeneration inside that callback would not refresh the client secret. Register `qyube.brokarim.com` and callback `https://qyube.brokarim.com/api/auth/callback/apple` on the Service ID. Apple sign-in requires HTTPS and cannot complete on `localhost`.
4. Create the **USD Qyube Pro lifetime** Polar product at $11 one-time and disable Polar trials. Set `POLAR_LIFETIME_PRODUCT_ID`, `EXPECTED_LIFETIME_AMOUNT_CENTS=1100`, and the organization access token. New recurring checkout is disabled. Keep old monthly/annual product IDs configured only while historical subscription webhooks or paid subscriptions still need recognition; do not delete their Polar products until the subscription ledger and pending jobs have been checked. Keep `POLAR_ENVIRONMENT=sandbox` until end-to-end tests pass; production requires a different Polar token, product ID, and webhook secret. Verify price and tax behavior in Polar before offering checkout.
5. Create a Polar webhook at `https://qyube.brokarim.com/api/billing/webhook/polar`. Subscribe to `order.paid` and `order.refunded`; keep `subscription.*` events while old subscriptions or their paid periods remain. Set `POLAR_WEBHOOK_SECRET`. Enable one-time orders and invoices in the customer portal and verify them in sandbox. QRIS is **not** advertised.
   Set a random `BILLING_JOB_TOKEN` (at least 32 characters) and keep the Dokploy cron calling `POST /api/internal/billing/retry` with `Authorization: Bearer <token>` while legacy lifetime upgrades may have queued subscription cancellation actions. Remove that cron only after the ledger confirms no active legacy subscriptions and no pending cancellation actions.
6. Generate an Ed25519 key pair outside the repository. Put the private PEM in `ENTITLEMENT_SIGNING_PRIVATE_KEY` (encoded with `\n` where your env UI requires a single line). Put only the raw 32-byte public key, Base64-encoded, into `Qoma/Info.plist`'s `QyubeEntitlementPublicKey`. A blank key intentionally prevents the Mac app from accepting a grant. Never commit the private key.
7. Build, sign, notarize, and distribute the Mac app with its public key and `qyube://auth/callback` URL scheme. The API URL is `https://qyube.brokarim.com` in Release; `QYUBE_API_URL` is only a Debug override.

## Scheduled maintenance

- Run `bun run apple:secret:check` daily and rotate the Apple JWT when it warns below 30 days.
- Run `bun run native-auth:cleanup` daily in a scheduled Dokploy command/container. It removes expired login attempts and handoffs.
- Run `bun run webhook:retry` every few minutes in a scheduled command/container. It retries signed Polar events persisted as failed or left received after an interrupted process; monitor its exit status and logs.
- Keep `TRUSTED_PROXY_COUNT` aligned with the Dokploy/Traefik proxy chain. The service trusts the proxy-supplied `X-Forwarded-For` header, so keep the app container reachable only through that proxy and configure the proxy to sanitize client-supplied forwarding headers.

`ENTITLEMENT_SIGNING_PUBLIC_KEY` in `.env.example` is documentation for the matching public value; the server signs with the private key only. Keep every other secret in Dokploy environment variables, not in Git or a `NEXT_PUBLIC_*` variable.

## Flow

Mac installation ID (Keychain) → one-time PKCE browser handoff → Better Auth Google or Apple OAuth → trial/device transaction → device credential (Keychain) → signed entitlement snapshot. Trial starts on the first completed native login, not when visiting the website. There is no card or auto-charge during trial.

Checkout requires a verified website session. The server fixes the product ID and account ID; new checkout accepts `lifetime` only. The webhook still recognizes configured historical recurring products for their paid access. A return from Polar is never proof of payment. The signed webhook updates the billing ledger and recomputes `entitlements`; the Mac refreshes from that API. Full refund removes lifetime access but never deletes local sessions or catches.

For an account with an existing paid subscription, the lifetime upgrade discount is created with one redemption, a lifetime-product restriction, and a short expiry. It credits the most recent non-refunded paid order, excluding tax. An account whose latest invoice is a plan-change proration remains blocked from this upgrade path until the final credit rule is verified in Polar sandbox. Subscription cancellation is queued only after lifetime `order.paid`; Polar retries the webhook when that follow-up API call fails. Remove this compatibility path only after confirming no active subscriptions or pending cancellation jobs.

## Mandatory sandbox acceptance checks

- Google and Apple sign-in, verified same-email linking, unverified email rejection, and wrong PKCE state/verifier.
- Account and installation trial once each, 2 active Macs, third Mac rejected, old Mac removal, revoked credential refused.
- Trial expiration, offline subscription through paid end + 3 days, lifetime 30 days since last server check, device removal while offline.
- Monthly/annual checkout requests are rejected; failed/canceled lifetime checkout grants nothing; verified paid lifetime grants only its owner; duplicate/out-of-order events and full/partial refunds.
- Existing subscription access still honors paid-through dates and revocation; legacy lifetime upgrade discount, cancellation retry and proration conflict paths remain covered until production ledger audit clears them.
- Stripe/Xendit are not wired in MVP. Polar payment methods and tax behavior must be verified in its dashboard per market.

No live PostgreSQL, OAuth, or Polar request has been exercised while credentials remain blank. Typecheck/build/unit tests do not replace these gates.

## Settings account links and launch waitlist (12 November 2026)

Apply the latest Drizzle migrations with `bun run db:migrate` before deploying the app's Account & purchases link or the website waitlist. They add `account_links`, `waitlist`, and `waitlist_attempts`; RLS stays enabled and these tables are accessed only by the server database connection.

The waitlist uses existing `DATABASE_URL`, `BETTER_AUTH_URL`, `BETTER_AUTH_SECRET` and `TRUSTED_PROXY_COUNT`. The public site origin must match `BETTER_AUTH_URL`; the reverse proxy must sanitize forwarding headers. No new email provider secret is needed: signup stores consent but does not send mail. Establish unsubscribe handling before sending a launch campaign. Support requests go to brokariim@gmail.com.

For isolated local verification, use a disposable Postgres database on 127.0.0.1:55439, run migrations, then execute `node --import tsx scripts/check-hero-account-integration.ts` with `QYUBE_TEST_DATABASE=1` and test-only environment values. The script removes its fixtures and all rate-limit attempts in that isolated database; never point it at real user data.
