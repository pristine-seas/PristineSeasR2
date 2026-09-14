/* Pristine Seas colour system — article behaviour.
   Reads window.PS_PALETTES, PS_STATES and PS_INK, which the article emits from
   ps_colors(), so the page can never drift from the package. Colour-vision
   simulation and CIEDE2000 are computed here, in the browser, so the toggles
   are instant. */
(function () {
  const PALETTES = window.PS_PALETTES;
  const STATES   = window.PS_STATES;
  const INK      = window.PS_INK;

  // Colour math ---------------------------------------------------------------
  const hex2rgb = h => [0, 1, 2].map(k => parseInt(h.substr(1 + k * 2, 2), 16) / 255);
  const rgb2hex = c => "#" + c.map(v => Math.round(Math.min(1, Math.max(0, v)) * 255)
                                          .toString(16).padStart(2, "0")).join("").toUpperCase();
  const s2l = c => c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
  const l2s = c => { c = Math.min(1, Math.max(0, c)); return c <= 0.0031308 ? c * 12.92 : 1.055 * Math.pow(c, 1 / 2.4) - 0.055; };
  const lum = c => { const l = c.map(s2l); return 0.2126 * l[0] + 0.7152 * l[1] + 0.0722 * l[2]; };

  function rgb2lab(c) {
    const l = c.map(s2l);
    const X = (0.4124564 * l[0] + 0.3575761 * l[1] + 0.1804375 * l[2]) / 0.95047;
    const Y = (0.2126729 * l[0] + 0.7151522 * l[1] + 0.0721750 * l[2]);
    const Z = (0.0193339 * l[0] + 0.1191920 * l[1] + 0.9503041 * l[2]) / 1.08883;
    const f = t => t > Math.pow(6 / 29, 3) ? Math.cbrt(t) : t / (3 * Math.pow(6 / 29, 2)) + 4 / 29;
    const fx = f(X), fy = f(Y), fz = f(Z);
    return [116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)];
  }

  function ciede2000(a, b) {
    const rad = Math.PI / 180, deg = 180 / Math.PI;
    const [L1, a1, b1] = a, [L2, a2, b2] = b;
    const C1 = Math.hypot(a1, b1), C2 = Math.hypot(a2, b2), Cb = (C1 + C2) / 2;
    const G = 0.5 * (1 - Math.sqrt(Math.pow(Cb, 7) / (Math.pow(Cb, 7) + Math.pow(25, 7))));
    const ap1 = (1 + G) * a1, ap2 = (1 + G) * a2;
    const Cp1 = Math.hypot(ap1, b1), Cp2 = Math.hypot(ap2, b2);
    const hp1 = (Math.atan2(b1, ap1) * deg + 360) % 360, hp2 = (Math.atan2(b2, ap2) * deg + 360) % 360;
    const dL = L2 - L1, dC = Cp2 - Cp1;
    let dh = 0;
    if (Cp1 * Cp2 !== 0) { dh = hp2 - hp1; if (dh > 180) dh -= 360; else if (dh < -180) dh += 360; }
    const dH = 2 * Math.sqrt(Cp1 * Cp2) * Math.sin(dh * rad / 2);
    const Lb = (L1 + L2) / 2, Cbp = (Cp1 + Cp2) / 2;
    let hb;
    if (Cp1 * Cp2 === 0) { hb = hp1 + hp2; }
    else { const s = hp1 + hp2, d = Math.abs(hp1 - hp2);
           hb = d <= 180 ? s / 2 : (s < 360 ? (s + 360) / 2 : (s - 360) / 2); }
    const T = 1 - 0.17 * Math.cos((hb - 30) * rad) + 0.24 * Math.cos(2 * hb * rad)
              + 0.32 * Math.cos((3 * hb + 6) * rad) - 0.20 * Math.cos((4 * hb - 63) * rad);
    const dTh = 30 * Math.exp(-Math.pow((hb - 275) / 25, 2));
    const Rc = 2 * Math.sqrt(Math.pow(Cbp, 7) / (Math.pow(Cbp, 7) + Math.pow(25, 7)));
    const Sl = 1 + (0.015 * Math.pow(Lb - 50, 2)) / Math.sqrt(20 + Math.pow(Lb - 50, 2));
    const Sc = 1 + 0.045 * Cbp, Sh = 1 + 0.015 * Cbp * T;
    const Rt = -Math.sin(2 * dTh * rad) * Rc;
    return Math.sqrt(Math.pow(dL / Sl, 2) + Math.pow(dC / Sc, 2) + Math.pow(dH / Sh, 2) + Rt * (dC / Sc) * (dH / Sh));
  }

  // Machado, Oliveira & Fernandes (2009) severity-1 matrices, in linear RGB
  const CVD = {
    protan: [[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]],
    deutan: [[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]],
    tritan: [[1.255528, -0.076749, -0.178779], [-0.078411, 0.930809, 0.147602], [0.004733, 0.691367, 0.303900]]
  };
  const MODES = ["normal", "deutan", "protan", "tritan", "grey"];
  const MODE_LABEL = { normal: "normal vision", deutan: "deuteranopia", protan: "protanopia",
                       tritan: "tritanopia", grey: "greyscale" };

  function simulate(hex, mode) {
    const c = hex2rgb(hex);
    if (mode === "normal") return c;
    if (mode === "grey") { const g = l2s(lum(c)); return [g, g, g]; }
    const M = CVD[mode], l = c.map(s2l);
    return M.map(r => l2s(r[0] * l[0] + r[1] * l[1] + r[2] * l[2]));
  }
  const simHex = (hex, mode) => rgb2hex(simulate(hex, mode));
  const simLab = (hex, mode) => rgb2lab(simulate(hex, mode).map(v => Math.min(1, Math.max(0, v))));

  // State ---------------------------------------------------------------------
  let mode = "normal";
  let bg = "light";
  let current = PALETTES[0].id;

  const $  = s => document.querySelector(s);
  const $$ = s => Array.from(document.querySelectorAll(s));
  const esc = s => String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;");
  const DE = "ΔE₀₀";

  // Palettes ------------------------------------------------------------------
  function keysHTML(p, hexes, cls) {
    return `<div class="minileg ${cls || ""}">` + p.colors.map((c, i) =>
      `<span><i style="background:${hexes[i]}"></i>${esc(c.role)} <em>${hexes[i]}</em></span>`
    ).join("") + "</div>";
  }

  function statesHTML(p, hexes) {
    const rows = STATES[p.id].map(st =>
      `<div class="state"><div class="nm">${esc(st.name)}</div><div class="sbar">` +
      st.share.map((v, i) => `<span style="flex:${v};background:${hexes[i]}"></span>`).join("") +
      `</div></div>`).join("");
    return rows + keysHTML(p, hexes, "states") +
      `<p class="statecap">Illustrative compositions</p>`;
  }

  function renderPalettes() {
    $$(".ps-pal").forEach(el => {
      const p = PALETTES.find(x => x.id === el.dataset.pal);
      if (!p) return;
      const hexes = p.colors.map(c => simHex(c.hex, mode));
      const labs  = p.colors.map(c => simLab(c.hex, mode));
      let pmin = Infinity;
      for (let i = 1; i < labs.length; i++) for (let j = 0; j < i; j++)
        pmin = Math.min(pmin, ciede2000(labs[i], labs[j]));
      let body;
      if (STATES[p.id]) {
        body = statesHTML(p, hexes);
      } else {
        body = `<div class="bar">${hexes.map(h => `<div style="background:${h}"></div>`).join("")}</div>` +
          (p.colors.length > 6 ? keysHTML(p, hexes)
            : `<div class="legend">` + p.colors.map((c, i) =>
                `<div class="lg"><div class="cls">${esc(c.role)}</div><div class="pt">${hexes[i]}</div></div>`
              ).join("") + `</div>`);
      }
      el.innerHTML = `<p class="pmin">Closest pair ${DE} ${pmin.toFixed(1)} under ${MODE_LABEL[mode]}</p>` + body;
    });
  }

  // Marker demo ---------------------------------------------------------------
  const MARK = {
    circle:  `<circle cx="0" cy="0" r="8"/>`,
    square:  `<rect x="-8" y="-8" width="16" height="16"/>`,
    diamond: `<path d="M0 -9 L9 0 L0 9 L-9 0 Z"/>`
  };
  function markerSVG(paper, ink) {
    const ex = PALETTES.find(p => p.id === "exposure").colors;
    const pick = k => simHex(ex.find(c => c.key === k).hex, mode);
    const fills = [pick("sheltered"), pick("channel"), pick("exposed")];
    const shapes = ["circle", "square", "diamond"];
    let g = `<rect x="0" y="0" width="268" height="44" rx="6" fill="${paper}"/>`;
    shapes.forEach((s, i) => {
      g += `<g transform="translate(${30 + i * 42},22)" fill="${fills[i]}" stroke="${ink}" stroke-width="1">${MARK[s]}</g>`;
    });
    shapes.forEach((s, i) => {
      const x = 156 + i * 42;
      g += `<g transform="translate(${x},22)" fill="none" stroke="${paper}" stroke-width="3.4">${MARK[s]}</g>` +
           `<g transform="translate(${x},22)" fill="none" stroke="${fills[i]}" stroke-width="1.6">${MARK[s]}</g>`;
    });
    return `<svg viewBox="0 0 268 44" class="mkdemo" role="img" aria-label="Marker treatment">${g}</svg>`;
  }
  function renderMarkers() {
    const el = $("#ps-markers");
    if (!el) return;
    el.innerHTML = markerSVG(INK.chart.canvas, INK.chart.title) +
                   markerSVG(INK.map.panel, INK.map.title);
  }

  // Distinctiveness -----------------------------------------------------------
  const STOPS = [[0.00, [214, 140, 116]], [0.25, [238, 201, 155]], [0.50, [221, 215, 166]],
                 [0.75, [168, 198, 162]], [1.00, [108, 165, 155]]];
  let D_MIN = 8, D_MAX = 46;
  function ramp(t) {
    t = Math.min(1, Math.max(0, t));
    for (let i = 0; i < STOPS.length - 1; i++) {
      const [p0, c0] = STOPS[i], [p1, c1] = STOPS[i + 1];
      if (t <= p1) { const f = (t - p0) / (p1 - p0);
        return "rgb(" + c0.map((v, k) => Math.round(v + (c1[k] - v) * f)).join(",") + ")"; }
    }
    return "rgb(" + STOPS[STOPS.length - 1][1].join(",") + ")";
  }
  const scaleOf = d => ramp((d - D_MIN) / (D_MAX - D_MIN));

  function setDomain(pal) {
    let lo = Infinity, hi = 0;
    for (const m of MODES) {
      const labs = pal.colors.map(c => simLab(c.hex, m));
      for (let i = 1; i < labs.length; i++) for (let j = 0; j < i; j++) {
        const d = ciede2000(labs[i], labs[j]);
        if (d < lo) lo = d;
        if (d > hi) hi = d;
      }
    }
    D_MIN = Math.floor(lo); D_MAX = Math.ceil(hi);
    $("#ps-srange").textContent = `${DE} ${D_MIN} to ${D_MAX} across vision modes`;
  }

  function renderMatrix() {
    const mx = $("#ps-mx");
    if (!mx) return;
    const pal = PALETTES.find(p => p.id === current);
    const cs = pal.colors, n = cs.length;
    setDomain(pal);
    const hexes = cs.map(c => simHex(c.hex, mode));
    const labs  = cs.map(c => simLab(c.hex, mode));
    const D = labs.map(x => labs.map(y => ciede2000(x, y)));

    const wide = n > 6;
    const cw = wide ? 64 : 120, cfs = wide ? 11.5 : 12.5;
    const ch = wide ? 30 : 40, vfs = wide ? 12 : 13;
    let html = `<tr><th class="corner">${DE}</th>` +
      cs.map((c, i) => `<th class="col" style="width:${cw}px;font-size:${cfs}px">` +
        `<div class="cbar" style="background:${hexes[i]}"></div>${esc(c.short)}</th>`).join("") + "</tr>";
    for (let i = 0; i < n; i++) {
      html += `<tr><th class="row"><span class="rbar" style="background:${hexes[i]}"></span>${esc(cs[i].role)}</th>`;
      for (let j = 0; j < n; j++) {
        const st = `height:${ch}px;font-size:${vfs}px;`;
        if (j > i) html += `<td></td>`;
        else if (j === i) html += `<td><div class="cell diag" style="${st}">—</div></td>`;
        else html += `<td><div class="cell" style="${st}background:${scaleOf(D[i][j])}">${D[i][j].toFixed(1)}</div></td>`;
      }
      html += "</tr>";
    }
    mx.innerHTML = html;

    const pairs = [];
    for (let i = 1; i < n; i++) for (let j = 0; j < i; j++)
      pairs.push({ a: cs[i].role, b: cs[j].role, d: D[i][j], heavy: cs[i].heavy && cs[j].heavy });
    pairs.sort((x, y) => x.d - y.d);
    const rows = [{ p: pairs[0], tag: "closest" }];
    const work = pairs.filter(q => q.heavy)[0];
    if (work && work !== pairs[0]) rows.push({ p: work, tag: "most used" });

    $("#ps-pcap").textContent = `Within palette, under ${MODE_LABEL[mode]}`;
    $("#ps-pairlist").innerHTML = rows.map(r =>
      `<li><span class="nm">${esc(r.p.a)} ↔ ${esc(r.p.b)}</span>` +
      `<span class="dv">${DE} ${r.p.d.toFixed(1)}</span><span class="tag">${r.tag}</span></li>`).join("");

    const XT = 15, cross = [];
    for (const other of PALETTES) {
      if (other.id === pal.id) continue;
      for (const a of cs) for (const b of other.colors) {
        const d = ciede2000(simLab(a.hex, mode), simLab(b.hex, mode));
        if (d < XT) cross.push({ a: a.role, b: b.role, d, from: other.title });
      }
    }
    cross.sort((x, y) => x.d - y.d);
    const cb = $("#ps-crossblock");
    if (cross.length) {
      cb.style.display = "block";
      $("#ps-ccap").textContent = `Across palettes, under ${MODE_LABEL[mode]}, below ${DE} ${XT}`;
      $("#ps-crosslist").innerHTML = cross.slice(0, 4).map(q =>
        `<li><span class="nm">${esc(q.a)} ↔ ${esc(q.b)}</span>` +
        `<span class="dv">${DE} ${q.d.toFixed(1)}</span><span class="tag">${esc(q.from)}</span></li>`).join("");
    } else {
      cb.style.display = "none";
    }
  }

  // Controls ------------------------------------------------------------------
  function press(group, btn) {
    $$(`${group} button`).forEach(b => b.setAttribute("aria-pressed", String(b === btn)));
  }
  function applyBg() {
    $$(".ps-panel").forEach(el => el.dataset.bg = bg);
  }
  function render() { renderPalettes(); renderMarkers(); renderMatrix(); }

  $$("#ps-vision button").forEach(btn => btn.addEventListener("click", () => {
    mode = btn.dataset.mode; press("#ps-vision", btn); render();
  }));
  $$("#ps-bg button").forEach(btn => btn.addEventListener("click", () => {
    bg = btn.dataset.bg; press("#ps-bg", btn); applyBg();
  }));

  const palctl = $("#ps-palctl");
  if (palctl) {
    palctl.innerHTML = PALETTES.map(p =>
      `<button type="button" data-pal="${p.id}" aria-pressed="${p.id === current}">${p.num}. ${esc(p.title)}</button>`
    ).join("");
    $$("#ps-palctl button").forEach(btn => btn.addEventListener("click", () => {
      current = btn.dataset.pal; press("#ps-palctl", btn); renderMatrix();
    }));
    $("#ps-grad").style.background = "linear-gradient(90deg," +
      STOPS.map(s => ramp(s[0]) + " " + (s[0] * 100) + "%").join(",") + ")";
  }

  applyBg();
  render();
})();
