---
name: test-driven-development
description: Use when implementing a new feature with clear expected behavior (checkout flow, booking/availability logic, API endpoint, Flutter widget logic), or when fixing a bug that should never regress. Trigger especially for payment, inventory, availability, or auth-related logic where a silent regression would be costly. Skip for pure UI styling tweaks with no logic.
---

# Test-Driven Development

Not every change needs a test. Use judgment: styling tweaks and copy changes don't need this. Business logic, payment flows, availability/booking logic, and anything that previously broke in production does.

## Workflow

1. Before writing the implementation, write down (in comments or a quick test file) what "correct" means: given input X, expected output Y, including edge cases — empty input, concurrent access, the specific bug that previously occurred.
2. Write a failing test for that expectation first if the project has a test setup. If it doesn't, write the implementation but explicitly verify each case manually and note them in the commit/PR description.
3. Implement.
4. Run the test, confirm it passes, then check it actually fails if you revert the fix (sanity check that the test is testing the right thing).

## Priority areas worth testing even if the rest of the project is untested

- Drop/slot availability logic (Honey Well) — concurrency bugs here are invisible until two customers hit it simultaneously.
- Checkout/payment amount calculations — a silent off-by-rounding-error bug costs real money.
- Auth/RLS-dependent queries — a regression here either breaks access for legitimate users or leaks data, both bad.
- Any Telegram webhook handler — these run unattended with no user-visible feedback if they silently fail.

## Flutter-specific

- Widget logic with conditional rendering (e.g. availability state, loading/error/success states) benefits from a quick widget test covering each state, since these are exactly the cases that get missed in manual testing.
- Prefer testing the underlying logic/provider/controller in isolation over full widget pump tests when the logic is the actual risk, not the rendering.

## When time is tight

If there's no time for a full test suite, at minimum write a short manual test checklist in the PR/commit description: "Tested: empty cart, two simultaneous bookings on same slot, expired session." That's still TDD's actual value — thinking through cases before shipping — even without automated tests.
