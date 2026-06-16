// pw-hero-animation.js — cinematic book-opening hero (Kim version)

(function () {
  "use strict";

  function initHeroAnimation() {
    const hero = document.querySelector(".hero");
    if (!hero || hero.dataset.pwHeroInit) return;
    hero.dataset.pwHeroInit = "1";

    hero.style.position = "relative";
    hero.style.overflow = "hidden";
    hero.style.minHeight = "100vh";

    const heroInner = hero.querySelector(".hero-inner");
    if (heroInner) heroInner.style.opacity = "0";

    const canvas = document.createElement("canvas");
    canvas.id = "pw-hero-canvas";
    canvas.style.cssText = "position:absolute;top:0;left:0;width:100%;height:100%;z-index:2;";
    hero.prepend(canvas);

    const ui = document.createElement("div");
    ui.id = "pw-hero-ui";
    ui.style.cssText =
      "position:absolute;top:0;left:0;width:100%;height:100%;z-index:3;" +
      "pointer-events:none;display:flex;flex-direction:column;align-items:center;" +
      "justify-content:flex-end;padding-bottom:11vh;";
    ui.innerHTML = `
      <div id="pw-tagline" style="opacity:0;transform:translateY(16px);transition:opacity 1.4s ease,transform 1.4s ease;text-align:center;font-family:Georgia,serif;">
        <h1 style="font-size:clamp(1.7rem,5vw,3.2rem);color:#fdf6e3;font-weight:400;letter-spacing:.05em;line-height:1.2;margin:0;">
          Your next world<br>is <em style="color:#ffb347;font-style:normal;">waiting.</em>
        </h1>
        <div id="pw-tline" style="width:0;height:1px;background:linear-gradient(to right,transparent,#ffb347,transparent);margin:.8rem auto;transition:width 1.6s ease .3s;"></div>
        <p style="font-size:clamp(.8rem,2vw,1rem);color:rgba(253,246,227,.45);margin-top:.6rem;letter-spacing:.14em;font-style:italic;">
          PageWalker — where every page is a universe
        </p>
      </div>
      <div id="pw-cta" style="opacity:0;transition:opacity 1s ease;margin-top:1.4rem;pointer-events:all;">
        <button type="button" id="pw-enter-btn" style="background:transparent;border:1px solid rgba(255,179,71,.5);color:#fdf6e3;padding:12px 30px;border-radius:999px;font-size:13px;letter-spacing:.12em;cursor:pointer;font-family:Georgia,serif;">
          Enter PageWalker →
        </button>
      </div>`;
    hero.appendChild(ui);

    const skip = document.createElement("div");
    skip.id = "pw-hero-skip";
    skip.textContent = "skip →";
    skip.style.cssText =
      "position:absolute;top:1.2rem;right:1.4rem;z-index:4;color:rgba(255,255,255,.22);" +
      "font-size:11px;letter-spacing:.1em;cursor:pointer;font-family:Georgia,serif;";
    hero.appendChild(skip);

    const ctx = canvas.getContext("2d");
    let W, H, done = false;
    function resize() {
      W = canvas.width = canvas.offsetWidth;
      H = canvas.height = canvas.offsetHeight;
    }
    resize();
    window.addEventListener("resize", resize);

    let t = 0, frame = 0, phase = 0, phaseT = 0, revealed = false;
    let bookOpenAngle = 0, bookGlow = 0, crackAlpha = 0, bookScale = 0;
    let pagesSpawned = false, runesSpawned = false;

    const bgStars = [];
    for (let i = 0; i < 380; i++) {
      bgStars.push({
        x: Math.random(), y: Math.random(),
        r: Math.random() * 1.3 + 0.2, tw: Math.random() * Math.PI * 2, b: Math.random(),
      });
    }

    const spills = [];
    function spawnSpill(cx, cy, n, burst) {
      for (let i = 0; i < n; i++) {
        const a = Math.random() * Math.PI * 2;
        const spd = burst ? Math.random() * 7 + 2 : Math.random() * 2 + 0.4;
        spills.push({
          x: cx, y: cy,
          vx: Math.cos(a) * spd, vy: Math.sin(a) * spd - (burst ? Math.random() * 2 : 0),
          r: Math.random() * (burst ? 4 : 2) + 0.6, life: 1,
          decay: Math.random() * 0.007 + 0.003,
          col: Math.random() < 0.6
            ? `hsl(${38 + Math.random() * 28},100%,${74 + Math.random() * 20}%)`
            : `hsl(${200 + Math.random() * 70},75%,${68 + Math.random() * 22}%)`,
          tw: Math.random() * Math.PI * 2, star: Math.random() < 0.18,
        });
      }
    }

    const constellations = [];
    function buildConst(cx, cy) {
      const pts = [];
      for (let i = 0; i < Math.floor(Math.random() * 4) + 4; i++) {
        const a = Math.random() * Math.PI * 2;
        const d = Math.random() * 90 + 25;
        pts.push({ x: cx + Math.cos(a) * d, y: cy + Math.sin(a) * d, a: 0 });
      }
      const lines = [];
      for (let i = 0; i < pts.length - 1; i++) lines.push([i, i + 1]);
      constellations.push({ pts, lines, alpha: 0 });
    }

    const RUNES = ["ᚠ", "ᚢ", "ᚦ", "ᚨ", "ᚱ", "✦", "⟡", "◈", "∞", "⋆", "✧", "⌖"];
    const runes = [];
    function spawnRunes(cx, cy) {
      for (let i = 0; i < 14; i++) {
        const a = (i / 14) * Math.PI * 2;
        const d = Math.random() * 90 + 50;
        runes.push({
          x: cx + Math.cos(a) * d, y: cy + Math.sin(a) * d,
          char: RUNES[Math.floor(Math.random() * RUNES.length)],
          alpha: 0, maxA: Math.random() * 0.5 + 0.15,
          size: Math.random() * 13 + 9, oa: a, od: d, os: (Math.random() - 0.5) * 0.007,
        });
      }
    }

    const pages = [];
    function spawnPages(cx, cy) {
      for (let i = 0; i < 20; i++) {
        const a = -Math.PI / 2 + (Math.random() - 0.5) * Math.PI * 0.85;
        pages.push({
          x: cx, y: cy,
          vx: Math.cos(a) * (Math.random() * 3 + 1),
          vy: Math.sin(a) * (Math.random() * 4 + 2) - 1.5,
          rot: Math.random() * Math.PI * 2, rv: (Math.random() - 0.5) * 0.14,
          w: Math.random() * 26 + 12, h: Math.random() * 18 + 8,
          life: 1, decay: Math.random() * 0.005 + 0.003,
        });
      }
    }

    const cracks = [];
    for (let i = 0; i < 9; i++) {
      const a = Math.random() * Math.PI * 2;
      const len = Math.random() * 0.28 + 0.06;
      const sx = (Math.random() - 0.5) * 0.5;
      const sy = (Math.random() - 0.5) * 0.5;
      cracks.push({ sx, sy, ex: sx + Math.cos(a) * len, ey: sy + Math.sin(a) * len, a: 0 });
    }

    function getBook() {
      const bw = Math.min(W * 0.3, 190);
      return { x: W / 2, y: H * 0.44, w: bw, h: bw * 1.38 };
    }

    function drawLightRay(cx, cy, angle, len, w, alpha) {
      ctx.save();
      ctx.globalAlpha = alpha;
      const g = ctx.createLinearGradient(cx, cy, cx + Math.cos(angle) * len, cy + Math.sin(angle) * len);
      g.addColorStop(0, "rgba(255,215,100,.8)");
      g.addColorStop(0.5, "rgba(255,170,60,.3)");
      g.addColorStop(1, "rgba(255,140,40,0)");
      ctx.strokeStyle = g;
      ctx.lineWidth = w;
      ctx.lineCap = "round";
      ctx.beginPath();
      ctx.moveTo(cx, cy);
      ctx.lineTo(cx + Math.cos(angle) * len, cy + Math.sin(angle) * len);
      ctx.stroke();
      ctx.restore();
    }

    function drawBook(bk, openA, glow, crA) {
      const { x, y, w, h } = bk;
      const half = w / 2;

      if (glow > 0) {
        const g = ctx.createRadialGradient(x, y, 0, x, y, w * 2);
        g.addColorStop(0, `rgba(255,195,70,${glow * 0.32})`);
        g.addColorStop(0.45, `rgba(160,80,255,${glow * 0.1})`);
        g.addColorStop(1, "rgba(0,0,0,0)");
        ctx.fillStyle = g;
        ctx.beginPath();
        ctx.arc(x, y, w * 2, 0, Math.PI * 2);
        ctx.fill();
      }

      if (openA > 0.06) {
        const ba = Math.min(openA / (Math.PI * 0.5), 1) * glow;
        for (let i = 0; i < 7; i++) {
          drawLightRay(x, y - h * 0.08, -Math.PI / 2 + (Math.random() - 0.5) * 0.7, H * 0.75, Math.random() * 14 + 4, ba * (0.25 + Math.random() * 0.4));
        }
      }

      const rg = ctx.createLinearGradient(x, y - h / 2, x + half, y + h / 2);
      rg.addColorStop(0, "#180830");
      rg.addColorStop(0.5, "#2a1055");
      rg.addColorStop(1, "#180830");
      ctx.fillStyle = rg;
      ctx.beginPath();
      if (ctx.roundRect) ctx.roundRect(x, y - h / 2, half, h, 4);
      else ctx.rect(x, y - h / 2, half, h);
      ctx.fill();

      if (openA > 0) {
        const ig = ctx.createRadialGradient(x + 5, y, 0, x + 5, y, h * 0.55);
        ig.addColorStop(0, `rgba(255,210,110,${Math.min(openA * 2.2, 1) * 0.85})`);
        ig.addColorStop(0.45, `rgba(180,100,255,${Math.min(openA * 1.5, 1) * 0.25})`);
        ig.addColorStop(1, "rgba(0,0,0,0)");
        ctx.fillStyle = ig;
        ctx.beginPath();
        if (ctx.roundRect) ctx.roundRect(x, y - h / 2, half, h, 4);
        else ctx.rect(x, y - h / 2, half, h);
        ctx.fill();
      }

      ctx.save();
      ctx.translate(x, y);
      const skewX = Math.cos(openA) * half;
      const cg = ctx.createLinearGradient(-half, 0, 0, 0);
      cg.addColorStop(0, "#0c0418");
      cg.addColorStop(0.6, "#180830");
      cg.addColorStop(1, "#2a1055");
      ctx.fillStyle = cg;
      ctx.beginPath();
      ctx.moveTo(0, -h / 2);
      ctx.lineTo(-skewX, -h / 2);
      ctx.lineTo(-skewX, h / 2);
      ctx.lineTo(0, h / 2);
      ctx.closePath();
      ctx.fill();

      if (openA < 1.3) {
        ctx.save();
        ctx.globalAlpha = (1 - openA / 1.4) * 0.65;
        ctx.fillStyle = "#ffb347";
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        ctx.font = `${w * 0.072}px Georgia`;
        ctx.fillText("PAGE", -skewX / 2, -h * 0.1);
        ctx.fillText("WALKER", -skewX / 2, h * 0.06);
        ctx.strokeStyle = "rgba(255,179,71,.28)";
        ctx.lineWidth = 0.8;
        ctx.strokeRect(-skewX * 0.84, -h * 0.41, skewX * 0.68, h * 0.82);
        ctx.restore();
      }

      if (crA > 0) {
        cracks.forEach((cr) => {
          ctx.save();
          ctx.globalAlpha = crA * cr.a * 0.85;
          ctx.strokeStyle = "rgba(255,215,100,.95)";
          ctx.lineWidth = 1.4;
          ctx.shadowColor = "rgba(255,200,80,1)";
          ctx.shadowBlur = 10;
          ctx.beginPath();
          ctx.moveTo(-skewX / 2 + cr.sx * skewX, -h / 2 + (0.5 + cr.sy) * h);
          ctx.lineTo(-skewX / 2 + cr.ex * skewX, -h / 2 + (0.5 + cr.ey) * h);
          ctx.stroke();
          ctx.restore();
        });
      }

      ctx.fillStyle = "#080210";
      ctx.fillRect(-3, -h / 2, 6, h);
      ctx.strokeStyle = "rgba(255,179,71,.35)";
      ctx.lineWidth = 0.5;
      ctx.strokeRect(-3, -h / 2, 6, h);
      ctx.restore();

      ctx.strokeStyle = "rgba(255,179,71,.2)";
      ctx.lineWidth = 0.8;
      ctx.beginPath();
      if (ctx.roundRect) ctx.roundRect(x - half, y - h / 2, w, h, 4);
      else ctx.rect(x - half, y - h / 2, w, h);
      ctx.stroke();
    }

    let constTimer = 0;

    function finishHero() {
      if (done) return;
      done = true;
      canvas.style.transition = "opacity .8s";
      ui.style.transition = "opacity .8s";
      skip.style.transition = "opacity .4s";
      canvas.style.opacity = "0";
      ui.style.opacity = "0";
      skip.style.opacity = "0";
      setTimeout(() => {
        canvas.style.display = "none";
        ui.style.display = "none";
        skip.style.display = "none";
        hero.style.minHeight = "";
        if (heroInner) {
          heroInner.style.transition = "opacity 1s";
          heroInner.style.opacity = "1";
        }
      }, 800);
    }

    function revealTagline() {
      const el = document.getElementById("pw-tagline");
      if (!el) return;
      el.style.opacity = "1";
      el.style.transform = "translateY(0)";
      const tline = document.getElementById("pw-tline");
      if (tline) tline.style.width = "210px";
      setTimeout(() => {
        const cta = document.getElementById("pw-cta");
        if (cta) cta.style.opacity = "1";
      }, 1300);
      skip.style.display = "none";
    }

    function skipAnim() {
      phase = 4;
      phaseT = 2;
      pagesSpawned = true;
      runesSpawned = true;
      bookOpenAngle = Math.PI * 0.56;
      bookGlow = 0.8;
      crackAlpha = 1;
      cracks.forEach((cr) => { cr.a = 1; });
      for (let i = 0; i < 5; i++) buildConst(W / 2 + (Math.random() - 0.5) * W * 0.7, H * 0.44 + (Math.random() - 0.5) * H * 0.5);
      spawnSpill(W / 2, H * 0.44, 130, true);
      if (!revealed) {
        revealed = true;
        revealTagline();
      }
    }

    function loop() {
      if (done) return;
      requestAnimationFrame(loop);
      t += 0.016;
      frame++;
      const bk = getBook();
      ctx.clearRect(0, 0, W, H);

      const bg = ctx.createRadialGradient(W / 2, H / 2, 0, W / 2, H / 2, Math.max(W, H) * 0.85);
      bg.addColorStop(0, "#070510");
      bg.addColorStop(0.6, "#030208");
      bg.addColorStop(1, "#000");
      ctx.fillStyle = bg;
      ctx.fillRect(0, 0, W, H);

      [[W * 0.28, H * 0.3, W * 0.5, "rgba(70,15,110,.07)"], [W * 0.72, H * 0.65, W * 0.4, "rgba(15,50,110,.055)"]].forEach(([nx, ny, nr, nc]) => {
        const n = ctx.createRadialGradient(nx, ny, 0, nx, ny, nr);
        n.addColorStop(0, nc);
        n.addColorStop(1, "rgba(0,0,0,0)");
        ctx.fillStyle = n;
        ctx.fillRect(0, 0, W, H);
      });

      bgStars.forEach((s) => {
        const tw = Math.sin(s.tw + t * (s.b * 0.4 + 0.2)) * 0.4 + 0.6;
        ctx.save();
        ctx.globalAlpha = s.b * 0.5 * tw;
        ctx.fillStyle = "#fff";
        ctx.beginPath();
        ctx.arc(s.x * W, s.y * H, s.r, 0, Math.PI * 2);
        ctx.fill();
        ctx.restore();
      });

      phaseT += 0.016;

      if (phase === 0) {
        bookScale = Math.min(phaseT / 1.1, 1);
        bookGlow = bookScale * 0.25;
        ctx.save();
        ctx.translate(bk.x, bk.y);
        ctx.scale(bookScale, bookScale);
        ctx.translate(-bk.x, -bk.y);
        drawBook(bk, 0, bookGlow, 0);
        ctx.restore();
        if (!runesSpawned && bookScale > 0.45) {
          runesSpawned = true;
          spawnRunes(bk.x, bk.y);
        }
        if (phaseT > 1.7) { phase = 1; phaseT = 0; }
      } else if (phase === 1) {
        bk.y += Math.sin(t * 1.15) * 5;
        bookGlow = 0.28 + Math.sin(t * 1.7) * 0.08;
        crackAlpha = Math.min(phaseT / 1.4, 1);
        cracks.forEach((cr, i) => { cr.a = Math.min((phaseT - 0.08 * i) / 0.7, 1); });
        drawBook(bk, 0, bookGlow, crackAlpha);
        if (phaseT > 2) { phase = 2; phaseT = 0; }
      } else if (phase === 2) {
        bk.y += Math.sin(t * 1.15) * 4;
        bookGlow = 0.28 + phaseT * 0.55;
        crackAlpha = 1;
        drawBook(bk, 0, Math.min(bookGlow, 1.3), crackAlpha);
        if (phaseT > 0.7) {
          const burst = ctx.createRadialGradient(bk.x, bk.y, 0, bk.x, bk.y, bk.w * 2.2);
          burst.addColorStop(0, `rgba(255,215,100,${Math.min((phaseT - 0.7) * 0.5, 0.38)})`);
          burst.addColorStop(1, "rgba(0,0,0,0)");
          ctx.fillStyle = burst;
          ctx.fillRect(0, 0, W, H);
        }
        if (phaseT > 1.5) { phase = 3; phaseT = 0; }
      } else if (phase >= 3) {
        bk.y += Math.sin(t * 1.1) * 3;
        if (phase === 3) {
          bookOpenAngle = Math.min(phaseT / 1.1, 1) * Math.PI * 0.56;
          bookGlow = 0.85 + Math.sin(t * 2) * 0.12;
          if (!pagesSpawned && bookOpenAngle > 0.28) {
            pagesSpawned = true;
            spawnPages(bk.x, bk.y);
            spawnSpill(bk.x, bk.y, 90, true);
          }
          if (phaseT > 1.3 && phaseT < 3.2) {
            if (frame % 3 === 0) spawnSpill(bk.x, bk.y - bk.h * 0.12, 5, false);
            constTimer++;
            if (constTimer % 38 === 0) buildConst(bk.x + (Math.random() - 0.5) * W * 0.62, bk.y + (Math.random() - 0.5) * H * 0.48);
          }
          if (phaseT > 2.7) { phase = 4; phaseT = 0; }
        } else {
          bookGlow = 0.7 + Math.sin(t * 2) * 0.1;
          if (frame % 2 === 0) spawnSpill(bk.x, bk.y - bk.h * 0.14, 5, false);
          if (frame % 48 === 0) buildConst(bk.x + (Math.random() - 0.5) * W * 0.7, bk.y + (Math.random() - 0.5) * H * 0.55);
          if (phaseT > 1.8 && !revealed) {
            revealed = true;
            revealTagline();
          }
        }
        drawBook(bk, bookOpenAngle, Math.min(bookGlow, 1.1), 1);
      }

      pages.forEach((pp) => {
        pp.x += pp.vx;
        pp.y += pp.vy;
        pp.vy += 0.035;
        pp.rot += pp.rv;
        pp.life -= pp.decay;
        if (pp.life <= 0) return;
        ctx.save();
        ctx.globalAlpha = pp.life * 0.65;
        ctx.translate(pp.x, pp.y);
        ctx.rotate(pp.rot);
        ctx.fillStyle = `rgba(240,228,200,${pp.life * 0.55})`;
        ctx.fillRect(-pp.w / 2, -pp.h / 2, pp.w, pp.h);
        ctx.strokeStyle = `rgba(100,75,155,${pp.life * 0.35})`;
        ctx.lineWidth = 0.5;
        for (let l = 1; l < 4; l++) {
          ctx.beginPath();
          ctx.moveTo(-pp.w * 0.38, -pp.h / 2 + l * pp.h / 4);
          ctx.lineTo(pp.w * 0.38, -pp.h / 2 + l * pp.h / 4);
          ctx.stroke();
        }
        ctx.restore();
      });

      spills.forEach((sp) => {
        sp.x += sp.vx;
        sp.y += sp.vy;
        sp.vx *= 0.993;
        sp.vy *= 0.993;
        sp.life -= sp.decay;
        sp.tw += 0.08;
        if (sp.life <= 0) return;
        const tw = Math.sin(sp.tw) * 0.3 + 0.7;
        ctx.save();
        ctx.globalAlpha = sp.life * tw;
        ctx.fillStyle = sp.col;
        if (sp.star) {
          ctx.shadowColor = sp.col;
          ctx.shadowBlur = 7;
        }
        ctx.beginPath();
        ctx.arc(sp.x, sp.y, sp.r * (sp.star ? 1.5 : 1), 0, Math.PI * 2);
        ctx.fill();
        ctx.restore();
      });

      constellations.forEach((con) => {
        con.alpha = Math.min(con.alpha + 0.007, 0.55);
        con.pts.forEach((p) => { p.a = Math.min(p.a + 0.014, 1); });
        ctx.save();
        ctx.globalAlpha = con.alpha * 0.45;
        ctx.strokeStyle = "rgba(170,140,255,.4)";
        ctx.lineWidth = 0.5;
        con.lines.forEach((l) => {
          const a = con.pts[l[0]];
          const b = con.pts[l[1]];
          ctx.beginPath();
          ctx.moveTo(a.x, a.y);
          ctx.lineTo(b.x, b.y);
          ctx.stroke();
        });
        con.pts.forEach((p) => {
          ctx.globalAlpha = con.alpha * p.a;
          ctx.fillStyle = "rgba(200,175,255,1)";
          ctx.shadowColor = "rgba(200,175,255,.7)";
          ctx.shadowBlur = 5;
          ctx.beginPath();
          ctx.arc(p.x, p.y, 1.7, 0, Math.PI * 2);
          ctx.fill();
        });
        ctx.restore();
      });

      runes.forEach((rp) => {
        rp.oa += rp.os;
        rp.x = W / 2 + Math.cos(rp.oa) * rp.od;
        rp.y = H * 0.44 + Math.sin(rp.oa) * rp.od * 0.55;
        rp.alpha = Math.min(rp.alpha + 0.009, rp.maxA * (phase >= 3 ? 0.45 : 1));
        ctx.save();
        ctx.globalAlpha = rp.alpha;
        ctx.fillStyle = "rgba(255,179,71,.75)";
        ctx.font = `${rp.size}px Georgia`;
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        ctx.fillText(rp.char, rp.x, rp.y);
        ctx.restore();
      });
    }

    skip.addEventListener("click", finishHero);
    document.getElementById("pw-enter-btn").addEventListener("click", finishHero);

    loop();
  }

  window.initHeroAnimation = initHeroAnimation;
})();
