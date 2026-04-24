# PageWalker — Build, Backend, and Operations Manual

This document explains **what PageWalker is**, **how the pieces fit together**, and **what was set up from day one** — in plain language. You do not need prior experience with Flutter, Supabase, or Vercel to follow the concepts; technical steps are included where they help you work with vendors (Supabase dashboard, Vercel dashboard, Apple/Google stores).

---

## 1. What PageWalker is

PageWalker is a **reading companion app**: users track books (to-read, reading, finished, did-not-finish), discover titles, write reviews, join **book clubs** with chat and polls, use a **reading timer**, see **achievements** and a **year-in-review (“wrapped”)** style summary, and browse a **community** of readers. There is also a **marketing / web app** at `pagewalker.org` that shares the same **accounts and database** as the mobile app (via Supabase Auth).

The product ships as:

1. **Flutter app** — iOS, Android (and other Flutter targets if enabled). Source lives under `pagewalker/` in the git repository.
2. **Static website + embedded web shell** — HTML, CSS, and JavaScript under `pagewalker/website/`, deployed to **Vercel** so visitors get `pagewalker.org` (or preview URLs).

---

## 2. Glossary (read this once)

| Term | Plain meaning |
|------|----------------|
| **Git / GitHub** | Version control: every change to code is stored in history; GitHub hosts a copy and can trigger deploys. |
| **Repository (repo)** | The PageWalker project folder tracked in git (e.g. the `PageWalker` repo on GitHub). |
| **Flutter** | Google’s UI toolkit used to build the **mobile app** from one codebase (Dart language). |
| **Supabase** | A “backend as a service”: **Postgres database**, **user login (Auth)**, **file storage**, and security rules (**RLS**) in one product. PageWalker uses it as the single source of truth for user data. |
| **Postgres** | A relational database: tables like `profiles`, `user_books`, `reviews` with rows and columns. |
| **RLS (Row Level Security)** | Rules in the database so each user (or the public) can only read/write the rows they are allowed to — critical for privacy. |
| **Anon (public) key** | A **public** API key embedded in the app and website. It is safe to ship **only** with RLS correctly configured. It is **not** a full admin password. |
| **Service role key** | **Secret admin key** — bypasses RLS. Must **never** ship inside the app, website, or public GitHub. Server-only. |
| **Vercel** | Hosting for the **website**: connects to GitHub, builds on every push, serves HTML/JS/CSS globally. |
| **Environment variable** | A named secret (e.g. API URL) stored in a host’s dashboard instead of pasted into public code. |
| **Deploy** | Publishing a new build so users get the latest site or app version. |

---

## 3. Big-picture architecture

```
┌─────────────────┐     ┌─────────────────┐
│  Flutter app    │     │  Web (Vercel)   │
│  iOS / Android  │     │  pagewalker.org │
└────────┬────────┘     └────────┬────────┘
         │                       │
         │   HTTPS + anon key    │
         └───────────┬───────────┘
                     ▼
            ┌────────────────┐
            │    Supabase    │
            │  Auth · DB ·   │
            │  Storage · RLS │
            └────────────────┘
```

- **No custom PageWalker “API server”** is required for the core product: the clients talk **directly** to Supabase with the user’s session.
- **Optional** integrations (when keys are configured): **Google Books** (search/metadata), **OpenAI** (if features use it). These keys stay out of public repos — use local config or secure CI.

---

## 4. Repository layout (what lives where)

| Path | Role |
|------|------|
| `pagewalker/` | Flutter application (`lib/`, `pubspec.yaml`, `android/`, `ios/`, assets). |
| `pagewalker/lib/` | Dart source: screens, repositories, theme, router. |
| `pagewalker/lib/core/config/` | App configuration; **Supabase URL and anon key** are read from `env.dart` (see security note below). |
| `pagewalker/website/` | Static site: `index.html`, `styles.css`, `js/` (e.g. `pw-webapp.js`, Supabase client in browser). |
| `pagewalker/supabase/` | SQL scripts and notes used to evolve the database (run in Supabase SQL editor or via CLI migrations). |
| `supabase/migrations/` | Additional migration-style SQL at repo root (some teams apply these in order). |
| `vercel.json` (repo root) | Tells Vercel the **output folder** is `pagewalker/website` and configures URL rewrites for SPA-style routes. |
| `repo/` | Separate package / experimental app slice (if present); not always required for day-to-day PageWalker mobile work. |

---

## 5. The Flutter mobile app

### 5.1 Technology

- **Language:** Dart  
- **UI:** Flutter widgets  
- **State / DI:** Riverpod (`flutter_riverpod`)  
- **Navigation:** `go_router`  
- **Backend client:** `supabase_flutter`

### 5.2 How the app starts

`pagewalker/lib/main.dart` initializes notifications, **initializes Supabase** (`SupabaseConfig.initialize()`), listens for password recovery events to route to the update-password screen, then runs `PagewalkerApp` with a `ProviderScope`.

### 5.3 Main routes (features)

The router (`pagewalker/lib/core/router/app_router.dart`) wires screens including:

- Splash, onboarding, login / signup / forgot password / update password  
- Shell: **Home**, **Library**, **Discover**, **Social**, **Profile**  
- Book detail, catalog flows, **book search**, **scanner**, **readers** directory, **public profile**  
- **Reading timer**, **achievements**, **yearly wrapped**  
- **Book clubs**: list, create, join, detail, **club chat**, members  
- Legal: privacy, terms  

Each area uses **repositories** under `pagewalker/lib/data/repositories/` to call Supabase (`from('table_name')`).

### 5.4 Running the app locally (developers)

1. Install [Flutter](https://docs.flutter.dev/get-started/install) and a device or emulator.  
2. In a terminal: `cd pagewalker` then `flutter pub get`.  
3. Ensure **valid** Supabase URL and anon key in local `env.dart` (or your team’s documented local setup — **never commit real secrets**).  
4. `flutter run`

If keys are still placeholders, the app may show a warning and auth/data will not work until real values are supplied.

---

## 6. Supabase (the backbone)

### 6.1 What Supabase does for PageWalker

1. **Authentication** — Email/password, magic links, OAuth providers as configured in the Supabase dashboard. Sessions are JWT-based; the Flutter and web clients hold the session after login.  
2. **Database** — Postgres tables hold profiles, books, shelves, reviews, clubs, messages, reading sessions, etc.  
3. **Storage** — e.g. **avatars** bucket for profile photos (see app code uploading to `avatars`).  
4. **Realtime (optional)** — Can be enabled for live features; many flows use standard queries and inserts.

### 6.2 Security model (must understand)

- The **anon key** is public. **All** sensitive access control must be enforced with **RLS policies** on each table that contains user data.  
- **Never** put the **service role** key in the Flutter app, website JS, or a public repo.  
- If a key is ever leaked, **rotate** it in the dashboard and redeploy clients.

### 6.3 Main database tables (conceptual)

These names appear in the Dart codebase; exact columns evolve with migrations:

| Table | Purpose (high level) |
|-------|----------------------|
| `profiles` | Username, display name, bio, avatar URL, visibility flags, etc. |
| `books` | Canonical book records (title, author, cover, identifiers). |
| `user_books` | Per-user shelf row: which book, status (tbr/reading/read/dnf), notes. |
| `reviews` | Text reviews, likes, optional star ratings; may denormalize book title/author for feeds. |
| `follows` | Social graph between users. |
| `reading_sessions` | Timer / session logging for stats and wrapped. |
| `reading_history` | Recent reading activity for diary-style features. |
| `achievements` / `user_achievements` | Badge definitions and unlocks. |
| `book_clubs` | Club metadata. |
| `book_club_members` | Membership. |
| `book_club_messages` | Club chat. |
| `book_club_polls` / `book_club_poll_options` / `book_club_poll_votes` | Polls inside clubs. |
| `book_tags` | Tags used in analytics/wrapped (as implemented). |

New environments (staging, production) need the **same schema** and **RLS** applied. SQL files under `pagewalker/supabase/` and `supabase/migrations/` document incremental changes; your team should keep a **run order** or use Supabase migration tooling so production matches development.

### 6.4 Applying SQL changes

Typical workflow:

1. Write or paste migration SQL in the Supabase **SQL Editor** on a **staging** project first, or use Supabase CLI `db push` if the project uses linked migrations.  
2. Verify RLS: try operations as a test user in the dashboard or app.  
3. Apply the same migration to **production** during a maintenance window if needed.

---

## 7. Website and Vercel

### 7.1 What gets deployed

Vercel serves the contents of **`pagewalker/website`** (see root `vercel.json`: `outputDirectory`). That includes:

- Marketing pages (`index.html`, `about.html`, legal pages, sign-in/up helpers).  
- JavaScript that loads Supabase in the browser and implements the **in-browser app shell** (discover, library, social, profile routes client-side).

### 7.2 URLs and rewrites

`vercel.json` maps paths like `/discover`, `/library`, `/profile` to the main `index.html` so the single-page shell can read the path and render the right view.

### 7.3 Caching

Headers can be set so browsers **revalidate** the HTML shell and pick up new JS after deploys. If you change only JS, a hard refresh or short cache TTL helps users see updates immediately.

### 7.4 Email privacy on the web

The web shell intentionally **does not show full login email** in prominent UI; addresses may be **masked** in profile and menu to reduce accidental exposure in screenshots or recordings. Support contact for account issues is the public **`support@pagewalker.org`** address on the site.

### 7.5 Triggering a production deploy

- **Git integration (recommended):** Pushing to the branch connected to **Production** in Vercel triggers a deploy automatically.  
- **Dashboard:** Vercel project → **Deployments** → **Redeploy** on the latest production deployment.  
- **CLI:** `vercel deploy --prod` from a machine that is logged in (`vercel login`) and **linked** to the project (`.vercel/project.json`). If the link is broken, run `vercel link` again.

If `pagewalker.org` looks “old” but preview looks new, check: **correct Vercel project**, **production branch**, **domain assignment**, and **browser cache**.

---

## 8. Optional third-party APIs

| Service | Used for | Configuration |
|---------|----------|----------------|
| **Google Books** | Search / metadata when enabled | API key from Google Cloud Console; restrict key by bundle ID / HTTP referrer where possible. |
| **OpenAI** | Any AI-assisted features if present in the build | Secret key — server-side or secure storage only; never in client source control. |

The app code checks for placeholder or missing keys and may degrade features gracefully.

---

## 9. Mobile releases (Apple / Google)

- **Android:** `pagewalker/android/` — signing keys in **keystore** files managed outside git; Play Console for rollout.  
- **iOS:** `pagewalker/ios/` — certificates and provisioning via Xcode / App Store Connect.  
- Version **name and build number** live in `pubspec.yaml` (`version: x.y.z+build`).

These steps are vendor-specific; use Apple and Google’s current documentation for submission checklists.

---

## 10. GitHub Actions (smoke checks)

The workflow `.github/workflows/production-smoke.yml` runs on a schedule and when certain paths change. It hits **`https://pagewalker.org`** (or `SMOKE_BASE_URL` secret) with `scripts/smoke-web.sh` to verify the production site responds. This does **not** replace manual QA before releases.

---

## 11. Day-one checklist for a new technical owner

1. **GitHub access** to the PageWalker repository.  
2. **Supabase access** — production (and staging) projects; confirm Auth providers and email templates.  
3. **Vercel access** — team/project; confirm domain `pagewalker.org` and environment variables if any.  
4. **Clone repo**, install Flutter, `flutter pub get` in `pagewalker/`.  
5. **Local Supabase keys** — from Dashboard → Settings → API (URL + anon); store in local `env.dart` or team-approved secret mechanism — **do not commit**.  
6. **Run app** on simulator; sign up a **test user** on staging first.  
7. **Review RLS** on all user tables in Supabase before treating anon key as “safe enough.”  
8. **Optional:** Google Books / OpenAI keys for full feature parity.

---

## 12. Troubleshooting

| Symptom | Things to check |
|---------|------------------|
| App says Supabase not connected | `env.dart` still has `YOUR_…` placeholders or wrong URL. |
| Login works on web but not app (or reverse) | Redirect URLs in Supabase Auth settings; platform-specific deep links (`com.pagewalker.app://…`). |
| 401 / empty data | Session expired; RLS policy blocking read; wrong user id. |
| Site shows old UI | CDN/browser cache; redeploy; verify `Cache-Control` headers. |
| Book clubs empty | Migrations not applied; RLS hiding rows; user not a member. |

---

## 13. Where to get help

- **Supabase:** [supabase.com/docs](https://supabase.com/docs)  
- **Flutter:** [docs.flutter.dev](https://docs.flutter.dev)  
- **Vercel:** [vercel.com/docs](https://vercel.com/docs)  

---

## 14. Document history

| Version | Date | Notes |
|---------|------|-------|
| 1.0 | April 2026 | Initial operations manual generated from repository layout and codebase patterns. |

---

*End of manual.*
