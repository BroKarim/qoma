CREATE TABLE IF NOT EXISTS checkout_attempts (
  id uuid PRIMARY KEY,
  account_id text NOT NULL,
  plan text NOT NULL CHECK (plan IN ('monthly', 'annual', 'lifetime')),
  product_id text NOT NULL,
  provider_checkout_id text UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz
);

ALTER TABLE billing_subscriptions ADD COLUMN IF NOT EXISTS provider_modified_at timestamptz;
ALTER TABLE billing_orders ADD COLUMN IF NOT EXISTS provider_modified_at timestamptz;

CREATE TABLE IF NOT EXISTS polar_subscription_state (
  subscription_id text PRIMARY KEY,
  account_id text NOT NULL,
  product_id text NOT NULL,
  revoked boolean NOT NULL,
  cancel_at_period_end boolean NOT NULL,
  provider_modified_at timestamptz NOT NULL
);
