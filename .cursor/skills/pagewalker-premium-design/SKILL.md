---
name: pagewalker-premium-design
description: Use whenever redesigning or polishing the visual design of Pagewalker (pagewalker.org) — hero/landing sections, Library shelves, Discover, Social, Clubs, Lists, or profile/book pages. Trigger on "make it look premium/expensive/$1M," "less generic/AI-made," or any request to revamp colors, typography, or layout. This is the design direction to follow instead of defaulting to generic SaaS templates — consult before writing any CSS/component markup for a visual overhaul.
---

# Pagewalker Premium Design Direction

Pagewalker is a book discovery + community product (Goodreads/StoryGraph/Hardcover category) — not an e-reader. There is no in-app page-turning or book-text rendering anywhere in this product; design for shelves, lists, reviews, and social feed, not a reading surface. The design should feel like it belongs to *books* — not like a generic SaaS dashboard that happens to display book covers.

## Adapt patterns, never clone a specific competitor's layout

It's fine — expected — to use the same *functional* patterns every app in this category uses (status shelves, shareable lists, follow/social, percent-match recommendations). These are category-standard, not any one company's invention. What's NOT fine: reproducing a specific competitor's exact page layout, component arrangement, or spacing and just swapping colors — that's still a recognizable clone underneath new paint, since people recognize structure before color. Build every pattern below using Pagewalker's own layout choices (the shelf/spine cards and marginalia rail defined here), not a competitor's component arrangement.

## Avoid the generic-AI defaults

Right now the site reads as generic because it likely falls into one of these clusters — actively design away from them:
1. Warm cream background + high-contrast serif + terracotta accent
2. Near-black background + single neon accent
3. Hairline-rule newspaper/broadsheet grid

## Color system (use these, don't invent new ones mid-build)

- **Ink** `#16140F` — primary dark background. Warm near-black (brown-black, not blue-black or pure neutral).
- **Parchment** `#EFE6D3` — light surface for cards and panels. Deliberately warmer/deeper than the generic AI-cream (#F4F1EA) to avoid looking like the default.
- **Ember** `#D9591A` — primary accent, refined from the existing brand orange (#ff6b1a) into something slightly more burnt/less neon.
- **Moss** `#4B6A52` — secondary accent, reserved for Social and Clubs (gives those surfaces a distinct identity without leaving the palette).
- **Brass** `#B08D4F` — tertiary, used only for dividers, folio numbers, match-score badges, and small structural marks. Never as a large fill — keep it meaningful, not decorative (see the "one accent, one meaning" note below).
- **Ink-soft** `#4A4438` — muted text on Parchment surfaces.

## Typography

- **Display**: Fraunces (variable, high optical size, soft weight) for headlines, book titles, and list names.
- **Body/UI**: a humanist sans that is *not* Inter — Inter is the generic AI default. Use Public Sans or Work Sans instead.
- **Utility/marginalia**: a monospace (IBM Plex Mono or JetBrains Mono) for page counts, percent-match scores, and timestamps — gives a "marginalia" feel, and these numbers genuinely are data, so a distinct face for them is functional, not decorative.

## Layout concept

- **Library**: render shelves (Want to Read / Currently Reading / Read / DNF) as book-spine cards, not a uniform square-card grid — vary height by actual cover aspect ratio so it reads as a real collection.
- **Discover**: recommendation cards use a percent-match badge (in Brass, monospace numerals) plus a one-line "because you finished X" explanation — never an opaque ranked grid.
- **Lists**: user-created lists get their own warm, hand-curated feel — a stack of spine-cards with a short editorial blurb at top, not a generic "playlist" tile.
- **Social**: follow feed and other-readers'-shelves browsing live in Moss, distinct from Library's Ink/Parchment, so the social layer feels like its own space.
- **Clubs**: a shared reading-group bulletin board — visible shared progress for the group, discussion scoped to how far each member has read (avoid spoilers).

## One accent, one meaning

Each accent color should map to exactly one kind of information, the way Brass should mean "trust/score" and nothing else. Don't let an accent drift into decorative use elsewhere on the page — that drift (bright, inconsistent accent use) is the single most common complaint about competitor apps in this exact category.

## Signature element: the marginalia rail

A slim vertical rail running alongside content on Library, Discover, and Lists — showing folio-style running numbers, percent-match ticks, or annotation marks, echoing how real books use margins and running heads. Use this consistently as the one ownable visual signature. Spend the design's "boldness budget" here; keep everything else disciplined and quiet around it.

## Cinematic hero treatment

The homepage hero can use a full-bleed atmospheric scene with subtle motion plus a floating glass stat card — a pattern common on premium SaaS/AI sites. Build it in Pagewalker's own palette and subject matter; do not copy any specific reference site's exact scene or card design.

**Scene**: a small silhouetted figure stands in a Parchment-gold field, facing a vast, billowing cloud formation glowing from within with Ember light — the cloud reads as both sky and softly-folded pages. Color gradient top to bottom: Ink at the very top of frame, fading through a muted brass-red into the glowing Ember underside of the cloud, down to warm Parchment-gold at ground level. The figure is a pure silhouette — no visible face or distinguishing detail — so it reads as "any reader," not a specific person. Style: painterly/illustrated, not photographic — this is a generated/illustrated piece, not a stock photo, both for legal reasons (stock/Pinterest images aren't licensed for site use) and because illustration fits a book platform's storybook quality better than a literal photo. Cloud drifts very slowly — one full pass every 15-20s.

**Floating UI card**: a glass-blur Parchment card in a corner of the hero, showing a real live stat — e.g. "1,204 people reading this week" or a trending book with its percent-match badge in Brass monospace numerals. This is the one place a "live data" moment fits Pagewalker's social/community angle.

**Export**: a single optimized image (WebP, under 300kb) with a subtle CSS Ken Burns pan/zoom for the drift, rather than a video file — keeps load time fast.

**Movement rules**:
- Cloud/light drift: slow, continuous, looping — never abrupt or fast.
- Parallax: background moves slower than foreground text on scroll, capped at 10-15% offset — subtle, not a full parallax scene.
- `prefers-reduced-motion`: serve the static version of the hero image with zero animation.
- Mobile: swap to a smaller static image (no animation) — protects load time and battery for something purely decorative.

**Hard rule**: text must stay legible over the scene at all times. Add a subtle Ink-tinted gradient overlay behind headline text rather than relying on the image being dark enough on its own.

## Restraint check before shipping any screen

- Does every numbered/structural device reflect something real about the content (shelf order, match score, page count), or is it decoration? Keep only the former.
- Mobile down to 375px, visible keyboard focus states, and respect `prefers-reduced-motion` for any hover/reveal animation.
- One signature moment per surface, not five competing ones.
