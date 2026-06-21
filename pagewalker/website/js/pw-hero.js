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

  let ticking = false;
  const capRatio = 0.12;

  function update() {
    ticking = false;
    updateImmersiveHeaderState(hero);

    if (reduced || mobile) {
      scene.style.transform = "";
      foreground.style.transform = "";
      return;
    }

    const rect = hero.getBoundingClientRect();
    const heroH = hero.offsetHeight || 1;
    const scrolled = Math.min(heroH, Math.max(0, -rect.top));
    const cap = heroH * capRatio;
    const bgShift = Math.min(cap, scrolled * capRatio);
    const fgShift = Math.min(cap * 0.45, scrolled * 0.045);
    scene.style.transform = `translate3d(0, ${bgShift}px, 0)`;
    foreground.style.transform = `translate3d(0, ${fgShift}px, 0)`;
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

  window.addEventListener("scroll", onScroll, { passive: true });
  window.addEventListener("resize", onResize, { passive: true });
  update();

  heroParallaxCleanup = () => {
    window.removeEventListener("scroll", onScroll);
    window.removeEventListener("resize", onResize);
    scene.style.transform = "";
    foreground.style.transform = "";
    document.body.classList.remove("pw-home-hero-scrolled");
  };
}
