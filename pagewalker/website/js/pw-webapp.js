import { getSupabase } from "./pw-supabase.js";
import { initUserMenu } from "./pw-user-menu.js";
import { closeAuthNudge, guardAuthAction } from "./pw-auth-nudge.js";
import { initHomeHeroParallax } from "./pw-hero.js";
import { initScrollReveal } from "./pw-scroll-reveal.js";
import {
  BOOK_SOURCE_LABELS,
  fetchJsonCached,
  filterBooksBySource,
  formatBookDescriptionParagraphs,
  inferBookSource,
  posterGridSkeleton,
  prefetchBookApi,
  renderBookAboutSection,
  renderBookSourceBadge,
} from "./pw-books.js";

const APP_ROUTES = new Set([
  "/",
  "/book",
  "/explore",
  "/discover",
  "/library",
  "/social",
  "/clubs",
  "/club",
  "/reader",
  "/profile",
]);
/** Canonical browse route (Discover + Search merged). /discover redirects here. */
const EXPLORE_PATH = "/explore";
const LEGACY_DISCOVER_PATH = "/discover";
/* /discover is public so guests can browse; library actions use auth nudge. */
const PROTECTED_ROUTES = new Set([
  "/library",
  "/social",
  "/clubs",
  "/club",
  "/reader",
  "/profile",
]);
const LIBRARY_STATUSES = ["tbr", "reading", "read", "dnf"];
const DISCOVER_PAGE_SIZE = 12;
const LIBRARY_PAGE_SIZE = 24;
const STATUS_LABELS = {
  tbr: "TBR",
  reading: "Reading",
  read: "Read",
  dnf: "DNF",
};
let discoverQuery = "";
let discoverGenre = "romance";
let discoverMood = "";
let discoverSourceFilter = "all";
const _discoverPanelBooks = { trending: [], genre: [], search: [], classics: [] };
const DISCOVER_MOOD_PRESETS = ["Make me cry", "Dark & twisted", "Cozy", "Slow burn", "Magic", "Mystery"];
let libraryFilter = "all";
let discoverPaging = {
  trendingPage: 1,
  genrePage: 1,
  searchPage: 1,
  classicsPage: 1,
};
let libraryPage = 1;
let socialDraft = { title: "", body: "", rating: "5" };
let socialComposerExpanded = false;
let bookPageReviewPanelOpen = false;
let clubsDraft = { name: "", description: "", inviteCode: "", emoji: "📚", maxMembers: "20" };
let readerTimer = {
  running: false,
  startedAtMs: null,
  elapsedSeconds: 0,
};
let readerTicker = null;

function t(key, fallback) {
  if (window.pwT) return window.pwT(key, fallback);
  return fallback || key;
}

function showBanner(type, text) {
  const err = document.getElementById("pw-err");
  const ok = document.getElementById("pw-ok");
  if (type === "error") {
    if (ok) ok.hidden = true;
    if (err) {
      err.hidden = false;
      err.className = "pw-banner pw-banner--error";
      err.textContent = text;
    }
    return;
  }
  if (err) err.hidden = true;
  if (ok) {
    ok.hidden = false;
    ok.className = "pw-banner pw-banner--success";
    ok.textContent = text;
  }
}

function hideBanners() {
  const err = document.getElementById("pw-err");
  const ok = document.getElementById("pw-ok");
  if (err) err.hidden = true;
  if (ok) ok.hidden = true;
}

function ensureAppPath() {
  if (window.location.pathname === LEGACY_DISCOVER_PATH) {
    const hash = String(window.location.hash || "").replace(/^#hub$/, "");
    window.history.replaceState({}, "", EXPLORE_PATH + window.location.search + hash);
  }
  const current = window.location.pathname;
  if (APP_ROUTES.has(current)) return;
  window.history.replaceState({}, "", "/");
}

function isExploreRoute(path = window.location.pathname) {
  return path === EXPLORE_PATH || path === LEGACY_DISCOVER_PATH;
}

const EXPLORE_TAB_IDS = ["trending", "genre", "classics", "search"];

/** No hash → Search (default Explore view). */
function getExploreView() {
  const raw = String(window.location.hash || "").replace(/^#/, "");
  if (!raw || raw === "hub") return "search";
  if (EXPLORE_TAB_IDS.includes(raw)) return raw;
  return "search";
}

/** @deprecated use getExploreView */
function getDiscoverView() {
  return getExploreView();
}

let _lastNavRouteForDiscover = null;

function setActiveRoute(route) {
  const mainLinks = document.querySelectorAll("a.pw-drawer__item[data-link-route]");
  for (let i = 0; i < mainLinks.length; i += 1) {
    const href = mainLinks[i].getAttribute("data-link-route");
    mainLinks[i].toggleAttribute("data-active", href === route);
  }
  const discoverGroup = document.getElementById("pw-drawer-discover");
  if (discoverGroup) {
    discoverGroup.toggleAttribute("data-nav-active", isExploreRoute(route));
    if (discoverGroup instanceof HTMLDetailsElement) {
      if (isExploreRoute(route) && _lastNavRouteForDiscover !== EXPLORE_PATH) {
        discoverGroup.open = true;
      } else if (!isExploreRoute(route)) {
        discoverGroup.open = false;
      }
    }
  }
  _lastNavRouteForDiscover = route;
  const discoverJumpLinks = document.querySelectorAll("a.pw-drawer__sublink, a.pw-discover-tablink, a[data-bottom-nav]");
  const v = getDiscoverView();
  for (let i = 0; i < discoverJumpLinks.length; i += 1) {
    const el = discoverJumpLinks[i];
    const jump = el.getAttribute("data-discover-jump") || "";
    const navRoute = el.getAttribute("data-link-route") || "";
    const bottomNav = el.getAttribute("data-bottom-nav") || "";
    let active = false;
    if (bottomNav === "home") active = route === "/";
    else if (bottomNav === "library") active = route === "/library";
    else if (bottomNav === "explore") active = isExploreRoute(route) && v === "search";
    else if (bottomNav === "trending") active = isExploreRoute(route) && v === "trending";
    else if (bottomNav === "social") active = route === "/social";
    else if (jump) active = isExploreRoute(route) && jump === v;
    else active = navRoute === route;
    el.toggleAttribute("data-active", active);
  }
  const otherNav = document.querySelectorAll(
    "[data-link-route]:not(a.pw-drawer__item):not(a.pw-drawer__sublink):not(a.pw-discover-tablink):not(a.pw-discover-hub-card):not(a[data-bottom-nav])",
  );
  for (let i = 0; i < otherNav.length; i += 1) {
    const path = otherNav[i].getAttribute("data-link-route");
    otherNav[i].toggleAttribute("data-active", path === route);
  }
  document.body.classList.toggle("pw-has-bottom-nav", true);
}

/** Each Discover tab uses its own backdrop (see assets/*.png sources). */
const DISCOVER_SCENE_BASE = {
  hub: "discover-sky",
  search: "discover-sky",
  trending: "trending-beach",
  genre: "discover-sky",
  classics: "discover-sky",
};

const FIXED_BACKDROP_SCENES = {
  home: { base: "hero-book-cloud", overlay: "home" },
  discoverSky: { base: "discover-sky", overlay: "discover" },
  libraryWalk: { base: "library-walk", overlay: "library" },
};

/** Body-level photo backdrops per route (guest home keeps its inline hero). */
const ROUTE_IMMERSIVE = {
  "/": { when: "signed-in", scene: "home" },
  "/explore": { when: "always", dynamic: true },
  "/library": { when: "always", scene: "libraryWalk" },
  "/social": { when: "signed-in", scene: "discoverSky" },
  "/clubs": { when: "signed-in", scene: "libraryWalk" },
  "/club": { when: "signed-in", scene: "libraryWalk" },
  "/reader": { when: "signed-in", scene: "libraryWalk" },
  "/profile": { when: "signed-in", scene: "home" },
};

function sceneAssets(sceneKey) {
  const scene = FIXED_BACKDROP_SCENES[sceneKey];
  if (!scene) return null;
  return {
    src: `/assets/${scene.base}.png`,
    mobileSrc: `/assets/${scene.base}-mobile.png`,
    overlay: scene.overlay,
  };
}

function routeUsesImmersiveBackdrop(route, session) {
  const cfg = ROUTE_IMMERSIVE[route];
  if (!cfg) return false;
  if (cfg.when === "always") return true;
  return Boolean(session?.user);
}

function applyImmersiveBodyClasses(route, session) {
  const signedIn = Boolean(session?.user);
  const isGuestHome = route === "/" && !signedIn;
  const immersive = routeUsesImmersiveBackdrop(route, session);
  const cfg = ROUTE_IMMERSIVE[route];

  document.body.classList.remove(
    "pw-home-immersive",
    "pw-home-dashboard-immersive",
    "pw-discover-immersive",
    "pw-library-immersive",
    "pw-app-immersive",
  );

  if (isGuestHome) {
    document.body.classList.add("pw-home-immersive");
    return;
  }
  if (!immersive) return;

  if (route === "/" && signedIn) {
    document.body.classList.add("pw-home-immersive", "pw-home-dashboard-immersive");
    return;
  }
  if (route === EXPLORE_PATH) {
    document.body.classList.add("pw-discover-immersive");
    return;
  }
  if (route === "/library") {
    document.body.classList.add("pw-library-immersive");
    return;
  }

  document.body.classList.add("pw-app-immersive");
  const overlay = cfg?.scene ? FIXED_BACKDROP_SCENES[cfg.scene]?.overlay : null;
  if (overlay === "discover") document.body.classList.add("pw-discover-immersive");
  else if (overlay === "library") document.body.classList.add("pw-library-immersive");
  else if (overlay === "home") {
    document.body.classList.add("pw-home-immersive", "pw-home-dashboard-immersive");
  }
}

function discoverSceneSrc(view) {
  const base = DISCOVER_SCENE_BASE[view] || DISCOVER_SCENE_BASE.hub;
  return `/assets/${base}.png`;
}

function discoverSceneMobileSrc(view) {
  const base = DISCOVER_SCENE_BASE[view] || DISCOVER_SCENE_BASE.hub;
  return `/assets/${base}-mobile.png`;
}

function immersiveBackdropPicture(src, mobileSrc, width, height) {
  return `
    <picture class="pw-hero-scene__picture">
      <source id="pw-immersive-scene-mobile" media="(max-width: 860px)" srcset="${mobileSrc}" />
      <img
        id="pw-immersive-scene-media"
        class="pw-hero-scene__media"
        src="${src}"
        alt=""
        width="${width}"
        height="${height}"
        decoding="async"
        fetchpriority="low"
      />
    </picture>
  `;
}

function updateImmersiveBackdropMedia(src, mobileSrc) {
  const media = document.getElementById("pw-immersive-scene-media");
  const mobile = document.getElementById("pw-immersive-scene-mobile");
  if (media && media.getAttribute("src") !== src) media.setAttribute("src", src);
  if (mobile && mobile.getAttribute("srcset") !== mobileSrc) mobile.setAttribute("srcset", mobileSrc);
}

function syncDiscoverSceneView() {
  if (!isExploreRoute()) {
    delete document.body.dataset.discoverView;
    return;
  }
  document.body.dataset.discoverView = getDiscoverView();
}

function syncImmersiveBackdrop(route, session) {
  const el = document.getElementById("pw-immersive-backdrop");
  if (!el) return;

  if (route === "/" && !session?.user) {
    el.hidden = true;
    el.innerHTML = "";
    el.removeAttribute("data-mode");
    delete el.dataset.discoverView;
    return;
  }

  if (!routeUsesImmersiveBackdrop(route, session)) {
    el.hidden = true;
    el.innerHTML = "";
    el.removeAttribute("data-mode");
    delete el.dataset.discoverView;
    return;
  }

  if (route === "/library") {
    const assets = sceneAssets("libraryWalk");
    el.hidden = false;
    if (el.dataset.mode === "library" && el.querySelector("#pw-immersive-scene-media")) {
      delete el.dataset.discoverView;
      updateImmersiveBackdropMedia(assets.src, assets.mobileSrc);
      return;
    }
    el.dataset.mode = "library";
    delete el.dataset.discoverView;
    el.innerHTML = `
      <div class="pw-immersive-scene" aria-hidden="true">
        ${immersiveBackdropPicture(assets.src, assets.mobileSrc, 576, 1024)}
      </div>
      <div class="pw-immersive-overlay pw-immersive-overlay--library" aria-hidden="true"></div>
    `;
    return;
  }

  if (route === EXPLORE_PATH) {
    const view = getDiscoverView();
    const src = discoverSceneSrc(view);
    const mobileSrc = discoverSceneMobileSrc(view);
    el.hidden = false;
    el.dataset.mode = "discover";
    el.dataset.discoverView = view;
    if (el.querySelector("#pw-immersive-scene-media")) {
      updateImmersiveBackdropMedia(src, mobileSrc);
      return;
    }
    el.innerHTML = `
      <div class="pw-immersive-scene" aria-hidden="true">
        ${immersiveBackdropPicture(src, mobileSrc, 573, 1024)}
      </div>
      <div class="pw-immersive-overlay pw-immersive-overlay--discover" aria-hidden="true"></div>
    `;
    return;
  }

  const cfg = ROUTE_IMMERSIVE[route];
  const assets = cfg?.scene ? sceneAssets(cfg.scene) : null;
  if (!assets) {
    el.hidden = true;
    el.innerHTML = "";
    el.removeAttribute("data-mode");
    delete el.dataset.discoverView;
    return;
  }

  const mode = cfg.scene;
  el.hidden = false;
  el.dataset.mode = mode;
  delete el.dataset.discoverView;
  if (el.querySelector("#pw-immersive-scene-media")) {
    updateImmersiveBackdropMedia(assets.src, assets.mobileSrc);
    return;
  }
  el.innerHTML = `
    <div class="pw-immersive-scene" aria-hidden="true">
      ${immersiveBackdropPicture(assets.src, assets.mobileSrc, 576, 1024)}
    </div>
    <div class="pw-immersive-overlay pw-immersive-overlay--${assets.overlay}" aria-hidden="true"></div>
  `;
}

function applyDiscoverPanelFromHash() {
  const root = document.getElementById("pw-discover-root");
  if (!root) return;
  const view = getDiscoverView();
  root.setAttribute("data-pw-active", view);
  syncDiscoverSceneView();
  updateImmersiveBackdropMedia(discoverSceneSrc(view), discoverSceneMobileSrc(view));
  const backdrop = document.getElementById("pw-immersive-backdrop");
  if (backdrop?.dataset.mode === "discover") {
    backdrop.dataset.discoverView = view;
  }
  window.scrollTo({ top: 0, behavior: "smooth" });
}

function markRouteRevealBlocks(root) {
  if (!root || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

  const blockSelectors = [
    ".pw-dashboard-head",
    ".pw-dash-card",
    ".pw-discover-title",
    ".pw-discover-page__lede",
    ".pw-discover-tabstrip",
    ".pw-library-page",
    ".pw-profile-hero",
    ".pw-profile-tabs",
    ".pw-profile-panel > section",
    ".pw-profile-panel > form",
    ".pw-social-composer",
    ".pw-social-feed__heading",
    ".pw-club-browse__title",
    ".pw-club-lede",
    "section.app-panel article.app-panel",
  ];

  for (let s = 0; s < blockSelectors.length; s += 1) {
    const nodes = root.querySelectorAll(blockSelectors[s]);
    for (let i = 0; i < nodes.length; i += 1) {
      const el = nodes[i];
      if (!el.hasAttribute("data-reveal")) el.setAttribute("data-reveal", "");
    }
  }

  const lonePanel = root.querySelector(":scope > section.app-panel");
  if (lonePanel && !lonePanel.hasAttribute("data-reveal")) {
    lonePanel.setAttribute("data-reveal", "");
  }

  const staggerSelectors = [
    ".pw-poster-grid",
    ".pw-home-scroll",
    ".app-grid.app-grid-3",
    ".pw-review-feed",
    ".pw-club-browse-grid",
    ".pw-home-pillars",
  ];
  for (let s = 0; s < staggerSelectors.length; s += 1) {
    const nodes = root.querySelectorAll(staggerSelectors[s]);
    for (let i = 0; i < nodes.length; i += 1) {
      const el = nodes[i];
      if (!el.hasAttribute("data-reveal-stagger")) el.setAttribute("data-reveal-stagger", "");
    }
  }
}

function escapeHtml(value) {
  return String(value || "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

/** Masks sign-in email in public UI (hero badge, profile) — full address stays in Supabase only. */
function maskEmailForDisplay(email) {
  const e = String(email || "").trim();
  if (!e) return "—";
  const at = e.indexOf("@");
  if (at < 1) return e;
  const local = e.slice(0, at);
  const domain = e.slice(at + 1);
  if (local.length <= 2) {
    return `${local[0] || "•"}•••@${domain}`;
  }
  return `${local[0]}•••${local[local.length - 1]}@${domain}`;
}

const MAX_PROFILE_AVATAR_BYTES = 2 * 1024 * 1024;
const AVATAR_STORAGE_KEY = (userId) => `avatar_${userId}.jpg`;

async function imageFileToJpegBlobIfNeeded(file) {
  if (file.type === "image/jpeg") return file;
  const objectUrl = URL.createObjectURL(file);
  try {
    const img = new Image();
    img.decoding = "async";
    await new Promise((resolve, reject) => {
      img.onload = () => resolve();
      img.onerror = () => reject(new Error("image_decode"));
      img.src = objectUrl;
    });
    const maxEdge = 512;
    let w = img.naturalWidth;
    let h = img.naturalHeight;
    if (w < 1 || h < 1) throw new Error("image_decode");
    if (w > maxEdge || h > maxEdge) {
      const r = Math.min(maxEdge / w, maxEdge / h);
      w = Math.round(w * r);
      h = Math.round(h * r);
    }
    const canvas = document.createElement("canvas");
    canvas.width = w;
    canvas.height = h;
    const ctx = canvas.getContext("2d");
    if (!ctx) throw new Error("canvas");
    ctx.drawImage(img, 0, 0, w, h);
    const blob = await new Promise((resolve, reject) => {
      canvas.toBlob(
        (b) => (b ? resolve(b) : reject(new Error("toBlob"))),
        "image/jpeg",
        0.85,
      );
    });
    return blob;
  } finally {
    URL.revokeObjectURL(objectUrl);
  }
}

function setProfilePhotoStatus(text, isError) {
  const el = document.getElementById("pw-profile-photo-status");
  if (!el) return;
  el.textContent = text || "";
  el.hidden = !text;
  if (isError) el.setAttribute("data-state", "error");
  else el.removeAttribute("data-state");
}

function bindProfilePhotoActions(supabase, onAfterChange) {
  const fileInput = document.getElementById("pw-profile-photo-file");
  const pickBtn = document.getElementById("pw-profile-photo-pick");
  const removeBtn = document.getElementById("pw-profile-photo-remove");
  if (!fileInput || !pickBtn) return;

  pickBtn.addEventListener("click", () => {
    setProfilePhotoStatus("", false);
    fileInput.click();
  });

  fileInput.addEventListener("change", async () => {
    const file = fileInput.files?.[0];
    fileInput.value = "";
    if (!file) return;
    const allowed = new Set(["image/jpeg", "image/png", "image/webp"]);
    if (!allowed.has(file.type)) {
      setProfilePhotoStatus(
        t("route.profile.photoTypeError", "Please choose a JPG, PNG, or WebP image."),
        true,
      );
      return;
    }
    if (file.size > MAX_PROFILE_AVATAR_BYTES) {
      setProfilePhotoStatus(t("route.profile.photoSizeError", "Image must be 2 MB or smaller."), true);
      return;
    }
    const { data: sessData, error: sessErr } = await supabase.auth.getSession();
    if (sessErr) {
      setProfilePhotoStatus(sessErr.message, true);
      return;
    }
    const user = sessData?.session?.user;
    if (!user) {
      setProfilePhotoStatus(t("route.authRequired", "Please sign in to view this section."), true);
      return;
    }
    pickBtn.disabled = true;
    if (removeBtn) removeBtn.disabled = true;
    setProfilePhotoStatus(t("route.profile.photoUploading", "Uploading…"), false);
    try {
      const blob = await imageFileToJpegBlobIfNeeded(file);
      if (blob.size > MAX_PROFILE_AVATAR_BYTES) {
        setProfilePhotoStatus(t("route.profile.photoSizeError", "Image must be 2 MB or smaller."), true);
        return;
      }
      const fileName = AVATAR_STORAGE_KEY(user.id);
      const { error: upErr } = await supabase.storage.from("avatars").upload(fileName, blob, {
        upsert: true,
        contentType: "image/jpeg",
        cacheControl: "3600",
      });
      if (upErr) throw upErr;
      const { data: urlData } = supabase.storage.from("avatars").getPublicUrl(fileName);
      const publicUrl = urlData?.publicUrl;
      if (!publicUrl) throw new Error("no_public_url");
      const { error: dbErr } = await supabase
        .from("profiles")
        .update({ avatar_url: publicUrl })
        .eq("id", user.id);
      if (dbErr) throw dbErr;
      setProfilePhotoStatus(t("route.profile.photoSuccess", "Profile photo updated."), false);
      await onAfterChange?.();
    } catch (e) {
      const msg =
        e instanceof Error && e.message
          ? e.message
          : t("route.profile.photoError", "Could not update photo. Try again.");
      setProfilePhotoStatus(msg, true);
    } finally {
      pickBtn.disabled = false;
      if (removeBtn) removeBtn.disabled = false;
    }
  });

  removeBtn?.addEventListener("click", async () => {
    const { data: sessData, error: sessErr } = await supabase.auth.getSession();
    if (sessErr) {
      setProfilePhotoStatus(sessErr.message, true);
      return;
    }
    const user = sessData?.session?.user;
    if (!user) return;
    const fileName = AVATAR_STORAGE_KEY(user.id);
    pickBtn.disabled = true;
    removeBtn.disabled = true;
    setProfilePhotoStatus(t("route.profile.photoRemoving", "Removing…"), false);
    try {
      await supabase.storage.from("avatars").remove([fileName]);
      const { error: dbErr } = await supabase
        .from("profiles")
        .update({ avatar_url: null })
        .eq("id", user.id);
      if (dbErr) throw dbErr;
      setProfilePhotoStatus(t("route.profile.photoRemoved", "Profile photo removed."), false);
      await onAfterChange?.();
    } catch (e) {
      const msg =
        e instanceof Error && e.message
          ? e.message
          : t("route.profile.photoError", "Could not update photo. Try again.");
      setProfilePhotoStatus(msg, true);
    } finally {
      pickBtn.disabled = false;
      removeBtn.disabled = false;
    }
  });
}

function listToHtml(items) {
  if (!items?.length) {
    return `<p class="muted">${t("appShell.empty", "No items yet.")}</p>`;
  }
  return `<ul class="app-list">${items
    .map((it) => `<li>${it}</li>`)
    .join("")}</ul>`;
}

const DEFAULT_QUERY_TIMEOUT_MS = 20000;

function withTimeout(promise, ms) {
  return Promise.race([
    promise,
    new Promise((_, reject) => {
      setTimeout(() => reject(new Error("query_timeout")), ms);
    }),
  ]);
}

/** Supabase/PostgREST can hang without rejecting; this caps wait time. */
async function runSafeQuery(work, emptyText, timeoutMs = DEFAULT_QUERY_TIMEOUT_MS) {
  try {
    const rows = await withTimeout(work(), timeoutMs);
    return rows;
  } catch (_) {
    return [{ __error: true, text: emptyText || t("appShell.missingData") }];
  }
}

function normalizeAuthors(authors) {
  if (Array.isArray(authors)) return authors.join(", ");
  return String(authors || "");
}

async function fetchJson(url) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`request_failed_${response.status}`);
  return response.json();
}

function parseGoogleBook(item) {
  const info = item?.volumeInfo || {};
  const images = info?.imageLinks || {};
  let cover = images?.thumbnail || images?.smallThumbnail || null;
  if (cover) {
    cover = String(cover).replace("http://", "https://").replace("zoom=1", "zoom=3");
  }
  const pubDate = String(info?.publishedDate || "");
  return {
    id: `google_${item?.id || Math.random().toString(36).slice(2)}`,
    title: String(info?.title || "Unknown Title"),
    author: normalizeAuthors(info?.authors) || "Unknown Author",
    coverUrl: cover,
    description: info?.description || null,
    pageCount: info?.pageCount || null,
    genres: Array.isArray(info?.categories) ? info.categories : [],
    publishedYear: pubDate.length >= 4 ? pubDate.slice(0, 4) : null,
    publisher: info?.publisher || null,
    googleRating: info?.averageRating || null,
    source: "google",
  };
}

function normalizeApiBook(book) {
  return {
    id: String(book?.id || `book_${Math.random().toString(36).slice(2)}`),
    title: String(book?.title || "Unknown Title"),
    author: String(book?.author || "Unknown Author"),
    coverUrl: book?.coverUrl || null,
    description: book?.description || null,
    pageCount: book?.pageCount || null,
    genres: Array.isArray(book?.genres) ? book.genres : [],
    publishedYear: book?.publishedYear || null,
    publisher: book?.publisher || null,
    googleRating: book?.googleRating || null,
    source: String(book?.source || "catalog"),
  };
}

function extractBooksFromApiResponse(json) {
  if (Array.isArray(json?.books)) return json.books.map(normalizeApiBook);
  if (Array.isArray(json?.items)) return json.items.map(parseGoogleBook);
  return [];
}

function dedupeBooksStable(rows) {
  const seen = new Set();
  const result = [];
  for (let i = 0; i < rows.length; i += 1) {
    const row = rows[i];
    const key = `${String(row?.id || "").trim()}::${String(row?.title || "").trim().toLowerCase()}::${String(row?.author || "").trim().toLowerCase()}`;
    if (!key || seen.has(key)) continue;
    seen.add(key);
    result.push(row);
  }
  return result;
}

function parseGutendexBook(book) {
  const formats = book?.formats || {};
  let cover = null;
  const keys = Object.keys(formats);
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
    id: `gutenberg_${book?.id || Math.random().toString(36).slice(2)}`,
    title: String(book?.title || "Untitled"),
    author,
    coverUrl: cover,
    source: "gutenberg",
    isFree: true,
  };
}

function formatDuration(totalSeconds) {
  const safe = Math.max(0, Number(totalSeconds || 0));
  const h = String(Math.floor(safe / 3600)).padStart(2, "0");
  const m = String(Math.floor((safe % 3600) / 60)).padStart(2, "0");
  const s = String(Math.floor(safe % 60)).padStart(2, "0");
  return `${h}:${m}:${s}`;
}

function truncateText(value, max = 220) {
  const text = String(value || "").trim();
  if (text.length <= max) return text;
  return `${text.slice(0, max).trim()}...`;
}

/** Book APIs often return HTML in descriptions; we show plain text in the app shell. */
function stripHtmlToPlainText(value) {
  return formatBookDescriptionParagraphs(value).join(" ");
}

function toStars(value) {
  const rating = Math.max(0, Math.min(5, Number(value || 0)));
  const rounded = Math.round(rating);
  return `${"★".repeat(rounded)}${"☆".repeat(5 - rounded)}`;
}

function fixCoverUrl(url) {
  const raw = String(url || "").trim();
  if (!raw) return "";
  return raw.replace("http://", "https://").replace("zoom=1", "zoom=3");
}

function firstGenre(genres) {
  if (Array.isArray(genres) && genres.length) return String(genres[0]);
  return "";
}

function renderBookPosterCard(book, opts = {}) {
  const cover = fixCoverUrl(book.coverUrl || book.cover_url);
  const title = escapeHtml(book.title || "Untitled");
  const author = escapeHtml(book.author || "Unknown Author");
  const year = escapeHtml(book.publishedYear || "");
  const genre = escapeHtml(firstGenre(book.genres) || "");
  const rating = book.googleRating != null ? `${Number(book.googleRating).toFixed(1)} ★` : "";
  const footer = [year, genre, rating].filter(Boolean).join(" · ");
  const action = opts.actionHtml || "";
  const source = inferBookSource(book);
  const routeBook = {
    id: book.id || "",
    title: book.title || "Untitled",
    author: book.author || "Unknown Author",
    coverUrl: cover,
    description: book.description || "",
    publishedYear: book.publishedYear || "",
    publisher: book.publisher || "",
    genres: Array.isArray(book.genres) ? book.genres : [],
    googleRating: book.googleRating ?? null,
    source,
  };
  const modalBook = escapeHtml(JSON.stringify(routeBook));
  const shareLink = escapeHtml(buildBookShareUrl(routeBook));
  const sourceBadge = opts.showSource ? renderBookSourceBadge(routeBook, t) : "";
  return `
    <article class="pw-poster-card">
      <button class="pw-poster-media pw-poster-hit" data-book-modal='${modalBook}'>
        ${cover ? `<img src="${escapeHtml(cover)}" alt="${title} cover" width="120" height="180" loading="lazy" decoding="async" />` : `<div class="pw-poster-fallback">PW</div>`}
        ${sourceBadge}
      </button>
      <div class="pw-poster-copy">
        <h4>${title}</h4>
        <p>${author}</p>
        ${footer ? `<p class="muted">${footer}</p>` : ""}
        <a href="${shareLink}" data-link-route="/book">Open details</a>
        ${action}
      </div>
    </article>
  `;
}

function encodeBookPayload(book) {
  try {
    return encodeURIComponent(JSON.stringify(book));
  } catch (_) {
    return "";
  }
}

function decodeBookPayload(payload) {
  try {
    const parsed = JSON.parse(decodeURIComponent(String(payload || "")));
    if (!parsed || typeof parsed !== "object") return null;
    return parsed;
  } catch (_) {
    return null;
  }
}

function buildBookShareUrl(book) {
  const stableId = String(book?.id || "").trim();
  const origin = window.location.origin || "";
  if (stableId) {
    return `${origin}/book?id=${encodeURIComponent(stableId)}`;
  }
  const encoded = encodeBookPayload(book);
  return `${origin}/book?data=${encoded}`;
}

function buildBookPageHtml(source, pageOpts = {}) {
  const { reviews: rawReviews = [], session: pageSession = null, panelOpen = false, reviewsError = "" } = pageOpts;
  const bookIdStr = String(source?.id || "").trim();
  const cleanReviews = (Array.isArray(rawReviews) ? rawReviews : []).filter((r) => r && !r.__error);
  const myReview = pageSession?.user
    ? cleanReviews.find((r) => r.user_id === pageSession.user.id) || null
    : null;
  const myBody = String(myReview?.review_text || myReview?.content || "").trim();
  const myStars = myReview
    ? String(Math.max(1, Math.min(5, Math.round(Number(myReview.star_rating) || 5))))
    : "5";

  const cover = fixCoverUrl(source.coverUrl);
  const title = escapeHtml(source.title || "Untitled");
  const author = escapeHtml(source.author || "Unknown Author");
  const metaLine = [
    source.publishedYear ? escapeHtml(String(source.publishedYear)) : "",
    source.publisher ? escapeHtml(String(source.publisher)) : "",
    Array.isArray(source.genres) && source.genres.length
      ? escapeHtml(source.genres.slice(0, 3).join(", "))
      : "",
  ]
    .filter(Boolean)
    .join(" · ");
  const ratingText =
    source.googleRating != null ? `${Number(source.googleRating).toFixed(1)} / 5` : "No rating yet";
  const shareUrl = buildBookShareUrl(source);
  const sourceBadge = renderBookSourceBadge(source, t);
  const bookForLibrary = {
    id: source.id || null,
    title: source.title || "Untitled",
    author: source.author || "",
    coverUrl: source.coverUrl || null,
  };
  const bookAttr = escapeHtml(JSON.stringify(bookForLibrary));

  const reviewCards = cleanReviews.map((r) => {
    const body = r.review_text || r.content || "";
    const ratingValue = r.star_rating ?? "-";
    const displayName =
      r.profiles?.display_name || r.profiles?.username || t("route.social.anonymous", "Reader");
    return `
    <article class="app-panel pw-book-review-row">
      <p class="muted">${escapeHtml(displayName)}</p>
      <p class="metric">${toStars(ratingValue)} · ${escapeHtml(String(ratingValue))}/5</p>
      <p>${escapeHtml(truncateText(body, 500))}</p>
    </article>
  `;
  });

  return `
    <section class="app-panel">
      <section class="pw-book-page-hero">
        <div class="pw-modal-cover">${
          cover
            ? `<img src="${escapeHtml(cover)}" alt="${title} cover" />`
            : "<div class=\"pw-poster-fallback\">PW</div>"
        }</div>
        <div>
          <h2>${title}</h2>
          <p>${author}</p>
          <p class="pw-book-source-line">${sourceBadge}</p>
          ${metaLine ? `<p class="muted">${metaLine}</p>` : ""}
          <p class="metric">Community rating: ${escapeHtml(ratingText)}</p>
          <div class="cta-actions">
            <button class="btn btn-outline" id="pw-book-page-copy">Copy share link</button>
            <a class="btn btn-outline" href="${escapeHtml(shareUrl)}">Open original link</a>
            <button type="button" class="btn btn-outline" data-require-auth data-book-page-review data-book='${bookAttr}'>${t("route.book.giveReview", "Give a review")}</button>
            <button type="button" class="btn" data-require-auth data-book-page-add data-book='${bookAttr}'>${t("route.discover.addTbr", "Add to TBR")}</button>
          </div>
          <div
            id="pw-book-review-composer"
            class="pw-book-review-composer app-panel"
            ${panelOpen ? "" : "hidden"}
            data-book-id="${escapeHtml(bookIdStr)}"
          >
            <h3 class="pw-book-review-composer__title">${t("route.book.reviewHere", "Write your review")}</h3>
            <form id="pw-book-review-form" class="form-stack">
              <input type="hidden" id="pw-book-review-book-id" value="${escapeHtml(bookIdStr)}" />
              <input type="hidden" id="pw-book-review-edit-id" value="${myReview ? escapeHtml(myReview.id) : ""}" />
              <label>
                <span>${t("route.book.reviewText", "Your review")}</span>
                <textarea id="pw-book-review-body" rows="4" maxlength="2000" required placeholder="${t("route.book.reviewPlaceholder", "What did you think?")}">${escapeHtml(myBody)}</textarea>
              </label>
              <label>
                <span>${t("route.social.formRating", "Rating")}</span>
                <select id="pw-book-review-stars" class="pw-select" aria-label="${t("route.social.formRating", "Rating")}">
                  ${[1, 2, 3, 4, 5]
                    .map(
                      (x) =>
                        `<option value="${x}"${String(x) === myStars ? " selected" : ""}>${x}</option>`,
                    )
                    .join("")}
                </select>
              </label>
              <div class="cta-actions">
                <button type="submit" class="btn">${t("route.book.postReview", "Post review")}</button>
                <button type="button" class="btn btn-outline" id="pw-book-review-cancel">${t("common.cancel", "Cancel")}</button>
              </div>
            </form>
            <p class="muted pw-book-review-composer__hint">${t(
              "route.book.reviewVisibleHint",
              "Your review appears in the list below for this book.",
            )}</p>
          </div>
        </div>
      </section>
      ${renderBookAboutSection(source.description, {
        title: t("route.book.about", "About this book"),
        emptyText: t("route.book.noDescription", "No description yet."),
      })}
      ${
        bookIdStr
          ? `<section class="app-panel pw-book-reviews">
        <h3>${t("route.book.reviewsForBook", "Reviews for this book")}</h3>
        ${reviewsError ? `<p class="muted">${escapeHtml(reviewsError)}</p>` : ""}
        ${
          cleanReviews.length
            ? `<div class="pw-book-reviews__list">${reviewCards.join("")}</div>`
            : !reviewsError
              ? `<p class="muted">${t("route.book.noReviewsYet", "No reviews yet. Be the first to add one above.")}</p>`
              : ""
        }
      </section>`
          : ""
      }
    </section>
  `;
}

function ensureBookModal() {
  let modal = document.getElementById("pw-book-modal");
  if (modal) return modal;
  modal = document.createElement("div");
  modal.id = "pw-book-modal";
  modal.className = "pw-modal";
  modal.hidden = true;
  modal.innerHTML = `
    <div class="pw-modal-backdrop" data-modal-close></div>
    <article class="pw-modal-card" role="dialog" aria-modal="true" aria-label="Book details">
      <button class="btn btn-outline pw-modal-close" data-modal-close>Close</button>
      <div class="pw-modal-body" id="pw-modal-body"></div>
    </article>
  `;
  document.body.appendChild(modal);
  return modal;
}

function openBookModal(book) {
  const modal = ensureBookModal();
  const body = modal.querySelector("#pw-modal-body");
  if (!body) return;
  const title = escapeHtml(book.title || "Untitled");
  const author = escapeHtml(book.author || "Unknown Author");
  const cover = fixCoverUrl(book.coverUrl);
  const meta = [
    book.publishedYear ? escapeHtml(String(book.publishedYear)) : "",
    book.publisher ? escapeHtml(String(book.publisher)) : "",
    Array.isArray(book.genres) && book.genres.length ? escapeHtml(book.genres.slice(0, 3).join(", ")) : "",
  ].filter(Boolean).join(" · ");
  const rating = book.googleRating != null ? `${Number(book.googleRating).toFixed(1)} / 5` : "No rating yet";
  const shareUrl = buildBookShareUrl(book);
  body.innerHTML = `
    <section class="pw-modal-hero">
      <div class="pw-modal-cover">${cover ? `<img src="${escapeHtml(cover)}" alt="${title} cover" />` : "<div class=\"pw-poster-fallback\">PW</div>"}</div>
      <div>
        <h3>${title}</h3>
        <p>${author}</p>
        ${meta ? `<p class="muted">${meta}</p>` : ""}
        <p class="metric">Community rating: ${escapeHtml(rating)}</p>
      </div>
    </section>
    ${renderBookAboutSection(book.description, {
      title: t("route.book.about", "About this book"),
      emptyText: t("route.book.noDescription", "No description yet."),
    })}
    <section class="app-panel">
      <h4>Where to find it</h4>
      <p>Use Discover search for editions and external links, then add it to your shelf.</p>
      <div class="cta-actions">
        <a class="btn btn-outline" href="${escapeHtml(shareUrl)}" data-link-route="/book">Open full page</a>
        <button class="btn btn-outline" id="pw-book-copy-link">Copy share link</button>
      </div>
    </section>
  `;
  const copyBtn = body.querySelector("#pw-book-copy-link");
  copyBtn?.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(shareUrl);
      showBanner("success", "Book link copied.");
    } catch (_) {
      showBanner("error", "Could not copy link.");
    }
  });
  modal.hidden = false;
  document.body.classList.add("pw-modal-open");
}

function closeBookModal() {
  const modal = document.getElementById("pw-book-modal");
  if (!modal) return;
  modal.hidden = true;
  document.body.classList.remove("pw-modal-open");
}

async function upsertUserBookStatus(supabase, userId, book, status) {
  const payload = {
    user_id: userId,
    status,
    book_id: book.id || null,
    title: book.title || "Untitled",
    author: normalizeAuthors(book.authors || book.author) || null,
    cover_url: book.cover_url || book.coverUrl || null,
  };
  const upsertRes = await supabase
    .from("user_books")
    .upsert(payload, { onConflict: "user_id,title" });
  if (!upsertRes.error) return;

  const { data: existing, error: existingErr } = await supabase
    .from("user_books")
    .select("id")
    .eq("user_id", userId)
    .eq("title", payload.title)
    .maybeSingle();
  if (existingErr) throw existingErr;

  if (existing?.id) {
    const { error: updateErr } = await supabase
      .from("user_books")
      .update(payload)
      .eq("id", existing.id);
    if (updateErr) throw updateErr;
    return;
  }

  const { error: insertErr } = await supabase
    .from("user_books")
    .insert(payload);
  if (insertErr) throw insertErr;
}

/** Loads reviews, then profiles in a second query (avoids nested select issues with RLS). */
async function fetchReviewsWithAuthorRows(supabase, limit) {
  const { data, error } = await supabase
    .from("reviews")
    .select("id, user_id, title, review_text, content, star_rating, created_at, book_title, book_author")
    .order("created_at", { ascending: false })
    .limit(limit);
  if (error) throw error;
  if (!data?.length) return [];
  const userIds = [...new Set(data.map((r) => r.user_id).filter(Boolean))];
  if (!userIds.length) {
    return data.map((r) => ({ ...r, profiles: null }));
  }
  const { data: profs, error: pErr } = await supabase
    .from("profiles")
    .select("id, username, display_name, avatar_url")
    .in("id", userIds);
  if (pErr) {
    return data.map((r) => ({ ...r, profiles: null }));
  }
  const byId = Object.fromEntries((profs || []).map((p) => [p.id, p]));
  return data.map((r) => ({ ...r, profiles: byId[r.user_id] || null }));
}

/** Reviews for a single catalog book (book details page). */
async function fetchReviewsForBook(supabase, bookId, limit = 40) {
  const id = String(bookId || "").trim();
  if (!id) return [];
  const { data, error } = await supabase
    .from("reviews")
    .select("id, user_id, title, review_text, content, star_rating, created_at, book_title, book_author, book_id")
    .eq("book_id", id)
    .order("created_at", { ascending: false })
    .limit(limit);
  if (error) throw error;
  if (!data?.length) return [];
  const userIds = [...new Set(data.map((r) => r.user_id).filter(Boolean))];
  if (!userIds.length) {
    return data.map((r) => ({ ...r, profiles: null }));
  }
  const { data: profs, error: pErr } = await supabase
    .from("profiles")
    .select("id, username, display_name, avatar_url")
    .in("id", userIds);
  if (pErr) {
    return data.map((r) => ({ ...r, profiles: null }));
  }
  const byId = Object.fromEntries((profs || []).map((p) => [p.id, p]));
  return data.map((r) => ({ ...r, profiles: byId[r.user_id] || null }));
}

async function renderHome(supabase, session) {
  if (session?.user) {
    return renderHomeDashboard(supabase, session);
  }
  return renderHomeGuest(session);
}

function renderBookCoverTile(book) {
  const cover = fixCoverUrl(book.coverUrl || book.cover_url);
  const title = escapeHtml(book.title || "Untitled");
  const author = escapeHtml(book.author || "");
  const source = inferBookSource(book);
  const routeBook = {
    id: book.id || book.book_id || "",
    title: book.title || "Untitled",
    author: book.author || "",
    coverUrl: cover,
    source,
  };
  const href = escapeHtml(buildBookShareUrl(routeBook));
  const sourceBadge = renderBookSourceBadge(routeBook, t);
  return `
    <a class="pw-cover-tile" href="${href}" data-link-route="/book">
      <span class="pw-cover-tile__media">${cover ? `<img src="${escapeHtml(cover)}" alt="${title} cover" width="100" height="150" loading="lazy" decoding="async" />` : `<span class="pw-cover-tile__fallback">PW</span>`}${sourceBadge}</span>
      <span class="pw-cover-tile__meta"><strong>${title}</strong>${author ? `<span>${author}</span>` : ""}</span>
    </a>
  `;
}

async function renderHomeDashboard(supabase, session) {
  const monthStart = new Date();
  monthStart.setDate(1);
  monthStart.setHours(0, 0, 0, 0);
  const monthStartIso = monthStart.toISOString();

  const [profileRow, userBooks, trendingBooks, feedReviews] = await Promise.all([
    runSafeQuery(async () => {
      const { data, error } = await supabase
        .from("profiles")
        .select("display_name, full_name, username")
        .eq("id", session.user.id)
        .maybeSingle();
      if (error) throw error;
      return data ? [data] : [];
    }, ""),
    runSafeQuery(async () => {
      const { data, error } = await supabase
        .from("user_books")
        .select("id, status, title, author, book_id, updated_at, books(id,title,author,cover_url)")
        .eq("user_id", session.user.id)
        .order("updated_at", { ascending: false })
        .limit(36);
      if (error) throw error;
      return data || [];
    }, t("appShell.missingUserBooks", "Could not load library.")),
    runSafeQuery(async () => {
      const json = await fetchJsonCached("/api/books?type=trending&maxResults=12");
      return extractBooksFromApiResponse(json).slice(0, 6);
    }, ""),
    runSafeQuery(async () => fetchReviewsWithAuthorRows(supabase, 5), ""),
  ]);

  const profile = profileRow[0] && !profileRow[0].__error ? profileRow[0] : {};
  const displayName =
    profile.display_name ||
    profile.full_name ||
    profile.username ||
    String(session.user.email || "reader").split("@")[0] ||
    "reader";
  const books = userBooks.filter((r) => !r.__error).map((r) => {
    const b = r.books || {};
    return {
      id: r.book_id || b.id || "",
      book_id: r.book_id,
      title: r.title || b.title || "Untitled",
      author: r.author || b.author || "",
      cover_url: b.cover_url || null,
      status: r.status,
      updated_at: r.updated_at,
    };
  });
  const readingNow = books.filter((b) => b.status === "reading").slice(0, 6);
  const readThisMonth = books.filter(
    (b) => b.status === "read" && b.updated_at && String(b.updated_at) >= monthStartIso,
  ).length;
  const trendRows = trendingBooks.filter((x) => !x.__error).slice(0, 6);
  const feedRows = feedReviews.filter((x) => !x.__error);

  return `
    <div class="pw-dashboard">
      <header class="pw-dashboard-head wrap">
        <div>
          <h1>${t("home.dashboardHi", "Hi {name}").replace("{name}", escapeHtml(displayName))}</h1>
          <p class="muted">${t("home.dashboardWelcome", "Welcome to your reading dashboard.")}</p>
        </div>
        <a class="pw-dashboard-edit btn btn-outline" href="/profile" data-link-route="/profile">${t("home.dashboardEdit", "Edit")}</a>
      </header>

      <section class="pw-dash-card wrap">
        <h2 class="pw-dash-card__title">${t("home.currentlyReading", "Currently Reading")}</h2>
        ${
          readingNow.length
            ? `<div class="pw-home-scroll">${readingNow.map((b) => renderBookCoverTile(b)).join("")}</div>`
            : `<p class="pw-dash-empty">${t(
                "home.currentlyReadingEmpty",
                "You are not reading anything right now — pick your next book?",
              )} <a href="/explore" data-link-route="/explore">${t("home.pickBook", "Browse Discover")}</a></p>`
        }
        <div class="pw-dash-nested">
          <div class="pw-section-head">
            <h3>${t("home.trendingMonth", "Books trending this month")}</h3>
            <a href="/explore#trending" data-link-route="/explore" data-discover-jump="trending">${t("home.viewAll", "View all")}</a>
          </div>
          <div class="pw-home-scroll">
            ${trendRows.length ? trendRows.map((book) => renderBookCoverTile(book)).join("") : `<p class="muted">${t("home.trendingEmpty", "Trending picks will appear here soon.")}</p>`}
          </div>
        </div>
      </section>

      <section class="pw-dash-card wrap">
        <div class="pw-section-head">
          <h2 class="pw-dash-card__title">${t("home.statsMonth", "Stats — This Month")}</h2>
          <a href="/profile" data-link-route="/profile">${t("home.viewAll", "View all")}</a>
        </div>
        ${
          readThisMonth
            ? `<p class="pw-dash-stat"><span class="pw-dash-stat__num">${readThisMonth}</span> ${t("home.booksReadMonth", "books finished this month")}</p>`
            : `<p class="pw-dash-empty">${t("home.statsMonthEmpty", "You have not finished any books yet this month.")}</p>`
        }
      </section>

      <section class="pw-dash-card wrap">
        <div class="pw-section-head">
          <h2 class="pw-dash-card__title">${t("home.feed", "Feed")}</h2>
          <a href="/social" data-link-route="/social">${t("home.viewAll", "View all")}</a>
        </div>
        ${
          feedRows.length
            ? `<div class="pw-review-feed">${feedRows
                .map(
                  (review) => `
            <article class="pw-review-row">
              <p><strong>${escapeHtml(review.book_title || review.title || "Book")}</strong> · ${toStars(review.rating ?? review.star_rating)}</p>
              <p>${escapeHtml(truncateText(review.review_text || "", 120))}</p>
              <p class="muted">by ${escapeHtml(review.profiles?.display_name || review.profiles?.username || "Reader")}</p>
            </article>`,
                )
                .join("")}</div>`
            : `<p class="pw-dash-empty">${t("home.feedEmpty", "No recent activity.")} <a href="/social" data-link-route="/social">${t("home.feedCta", "Open Social")}</a></p>`
        }
      </section>

      <section class="pw-dash-card wrap">
        <h2 class="pw-dash-card__title">${t("home.readingGoals", "Reading Goals")}</h2>
        <p class="pw-dash-empty">${t("home.goalsEmpty", "You have not set any reading goals yet.")} <a href="/profile" data-link-route="/profile">${t("home.goalsCta", "Set a goal in Profile")}</a></p>
      </section>
    </div>
  `;
}

async function fetchReadersThisWeekCount(supabase) {
  try {
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);
    const { count, error } = await supabase
      .from("user_books")
      .select("id", { count: "exact", head: true })
      .eq("status", "reading")
      .gte("updated_at", weekAgo.toISOString());
    if (error || count == null) return null;
    return count;
  } catch (_) {
    return null;
  }
}

async function renderHomeGuest(session) {
  const supabase = await getSupabase();
  const [trendingBooks, latestReviews, readersThisWeek] = await Promise.all([
    runSafeQuery(async () => {
      const json = await fetchJsonCached("/api/books?type=trending&maxResults=12");
      return extractBooksFromApiResponse(json).slice(0, 12);
    }, "Trending unavailable."),
    runSafeQuery(async () => {
      return fetchReviewsWithAuthorRows(supabase, 4);
    }, "Reviews unavailable."),
    runSafeQuery(() => fetchReadersThisWeekCount(supabase), ""),
  ]);
  const trendRows = trendingBooks.filter((x) => !x.__error);
  const reviewRows = latestReviews.filter((x) => !x.__error);
  const joinHref = session?.user ? "/library" : "/sign-up";
  const joinLabel = session?.user
    ? t("home.joinSignedIn", "Open your library")
    : t("home.joinCta", "Join Pagewalker");
  const readerCount =
    typeof readersThisWeek === "number" && !Number.isNaN(readersThisWeek) && readersThisWeek > 0
      ? readersThisWeek
      : null;
  const statCardHtml =
    readerCount != null
      ? `
          <aside class="pw-hero-stat" aria-label="${t("home.statLabel", "Community pulse")}">
            <p class="pw-hero-stat__label">${t("home.statLabel", "Community pulse")}</p>
            <p class="pw-hero-stat__value">${escapeHtml(readerCount.toLocaleString())}</p>
            <p class="pw-hero-stat__sub">${t("home.statReadersWeek", "people reading this week")}</p>
          </aside>`
      : "";
  return `
    <div class="pw-home">
      <section class="pw-home-hero" data-pw-hero aria-labelledby="pw-home-title">
        <div class="pw-hero-scene" aria-hidden="true">
          <picture class="pw-hero-scene__picture">
            <source
              media="(max-width: 860px) and (orientation: portrait)"
              srcset="/assets/hero-book-cloud-portrait.png"
            />
            <source
              media="(max-width: 860px) and (orientation: landscape)"
              srcset="/assets/hero-book-cloud-mobile.png"
            />
            <img
              class="pw-hero-scene__media"
              src="/assets/hero-book-cloud.png"
              alt=""
              width="1024"
              height="576"
              decoding="async"
              fetchpriority="high"
            />
          </picture>
        </div>
        <div class="pw-hero-overlay" aria-hidden="true"></div>
        <div class="pw-hero-foreground wrap" data-pw-hero-foreground>
          <div class="pw-home-hero__content">
            <div class="pw-hero-scrim">
              <div class="pw-store-row">
                <a class="pw-store-pill" href="https://play.google.com/store/apps/details?id=com.pagewalker.app" rel="noopener noreferrer">
                  <span aria-hidden="true">▶</span>
                  ${t("home.storeAndroid", "Get Android app")}
                </a>
              </div>
              <h1 id="pw-home-title">${t("home.heroHeadline", "Walk your shelves.")}</h1>
              <p class="pw-hero-lede">${t(
                "home.heroLede",
                "Pagewalker is your reading home on web and app - discover your next book, track your progress, and share honest reviews with people who love stories as much as you do.",
              )}</p>
              <a class="btn" href="${joinHref}">${escapeHtml(joinLabel)}</a>
            </div>
          </div>
          ${statCardHtml}
        </div>
      </section>

      <section class="pw-home-pillars wrap" data-reveal aria-label="${t("home.pillarsLabel", "What you can do")}">
        <a class="pw-pillar" href="/explore" data-link-route="/explore">
          <span class="pw-pillar__icon" aria-hidden="true">🔎</span>
          <h2 class="pw-pillar__title">${t("home.pillarFind", "Find")}</h2>
          <p class="pw-pillar__desc">${t("home.pillarFindDesc", "Search, moods, and explainable picks.")}</p>
        </a>
        <a class="pw-pillar" href="/library" data-link-route="/library">
          <span class="pw-pillar__icon" aria-hidden="true">📚</span>
          <h2 class="pw-pillar__title">${t("home.pillarTrack", "Track")}</h2>
          <p class="pw-pillar__desc">${t("home.pillarTrackDesc", "TBR, reading, read, and DNF shelves.")}</p>
        </a>
        <a class="pw-pillar" href="/social" data-link-route="/social" data-tone="moss">
          <span class="pw-pillar__icon" aria-hidden="true">💬</span>
          <h2 class="pw-pillar__title">${t("home.pillarConnect", "Connect")}</h2>
          <p class="pw-pillar__desc">${t("home.pillarConnectDesc", "Reviews, follows, and club rooms.")}</p>
        </a>
        <a class="pw-pillar" href="/explore#trending" data-link-route="/explore" data-discover-jump="trending">
          <span class="pw-pillar__icon" aria-hidden="true">✨</span>
          <h2 class="pw-pillar__title">${t("home.pillarDiscover", "Discover")}</h2>
          <p class="pw-pillar__desc">${t("home.pillarDiscoverDesc", "Trending titles and curated lists.")}</p>
        </a>
      </section>

      <section class="pw-home-section wrap pw-marginalia-rail" data-reveal>
        <span class="pw-marginalia-rail__tick" style="top:0.2rem">01</span>
        <div class="pw-section-head">
          <h2>${t("home.trendingHeading", "Trending on Pagewalker")}</h2>
          <a href="/explore#trending" data-link-route="/explore" data-discover-jump="trending">${t("home.viewAll", "View all")}</a>
        </div>
        <p class="muted pw-section-note">${t(
          "home.trendingNote",
          "Books readers are adding and finishing lately — open Discover for the full list.",
        )}</p>
        <div class="pw-home-scroll">
          ${trendRows.length
            ? trendRows.map((book) => renderBookPosterCard(book)).join("")
            : `<p class="muted">${t("home.trendingEmpty", "Trending picks will appear here soon.")}</p>`}
        </div>
      </section>

      <section class="pw-home-section wrap pw-marginalia-rail" data-reveal>
        <span class="pw-marginalia-rail__tick" style="top:0.2rem">02</span>
        <div class="pw-section-head">
          <h2>${t("home.buzzHeading", "Reader buzz")}</h2>
          <a href="/social" data-link-route="/social">${t("home.goSocial", "Go to Social")}</a>
        </div>
        <p class="muted pw-section-note">${t(
          "home.readerBuzzExplainer",
          "Recent reviews from other readers. Open Social for the full feed. Trending books and search are on Discover.",
        )}</p>
        <div class="pw-review-feed">
          ${reviewRows.length
            ? reviewRows
                .map(
                  (review) => `
          <article class="pw-review-row">
            <p><strong>${escapeHtml(review.book_title || review.title || "Book")}</strong> · ${toStars(review.rating ?? review.star_rating)}</p>
            <p>${escapeHtml(truncateText(review.review_text || "", 130))}</p>
            <p class="muted">by ${escapeHtml(review.profiles?.display_name || review.profiles?.username || "Reader")}</p>
          </article>
        `,
                )
                .join("")
            : `<p class="muted">${t("home.reviewsEmpty", "Reviews will appear here as readers post.")}</p>`}
        </div>
      </section>

      <section class="cta-band" data-reveal>
        <div class="cta-inner">
          <h2>${t("home.ctaHeading", "Start your next chapter")}</h2>
          <p class="cta-lede">${t("home.ctaLede", "Get the app on Google Play, read release notes, or reach out for support.")}</p>
          <div class="cta-actions">
            <a class="btn" href="https://play.google.com/store/apps/details?id=com.pagewalker.app" rel="noopener noreferrer">${t("home.ctaPlay", "Get it on Google Play")}</a>
            <a class="btn btn-outline" href="/updates">${t("home.ctaUpdates", "Read updates")}</a>
            <a class="btn btn-outline" href="/about">${t("nav.about", "About")}</a>
          </div>
        </div>
      </section>
    </div>
  `;
}

async function loadGoogleBookPages(baseUrl, pages) {
  const reqs = [];
  for (let i = 0; i < pages; i += 1) {
    const startIndex = i * DISCOVER_PAGE_SIZE;
    reqs.push(
      fetchJsonCached(
        `${baseUrl}${baseUrl.includes("?") ? "&" : "?"}startIndex=${startIndex}&maxResults=${DISCOVER_PAGE_SIZE}`,
      ),
    );
  }
  const responses = await Promise.all(reqs);
  const books = dedupeBooksStable(responses.flatMap((x) => extractBooksFromApiResponse(x)));
  const last = responses[responses.length - 1] || {};
  const hasMore =
    typeof last?.hasMore === "boolean"
      ? last.hasMore
      : Number(last?.totalItems || 0) > books.length;
  return { books, hasMore };
}

async function loadClassicsBookPages(pages) {
  const reqs = [];
  for (let i = 1; i <= pages; i += 1) {
    reqs.push(fetchJsonCached(`/api/books?type=classics&page=${i}`));
  }
  const responses = await Promise.all(reqs);
  const books = dedupeBooksStable(responses.flatMap((x) => x.results || []).map(parseGutendexBook));
  const hasMore = Boolean(responses[responses.length - 1]?.next);
  return { books, hasMore };
}

function discoverBookActionsHtml(book) {
  return `<div class="cta-actions">
    <button type="button" class="btn btn-outline" data-require-auth data-discover-add data-status="tbr" data-book='${escapeHtml(JSON.stringify(book))}'>${t("route.discover.addTbr", "Add to TBR")}</button>
    <button type="button" class="btn btn-outline" data-require-auth data-discover-add data-status="reading" data-book='${escapeHtml(JSON.stringify(book))}'>${t("route.discover.addReading", "Mark Reading")}</button>
  </div>`;
}

function renderDiscoverBooksHtml(books, opts = {}) {
  const rows = filterBooksBySource(books, discoverSourceFilter);
  if (!rows.length) {
    return `<p class="muted">${opts.emptyText || t("route.discover.searchEmpty", "No matches. Try different words.")}</p>`;
  }
  return rows
    .map((book) =>
      renderBookPosterCard(book, {
        actionHtml: opts.actionHtml ? opts.actionHtml(book) : discoverBookActionsHtml(book),
      }),
    )
    .join("");
}

function renderDiscoverSourceFilters() {
  const filters = [
    ["all", t("route.discover.source.all", "All sources")],
    ["google", t("route.discover.source.google", BOOK_SOURCE_LABELS.google)],
    ["openlibrary", t("route.discover.source.openlibrary", BOOK_SOURCE_LABELS.openlibrary)],
    ["gutenberg", t("route.discover.source.gutenberg", BOOK_SOURCE_LABELS.gutenberg)],
  ];
  return `<label class="pw-source-filter-field">
    <span class="pw-source-filter-field__label">${t("route.discover.sourceFilterLabel", "Filter by source")}</span>
    <select id="pw-discover-source" class="pw-select pw-source-select" aria-label="${escapeHtml(t("route.discover.sourceFilterLabel", "Filter by source"))}">
      ${filters
        .map(
          ([id, label]) =>
            `<option value="${escapeHtml(id)}"${discoverSourceFilter === id ? " selected" : ""}>${escapeHtml(label)}</option>`,
        )
        .join("")}
    </select>
  </label>`;
}

function renderDiscoverShell(session) {
  const discoverView = getDiscoverView();
  const safeQuery = discoverQuery.trim();
  const genres = ["romance", "mystery", "adventure", "horror", "fantasy", "history", "drama", "sci-fi"];
  const moodInPreset = Boolean(discoverMood && DISCOVER_MOOD_PRESETS.includes(discoverMood));
  const moodSelectValue = !discoverMood ? "" : moodInPreset ? discoverMood : "__custom";
  const moodCustomValue = !moodInPreset && discoverMood ? discoverMood : "";

  return `
    <div class="pw-discover-route">
    <section class="app-panel pw-discover-page" id="pw-discover-root" data-pw-active="${discoverView}">
      <h2 class="pw-discover-title">${t("route.explore.heading", "Explore")}</h2>
      <p class="pw-discover-page__lede muted">${t("route.explore.lede", "Search, mood picks, trending books, genres, and free classics — one place to find your next read.")}</p>
      <nav class="pw-discover-tabstrip" aria-label="${t("route.explore.tabstripLabel", "Explore sections")}">
        <a class="btn btn-outline pw-discover-tablink" data-link-route="/explore" href="/explore" data-discover-jump="search">${t("route.explore.tabSearch", "Search & mood")}</a>
        <a class="btn btn-outline pw-discover-tablink" data-link-route="/explore" href="/explore#trending" data-discover-jump="trending">${t("drawer.discover.trending", "Trending")}</a>
        <a class="btn btn-outline pw-discover-tablink" data-link-route="/explore" href="/explore#genre" data-discover-jump="genre">${t("drawer.discover.genre", "Genre exploration")}</a>
        <a class="btn btn-outline pw-discover-tablink" data-link-route="/explore" href="/explore#classics" data-discover-jump="classics">${t("drawer.discover.classics", "Classics")}</a>
      </nav>
      <div class="pw-discover-panels" role="region" aria-label="${t("route.explore.sectionsLabel", "Explore content")}">
        <section class="app-panel pw-discover-panel" data-pw-discover-panel="trending" id="pw-discover-trending">
          <h3>🔥 ${t("route.discover.trendingTitle", "Trending now")}</h3>
          <div class="pw-poster-grid" data-discover-grid="trending">${posterGridSkeleton(8)}</div>
          <div data-discover-more="trending"></div>
        </section>
        <section class="pw-discover-panel pw-discover-panel--stack" data-pw-discover-panel="genre" id="pw-discover-genre">
          <article class="app-panel">
            <h3>${t("route.discover.genreTitle", "Explore by genre")}</h3>
            <div class="cta-actions">
              ${genres.map((g) => `<button class="btn btn-outline" data-genre-chip="${escapeHtml(g)}">${escapeHtml(g)}</button>`).join("")}
            </div>
          </article>
          <div class="pw-poster-grid" data-discover-grid="genre">${posterGridSkeleton(8)}</div>
          <div data-discover-more="genre"></div>
        </section>
        <section class="app-panel pw-discover-panel" data-pw-discover-panel="classics" id="pw-discover-classics">
          <h3>📖 ${t("route.discover.freeClassics", "Free classics")}</h3>
          <p class="muted">${t("route.discover.classicsSource", "Public-domain novels from Project Gutenberg.")}</p>
          <div class="pw-poster-grid" data-discover-grid="classics">${posterGridSkeleton(8)}</div>
          <div data-discover-more="classics"></div>
        </section>
        <section class="pw-discover-panel pw-discover-panel--search" data-pw-discover-panel="search" id="pw-discover-search">
          <div class="pw-discover-tools">
            <div class="pw-discover-tiles">
              <article class="app-panel pw-discover-tile">
                <h3 class="pw-discover-tile__title">${t("route.discover.searchLabel", "Search books")}</h3>
                <form id="pw-discover-search-form" class="pw-discover-tile__body form-stack">
                  <label>
                    <span class="pw-discover-sr-only">${t("route.discover.searchLabel", "Search books")}</span>
                    <input id="pw-discover-query" type="search" autocomplete="off" value="${escapeHtml(safeQuery)}" placeholder="${t("route.discover.searchPlaceholder", "Search by title")}" />
                  </label>
                  ${renderDiscoverSourceFilters()}
                  <button type="submit" class="btn">${t("route.discover.searchAction", "Search")}</button>
                </form>
              </article>
              <article class="app-panel pw-discover-tile">
                <h3 class="pw-discover-tile__title">${t("route.discover.moodTitle", "What's your vibe?")}</h3>
                <form id="pw-mood-form" class="pw-discover-tile__body form-stack">
                  <label class="pw-mood-field">
                    <span class="pw-discover-sr-only">${t("route.discover.moodInputLabel", "Mood")}</span>
                    <select id="pw-mood-select" class="pw-select" aria-label="${escapeHtml(t("route.discover.moodTitle", "What's your vibe?"))}">
                      <option value="">${t("route.discover.moodSelectHint", "Choose a vibe…")}</option>
                      ${DISCOVER_MOOD_PRESETS.map(
                        (m) =>
                          `<option value="${escapeHtml(m)}"${moodSelectValue === m ? " selected" : ""}>${escapeHtml(m)}</option>`,
                      ).join("")}
                      <option value="__custom" ${moodSelectValue === "__custom" ? " selected" : ""}>${t("route.discover.moodCustom", "Custom…")}</option>
                    </select>
                    <input id="pw-mood-input" type="text" class="pw-mood-custom-input" value="${escapeHtml(moodCustomValue)}" placeholder="${t("route.discover.moodPlaceholder", "Describe your mood")}" ${moodSelectValue === "__custom" ? "" : " hidden"} />
                  </label>
                  <button type="submit" class="btn">${t("route.discover.moodAction", "Find my next read")}</button>
                </form>
              </article>
            </div>
            <div id="pw-mood-results" class="pw-mood-results-below"></div>
            <div class="app-panel pw-discover-search-title-block" id="pw-discover-search-results" ${safeQuery ? "" : "hidden"}>
              <h3 class="pw-discover-tile__title">${t("route.discover.searchResultsTitle", "Title search results")}</h3>
              <div class="pw-poster-grid" data-discover-grid="search">${posterGridSkeleton(8)}</div>
              <div data-discover-more="search"></div>
            </div>
          </div>
        </section>
      </div>
      <p class="pw-discover-attribution muted">${t(
        "route.discover.sourcesNote",
        "Covers and descriptions from Google Books, Open Library, and Project Gutenberg.",
      )}</p>
      <p class="muted pw-discover-session-note">${
        session?.user
          ? t("route.discover.noteAuthed", "You are signed in. Use discover + library together.")
          : t("route.discover.noteGuest", "Sign in to save books to your TBR and library.")
      }</p>
    </section>
    </div>
  `;
}

async function hydrateDiscoverPanels(session) {
  const discoverView = getDiscoverView();
  const safeQuery = discoverQuery.trim();
  const fillGrid = (key, html) => {
    const el = document.querySelector(`[data-discover-grid="${key}"]`);
    if (el) el.innerHTML = html;
  };
  const fillMore = (key, hasMore) => {
    const el = document.querySelector(`[data-discover-more="${key}"]`);
    if (!el) return;
    el.innerHTML = hasMore
      ? `<div class="cta-actions"><button class="btn btn-outline" data-discover-more="${key}">Load more</button></div>`
      : "";
  };

  if (discoverView === "trending") {
    const trending = await runSafeQuery(
      () => loadGoogleBookPages("/api/books?type=trending", discoverPaging.trendingPage),
      t("route.discover.trendingFallback", "Trending data is not available yet."),
    );
    const rows = (trending?.books || []).filter((b) => !b.__error);
    _discoverPanelBooks.trending = rows;
    fillGrid(
      "trending",
      renderDiscoverBooksHtml(rows, {
        actionHtml: (book) =>
          `<div class="cta-actions"><button type="button" class="btn btn-outline" data-require-auth data-discover-add data-status="tbr" data-book='${escapeHtml(JSON.stringify(book))}'>${t("route.discover.addTbr", "Add to TBR")}</button></div>`,
      }),
    );
    fillMore("trending", Boolean(trending?.hasMore));
    return;
  }

  if (discoverView === "genre") {
    const g = encodeURIComponent(discoverGenre);
    const genreBooks = await runSafeQuery(
      () => loadGoogleBookPages(`/api/books?type=genre&genre=${g}`, discoverPaging.genrePage),
      t("route.discover.trendingFallback", "Trending data is not available yet."),
    );
    const rows = (genreBooks?.books || []).filter((b) => !b.__error);
    _discoverPanelBooks.genre = rows;
    fillGrid("genre", renderDiscoverBooksHtml(rows));
    fillMore("genre", Boolean(genreBooks?.hasMore));
    return;
  }

  if (discoverView === "classics") {
    const classics = await runSafeQuery(
      () => loadClassicsBookPages(discoverPaging.classicsPage),
      t("route.discover.trendingFallback", "Trending data is not available yet."),
    );
    const rows = (classics?.books || []).filter((b) => !b.__error);
    _discoverPanelBooks.classics = rows;
    fillGrid(
      "classics",
      renderDiscoverBooksHtml(rows, {
        actionHtml: () => `<p class="metric">${t("route.discover.freeBadge", "Free")}</p>`,
      }),
    );
    fillMore("classics", Boolean(classics?.hasMore));
    return;
  }

  if (discoverView === "search" && safeQuery) {
    const searchBlock = document.getElementById("pw-discover-search-results");
    if (searchBlock) searchBlock.removeAttribute("hidden");
    const q = encodeURIComponent(safeQuery);
    const searchBooks = await runSafeQuery(
      () => loadGoogleBookPages(`/api/books?type=search&q=${q}`, discoverPaging.searchPage),
      t("route.discover.trendingFallback", "Trending data is not available yet."),
    );
    const rows = (searchBooks?.books || []).filter((b) => !b.__error);
    _discoverPanelBooks.search = rows;
    fillGrid("search", renderDiscoverBooksHtml(rows));
    fillMore("search", Boolean(searchBooks?.hasMore));
  }
}

function renderDiscover(session) {
  return renderDiscoverShell(session);
}

async function renderLibrary(supabase, session) {
  if (!session?.user) {
    return `<section class="app-panel"><h2>${t("route.library.title", "Library")}</h2><p>${t("route.authRequired", "Please sign in to view this section.")}</p></section>`;
  }
  const rows = await runSafeQuery(async () => {
    const reqs = [];
    for (let i = 0; i < libraryPage; i += 1) {
      const from = i * LIBRARY_PAGE_SIZE;
      const to = from + LIBRARY_PAGE_SIZE - 1;
      reqs.push(
        supabase
          .from("user_books")
          .select("id, status, title, author, book_id, created_at, books(id,title,author,cover_url,description,page_count,genre)")
          .eq("user_id", session.user.id)
          .order("updated_at", { ascending: false })
          .range(from, to),
      );
    }
    const responses = await Promise.all(reqs);
    const merged = [];
    for (let i = 0; i < responses.length; i += 1) {
      if (responses[i].error) throw responses[i].error;
      merged.push(...(responses[i].data || []));
    }
    return merged;
  }, t("appShell.missingUserBooks", "Could not load user_books."));
  const cleanRows = rows.filter((r) => !r.__error).map((r) => {
    const b = r.books || {};
    return {
      ...r,
      title: r.title || b.title || "Untitled",
      author: r.author || b.author || "",
      cover_url: b.cover_url || null,
    };
  });
  const counts = LIBRARY_STATUSES.reduce((acc, status) => {
    acc[status] = cleanRows.filter((x) => x.status === status).length;
    return acc;
  }, {});
  const filteredRows = libraryFilter === "all"
    ? cleanRows
    : cleanRows.filter((x) => x.status === libraryFilter);
  const hasMoreLibrary = cleanRows.length >= libraryPage * LIBRARY_PAGE_SIZE;

  return `
    <div class="pw-library-route">
    <section class="app-panel pw-library-page">
      <h2>${t("route.library.title", "Library")}</h2>
      <p class="muted">${t("route.library.explainer", "This is your reading shelf. Add books from Discover, then move them across TBR, Reading, Read, and DNF.")}</p>
      <div class="cta-actions pw-sticky-bar">
        <button class="btn btn-outline" data-library-filter="all">${t("route.library.filterAll", "All")} (${cleanRows.length})</button>
        ${LIBRARY_STATUSES.map((status) => `<button class="btn btn-outline" data-library-filter="${status}">${STATUS_LABELS[status]} (${counts[status] || 0})</button>`).join("")}
      </div>
      ${filteredRows.length ? "" : `<p class="muted">${t("route.library.emptyHint", "No books in this shelf yet. Add one from Discover.")}</p>`}
      <div class="pw-poster-grid">
        ${
          filteredRows.map((r) => renderBookPosterCard({
            id: r.book_id || "",
            title: r.title,
            author: r.author,
            cover_url: r.cover_url,
          }, {
            actionHtml: `<p class="metric">${t("route.library.status", "Status")}: ${escapeHtml(STATUS_LABELS[r.status] || r.status || "-")}</p>
            <div class="cta-actions">
              ${LIBRARY_STATUSES.map((status) => `<button class="btn btn-outline" data-library-status="${status}" data-library-title="${escapeHtml(r.title || "")}">${STATUS_LABELS[status]}</button>`).join("")}
            </div>`,
          })).join("")
        }
      </div>
      ${hasMoreLibrary ? `<div class="cta-actions"><button class="btn btn-outline" data-library-more>Load more</button></div>` : ""}
      ${rows.some((r) => r.__error) ? `<p class="muted">${escapeHtml(rows.find((r) => r.__error)?.text || "")}</p>` : ""}
    </section>
    </div>
  `;
}

async function renderSocial(supabase, session) {
  if (!session?.user) {
    return `<section class="app-panel"><h2>${t("route.social.title", "Reviews & social")}</h2><p>${t("route.authRequired", "Please sign in to view this section.")}</p></section>`;
  }
  const reviews = await runSafeQuery(
    () => fetchReviewsWithAuthorRows(supabase, 25),
    t("appShell.missingReviews", "Could not load reviews."),
  );
  const hasDraft = Boolean(
    (socialDraft.title && String(socialDraft.title).trim()) ||
      (socialDraft.body && String(socialDraft.body).trim()),
  );
  const showComposer = socialComposerExpanded || hasDraft;
  const cards = reviews.map((r) => {
    if (r.__error) return `<article class="app-panel"><p>${escapeHtml(r.text)}</p></article>`;
    const title = r.title || r.book_title || t("route.social.reviewTitle", "Review");
    const body = r.review_text || r.content || "";
    const ratingValue = r.rating ?? r.star_rating ?? "-";
    const displayName =
      r.profiles?.display_name ||
      r.profiles?.username ||
      t("route.social.anonymous", "Reader");
    const isMine = r.user_id && r.user_id === session.user.id;
    return `
      <article class="app-panel pw-review-card">
        <p class="muted">${escapeHtml(displayName)} reviewed</p>
        <h3>${escapeHtml(title)}</h3>
        <p class="metric">${toStars(ratingValue)} · ${escapeHtml(String(ratingValue))}/5</p>
        <p data-review-full hidden>${escapeHtml(body)}</p>
        <p data-review-short>${escapeHtml(truncateText(body, 220))}</p>
        ${String(body).length > 220 ? `<button class="btn btn-outline" data-review-toggle>Read more</button>` : ""}
        <div class="pw-review-actions">
          <span>Like</span><span>Comment</span><span>Spoiler</span>
        </div>
        ${isMine ? `<div class="cta-actions"><button class="btn btn-outline" data-social-edit="${escapeHtml(r.id)}" data-social-title="${escapeHtml(title)}" data-social-body="${escapeHtml(body)}" data-social-rating="${escapeHtml(String(ratingValue === "-" ? 5 : ratingValue))}">${t("route.social.edit", "Edit")}</button><button class="btn btn-outline" data-social-delete="${escapeHtml(r.id)}">${t("route.social.delete", "Delete")}</button></div>` : ""}
      </article>
    `;
  });

  return `
    <section class="app-panel">
      <h2>${t("route.social.title", "Reviews & social")}</h2>
      <p class="muted pw-social-feed-intro">${t(
        "route.social.feedIntro",
        "Member reviews below (newest first). Discover has trending and search. Home shows a short preview in Reader buzz. No per-book page on web yet.",
      )}</p>
      <div class="pw-social-composer">
        <button
          type="button"
          id="pw-social-composer-toggle"
          class="btn btn-outline pw-social-composer__toggle"
          aria-expanded="${showComposer ? "true" : "false"}"
          aria-controls="pw-social-composer-panel"
        >
          ${t("route.social.writeReviewToggle", "Write a review")}
        </button>
        <div id="pw-social-composer-panel" class="pw-social-composer__panel" ${showComposer ? "" : "hidden"}>
          <p class="muted pw-social-composer__hint">${t(
            "route.social.composerHint",
            "Choose the book, add stars, and write your take.",
          )}</p>
          <form id="pw-social-form" class="form-stack">
            <label>
              <span>${t("route.social.formTitle", "Book or review title")}</span>
              <input id="pw-social-title" type="text" value="${escapeHtml(socialDraft.title)}" maxlength="140" required />
            </label>
            <label>
              <span>${t("route.social.formBody", "Your review")}</span>
              <textarea id="pw-social-body" rows="4" maxlength="1000" required>${escapeHtml(socialDraft.body)}</textarea>
            </label>
            <label>
              <span>${t("route.social.formRating", "Rating")}</span>
              <select id="pw-social-rating" class="pw-select">
                ${[1, 2, 3, 4, 5]
                  .map(
                    (x) =>
                      `<option value="${x}"${String(x) === String(socialDraft.rating) ? " selected" : ""}>${x}</option>`,
                  )
                  .join("")}
              </select>
            </label>
            <div class="cta-actions">
              <button type="submit" class="btn">${t("route.social.publish", "Publish review")}</button>
              <input id="pw-social-edit-id" type="hidden" value="" />
            </div>
          </form>
        </div>
      </div>
      <h3 class="pw-social-feed__heading">${t("route.social.feedSectionTitle", "From readers")}</h3>
      <div class="app-grid app-grid-3">
        ${cards.join("")}
      </div>
      <p class="muted">${t("route.social.authed", "Use the mobile app and web together with the same account.")}</p>
    </section>
  `;
}

function renderClubCardFooter(c, { myRole, requestStatus, atCapacity }) {
  if (c.__error) return "";
  const isListed = c.is_private === false;
  if (myRole) {
    return `<p class="muted pw-club-card__state">${t("route.clubs.inClub", "You are in this club.")} · ${t("route.clubs.yourRole", "Your role")}: ${escapeHtml(
      myRole,
    )}</p>`;
  }
  if (!isListed) {
    return `<p class="muted">${t("route.clubs.inviteOnlyCard", "Invite only — get a code from a member to join.")}</p>`;
  }
  if (atCapacity) {
    return `<p class="muted">${t("route.clubs.clubFull", "This club is full.")}</p>`;
  }
  if (requestStatus === "pending") {
    return `<button type="button" class="btn btn-outline" disabled>${t("route.clubs.requestPending", "Request sent")}</button>`;
  }
  if (requestStatus === "rejected") {
    return `<button type="button" class="btn btn-outline" data-club-rejoin="${escapeHtml(c.id)}">${t("route.clubs.requestAgain", "Ask again")}</button>`;
  }
  return `<button type="button" class="btn" data-club-request="${escapeHtml(c.id)}">${t("route.clubs.requestToJoin", "Request to join")}</button>`;
}

/** Create / join forms — used on Profile → Book clubs tab (not on /clubs browse). */
function renderClubSetupFormsHtml() {
  return `
      <div class="app-grid app-grid-2 pw-club-forms">
        <article class="app-panel">
          <h3>${t("route.clubs.createTitle", "Create a club")}</h3>
          <form id="pw-club-create-form" class="form-stack">
            <label><span>${t("route.clubs.clubName", "Club name")}</span><input id="pw-club-name" type="text" maxlength="120" value="${escapeHtml(
              clubsDraft.name,
            )}" required /></label>
            <label><span>${t("route.clubs.clubDescription", "Description")}</span><textarea id="pw-club-description" rows="3" maxlength="500">${escapeHtml(
              clubsDraft.description,
            )}</textarea></label>
            <label><span>${t("route.clubs.clubEmoji", "Emoji")}</span><input id="pw-club-emoji" type="text" maxlength="2" value="${escapeHtml(
              clubsDraft.emoji,
            )}" /></label>
            <label><span>${t("route.clubs.maxMembers", "Max members")}</span><select id="pw-club-max-members" class="pw-select"><option value="5"${clubsDraft.maxMembers === "5" ? " selected" : ""}>5</option><option value="10"${clubsDraft.maxMembers === "10" ? " selected" : ""}>10</option><option value="20"${clubsDraft.maxMembers === "20" ? " selected" : ""}>20</option></select></label>
            <label class="pw-checkbox">
              <input type="checkbox" id="pw-club-directory" checked />
              <span>${t("route.clubs.listInDirectory", "List in directory (others can request to join)")}</span>
            </label>
            <button type="submit" class="btn">${t("route.clubs.createAction", "Create club")}</button>
          </form>
        </article>
        <article class="app-panel">
          <h3>${t("route.clubs.joinTitle", "Join with invite code")}</h3>
          <form id="pw-club-join-form" class="form-stack">
            <label><span>${t("route.clubs.inviteCode", "Invite code")}</span><input id="pw-club-invite-code" type="text" maxlength="30" value="${escapeHtml(
              clubsDraft.inviteCode,
            )}" placeholder="A1B2C3D4" required /></label>
            <button type="submit" class="btn btn-outline">${t("route.clubs.joinAction", "Join club")}</button>
          </form>
        </article>
      </div>
      <p class="muted pw-profile-club-hint">${t("route.profile.clubSetupHint", "Then open Clubs in the app menu to browse and enter your club’s forum.")}</p>
  `;
}

function bindProfileTabActions() {
  const buttons = document.querySelectorAll("[data-profile-tab]");
  const acc = document.getElementById("pw-profile-panel-account");
  const cl = document.getElementById("pw-profile-panel-clubs");
  for (let i = 0; i < buttons.length; i += 1) {
    buttons[i].addEventListener("click", () => {
      const tab = buttons[i].getAttribute("data-profile-tab") || "account";
      const u = new URL(window.location.href);
      if (tab === "clubs") u.searchParams.set("tab", "clubs");
      else u.searchParams.delete("tab");
      const qs = u.searchParams.toString();
      window.history.pushState({}, "", u.pathname + (qs ? `?${qs}` : ""));
      for (let j = 0; j < buttons.length; j += 1) {
        const id = buttons[j].getAttribute("data-profile-tab");
        buttons[j].setAttribute("aria-selected", id === tab ? "true" : "false");
      }
      if (acc) acc.hidden = tab !== "account";
      if (cl) cl.hidden = tab !== "clubs";
    });
  }
}

function bindProfileSettingsForm(supabase, session, rerender) {
  const form = document.getElementById("pw-profile-form");
  const statusEl = document.getElementById("pw-profile-save-status");
  const saveBtn = document.getElementById("pw-profile-save");
  if (!form || !session?.user) return;

  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    if (statusEl) {
      statusEl.hidden = true;
      statusEl.removeAttribute("data-state");
    }

    const fd = new FormData(form);
    const username = String(fd.get("username") || "")
      .trim()
      .toLowerCase()
      .replace(/\s+/g, "");
    const displayName = String(fd.get("display_name") || "").trim();
    const bio = String(fd.get("bio") || "").trim();
    const location = String(fd.get("location") || "").trim();
    const favouriteGenre = String(fd.get("favourite_genre") || "").trim();
    const readingGoal = Math.max(1, Math.min(999, Number.parseInt(String(fd.get("reading_goal") || "12"), 10) || 12));
    const isPublic = fd.get("is_public") === "on";

    if (username.length < 3) {
      if (statusEl) {
        statusEl.textContent = t("route.profile.usernameShort", "Username must be at least 3 characters.");
        statusEl.dataset.state = "error";
        statusEl.hidden = false;
      }
      return;
    }
    if (!/^[a-z0-9_]+$/.test(username)) {
      if (statusEl) {
        statusEl.textContent = t(
          "route.profile.usernameInvalid",
          "Username can only use lowercase letters, numbers, and underscores.",
        );
        statusEl.dataset.state = "error";
        statusEl.hidden = false;
      }
      return;
    }

    if (saveBtn) saveBtn.disabled = true;
    if (statusEl) {
      statusEl.textContent = t("route.profile.saving", "Saving…");
      statusEl.hidden = false;
      statusEl.removeAttribute("data-state");
    }

    try {
      const { error } = await withTimeout(
        supabase
          .from("profiles")
          .update({
            username,
            display_name: displayName || username,
            full_name: displayName || username,
            bio: bio || null,
            location: location || null,
            favourite_genre: favouriteGenre || null,
            reading_goal: readingGoal,
            is_public: isPublic,
          })
          .eq("id", session.user.id),
        12000,
      );
      if (error) throw error;
      if (statusEl) {
        statusEl.textContent = t("route.profile.saved", "Profile updated.");
        statusEl.dataset.state = "success";
        statusEl.hidden = false;
      }
      if (typeof window.pwUserMenuRefresh === "function") {
        await window.pwUserMenuRefresh();
      }
      await rerender();
    } catch (err) {
      const msg = String(err?.message || "");
      if (statusEl) {
        statusEl.textContent = msg.includes("duplicate")
          ? t("route.profile.usernameTaken", "That username is already taken.")
          : msg || t("route.profile.saveError", "Could not save profile. Try again.");
        statusEl.dataset.state = "error";
        statusEl.hidden = false;
      }
    } finally {
      if (saveBtn) saveBtn.disabled = false;
    }
  });
}

function renderProfileGuestCta() {
  return `
    <section class="webapp-hero app-panel">
      <h1>${t("appShell.heroTitle", "Your full Pagewalker experience on web")}</h1>
      <p>${t("appShell.heroLede", "Sign in once and move across library, discover, social, clubs, and reader tools.")}</p>
      <div class="webapp-auth-row">
        <span class="badge-outline">${t("appShell.authGuest", "Guest mode")}</span>
        <button id="pw-profile-signin" class="btn" type="button">${t("appShell.signIn", "Sign in")}</button>
        <button id="pw-profile-signup" class="btn btn-outline" type="button">${t("appShell.signUp", "Sign up")}</button>
      </div>
      <p class="muted pw-profile-guest-forgot"><a href="/forgot-password">${t("signin.forgot", "Forgot password?")}</a></p>
    </section>
  `;
}

async function renderClubDetail(supabase, session) {
  if (!session?.user) {
    return `<section class="app-panel"><h2>${t("route.clubs.title", "Book clubs")}</h2><p>${t("route.authRequired", "Please sign in to view this section.")}</p></section>`;
  }
  const params = new URLSearchParams(window.location.search);
  const clubId = String(params.get("id") || "").trim();
  if (!clubId) {
    return `<section class="app-panel"><h2>${t("route.clubs.clubForum", "Club")}</h2><p class="muted">${t("route.clubs.missingId", "Missing club. Go back to Clubs.")}</p><p><a href="/clubs" data-link-route="/clubs">${t("route.clubs.backToClubs", "Back to clubs")}</a></p></section>`;
  }
  const { data: club, error: clubErr } = await supabase
    .from("book_clubs")
    .select("id, name, description, cover_emoji, invite_code, max_members, created_by, is_private, current_book_id, member_count, created_at")
    .eq("id", clubId)
    .maybeSingle();
  if (clubErr || !club) {
    return `<section class="app-panel"><h2>${t("route.clubs.clubForum", "Club")}</h2><p>${t("route.clubs.loadFailed", "We could not load this club.")}</p><p><a href="/clubs" data-link-route="/clubs">${t("route.clubs.backToClubs", "Back to clubs")}</a></p></section>`;
  }
  const { data: myMember } = await supabase
    .from("book_club_members")
    .select("role")
    .eq("club_id", clubId)
    .eq("user_id", session.user.id)
    .maybeSingle();
  const isMember = Boolean(myMember);
  const isCreator = club.created_by === session.user.id;

  const { data: msgRows, error: msgErr } = await supabase
    .from("book_club_messages")
    .select("id, user_id, content, message_type, chapter_ref, created_at, contains_spoiler")
    .eq("club_id", clubId)
    .order("created_at", { ascending: true })
    .limit(200);
  if (msgErr) {
    return `<section class="app-panel"><h2>${escapeHtml(club.name || "Club")}</h2><p>${t("appShell.missingData", "Something went wrong.")}</p></section>`;
  }
  const messages = msgRows || [];
  const uids = [...new Set(messages.map((m) => m.user_id))];
  let nameBy = {};
  if (uids.length) {
    const { data: profs } = await supabase.from("profiles").select("id, display_name, username").in("id", uids);
    nameBy = Object.fromEntries((profs || []).map((p) => [p.id, p.display_name || p.username || String(p.id).slice(0, 6)]));
  }
  const back = `<p class="pw-club-detail__back"><a href="/clubs" data-link-route="/clubs">← ${t("route.clubs.backToClubs", "Back to clubs")}</a></p>`;
  const head = `
    <header class="pw-club-detail__head app-panel">
      <p class="pw-club-detail__emoji">${escapeHtml(club.cover_emoji || "📚")}</p>
      <h2>${escapeHtml(club.name || t("route.clubs.unnamed", "Club"))}</h2>
      <p class="pw-club-detail__desc">${escapeHtml(club.description || "")}</p>
      <p class="metric">${t("route.clubs.members", "Members")}: ${Number(club.member_count || 0)}/${Number(club.max_members || 20)}</p>
      ${isCreator || isMember ? `<p class="muted">${t("route.clubs.code", "Code")}: ${escapeHtml(club.invite_code || "—")}</p>` : ""}
    </header>
  `;
  if (!isMember) {
    return `
      <section class="app-panel pw-club-detail">
        ${back}
        ${head}
        <p class="muted">${t("route.clubs.forumMemberOnly", "Join this club to read and post in the book forum. Use Profile → Book clubs to join with a code, or request access from the club card on Browse.")}</p>
      </section>
    `;
  }
  const meId = session.user.id;
  const fmtTime = (iso) => {
    try {
      return new Date(iso).toLocaleString(undefined, { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" });
    } catch (_) {
      return String(iso || "");
    }
  };
  const msgBubbles = messages.length
    ? messages
        .map((m) => {
          const isMe = m.user_id === meId;
          const who = escapeHtml(nameBy[m.user_id] || "?");
          const time = escapeHtml(fmtTime(m.created_at));
          const chip =
            m.chapter_ref != null
              ? `<span class="pw-club-chat__chip">${t("route.clubs.chapter", "Ch.")} ${escapeHtml(String(m.chapter_ref))}</span>`
              : "";
          return `
        <li class="pw-club-chat__row${isMe ? " pw-club-chat__row--me" : ""}">
          <div class="pw-club-chat__bubble">
            <div class="pw-club-chat__bubble-meta">
              <span class="pw-club-chat__who">${isMe ? t("route.clubs.chatYou", "You") : who}</span>
              ${chip}
              <time class="pw-club-chat__time" datetime="${escapeHtml(m.created_at || "")}">${time}</time>
            </div>
            <p class="pw-club-chat__text">${m.contains_spoiler ? `<em class="pw-club-chat__spoiler-flag">${t("route.clubs.spoiler", "Spoiler")}</em> ` : ""}${escapeHtml(m.content || "")}</p>
          </div>
        </li>`;
        })
        .join("")
    : "";
  return `
    <section class="app-panel pw-club-detail">
      ${back}
      ${head}
      <h3 class="pw-club-chat__title">${t("route.clubs.chatTitle", "Group chat")}</h3>
      <p class="muted pw-club-chat__hint">${t(
        "route.clubs.chatHint",
        "Everyone in the club can read and post here. New messages appear at the bottom—scroll up for older ones.",
      )}</p>
      <div class="pw-club-chat" aria-label="${t("route.clubs.chatTitle", "Group chat")}">
        <div id="pw-club-chat-scroll" class="pw-club-chat__scroll" tabindex="0" role="log" aria-relevant="additions" aria-live="polite">
          ${
            messages.length
              ? `<ol class="pw-club-chat__list">${msgBubbles}</ol>`
              : `<p class="pw-club-chat__empty muted">${t("route.clubs.chatEmpty", "No messages yet. Say hi below—others will see it here, like a group chat.")}</p>`
          }
        </div>
        <form id="pw-club-forum-form" class="pw-club-chat__composer" autocomplete="off">
          <div class="pw-club-chat__input-wrap">
            <label class="visually-hidden" for="pw-club-forum-body">${t("route.clubs.forumMessage", "Message")}</label>
            <textarea
              id="pw-club-forum-body"
              class="pw-club-chat__textarea"
              rows="3"
              maxlength="2000"
              required
              placeholder="${t("route.clubs.chatPlaceholder", "Message the group…")}"
            ></textarea>
            <button type="submit" class="btn pw-club-chat__send" aria-label="${t("route.clubs.send", "Send")}">${t("route.clubs.send", "Send")}</button>
          </div>
          <details class="pw-club-chat__options">
            <summary>${t("route.clubs.chatOptions", "Chapter & spoiler")}</summary>
            <div class="pw-club-chat__options-row">
              <label><span>${t("route.clubs.chapterRef", "Chapter (optional)")}</span><input id="pw-club-forum-chapter" type="number" min="0" step="1" placeholder="0" /></label>
              <label class="pw-checkbox">
                <input type="checkbox" id="pw-club-forum-spoiler" />
                <span>${t("route.clubs.markSpoiler", "Mark as spoiler")}</span>
              </label>
            </div>
          </details>
          <input type="hidden" id="pw-club-forum-club-id" value="${escapeHtml(clubId)}" />
        </form>
      </div>
    </section>
  `;
}

function bindClubDetailActions(supabase, session, rerender) {
  const form = document.getElementById("pw-club-forum-form");
  form?.addEventListener("submit", async (event) => {
    event.preventDefault();
    const clubId = document.getElementById("pw-club-forum-club-id")?.value || "";
    const body = String(document.getElementById("pw-club-forum-body")?.value || "").trim();
    const chRaw = document.getElementById("pw-club-forum-chapter")?.value;
    const chapterRef = chRaw === "" || chRaw == null ? null : Math.max(0, parseInt(chRaw, 10) || 0);
    const spoiler = Boolean(document.getElementById("pw-club-forum-spoiler")?.checked);
    if (!clubId || !body) return;
    try {
      const { data: freshAuth, error: se } = await supabase.auth.getSession();
      if (se) throw se;
      const uid = freshAuth?.session?.user?.id;
      if (!uid) throw new Error("sign_in");
      const { error } = await supabase.from("book_club_messages").insert({
        club_id: clubId,
        user_id: uid,
        content: body,
        message_type: "text",
        contains_spoiler: spoiler,
        chapter_ref: chapterRef,
      });
      if (error) throw error;
      rerender();
    } catch (error) {
      showBanner("error", error?.message || t("appShell.missingData", "Something went wrong."));
    }
  });
}

async function renderClubs(supabase, session) {
  if (!session?.user) {
    return `<section class="app-panel"><h2>${t("route.clubs.title", "Book clubs")}</h2><p>${t("route.authRequired", "Please sign in to view this section.")}</p></section>`;
  }

  const clubs = await runSafeQuery(async () => {
    const { data, error } = await supabase
      .from("book_clubs")
      .select("id, name, description, invite_code, cover_emoji, max_members, created_by, is_private, member_count")
      .order("created_at", { ascending: false })
      .limit(50);
    if (error) throw error;
    return data || [];
  }, t("appShell.missingClubs", "Could not load book_clubs."));

  const cleanClubs = clubs.filter((c) => !c.__error);
  const clubIds = cleanClubs.map((c) => c.id);
  const myCreatedIds = cleanClubs.filter((c) => c.created_by === session.user.id).map((c) => c.id);

  let myMemberships = await runSafeQuery(async () => {
    const { data, error } = await supabase
      .from("book_club_members")
      .select("club_id, role")
      .eq("user_id", session.user.id);
    if (error) throw error;
    return data || [];
  }, "");
  if (Array.isArray(myMemberships) && myMemberships[0]?.__error) {
    myMemberships = [];
  }
  const myRoleByClub = Object.fromEntries(
    (Array.isArray(myMemberships) ? myMemberships : [])
      .filter((r) => r && !r.__error)
      .map((m) => [m.club_id, m.role || "member"]),
  );

  let myRequestByClub = {};
  const reqRows = await runSafeQuery(async () => {
    const { data, error } = await supabase
      .from("book_club_join_requests")
      .select("club_id, status")
      .eq("user_id", session.user.id);
    if (error) throw error;
    return data || [];
  }, "");
  if (Array.isArray(reqRows) && !reqRows[0]?.__error) {
    myRequestByClub = Object.fromEntries(reqRows.filter((r) => r && !r.__error).map((r) => [r.club_id, r.status]));
  }

  let incomingRows = [];
  if (myCreatedIds.length) {
    const inc = await runSafeQuery(async () => {
      const { data, error } = await supabase
        .from("book_club_join_requests")
        .select("id, club_id, user_id, status, created_at")
        .eq("status", "pending")
        .in("club_id", myCreatedIds);
      if (error) throw error;
      return data || [];
    }, "");
    if (Array.isArray(inc) && !inc[0]?.__error) {
      const rows = inc.filter((r) => r && !r.__error);
      const uids = [...new Set(rows.map((r) => r.user_id))];
      let profById = {};
      if (uids.length) {
        const { data: profs } = await supabase.from("profiles").select("id, display_name, username").in("id", uids);
        profById = Object.fromEntries((profs || []).map((p) => [p.id, p]));
      }
      const nameByClub = Object.fromEntries(cleanClubs.map((c) => [c.id, c.name]));
      incomingRows = rows.map((r) => ({
        ...r,
        _clubName: nameByClub[r.club_id] || t("route.clubs.unnamed", "Club"),
        _uname:
          profById[r.user_id]?.display_name || profById[r.user_id]?.username || String(r.user_id).slice(0, 6),
      }));
    }
  }

  const incomingBlock =
    incomingRows.length > 0
      ? `
    <div class="app-panel pw-club-incoming">
      <h3>${t("route.clubs.incomingTitle", "Join requests for your clubs")}</h3>
      <ul class="pw-club-incoming__list">
        ${incomingRows
          .map((r) => {
            const clubName = r._clubName || t("route.clubs.unnamed", "Club");
            const uname = r._uname || String(r.user_id).slice(0, 8);
            return `
            <li class="pw-club-incoming__item">
              <div>
                <strong>${escapeHtml(clubName)}</strong>
                <span class="muted"> · ${escapeHtml(uname)}</span>
              </div>
              <div class="pw-club-incoming__actions">
                <button type="button" class="btn" data-club-approve="${escapeHtml(r.id)}" data-club-approve-club="${escapeHtml(
                  r.club_id,
                )}" data-club-approve-user="${escapeHtml(r.user_id)}">${t("route.clubs.approve", "Approve")}</button>
                <button type="button" class="btn btn-outline" data-club-reject="${escapeHtml(r.id)}">${t(
                  "route.clubs.reject",
                  "Decline",
                )}</button>
              </div>
            </li>`;
          })
          .join("")}
      </ul>
    </div>
  `
      : "";

  return `
    <section class="app-panel">
      <h2>${t("route.clubs.title", "Book clubs")}</h2>
      <p class="muted pw-club-lede">${t(
        "route.clubs.browseLede",
        "Open-directory clubs are listed below: member counts and request-to-join. Invite-only clubs stay off the list (use a code). Club owners can approve join requests in the next section when present.",
      )}</p>
      ${incomingBlock}
      <h3 class="pw-club-browse__title">${t("route.clubs.browseTitle", "Browse clubs")}</h3>
      <div class="app-grid app-grid-2 pw-club-browse-grid">
        ${
          cleanClubs.length
            ? cleanClubs
                .map((c) => {
                  const mcount = c.member_count != null ? Number(c.member_count) : 0;
                  const maxM = c.max_members || 20;
                  const myRole = myRoleByClub[c.id];
                  const isCreator = c.created_by === session.user.id;
                  const atCapacity = mcount >= maxM;
                  const req = myRequestByClub[c.id];
                  const isListed = c.is_private === false;
                  const showCode = isCreator || Boolean(myRole);
                  return `
              <article class="app-panel pw-club-card" data-club-id="${escapeHtml(c.id)}">
                <div class="pw-club-card__head">
                  <h3><span class="pw-club-card__emoji">${escapeHtml(c.cover_emoji || "📚")}</span> ${escapeHtml(c.name || "Club")}</h3>
                  ${isListed ? `<span class="pw-club-badge">${t("route.clubs.listedBadge", "In directory")}</span>` : ""}
                </div>
                <p>${escapeHtml(c.description || "")}</p>
                <p class="metric">${t("route.clubs.members", "Members")}: ${mcount}/${escapeHtml(String(maxM))}</p>
                ${showCode ? `<p class="muted">${t("route.clubs.code", "Code")}: ${escapeHtml(c.invite_code || "—")}</p>` : ""}
                <div class="pw-club-card__ctas">
                  <a class="btn" href="/club?id=${encodeURIComponent(c.id)}" data-link-route="/club">${t("route.clubs.openClub", "Open club")}</a>
                  <div class="pw-club-card__actions">${renderClubCardFooter(c, { myRole, requestStatus: req, atCapacity })}</div>
                </div>
              </article>
            `;
                })
                .join("")
            : !clubs[0]?.__error
              ? `<p class="muted">${t("route.clubs.emptyBrowse", "No clubs to show yet. Create one and list it in the directory, or ask a friend to share a code.")}</p>`
              : ""
        }
        ${clubs[0]?.__error ? `<article class="app-panel"><p>${escapeHtml(clubs[0].text)}</p></article>` : ""}
      </div>
      <p class="muted pw-clubs-footer-hint">${t("route.clubs.browseSetupHint", "To create a club or join with a code, go to Profile and open the Book clubs tab.")}</p>
    </section>
  `;
}

async function renderReader(supabase, session) {
  if (!session?.user) {
    return `<section class="app-panel"><h2>${t("route.reader.title", "Reader tools")}</h2><p>${t("route.authRequired", "Please sign in to view this section.")}</p></section>`;
  }
  const [sessions, history] = await Promise.all([
    runSafeQuery(async () => {
      const { data, error } = await supabase
        .from("reading_sessions")
        .select("duration_seconds, started_at, ended_at, pages_read, created_at")
        .eq("user_id", session.user.id)
        .order("created_at", { ascending: false })
        .limit(30);
      if (error) throw error;
      return data || [];
    }, t("appShell.missingSessions", "Could not load reading_sessions.")),
    runSafeQuery(async () => {
      const { data, error } = await supabase
        .from("reading_history")
        .select("book_title, book_author, source, is_finished, last_read_at")
        .eq("user_id", session.user.id)
        .order("last_read_at", { ascending: false })
        .limit(12);
      if (error) throw error;
      return data || [];
    }, t("appShell.missingHistory", "Could not load reading_history.")),
  ]);

  const totalMinutes = sessions.reduce((sum, x) => {
    if (x.__error) return sum;
    return sum + Math.round(Number(x.duration_seconds || 0) / 60);
  }, 0);
  const historyItems = history.map((h) => {
    if (h.__error) return `<span>${escapeHtml(h.text)}</span>`;
    return `<strong>${escapeHtml(h.book_title || "Book")}</strong><span>${escapeHtml(h.book_author || "")} · ${escapeHtml(h.source || "web")} · ${h.is_finished ? t("route.reader.finished", "Finished") : t("route.reader.inProgress", "In progress")}</span>`;
  });
  const latestSessions = sessions
    .filter((x) => !x.__error)
    .slice(0, 6)
    .map((x) => {
      const seconds = Number(x.duration_seconds || 0);
      const pages = Number(x.pages_read || 0);
      return `<li><strong>${formatDuration(seconds)}</strong><span>${pages > 0 ? `${pages} ${t("route.reader.pages", "pages")} · ` : ""}${escapeHtml(x.ended_at || x.started_at || "")}</span></li>`;
    });

  return `
    <section class="app-panel">
      <h2>${t("route.reader.title", "Reader tools")}</h2>
      <p class="metric">${t("route.reader.minutes", "Total minutes (latest sessions)")}: ${totalMinutes}</p>
      <article class="app-panel">
        <h3>${t("route.reader.timerTitle", "Reading timer")}</h3>
        <p class="metric" id="pw-reader-timer-value">${formatDuration(readerTimer.elapsedSeconds)}</p>
        <div class="cta-actions">
          <button class="btn" id="pw-reader-start-pause">${readerTimer.running ? t("route.reader.pause", "Pause") : t("route.reader.start", "Start reading")}</button>
          <button class="btn btn-outline" id="pw-reader-finish"${readerTimer.elapsedSeconds > 0 ? "" : " disabled"}>${t("route.reader.finish", "Finish session")}</button>
        </div>
        <label>
          <span>${t("route.reader.pagesRead", "Pages read this session")}</span>
          <input id="pw-reader-pages" type="number" min="0" step="1" value="0" />
        </label>
      </article>
      <article class="app-panel">
        <h3>${t("route.reader.historyTitle", "Log reading history")}</h3>
        <form id="pw-reader-history-form" class="form-stack">
          <label><span>${t("route.reader.bookTitle", "Book title")}</span><input id="pw-reader-book-title" type="text" maxlength="200" required /></label>
          <label><span>${t("route.reader.bookAuthor", "Book author")}</span><input id="pw-reader-book-author" type="text" maxlength="200" /></label>
          <label><span>${t("route.reader.source", "Source")}</span><input id="pw-reader-source" type="text" value="web" maxlength="120" /></label>
          <label><span>${t("route.reader.finishedQuestion", "Mark as finished?")}</span><input id="pw-reader-finished" type="checkbox" /></label>
          <button type="submit" class="btn">${t("route.reader.saveHistory", "Save history item")}</button>
        </form>
      </article>
      <article class="app-panel">
        <h3>${t("route.reader.latestSessions", "Latest sessions")}</h3>
        ${listToHtml(latestSessions)}
      </article>
      ${listToHtml(historyItems)}
    </section>
  `;
}

async function renderProfile(supabase, session) {
  if (!session?.user) {
    return `
      <div class="pw-profile-route">
        ${renderProfileGuestCta()}
        <section class="app-panel"><h2>${t("route.profile.title", "Profile")}</h2><p>${t("route.authRequired", "Please sign in to view this section.")}</p></section>
      </div>
    `;
  }

  const profiles = await runSafeQuery(async () => {
    const { data, error } = await supabase
      .from("profiles")
      .select(
        "username, full_name, display_name, bio, avatar_url, location, favourite_genre, reading_goal, is_public",
      )
      .eq("id", session.user.id)
      .maybeSingle();
    if (error) throw error;
    return data ? [data] : [];
  }, t("appShell.missingProfile", "Could not load profile."));

  const profile = profiles[0] || {};
  if (profiles[0]?.__error) {
    return `
      <div class="pw-profile-route">
        <section class="app-panel">
          <h2>${t("route.profile.title", "Profile")}</h2>
          <p class="muted">${escapeHtml(profiles[0].text)}</p>
        </section>
      </div>
    `;
  }

  if (!profile?.username) {
    try {
      const emailPrefix = String(session.user.email || "reader")
        .split("@")[0]
        .toLowerCase()
        .replace(/[^a-z0-9]/g, "");
      await withTimeout(
        supabase.from("profiles").upsert({
          id: session.user.id,
          username: emailPrefix || "reader",
          display_name: emailPrefix || "reader",
        }),
        12000,
      );
      profile.username = emailPrefix || "reader";
      profile.display_name = emailPrefix || "reader";
    } catch (_) {}
  }

  const [userBooks, diaryRows] = await Promise.all([
    runSafeQuery(async () => {
      const { data, error } = await supabase
        .from("user_books")
        .select("title, author, status, book_id, created_at, books(id, cover_url)")
        .eq("user_id", session.user.id)
        .order("updated_at", { ascending: false })
        .limit(48);
      if (error) throw error;
      return data || [];
    }, t("route.profile.booksUnavailable", "Books unavailable.")),
    runSafeQuery(async () => {
      const { data, error } = await supabase
        .from("reading_history")
        .select("book_title, book_author, last_read_at, is_finished")
        .eq("user_id", session.user.id)
        .order("last_read_at", { ascending: false })
        .limit(8);
      if (error) throw error;
      return data || [];
    }, t("route.profile.diaryUnavailable", "Diary unavailable.")),
  ]);

  const favBooks = userBooks.filter((x) => !x.__error && x.status === "read").slice(0, 4);
  const listCounts = LIBRARY_STATUSES.reduce((acc, status) => {
    acc[status] = userBooks.filter((x) => !x.__error && x.status === status).length;
    return acc;
  }, {});
  const avatarUrl = profile.avatar_url ? String(profile.avatar_url).trim() : "";
  const displayName =
    profile.display_name || profile.full_name || profile.username || t("route.profile.defaultName", "Reader");
  const letterFallback = escapeHtml(displayName.trim().charAt(0) || "?").toUpperCase();
  const handle = profile.username ? `@${profile.username}` : "";
  const readingGoal = Number(profile.reading_goal) > 0 ? Number(profile.reading_goal) : 12;
  const isPublic = profile.is_public !== false;
  const profileTab =
    new URLSearchParams(typeof window !== "undefined" ? window.location.search : "").get("tab") === "clubs"
      ? "clubs"
      : "account";
  const showClubsTab = profileTab === "clubs";

  return `
    <div class="pw-profile-route">
      <header class="app-panel pw-profile-hero">
        <div class="pw-profile-hero__top">
          <div class="pw-profile-photo-wrap">
            ${
              avatarUrl
                ? `<img class="pw-profile-avatar-lg" id="pw-profile-avatar-preview" src="${escapeHtml(avatarUrl)}" alt="${t("userMenu.profilePhotoAlt", "Profile photo")}" width="96" height="96" loading="lazy" />`
                : `<div class="pw-profile-avatar-lg pw-profile-avatar-lg--empty" id="pw-profile-avatar-fallback" aria-hidden="true">${letterFallback}</div>`
            }
          </div>
          <div class="pw-profile-hero__meta">
            <p class="pw-kicker">${t("route.profile.kicker", "Your account")}</p>
            <h1 class="pw-profile-hero__name">${escapeHtml(displayName)}</h1>
            ${handle ? `<p class="pw-profile-handle">${escapeHtml(handle)}</p>` : ""}
            <p class="pw-profile-bio-preview">${escapeHtml(profile.bio || t("route.profile.bioEmpty", "No bio yet."))}</p>
          </div>
        </div>
        <div class="pw-profile-hero__bar">
          <div class="pw-profile-hero__chips">
            <span class="badge-outline">${t("appShell.authSignedIn", "Signed in")}</span>
            <span class="muted pw-profile-email">${escapeHtml(maskEmailForDisplay(session.user.email))}</span>
          </div>
          <div class="pw-profile-hero__actions">
            <a class="btn btn-outline" href="/library" data-link-route="/library">${t("route.profile.openLibrary", "Open library")}</a>
            <button type="button" class="btn btn-outline" id="pw-profile-signout">${t("appShell.signOut", "Sign out")}</button>
          </div>
        </div>
        <div class="pw-profile-photo-actions pw-profile-photo-actions--hero">
          <input type="file" id="pw-profile-photo-file" class="visually-hidden" accept="image/jpeg,image/png,image/webp" />
          <button type="button" class="btn btn-outline" id="pw-profile-photo-pick">${t("route.profile.photoChoose", "Upload photo")}</button>
          <button type="button" class="btn btn-outline" id="pw-profile-photo-remove"${avatarUrl ? "" : " hidden"}>${t("route.profile.photoRemove", "Remove photo")}</button>
        </div>
        <p class="muted" id="pw-profile-photo-status" role="status" hidden></p>
      </header>

      <div class="pw-profile-tabs" role="tablist" aria-label="${t("route.profile.tablistLabel", "Profile sections")}">
        <button type="button" class="pw-profile-tab" role="tab" id="pw-profile-tab-btn-account" data-profile-tab="account" aria-selected="${!showClubsTab ? "true" : "false"}" aria-controls="pw-profile-panel-account">${t("route.profile.tabAccount", "Account")}</button>
        <button type="button" class="pw-profile-tab" role="tab" id="pw-profile-tab-btn-clubs" data-profile-tab="clubs" aria-selected="${showClubsTab ? "true" : "false"}" aria-controls="pw-profile-panel-clubs">${t("route.profile.tabClubs", "Book clubs")}</button>
      </div>

      <div id="pw-profile-panel-clubs" class="pw-profile-panel" role="tabpanel" aria-labelledby="pw-profile-tab-btn-clubs" ${showClubsTab ? "" : "hidden"}>
        <section class="app-panel">
          <h2>${t("route.profile.tabClubs", "Book clubs")}</h2>
          <p class="muted">${t("route.profile.clubTabLede", "Start a new club or join with an invite code. Then use Clubs in the menu to open your club and use the book forum.")}</p>
          ${renderClubSetupFormsHtml()}
        </section>
      </div>

      <div id="pw-profile-panel-account" class="pw-profile-panel" role="tabpanel" aria-labelledby="pw-profile-tab-btn-account" ${showClubsTab ? "hidden" : ""}>
        <form id="pw-profile-form" class="app-panel pw-profile-settings" novalidate>
          <div class="pw-section-head">
            <h2>${t("route.profile.settingsTitle", "Account settings")}</h2>
            <button type="submit" class="btn" id="pw-profile-save">${t("route.profile.save", "Save changes")}</button>
          </div>
          <p class="pw-section-note muted">${t("route.profile.settingsLede", "Same fields as the Pagewalker app — changes sync across web and mobile.")}</p>
          <p class="muted" id="pw-profile-save-status" role="status" hidden></p>

          <fieldset class="pw-profile-fieldset">
            <legend>${t("route.profile.sectionPersonal", "Personal")}</legend>
            <div class="pw-profile-form-grid">
              <label>
                <span>${t("route.profile.displayName", "Display name")}</span>
                <input name="display_name" type="text" maxlength="80" value="${escapeHtml(profile.display_name || profile.full_name || "")}" autocomplete="name" />
              </label>
              <label>
                <span>${t("route.profile.username", "Username")}</span>
                <input name="username" type="text" maxlength="32" value="${escapeHtml(profile.username || "")}" autocomplete="username" autocapitalize="off" spellcheck="false" required />
              </label>
              <label class="pw-profile-span-2">
                <span>${t("route.profile.bioLabel", "Bio")}</span>
                <textarea name="bio" rows="3" maxlength="150" placeholder="${t("route.profile.bioPlaceholder", "A line about your reading taste…")}">${escapeHtml(profile.bio || "")}</textarea>
              </label>
              <label>
                <span>${t("route.profile.location", "Location")}</span>
                <input name="location" type="text" maxlength="80" value="${escapeHtml(profile.location || "")}" autocomplete="address-level2" />
              </label>
              <label>
                <span>${t("route.profile.favouriteGenre", "Favourite genre")}</span>
                <input name="favourite_genre" type="text" maxlength="60" value="${escapeHtml(profile.favourite_genre || "")}" />
              </label>
            </div>
          </fieldset>

          <fieldset class="pw-profile-fieldset">
            <legend>${t("route.profile.sectionReading", "Reading")}</legend>
            <div class="pw-profile-form-grid">
              <label>
                <span>${t("route.profile.readingGoal", "Books to read this year")}</span>
                <input name="reading_goal" type="number" min="1" max="999" step="1" value="${readingGoal}" />
              </label>
              <div class="pw-profile-stat-chip">
                <span class="muted">${t("route.profile.onShelfRead", "On your Read shelf")}</span>
                <strong>${listCounts.read || 0}</strong>
              </div>
            </div>
          </fieldset>

          <fieldset class="pw-profile-fieldset">
            <legend>${t("route.profile.sectionPrivacy", "Privacy")}</legend>
            <label class="pw-profile-check">
              <input name="is_public" type="checkbox"${isPublic ? " checked" : ""} />
              <span>${t("route.profile.publicProfile", "Show my profile to other readers")}</span>
            </label>
            <p class="muted pw-profile-field-hint">${t("route.profile.emailHint", "Shown masked on web. Use the app or support@pagewalker.org for account help.")}</p>
          </fieldset>
        </form>

        <section class="app-panel pw-profile-shelf">
          <div class="pw-section-head">
            <h3>${t("route.profile.favoritesTitle", "Top 4 favorites")}</h3>
            <a href="/library" data-link-route="/library">${t("route.profile.manageLibrary", "Manage in Library")}</a>
          </div>
          <p class="pw-section-note muted">${t("route.profile.favoritesHint", "Your four most recently finished books appear here.")}</p>
          <div class="pw-favorites-grid">
            ${Array.from({ length: 4 })
              .map((_, i) => {
                const book = favBooks[i];
                const cover = fixCoverUrl(book?.books?.cover_url);
                const title = escapeHtml(book?.title || "");
                if (!book) {
                  return `<div class="pw-fav-slot pw-fav-slot--empty" aria-label="${t("route.profile.favEmpty", "Empty favorite slot")}"><span>+</span></div>`;
                }
                return `
                  <figure class="pw-fav-slot pw-fav-slot--filled">
                    ${cover ? `<img src="${escapeHtml(cover)}" alt="${title} cover" loading="lazy" />` : `<span class="pw-fav-slot__fallback">${title.slice(0, 1) || "B"}</span>`}
                    <figcaption>${title}</figcaption>
                  </figure>
                `;
              })
              .join("")}
          </div>
        </section>

        <div class="app-grid app-grid-2 pw-profile-secondary">
          <article class="app-panel">
            <h3>${t("route.profile.diaryTitle", "Diary")}</h3>
            ${
              diaryRows.some((x) => !x.__error)
                ? `<ul class="app-list pw-profile-diary">
            ${diaryRows
              .filter((x) => !x.__error)
              .map(
                (row) =>
                  `<li><strong>${escapeHtml(row.book_title || "Book")}</strong><span>${escapeHtml(row.book_author || "")} · ${row.is_finished ? t("route.reader.finished", "Finished") : t("route.reader.inProgress", "In progress")}${row.last_read_at ? ` · ${escapeHtml(String(row.last_read_at).slice(0, 10))}` : ""}</span></li>`,
              )
              .join("")}
          </ul>`
                : `<p class="muted">${t("route.profile.diaryEmpty", "Your diary entries will show up here.")}</p>`
            }
          </article>
          <article class="app-panel">
            <h3>${t("route.profile.listsTitle", "My lists")}</h3>
            <div class="pw-list-collage">
              ${LIBRARY_STATUSES.map(
                (status) => `
                <a class="pw-shelf-stat" href="/library" data-link-route="/library">
                  <strong>${STATUS_LABELS[status]}</strong>
                  <span>${listCounts[status] || 0}</span>
                </a>`,
              ).join("")}
            </div>
          </article>
        </div>
      </div>
    </div>
  `;
}

async function renderBookRoute(supabase, session) {
  const params = new URLSearchParams(window.location.search);
  const stableId = String(params.get("id") || "").trim();
  if (stableId) {
    try {
      const fetched = await fetchJsonCached(`/api/books?type=detail&id=${encodeURIComponent(stableId)}`);
      const bid = String(fetched?.id || stableId).trim();
      const raw = await runSafeQuery(
        () => fetchReviewsForBook(supabase, bid, 40),
        t("appShell.missingReviews", "Could not load reviews."),
      );
      const reviewsError = raw.find((r) => r?.__error)?.text || "";
      const list = raw.filter((r) => r && !r.__error);
      return buildBookPageHtml(fetched, {
        reviews: list,
        session,
        panelOpen: bookPageReviewPanelOpen,
        reviewsError,
      });
    } catch (error) {
      const msg = String(error?.message || "");
      const notFound = msg.includes("request_failed_404");
      const unavailable = msg.includes("request_failed_5");
      return `
        <section class="app-panel">
          <h2>Book details</h2>
          <p class="muted">${
            notFound
              ? "This book link no longer exists or was removed by the source provider."
              : unavailable
                ? "Book data is temporarily unavailable. Please try again in a moment."
                : "We could not load this book right now. Try opening it again from Discover."
          }</p>
          <p><a href="/explore" data-link-route="/explore">${t("home.goExplore", "Go to Explore")}</a></p>
        </section>
      `;
    }
  }
  const raw = params.get("data");
  const book = decodeBookPayload(raw);
  if (!book) {
    return `
      <section class="app-panel">
        <h2>Book details</h2>
        <p class="muted">This link is missing data. Open a book from Discover or Library first.</p>
        <p><a href="/explore" data-link-route="/explore">${t("home.goExplore", "Go to Explore")}</a></p>
      </section>
    `;
  }
  const bid = String(book?.id || "").trim();
  const rRaw = await runSafeQuery(
    () => fetchReviewsForBook(supabase, bid, 40),
    t("appShell.missingReviews", "Could not load reviews."),
  );
  const reviewsError = rRaw.find((r) => r?.__error)?.text || "";
  const list = rRaw.filter((r) => r && !r.__error);
  return buildBookPageHtml(book, { reviews: list, session, panelOpen: bookPageReviewPanelOpen, reviewsError });
}

function renderProtectedRouteGate(route) {
  const routeNameMap = {
    "/explore": t("appNav.explore", "Explore"),
    "/library": t("appNav.library", "Library"),
    "/social": t("appNav.social", "Social"),
    "/clubs": t("appNav.clubs", "Clubs"),
    "/reader": t("appNav.reader", "Reader"),
    "/profile": t("appNav.profile", "Profile"),
  };
  return `
    <section class="app-panel pw-route-gate">
      <h2>${t("route.locked.title", "Sign in required")}</h2>
      <p>${t("route.locked.body", "To view in-depth product content on web, please sign in first.")}</p>
      <p class="muted">${t("route.locked.target", "Requested section")}: ${escapeHtml(routeNameMap[route] || route)}</p>
      <div class="cta-actions">
        <button id="pw-locked-signin" class="btn">${t("appShell.signIn", "Sign in")}</button>
        <button id="pw-locked-signup" class="btn btn-outline">${t("appShell.signUp", "Sign up")}</button>
      </div>
      <p class="muted" style="margin-top:12px;text-align:center">
        <a href="/forgot-password">${t("signin.forgot", "Forgot password?")}</a>
      </p>
    </section>
  `;
}

function renderRouteSkeleton(route) {
  if (route === "/") {
    return `
      <div class="pw-home">
        <section class="pw-home-hero pw-shimmer-block" style="min-height: 20rem;border-radius:0"></section>
        <section class="pw-home-pillars wrap">
          ${Array.from({ length: 4 }).map(() => `<div class="pw-pillar pw-shimmer-block" style="min-height:5rem"></div>`).join("")}
        </section>
        <section class="pw-home-scroll">
          ${Array.from({ length: 6 }).map(() => `<article class="pw-poster-card"><div class="pw-poster-media pw-shimmer-block"></div></article>`).join("")}
        </section>
      </div>
    `;
  }
  return `
    <section class="app-panel">
      <div class="pw-shimmer-line"></div>
      <div class="pw-shimmer-line"></div>
      <div class="pw-shimmer-line short"></div>
      <div class="pw-poster-grid">
        ${Array.from({ length: 8 }).map(() => `<article class="pw-poster-card"><div class="pw-poster-media pw-shimmer-block"></div><div class="pw-poster-copy"><div class="pw-shimmer-line"></div><div class="pw-shimmer-line short"></div></div></article>`).join("")}
      </div>
    </section>
  `;
}

function bindLockedGateActions() {
  const signInBtn = document.getElementById("pw-locked-signin");
  const signUpBtn = document.getElementById("pw-locked-signup");
  signInBtn?.addEventListener("click", () => {
    window.location.href = "/sign-in";
  });
  signUpBtn?.addEventListener("click", () => {
    window.location.href = "/sign-up";
  });
  const forgot = document.querySelector('a[href="/forgot-password"]');
  forgot?.addEventListener("click", (e) => {
    e.preventDefault();
    window.location.href = "/forgot-password";
  });
}

function bindDiscoverActions(supabase, session, rerender) {
  const form = document.getElementById("pw-discover-search-form");
  const input = document.getElementById("pw-discover-query");
  form?.addEventListener("submit", (event) => {
    event.preventDefault();
    discoverQuery = String(input?.value || "").trim();
    discoverPaging.searchPage = 1;
    if (isExploreRoute()) {
      const hash = discoverQuery.trim() ? "#search" : window.location.hash || "";
      window.history.replaceState({}, "", `${EXPLORE_PATH}${window.location.search}${hash}`);
      applyDiscoverPanelFromHash();
      setActiveRoute(EXPLORE_PATH);
    }
    rerender();
  });
  const genreButtons = document.querySelectorAll("[data-genre-chip]");
  for (let i = 0; i < genreButtons.length; i += 1) {
    genreButtons[i].addEventListener("click", () => {
      discoverGenre = String(genreButtons[i].getAttribute("data-genre-chip") || "romance");
      discoverQuery = "";
      discoverPaging.genrePage = 1;
      rerender();
    });
  }
  const sourceSelect = document.getElementById("pw-discover-source");
  sourceSelect?.addEventListener("change", () => {
    discoverSourceFilter = String(sourceSelect.value || "all");
    const view = getDiscoverView();
    const cached = _discoverPanelBooks[view] || [];
    const grid = document.querySelector(`[data-discover-grid="${view}"]`);
    if (grid && cached.length) {
      grid.innerHTML = renderDiscoverBooksHtml(cached);
    } else {
      hydrateDiscoverPanels(session);
    }
  });
  const moodSelect = document.getElementById("pw-mood-select");
  const moodInput = document.getElementById("pw-mood-input");
  const syncMoodCustom = () => {
    if (!moodInput || !moodSelect) return;
    if (moodSelect.value === "__custom") moodInput.removeAttribute("hidden");
    else moodInput.setAttribute("hidden", "");
  };
  moodSelect?.addEventListener("change", syncMoodCustom);
  syncMoodCustom();
  const moodForm = document.getElementById("pw-mood-form");
  moodForm?.addEventListener("submit", async (event) => {
    event.preventDefault();
    const sel = document.getElementById("pw-mood-select");
    const mInput = document.getElementById("pw-mood-input");
    let mood = "";
    if (sel?.value === "__custom") mood = String(mInput?.value || "").trim();
    else mood = String(sel?.value || "").trim();
    discoverMood = mood;
    if (!mood) return;
    const resultsRoot = document.getElementById("pw-mood-results");
    if (resultsRoot) {
      resultsRoot.innerHTML = `<p class="muted">${t("route.discover.loadingMood", "Finding recommendations...")}</p>`;
    }
    try {
      const response = await fetch("/api/mood-recommendations", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ mood }),
      });
      const data = await response.json();
      const rows = Array.isArray(data.recommendations) ? data.recommendations : [];
      if (resultsRoot) {
        resultsRoot.innerHTML = rows.length
          ? `<div class="app-grid app-grid-3">${rows.map((r) => `<article class="app-panel"><h4>${escapeHtml(r.title || "Book")}</h4><p>${escapeHtml(r.author || "")}</p><p>${escapeHtml(r.reason || "")}</p></article>`).join("")}</div>`
          : `<p class="muted">${t("route.discover.noMoodResults", "No recommendations yet. Try another mood.")}</p>`;
      }
      if (isExploreRoute()) {
        window.history.replaceState({}, "", `${EXPLORE_PATH}${window.location.search}#search`);
        applyDiscoverPanelFromHash();
        setActiveRoute(EXPLORE_PATH);
      }
    } catch (_) {
      if (resultsRoot) {
        resultsRoot.innerHTML = `<p class="muted">${t("route.discover.noMoodResults", "No recommendations yet. Try another mood.")}</p>`;
      }
    }
  });
  const addButtons = document.querySelectorAll("[data-discover-add]");
  for (let i = 0; i < addButtons.length; i += 1) {
    addButtons[i].addEventListener("click", async (event) => {
      event.stopPropagation();
      if (!guardAuthAction(addButtons[i], session)) return;
      try {
        const raw = addButtons[i].getAttribute("data-book");
        const status = addButtons[i].getAttribute("data-status") || "tbr";
        if (!raw) return;
        const parsed = JSON.parse(raw);
        await upsertUserBookStatus(supabase, session.user.id, parsed, status);
        showBanner("success", t("route.discover.saved", "Saved to your library."));
      } catch (error) {
        showBanner("error", error?.message || t("appShell.missingData", "Something went wrong."));
      }
    });
  }
  const discoverRoot = document.getElementById("pw-discover-root");
  if (discoverRoot && !discoverRoot.dataset.addDelegateBound) {
    discoverRoot.dataset.addDelegateBound = "1";
    discoverRoot.addEventListener("click", async (event) => {
      const btn = event.target instanceof Element ? event.target.closest("[data-discover-add]") : null;
      if (!btn) return;
      event.stopPropagation();
      if (!guardAuthAction(btn, session)) return;
      try {
        const raw = btn.getAttribute("data-book");
        const status = btn.getAttribute("data-status") || "tbr";
        if (!raw || !session?.user) return;
        const parsed = JSON.parse(raw);
        await upsertUserBookStatus(supabase, session.user.id, parsed, status);
        showBanner("success", t("route.discover.saved", "Saved to your library."));
      } catch (error) {
        showBanner("error", error?.message || t("appShell.missingData", "Something went wrong."));
      }
    });
  }
  const loadMoreButtons = document.querySelectorAll("[data-discover-more]");
  for (let i = 0; i < loadMoreButtons.length; i += 1) {
    loadMoreButtons[i].addEventListener("click", () => {
      const mode = String(loadMoreButtons[i].getAttribute("data-discover-more") || "");
      if (mode === "trending") discoverPaging.trendingPage += 1;
      if (mode === "genre") discoverPaging.genrePage += 1;
      if (mode === "search") discoverPaging.searchPage += 1;
      if (mode === "classics") discoverPaging.classicsPage += 1;
      rerender();
    });
  }
  applyDiscoverPanelFromHash();
  if (!window.pwDiscoverHashBound) {
    window.pwDiscoverHashBound = true;
    window.addEventListener("hashchange", () => {
      if (!isExploreRoute()) return;
      applyDiscoverPanelFromHash();
      const pathForNav = window.location.pathname === "/club" ? "/clubs" : window.location.pathname;
      setActiveRoute(pathForNav);
    });
  }
}

function bindLibraryActions(supabase, session, rerender) {
  const filterButtons = document.querySelectorAll("[data-library-filter]");
  for (let i = 0; i < filterButtons.length; i += 1) {
    filterButtons[i].addEventListener("click", () => {
      libraryFilter = filterButtons[i].getAttribute("data-library-filter") || "all";
      rerender();
    });
  }
  const statusButtons = document.querySelectorAll("[data-library-status]");
  for (let i = 0; i < statusButtons.length; i += 1) {
    statusButtons[i].addEventListener("click", async () => {
      try {
        const title = statusButtons[i].getAttribute("data-library-title") || "";
        const status = statusButtons[i].getAttribute("data-library-status") || "tbr";
        const { error } = await supabase
          .from("user_books")
          .update({ status })
          .eq("user_id", session.user.id)
          .eq("title", title);
        if (error) throw error;
        showBanner("success", t("route.library.updated", "Library status updated."));
        rerender();
      } catch (error) {
        showBanner("error", error?.message || t("appShell.missingData", "Something went wrong."));
      }
    });
  }
  const loadMoreBtn = document.querySelector("[data-library-more]");
  loadMoreBtn?.addEventListener("click", () => {
    libraryPage += 1;
    rerender();
  });
}

function bindBookPageActions(supabase, session, rerender) {
  const copyBtn = document.getElementById("pw-book-page-copy");
  copyBtn?.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(window.location.href);
      showBanner("success", "Book link copied.");
    } catch (_) {
      showBanner("error", "Could not copy link.");
    }
  });
  const addBtn = document.querySelector("[data-book-page-add]");
  addBtn?.addEventListener("click", async (event) => {
    event.preventDefault();
    if (!guardAuthAction(addBtn, session)) return;
    try {
      const raw = addBtn.getAttribute("data-book");
      if (!raw) return;
      const parsed = JSON.parse(raw);
      await upsertUserBookStatus(supabase, session.user.id, parsed, "tbr");
      showBanner("success", t("route.discover.saved", "Saved to your library."));
    } catch (error) {
      showBanner("error", error?.message || t("appShell.missingData", "Something went wrong."));
    }
  });
  const reviewBtn = document.querySelector("[data-book-page-review]");
  reviewBtn?.addEventListener("click", (event) => {
    event.preventDefault();
    if (!guardAuthAction(reviewBtn, session)) return;
    bookPageReviewPanelOpen = true;
    rerender();
  });

  const cancelBookReview = document.getElementById("pw-book-review-cancel");
  cancelBookReview?.addEventListener("click", () => {
    bookPageReviewPanelOpen = false;
    rerender();
  });

  const bookReviewForm = document.getElementById("pw-book-review-form");
  bookReviewForm?.addEventListener("submit", async (event) => {
    event.preventDefault();
    if (!session?.user) {
      showBanner("error", t("route.authRequired", "Please sign in to post."));
      return;
    }
    const bookId = String(document.getElementById("pw-book-review-book-id")?.value || "").trim();
    const body = String(document.getElementById("pw-book-review-body")?.value || "").trim();
    const stars = Number(document.getElementById("pw-book-review-stars")?.value || 5);
    const editId = String(document.getElementById("pw-book-review-edit-id")?.value || "").trim();
    const rawAttr =
      reviewBtn?.getAttribute("data-book") ||
      document.querySelector("[data-book-page-add]")?.getAttribute("data-book");
    let bookMeta = { title: "Untitled", author: "" };
    try {
      if (rawAttr) bookMeta = JSON.parse(rawAttr);
    } catch {
      /* ignore */
    }
    if (!bookId) {
      showBanner("error", t("appShell.missingData", "Something went wrong."));
      return;
    }
    if (!body) {
      showBanner("error", t("route.book.reviewTextRequired", "Write something for your review."));
      return;
    }
    try {
      if (editId) {
        const { error: uErr } = await supabase
          .from("reviews")
          .update({
            review_text: body,
            content: body,
            title: bookMeta.title,
            star_rating: stars,
            book_title: bookMeta.title,
            book_author: bookMeta.author || null,
            updated_at: new Date().toISOString(),
          })
          .eq("id", editId)
          .eq("user_id", session.user.id);
        if (uErr) throw uErr;
        showBanner("success", t("route.social.updated", "Review updated."));
      } else {
        const payload = {
          user_id: session.user.id,
          book_id: bookId,
          title: bookMeta.title,
          book_title: bookMeta.title,
          book_author: bookMeta.author || null,
          review_text: body,
          content: body,
          star_rating: Math.max(1, Math.min(5, stars || 5)),
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        };
        let { error } = await supabase.from("reviews").insert(payload);
        if (error && String(error.message || "").toLowerCase().includes("book_id")) {
          const retry = await supabase
            .from("reviews")
            .insert({ ...payload, book_id: "web-review" });
          error = retry.error;
        }
        if (error) throw error;
        showBanner("success", t("route.social.published", "Review published."));
      }
      bookPageReviewPanelOpen = false;
      rerender();
    } catch (error) {
      showBanner("error", error?.message || t("appShell.missingData", "Something went wrong."));
    }
  });

  if (bookPageReviewPanelOpen) {
    requestAnimationFrame(() => {
      document.getElementById("pw-book-review-composer")?.scrollIntoView({ behavior: "smooth", block: "nearest" });
      document.getElementById("pw-book-review-body")?.focus();
    });
  }
}

function bindBookModalActions() {
  const hitAreas = document.querySelectorAll("[data-book-modal]");
  for (let i = 0; i < hitAreas.length; i += 1) {
    hitAreas[i].addEventListener("click", () => {
      const raw = hitAreas[i].getAttribute("data-book-modal");
      if (!raw) return;
      try {
        openBookModal(JSON.parse(raw));
      } catch (_) {}
    });
  }

  const modal = ensureBookModal();
  const closers = modal.querySelectorAll("[data-modal-close]");
  for (let i = 0; i < closers.length; i += 1) {
    if (closers[i].dataset.bound === "true") continue;
    closers[i].addEventListener("click", closeBookModal);
    closers[i].dataset.bound = "true";
  }
  if (!document.body.dataset.modalEscBound) {
    document.addEventListener("keydown", (event) => {
      if (event.key === "Escape") closeBookModal();
    });
    document.body.dataset.modalEscBound = "true";
  }
}

function bindSocialActions(supabase, session, rerender) {
  const form = document.getElementById("pw-social-form");
  const titleInput = document.getElementById("pw-social-title");
  const bodyInput = document.getElementById("pw-social-body");
  const ratingInput = document.getElementById("pw-social-rating");
  const editIdInput = document.getElementById("pw-social-edit-id");
  const compToggle = document.getElementById("pw-social-composer-toggle");
  const compPanel = document.getElementById("pw-social-composer-panel");

  function setComposerOpen(open) {
    if (!compPanel || !compToggle) return;
    compPanel.hidden = !open;
    compToggle.setAttribute("aria-expanded", open ? "true" : "false");
    socialComposerExpanded = open;
  }

  compToggle?.addEventListener("click", () => {
    if (!compPanel) return;
    setComposerOpen(!!compPanel.hidden);
  });

  form?.addEventListener("submit", async (event) => {
    event.preventDefault();
    const title = String(titleInput?.value || "").trim();
    const body = String(bodyInput?.value || "").trim();
    const rating = Number(ratingInput?.value || 5);
    const editId = String(editIdInput?.value || "");
    socialDraft = { title, body, rating: String(rating || 5) };
    if (!title || !body) {
      setComposerOpen(true);
      showBanner("error", t("route.social.validation", "Title and review text are required."));
      return;
    }
    try {
      if (editId) {
        const { error } = await supabase
          .from("reviews")
          .update({
            title,
            review_text: body,
            content: body,
            star_rating: rating,
            updated_at: new Date().toISOString(),
          })
          .eq("id", editId)
          .eq("user_id", session.user.id);
        if (error) throw error;
        showBanner("success", t("route.social.updated", "Review updated."));
      } else {
        const payload = {
          user_id: session.user.id,
          title,
          review_text: body,
          content: body,
          star_rating: rating,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        };
        let { error } = await supabase.from("reviews").insert(payload);
        if (error && String(error.message || "").toLowerCase().includes("book_id")) {
          const retry = await supabase
            .from("reviews")
            .insert({ ...payload, book_id: "web-review" });
          error = retry.error;
        }
        if (error) throw error;
        showBanner("success", t("route.social.published", "Review published."));
      }
      socialDraft = { title: "", body: "", rating: "5" };
      socialComposerExpanded = false;
      setComposerOpen(false);
      rerender();
    } catch (error) {
      showBanner("error", error?.message || t("appShell.missingData", "Something went wrong."));
    }
  });

  const editButtons = document.querySelectorAll("[data-social-edit]");
  for (let i = 0; i < editButtons.length; i += 1) {
    editButtons[i].addEventListener("click", () => {
      const id = editButtons[i].getAttribute("data-social-edit") || "";
      const title = editButtons[i].getAttribute("data-social-title") || "";
      const body = editButtons[i].getAttribute("data-social-body") || "";
      const rating = editButtons[i].getAttribute("data-social-rating") || "5";
      if (titleInput) titleInput.value = title;
      if (bodyInput) bodyInput.value = body;
      if (ratingInput) ratingInput.value = rating;
      if (editIdInput) editIdInput.value = id;
      socialDraft = { title, body, rating };
      setComposerOpen(true);
      compPanel?.scrollIntoView({ behavior: "smooth", block: "start" });
      showBanner("success", t("route.social.editing", "Editing review. Save to apply changes."));
    });
  }

  const deleteButtons = document.querySelectorAll("[data-social-delete]");
  for (let i = 0; i < deleteButtons.length; i += 1) {
    deleteButtons[i].addEventListener("click", async () => {
      const id = deleteButtons[i].getAttribute("data-social-delete");
      if (!id) return;
      try {
        const { error } = await supabase
          .from("reviews")
          .delete()
          .eq("id", id)
          .eq("user_id", session.user.id);
        if (error) throw error;
        showBanner("success", t("route.social.deleted", "Review deleted."));
        rerender();
      } catch (error) {
        showBanner("error", error?.message || t("appShell.missingData", "Something went wrong."));
      }
    });
  }

  const toggleButtons = document.querySelectorAll("[data-review-toggle]");
  for (let i = 0; i < toggleButtons.length; i += 1) {
    toggleButtons[i].addEventListener("click", () => {
      const card = toggleButtons[i].closest(".pw-review-card");
      if (!card) return;
      const full = card.querySelector("[data-review-full]");
      const short = card.querySelector("[data-review-short]");
      if (!full || !short) return;
      const expanded = !full.hidden;
      full.hidden = expanded;
      short.hidden = !expanded;
      toggleButtons[i].textContent = expanded ? "Read more" : "Show less";
    });
  }
}

function bindReaderActions(supabase, session, rerender) {
  const timerEl = document.getElementById("pw-reader-timer-value");
  const startPauseBtn = document.getElementById("pw-reader-start-pause");
  const finishBtn = document.getElementById("pw-reader-finish");
  const pagesInput = document.getElementById("pw-reader-pages");
  const historyForm = document.getElementById("pw-reader-history-form");

  const updateTimerUi = () => {
    if (timerEl) timerEl.textContent = formatDuration(readerTimer.elapsedSeconds);
    if (startPauseBtn) {
      startPauseBtn.textContent = readerTimer.running
        ? t("route.reader.pause", "Pause")
        : t("route.reader.start", "Start reading");
    }
    if (finishBtn) finishBtn.disabled = readerTimer.elapsedSeconds <= 0;
  };

  const ensureTicker = () => {
    if (readerTicker) clearInterval(readerTicker);
    readerTicker = setInterval(() => {
      if (!readerTimer.running) return;
      readerTimer.elapsedSeconds += 1;
      updateTimerUi();
    }, 1000);
  };

  startPauseBtn?.addEventListener("click", () => {
    if (!readerTimer.running) {
      readerTimer.running = true;
      if (!readerTimer.startedAtMs) {
        readerTimer.startedAtMs = Date.now() - readerTimer.elapsedSeconds * 1000;
      }
      ensureTicker();
    } else {
      readerTimer.running = false;
    }
    updateTimerUi();
  });

  finishBtn?.addEventListener("click", async () => {
    if (readerTimer.elapsedSeconds <= 0) return;
    try {
      const endedAt = new Date();
      const startedAt = new Date(readerTimer.startedAtMs || Date.now() - readerTimer.elapsedSeconds * 1000);
      const pagesRead = Math.max(0, Number(pagesInput?.value || 0));
      const payload = {
        user_id: session.user.id,
        started_at: startedAt.toISOString(),
        ended_at: endedAt.toISOString(),
        duration_seconds: Math.round(readerTimer.elapsedSeconds),
        pages_read: pagesRead,
      };
      const { error } = await supabase.from("reading_sessions").insert(payload);
      if (error) throw error;
      readerTimer = { running: false, startedAtMs: null, elapsedSeconds: 0 };
      if (pagesInput) pagesInput.value = "0";
      updateTimerUi();
      showBanner("success", t("route.reader.savedSession", "Reading session saved."));
      rerender();
    } catch (error) {
      showBanner("error", error?.message || t("appShell.missingData", "Something went wrong."));
    }
  });

  historyForm?.addEventListener("submit", async (event) => {
    event.preventDefault();
    const titleEl = document.getElementById("pw-reader-book-title");
    const authorEl = document.getElementById("pw-reader-book-author");
    const sourceEl = document.getElementById("pw-reader-source");
    const finishedEl = document.getElementById("pw-reader-finished");
    const bookTitle = String(titleEl?.value || "").trim();
    if (!bookTitle) {
      showBanner("error", t("route.reader.historyValidation", "Book title is required."));
      return;
    }
    try {
      const { error } = await supabase.from("reading_history").insert({
        user_id: session.user.id,
        book_id: `web-${Date.now()}`,
        book_title: bookTitle,
        book_author: String(authorEl?.value || "").trim(),
        source: String(sourceEl?.value || "web").trim() || "web",
        scroll_position: 100,
        is_finished: !!finishedEl?.checked,
        last_read_at: new Date().toISOString(),
      });
      if (error) throw error;
      historyForm.reset();
      const sourceReset = document.getElementById("pw-reader-source");
      if (sourceReset) sourceReset.value = "web";
      showBanner("success", t("route.reader.savedHistory", "Reading history saved."));
      rerender();
    } catch (error) {
      showBanner("error", error?.message || t("appShell.missingData", "Something went wrong."));
    }
  });

  updateTimerUi();
  if (readerTimer.running) ensureTicker();
}

function bindClubsActions(supabase, session, rerender) {
  const createForm = document.getElementById("pw-club-create-form");
  const joinForm = document.getElementById("pw-club-join-form");

  createForm?.addEventListener("submit", async (event) => {
    event.preventDefault();
    const nameEl = document.getElementById("pw-club-name");
    const descEl = document.getElementById("pw-club-description");
    const emojiEl = document.getElementById("pw-club-emoji");
    const maxMembersEl = document.getElementById("pw-club-max-members");
    const name = String(nameEl?.value || "").trim();
    const description = String(descEl?.value || "").trim();
    const emoji = String(emojiEl?.value || "📚").trim() || "📚";
    const maxMembers = Number(maxMembersEl?.value || 20);
    clubsDraft = { ...clubsDraft, name, description, emoji, maxMembers: String(maxMembers) };
    if (!name) {
      showBanner("error", t("route.clubs.validationName", "Club name is required."));
      return;
    }
    const dirEl = document.getElementById("pw-club-directory");
    const listInDirectory = dirEl ? Boolean(dirEl.checked) : true;
    try {
      const { data: freshAuth, error: sessionErr } = await supabase.auth.getSession();
      if (sessionErr) throw sessionErr;
      const uid = freshAuth?.session?.user?.id;
      if (!uid) {
        showBanner("error", t("route.clubs.signInToCreate", "Sign in to create a club."));
        return;
      }
      const { data: created, error } = await supabase
        .from("book_clubs")
        .insert({
          name,
          description: description || null,
          cover_emoji: emoji,
          created_by: uid,
          max_members: maxMembers,
          is_private: !listInDirectory,
        })
        .select("id, invite_code")
        .single();
      if (error) throw error;
      const { error: memberErr } = await supabase
        .from("book_club_members")
        .insert({
          club_id: created.id,
          user_id: uid,
          role: "admin",
        });
      if (memberErr) throw memberErr;
      clubsDraft = { ...clubsDraft, name: "", description: "" };
      showBanner("success", `${t("route.clubs.created", "Club created.")} ${t("route.clubs.code", "Code")}: ${created.invite_code || "-"}`);
      rerender();
    } catch (error) {
      showBanner("error", error?.message || t("appShell.missingData", "Something went wrong."));
    }
  });

  const doJoinWithCode = async (rawCode) => {
    const code = String(rawCode || "").trim();
    clubsDraft = { ...clubsDraft, inviteCode: code };
    if (!code) {
      showBanner("error", t("route.clubs.validationCode", "Invite code is required."));
      return;
    }
    try {
      const { data: club, error } = await supabase
        .from("book_clubs")
        .select("id")
        .ilike("invite_code", code)
        .maybeSingle();
      if (error) throw error;
      if (!club?.id) {
        showBanner("error", t("route.clubs.invalidCode", "Invite code not found."));
        return;
      }
      const { data: jAuth, error: jSessErr } = await supabase.auth.getSession();
      if (jSessErr) throw jSessErr;
      const joinUid = jAuth?.session?.user?.id;
      if (!joinUid) {
        showBanner("error", t("route.clubs.signInToCreate", "Sign in to create a club."));
        return;
      }
      const { error: joinErr } = await supabase
        .from("book_club_members")
        .upsert({ club_id: club.id, user_id: joinUid, role: "member" }, { onConflict: "club_id,user_id" });
      if (joinErr) throw joinErr;
      clubsDraft = { ...clubsDraft, inviteCode: "" };
      showBanner("success", t("route.clubs.joined", "Joined club successfully."));
      rerender();
    } catch (error) {
      showBanner("error", error?.message || t("appShell.missingData", "Something went wrong."));
    }
  };

  joinForm?.addEventListener("submit", async (event) => {
    event.preventDefault();
    const codeEl = document.getElementById("pw-club-invite-code");
    await doJoinWithCode(codeEl?.value || "");
  });

  const requestButtons = document.querySelectorAll("[data-club-request]");
  for (let i = 0; i < requestButtons.length; i += 1) {
    requestButtons[i].addEventListener("click", async () => {
      const clubId = requestButtons[i].getAttribute("data-club-request") || "";
      if (!clubId) return;
      try {
        const { error } = await supabase.from("book_club_join_requests").insert({
          club_id: clubId,
          user_id: session.user.id,
          status: "pending",
        });
        if (error) throw error;
        showBanner("success", t("route.clubs.requestSent", "Request sent. The organiser can approve you."));
        rerender();
      } catch (error) {
        showBanner("error", error?.message || t("appShell.missingData", "Something went wrong."));
      }
    });
  }

  const rejoinButtons = document.querySelectorAll("[data-club-rejoin]");
  for (let i = 0; i < rejoinButtons.length; i += 1) {
    rejoinButtons[i].addEventListener("click", async () => {
      const clubId = rejoinButtons[i].getAttribute("data-club-rejoin") || "";
      if (!clubId) return;
      try {
        const { error } = await supabase
          .from("book_club_join_requests")
          .update({ status: "pending", resolved_at: null })
          .eq("club_id", clubId)
          .eq("user_id", session.user.id)
          .eq("status", "rejected");
        if (error) throw error;
        showBanner("success", t("route.clubs.requestSent", "Request sent. The organiser can approve you."));
        rerender();
      } catch (error) {
        showBanner("error", error?.message || t("appShell.missingData", "Something went wrong."));
      }
    });
  }

  const approveButtons = document.querySelectorAll("[data-club-approve]");
  for (let i = 0; i < approveButtons.length; i += 1) {
    approveButtons[i].addEventListener("click", async () => {
      const requestId = approveButtons[i].getAttribute("data-club-approve") || "";
      const clubId = approveButtons[i].getAttribute("data-club-approve-club") || "";
      const userId = approveButtons[i].getAttribute("data-club-approve-user") || "";
      if (!requestId || !clubId || !userId) return;
      try {
        const { error: mErr } = await supabase
          .from("book_club_members")
          .insert({ club_id: clubId, user_id: userId, role: "member" });
        if (mErr) throw mErr;
        const { error: uErr } = await supabase
          .from("book_club_join_requests")
          .update({ status: "approved", resolved_at: new Date().toISOString() })
          .eq("id", requestId);
        if (uErr) throw uErr;
        showBanner("success", t("route.clubs.approved", "Member added."));
        rerender();
      } catch (error) {
        showBanner("error", error?.message || t("appShell.missingData", "Something went wrong."));
      }
    });
  }

  const rejectButtons = document.querySelectorAll("[data-club-reject]");
  for (let i = 0; i < rejectButtons.length; i += 1) {
    rejectButtons[i].addEventListener("click", async () => {
      const requestId = rejectButtons[i].getAttribute("data-club-reject") || "";
      if (!requestId) return;
      try {
        const { error } = await supabase
          .from("book_club_join_requests")
          .update({ status: "rejected", resolved_at: new Date().toISOString() })
          .eq("id", requestId);
        if (error) throw error;
        showBanner("success", t("route.clubs.rejected", "Request declined."));
        rerender();
      } catch (error) {
        showBanner("error", error?.message || t("appShell.missingData", "Something went wrong."));
      }
    });
  }
}

async function renderCurrentRoute(supabase, session, route) {
  if (route === "/") return renderHome(supabase, session);
  if (route === "/book") return renderBookRoute(supabase, session);
  if (route === EXPLORE_PATH) return renderDiscover(session);
  if (route === "/library") return renderLibrary(supabase, session);
  if (route === "/social") return renderSocial(supabase, session);
  if (route === "/clubs") return renderClubs(supabase, session);
  if (route === "/club") return renderClubDetail(supabase, session);
  if (route === "/reader") return renderReader(supabase, session);
  if (route === "/profile") return renderProfile(supabase, session);
  return "";
}

let _routeRenderGen = 0;

async function renderRoute(supabase, session, expectedPath, opts = {}) {
  if (window.location.pathname === LEGACY_DISCOVER_PATH) {
    ensureAppPath();
  }
  let route =
    expectedPath && APP_ROUTES.has(expectedPath)
      ? expectedPath
      : APP_ROUTES.has(window.location.pathname)
        ? window.location.pathname
        : "/";
  if (route === LEGACY_DISCOVER_PATH) route = EXPLORE_PATH;
  const renderGen = ++_routeRenderGen;
  const pathForNav = window.location.pathname === "/club" ? "/clubs" : route;
  setActiveRoute(pathForNav);
  const root = document.getElementById("pw-route-content");
  if (!root) return;

  if (route === EXPLORE_PATH && opts.soft && document.getElementById("pw-discover-root")) {
    hideBanners();
    applyImmersiveBodyClasses(route, session);
    syncDiscoverSceneView();
    syncImmersiveBackdrop(route, session);
    applyDiscoverPanelFromHash();
    setActiveRoute(EXPLORE_PATH);
    await hydrateDiscoverPanels(session);
    const rerenderSoft = () => renderRoute(supabase, session);
    bindDiscoverActions(supabase, session, rerenderSoft);
    bindBookModalActions();
    return;
  }

  hideBanners();
  if (route !== "/book") {
    bookPageReviewPanelOpen = false;
  }
  if (!session?.user && PROTECTED_ROUTES.has(route)) {
    applyImmersiveBodyClasses(route, session);
    syncDiscoverSceneView();
    syncImmersiveBackdrop(route, session);
    document.body.classList.remove("pw-home-hero-scrolled");
    root.innerHTML = renderProtectedRouteGate(route);
    bindLockedGateActions();
    return;
  }

  applyImmersiveBodyClasses(route, session);
  syncDiscoverSceneView();
  syncImmersiveBackdrop(route, session);
  if (route !== "/" || session?.user) {
    document.body.classList.remove("pw-home-hero-scrolled");
  }

  root.classList.remove("pw-route-enter");
  const softExplore = Boolean(opts.soft) && route === EXPLORE_PATH;
  if (!softExplore) {
    root.innerHTML = renderRouteSkeleton(route);
  }
  const html = await renderCurrentRoute(supabase, session, route);
  if (renderGen !== _routeRenderGen) return;
  root.innerHTML = html;
  if (route === EXPLORE_PATH) {
    await hydrateDiscoverPanels(session);
  }
  if (renderGen !== _routeRenderGen) return;
  requestAnimationFrame(() => {
    root.classList.add("pw-route-enter");
    if (route === "/club") {
      const sc = document.getElementById("pw-club-chat-scroll");
      if (sc) sc.scrollTop = sc.scrollHeight;
    }
    if (route === EXPLORE_PATH) {
      requestAnimationFrame(() => {
        applyDiscoverPanelFromHash();
      });
    }
  });
  const rerender = () => renderRoute(supabase, session);
  if (route === EXPLORE_PATH) bindDiscoverActions(supabase, session, rerender);
  if (route === "/library") bindLibraryActions(supabase, session, rerender);
  if (route === "/social") bindSocialActions(supabase, session, rerender);
  if (route === "/reader") bindReaderActions(supabase, session, rerender);
  if (route === "/clubs") bindClubsActions(supabase, session, rerender);
  if (route === "/club") bindClubDetailActions(supabase, session, rerender);
  if (route === "/profile" && session?.user) {
    bindClubsActions(supabase, session, rerender);
    bindProfileTabActions();
    bindProfileSettingsForm(supabase, session, rerender);
  }
  if (route === "/profile") {
    const signInBtn = document.getElementById("pw-profile-signin");
    const signUpBtn = document.getElementById("pw-profile-signup");
    const signOutBtn = document.getElementById("pw-profile-signout");
    signInBtn?.addEventListener("click", () => {
      window.location.href = "/sign-in";
    });
    signUpBtn?.addEventListener("click", () => {
      window.location.href = "/sign-up";
    });
    signOutBtn?.addEventListener("click", async () => {
      const { error } = await supabase.auth.signOut();
      if (error) {
        showBanner("error", error.message);
        return;
      }
      showBanner("success", t("appShell.signedOut", "You are signed out."));
    });
    if (session?.user) {
      bindProfilePhotoActions(supabase, async () => {
        if (typeof window.pwUserMenuRefresh === "function") {
          await window.pwUserMenuRefresh();
        }
        if (typeof window.pwRerender === "function") {
          await window.pwRerender();
        }
      });
    }
  }
  if (route === "/book") {
    bindBookPageActions(supabase, session, rerender);
  }
  bindBookModalActions();
  if (route === "/") initHomeHeroParallax();
  markRouteRevealBlocks(root);
  if (root.querySelector("[data-reveal], [data-reveal-stagger]")) initScrollReveal(root);
}

/** Briefly fades/scales the current route content forward before it's
 *  swapped, so navigating reads as "diving into" the next page rather
 *  than an instant cut. Skipped entirely under reduced-motion. */
function diveToRoute(run) {
  const root = document.getElementById("pw-route-content");
  const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  if (!root || reduced) {
    run();
    return;
  }
  const mobile = window.matchMedia("(max-width: 860px)").matches;
  root.classList.remove("pw-route-enter");
  root.classList.add(mobile ? "pw-route-exit-lite" : "pw-route-exit");
  const ms = mobile ? 110 : 150;
  window.setTimeout(() => {
    root.classList.remove("pw-route-exit", "pw-route-exit-lite");
    run();
  }, ms);
}

function initLinks(render) {
  document.addEventListener("click", (event) => {
    const target = event.target;
    if (!(target instanceof Element)) return;
    const link = target.closest("[data-link-route]");
    if (!link) return;
    event.preventDefault();
    const href = link.getAttribute("href") || link.getAttribute("data-link-route") || "/";
    let nextPathWithHash = href;
    let pathOnly = "/";
    try {
      const u = new URL(href, window.location.origin);
      nextPathWithHash = u.pathname + u.search + u.hash;
      pathOnly = u.pathname || "/";
    } catch (_) {}
    if (!APP_ROUTES.has(pathOnly)) return;
    const currentFull = `${window.location.pathname}${window.location.search}${window.location.hash}`;
    const isSameRoute = currentFull === nextPathWithHash;
    if (isSameRoute) return;
    if (pathOnly === EXPLORE_PATH || pathOnly === LEGACY_DISCOVER_PATH) {
      const u = new URL(nextPathWithHash, window.location.origin);
      const target = EXPLORE_PATH + u.search + u.hash.replace(/^#hub$/, "");
      const onlyTabChange =
        isExploreRoute() &&
        window.location.pathname.replace(LEGACY_DISCOVER_PATH, EXPLORE_PATH) === EXPLORE_PATH &&
        u.pathname.replace(LEGACY_DISCOVER_PATH, EXPLORE_PATH) === EXPLORE_PATH;
      if (onlyTabChange) {
        window.history.pushState({}, "", target);
        applyDiscoverPanelFromHash();
        setActiveRoute(EXPLORE_PATH);
        render(EXPLORE_PATH, { soft: true });
        return;
      }
      diveToRoute(() => {
        window.history.pushState({}, "", target);
        render(EXPLORE_PATH);
      });
      return;
    }
    diveToRoute(() => {
      window.history.pushState({}, "", nextPathWithHash);
      render(pathOnly);
    });
  });
  window.addEventListener("popstate", () => {
    if (isExploreRoute()) render(EXPLORE_PATH, { soft: true });
    else render();
  });
}

function initBottomNav(_render) {
  /* Search merged into Explore — no separate bottom-nav control. */
}

async function boot() {
  ensureAppPath();
  let supabase;
  try {
    supabase = await getSupabase();
  } catch (error) {
    showBanner("error", t("app.configError"));
    return;
  }

  let session;
  try {
    const { data, error } = await withTimeout(supabase.auth.getSession(), 15000);
    if (error) {
      showBanner("error", error.message);
    }
    session = data?.session ?? null;
  } catch (_) {
    showBanner(
      "error",
      t(
        "app.sessionTimeout",
        "Session is taking too long. Check your connection and try refreshing the page.",
      ),
    );
    session = null;
  }

  const userMenu = initUserMenu(supabase);
  window.pwSyncNav = function pwSyncNav() {
    const route = APP_ROUTES.has(window.location.pathname) ? window.location.pathname : "/";
    const pathForNav = window.location.pathname === "/club" ? "/clubs" : route;
    setActiveRoute(pathForNav);
  };

  const render = async (expectedPath, opts = {}) => {
    userMenu.close();
    closeAuthNudge();
    await renderRoute(supabase, session, expectedPath, opts);
  };
  window.pwRerender = render;
  window.pwUserMenuRefresh = () => userMenu.refresh(session);

  initLinks(render);
  initBottomNav(render);
  await userMenu.refresh(session);
  prefetchBookApi("/api/books?type=trending&maxResults=12");
  await render();

  supabase.auth.onAuthStateChange(async (_evt, newSession) => {
    session = newSession;
    await userMenu.refresh(session);
    await render();
  });
}

boot();
