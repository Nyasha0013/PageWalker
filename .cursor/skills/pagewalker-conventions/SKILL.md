---
name: pagewalker-conventions
description: Use for any work on Pagewalker (pagewalker.org or the companion app) — a book discovery and community platform (Goodreads/StoryGraph/Hardcover category), not an e-book reader. Trigger for features touching shelves/reading status, book clubs, the social/follow feed, lists, reviews, or web-app parity with the mobile app. Important whenever a feature exists in the app and needs a matching web implementation, or vice versa — the product is explicitly "same account, same community" across both.
---

# Pagewalker Conventions

Pagewalker is a book discovery + community product — the same category as Goodreads, StoryGraph, and Hardcover. **Users do not read book text inside Pagewalker.** It's for tracking what you're reading, discovering what to read next, reviewing books, and talking about them with other readers. Don't build an in-app e-reader (no page rendering, no EPUB/PDF viewer) — that's explicitly out of scope.

Five core surfaces: **Library** (the user's shelves), **Discover** (browse/recommendations), **Social** (follow feed), **Clubs** (group reading/discussion), and **Reader** (status tracking — "what page am I on," not the book content itself). Web and app share one account — there is no "web-only" or "app-only" user.

## Cross-platform parity is a product requirement, not a nice-to-have

The product explicitly markets itself as having "the same account, same community, and same reading momentum" across app and web. Before building any feature on one platform, check:
- Does this already exist on the other platform? If so, match its behavior and data model rather than designing a parallel version.
- If this is genuinely new, will the other platform need it soon? Flag the gap rather than letting web and app silently diverge.
- Reading progress, shelves, and club membership must sync immediately across platforms — a user switching from app to web mid-book should land exactly where they left off, not stale state.

## Shelves & reading status (the core of Library)

Every book a user adds gets a status: Want to Read, Currently Reading, Read, or Did Not Finish. This is the backbone data model — get it right before anything else:
- Status changes should be one tap, not a form. Friction here is the #1 complaint about competitors (StoryGraph) being slow.
- Let users mark a book private, friends-only, or public *per book* — not a single global privacy setting. Some books people don't want showing on a public profile.
- Support a Did Not Finish shelf from day one — it's one of the most-requested features across this entire app category and trivial to add now versus retrofitting later.

## Reader (status tracking, not a book viewer)

- "Reader" here means letting a user log what page/percent they're on for a book marked Currently Reading — a simple progress update, not rendering book content. Persist this eagerly on update, since losing someone's logged progress is the worst failure mode for this kind of tracking feature.
- Progress updates should sync immediately across web/app — a user updating on their phone should see it reflected on web instantly, consistent with the one-account model.

## Lists

- Custom, user-created lists (e.g. "Books that wrecked me," "Cozy fantasy") are a core discovery mechanic — let users create, follow, and like other people's lists. This is one of the most differentiating features in this product category; don't treat it as a minor add-on.

## Clubs (group reading)

- Club features likely involve shared pacing (a group reading the same book on a schedule) and discussion tied to specific chapters/pages — avoid spoiler leakage by scoping discussion visibility to reading progress where relevant, rather than showing all club discussion to everyone regardless of how far they've read.
- Club membership and activity should feed into the Social surface consistently — treat Clubs as a specialized view of the social graph, not a fully separate system, to avoid duplicating follow/membership logic.

## Discover / recommendations

- Discovery surfaces should respect what's already in the user's Library (don't recommend books they've already finished or are mid-way through) and should be explainable — a "because you read X" framing is more trustworthy than an opaque recommendation, especially early in the product's life when the catalog/algorithm is less mature.

## Localization

The site exposes English/Magyar (Hungarian) — same bilingual requirement as Nuvelo. Ship both locales together for any new user-facing copy.

## Theming

Brand accent is a warm orange (`#ff6b1a`) — keep new UI consistent with this rather than defaulting to a generic blue/purple AI-template palette (see frontend-design skill for the general principle).
