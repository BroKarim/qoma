ALTER TABLE billing_orders ADD COLUMN IF NOT EXISTS total_cents integer;
ALTER TABLE billing_orders ADD COLUMN IF NOT EXISTS billing_reason text;
