/**
 * Left navigation drawer: primary app sections with short descriptions.
 * Closes when the app calls close() after route changes, or via backdrop / Escape.
 */

export function initAppDrawer() {
  const openBtn = document.getElementById("pw-drawer-open");
  const closeBtn = document.getElementById("pw-drawer-close");
  const drawer = document.getElementById("pw-app-drawer");
  const backdrop = document.getElementById("pw-drawer-backdrop");
  if (!openBtn || !drawer || !backdrop) {
    return { close: () => {} };
  }

  function isOpen() {
    return drawer.classList.contains("is-open");
  }

  function open() {
    drawer.classList.add("is-open");
    drawer.removeAttribute("hidden");
    drawer.setAttribute("aria-hidden", "false");
    backdrop.classList.add("is-open");
    backdrop.removeAttribute("hidden");
    backdrop.setAttribute("aria-hidden", "false");
    openBtn.setAttribute("aria-expanded", "true");
    document.body.classList.add("pw-app-drawer-open");
    const toFocus = drawer.querySelector(".pw-drawer__item");
    if (toFocus instanceof HTMLElement) {
      setTimeout(() => toFocus.focus(), 0);
    }
  }

  function close() {
    drawer.classList.remove("is-open");
    drawer.setAttribute("aria-hidden", "true");
    drawer.setAttribute("hidden", "");
    backdrop.classList.remove("is-open");
    backdrop.setAttribute("aria-hidden", "true");
    backdrop.setAttribute("hidden", "");
    openBtn.setAttribute("aria-expanded", "false");
    document.body.classList.remove("pw-app-drawer-open");
    if (document.activeElement && drawer.contains(document.activeElement)) {
      openBtn.focus();
    }
  }

  openBtn.addEventListener("click", () => (isOpen() ? close() : open()));
  closeBtn?.addEventListener("click", () => close());
  backdrop.addEventListener("click", () => close());

  document.addEventListener(
    "keydown",
    (e) => {
      if (e.key === "Escape" && isOpen()) {
        e.preventDefault();
        close();
      }
    },
    true,
  );

  window.addEventListener("popstate", () => {
    if (isOpen()) close();
  });

  return { close, open, isOpen };
}
