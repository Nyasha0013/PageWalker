const { withRequestContext, applyRateLimit, sendError, blockLikelyBots } = require("./_utils");

module.exports = async (req, res) => {
  const ctx = withRequestContext(req, res, "books");
  if (req.method !== "GET") {
    res.setHeader("Allow", "GET");
    return res.status(405).json({ error: "Method not allowed" });
  }
  if (blockLikelyBots(req, res, ctx)) return;
  if (!applyRateLimit(res, ctx, { windowMs: 60000, max: 90 })) return;
  res.setHeader("Content-Type", "application/json");
  const type = String(req.query?.type || "").trim();
  const googleKey = process.env.GOOGLE_BOOKS_API_KEY || "";
  const toInt = (value, fallback) => {
    const n = Number.parseInt(String(value || ""), 10);
    return Number.isFinite(n) && n >= 0 ? n : fallback;
  };

  const normalizeGoogleBook = (item) => {
    const info = item?.volumeInfo || {};
    const images = info?.imageLinks || {};
    const pubDate = String(info?.publishedDate || "");
    let cover = images?.thumbnail || images?.smallThumbnail || null;
    if (cover) {
      cover = String(cover).replace("http://", "https://").replace("zoom=1", "zoom=3");
    }
    return {
      id: `google_${item?.id || ""}`,
      source: "google",
      title: String(info?.title || "Unknown Title"),
      author: Array.isArray(info?.authors) ? info.authors.join(", ") : String(info?.authors || "Unknown Author"),
      coverUrl: cover,
      description: info?.description || "",
      publishedYear: pubDate.length >= 4 ? pubDate.slice(0, 4) : "",
      publisher: info?.publisher || "",
      genres: Array.isArray(info?.categories) ? info.categories : [],
      googleRating: info?.averageRating ?? null,
    };
  };

  const normalizeOpenLibraryBook = (item) => {
    const key = String(item?.key || "");
    const workId = key.startsWith("/works/") ? key.replace("/works/", "") : "";
    const coverId = item?.cover_i;
    const subject = Array.isArray(item?.subject) ? item.subject : [];
    const authorNames = Array.isArray(item?.author_name) ? item.author_name : [];
    const year = item?.first_publish_year;
    const description =
      typeof item?.first_sentence === "string"
        ? item.first_sentence
        : typeof item?.first_sentence?.value === "string"
          ? item.first_sentence.value
          : "";

    return {
      id: `openlibrary_${workId || Math.random().toString(36).slice(2)}`,
      source: "openlibrary",
      title: String(item?.title || "Unknown Title"),
      author: authorNames.length ? String(authorNames[0]) : "Unknown Author",
      coverUrl: coverId ? `https://covers.openlibrary.org/b/id/${coverId}-L.jpg` : null,
      description,
      publishedYear: year ? String(year) : "",
      publisher: "",
      genres: subject.slice(0, 8),
      googleRating: null,
    };
  };

  const normalizeTitle = (value) =>
    String(value || "")
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, " ")
      .trim();

  const dedupeBooks = (rows) => {
    const seen = new Set();
    const result = [];
    for (let i = 0; i < rows.length; i += 1) {
      const row = rows[i];
      const key = `${normalizeTitle(row?.title)}::${normalizeTitle(row?.author)}`;
      if (!key || seen.has(key)) continue;
      seen.add(key);
      result.push(row);
    }
    return result;
  };

  const scoreBook = (book, searchQuery) => {
    let score = 0;
    if (book?.coverUrl) score += 20;
    if (book?.description) score += 12;
    if (book?.publisher) score += 6;
    if (Array.isArray(book?.genres) && book.genres.length) score += 8;
    if (book?.googleRating) score += Math.min(20, Number(book.googleRating) * 4);

    const year = Number.parseInt(String(book?.publishedYear || ""), 10);
    if (Number.isFinite(year) && year >= 1900) {
      score += Math.min(10, Math.max(0, (year - 1900) / 12));
    }

    if (book?.source === "google") score += 8;
    if (book?.source === "openlibrary") score += 5;

    const q = normalizeTitle(searchQuery);
    if (q) {
      const title = normalizeTitle(book?.title);
      const author = normalizeTitle(book?.author);
      if (title.includes(q)) score += 16;
      if (author.includes(q)) score += 10;
    }
    return score;
  };

  const mergeProviderBooks = (
    googleBooks,
    openLibraryBooks,
    startIndex,
    maxResults,
    searchQuery,
  ) => {
    const offset = Math.max(0, Number(startIndex || 0));
    const limit = Math.max(1, Number(maxResults || 20));
    const combined = dedupeBooks([...googleBooks, ...openLibraryBooks]);
    const scored = combined
      .map((book) => ({ book, score: scoreBook(book, searchQuery) }))
      .sort((a, b) => {
        if (b.score !== a.score) return b.score - a.score;
        const at = normalizeTitle(a?.book?.title);
        const bt = normalizeTitle(b?.book?.title);
        if (at < bt) return -1;
        if (at > bt) return 1;
        const aa = normalizeTitle(a?.book?.author);
        const ba = normalizeTitle(b?.book?.author);
        if (aa < ba) return -1;
        if (aa > ba) return 1;
        return String(a?.book?.id || "").localeCompare(String(b?.book?.id || ""));
      })
      .slice(offset, offset + limit)
      .map((row) => row.book);
    return scored;
  };

  const normalizeGutendexBook = (book) => {
    const formats = book?.formats || {};
    const keys = Object.keys(formats);
    let cover = null;
    for (let i = 0; i < keys.length; i += 1) {
      if (keys[i].includes("image")) {
        cover = String(formats[keys[i]] || "").replace("http://", "https://");
        break;
      }
    }
    const authors = Array.isArray(book?.authors) ? book.authors : [];
    let author = "Unknown Author";
    if (authors.length) {
      const raw = String(authors[0]?.name || "");
      const parts = raw.split(", ");
      author = parts.length >= 2 ? `${parts[1]} ${parts[0]}`.trim() : raw;
    }
    return {
      id: `gutenberg_${book?.id || ""}`,
      source: "gutenberg",
      title: String(book?.title || "Untitled"),
      author,
      coverUrl: cover,
      description: String(book?.summaries?.[0] || ""),
      publishedYear: "",
      publisher: "",
      genres: [],
      googleRating: null,
    };
  };

  try {
    if (type === "classics") {
      res.setHeader("Cache-Control", "s-maxage=1800, stale-while-revalidate=86400");
      const page = Math.max(1, toInt(req.query?.page, 1));
      const classicsRes = await fetch(
        `https://gutendex.com/books?languages=en&copyright=false&page=${page}`,
      );
      const classics = await classicsRes.json();
      return res.status(200).json(classics);
    }

    if (type === "detail") {
      res.setHeader("Cache-Control", "s-maxage=1800, stale-while-revalidate=86400");
      const rawId = String(req.query?.id || "").trim();
      if (!rawId) {
        return res.status(400).json({ error: "Missing book id" });
      }
      if (rawId.startsWith("gutenberg_")) {
        const gutId = encodeURIComponent(rawId.replace("gutenberg_", ""));
        const gutRes = await fetch(`https://gutendex.com/books/${gutId}`);
        if (!gutRes.ok) {
          return res.status(gutRes.status).json({ error: "Book not found" });
        }
        const gutData = await gutRes.json();
        return res.status(200).json(normalizeGutendexBook(gutData));
      }
      if (rawId.startsWith("openlibrary_")) {
        const workId = encodeURIComponent(rawId.replace("openlibrary_", ""));
        const workRes = await fetch(`https://openlibrary.org/works/${workId}.json`);
        if (!workRes.ok) {
          return res.status(workRes.status).json({ error: "Book not found" });
        }
        const workData = await workRes.json();
        const covers = Array.isArray(workData?.covers) ? workData.covers : [];
        const subjects = Array.isArray(workData?.subjects) ? workData.subjects : [];
        const description =
          typeof workData?.description === "string"
            ? workData.description
            : typeof workData?.description?.value === "string"
              ? workData.description.value
              : "";
        let author = "Unknown Author";
        const authors = Array.isArray(workData?.authors) ? workData.authors : [];
        if (authors.length && authors[0]?.author?.key) {
          try {
            const authorRes = await fetch(`https://openlibrary.org${authors[0].author.key}.json`);
            if (authorRes.ok) {
              const authorData = await authorRes.json();
              author = String(authorData?.name || author);
            }
          } catch (_) {
            // Keep fallback author when author lookup fails.
          }
        }
        return res.status(200).json({
          id: `openlibrary_${rawId.replace("openlibrary_", "")}`,
          source: "openlibrary",
          title: String(workData?.title || "Unknown Title"),
          author,
          coverUrl: covers.length ? `https://covers.openlibrary.org/b/id/${covers[0]}-L.jpg` : null,
          description,
          publishedYear: workData?.first_publish_date
            ? String(workData.first_publish_date).slice(0, 4)
            : "",
          publisher: "",
          genres: subjects.slice(0, 8),
          googleRating: null,
        });
      }
      if (!googleKey) {
        return res.status(500).json({ error: "GOOGLE_BOOKS_API_KEY is missing" });
      }
      const googleId = encodeURIComponent(rawId.replace("google_", ""));
      const googleRes = await fetch(
        `https://www.googleapis.com/books/v1/volumes/${googleId}?key=${googleKey}`,
      );
      if (!googleRes.ok) {
        return res.status(googleRes.status).json({ error: "Book not found" });
      }
      const googleData = await googleRes.json();
      return res.status(200).json(normalizeGoogleBook(googleData));
    }

    res.setHeader("Cache-Control", "s-maxage=600, stale-while-revalidate=3600");
    const startIndex = toInt(req.query?.startIndex, 0);
    const maxResults = Math.min(40, Math.max(1, toInt(req.query?.maxResults, 20)));
    const candidateLimit = Math.min(120, startIndex + maxResults * 3);
    if (startIndex > 2000) {
      return res.status(400).json({ error: "startIndex too large" });
    }
    const queryLen = String(req.query?.q || "").trim().length;
    if (type === "search" && (queryLen < 2 || queryLen > 160)) {
      return res.status(400).json({ error: "Search query must be 2-160 characters" });
    }
    const genreLen = String(req.query?.genre || "").trim().length;
    if (type === "genre" && (genreLen < 2 || genreLen > 80)) {
      return res.status(400).json({ error: "Genre must be 2-80 characters" });
    }
    if (type !== "trending" && type !== "genre" && type !== "search") {
      return res.status(400).json({ error: "Invalid books type" });
    }

    const olPage = 1;
    const googleUrlByType = () => {
      if (!googleKey) return "";
      if (type === "trending") {
        return (
          `https://www.googleapis.com/books/v1/volumes` +
          `?q=subject:fiction&orderBy=relevance&startIndex=0&maxResults=${Math.min(40, candidateLimit)}&langRestrict=en&key=${googleKey}`
        );
      }
      if (type === "genre") {
        const genre = encodeURIComponent(String(req.query?.genre || "romance"));
        return (
          `https://www.googleapis.com/books/v1/volumes` +
          `?q=subject:${genre}&orderBy=relevance&startIndex=0&maxResults=${Math.min(40, candidateLimit)}&langRestrict=en&key=${googleKey}`
        );
      }
      const q = encodeURIComponent(String(req.query?.q || ""));
      return (
        `https://www.googleapis.com/books/v1/volumes` +
        `?q=${q}&startIndex=0&maxResults=${Math.min(40, candidateLimit)}&langRestrict=en&key=${googleKey}`
      );
    };

    const openLibraryUrlByType = () => {
      if (type === "trending") {
        return `https://openlibrary.org/subjects/fiction.json?limit=${candidateLimit}&offset=0`;
      }
      if (type === "genre") {
        const genre = encodeURIComponent(String(req.query?.genre || "romance"));
        return `https://openlibrary.org/subjects/${genre}.json?limit=${candidateLimit}&offset=0`;
      }
      const q = encodeURIComponent(String(req.query?.q || ""));
      return `https://openlibrary.org/search.json?q=${q}&limit=${candidateLimit}&page=${olPage}`;
    };

    const [googleRes, olRes] = await Promise.all([
      (async () => {
        const url = googleUrlByType();
        if (!url) return null;
        try {
          const response = await fetch(url);
          if (!response.ok) return null;
          return response.json();
        } catch (_) {
          return null;
        }
      })(),
      (async () => {
        try {
          const response = await fetch(openLibraryUrlByType());
          if (!response.ok) return null;
          return response.json();
        } catch (_) {
          return null;
        }
      })(),
    ]);

    const googleItems = Array.isArray(googleRes?.items) ? googleRes.items : [];
    const googleBooks = googleItems.map(normalizeGoogleBook);

    const olRawRows =
      type === "search"
        ? Array.isArray(olRes?.docs)
          ? olRes.docs
          : []
        : Array.isArray(olRes?.works)
          ? olRes.works
          : [];
    const openLibraryBooks = olRawRows.map(normalizeOpenLibraryBook);

    const searchQuery = type === "search" ? String(req.query?.q || "") : "";
    const books = mergeProviderBooks(
      googleBooks,
      openLibraryBooks,
      startIndex,
      maxResults,
      searchQuery,
    );
    const googleHasMore = Number(googleRes?.totalItems || 0) > startIndex + maxResults;
    const openLibraryTotal = Number(type === "search" ? olRes?.numFound : olRes?.work_count || 0);
    const openLibraryHasMore = openLibraryTotal > startIndex + maxResults;
    const hasMore = googleHasMore || openLibraryHasMore;

    return res.status(200).json({
      books,
      hasMore,
      totalItems: Math.max(Number(googleRes?.totalItems || 0), openLibraryTotal),
      providers: {
        google: googleItems.length,
        openLibrary: olRawRows.length,
      },
    });
  } catch (error) {
    return sendError(res, ctx, 500, "books_proxy_failed", error);
  }
};
