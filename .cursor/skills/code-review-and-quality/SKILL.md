---
name: code-review-and-quality
description: Use before considering a feature "done," before committing, or whenever the user asks to review, clean up, or audit code. Trigger on phrases like "review this," "is this ready," "clean this up," or after generating a non-trivial chunk of new code (>30 lines) — apply this checklist proactively rather than waiting to be asked.
---

# Code Review & Quality

Run this checklist on any non-trivial change before calling it finished.

## Correctness

- Does the happy path actually work end-to-end, not just type-check?
- What happens on the error path — network failure, empty result, malformed input? Silent failures (caught errors that just `console.log` and continue) are a common source of "it doesn't work but no error shows" bugs.
- For anything touching money, inventory, or availability (checkout, drop assignment, slot booking): is there a race condition if two requests hit at once?

## Auth & data exposure

- Does any client-side code reference a secret key, service-role key, or admin-only field?
- Does every new database query that returns user data go through RLS, or explicitly justify why it doesn't (service role + manual auth check)?

## Consistency with the codebase

- Does this match existing naming conventions, file structure, and the Supabase client pattern already in use (see supabase-patterns skill)?
- Don't introduce a new pattern (new state management approach, new folder convention) for a one-off feature — flag it as a suggestion instead of silently diverging.

## Before marking done

- Remove dead code and commented-out blocks from debugging — don't leave them "just in case."
- Check for leftover `console.log` / debug statements in code headed to production.
- If a bug was just fixed, briefly state the root cause in the response (not just "fixed it") so the pattern is recognizable next time it appears elsewhere in the codebase.

## When reviewing someone else's diff (or AI-generated code from earlier in the session)

- Read it as if you didn't write it. Would the intent be clear to someone with no context?
- Check that error messages shown to users are actually useful, not raw stack traces or generic "something went wrong."
