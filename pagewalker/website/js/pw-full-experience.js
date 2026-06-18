// pw-full-experience.js — scroll-driven Three.js book-globe intro

(function () {
  "use strict";

  const PLAY_STORE_URL = "https://play.google.com/store/apps/details?id=com.pagewalker.app";

  let rafId = 0;
  let onScroll = null;
  let onResize = null;

  function destroyFullExperience() {
    if (rafId) cancelAnimationFrame(rafId);
    rafId = 0;
    if (onScroll) window.removeEventListener("scroll", onScroll);
    if (onResize) window.removeEventListener("resize", onResize);
    onScroll = null;
    onResize = null;
    if (typeof window._pwFeDispose === "function") {
      window._pwFeDispose();
      window._pwFeDispose = null;
    }
    document.documentElement.removeAttribute("data-pw-fe-active");
    document.querySelectorAll(".pw-fe-disc-card").forEach((el) => el.remove());
  }

  function initFullExperience() {
    if (typeof THREE === "undefined") return;
    const canvas = document.getElementById("pw-fe-canvas");
    if (!canvas || canvas.dataset.pwFeInit) return;
    destroyFullExperience();
    canvas.dataset.pwFeInit = "1";
    document.documentElement.setAttribute("data-pw-fe-active", "1");

    const renderer = new THREE.WebGLRenderer({ canvas, antialias: true });
    renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
    renderer.setSize(innerWidth, innerHeight);
    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(52, innerWidth / innerHeight, 0.1, 2000);
    camera.position.set(0, 5, 22);
    camera.lookAt(0, 1, 0);

    onResize = () => {
      camera.aspect = innerWidth / innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(innerWidth, innerHeight);
    };
    window.addEventListener("resize", onResize);

    const c01 = (v) => Math.max(0, Math.min(1, v));
    const lerp = (a, b, t) => a + (b - a) * t;
    const easeOut = (t) => 1 - Math.pow(1 - t, 3);
    const easeIn = (t) => t * t * t;
    const easeInOut = (t) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);

    let time = 0;
    let dt = 0;
    let lastTs = 0;
    let scrollP = 0;
    let revealed = false;

    const GLOBE_R = 5.0;
    const GLOBE_X = 0;
    const GLOBE_Y_START = 6.5;
    const GLOBE_Y_REST = 1.8;
    const GLOBE_CNT = 220;
    const BOOK_COLS = [
      0xff6b1a, 0xd44010, 0xb83008, 0x2d1060, 0x1a0848, 0x4a1080,
      0x8b1818, 0x601010, 0x1a4055, 0x0a2840, 0xc89020, 0xa06010,
      0x402080, 0x301060, 0x205030, 0x103020,
    ];

    const starsMat = new THREE.ShaderMaterial({
      uniforms: { uTime: { value: 0 } },
      vertexShader: `
        attribute float aSize; attribute float aTw; uniform float uTime; varying float vA;
        void main(){
          vA=.45+.55*sin(aTw+uTime*.45);
          gl_PointSize=aSize*vA*(320./length((modelViewMatrix*vec4(position,1.)).xyz));
          gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.);
        }
      `,
      fragmentShader: `
        varying float vA;
        void main(){
          float d=length(gl_PointCoord-.5); if(d>.5)discard;
          gl_FragColor=vec4(1.,1.,1.,(1.-smoothstep(0.,.5,d))*vA*.65);
        }
      `,
      transparent: true,
      depthWrite: false,
      blending: THREE.AdditiveBlending,
    });
    {
      const n = 1600;
      const pos = new Float32Array(n * 3);
      const sz = new Float32Array(n);
      const tw = new Float32Array(n);
      for (let i = 0; i < n; i++) {
        const phi = Math.acos(2 * Math.random() - 1);
        const theta = Math.random() * Math.PI * 2;
        const r = 500 + Math.random() * 300;
        pos[i * 3] = r * Math.sin(phi) * Math.cos(theta);
        pos[i * 3 + 1] = r * Math.cos(phi);
        pos[i * 3 + 2] = r * Math.sin(phi) * Math.sin(theta);
        sz[i] = Math.random() * 2 + 0.3;
        tw[i] = Math.random() * Math.PI * 2;
      }
      const geo = new THREE.BufferGeometry();
      geo.setAttribute("position", new THREE.BufferAttribute(pos, 3));
      geo.setAttribute("aSize", new THREE.BufferAttribute(sz, 1));
      geo.setAttribute("aTw", new THREE.BufferAttribute(tw, 1));
      scene.add(new THREE.Points(geo, starsMat));
    }

    const globeGroup = new THREE.Group();
    globeGroup.position.set(GLOBE_X, GLOBE_Y_START, 0);
    scene.add(globeGroup);

    globeGroup.add(new THREE.Mesh(
      new THREE.SphereGeometry(GLOBE_R * 1.22, 32, 32),
      new THREE.MeshBasicMaterial({ color: 0xff6b1a, transparent: true, opacity: 0.05, side: THREE.BackSide, depthWrite: false }),
    ));
    globeGroup.add(new THREE.Mesh(
      new THREE.SphereGeometry(GLOBE_R * 0.97, 16, 16),
      new THREE.MeshBasicMaterial({ color: 0xff6b1a, wireframe: true, transparent: true, opacity: 0.03 }),
    ));

    const startPos = [];
    const endPos = [];
    const startQuats = [];
    const endQuats = [];
    const dummy = new THREE.Object3D();
    const GORIGIN = new THREE.Vector3(GLOBE_X, GLOBE_Y_START, 0);

    for (let i = 0; i < GLOBE_CNT; i++) {
      const t = i / GLOBE_CNT;
      startPos.push(new THREE.Vector3(-30 + t * 26, Math.sin(t * Math.PI * 4) * 3.5, Math.cos(t * Math.PI * 3) * 2.5));
      const phi = Math.acos(1 - 2 * (i + 0.5) / GLOBE_CNT);
      const theta = Math.PI * (1 + Math.sqrt(5)) * (i + 0.5);
      const nx = Math.sin(phi) * Math.cos(theta);
      const ny = Math.cos(phi);
      const nz = Math.sin(phi) * Math.sin(theta);
      const ep = new THREE.Vector3(nx * GLOBE_R, ny * GLOBE_R, nz * GLOBE_R);
      endPos.push(ep);
      dummy.position.copy(ep);
      dummy.lookAt(new THREE.Vector3(0, 0, 0));
      endQuats.push(dummy.quaternion.clone());
      startQuats.push(new THREE.Quaternion());
    }
    const startPosLocal = startPos.map((p) => p.clone().sub(GORIGIN));

    const bkGeo = new THREE.BoxGeometry(0.30, 0.50, 0.09);
    const bkMat = new THREE.MeshStandardMaterial({ roughness: 0.65, metalness: 0.08 });
    const globe = new THREE.InstancedMesh(bkGeo, bkMat, GLOBE_CNT);
    globeGroup.add(globe);
    const colBuf = new THREE.Color();
    for (let i = 0; i < GLOBE_CNT; i++) {
      dummy.position.copy(startPosLocal[i]);
      dummy.quaternion.copy(startQuats[i]);
      dummy.updateMatrix();
      globe.setMatrixAt(i, dummy.matrix);
      colBuf.setHex(BOOK_COLS[i % BOOK_COLS.length]);
      globe.setColorAt(i, colBuf);
    }
    globe.instanceMatrix.needsUpdate = true;
    globe.instanceColor.needsUpdate = true;

    scene.add(new THREE.AmbientLight(0x1a0838, 0.42));
    const keyLight = new THREE.DirectionalLight(0xffa040, 0.9);
    keyLight.position.set(6, 12, 6);
    scene.add(keyLight);
    const globePt = new THREE.PointLight(0xff6b1a, 3.5, 28);
    globeGroup.add(globePt);
    const fillPt = new THREE.PointLight(0x4020a0, 0.5, 22);
    fillPt.position.set(-12, 4, 5);
    scene.add(fillPt);
    const bookLight = new THREE.PointLight(0xffd080, 1.5, 18);
    bookLight.position.set(0, 3, 3);
    scene.add(bookLight);
    scene.fog = new THREE.FogExp2(0x04020e, 0.007);

    let phase = "assembly";
    let phaseT = 0;
    let globeVY = 0;
    let globeY = GLOBE_Y_START;
    const ASSEMBLY_DUR = 3.8;

    const streamBooks = [];
    const streamCurve = new THREE.CatmullRomCurve3([
      new THREE.Vector3(GLOBE_R + 0.4, 0.0, 0.0),
      new THREE.Vector3(8, 0.8, 3.5),
      new THREE.Vector3(13, 0.3, 7.0),
      new THREE.Vector3(18, -0.3, 10.0),
      new THREE.Vector3(23, -0.9, 13.0),
    ]);
    let streamTimer = 0;

    function updateStream() {
      streamTimer++;
      if (streamBooks.length < 24 && streamTimer % 10 === 0) {
        const w = 0.26 + Math.random() * 0.22;
        const h = 0.42 + Math.random() * 0.22;
        const d = 0.06 + Math.random() * 0.04;
        const mat = new THREE.MeshStandardMaterial({
          color: BOOK_COLS[Math.floor(Math.random() * BOOK_COLS.length)],
          roughness: 0.6,
          metalness: 0.1,
          transparent: true,
          opacity: 0,
        });
        const mesh = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), mat);
        scene.add(mesh);
        const axis = new THREE.Vector3(Math.random() - 0.5, Math.random() - 0.5, Math.random() - 0.5).normalize();
        streamBooks.push({ mesh, t: 0, speed: 0.003 + Math.random() * 0.002, axis, rotSpd: (Math.random() - 0.5) * 0.04 });
      }
      for (let i = streamBooks.length - 1; i >= 0; i--) {
        const b = streamBooks[i];
        b.t += b.speed;
        if (b.t > 1.12) {
          scene.remove(b.mesh);
          b.mesh.geometry.dispose();
          b.mesh.material.dispose();
          streamBooks.splice(i, 1);
          continue;
        }
        const cp = streamCurve.getPoint(Math.min(b.t, 1.0));
        b.mesh.position.set(globeGroup.position.x + cp.x, globeGroup.position.y + cp.y, globeGroup.position.z + cp.z);
        b.mesh.rotateOnAxis(b.axis, b.rotSpd);
        b.mesh.material.opacity = b.t < 0.08 ? b.t / 0.08 : b.t > 0.8 ? c01(1 - (b.t - 0.8) / 0.3) : 1;
      }
    }

    const DISC = [
      { title: "The Way of Kings", author: "Brandon Sanderson", genre: "Fantasy", col: "#180840", acc: "#8040ff" },
      { title: "Dune", author: "Frank Herbert", genre: "Sci-Fi", col: "#102010", acc: "#28a830" },
      { title: "Project Hail Mary", author: "Andy Weir", genre: "Sci-Fi", col: "#081828", acc: "#2878d8" },
      { title: "The Name of the Wind", author: "Patrick Rothfuss", genre: "Fantasy", col: "#180a08", acc: "#ff6b1a" },
      { title: "Hyperion", author: "Dan Simmons", genre: "Sci-Fi", col: "#200818", acc: "#c840a8" },
      { title: "Mistborn", author: "Brandon Sanderson", genre: "Fantasy", col: "#080820", acc: "#6848ff" },
      { title: "The Martian", author: "Andy Weir", genre: "Sci-Fi", col: "#180800", acc: "#e03010" },
      { title: "Ender's Game", author: "Orson Scott Card", genre: "Sci-Fi", col: "#001018", acc: "#00a8d8" },
    ];
    const cardEls = [];
    const discLabel = document.getElementById("pw-fe-disc-label");
    const scrollHint = document.getElementById("pw-fe-scroll-hint");
    DISC.forEach((b) => {
      const el = document.createElement("div");
      el.className = "pw-fe-disc-card";
      el.style.background = b.col;
      el.style.borderLeft = `4px solid ${b.acc}`;
      el.innerHTML = `<div class="genre" style="color:${b.acc}">${b.genre}</div><div class="title">${b.title}</div><div class="author">${b.author}</div>`;
      document.body.appendChild(el);
      cardEls.push(el);
    });
    let currentCard = -1;

    function updateCards() {
      const cs = 0.22;
      const ce = 0.82;
      const cp = c01((scrollP - cs) / (ce - cs));
      const idx = Math.min(Math.floor(cp * DISC.length), DISC.length - 1);
      if (discLabel) discLabel.style.color = "rgba(255,255,255,.4)";
      if (idx !== currentCard) {
        if (currentCard >= 0) {
          const old = cardEls[currentCard];
          old.style.transition = "transform .55s cubic-bezier(.55,0,1,.45),opacity .45s ease";
          old.style.transform = "translate(260px,-260px) rotate(10deg)";
          old.style.opacity = "0";
        }
        currentCard = idx;
        const el = cardEls[idx];
        el.style.transition = "none";
        el.style.transform = "translate(-260px,260px) rotate(-10deg)";
        el.style.opacity = "0";
        requestAnimationFrame(() => requestAnimationFrame(() => {
          el.style.transition = "transform .72s cubic-bezier(.23,1,.32,1),opacity .55s ease";
          el.style.transform = "translate(0,0) rotate(0deg)";
          el.style.opacity = "1";
        }));
      }
    }

    function hideCards() {
      cardEls.forEach((el) => {
        el.style.opacity = "0";
        el.style.transform = "translate(-400px,400px)";
      });
      if (discLabel) discLabel.style.color = "rgba(255,255,255,0)";
      currentCard = -1;
    }

    onScroll = () => {
      if (phase !== "settled") return;
      const scroller = document.getElementById("pw-fe-scroller");
      const zone = scroller ? scroller.offsetHeight : document.body.scrollHeight;
      const max = Math.max(zone - window.innerHeight, 1);
      scrollP = c01(window.scrollY / max);
      if (scrollHint) {
        scrollHint.style.color = scrollP > 0.05 ? "rgba(255,255,255,0)" : "rgba(255,255,255,.3)";
      }
      if (window.scrollY > zone * 0.92) {
        canvas.style.opacity = "0";
        canvas.style.pointerEvents = "none";
        hideCards();
        if (discLabel) discLabel.style.color = "rgba(255,255,255,0)";
      } else {
        canvas.style.opacity = "1";
        canvas.style.pointerEvents = "";
      }
    };
    window.addEventListener("scroll", onScroll);

    function revealUI() {
      const logo = document.getElementById("pw-fe-logo");
      if (logo) {
        logo.style.opacity = "1";
        logo.style.transform = "translateY(0)";
      }
      const line = document.getElementById("pw-fe-logo-line");
      if (line) line.style.width = "200px";
      setTimeout(() => {
        const cta = document.getElementById("pw-fe-cta");
        if (cta) cta.style.opacity = "1";
        const skip = document.getElementById("pw-fe-skip");
        if (skip) skip.style.display = "none";
      }, 1500);
    }

    function skipAnim() {
      for (let i = 0; i < GLOBE_CNT; i++) {
        dummy.position.copy(endPos[i]);
        dummy.quaternion.copy(endQuats[i]);
        dummy.updateMatrix();
        globe.setMatrixAt(i, dummy.matrix);
      }
      globe.instanceMatrix.needsUpdate = true;
      globeGroup.position.set(GLOBE_X, GLOBE_Y_REST, 0);
      phase = "settled";
      phaseT = 0;
      if (scrollHint) scrollHint.style.color = "rgba(255,255,255,.3)";
      const skip = document.getElementById("pw-fe-skip");
      if (skip) skip.style.display = "none";
      if (!revealed) {
        revealed = true;
        revealUI();
      }
    }

    const skipBtn = document.getElementById("pw-fe-skip");
    if (skipBtn) skipBtn.addEventListener("click", skipAnim);

    const ctaLink = document.querySelector("#pw-fe-cta a");
    if (ctaLink && !ctaLink.getAttribute("href")) {
      ctaLink.href = PLAY_STORE_URL;
    }

    function updatePhase() {
      if (phase === "assembly") {
        phaseT += dt;
        const ov = c01(phaseT / ASSEMBLY_DUR);
        for (let i = 0; i < GLOBE_CNT; i++) {
          const stagger = (i / GLOBE_CNT) * 0.42;
          const ip = easeOut(c01((ov - stagger) / (1 - stagger)));
          dummy.position.lerpVectors(startPosLocal[i], endPos[i], ip);
          dummy.quaternion.copy(startQuats[i]).slerp(endQuats[i], ip);
          dummy.updateMatrix();
          globe.setMatrixAt(i, dummy.matrix);
        }
        globe.instanceMatrix.needsUpdate = true;
        if (ov >= 1) { phase = "spinBounce"; phaseT = 0; }
      } else if (phase === "spinBounce") {
        phaseT += dt;
        const p = c01(phaseT / 4.5);
        globeGroup.rotation.y += lerp(0.008, 0.065, easeInOut(c01(phaseT / 1.5)));
        if (phaseT > 1.2) {
          const bt = phaseT - 1.2;
          const amp = Math.max(0, 2.0 * Math.exp(-bt * 0.85));
          globeGroup.position.y = GLOBE_Y_START + Math.sin(bt * 5.5) * amp;
        }
        if (p >= 1) {
          phase = "fall";
          phaseT = 0;
          globeVY = 0;
          globeY = globeGroup.position.y;
        }
      } else if (phase === "fall") {
        phaseT += dt;
        globeVY -= 0.007;
        globeY += globeVY;
        if (globeY <= GLOBE_Y_REST) {
          globeY = GLOBE_Y_REST;
          globeVY = -globeVY * 0.46;
          if (Math.abs(globeVY) < 0.012) {
            globeVY = 0;
            globeY = GLOBE_Y_REST;
            phase = "settled";
            phaseT = 0;
            if (scrollHint) scrollHint.style.color = "rgba(255,255,255,.3)";
            if (!revealed) {
              revealed = true;
              setTimeout(revealUI, 400);
            }
          }
        }
        globeGroup.position.y = globeY;
        globeGroup.rotation.y += 0.055;
      } else if (phase === "settled") {
        globeGroup.rotation.y += 0.035 + scrollP * 0.045;
        if (scrollP > 0.05 && scrollP < 0.33) updateStream();
        if (scrollP >= 0.22 && scrollP < 0.83) updateCards();
        else if (scrollP >= 0.83) hideCards();
      }
    }

    function animate(ts) {
      rafId = requestAnimationFrame(animate);
      dt = Math.min((ts - lastTs) / 1000, 0.05);
      lastTs = ts;
      time += dt;
      starsMat.uniforms.uTime.value = time;
      globePt.intensity = 2.8 + Math.sin(time * 1.6) * 0.7;
      updatePhase();
      camera.position.x = Math.sin(time * 0.04) * 0.5;
      camera.lookAt(0, 2, 0);
      renderer.render(scene, camera);
    }

    window._pwFeDispose = () => {
      renderer.dispose();
      bkGeo.dispose();
      bkMat.dispose();
      starsMat.dispose();
      streamBooks.forEach((b) => {
        scene.remove(b.mesh);
        b.mesh.geometry.dispose();
        b.mesh.material.dispose();
      });
      canvas.removeAttribute("data-pw-fe-init");
    };

    rafId = requestAnimationFrame(animate);
  }

  window.initFullExperience = initFullExperience;
  window.destroyFullExperience = destroyFullExperience;
})();
