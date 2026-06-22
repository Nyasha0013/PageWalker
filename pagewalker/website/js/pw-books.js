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
