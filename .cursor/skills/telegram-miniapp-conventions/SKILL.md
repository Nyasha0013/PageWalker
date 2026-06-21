---
name: telegram-miniapp-conventions
description: Use for any work on a Telegram Mini App — bot setup, webhook handlers, initData verification, iframe/embedding issues, or UI that renders inside Telegram's in-app browser. Trigger on "Telegram bot," "Mini App," "BotFather," or issues with the app not loading/rendering inside Telegram specifically while working fine in a normal browser.
---

# Telegram Mini App Conventions

## Auth: verifying initData

Never trust `initData` (the user info Telegram passes to the Mini App) without verifying its HMAC signature against the bot token server-side. Treat unverified `initData` as untrusted user input — don't use it to authorize privileged actions (admin reveal, payment confirmation) until verified.

## Embedding / iframe issues

Telegram renders Mini Apps inside a webview/iframe. The recurring failure mode: the app's own security headers block the embed.
- Check `next.config.js` (or hosting platform headers) for `X-Frame-Options: DENY` or a CSP missing `frame-ancestors` — either blocks Telegram from embedding the page at all, producing a blank screen with no obvious client-side error.
- Fix: scope `frame-ancestors` to `https://web.telegram.org` and `https://telegram.org` rather than removing frame protection entirely.

## Theming

Pull `window.Telegram.WebApp.themeParams` and `colorScheme` rather than hardcoding light/dark — Telegram users span both, and a hardcoded light theme looks broken inside a dark-mode Telegram client.

## Viewport

- Call `Telegram.WebApp.expand()` on load if the app needs full height; otherwise it opens in a collapsed half-screen state.
- The viewport height changes when the on-screen keyboard opens (e.g. on a checkout form) — don't use a fixed-height layout assuming a stable viewport; listen to `viewportHeight` changes if precise layout matters.

## Notifications to users (e.g. drop/order reveal messages)

For flows that notify a customer via a bot message when something happens server-side (e.g. a delivery drop being assigned): send via the Bot API from a server context only, never trust the client to "confirm" that a notification should fire — the server action that changes state should be what triggers the message, so the two can't get out of sync.

## Local development

Telegram requires a real HTTPS URL — `localhost` won't work inside the actual Telegram client. Use a tunnel (ngrok or similar) pointed at local dev when testing Mini App behavior that depends on Telegram's webview specifically (theming, initData, viewport events); plain browser testing won't catch those.
