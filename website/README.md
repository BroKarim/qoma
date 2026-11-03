# Qyube website

Next.js website, Better Auth login, and server API for Qyube's Mac app. Database hosting uses Supabase PostgreSQL with Drizzle; the website is deployed on Dokploy.

## Account and billing setup

- [Overall setup](SETUP.md)
- [Supabase, connection strings, and Drizzle migrations](SUPABASE_SETUP.md)
- [Polar sandbox, products, tokens, webhooks, and entitlement keys](POLAR_SETUP.md)

Use the variable names from `.env.example` in your private environment configuration. Database, billing, OAuth, and signing secrets are server-only.

## Deploy with Dokploy

The GitHub Actions workflow builds `website/Dockerfile` and publishes an ARM64 Next.js server image to GHCR when `website/**` changes on `main`, tagged `latest` and with the commit SHA:

```text
ghcr.io/brokarim/qoma-website:latest
```

In Dokploy, configure that image, the public HTTPS domain, and container port `3000`. If the GHCR package is private, use a GitHub username and a personal access token with `read:packages`. Add the runtime variables from `.env.example` in the Dokploy service; local `.env` values are not included in the image. Keep the Polar environment set to `sandbox` while testing.

Before the first sign-in, point `DATABASE_URL` and `DATABASE_MIGRATION_URL` at the intended Supabase project, then run `bun run auth:migrate` and `bun run db:migrate` from `website/`. Migrations are an operator step and do not run automatically when the container starts.

## Adding components

To add components to your app, run the following command:

```bash
npx shadcn@latest add button
```

This will place the ui components in the `components` directory.

## Using components

To use the components in your app, import them as follows:

```tsx
import { Button } from "@/components/ui/button";
```
