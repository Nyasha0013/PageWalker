let heroParallaxCleanup = null;

function syncSiteHeaderHeight() {
  const header = document.querySelector(".site-header");
  if (!header) return;
  document.documentElement.style.setProperty("--site-header-h", `${header.offsetHeight}px`);
}

function updateImmersiveHeaderState(hero) {
  if (!document.body.classList.contains("pw-home-immersive")) return;
  const headerH =
    parseFloat(getComputedStyle(document.documentElement).getPropertyValue("--site-header-h")) || 72;
  const rect = hero.getBoundingClientRect();
  document.body.classList.toggle("pw-home-hero-scrolled", rect.bottom <= headerH + 8);
}

export function initHomeHeroParallax() {
  if (heroParallaxCleanup) {
    heroParallaxCleanup();
    heroParallaxCleanup = null;
  }

  const hero = document.querySelector("[data-pw-hero]");
  if (!hero) return;

  syncSiteHeaderHeight();

  const scene = hero.querySelector(".pw-hero-scene");
  const foreground = hero.querySelector("[data-pw-hero-foreground]");
  if (!scene || !foreground) return;

  const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const mobile = window.matchMedia("(max-width: 860px)").matches;
  const finePointer = window.matchMedia("(pointer: fine)").matches;

  let ticking = false;
  const capRatio = 0.12;

  // cursor offsets, tracked separately from scroll and blended in each frame
  let mouseX = 0;
  let mouseY = 0;

  function update() {
    ticking = false;
    updateImmersiveHeaderState(hero);

    if (reduced || mobile) {
      scene.style.transform = "";
      foreground.style.transform = "";
      return;
    }

    // When the scene is a fixed full-page backdrop, it must stay pinned —
    // scroll-shifting a fixed layer would reveal a gap at the edges. So we
    // only ever apply the subtle cursor drift to it, never the scroll shift.
    const immersive = document.body.classList.contains("pw-home-immersive");

    const rect = hero.getBoundingClientRect();
    const heroH = hero.offsetHeight || 1;
    const scrolled = Math.min(heroH, Math.max(0, -rect.top));
    const cap = heroH * capRatio;
    const bgShift = immersive ? 0 : Math.min(cap, scrolled * capRatio);
    const fgShift = Math.min(cap * 0.45, scrolled * 0.045);

    // small extra offset from cursor position, on top of the scroll drift —
    // background and foreground move opposite directions for depth
    const cursorBgX = mouseX * 10;
    const cursorBgY = mouseY * 8;
    const cursorFgX = mouseX * -4;
    const cursorFgY = mouseY * -3;

    scene.style.transform = `translate3d(${cursorBgX}px, ${bgShift + cursorBgY}px, 0)`;
    foreground.style.transform = `translate3d(${cursorFgX}px, ${fgShift + cursorFgY}px, 0)`;
  }

  function onScroll() {
    if (!ticking) {
      ticking = true;
      requestAnimationFrame(update);
    }
  }

  function onResize() {
    syncSiteHeaderHeight();
    onScroll();
  }

  function onMouseMove(e) {
    const rect = hero.getBoundingClientRect();
    if (rect.bottom <= 0 || rect.top >= window.innerHeight) return; // hero off-screen, ignore
    mouseX = (e.clientX / window.innerWidth - 0.5) * 2;
    mouseY = (e.clientY / window.innerHeight - 0.5) * 2;
    onScroll();
  }

  window.addEventListener("scroll", onScroll, { passive: true });
  window.addEventListener("resize", onResize, { passive: true });
  if (finePointer && !reduced && !mobile) {
    window.addEventListener("mousemove", onMouseMove, { passive: true });
  }
  update();

  heroParallaxCleanup = () => {
    window.removeEventListener("scroll", onScroll);
    window.removeEventListener("resize", onResize);
    window.removeEventListener("mousemove", onMouseMove);
    scene.style.transform = "";
    foreground.style.transform = "";
    document.body.classList.remove("pw-home-hero-scrolled");
  };
}
