/**
 * Generic scroll-reveal: any element marked data-reveal fades/slides up
 * once it's ~20% into the viewport. Safe to call on every route — it's a
 * no-op if there's nothing to observe, and it disconnects its previous
 * observer first so re-renders don't pile up listeners.
 */
let revealObserver = null;

export function initScrollReveal(root = document) {
  if (revealObserver) {
    revealObserver.disconnect();
    revealObserver = null;
  }

  if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

  const els = root.querySelectorAll("[data-reveal]");
  if (!els.length) return;

  revealObserver = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        entry.target.classList.toggle("is-revealed", entry.intersectionRatio > 0.2);
      });
    },
    { threshold: [0, 0.2, 1] },
  );

  els.forEach((el) => revealObserver.observe(el));
}
