// pw-full-experience.js — PageWalker space intro and horizontal page globe

(function () {
  "use strict";

  const THREE_CDN = "https://cdnjs.cloudflare.com/ajax/libs/three.js/r134/three.min.js";
  const WORD = "PAGEWALKER";

  let rafId = 0;
  let onResize = null;
  let landingTrack = null;
  let onTrackScroll = null;
  let onWheel = null;
  let pageObserver = null;

  function loadScript(src) {
    return new Promise((resolve, reject) => {
      if (window.THREE) {
        resolve();
        return;
      }
      const existing = document.querySelector(`script[src="${src}"]`);
      if (existing) {
        existing.addEventListener("load", () => resolve(), { once: true });
        existing.addEventListener("error", () => reject(new Error("script load failed")), { once: true });
        return;
      }
      const script = document.createElement("script");
      script.src = src;
      script.async = true;
      script.onload = () => resolve();
      script.onerror = () => reject(new Error("script load failed"));
      document.head.appendChild(script);
    });
  }

  function destroyFullExperience() {
    if (rafId) cancelAnimationFrame(rafId);
    rafId = 0;
    if (landingTrack && onTrackScroll) landingTrack.removeEventListener("scroll", onTrackScroll);
    if (landingTrack && onWheel) landingTrack.removeEventListener("wheel", onWheel);
    if (pageObserver) pageObserver.disconnect();
    landingTrack = null;
    onTrackScroll = null;
    onWheel = null;
    pageObserver = null;
    if (onResize) window.removeEventListener("resize", onResize);
    onResize = null;
    if (typeof window._pwFeDispose === "function") {
      window._pwFeDispose();
      window._pwFeDispose = null;
    }
    document.documentElement.removeAttribute("data-pw-fe-active");
    document.querySelectorAll(".pw-fe-letter-stage").forEach((el) => el.remove());
  }

  function clamp01(v) {
    return Math.max(0, Math.min(1, v));
  }

  function lerp(a, b, t) {
    return a + (b - a) * t;
  }

  function easeOut(t) {
    return 1 - Math.pow(1 - t, 3);
  }

  function easeInOut(t) {
    return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
  }

  function initLandingTrack(track) {
    const pages = track.querySelectorAll(".pw-landing-page");
    const dots = document.querySelectorAll(".pw-landing-dot");

    pageObserver = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          entry.target.classList.toggle("is-visible", entry.isIntersecting && entry.intersectionRatio > 0.35);
        });
      },
      { root: track, threshold: [0.35, 0.55] },
    );
    pages.forEach((page) => pageObserver.observe(page));
    if (pages[0]) pages[0].classList.add("is-visible");

    dots.forEach((dot) => {
      dot.addEventListener("click", () => {
        const index = Number(dot.getAttribute("data-page") || "0");
        track.scrollTo({ left: index * window.innerWidth, behavior: "smooth" });
      });
    });

    onWheel = (event) => {
      if (Math.abs(event.deltaY) <= Math.abs(event.deltaX)) return;
      event.preventDefault();
      track.scrollLeft += event.deltaY;
    };
    track.addEventListener("wheel", onWheel, { passive: false });
  }

  function bindTrackScroll(track, handlers) {
    onTrackScroll = () => {
      const pageW = Math.max(window.innerWidth, 1);
      const pageProgress = track.scrollLeft / pageW;
      handlers.onProgress(pageProgress);
      const active = Math.round(pageProgress);
      document.querySelectorAll(".pw-landing-dot").forEach((dot, index) => {
        const on = index === active;
        dot.classList.toggle("is-active", on);
        dot.setAttribute("aria-current", on ? "true" : "false");
      });
      track.querySelectorAll(".pw-landing-page").forEach((page, index) => {
        page.classList.toggle("is-near", Math.abs(index - pageProgress) < 0.55);
      });
    };
    track.addEventListener("scroll", onTrackScroll, { passive: true });
    onTrackScroll();
  }

  async function initFullExperience() {
    const reducedMotion = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const canvas = document.getElementById("pw-fe-canvas");
    const track = document.getElementById("pw-landing-track");
    if (!canvas || !track || canvas.dataset.pwFeInit) return;
    destroyFullExperience();
    canvas.dataset.pwFeInit = "1";
    landingTrack = track;
    document.documentElement.setAttribute("data-pw-fe-active", "1");

    const logo = document.getElementById("pw-fe-logo");
    const logoLine = document.getElementById("pw-fe-logo-line");
    const feUi = document.getElementById("pw-fe-ui");

    function revealUi() {
      if (logo) {
        logo.style.opacity = "1";
        logo.style.transform = "translateY(0)";
      }
      if (logoLine) logoLine.style.width = "200px";
    }

    initLandingTrack(track);

    let scrollP = 0;
    let resumeRender = null;

    bindTrackScroll(track, {
      onProgress(pageProgress) {
        scrollP = clamp01(pageProgress);
        const fade = clamp01((pageProgress - 0.75) / 0.4);
        canvas.style.opacity = String(1 - fade);
        canvas.style.pointerEvents = fade > 0.95 ? "none" : "";
        if (feUi) feUi.style.opacity = pageProgress > 0.45 ? "0" : "1";
        if (resumeRender) resumeRender();
      },
    });

    if (!reducedMotion) {
      try {
        await loadScript(THREE_CDN);
      } catch (_) {
        /* static fallback below */
      }
    }

    if (reducedMotion || typeof THREE === "undefined") {
      canvas.style.display = "none";
      revealUi();
      window._pwFeDispose = () => {
        canvas.removeAttribute("data-pw-fe-init");
      };
      return;
    }

    const isMobile = window.innerWidth < 720;
    const isSmallPhone = window.innerWidth < 420;
    const config = {
      bookCount: isMobile ? (isSmallPhone ? 72 : 96) : 100,
      pixelRatio: Math.min(window.devicePixelRatio || 1, isMobile ? 1.25 : 1.5),
      globeRadius: isMobile ? 3.25 : 5.0,
      cameraZ: isMobile ? 20 : 22,
      cameraY: isMobile ? 4.5 : 5.2,
      letterDuration: isMobile ? 3.0 : 3.6,
      bookDuration: isMobile ? 2.2 : 2.8,
      globeRestY: isMobile ? 1.2 : 1.7,
    };

    const renderer = new THREE.WebGLRenderer({ canvas, antialias: false, alpha: true, powerPreference: "high-performance" });
    renderer.setPixelRatio(config.pixelRatio);
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setClearColor(0x000000, 0);

    const scene = new THREE.Scene();
    scene.fog = new THREE.FogExp2(0x04020e, 0.0065);

    const camera = new THREE.PerspectiveCamera(52, window.innerWidth / window.innerHeight, 0.1, 2000);
    camera.position.set(0, config.cameraY, config.cameraZ);
    camera.lookAt(0, 1.5, 0);

    const letterStage = document.createElement("div");
    letterStage.className = "pw-fe-letter-stage";
    letterStage.setAttribute("aria-hidden", "true");
    document.body.appendChild(letterStage);

    const letterEls = WORD.split("").map((char, index) => {
      const span = document.createElement("span");
      span.className = "pw-fe-letter";
      span.textContent = char;
      letterStage.appendChild(span);
      return { el: span, char, index };
    });

    function updateLetters(t) {
      const W = window.innerWidth;
      const H = window.innerHeight;
      const gap = Math.min(Math.max(W * 0.065, 23), isMobile ? 34 : 54);
      const startX = -((WORD.length - 1) * gap) / 2;
      const baseY = H * (isMobile ? 0.42 : 0.43);
      const initialOffset = W * 0.62 + 120;

      letterEls.forEach((letter) => {
        const i = letter.index;
        const side = i <= 4 ? -1 : 1;
        const order = side < 0 ? i : WORD.length - 1 - i;
        const stagger = order * 0.045;
        const p = clamp01((t - stagger) / 0.74);
        const h = easeInOut(p);
        const settle = clamp01((t - 0.68 - stagger * 0.35) / 0.22);
        const fade = clamp01((t - 0.82) / 0.16);
        const finalX = startX + i * gap;
        const swirl = (1 - h) * (isMobile ? 82 : 135);
        const angle = (p * Math.PI * 3.6) + i * 0.72;
        const x = lerp(side * initialOffset, finalX + Math.cos(angle) * swirl, h);
        const y = lerp(baseY + Math.sin(i * 0.8) * 190, baseY + Math.sin(angle) * swirl * 0.46, h);
        const z = Math.sin(angle) * (1 - settle) * 180;
        const scale = lerp(1.4, 1, settle) * (1 - fade * 0.9);
        const opacity = p < 0.04 ? p / 0.04 : 1 - fade;
        const rot = side * (1 - settle) * (160 - p * 60);

        letter.el.style.opacity = String(Math.max(0, opacity));
        letter.el.style.transform = [
          `translate3d(${x}px, ${y}px, ${z}px)`,
          `rotateY(${rot}deg)`,
          `rotateZ(${Math.sin(angle) * 22 * (1 - settle)}deg)`,
          `scale(${Math.max(0.04, scale)})`,
        ].join(" ");
      });

      if (t >= 1) letterStage.style.display = "none";
    }

    scene.add(new THREE.AmbientLight(0x1a1235, 0.46));
    const keyLight = new THREE.DirectionalLight(0xffb06a, 0.85);
    keyLight.position.set(7, 10, 6);
    scene.add(keyLight);

    const globeGroup = new THREE.Group();
    globeGroup.position.set(0, config.globeRestY, 0);
    globeGroup.visible = false;
    scene.add(globeGroup);

    const halo = new THREE.Mesh(
      new THREE.SphereGeometry(config.globeRadius * 1.18, isMobile ? 16 : 24, isMobile ? 12 : 16),
      new THREE.MeshBasicMaterial({
        color: 0xff6b1a,
        transparent: true,
        opacity: 0.055,
        side: THREE.BackSide,
        depthWrite: false,
      }),
    );
    globeGroup.add(halo);

    const globeLight = new THREE.PointLight(0xff6b1a, 3.0, 30);
    globeGroup.add(globeLight);

    const bookGeo = new THREE.BoxGeometry(0.28, 0.47, 0.075);
    const bookMat = new THREE.MeshStandardMaterial({
      roughness: 0.72,
      metalness: 0.05,
      transparent: true,
      opacity: 0.98,
    });
    const books = new THREE.InstancedMesh(bookGeo, bookMat, config.bookCount);
    books.frustumCulled = false;
    globeGroup.add(books);

    const palette = [
      0xff6b1a, 0xd64612, 0x26104f, 0x3d1b82,
      0x142f55, 0x0f5168, 0x7b1c2d, 0xa97518,
      0x1f5b35, 0x201448, 0x5d235f, 0x0b3b49,
    ];
    const color = new THREE.Color();
    for (let i = 0; i < config.bookCount; i += 1) {
      color.setHex(palette[i % palette.length]);
      books.setColorAt(i, color);
    }
    books.instanceColor.needsUpdate = true;

    const dummy = new THREE.Object3D();
    const startPositions = [];
    const globePositions = [];
    const exitPositions = [];
    const startQuats = [];
    const globeQuats = [];
    const exitQuats = [];

    function makeBookSpiralPosition(i, total) {
      const u = i / Math.max(total - 1, 1);
      const angle = u * Math.PI * (isMobile ? 6.5 : 8.5);
      const radius = lerp(isMobile ? 1.5 : 2.3, isMobile ? 4.8 : 7.0, u);
      return new THREE.Vector3(
        lerp(isMobile ? -15 : -24, isMobile ? -5.5 : -8.5, u),
        Math.sin(angle) * radius * 0.62 + lerp(-1.4, 2.2, u),
        Math.cos(angle) * radius,
      );
    }

    function makeGlobePosition(i, total) {
      const phi = Math.acos(1 - 2 * (i + 0.5) / total);
      const theta = Math.PI * (1 + Math.sqrt(5)) * (i + 0.5);
      return new THREE.Vector3(
        Math.sin(phi) * Math.cos(theta) * config.globeRadius,
        Math.cos(phi) * config.globeRadius,
        Math.sin(phi) * Math.sin(theta) * config.globeRadius,
      );
    }

    function makeExitSpiralPosition(i, total) {
      const u = i / Math.max(total - 1, 1);
      const angle = u * Math.PI * (isMobile ? 7.2 : 9.4) + Math.PI * 0.4;
      const radius = lerp(isMobile ? 1.4 : 2.2, isMobile ? 5.2 : 8.4, u);
      return new THREE.Vector3(
        lerp(isMobile ? 5.6 : 8.2, isMobile ? 17 : 28, u),
        Math.sin(angle) * radius * 0.56 + lerp(2.1, -1.7, u),
        Math.cos(angle) * radius,
      );
    }

    function lookAlong(position, target, outQuat) {
      dummy.position.copy(position);
      dummy.lookAt(target);
      outQuat.copy(dummy.quaternion);
    }

    for (let i = 0; i < config.bookCount; i += 1) {
      const sp = makeBookSpiralPosition(i, config.bookCount);
      const gp = makeGlobePosition(i, config.bookCount);
      const ep = makeExitSpiralPosition(i, config.bookCount);
      startPositions.push(sp);
      globePositions.push(gp);
      exitPositions.push(ep);
      const sq = new THREE.Quaternion();
      const gq = new THREE.Quaternion();
      const eq = new THREE.Quaternion();
      lookAlong(sp, new THREE.Vector3(0, 0, 0), sq);
      lookAlong(gp, new THREE.Vector3(0, 0, 0), gq);
      lookAlong(ep, new THREE.Vector3(ep.x + 2, ep.y, ep.z), eq);
      startQuats.push(sq);
      globeQuats.push(gq);
      exitQuats.push(eq);
    }

    function setBooks(stage, scrollExitP) {
      const total = config.bookCount;
      for (let i = 0; i < total; i += 1) {
        let p = 0;
        let scale = 0.001;

        if (stage === "incoming") {
          const stagger = (i / total) * 0.36;
          p = easeOut(clamp01((scrollExitP - stagger) / (1 - stagger)));
          dummy.position.copy(startPositions[i]).lerp(globePositions[i], p);
          dummy.quaternion.copy(startQuats[i]).slerp(globeQuats[i], p);
          scale = lerp(0.15, 1, p);
        } else if (stage === "globe") {
          dummy.position.copy(globePositions[i]);
          dummy.quaternion.copy(globeQuats[i]);
          scale = 1;
        } else if (stage === "exit") {
          const stagger = (i / total) * 0.28;
          p = easeInOut(clamp01((scrollExitP - stagger) / (1 - stagger)));
          dummy.position.copy(globePositions[i]).lerp(exitPositions[i], p);
          dummy.quaternion.copy(globeQuats[i]).slerp(exitQuats[i], p);
          scale = lerp(1, 0.48, p);
        }

        dummy.scale.setScalar(scale);
        dummy.updateMatrix();
        books.setMatrixAt(i, dummy.matrix);
      }
      books.instanceMatrix.needsUpdate = true;
    }

    setBooks("incoming", 0);

    let phase = "letters";
    let phaseT = 0;
    let time = 0;
    let lastTs = 0;
    let dt = 0;
    let uiRevealed = false;
    let renderActive = true;

    function revealWhenReady() {
      if (uiRevealed) return;
      uiRevealed = true;
      revealUi();
    }

    onResize = () => {
      camera.aspect = window.innerWidth / window.innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(window.innerWidth, window.innerHeight);
    };
    window.addEventListener("resize", onResize);

    function needsRender() {
      return phase !== "settled" || scrollP < 1.35;
    }

    function updatePhase() {
      if (phase === "letters") {
        const p = clamp01(phaseT / config.letterDuration);
        updateLetters(p);
        if (p >= 1) {
          phase = "booksIn";
          phaseT = 0;
          globeGroup.visible = true;
        }
      } else if (phase === "booksIn") {
        const p = clamp01(phaseT / config.bookDuration);
        setBooks("incoming", p);
        if (p >= 1) {
          phase = "settled";
          phaseT = 0;
          globeGroup.rotation.set(0, 0, 0);
          setBooks("globe", 0);
          revealWhenReady();
        }
      } else if (phase === "settled") {
        const exitP = clamp01((scrollP - 0.12) / 0.88);
        if (exitP > 0) {
          setBooks("exit", exitP);
        } else {
          setBooks("globe", 0);
        }
        globeGroup.rotation.set(0, 0, 0);
      }
    }

    function animate(ts) {
      if (!renderActive) return;
      rafId = requestAnimationFrame(animate);
      dt = Math.min((ts - lastTs) / 1000, 0.05);
      lastTs = ts;
      time += dt;
      phaseT += dt;
      globeLight.intensity = 2.6 + Math.sin(time * 1.4) * 0.35;
      updatePhase();
      renderer.render(scene, camera);
      if (!needsRender()) {
        renderActive = false;
        rafId = 0;
      }
    }

    resumeRender = () => {
      if (needsRender() && !renderActive) {
        renderActive = true;
        lastTs = 0;
        rafId = requestAnimationFrame(animate);
      }
    };

    window._pwFeDispose = () => {
      renderer.dispose();
      bookGeo.dispose();
      bookMat.dispose();
      halo.geometry.dispose();
      halo.material.dispose();
      letterStage.remove();
      canvas.removeAttribute("data-pw-fe-init");
    };

    renderActive = true;
    rafId = requestAnimationFrame(animate);
  }

  window.initFullExperience = () => {
    void initFullExperience();
  };
  window.destroyFullExperience = destroyFullExperience;
})();
