// pw-hero-animation.js
// Cinematic space-to-book hero animation for PageWalker
// Drop this file into pagewalker/website/js/
// Then add <script src="/js/pw-hero-animation.js"></script> to index.html (before </body>)
// Call initHeroAnimation() after renderHome() mounts the .hero element

(function () {
  "use strict";

  function initHeroAnimation() {
    const hero = document.querySelector(".hero");
    if (!hero) return;

    // Inject canvas + book overlay on top of existing hero
    hero.style.position = "relative";
    hero.style.overflow = "hidden";
    hero.style.minHeight = "100vh";

    // Hide hero text initially
    const heroInner = hero.querySelector(".hero-inner");
    if (heroInner) heroInner.style.opacity = "0";

    // Canvas
    const canvas = document.createElement("canvas");
    canvas.id = "pw-hero-canvas";
    canvas.style.cssText =
      "position:absolute;top:0;left:0;width:100%;height:100%;z-index:2;";
    hero.prepend(canvas);

    // Book overlay
    const bookWrap = document.createElement("div");
    bookWrap.id = "pw-book-wrap";
    bookWrap.style.cssText =
      "position:absolute;top:0;left:0;width:100%;height:100%;z-index:3;" +
      "display:flex;align-items:center;justify-content:center;opacity:0;" +
      "pointer-events:none;transition:opacity .6s;";
    bookWrap.innerHTML = `
      <div id="pw-book" style="
        width:min(440px,88vw);height:min(540px,78vh);
        position:relative;perspective:1400px;">
        <div id="pw-cover-left" style="
          position:absolute;top:0;left:0;width:50%;height:100%;
          background:linear-gradient(135deg,#1a0a2e 0%,#2d1060 40%,#1a0a2e 100%);
          border-radius:4px 0 0 4px;border:1px solid rgba(255,107,26,.3);
          transform-origin:right center;transform:rotateY(0deg);
          transition:transform 1.4s cubic-bezier(.23,1,.32,1);
          display:flex;flex-direction:column;align-items:center;justify-content:center;">
          <div style="width:3px;height:70%;background:linear-gradient(to bottom,transparent,#ff6b1a,transparent);
            position:absolute;right:0;top:15%;border-radius:2px;box-shadow:0 0 10px #ff6b1a;"></div>
          <p style="color:#c8a0ff;font-size:clamp(1rem,3.5vw,1.3rem);font-style:italic;text-align:center;">✦ PageWalker ✦</p>
          <p style="color:#8060c0;font-size:clamp(.7rem,2vw,.85rem);text-align:center;margin-top:.3rem;">Your reading universe</p>
        </div>
        <div id="pw-cover-right" style="
          position:absolute;top:0;right:0;width:50%;height:100%;
          background:linear-gradient(135deg,#1a0a2e 0%,#2d1060 40%,#1a0a2e 100%);
          border-radius:0 4px 4px 0;border:1px solid rgba(255,107,26,.3);
          display:flex;align-items:center;justify-content:center;">
          <span style="font-size:clamp(2.5rem,8vw,4rem);">📚</span>
        </div>
        <div id="pw-page-inner" style="
          position:absolute;top:0;left:0;width:100%;height:100%;
          background:#fdf6e3;border-radius:4px;
          display:flex;flex-direction:column;align-items:center;justify-content:center;
          padding:2rem;opacity:0;transition:opacity .8s .8s;text-align:center;">
          <span style="font-size:2.5rem;margin-bottom:1rem;">📖</span>
          <h2 style="font-size:clamp(1.3rem,4vw,1.9rem);color:#ff6b1a;margin-bottom:.5rem;font-family:Georgia,serif;">Welcome to PageWalker</h2>
          <p style="font-size:clamp(.8rem,2.5vw,.95rem);color:#555;line-height:1.7;margin-bottom:1.5rem;">
            Discover books. Track your reading.<br>Connect with readers across the universe.
          </p>
          <button id="pw-enter-btn" style="
            background:#ff6b1a;color:#fff;border:none;
            padding:12px 28px;border-radius:999px;font-size:14px;cursor:pointer;">
            Explore PageWalker →
          </button>
        </div>
      </div>`;
    hero.appendChild(bookWrap);

    // Skip hint
    const hint = document.createElement("div");
    hint.id = "pw-hint";
    hint.textContent = "click to skip";
    hint.style.cssText =
      "position:absolute;bottom:1.2rem;left:50%;transform:translateX(-50%);" +
      "color:rgba(255,255,255,.4);font-size:11px;letter-spacing:.12em;" +
      "text-transform:uppercase;z-index:10;pointer-events:none;";
    hero.appendChild(hint);

    // Status message
    const msg = document.createElement("div");
    msg.id = "pw-msg";
    msg.style.cssText =
      "position:absolute;bottom:3.5rem;left:50%;transform:translateX(-50%);" +
      "color:#fff;font-size:12px;letter-spacing:.12em;text-transform:uppercase;" +
      "z-index:10;pointer-events:none;text-shadow:0 0 16px rgba(255,140,60,.7);" +
      "white-space:nowrap;";
    hero.appendChild(msg);

    // ── Canvas engine ──────────────────────────────────────────────
    const ctx = canvas.getContext("2d");
    let W, H;
    function resize() {
      W = canvas.width = canvas.offsetWidth;
      H = canvas.height = canvas.offsetHeight;
    }
    resize();
    window.addEventListener("resize", resize);

    let frame = 0, phase = 0, phaseTimer = 0;
    let rocketX, rocketY, shakeX = 0, shakeY = 0;
    let earthX, earthY, earthR;
    let stars = [], stars2 = [], marsGround = [], marsParticles = [], trail = [];
    let bookDone = false;

    function initStars() {
      stars = [];
      for (let i = 0; i < 280; i++)
        stars.push({ x: Math.random() * W, y: Math.random() * H, r: Math.random() * 1.4 + .3, tw: Math.random() * Math.PI * 2 });
    }
    function initStars2() {
      stars2 = [];
      for (let i = 0; i < 80; i++)
        stars2.push({ x: Math.random() * W, y: Math.random() * H, speed: Math.random() * 7 + 2, r: Math.random() * 1.4 + .5 });
    }
    function initMars() {
      marsGround = [];
      for (let x = 0; x <= W; x += 8)
        marsGround.push({ x, y: H * .72 + Math.sin(x * .02) * 16 + Math.sin(x * .07) * 7 + Math.random() * 5 });
      rocketX = W * .38; rocketY = H * .62;
      earthX = W * .75; earthY = H * .18; earthR = Math.min(W, H) * .09;
      marsParticles = []; trail = [];
    }
    initStars(); initStars2(); initMars();

    const lerp = (a, b, t) => a + (b - a) * t;
    const easeIn = t => t * t * t;
    const easeOut = t => 1 - Math.pow(1 - t, 3);
    const easeIO = t => t < .5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;

    function setMsg(txt) { msg.textContent = txt; }

    function drawStars(alpha) {
      stars.forEach(s => {
        const tw = Math.sin(s.tw + frame * .015) * .35 + .65;
        ctx.save(); ctx.globalAlpha = alpha * tw;
        ctx.fillStyle = "#fff";
        ctx.beginPath(); ctx.arc(s.x, s.y, s.r, 0, Math.PI * 2); ctx.fill();
        ctx.restore();
      });
    }

    function drawMars() {
      const hy = H * .7;
      const sky = ctx.createLinearGradient(0, 0, 0, hy);
      sky.addColorStop(0, "#0a0010"); sky.addColorStop(.6, "#1a0830"); sky.addColorStop(1, "#3d1510");
      ctx.fillStyle = sky; ctx.fillRect(0, 0, W, hy);
      const gnd = ctx.createLinearGradient(0, hy, 0, H);
      gnd.addColorStop(0, "#8b3a1a"); gnd.addColorStop(.3, "#6b2a10"); gnd.addColorStop(1, "#3d1508");
      ctx.fillStyle = gnd;
      ctx.beginPath(); ctx.moveTo(0, H);
      marsGround.forEach(p => ctx.lineTo(p.x, p.y));
      ctx.lineTo(W, H); ctx.closePath(); ctx.fill();
    }

    function drawEarth(alpha) {
      ctx.save(); ctx.globalAlpha = alpha;
      const glow = ctx.createRadialGradient(earthX, earthY, earthR * .5, earthX, earthY, earthR * 2.4);
      glow.addColorStop(0, "rgba(100,180,255,.22)"); glow.addColorStop(1, "rgba(0,0,0,0)");
      ctx.fillStyle = glow; ctx.beginPath(); ctx.arc(earthX, earthY, earthR * 2.4, 0, Math.PI * 2); ctx.fill();
      const eg = ctx.createRadialGradient(earthX - earthR * .3, earthY - earthR * .3, earthR * .1, earthX, earthY, earthR);
      eg.addColorStop(0, "#4ab8ff"); eg.addColorStop(.4, "#1e7fd4"); eg.addColorStop(.7, "#2d6e2d"); eg.addColorStop(1, "#0d3d7a");
      ctx.fillStyle = eg; ctx.beginPath(); ctx.arc(earthX, earthY, earthR, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = "rgba(255,255,255,.3)";
      ctx.beginPath(); ctx.ellipse(earthX - earthR * .2, earthY - earthR * .3, earthR * .38, earthR * .11, -.3, 0, Math.PI * 2); ctx.fill();
      ctx.beginPath(); ctx.ellipse(earthX + earthR * .3, earthY + earthR * .1, earthR * .28, earthR * .09, .4, 0, Math.PI * 2); ctx.fill();
      ctx.restore();
    }

    function drawRocket(x, y, angle, flame) {
      ctx.save(); ctx.translate(x + shakeX, y + shakeY); ctx.rotate(angle);
      if (flame > 0) {
        const fg = ctx.createRadialGradient(0, 22, 2, 0, 30, 26 * flame);
        fg.addColorStop(0, "rgba(255,255,200,.9)"); fg.addColorStop(.3, "rgba(255,140,0,.7)");
        fg.addColorStop(.7, "rgba(255,60,0,.3)"); fg.addColorStop(1, "rgba(255,60,0,0)");
        ctx.fillStyle = fg; ctx.beginPath(); ctx.ellipse(0, 22 + 13 * flame, 7, 17 * flame, 0, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = "rgba(255,255,200,.8)"; ctx.beginPath(); ctx.ellipse(0, 22 + 4 * flame, 3, 7 * flame, 0, 0, Math.PI * 2); ctx.fill();
      }
      ctx.fillStyle = "#e8e8ec";
      ctx.beginPath(); ctx.moveTo(0, -26); ctx.quadraticCurveTo(10, -10, 10, 16); ctx.lineTo(-10, 16); ctx.quadraticCurveTo(-10, -10, 0, -26); ctx.fill();
      ctx.fillStyle = "#ff6b1a";
      ctx.beginPath(); ctx.moveTo(0, -26); ctx.lineTo(6, -12); ctx.lineTo(-6, -12); ctx.closePath(); ctx.fill();
      ctx.fillStyle = "rgba(100,200,255,.8)"; ctx.beginPath(); ctx.arc(0, -4, 5, 0, Math.PI * 2); ctx.fill();
      ctx.strokeStyle = "rgba(255,255,255,.4)"; ctx.lineWidth = 1; ctx.stroke();
      ctx.fillStyle = "#ff6b1a";
      ctx.beginPath(); ctx.moveTo(10, 10); ctx.lineTo(18, 22); ctx.lineTo(10, 18); ctx.closePath(); ctx.fill();
      ctx.beginPath(); ctx.moveTo(-10, 10); ctx.lineTo(-18, 22); ctx.lineTo(-10, 18); ctx.closePath(); ctx.fill();
      ctx.restore();
    }

    const phaseDur = [90, 80, 200, 120, 80];

    function loop() {
      if (bookDone) return;
      requestAnimationFrame(loop);
      frame++; phaseTimer++;
      shakeX *= .82; shakeY *= .82;
      ctx.clearRect(0, 0, W, H);

      if (phase === 0) {
        drawStars(.6); drawMars(); drawEarth(.7);
        drawRocket(rocketX, H * .62 + Math.sin(frame * .04) * 3, 0, Math.sin(frame * .15) * .2 + .3);
        setMsg("🚀 Launching from Mars…");
        if (phaseTimer > phaseDur[0]) { phase = 1; phaseTimer = 0; }
      }
      else if (phase === 1) {
        const p = Math.min(phaseTimer / phaseDur[1], 1);
        drawStars(.6); drawMars(); drawEarth(.7);
        const ly = H * .62 - easeIn(p) * H * .45;
        shakeX = (Math.random() - .5) * 4 * p; shakeY = (Math.random() - .5) * 4 * p;
        for (let i = 0; i < 4; i++)
          marsParticles.push({ x: rocketX + (Math.random() - .5) * 8, y: ly + 20, vx: (Math.random() - .5) * 5, vy: Math.random() * 4 + 2, life: 1, r: Math.random() * 5 + 2, col: `hsl(${Math.random() * 40 + 10},90%,60%)` });
        marsParticles.forEach(mp => { mp.x += mp.vx; mp.y += mp.vy; mp.life -= .04; });
        marsParticles = marsParticles.filter(mp => mp.life > 0);
        marsParticles.forEach(mp => { ctx.save(); ctx.globalAlpha = mp.life; ctx.fillStyle = mp.col; ctx.beginPath(); ctx.arc(mp.x, mp.y, mp.r, 0, Math.PI * 2); ctx.fill(); ctx.restore(); });
        drawRocket(rocketX, ly, 0, .6 + p * 2);
        setMsg("🔥 Engines at full thrust!");
        if (p >= 1) { phase = 2; phaseTimer = 0; rocketX = W * .38; rocketY = H * .18; initStars2(); }
      }
      else if (phase === 2) {
        const p = Math.min(phaseTimer / phaseDur[2], 1), ep = easeOut(p);
        const bg = ctx.createRadialGradient(W / 2, H / 2, 0, W / 2, H / 2, Math.max(W, H));
        bg.addColorStop(0, "#0a0018"); bg.addColorStop(1, "#000005");
        ctx.fillStyle = bg; ctx.fillRect(0, 0, W, H);
        stars2.forEach(s => {
          const sp = s.speed * (1 + p * 4); s.x -= sp; if (s.x < 0) s.x = W;
          ctx.save(); ctx.globalAlpha = .6 + p * .4; ctx.strokeStyle = "rgba(200,180,255,.7)"; ctx.lineWidth = s.r;
          ctx.beginPath(); ctx.moveTo(s.x, s.y); ctx.lineTo(s.x + sp * 3, s.y); ctx.stroke(); ctx.restore();
        });
        drawStars(.7);
        earthX = W * .75 + W * .1 * (1 - ep); earthY = H * .18 + H * .05 * (1 - ep); earthR = Math.min(W, H) * (.09 + ep * .12);
        drawEarth(.5 + ep * .5);
        trail.push({ x: rocketX, y: rocketY, life: 1 }); trail.forEach(tp => tp.life -= .02); trail = trail.filter(tp => tp.life > 0);
        trail.forEach(tp => { ctx.save(); ctx.globalAlpha = tp.life * .5; ctx.fillStyle = "rgba(255,140,60,.6)"; ctx.beginPath(); ctx.arc(tp.x, tp.y, 2 * tp.life, 0, Math.PI * 2); ctx.fill(); ctx.restore(); });
        const tx = earthX - 25, ty = earthY + earthR * .3, sx = W * .38, sy = H * .18, cx2 = W * .8, cy2 = H * .55;
        rocketX = lerp(lerp(sx, cx2, ep), lerp(cx2, tx, ep), ep);
        rocketY = lerp(lerp(sy, cy2, ep), lerp(cy2, ty, ep), ep);
        drawRocket(rocketX, rocketY, (Math.atan2(ty - sy, tx - sx) + Math.PI / 2 * (1 - p)) - Math.PI / 4 * p, .8 + Math.sin(frame * .08) * .3);
        setMsg(["🌌 Crossing the asteroid belt…", "⭐ Passing the outer planets…", "🌍 Earth ahead!"][Math.floor(p * 2.99)]);
        if (p >= 1) { phase = 3; phaseTimer = 0; }
      }
      else if (phase === 3) {
        const p = Math.min(phaseTimer / phaseDur[3], 1);
        const bg = ctx.createRadialGradient(W / 2, H / 2, 0, W / 2, H / 2, Math.max(W, H));
        bg.addColorStop(0, "#020015"); bg.addColorStop(1, "#000008");
        ctx.fillStyle = bg; ctx.fillRect(0, 0, W, H);
        drawStars(.5 + p * .5);
        stars2.forEach(s => {
          const sp = s.speed * (1 - easeIn(p)); s.x -= sp; if (s.x < 0) s.x = W;
          ctx.save(); ctx.globalAlpha = .4 * (1 - p); ctx.strokeStyle = "rgba(200,180,255,.5)"; ctx.lineWidth = s.r;
          ctx.beginPath(); ctx.moveTo(s.x, s.y); ctx.lineTo(s.x + sp * 3, s.y); ctx.stroke(); ctx.restore();
        });
        earthR = Math.min(W, H) * (.21 + p * .5); earthX = W * .5; earthY = H * (-.1 + p * .3);
        drawEarth(1);
        shakeX = (Math.random() - .5) * 3 * p; shakeY = (Math.random() - .5) * 3 * p;
        rocketX = lerp(rocketX, W * .5, easeIn(p) * .08); rocketY = lerp(rocketY, H * .55, easeIn(p) * .08);
        drawRocket(rocketX, rocketY, -Math.PI * .1 + p * .1, 1 + p);
        setMsg(p < .5 ? "🌍 Entering orbit…" : "📚 Descending to PageWalker…");
        if (p >= 1) { phase = 4; phaseTimer = 0; }
      }
      else if (phase === 4) {
        const p = Math.min(phaseTimer / phaseDur[4], 1), rp = easeIn(p);
        const bg = ctx.createRadialGradient(W / 2, H / 2, 0, W / 2, H / 2, Math.max(W, H) * (1 - p * .9));
        bg.addColorStop(0, "#1a0a40"); bg.addColorStop(1, "#000010");
        ctx.fillStyle = bg; ctx.fillRect(0, 0, W, H);
        drawStars(1 - p);
        earthR = Math.min(W, H) * (.71 + p * .8); earthX = W * .5; earthY = H * (-.3 + p * .2);
        ctx.save(); ctx.globalAlpha = 1 - p * .8; drawEarth(1); ctx.restore();
        const scale = 1 - rp * .85;
        ctx.save(); ctx.translate(W * .5, H * (.55 - rp * .6)); ctx.scale(scale, scale); ctx.translate(-W * .5, -H * (.55 - rp * .6));
        drawRocket(W * .5, H * (.55 - rp * .6), -Math.PI / 2, 2 * (1 - p));
        ctx.restore();
        if (p > .8) { ctx.fillStyle = `rgba(255,240,200,${(p - .8) / .2})`; ctx.fillRect(0, 0, W, H); }
        msg.style.opacity = String(1 - p);
        hint.style.opacity = "0";
        if (p >= 1) showBook();
      }
    }

    function showBook() {
      bookDone = true;
      canvas.style.transition = "opacity .4s";
      canvas.style.opacity = "0";
      msg.style.opacity = "0";
      bookWrap.style.opacity = "1";
      bookWrap.style.pointerEvents = "all";
      bookWrap.style.background = "radial-gradient(ellipse at center,#1a0a40 0%,#0a0518 60%,#000 100%)";
      hint.style.display = "none";
      setTimeout(() => {
        document.getElementById("pw-cover-left").style.transform = "rotateY(-160deg)";
        document.getElementById("pw-page-inner").style.opacity = "1";
      }, 600);
      // After book opens, reveal real hero
      setTimeout(() => {
        bookWrap.style.transition = "opacity 1s";
        bookWrap.style.opacity = "0";
        canvas.style.opacity = "0";
        setTimeout(() => {
          bookWrap.style.display = "none";
          canvas.style.display = "none";
          hint.style.display = "none";
          if (heroInner) {
            heroInner.style.transition = "opacity 1s";
            heroInner.style.opacity = "1";
          }
        }, 1000);
      }, 4000);
    }

    // Enter button skips straight to site
    setTimeout(() => {
      const btn = document.getElementById("pw-enter-btn");
      if (btn) btn.addEventListener("click", () => {
        bookWrap.style.opacity = "0";
        setTimeout(() => {
          bookWrap.style.display = "none";
          canvas.style.display = "none";
          if (heroInner) { heroInner.style.transition = "opacity .8s"; heroInner.style.opacity = "1"; }
        }, 600);
      });
    }, 500);

    // Skip on click during animation
    canvas.addEventListener("click", () => {
      if (phase < 4) { phase = Math.min(phase + 1, 4); phaseTimer = 0; }
    });

    // Auto-start after short pause
    setTimeout(() => { if (phase === 0) { phase = 1; phaseTimer = 0; } }, 1800);

    loop();
  }

  // Expose globally so pw-webapp.js can call it after renderHome()
  window.initHeroAnimation = initHeroAnimation;
})();
