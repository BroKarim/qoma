# Polar setup for Qyube Pro

New purchases use one **one-time Qyube Pro** product. Existing monthly/annual product IDs remain recognized only for historical orders and subscriptions until their paid access and pending cancellation jobs have ended.

## Product

- Name: `Qyube Pro`
- Billing type: one-time
- Price: USD $11 (verify against the dashboard before launch)
- Benefit: lifetime access to Qyube for macOS, up to two active Macs per account
- Disable Polar's built-in trial; Qyube grants its seven-day trial after the first completed native sign-in.
- Set `EXPECTED_LIFETIME_AMOUNT_CENTS=1100` and `MIN_LIFETIME_AMOUNT_CENTS=500`. A normal order must have subtotal minus discount equal to 1100 cents; tax is handled separately; an upgrade discount is accepted only when that checkout's server record has a matching credit and the resulting amount is at least 500 cents. A $4.90 order is rejected and saved in the webhook review log.
- Set the product ID in `POLAR_LIFETIME_PRODUCT_ID`. The browser cannot choose a Polar product ID.

## Webhook

URL: `https://qyube.brokarim.com/api/billing/webhook/polar`

Subscribe to `order.paid` and `order.refunded`. Keep `subscription.*` events enabled while existing recurring subscriptions or their paid access remain. Copy the endpoint secret to `POLAR_WEBHOOK_SECRET` in Dokploy. The handler verifies Polar's signature, deduplicates event IDs, checks product/currency/account association, and updates access only from verified provider events. A checkout return URL does not grant access.

## Customer portal

Enable customer access to one-time orders and invoices/receipts. The app's **Account & purchases** link opens Qyube's authenticated `/account` page; its purchase link creates a short-lived Polar customer portal session on the server. Verify order and invoice visibility for a one-time buyer in sandbox. Existing subscribers may also use Polar's subscription controls during the compatibility period.

## Sandbox check

1. Use sandbox credentials and only the lifetime product ID for new checkouts.
2. Verify a canceled or pending checkout leaves access unchanged.
3. Verify `order.paid` grants lifetime access to the signed-in account and the portal shows the order/invoice.
4. Verify duplicate paid events do not duplicate grants; full refund revokes the related lifetime grant, while partial refund follows the current refund policy.
5. Confirm monthly and annual checkout API requests are rejected even if old product IDs remain configured.

Do not remove the old product IDs, subscription webhook events, or cancellation retry cron until the production ledger shows no active subscription access and no queued `cancel_subscription` action. Do not put the access token or webhook secret in the app or a `NEXT_PUBLIC_*` variable.

## End-to-end setup for a new project

This document describes Qyube's implementation. An agent adapting it must inspect the new project's code, database schema, deployment environment, and current Polar documentation; replace the domain, product, prices, URLs, bundle identifier and paths below. Do not copy Qyube's credentials or assume another project has the same tables or endpoints.

1. **Design the access flow.** Create accounts and device credentials, an authenticated checkout endpoint, verified and idempotent webhook processing, a durable order ledger and entitlement record, and an authenticated endpoint returning a signed access snapshot. The native app must verify the signature, account, device, scope and validity before granting access. The checkout return page is informational: it is not proof of payment.
2. **Database and website.** Configure PostgreSQL and authentication, run the project's migrations against the intended database, and deploy the website with its public HTTPS URL. For Qyube use [SETUP.md](SETUP.md) and [SUPABASE_SETUP.md](SUPABASE_SETUP.md); verify migration history and the actual schema before changing a live database. Set `BETTER_AUTH_URL` to the public origin, not `0.0.0.0` or an internal container address. Keep database and auth secrets server-side.
3. **Polar sandbox.** In the sandbox dashboard create the organization and one-time product, record its product ID, create an organization access token and configure the webhook endpoint and events above. In Dokploy set `POLAR_ENVIRONMENT=sandbox`, `POLAR_ACCESS_TOKEN`, `POLAR_LIFETIME_PRODUCT_ID`, `POLAR_WEBHOOK_SECRET`, and the amount settings. Sandbox and production require their own matching credentials, product IDs and webhook secrets. Redeploy after environment changes and check the active deployment.
4. **Checkout and portal.** Require the website account for checkout, associate the checkout with that account in server-controlled metadata, and redirect the user to Polar. Set the success URL to the public account page. Create the customer portal session server-side and use its returned URL for invoices. Verify `BETTER_AUTH_URL` if a redirect points to `0.0.0.0`.
5. **macOS signing and networking.** Generate an Ed25519 entitlement signing pair outside the repository. Set `ENTITLEMENT_SIGNING_PRIVATE_KEY` on the server; set the corresponding raw 32-byte Base64 public key in `QyubeEntitlementPublicKey` in the app's `Info.plist`. `ENTITLEMENT_SIGNING_PUBLIC_KEY` is a reference value; Qyube's server signs using the private key. If App Sandbox is enabled, enable `com.apple.security.network.client` in the app's entitlements. Rebuild the app after changing its key or entitlements.
6. **Exercise the complete flow.** Sign in on the Mac, finish a sandbox purchase, inspect the signed webhook delivery and database, refresh or restart the app, and open the invoice in the customer portal. Check canceled checkout, duplicate delivery and refund handling as described above. Only switch to production after configuring and verifying the production resources separately.

## Troubleshooting from Qyube's sandbox setup

- **Checkout HTTP 500 and Polar `401 invalid_token`:** check that the deployed access token belongs to the selected Polar environment and is active. An empty 500 response can also cause the browser's `Unexpected end of JSON input`; inspect the server error first.
- **Postgres `tenant/user ... not found`:** check the project reference, user and pooler host in the deployed database connection string. Do not paste connection strings into logs or chat.
- **Webhook 500: `column "event_type" ... does not exist`:** the deployed code and database schema differ. Inspect the actual `webhook_events` columns and migration history, confirm the deployment points to the intended database, and apply the missing reviewed migration. Re-running migrations blindly is not a diagnosis.
- **`Lifetime order amount mismatch: expected 1100 ... received 991`:** this order had subtotal/total 1100 cents, tax 109 cents and net 991 cents. Validate the intended product price and discount using the provider's amount fields and the recorded checkout; treat tax separately. Do not use `net_amount` as the product price. Check the current webhook implementation and provider payload before adapting the rule.
- **Paid in Polar but app still gated:** an invoice or dashboard revenue confirms Polar recorded payment; it does not establish that the app processed it. Check the `order.paid` delivery status and server logs, then inspect `checkout_attempts.completed_at`, the order ledger and `entitlements` for the correct account. A null completion timestamp alone does not prove payment failed. After fixing the cause, retry the original signed delivery through Polar if available and verify a 200 response and entitlement state.
- **macOS `NSURLErrorDomain -1003` during entitlement request:** verify DNS and HTTPS from the Mac, then inspect the actual app URL, redirects and sandbox network entitlement. In this incident the app lacked outgoing network permission even though Terminal could resolve the host. A successful Terminal request alone does not prove the sandboxed app can connect.
- **Entitlement HTTP 200 but signature verification fails:** compare the public key derived from the private key actually deployed with the public key in the built app. Check token header and verification logs too. In this incident the app contained an older public key; updating it and rebuilding restored access. Do not bypass signature verification.

To derive the raw public key from a locally secured PEM file (the PEM must contain actual newlines, not literal `\\n`):

```bash
openssl pkey -in /secure/path/private-key.pem -pubout -outform DER | tail -c 32 | base64
```

Compare the entire result with the app's `QyubeEntitlementPublicKey` and the reference public key. This command assumes an Ed25519 key in the usual DER encoding. Keep private keys outside the repository; never paste them into chat, logs or commits. Remove any temporary local copy after securely retaining the intended secret.

## Debug commands for macOS

Run from the repository root; adjust the project, scheme and DerivedData path for the machine. Build output identifies the actual app location; do not assume another Mac has Qyube's DerivedData hash.

```bash
xcodebuild -project qoma.xcodeproj -scheme Qoma -configuration Debug \
  -destination 'platform=macOS' build
```

Stop the running app and open the freshly built copy, replacing the path with your build output:

```bash
pkill -x Qoma 2>/dev/null || true
open /Users/kiram/Library/Developer/Xcode/DerivedData/qoma-drxrbpjdzxdevegbhqstemmkbakm/Build/Products/Debug/Qoma.app
```

For the diagnostic logging currently present in `AccessCoordinator`, start this before refreshing access or launching the app. The access gate's refresh button only appears when applicable; a normal startup also triggers refresh:

```bash
log stream --style compact --level info \
  --predicate 'subsystem == "com.dzulkiram.qoma" AND category == "AccessRefresh"'
```

For broader system logs, which can be noisy:

```bash
log stream --style compact --level debug --predicate 'process == "Qoma"'
```

Use Ctrl+C to stop streaming. Do not share credentials, signed snapshots, customer session URLs or private keys in logs. Check the app's actual signed entitlements and bundled public key if needed:

```bash
codesign -d --entitlements :- /path/to/Qoma.app
/usr/libexec/PlistBuddy -c 'Print :QyubeEntitlementPublicKey' /path/to/Qoma.app/Contents/Info.plist
```

Check DNS and website reachability independently from the app:

```bash
dscacheutil -q host -a name qyube.brokarim.com
curl -I https://qyube.brokarim.com
curl -sS -D - -o /dev/null https://qyube.brokarim.com/api/me/entitlement
```

An unauthenticated `401` from the last command shows the endpoint responded; it does not verify a signed-in device or its entitlement. Replace the domain and endpoint for another project.
