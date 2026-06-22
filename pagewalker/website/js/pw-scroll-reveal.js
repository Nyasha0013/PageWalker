/**
 * Scroll-reveal for [data-reveal] and staggered [data-reveal-stagger] grids.
 * Safe on every route — disconnects prior observers before re-binding.
 */
let revealObserver = null;

function primeVisibleReveals(els) {
  const vh = window.innerHeight || document.documentElement.clientHeight;
  for (let i = 0; i < els.length; i += 1) {
    const el = els[i];
    const rect = el.getBoundingClientRect();
    if (rect.top < vh * 0.92 && rect.bottom > 0) {
      el.classList.add("is-revealed");
    }
  }
}

export function initScrollReveal(root = document) {
  if (revealObserver) {
    revealObserver.disconnect();
    revealObserver = null;
  }

  if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

  const els = root.querySelectorAll("[data-reveal], [data-reveal-stagger]");
  if (!els.length) return;

  primeVisibleReveals(els);

  revealObserver = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        entry.target.classList.toggle("is-revealed", entry.intersectionRatio > 0.12);
      });
    },
    { threshold: [0, 0.12, 0.35, 1], rootMargin: "0px 0px -4% 0px" },
  );

  els.forEach((el) => revealObserver.observe(el));
}
