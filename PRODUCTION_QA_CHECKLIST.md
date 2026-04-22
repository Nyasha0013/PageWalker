# Production QA Checklist

Use this checklist before major releases and after infra/env changes.

## 1) API and Environment Health

- [ ] `./scripts/smoke-web.sh https://pagewalker.org` passes
- [ ] `./scripts/smoke-web-extended.sh https://pagewalker.org` passes
- [ ] Vercel env vars exist for Production + Preview:
  - [ ] `GOOGLE_BOOKS_API_KEY`
  - [ ] `OPENAI_API_KEY`
  - [ ] `SUPABASE_URL`
  - [ ] `SUPABASE_ANON_KEY`
  - [ ] `ERROR_ALERT_WEBHOOK_URL` (optional, for 5xx alerting)
- [ ] API routes return request IDs (`x-request-id`)
- [ ] Rate limiting is active (`429` with `Retry-After` after repeated abuse tests)
- [ ] Method allow-lists active (`405` on invalid methods for `/api/config` and `/api/books`)
- [ ] Bot-deny guard active (`403` for denied user agents)

## 2) Core User Flows

- [ ] Home route loads quickly and theme/language controls work
- [ ] Discover:
  - [ ] Trending, genre, search, classics return data
  - [ ] `Load more` works for each section
  - [ ] Mood recommendations call works
- [ ] Library:
  - [ ] Book add/status transitions work
  - [ ] `Load more` works and does not duplicate rows
- [ ] Book details:
  - [ ] Modal opens/closes
  - [ ] `/book?id=...` deep link opens correctly
  - [ ] Copy share link works
- [ ] Auth:
  - [ ] Sign in, sign up, sign out
  - [ ] Protected routes gated for guests

## 3) Browser + Device Matrix

- [ ] Chrome (latest)
- [ ] Safari (latest)
- [ ] Firefox (latest)
- [ ] Mobile Safari (iOS)
- [ ] Mobile Chrome (Android)

## 4) Accessibility Baseline

- [ ] Keyboard navigation can reach all key controls
- [ ] Focus indicators visible on links/buttons/forms
- [ ] Color contrast acceptable in light and dark themes
- [ ] Modal can be dismissed with Escape and backdrop

## 5) Performance + Caching

- [ ] API cache headers visible on `/api/books` responses
- [ ] No large layout shifts on route transitions
- [ ] Poster grids lazy-load and remain scrollable on mobile
