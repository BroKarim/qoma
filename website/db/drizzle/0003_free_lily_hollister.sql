CREATE TABLE "waitlist" (
	"email" text PRIMARY KEY NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"consent_at" timestamp with time zone DEFAULT now() NOT NULL,
	"consent_version" text NOT NULL,
	"status" text DEFAULT 'subscribed' NOT NULL
);
--> statement-breakpoint
ALTER TABLE "waitlist" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE "waitlist_attempts" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"ip_hash" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "waitlist_attempts" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE INDEX "waitlist_attempts_ip_date" ON "waitlist_attempts" USING btree ("ip_hash","created_at");