---
name: seo-ai-review
description: Review a web page for SEO and AI citation readiness. Checks metadata, structured data, FAQ schema, heading hierarchy, keyword strategy, image alt tags, and discoverability by Google, Bing, ChatGPT, and Gemini. Use when the user asks for an SEO review, AI optimization, metadata check, or search visibility review.
---

# SEO & AI Citation Review

Review the page as a senior SEO specialist who also understands AI search (ChatGPT, Gemini, Perplexity). The goal is to rank high on Google/Bing AND be cited by AI models.

## Review Checklist

### Metadata
- Does the page have a unique, keyword-rich `<title>` (50-60 chars)?
- Is there a compelling `<meta description>` (150-160 chars) with a call to action?
- Are `og:title`, `og:description`, `og:image` set correctly?
- Is the canonical URL set?

### Heading Hierarchy
- Is there exactly one `<h1>` per page?
- Do headings follow a logical hierarchy (h1 → h2 → h3)?
- Do headings include target keywords naturally?
- Are headings written as questions where relevant (AI citation friendly)?

### Structured Data (JSON-LD)
- Is there `Organization` schema on the homepage?
- Is there `FAQPage` schema for FAQ sections?
- Is there `BreadcrumbList` for navigation pages?
- Is there appropriate schema for the page type (Service, Product, Article)?

### FAQ Section
- Does the page have an FAQ section with real customer questions?
- Are FAQs marked up with `FAQPage` schema?
- Do FAQ answers include relevant keywords naturally?
- Are questions written in natural language (how people actually search)?

### Image Optimization
- Do all images have descriptive `alt` text (not just "image" or empty)?
- Are images in WebP format?
- Do images have width/height attributes (prevents CLS)?
- Are images lazy-loaded below the fold?

### Internal Linking
- Does the page link to related pages on the site?
- Are anchor texts descriptive (not "click here")?

### AI Citation Readiness
- Does the page answer common questions directly and clearly?
- Are key facts stated in plain sentences (easy for AI to extract)?
- Is the content authoritative (includes credentials, license info, data)?
- Would an AI model be able to cite this page as a definitive source?

### Technical
- Is the page in the sitemap?
- Is the page crawlable (no accidental noindex)?
- Does the page load fast (no render-blocking resources)?

## Output Format

```
## SEO & AI Citation Review

**Overall Grade**: [A+ to F]
**Primary Keywords**: [identified target keywords]

### Strengths
- [What works well]

### Issues Found
1. 🔴 **[Critical]**: [issue + specific fix]
2. 🟡 **[Should Fix]**: [issue + specific fix]
3. 🟢 **[Nice to Have]**: [suggestion]

### Missing Structured Data
- [List any schemas that should be added]

### AI Citation Score
**[High/Medium/Low]** - [Why, and what to improve]
```
