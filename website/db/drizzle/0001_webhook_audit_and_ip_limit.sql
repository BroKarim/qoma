ALTER TABLE "native_login_attempts" ADD COLUMN "source_ip_hash" text;--> statement-breakpoint
ALTER TABLE "webhook_events" ADD COLUMN "event_type" text;--> statement-breakpoint
ALTER TABLE "webhook_events" ADD COLUMN "status" text DEFAULT 'received' NOT NULL;--> statement-breakpoint
ALTER TABLE "webhook_events" ADD COLUMN "account_id" text;