CREATE TABLE IF NOT EXISTS native_login_attempts (
  id uuid PRIMARY KEY,
  installation_hash text NOT NULL,
  device_name text NOT NULL,
  challenge text NOT NULL,
  state text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL,
  completed_at timestamptz
);
CREATE INDEX IF NOT EXISTS native_attempt_expiry ON native_login_attempts(expires_at);

ALTER TABLE native_handoffs ADD COLUMN IF NOT EXISTS attempt_id uuid UNIQUE REFERENCES native_login_attempts(id);
ALTER TABLE native_handoffs ADD COLUMN IF NOT EXISTS device_id uuid;
CREATE INDEX IF NOT EXISTS native_handoff_expiry ON native_handoffs(expires_at);
