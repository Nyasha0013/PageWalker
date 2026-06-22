# QA web account (shared checker login)

Use a **dedicated** Pagewalker account for smoke tests, Play Console app access, and agent/manual QA — not a personal reading account.

## Create the account (once)

1. Supabase Dashboard → **Authentication** → **Users** → **Add user**
2. Email: `qa-checker@pagewalker.org` (or another address you control)
3. Password: strong random value (password manager)
4. Enable **Auto confirm user** so email verification is not required

The account is a normal user. RLS applies the same as any member — no service role in the browser.

## Store credentials (never in git)

| Where | Variables |
|-------|-----------|
| Local | `.env.local` → `PAGEWALKER_QA_EMAIL`, `PAGEWALKER_QA_PASSWORD` |
| Vercel (Preview only) | Same names if you want automated checks on preview deploys |
| Play Console → App access | Same email + password for Google reviewers |

Add to `.gitignore` (already): `.env`, `.env.*`, `.env.local`

## Sign in on the site

https://pagewalker.org/sign-in — same email/password as the Android app.

## Rotate if exposed

If the password appears in chat, logs, or a commit: change it in Supabase immediately and update env vars / Play Console.
