CREATE TABLE IF NOT EXISTS trial_claims (
  account_id text PRIMARY KEY,
  installation_hash text NOT NULL UNIQUE,
  started_at timestamptz NOT NULL DEFAULT now(),
  ends_at timestamptz NOT NULL
);

CREATE TABLE IF NOT EXISTS trial_devices (
  installation_hash text PRIMARY KEY,
  first_account_id text NOT NULL,
  claimed_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS devices (
  id uuid PRIMARY KEY,
  account_id text NOT NULL,
  installation_hash text NOT NULL,
  name text NOT NULL,
  activated_at timestamptz NOT NULL DEFAULT now(),
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  revoked_at timestamptz,
  UNIQUE (account_id, installation_hash)
);
CREATE INDEX IF NOT EXISTS devices_active_by_account ON devices (account_id) WHERE revoked_at IS NULL;

CREATE TABLE IF NOT EXISTS native_handoffs (
  code_hash text PRIMARY KEY,
  account_id text NOT NULL,
  installation_hash text NOT NULL,
  challenge text NOT NULL,
  state text NOT NULL,
  device_name text NOT NULL,
  expires_at timestamptz NOT NULL,
  consumed_at timestamptz
);

CREATE TABLE IF NOT EXISTS device_credentials (
  token_hash text PRIMARY KEY,
  device_id uuid NOT NULL REFERENCES devices(id),
  account_id text NOT NULL,
  expires_at timestamptz NOT NULL,
  revoked_at timestamptz
);
CREATE INDEX IF NOT EXISTS credentials_by_device ON device_credentials(device_id);

CREATE TABLE IF NOT EXISTS billing_customers (
  account_id text NOT NULL,
  provider text NOT NULL,
  provider_customer_id text NOT NULL,
  PRIMARY KEY (account_id, provider),
  UNIQUE (provider, provider_customer_id)
);

CREATE TABLE IF NOT EXISTS billing_subscriptions (
  provider text NOT NULL,
  provider_subscription_id text NOT NULL,
  account_id text NOT NULL,
  plan text NOT NULL CHECK (plan IN ('monthly', 'annual')),
  paid_until timestamptz NOT NULL,
  cancel_at_period_end boolean NOT NULL DEFAULT false,
  revoked_at timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (provider, provider_subscription_id)
);
CREATE INDEX IF NOT EXISTS subscriptions_by_account ON billing_subscriptions(account_id);

CREATE TABLE IF NOT EXISTS billing_orders (
  provider text NOT NULL,
  provider_order_id text NOT NULL,
  account_id text NOT NULL,
  plan text NOT NULL CHECK (plan IN ('monthly', 'annual', 'lifetime')),
  subscription_id text,
  amount_cents integer NOT NULL CHECK (amount_cents >= 0),
  refunded_cents integer NOT NULL DEFAULT 0 CHECK (refunded_cents >= 0),
  currency text NOT NULL CHECK (currency = 'usd'),
  status text NOT NULL CHECK (status IN ('paid', 'refunded')),
  paid_at timestamptz NOT NULL,
  period_start timestamptz,
  period_end timestamptz,
  PRIMARY KEY (provider, provider_order_id)
);
CREATE INDEX IF NOT EXISTS orders_by_account ON billing_orders(account_id, paid_at DESC);

CREATE TABLE IF NOT EXISTS webhook_events (
  provider text NOT NULL,
  event_id text NOT NULL,
  payload jsonb NOT NULL,
  received_at timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz,
  error text,
  PRIMARY KEY (provider, event_id)
);

CREATE TABLE IF NOT EXISTS entitlements (
  account_id text PRIMARY KEY,
  plan text CHECK (plan IN ('trial', 'monthly', 'annual', 'lifetime')),
  status text NOT NULL CHECK (status IN ('active', 'expired', 'revoked')),
  access_until timestamptz,
  trial_ends_at timestamptz,
  version bigint NOT NULL DEFAULT 1,
  updated_at timestamptz NOT NULL DEFAULT now()
);
