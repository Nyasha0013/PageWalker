import { getSupabase } from "./pw-supabase.js";

const APP_ROUTES = new Set([
  "/",
  "/discover",
  "/library",
  "/social",
  "/clubs",
  "/reader",
  "/profile",
]);
const PROTECTED_ROUTES = new Set([
  "/discover",
  "/library",
  "/social",
  "/clubs",
  "/reader",
  "/profile",
]);

function t(key, fallback) {
  if (window.pwT) return window.pwT(key);
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
  const current = window.location.pathname;
  if (APP_ROUTES.has(current)) return;
  window.history.replaceState({}, "", "/");
}

function setActiveRoute(route) {
  const links = document.querySelectorAll("[data-link-route]");
  for (let i = 0; i < links.length; i += 1) {
    const href = links[i].getAttribute("data-link-route");
    links[i].toggleAttribute("data-active", href === route);
  }
}

function escapeHtml(value) {
  return String(value || "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function listToHtml(items) {
  if (!items?.length) {
    return `<p class="muted">${t("appShell.empty", "No items yet.")}</p>`;
  }
  return `<ul class="app-list">${items
    .map((it) => `<li>${it}</li>`)
    .join("")}</ul>`;
}

async function runSafeQuery(work, emptyText) {
  try {
    const rows = await work();
    return rows;
  } catch (_) {
    return [{ __error: true, text: emptyText || t("appShell.missingData") }];
  }
}

async function renderHome(_supabase, _session) {
  return `
    <section class="hero">
      <div class="hero-inner">
        <h1>
          <span>${t("home.heroLine1", "Walk your shelves.")}</span><br />
          <span class="accent">${t("home.heroLine2", "Share the story.")}</span>
        </h1>
        <p class="lede">${t("home.heroLede", "Your cozy corner for TBR piles, reading streaks, spicy reviews, and book-club chaos — all the bookish energy, none of the pirated pages.")}</p>
        <div class="hero-actions">
          <a class="badge-play" href="https://play.google.com/store/apps/details?id=com.pagewalker.app" rel="noopener noreferrer" aria-label="${t("home.playAlt", "Get it on Google Play")}">
            <img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" alt="${t("home.playAlt", "Get it on Google Play")}" width="646" height="250" />
          </a>
        </div>
        <p class="hero-tagline">${t("home.heroTagline", "Free on Google Play · same login here & in the app")}</p>
      </div>
    </section>
    <section class="app-grid app-grid-3">
      <article class="app-panel">
        <h3>${t("home.feature1Title", "Discover & stack")}</h3>
        <p>${t("home.feature1Desc", "Hunt your next obsession, curate your TBR, and flex your finished pile like the main character you are.")}</p>
      </article>
      <article class="app-panel">
        <h3>${t("home.feature2Title", "Track the vibe")}</h3>
        <p>${t("home.feature2Desc", "Sessions, streaks, and yearly wraps so your reading era gets the spotlight.")}</p>
      </article>
      <article class="app-panel">
        <h3>${t("home.feature3Title", "Gossip & clubs")}</h3>
        <p>${t("home.feature3Desc", "Hot takes, profiles, and book-club rooms for when you need to process that ending together.")}</p>
      </article>
    </section>
    <section class="cta-band">
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
    <section class="app-panel">
      <h3>${t("route.home.profilePromptTitle", "Account actions are in Profile")}</h3>
      <p>${t("route.home.profilePromptBody", "Use the Profile tab for Guest mode, Sign in, Sign up, and Sign out.")}</p>
      <p><a href="/profile" data-link-route="/profile">${t("appNav.profile", "Profile")}</a></p>
    </section>
  `;
}

async function renderDiscover(supabase, session) {
  const catalog = await runSafeQuery(async () => {
    const { data, error } = await supabase
      .from("catalog_books")
      .select("title, authors, cover_url")
      .limit(8);
    if (error) throw error;
    return data || [];
  }, t("appShell.missingCatalog", "Could not load catalog_books."));

  const rows = catalog
    .slice(0, 8)
    .map((b) => {
      if (b.__error) return `<li>${escapeHtml(b.text)}</li>`;
      const author = Array.isArray(b.authors) ? b.authors.join(", ") : (b.authors || "");
      return `<li><strong>${escapeHtml(b.title || "Untitled")}</strong><span>${escapeHtml(author)}</span></li>`;
    });

  return `
    <section class="app-panel">
      <h2>${t("route.discover.title", "Discover & search")}</h2>
      <p>${t("route.discover.body", "Browse catalog books and use app search from web.")}</p>
      ${listToHtml(rows)}
      ${
        session?.user
          ? `<p class="muted">${t("route.discover.noteAuthed", "You are signed in. Use discover + library together.")}</p>`
          : `<p class="muted">${t("route.discover.noteGuest", "Sign in to save discoveries to your library.")}</p>`
      }
    </section>
  `;
}

async function renderLibrary(supabase, session) {
  if (!session?.user) {
    return `<section class="app-panel"><h2>${t("route.library.title", "Library")}</h2><p>${t("route.authRequired", "Please sign in to view this section.")}</p></section>`;
  }
  const rows = await runSafeQuery(async () => {
    const { data, error } = await supabase
      .from("user_books")
      .select("status, title, author")
      .eq("user_id", session.user.id)
      .order("updated_at", { ascending: false })
      .limit(12);
    if (error) throw error;
    return data || [];
  }, t("appShell.missingUserBooks", "Could not load user_books."));

  const items = rows.map((r) => {
    if (r.__error) return `<span>${escapeHtml(r.text)}</span>`;
    return `<strong>${escapeHtml(r.title || "Untitled")}</strong><span>${escapeHtml(r.author || "")} · ${escapeHtml(r.status || "")}</span>`;
  });
  return `<section class="app-panel"><h2>${t("route.library.title", "Library")}</h2>${listToHtml(items)}</section>`;
}

async function renderSocial(supabase, session) {
  const reviews = await runSafeQuery(async () => {
    const { data, error } = await supabase
      .from("reviews")
      .select("title, review_text, rating")
      .order("created_at", { ascending: false })
      .limit(10);
    if (error) throw error;
    return data || [];
  }, t("appShell.missingReviews", "Could not load reviews."));

  const items = reviews.map((r) => {
    if (r.__error) return `<span>${escapeHtml(r.text)}</span>`;
    return `<strong>${escapeHtml(r.title || "Review")}</strong><span>${escapeHtml(r.review_text || "")}</span><span>${t("route.social.rating", "Rating")}: ${escapeHtml(r.rating ?? "-")}</span>`;
  });

  return `
    <section class="app-panel">
      <h2>${t("route.social.title", "Reviews & social")}</h2>
      ${listToHtml(items)}
      ${
        session?.user
          ? `<p class="muted">${t("route.social.authed", "Use the mobile app and web together with the same account.")}</p>`
          : `<p class="muted">${t("route.social.guest", "Sign in to write and manage your own reviews.")}</p>`
      }
    </section>
  `;
}

async function renderClubs(supabase, session) {
  const clubs = await runSafeQuery(async () => {
    const { data, error } = await supabase
      .from("book_clubs")
      .select("id, name, description")
      .order("created_at", { ascending: false })
      .limit(8);
    if (error) throw error;
    return data || [];
  }, t("appShell.missingClubs", "Could not load book_clubs."));

  const items = clubs.map((c) => {
    if (c.__error) return `<span>${escapeHtml(c.text)}</span>`;
    return `<strong>${escapeHtml(c.name || "Club")}</strong><span>${escapeHtml(c.description || "")}</span>`;
  });

  return `<section class="app-panel"><h2>${t("route.clubs.title", "Book clubs")}</h2>${listToHtml(items)}${
    session?.user ? "" : `<p class="muted">${t("route.clubs.guest", "Sign in to join clubs and vote in polls.")}</p>`
  }</section>`;
}

async function renderReader(supabase, session) {
  if (!session?.user) {
    return `<section class="app-panel"><h2>${t("route.reader.title", "Reader tools")}</h2><p>${t("route.authRequired", "Please sign in to view this section.")}</p></section>`;
  }
  const [sessions, history] = await Promise.all([
    runSafeQuery(async () => {
      const { data, error } = await supabase
        .from("reading_sessions")
        .select("minutes_read")
        .eq("user_id", session.user.id)
        .order("created_at", { ascending: false })
        .limit(20);
      if (error) throw error;
      return data || [];
    }, t("appShell.missingSessions", "Could not load reading_sessions.")),
    runSafeQuery(async () => {
      const { data, error } = await supabase
        .from("reading_history")
        .select("book_title")
        .eq("user_id", session.user.id)
        .order("created_at", { ascending: false })
        .limit(8);
      if (error) throw error;
      return data || [];
    }, t("appShell.missingHistory", "Could not load reading_history.")),
  ]);

  const totalMinutes = sessions.reduce((sum, x) => sum + Number(x.minutes_read || 0), 0);
  const historyItems = history.map((h) => {
    if (h.__error) return `<span>${escapeHtml(h.text)}</span>`;
    return `<strong>${escapeHtml(h.book_title || "Book")}</strong>`;
  });

  return `
    <section class="app-panel">
      <h2>${t("route.reader.title", "Reader tools")}</h2>
      <p class="metric">${t("route.reader.minutes", "Total minutes (latest sessions)")}: ${totalMinutes}</p>
      ${listToHtml(historyItems)}
    </section>
  `;
}

async function renderProfile(supabase, session) {
  const signedIn = !!(session && session.user);
  const authPanel = `
    <section class="webapp-hero">
      <h1>${t("appShell.heroTitle", "Your full Pagewalker experience on web")}</h1>
      <p>${t("appShell.heroLede", "Sign in once and move across library, discover, social, clubs, and reader tools.")}</p>
      <div class="webapp-auth-row">
        <span class="badge-outline">${signedIn ? `${t("appShell.authSignedIn", "Signed in")}: ${escapeHtml(session.user.email || "")}` : t("appShell.authGuest", "Guest mode")}</span>
        <button id="pw-profile-signin" class="btn"${signedIn ? " hidden" : ""}>${t("appShell.signIn", "Sign in")}</button>
        <button id="pw-profile-signup" class="btn btn-outline"${signedIn ? " hidden" : ""}>${t("appShell.signUp", "Sign up")}</button>
        <button id="pw-profile-signout" class="btn btn-outline"${signedIn ? "" : " hidden"}>${t("appShell.signOut", "Sign out")}</button>
      </div>
    </section>
  `;

  if (!session?.user) {
    return `
      ${authPanel}
      <section class="app-panel"><h2>${t("route.profile.title", "Profile")}</h2><p>${t("route.authRequired", "Please sign in to view this section.")}</p></section>
    `;
  }

  const profiles = await runSafeQuery(async () => {
    const { data, error } = await supabase
      .from("profiles")
      .select("username, full_name, bio")
      .eq("id", session.user.id)
      .maybeSingle();
    if (error) throw error;
    return data ? [data] : [];
  }, t("appShell.missingProfile", "Could not load profile."));

  const profile = profiles[0] || {};
  return `
    ${authPanel}
    <section class="app-grid app-grid-3">
      <article class="app-panel">
        <h2>${t("route.profile.title", "Profile")}</h2>
        <div class="profile-grid">
          <div><span class="muted">${t("route.profile.email", "Email")}</span><p>${escapeHtml(session.user.email || "-")}</p></div>
          <div><span class="muted">${t("route.profile.username", "Username")}</span><p>${escapeHtml(profile.username || "-")}</p></div>
          <div><span class="muted">${t("route.profile.fullName", "Name")}</span><p>${escapeHtml(profile.full_name || "-")}</p></div>
        </div>
        <p>${escapeHtml(profile.bio || t("route.profile.bioEmpty", "No bio yet."))}</p>
      </article>
      <article class="app-panel">
        <h3>${t("route.profile.featuresTitle", "Your app sections")}</h3>
        <p>${t("route.profile.featuresBody", "Open deep product sections from Profile after signing in.")}</p>
        <div class="cta-actions">
          <a class="btn btn-outline" href="/discover" data-link-route="/discover">${t("appNav.discover", "Discover")}</a>
          <a class="btn btn-outline" href="/library" data-link-route="/library">${t("appNav.library", "Library")}</a>
          <a class="btn btn-outline" href="/social" data-link-route="/social">${t("appNav.social", "Social")}</a>
          <a class="btn btn-outline" href="/clubs" data-link-route="/clubs">${t("appNav.clubs", "Clubs")}</a>
          <a class="btn btn-outline" href="/reader" data-link-route="/reader">${t("appNav.reader", "Reader")}</a>
        </div>
      </article>
      <article class="app-panel">
        <h3>${t("route.profile.securityTitle", "Guest-safe web mode")}</h3>
        <p>${t("route.profile.securityBody", "Guests can browse public information and auth entry points; in-depth sections require sign-in.")}</p>
      </article>
    </section>
  `;
}

function renderProtectedRouteGate(route) {
  const routeNameMap = {
    "/discover": t("appNav.discover", "Discover"),
    "/library": t("appNav.library", "Library"),
    "/social": t("appNav.social", "Social"),
    "/clubs": t("appNav.clubs", "Clubs"),
    "/reader": t("appNav.reader", "Reader"),
    "/profile": t("appNav.profile", "Profile"),
  };
  return `
    <section class="app-panel">
      <h2>${t("route.locked.title", "Sign in required")}</h2>
      <p>${t("route.locked.body", "To view in-depth product content on web, please sign in first.")}</p>
      <p class="muted">${t("route.locked.target", "Requested section")}: ${escapeHtml(routeNameMap[route] || route)}</p>
      <div class="cta-actions">
        <button id="pw-locked-signin" class="btn">${t("appShell.signIn", "Sign in")}</button>
        <button id="pw-locked-signup" class="btn btn-outline">${t("appShell.signUp", "Sign up")}</button>
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
}

async function renderCurrentRoute(supabase, session, route) {
  if (route === "/") return renderHome(supabase, session);
  if (route === "/discover") return renderDiscover(supabase, session);
  if (route === "/library") return renderLibrary(supabase, session);
  if (route === "/social") return renderSocial(supabase, session);
  if (route === "/clubs") return renderClubs(supabase, session);
  if (route === "/reader") return renderReader(supabase, session);
  if (route === "/profile") return renderProfile(supabase, session);
  return "";
}

async function renderRoute(supabase, session) {
  const route = APP_ROUTES.has(window.location.pathname) ? window.location.pathname : "/";
  setActiveRoute(route);
  const root = document.getElementById("pw-route-content");
  if (!root) return;

  hideBanners();
  if (!session?.user && PROTECTED_ROUTES.has(route)) {
    root.innerHTML = renderProtectedRouteGate(route);
    bindLockedGateActions();
    return;
  }
  root.innerHTML = await renderCurrentRoute(supabase, session, route);
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
  }
}

function initLinks(render) {
  document.addEventListener("click", (event) => {
    const target = event.target;
    if (!(target instanceof Element)) return;
    const link = target.closest("[data-link-route]");
    if (!link) return;
    event.preventDefault();
    const route = link.getAttribute("data-link-route") || "/";
    if (!APP_ROUTES.has(route)) return;
    if (window.location.pathname !== route) {
      window.history.pushState({}, "", route);
    }
    render();
  });
  window.addEventListener("popstate", render);
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

  let session = (await supabase.auth.getSession()).data.session;

  const render = async () => {
    await renderRoute(supabase, session);
  };

  initLinks(render);
  await render();

  supabase.auth.onAuthStateChange(async (_evt, newSession) => {
    session = newSession;
    await render();
  });
}

boot();
