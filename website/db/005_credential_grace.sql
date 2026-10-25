ALTER TABLE device_credentials ADD COLUMN IF NOT EXISTS grace_until timestamptz;
