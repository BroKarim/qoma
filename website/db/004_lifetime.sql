ALTER TABLE checkout_attempts ADD COLUMN IF NOT EXISTS credit_cents integer NOT NULL DEFAULT 0;
ALTER TABLE checkout_attempts ADD COLUMN IF NOT EXISTS discount_id text;
ALTER TABLE checkout_attempts ADD COLUMN IF NOT EXISTS prior_subscription_id text;

CREATE TABLE IF NOT EXISTS billing_actions (
  id bigserial PRIMARY KEY,
  provider text NOT NULL,
  action text NOT NULL,
  account_id text NOT NULL,
  provider_subscription_id text NOT NULL,
  completed_at timestamptz,
  last_error text,
  UNIQUE(provider, action, provider_subscription_id)
);
