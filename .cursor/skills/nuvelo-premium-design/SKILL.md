---
name: nuvelo-premium-design
description: Use whenever redesigning or polishing the visual design of Nuvelo (nuvelo.one) — hero/landing, browse/listing grid, the Verified seller badge, post-an-ad flow, or search/filter UI. Trigger on "make it look grandeur/premium/expensive/$1M," "less generic," or any request to revamp colors, typography, or layout. Consult before writing any CSS/component markup for a visual overhaul — this is the direction to follow instead of a generic marketplace template.
---

# Nuvelo "Grandeur" Design Direction

Nuvelo is a trust-driven classifieds marketplace for Hungary's international community. The product's whole value proposition is *trust* (the manually-reviewed Verified badge, safety tips, structured reporting) — "grandeur" here should read as institutional confidence and authentication, not generic marketplace flash.

## Avoid the generic-AI defaults

Don't default to a generic blue/teal "marketplace SaaS" look, a single neon accent on near-black, or a hairline-rule broadsheet grid. The site already has a dark indigo theme color (`#0d0a1e`) — build on that existing identity rather than discarding it for a template default.

## Color system

- **Void** `#0D0A1E` — primary background, matches the site's existing theme color. Keep this as the anchor; don't replace it.
- **Indigo-deep** `#1A1530` — secondary surface for cards and panels.
- **Brass-gold** `#C9A227` — primary accent, reserved *exclusively* for trust/verification signals (the Verified badge, "Verified seller" filter, confirmation states). Using it everywhere dilutes its meaning — it should read as a mark of authentication, not a generic brand color.
- **Warm-white** `#F5F2EA` — primary text on dark surfaces and light-mode background.
- **Signal-teal** `#2E8B82` — secondary accent for ordinary CTAs (Post an ad, Search) so gold stays unambiguously tied to trust.
- **Muted-lavender** `#8B85A8` — tertiary, dividers and secondary text only.

## Typography

- **Display**: Spectral or Source Serif 4 for headlines and category headers — an institutional serif that reads as credible/established, distinct from a generic marketplace's default sans-everything look.
- **Body/UI**: a clean grotesque sans (Work Sans or General Sans) for listings, search, and data — never Inter, which is the generic AI default.
- Keep the serif strictly for headlines/category labels; listings data (price, location, condition) should stay in the sans for scannability.

## Layout concept

- Treat the browse grid like an editorial real-estate spread, not a uniform Pinterest-style card grid: give recently-verified or featured listings visibly more weight (larger card, more whitespace around it) rather than treating every listing identically.
- Give the search/location bar real ceremony — it's the primary action on the homepage ("Select a city or town" + search), so it should be the most considered element on the page, not a thin generic input.
- Category pages (jobs/rentals/vehicles/electronics) can each carry a slightly different supporting layout for their distinct required fields, while staying inside the same color/type system — variation within the system, not a different system per category.

## Signature element: the seal

Redesign the ✅ Verified badge into an actual small engraved-look seal (a circular brass-gold mark with fine line detail) rather than a generic checkmark-in-a-circle. Since verification is explicitly described to users as manually reviewed and central to trust on the platform, this is the one element worth real craft — and it's the single most repeated UI element across the whole product (every listing, every profile), so getting it right pays off everywhere. Spend the design's signature "boldness" here; keep surrounding UI disciplined.

## Cinematic hero treatment

The homepage hero can use a full-bleed atmospheric scene with subtle motion plus a floating glass stat card — the same technique covered in the pagewalker-premium-design skill, built here in Nuvelo's own palette and subject matter. Do not copy any specific reference site's exact scene or card design.

**Scene**: dawn breaking over a soft, abstracted skyline silhouette (Budapest-flavored, not a literal photo of a specific landmark) — Brass-gold (`#C9A227`) light low on the horizon, fading up into Void (`#0D0A1E`) at the top of the frame. Slow cloud/light drift, one pass every 15-20s. Generate as a single optimized image (WebP, under 300kb) with a subtle CSS Ken Burns pan/zoom rather than a video file.

**Floating UI card**: a glass-blur Indigo-deep card showing a real live stat tied to trust — e.g. "312 listings verified this week." Brass-gold numerals only, since gold must stay reserved for trust/verification (see "Brass-gold... reserved exclusively for trust/verification signals" above) — never use gold elsewhere on the page just because it appears in the hero.

**Movement rules**: identical to Pagewalker's — slow continuous drift, parallax capped at 10-15% offset, static fallback for `prefers-reduced-motion`, static smaller image on mobile (no animation there).

**Hard rule**: text must stay legible at all times — add a subtle Void-tinted gradient overlay behind headline text rather than relying on the image being dark enough on its own.

## Restraint check before shipping any screen

- Is brass-gold appearing anywhere that isn't a trust/verification signal? If so, pull it back to teal or remove it.
- Mobile down to 375px (most traffic context), visible keyboard focus, `prefers-reduced-motion` respected for any hover/reveal animation.
- EN/HU copy shipped together — see the nuvelo-conventions skill for localization handling.
