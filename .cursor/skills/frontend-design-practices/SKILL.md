---
name: frontend-design-practices
description: Use whenever editing, redesigning, or building UI/UX for a website or web app — landing pages, dashboards, forms, marketplace listings, e-commerce flows. Trigger this for any request involving layout, spacing, typography, color, visual hierarchy, "make this look better/more professional/less generic," or component styling. Make sure to consult this before touching CSS/Tailwind classes or component markup.
---

# Frontend Design

Goal: ship UI that looks intentional and specific to the product, not like a generic AI-generated template.

## Before changing anything

1. Identify the existing design language already in the codebase (colors, font stack, spacing scale, border-radius values, component library). Read at least 2-3 existing components before adding new ones — match what's there unless explicitly asked to redesign.
2. Identify the product's actual character. A flower shop e-commerce site (Honey Well) should not look like a SaaS dashboard. An expat classifieds marketplace (Nuvelo) needs to feel trustworthy and scannable, not playful.

## Hard rules (avoid generic "AI slop" look)

- **No default purple/blue gradient hero sections.** Pick a palette derived from the product's actual subject matter (flowers → warm/organic tones; classifieds → neutral + one confident accent).
- **No centered-everything layouts** as a default. Real products use asymmetry, left-aligned text blocks, varied card sizes.
- **Type scale**: use no more than 4 font sizes per page. Headings should differ from body by ratio, not just bolding.
- **Spacing**: use a consistent scale (e.g. 4/8/12/16/24/32/48/64px or Tailwind's default scale). Don't eyeball arbitrary px values.
- **Shadows/borders**: pick one elevation style (flat + border, or soft shadow) and use it everywhere. Mixing both reads as unpolished.
- **Buttons**: one primary style, one secondary style, one destructive style. No more.

## Workflow

1. State the design direction in one sentence before writing code ("warm, editorial, generous whitespace, single accent color") so it's a deliberate choice, not a default.
2. Build/edit components with that direction explicit in mind.
3. Check responsiveness at 375px (mobile) and 1280px (desktop) minimum — most of Nuvelo/Honey Well traffic context is mobile-first given Telegram Mini App usage.
4. For forms (checkout, listing creation): label every field, show inline validation errors next to the field (not just at top of form), and disable submit buttons during async actions instead of allowing double-submits.

## Telegram Mini App specific

If the page renders inside a Telegram Mini App webview:
- Respect Telegram's theme params (`window.Telegram.WebApp.themeParams`) for dark/light mode rather than hardcoding a light-only palette.
- Keep tap targets ≥44px — Mini App viewports are touch-only, no hover states to rely on.
- Avoid fixed-height layouts that assume a specific viewport; Telegram's in-app browser height varies by OS and resizes when the keyboard opens.

## When asked to "make it look more professional"

Don't just add shadows and rounded corners. Check, in order: spacing consistency, type hierarchy, color contrast (WCAG AA minimum for text), and whether every interactive element has a clear hover/active/disabled state. Fix those first — that's 80% of what reads as "unprofessional."
