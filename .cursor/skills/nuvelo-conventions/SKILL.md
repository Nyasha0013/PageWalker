---
name: nuvelo-conventions
description: Use for any work on nuvelo.one — the Hungary expat classifieds marketplace. Trigger for listing creation/editing, browse/search/filter logic, seller verification, messaging between buyers and sellers, profile/saved listings, or EN/HU localization. Critical for anything involving the Verified seller badge, fraud reporting, or post-an-ad flow — these carry trust and safety weight beyond normal CRUD.
---

# Nuvelo Conventions

Nuvelo is a free classifieds marketplace for Hungary's international community: jobs, rentals, vehicles, electronics, services. Trust and safety matter more here than on a typical CRUD app — users are arranging real-world cash transactions and meetups with strangers.

## Listings (post/browse)

- Listing categories (jobs, rentals, vehicles, electronics, services, etc.) likely have different required fields — don't force a one-size-fits-all form. A rental needs deposit/contract terms; a job listing needs salary/hours; electronics needs condition/serial number capture for the safety-tips guidance already shown to users.
- Location filtering is core to the product ("Select a city or town") — any new listing or search feature should respect the active location filter rather than defaulting to all-Hungary.
- The "SELL" / "Post an ad" flow is the primary conversion action — keep it short. Every required field that isn't load-bearing for safety or search should be reconsidered as optional.

## Verified seller badge — handle with care

The ✅ Verified badge is explicitly described to users as **manually reviewed, never automatic**. Any code touching verification status must preserve that:
- Never auto-grant the badge from a webhook, batch job, or heuristic — it requires a human review step in the data model and UI, even during the MVP period where it's free.
- Misuse/spoofing of the badge is described to users as groundsfor suspension — if building admin tools, make sure there's a clear audit trail of who granted/revoked verification and when.

## Messaging & off-platform risk

The safety guidance explicitly tells users to keep conversations on-platform and flags being pushed to WhatsApp/Telegram before a deal is confirmed as a red flag. Any messaging feature should reinforce this: e.g. don't auto-suggest "continue on WhatsApp" as a convenience feature, and consider surfacing the safety tips contextually (e.g. on first message in a new conversation) rather than only in a separate help page.

## Reporting & disputes

The "Report" button on profiles and the support email fraud-reporting flow (with screenshots) need to capture enough context server-side (listing id, both user ids, timestamp, message thread reference) that support can actually act on it — don't build a report flow that just sends a freeform text email with no structured data attached.

## Localization (EN/HU)

The site is bilingual (EN | HU) with a visible language toggle. Any new user-facing string needs both locales added at the same time — don't ship EN-only copy and treat HU as a follow-up; partially-translated pages look broken to the Hungarian user segment this product specifically targets.

## Theming

Default theme color is a dark indigo (`#0d0a1e`) with a System/Light/Dark toggle exposed in the header — respect the user's selected theme rather than assuming dark-only, and test new components in all three modes.

## Auth

Sign-in supports Google, Facebook, passwordless email link, and SMS code — plus a "Role" selector (Buyer/Tenant/Seller/Agent/Landlord) at sign-in. New features that personalize by role should read this field rather than inferring role from behavior.
