---
name: ux-design-review
description: Review a web page for UX and design quality. Checks layout, mobile responsiveness, above-the-fold content, CTAs, accessibility, visual hierarchy, and touch targets. Use when the user asks for a UX review, design review, layout check, or mobile review.
---

# UX / Design Review

Review the page as a senior UX designer. Be specific and actionable — give grades and concrete fixes, not vague praise.

## Review Checklist

### Above the Fold
- Is the value proposition immediately clear?
- Is there a visible CTA without scrolling (desktop AND mobile — check both)?
- Does the hero section load fast and look clean?

### Layout & Visual Hierarchy
- Is there a clear visual flow guiding the eye?
- Are sections properly spaced (not cramped, not too airy)?
- Is the information hierarchy correct (headings, subheadings, body)?
- Are related elements grouped logically?

### CTAs (Calls to Action)
- Is the primary CTA obvious and prominent?
- Is there a clear visual distinction between primary and secondary CTAs?
- Are CTAs placed at **natural decision points** — after trust signals, after benefits, after objection handling? (Not just at the top and bottom.)
- Do CTA labels use action words ("Get Started", "Open Account", not "Submit")?

### Form & Data Entry Trust
If the page has forms that ask for sensitive information (financial, personal, health):
- Does the form feel safe? Are there trust signals near the input fields?
- Is the amount of data requested proportional to the stage? (Don't ask for everything upfront.)
- Are multi-step forms broken into logical steps with progress indicators?

### Mobile Responsiveness
- Does the layout work well on mobile (375px)?
- Are touch targets at least 44x44px with adequate spacing?
- Is text readable without zooming?
- Do images scale properly?
- Is the hamburger menu intuitive?

### Accessibility
- Are `aria-label`, `aria-expanded`, and roles used correctly?
- Is there sufficient color contrast (WCAG 2.1 AA)?
- Can the page be navigated by keyboard?
- Do images have meaningful alt text?

### Image Quality
- Are images high quality originals — not compressed screenshots, chat uploads, or low-res placeholders?
- Are images served in WebP format for performance?
- If images look blurry or pixelated, flag it. Source files should come from original assets (design tools, Drive, asset library), never from chat messages or screenshots.

### Loading & Empty States
- Are loading states handled (skeletons for content, spinners for actions)?
- Are empty states friendly and have a clear next step?
- If data fails to load, is there a helpful error state (not a blank page)?

## Output Format

```
## UX / Design Review

**Overall Grade**: [A+ to F]

### Strengths
- [What works well]

### Issues Found
1. 🔴 **[Critical]**: [issue + specific fix]
2. 🟡 **[Should Fix]**: [issue + specific fix]
3. 🟢 **[Nice to Have]**: [suggestion]

### Mobile-Specific Issues
- [Any mobile-only problems]
```
