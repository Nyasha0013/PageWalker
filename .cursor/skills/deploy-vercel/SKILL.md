---
name: deploy-vercel
description: Use whenever deploying a Next.js project to Vercel, troubleshooting a failed deployment, setting up environment variables, or configuring preview/production environments. Trigger on "deploy," "push to production," "it works locally but not on Vercel," or build/env-var errors.
---

# Deploy to Vercel

## Pre-deploy checklist

1. Confirm all required env vars exist in Vercel's dashboard for the target environment (Production / Preview / Development) — a var set only locally in `.env.local` will build fine locally and fail silently or 500 in production.
2. Run `next build` locally first. Catches type errors and missing env vars before pushing, faster than waiting on Vercel's build queue.
3. Check that Supabase URL/anon key env vars are prefixed correctly (`NEXT_PUBLIC_` for anything needed client-side; without the prefix it's invisible to the browser bundle and `undefined` at runtime — a classic "works locally, breaks in prod" bug if `.env.local` had it cached).

## "Works locally, broken on Vercel" — check in this order

1. Env var missing or wrong prefix (see above) — most common cause.
2. Case-sensitivity in import paths — local filesystem (Mac/Windows) is often case-insensitive, Vercel's Linux build isn't.
3. Node version mismatch — pin `engines.node` in `package.json` if relying on a specific feature.
4. Edge runtime vs Node runtime differences if any API route specifies `runtime: 'edge'` — some Node APIs (like certain crypto or fs calls) aren't available there.

## Telegram Mini App deploy specifics

- Mini Apps require HTTPS — Vercel preview URLs work for this, but if the bot is configured with a single fixed webhook/Mini App URL, preview deploys won't be reachable from Telegram unless you update the URL in the bot settings (BotFather) or use a stable domain alias for testing.
- X-Frame-Options / CSP headers: if the Mini App needs to render inside Telegram's webview, check `next.config.js` headers don't set `X-Frame-Options: DENY` — this is the exact class of bug that broke Honey Well's Mini App embed previously. Use a CSP `frame-ancestors` directive scoped to Telegram's domains instead of a blanket deny.

## Rollback

Know before you need it: Vercel keeps previous deployments — "Promote to Production" on a prior deployment is faster than reverting a git commit and waiting for a fresh build if something breaks right after a deploy.
