const BOOK_API_CACHE = new Map();
const DEFAULT_BOOK_CACHE_MS = 5 * 60 * 1000;

export const BOOK_SOURCE_LABELS = {
  google: "Google Books",
  openlibrary: "Open Library",
  gutenberg: "Project Gutenberg",
};

export function inferBookSource(book) {
  const explicit = String(book?.source || "").trim().toLowerCase();
  if (explicit && BOOK_SOURCE_LABELS[explicit]) return explicit;
  const id = String(book?.id || "");
  if (id.startsWith("google_")) return "google";
  if (id.startsWith("openlibrary_")) return "openlibrary";
  if (id.startsWith("gutenberg_")) return "gutenberg";
  return explicit || "catalog";
}

export function bookSourceLabel(source) {
  return BOOK_SOURCE_LABELS[source] || "Catalog";
}

export function renderBookSourceBadge(book, t) {
  const source = inferBookSource(book);
  const label =
    typeof t === "function"
      ? t(`route.discover.source.${source}`, bookSourceLabel(source))
      : bookSourceLabel(source);
  return `<span class="pw-source-badge pw-source-badge--${source}" title="${label}">${label}</span>`;
}

export function filterBooksBySource(books, filter) {
  const f = String(filter || "all").toLowerCase();
  if (f === "all") return books;
  return books.filter((book) => inferBookSource(book) === f);
}

export async function fetchJsonCached(url, ttlMs = DEFAULT_BOOK_CACHE_MS) {
  const key = String(url);
  const now = Date.now();
  const hit = BOOK_API_CACHE.get(key);
  if (hit && hit.expiresAt > now) {
    return hit.data;
  }
  const response = await fetch(url, { credentials: "same-origin" });
  if (!response.ok) throw new Error(`request_failed_${response.status}`);
  const data = await response.json();
  BOOK_API_CACHE.set(key, { data, expiresAt: now + ttlMs });
  return data;
}

export function prefetchBookApi(url) {
  fetchJsonCached(url).catch(() => {});
}

export function posterGridSkeleton(count = 8) {
  return Array.from({ length: count })
    .map(
      () =>
        `<article class="pw-poster-card pw-poster-card--skeleton"><div class="pw-poster-media pw-shimmer-block"></div><div class="pw-poster-copy"><div class="pw-shimmer-line"></div><div class="pw-shimmer-line short"></div></div></article>`,
    )
    .join("");
}

/** Split catalog descriptions into readable paragraphs (keeps breaks from HTML). */
export function formatBookDescriptionParagraphs(value) {
  let s = String(value || "");
  if (!s.trim()) return [];

  s = s
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<\/p>\s*/gi, "\n\n")
    .replace(/<\/div>\s*/gi, "\n\n")
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&lt;/gi, "<")
    .replace(/&gt;/gi, ">")
    .replace(/&quot;/gi, '"')
    .replace(/&#39;/gi, "'")
    .replace(/\r\n/g, "\n")
    .replace(/\r/g, "\n");

  const chunks = s
    .split(/\n{2,}/)
    .map((part) => part.replace(/\s+/g, " ").trim())
    .filter(Boolean);

  if (chunks.length > 1) return chunks;

  const single = chunks[0] || s.replace(/\s+/g, " ").trim();
  if (!single) return [];

  if (single.length <= 320) return [single];

  return single
    .split(/(?<=[.!?])\s+(?=[A-Z"“])/)
    .map((part) => part.trim())
    .filter((part) => part.length > 20)
    .slice(0, 8);
}

function escapeHtml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

export function renderBookAboutSection(raw, opts = {}) {
  const title = opts.title || "About this book";
  const emptyText = opts.emptyText || "No description yet.";
  const paragraphs = formatBookDescriptionParagraphs(raw);

  if (!paragraphs.length) {
    return `<article class="app-panel pw-book-about">
      <h3>${escapeHtml(title)}</h3>
      <p class="pw-book-about__empty muted">${escapeHtml(emptyText)}</p>
    </article>`;
  }

  const body = paragraphs.map((p) => `<p>${escapeHtml(p)}</p>`).join("");
  const long = paragraphs.join(" ").length > 420 || paragraphs.length > 2;

  if (!long) {
    return `<article class="app-panel pw-book-about">
      <h3>${escapeHtml(title)}</h3>
      <div class="pw-book-about__body">${body}</div>
    </article>`;
  }

  return `<article class="app-panel pw-book-about">
    <h3>${escapeHtml(title)}</h3>
    <details class="pw-book-about__details">
      <summary class="pw-book-about__toggle">Read full description</summary>
      <div class="pw-book-about__body pw-book-about__body--clamped">${body}</div>
    </details>
  </article>`;
}
