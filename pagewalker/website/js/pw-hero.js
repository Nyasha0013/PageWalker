let heroParallaxCleanup = null;

export function initHomeHeroParallax() {
  if (heroParallaxCleanup) {
    heroParallaxCleanup();
    heroParallaxCleanup = null;
  }

  const hero = document.querySelector("[data-pw-hero]");
  if (!hero) return;

  const scene = hero.querySelector(".pw-hero-scene");
  const foreground = hero.querySelector("[data-pw-hero-foreground]");
  if (!scene || !foreground) return;

  const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const mobile = window.matchMedia("(max-width: 860px)").matches;
  if (reduced || mobile) {
    scene.style.transform = "";
    foreground.style.transform = "";
    return;
  }

  let ticking = false;
  const capRatio = 0.12;

  function update() {
    ticking = false;
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

  window.addEventListener("scroll", onScroll, { passive: true });
  window.addEventListener("resize", onScroll, { passive: true });
  update();

  heroParallaxCleanup = () => {
    window.removeEventListener("scroll", onScroll);
    window.removeEventListener("resize", onScroll);
    scene.style.transform = "";
    foreground.style.transform = "";
  };
}
