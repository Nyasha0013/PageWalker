---
name: content-review
description: Review a web page for content quality including tone, clarity, brand voice, microcopy, trust signals, and copy errors. Use when the user asks for a content review, copy review, brand voice check, or text quality review.
---

# Content Review

Review the page as a senior content strategist. Focus on clarity, tone, brand consistency, and conversion-oriented copy.

## Before You Start

Ask the user (or infer from context):
- **Brand tone**: What's the desired voice? (e.g., professional, playful, minimalist, bold)
- **Audience**: Who is reading this?
- **Goal**: What should the reader do after reading?

## Review Checklist

### Clarity & Readability
- Is every sentence easy to understand on first read?
- Are paragraphs short (3-4 lines max)?
- Is jargon avoided or explained?
- Is the reading flow logical (problem → solution → proof → action)?

### Brand Consistency
- Does the tone match the company's voice throughout — no sudden shifts?
- Check for tone killers:
  - Exclamation points in professional/trust-building copy (almost never appropriate)
  - Aggressive sales language ("Act NOW!", "Don't miss out!", "Limited time!")
  - Filler phrases that add no value ("We are pleased to...", "It's worth noting that...")

### Formatting Rules
- **Never use em dashes (—)** in web copy. Use regular hyphens (-) or rewrite the sentence. Em dashes look broken on many devices and feel literary, not professional.
- Are headings benefit-oriented (what the reader gets, not what the company does)?
- Are bullet points used for lists instead of dense paragraphs?
- Is there enough white space to make scanning easy?

### Trust Signals
- Is regulatory, certification, or credential information present where needed?
- Are testimonials specific and credible (real details, not "Great service! - John")?
- Is social proof placed near decision points (CTAs), not just at the bottom?

### CTA Destinations
- Do CTAs actually link to the right place? (Sounds obvious — check anyway.)
- Is there a clear primary CTA and a secondary option for people not ready to commit?
- Are button labels action-oriented ("Get Started", "Open Account", not "Submit" or "Click Here")?

### Microcopy
- Are form labels short, clear, and helpful?
- Are error messages helpful, not blaming ("Please enter a valid email" not "Error: invalid input")?
- Do placeholder texts actually help the user (example values, not redundant labels)?

### Numbers, Currencies & Formatting
- Are currency symbols and formats correct and consistent (₪, $, €, £)?
- Are numbers formatted for readability (1,000 not 1000)?
- Are percentages and rates displayed consistently?

### Bilingual / Multilingual Content
- If the page has content in multiple languages — are translations accurate and natural, not machine-translated?
- Is the language toggle easy to find?
- Are names, dates, and numbers formatted correctly for each locale?

### Spelling & Grammar
- Any typos or grammatical errors?
- Are proper nouns capitalized correctly?
- Are acronyms explained on first use?

## Output Format

```
## Content Review

**Overall Grade**: [A+ to F]

### Strengths
- [What works well]

### Issues Found
1. 🔴 **[Critical]**: [issue + suggested rewrite]
2. 🟡 **[Should Fix]**: [issue + suggested rewrite]
3. 🟢 **[Nice to Have]**: [suggestion]

### Suggested Rewrites
| Current | Suggested | Why |
|---------|-----------|-----|
| "..." | "..." | [reason] |
```
