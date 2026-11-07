# Polar setup for Qyube Pro

New purchases use one **one-time Qyube Pro** product. Existing monthly/annual product IDs remain recognized only for historical orders and subscriptions until their paid access and pending cancellation jobs have ended.

## Product

- Name: `Qyube Pro`
- Billing type: one-time
- Price: USD $11 (verify against the dashboard before launch)
- Benefit: lifetime access to Qyube for macOS, up to two active Macs per account
- Disable Polar's built-in trial; Qyube grants its seven-day trial after the first completed native sign-in.
- Set `EXPECTED_LIFETIME_AMOUNT_CENTS=1100` and `MIN_LIFETIME_AMOUNT_CENTS=500`. A normal order must net exactly 1100 cents before tax; an upgrade discount is accepted only when that checkout's server record has a matching credit and the resulting amount is at least 500 cents. A $4.90 order is rejected and saved in the webhook review log.
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
