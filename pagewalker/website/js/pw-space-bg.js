// pw-space-bg.js — site-wide deep-space canvas (stars, constellations, shooting stars, planets)

(function () {
  "use strict";

  if (window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

  const canvas = document.createElement("canvas");
  canvas.id = "pw-space-canvas";
  canvas.setAttribute("aria-hidden", "true");
  document.body.prepend(canvas);

  const ctx = canvas.getContext("2d");
  let W = 0;
  let H = 0;
  let frame = 0;
  let stars = [];
  let constellations = [];
  let planets = [];
  let shooting = [];
  let nextShoot = 120;

  function resize() {
    W = canvas.width = window.innerWidth;
    H = canvas.height = window.innerHeight;
    initScene();
  }

  function initScene() {
    stars = [];
    for (let i = 0; i < 320; i++) {
      stars.push({
        x: Math.random() * W,
        y: Math.random() * H,
        r: Math.random() * 1.4 + 0.25,
        tw: Math.random() * Math.PI * 2,
        sp: Math.random() * 0.02 + 0.008,
        b: Math.random() * 0.5 + 0.35,
      });
    }

    constellations = [];
    for (let g = 0; g < 5; g++) {
      const cx = Math.random() * W;
      const cy = Math.random() * H * 0.85;
      const pts = [];
      const n = 4 + Math.floor(Math.random() * 3);
      for (let i = 0; i < n; i++) {
        const a = (i / n) * Math.PI * 2 + Math.random() * 0.4;
        const d = 28 + Math.random() * 55;
        pts.push({ x: cx + Math.cos(a) * d, y: cy + Math.sin(a) * d });
      }
      const lines = [];
      for (let i = 0; i < pts.length - 1; i++) lines.push([i, i + 1]);
      if (Math.random() > 0.4) lines.push([pts.length - 1, 0]);
      constellations.push({ pts, lines, alpha: 0.12 + Math.random() * 0.18 });
    }

    planets = [
      { x: W * 0.82, y: H * 0.18, r: 38, c1: "rgba(80,120,255,0.14)", c2: "rgba(40,60,180,0.04)", ring: true },
      { x: W * 0.12, y: H * 0.72, r: 52, c1: "rgba(255,107,26,0.1)", c2: "rgba(120,40,10,0.03)", ring: false },
      { x: W * 0.55, y: H * 0.88, r: 24, c1: "rgba(180,100,255,0.09)", c2: "rgba(60,20,100,0.02)", ring: false },
    ];
  }

  function spawnShootingStar() {
    const x = Math.random() * W * 0.7;
    const y = Math.random() * H * 0.35;
    const len = 80 + Math.random() * 120;
    const ang = Math.PI * 0.22 + Math.random() * 0.25;
    shooting.push({ x, y, len, ang, life: 1, spd: 0.018 + Math.random() * 0.012 });
    nextShoot = 90 + Math.floor(Math.random() * 180);
  }

  function drawBackground() {
    const g = ctx.createRadialGradient(W * 0.5, H * 0.35, 0, W * 0.5, H * 0.5, Math.max(W, H) * 0.9);
    g.addColorStop(0, "#0a0618");
    g.addColorStop(0.45, "#060410");
    g.addColorStop(1, "#020108");
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, W, H);

    const neb1 = ctx.createRadialGradient(W * 0.2, H * 0.3, 0, W * 0.2, H * 0.3, W * 0.35);
    neb1.addColorStop(0, "rgba(70,20,120,0.08)");
    neb1.addColorStop(1, "rgba(0,0,0,0)");
    ctx.fillStyle = neb1;
    ctx.fillRect(0, 0, W, H);

    const neb2 = ctx.createRadialGradient(W * 0.78, H * 0.65, 0, W * 0.78, H * 0.65, W * 0.28);
    neb2.addColorStop(0, "rgba(20,60,140,0.06)");
    neb2.addColorStop(1, "rgba(0,0,0,0)");
    ctx.fillStyle = neb2;
    ctx.fillRect(0, 0, W, H);
  }

  function drawPlanets() {
    planets.forEach((p) => {
      const g = ctx.createRadialGradient(p.x - p.r * 0.2, p.y - p.r * 0.2, p.r * 0.1, p.x, p.y, p.r);
      g.addColorStop(0, p.c1);
      g.addColorStop(0.7, p.c2);
      g.addColorStop(1, "rgba(0,0,0,0)");
      ctx.fillStyle = g;
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
      ctx.fill();
      if (p.ring) {
        ctx.save();
        ctx.translate(p.x, p.y);
        ctx.scale(1, 0.28);
        ctx.strokeStyle = "rgba(200,180,255,0.12)";
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(0, 0, p.r * 1.35, 0, Math.PI * 2);
        ctx.stroke();
        ctx.restore();
      }
    });
  }

  function drawConstellations() {
    constellations.forEach((con) => {
      ctx.save();
      ctx.strokeStyle = `rgba(170,150,255,${con.alpha})`;
      ctx.lineWidth = 0.6;
      con.lines.forEach(([a, b]) => {
        const p1 = con.pts[a];
        const p2 = con.pts[b];
        ctx.beginPath();
        ctx.moveTo(p1.x, p1.y);
        ctx.lineTo(p2.x, p2.y);
        ctx.stroke();
      });
      con.pts.forEach((p) => {
        ctx.fillStyle = `rgba(220,200,255,${con.alpha + 0.15})`;
        ctx.beginPath();
        ctx.arc(p.x, p.y, 1.2, 0, Math.PI * 2);
        ctx.fill();
      });
      ctx.restore();
    });
  }

  function drawStars() {
    stars.forEach((s) => {
      const tw = Math.sin(s.tw + frame * s.sp) * 0.35 + 0.65;
      ctx.save();
      ctx.globalAlpha = s.b * tw;
      ctx.fillStyle = "#fff";
      ctx.beginPath();
      ctx.arc(s.x, s.y, s.r, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    });
  }

  function drawShooting() {
    for (let i = shooting.length - 1; i >= 0; i--) {
      const s = shooting[i];
      s.life -= s.spd;
      if (s.life <= 0) {
        shooting.splice(i, 1);
        continue;
      }
      const ex = s.x + Math.cos(s.ang) * s.len * (1 - s.life);
      const ey = s.y + Math.sin(s.ang) * s.len * (1 - s.life);
      const g = ctx.createLinearGradient(s.x, s.y, ex, ey);
      g.addColorStop(0, "rgba(255,255,255,0)");
      g.addColorStop(0.4, `rgba(255,240,200,${s.life * 0.7})`);
      g.addColorStop(1, `rgba(255,180,100,${s.life * 0.35})`);
      ctx.save();
      ctx.strokeStyle = g;
      ctx.lineWidth = 1.5;
      ctx.lineCap = "round";
      ctx.beginPath();
      ctx.moveTo(s.x, s.y);
      ctx.lineTo(ex, ey);
      ctx.stroke();
      ctx.fillStyle = `rgba(255,255,255,${s.life})`;
      ctx.beginPath();
      ctx.arc(ex, ey, 1.5, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    }
  }

  function loop() {
    requestAnimationFrame(loop);
    frame++;
    if (nextShoot <= 0) spawnShootingStar();
    else nextShoot--;
    drawBackground();
    drawPlanets();
    drawConstellations();
    drawStars();
    drawShooting();
  }

  resize();
  window.addEventListener("resize", resize);
  loop();
})();
