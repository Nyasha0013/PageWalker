---
name: supabase-patterns
description: Use whenever writing or editing Supabase auth, database schema, Row Level Security (RLS) policies, Supabase client setup, or any admin/protected route that reads or writes data. Make sure to use this for bugs involving "save button doesn't work," "unauthorized," "permission denied," session/cookie issues, or anything touching auth.uid(). Critical for catching client/server auth handler mismatches before they ship.
---

# Supabase Patterns

## The recurring bug class: auth handler mismatch

The most common silent failure is mixing auth clients: using the browser client (`createBrowserClient` / anon key) in a context that needs the server client (`createServerClient` / cookies-based session), or vice versa. Symptoms: buttons that do nothing, writes that silently no-op, or RLS denying a request that "should" be allowed.

**Checklist before debugging anything else when an admin/protected action fails silently:**
1. Is this running on the server (route handler, server action, middleware) or client (component with `"use client"`)?
2. Does it use the matching Supabase client for that context? Server code must read the session from cookies via the server client — never reuse a client-side singleton in a server action.
3. Log the actual Supabase error object (`{ data, error }`), not just `error` — RLS denials often return a generic message that hides the real cause unless you inspect `error.details` / `error.hint`.
4. Confirm `auth.uid()` actually resolves inside the RLS policy by testing the query in the Supabase SQL editor as that specific user, not just as the service role.

## RLS policy rules

- Every table with user data needs RLS enabled before going to production — never rely on "we'll add it later."
- Write policies as: who (role), what (select/insert/update/delete), and the exact `using`/`with check` expression. Don't write a single broad policy when the actual access pattern differs between read and write.
- Test every policy with at least two cases: the intended user can do the action, and a different user cannot.
- Service-role key bypasses RLS entirely — never expose it client-side, and flag any code path where it's used outside of a trusted server context (webhooks, admin scripts).

## Schema changes

- Write migrations, don't edit the schema by hand in the dashboard for anything beyond a quick prototype — migrations are what make Honey Well/Nuvelo/Pagewalker reproducible across environments.
- When adding a column with a default that affects existing rows (e.g. a new `status` field), backfill explicitly rather than assuming the default covers it.

## Realtime / availability bugs

For "drop availability" style bugs (race conditions on shared availability state): prefer a database-level constraint or transaction over client-side checks. Client-side "is this slot free?" checks followed by a separate write are inherently racy — two clients can both see "available" and both write.

## Client setup sanity check

When starting work on a route, confirm in 5 seconds which client is in scope:
- `app/**/route.ts` or Server Actions → server client, cookies-based
- Client components → browser client
- Telegram Mini App webhook/bot handlers → server client with service role only if doing privileged writes after verifying the Telegram `initData` signature
