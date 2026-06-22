const NON_NOVEL_TITLE_RE =
  /\b(dissertation|thesis|doctoral|peer[- ]reviewed|journal article|conference proceedings|technical report|white paper|case study|working paper|annotated bibliography|study guide|teacher'?s guide|solution manual|answer key|lab manual|textbook|workbook|handbook|encyclopedia|dictionary|catalog(?:ue)?|annual report|yearbook|almanac|atlas|directory|index of|bibliography of|introduction to the|introduction to |history of the|guide to |how to |cookbook|manual for)\b/i;

const NON_NOVEL_GENRE_RE =
  /\b(nonfiction|non-fiction|biograph|autobiograph|memoir|true crime|reference|textbook|study guides?|juvenile nonfiction|science(?! fiction)|mathematics|medicine|medical|law\b|legal|business|economics|finance|accounting|political science|social science|technology|engineering|computer|self[- ]help|travel\b|sports|gardening|cookery|cooking|crafts|hobbies|photography|architecture|education|teaching|periodical|magazine|journal|newspaper|essay|essays|poetry|poems|drama(?! fiction)|plays?\b|performing arts|journalism|anthropology|archaeology|psychology|philosophy(?! fiction)|religion|theology|sermon|speech|speeches|catalog|bibliograph|dissertation|thesis|article|handbook|encyclopedia|dictionary|manual\b|report)\b/i;

const FICTION_GENRE_RE =
  /\b(fiction|novel|novels|stories|story|literary|fantasy|romance|mystery|thriller|suspense|horror|science fiction|sci[- ]?fi|historical fiction|adventure|fairy tales?|fables?|mythology|legends?|dystopian|utopian|coming[- ]of[- ]age|juvenile fiction|children'?s fiction|young adult fiction|imaginary|love stories|ghost stories|sea stories)\b/i;

const GUTENDEX_NON_NOVEL_RE =
  /\b(poetry|poems|essay|essays|speech|speeches|sermon|tract|pamphlet|periodical|magazine|dissertation|thesis|catalog|bibliography|dictionary|encyclopedia|handbook|manual|textbook|biograph|autobiograph|music\b|journal|article|plays?\b|drama\b(?!\s+fiction)|science\b(?!\s+fiction)|history\b(?!\s+fiction)|philosophy\b(?!\s+fiction)|religion\b|economics\b|psychology\b)\b/i;

/** Map Discover genre chips to fiction-friendly subject queries. */
const NOVEL_GENRE_ALIASES = {
  history: "historical fiction",
  drama: "fiction",
  "sci-fi": "science fiction",
};

function novelGenreQuery(genre) {
  const raw = String(genre || "").trim().toLowerCase();
  if (!raw) return "fiction";
  return NOVEL_GENRE_ALIASES[raw] || raw;
}

function isNovelLike(book) {
  const title = String(book?.title || "").trim();
  if (!title || NON_NOVEL_TITLE_RE.test(title)) return false;

  const printType = String(book?.printType || "BOOK").toUpperCase();
  if (printType && printType !== "BOOK") return false;

  const genres = Array.isArray(book?.genres) ? book.genres.map((g) => String(g)) : [];
  const genreBlob = genres.join(" | ");

  if (genres.some((g) => NON_NOVEL_GENRE_RE.test(g) && !FICTION_GENRE_RE.test(g))) {
    return false;
  }

  if (genres.some((g) => FICTION_GENRE_RE.test(g))) return true;
  if (/\bfiction\b/i.test(genreBlob)) return true;

  return false;
}

function filterNovels(books) {
  if (!Array.isArray(books)) return [];
  return books.filter(isNovelLike);
}

function isGutendexNovel(book) {
  const title = String(book?.title || "").trim();
  if (!title || NON_NOVEL_TITLE_RE.test(title)) return false;

  const subjects = Array.isArray(book?.subjects) ? book.subjects.map((s) => String(s)) : [];
  const subjectBlob = subjects.join(" | ");

  if (subjects.some((s) => FICTION_GENRE_RE.test(s))) return true;
  if (GUTENDEX_NON_NOVEL_RE.test(subjectBlob) && !FICTION_GENRE_RE.test(subjectBlob)) {
    return false;
  }

  return true;
}

function filterGutendexNovels(results) {
  if (!Array.isArray(results)) return [];
  return results.filter(isGutendexNovel);
}

module.exports = {
  novelGenreQuery,
  isNovelLike,
  filterNovels,
  isGutendexNovel,
  filterGutendexNovels,
};
