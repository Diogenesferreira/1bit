/* Laboratorio de animacao do combo - Ilha Digital (layout Terminal).
 * Linha do tempo deterministica: cada efeito = (inicio, duracao, begin/update/end).
 * Os eventos da logica (ComboLogic, porta do BattleLogic.gd) viram itens da linha do tempo.
 */
function bootLab() {
  const { Logic, ELEM, PRESETS } = window.ComboLogic;
  const IMG = window.LAB_CARD_IMG;
  // mesmas cores de elemento do Main.dc.html (this.UI)
  const UI = { dragon: '#FF5A3D', knight: '#4DA8FF', nature: '#5BD75B', light: '#FFC93C', dark: '#B06BFF', wild: '#CFCFE4', capsule: '#C89A5A' };
  const SLOT_OF_COR = { 0: 'A1', 1: 'A3', 2: 'A5', 3: 'A4', 4: 'A2' };
  const ALLY_BASE = { A1: 45, A2: 30, A3: 55, A4: 30, A5: 30 };
  const colorOf = (cor) => UI[ELEM[cor]];

  // ------------------------------------------------------------------ parametros
  const SCHEMA = [
    ['Seleção', [
      ['liftPx', 'Elevação da carta marcada (px)', 0, 16, 1, 5],
      ['selectMs', 'Marcar / desmarcar (ms)', 40, 400, 10, 120],
      ['dropMs', 'Carta da BAG desce na entrada (ms)', 100, 900, 10, 420],
      ['returnMs', 'Carta volta para a BAG (ms)', 60, 600, 10, 180],
    ]],
    ['Fusão', [
      ['cascadeFlashMs', 'Destaque das cartas da cascata (ms)', 0, 400, 10, 150],
      ['gatherMs', 'Ir ao centro e alinhar (ms)', 80, 900, 10, 280],
      ['lineGap', 'Espaço entre as alinhadas (× largura)', 0.6, 1.5, 0.02, 1.2],
      ['gatherScale', 'Escala no centro', 0.8, 1.6, 0.02, 1.14],
      ['holdMs', 'Pausa alinhadas (ms)', 0, 500, 10, 90],
      ['mergeMs', 'Juntar e fundir (ms)', 100, 1200, 10, 440],
      ['whiteStart', 'Começa a branquear (fração)', 0, 1, 0.05, 0.3],
      ['glowPx', 'Brilho da cor do elemento (px)', 0, 60, 1, 26],
      ['wobbleDeg', 'Vibração ao fundir (graus)', 0, 12, 0.5, 3],
      ['chargeMs', 'Carga antes de explodir (ms)', 0, 600, 10, 150],
      ['shakePx', 'Tremor da carga (px)', 0, 6, 0.25, 1.75],
    ]],
    ['Explosão', [
      ['flashMs', 'Flash branco (ms)', 60, 800, 10, 220],
      ['flashRadius', 'Raio do flash (px)', 20, 260, 5, 95],
      ['ringMs', 'Onda de choque (ms)', 80, 900, 10, 380],
      ['ringRadius', 'Raio final da onda (px)', 40, 320, 5, 150],
      ['ringWidth', 'Espessura da onda (px)', 1, 20, 0.5, 7],
      ['particles', 'Partículas', 0, 160, 2, 56],
      ['pSpeedMin', 'Velocidade mínima (px/s)', 20, 400, 10, 90],
      ['pSpeedMax', 'Velocidade máxima (px/s)', 60, 900, 10, 360],
      ['pLifeMs', 'Vida da partícula (ms)', 150, 1500, 10, 620],
      ['pSize', 'Tamanho da partícula (px)', 1, 8, 0.25, 2.6],
      ['gravity', 'Gravidade (px/s²)', -400, 800, 10, 160],
    ]],
    ['Energia até o personagem', [
      ['energyDelayMs', 'Atraso depois da explosão (ms)', 0, 500, 10, 70],
      ['orbs', 'Orbes por personagem', 1, 10, 1, 4],
      ['orbStaggerMs', 'Intervalo entre orbes (ms)', 0, 200, 5, 55],
      ['energyMs', 'Tempo de viagem (ms)', 150, 1600, 10, 560],
      ['arcPx', 'Curvatura da trajetória (px)', 0, 260, 5, 120],
      ['orbSize', 'Tamanho do orbe (px)', 1, 12, 0.5, 4.5],
      ['trail', 'Rastro (fração do caminho)', 0, 0.6, 0.02, 0.2],
      ['impactParticles', 'Partículas no impacto', 0, 60, 1, 14],
      ['ringTeto', 'Energia para encher o anel', 100, 3000, 50, 900],
      ['auraGlow', 'Aura que fica no personagem (intensidade)', 0, 2, 0.05, 1],
      ['auraMotes', 'Aura: partículas subindo', 0, 24, 1, 9],
    ]],
    ['Cascata e mão', [
      ['betweenTriosMs', 'Pausa entre trios da cascata (ms)', 0, 800, 10, 120],
      ['chainLabelMs', 'Rótulo CADEIA (ms)', 0, 1500, 20, 700],
      ['rainStaggerMs', 'Chuva de cartas: intervalo (ms)', 0, 200, 5, 45],
      ['rainMs', 'Chuva de cartas: queda (ms)', 80, 700, 10, 220],
      ['pileMs', 'Juntar para redistribuir (ms)', 80, 800, 10, 240],
      ['dealMs', 'Distribuir cada carta (ms)', 80, 800, 10, 220],
      ['dealStaggerMs', 'Distribuir: intervalo (ms)', 0, 120, 2, 26],
    ]],
    ['Dano no inimigo', [
      ['preFinalMs', 'Pausa antes do ataque final (ms)', 0, 900, 10, 180],
      ['strikeMs', 'Disparo do personagem ao inimigo (ms)', 80, 1000, 10, 300],
      ['strikeStaggerMs', 'Intervalo entre disparos (ms)', 20, 500, 5, 130],
      ['numRx', 'Espalhar números: horizontal (px)', 0, 160, 2, 64],
      ['numRy', 'Espalhar números: vertical (px)', 0, 140, 2, 46],
      ['numSize', 'Tamanho do número (px)', 10, 48, 1, 22],
      ['critScale', 'Escala do crítico', 1, 2.2, 0.05, 1.45],
      ['numPop', 'Estouro do número (escala)', 1, 2, 0.05, 1.4],
      ['numRise', 'Subida do número (px)', 0, 160, 2, 54],
      ['numDrift', 'Deriva lateral (px)', 0, 90, 2, 26],
      ['numJump', 'Salto até o ponto (fração da vida)', 0, 0.6, 0.02, 0.2],
      ['numHop', 'Altura do salto (px)', 0, 60, 1, 18],
      ['numLifeMs', 'Vida do número (ms)', 300, 2500, 20, 1150],
      ['hitShakePx', 'Tremor do inimigo (px)', 0, 14, 0.5, 4],
      ['showTotal', 'Mostrar total no fim (0/1)', 0, 1, 1, 1],
      ['perColor', 'Um número por cor em vez de por trio (0/1)', 0, 1, 1, 0],
    ]],
    ['Inimigo ataca', [
      ['enemyLungePx', 'Avanço do inimigo (px)', 0, 60, 1, 22],
      ['enemyAtkMs', 'Duração do ataque (ms)', 100, 900, 10, 320],
    ]],
    ['Personagens parados (idle)', [
      ['idleOn', 'Ligado (0/1)', 0, 1, 1, 1],
      ['idleBreath', 'Respiração (escala)', 0, 0.08, 0.002, 0.022],
      ['idleBobPx', 'Flutuar (px)', 0, 6, 0.1, 1.2],
      ['idleSwayDeg', 'Balanço dos inimigos (graus)', 0, 4, 0.1, 0.8],
      ['idleSpeed', 'Velocidade', 0.2, 3, 0.05, 1],
      ['hopPx', 'Pulinho ao receber energia (px)', 0, 20, 0.5, 6],
    ]],
    ['Skill de líder', [
      ['leaderOrbs', 'Orbes até cada aliado', 0, 8, 1, 3],
      ['leaderMs', 'Duração da ativação (ms)', 200, 1600, 20, 700],
      ['leaderAura', 'Aura dourada no time (intensidade)', 0, 2, 0.05, 0.9],
    ]],
    ['Vitória / Derrota', [
      ['endDelayMs', 'Espera antes da tela (ms)', 0, 1500, 20, 420],
      ['endTitlePx', 'Tamanho do título (px)', 24, 72, 1, 48],
      ['endLetterMs', 'Intervalo entre letras (ms)', 0, 200, 5, 75],
      ['endRays', 'Raios de luz (intensidade)', 0, 1, 0.05, 0.55],
      ['endConfetti', 'Confete (quantidade)', 0, 300, 5, 140],
      ['endGlitchPx', 'Glitch da derrota (px)', 0, 10, 0.5, 3.5],
      ['endDesatMs', 'Tela desbotando (ms)', 100, 3000, 50, 1100],
    ]],
    ['Som', [
      ['sfxOn', 'Ligado (0/1)', 0, 1, 1, 1],
      ['sfxVol', 'Volume', 0, 1, 0.05, 0.6],
    ]],
  ];
  const DEFAULTS = {};
  SCHEMA.forEach(([, rows]) => rows.forEach(([k, , , , , v]) => { DEFAULTS[k] = v; }));
  const LS_KEY = 'ilhaDigital.comboLab.params.v1';
  let P = { ...DEFAULTS };
  try { Object.assign(P, JSON.parse(localStorage.getItem(LS_KEY) || '{}')); } catch (e) { /* sem storage */ }
  const saveP = () => { try { localStorage.setItem(LS_KEY, JSON.stringify(P)); } catch (e) { /* ignore */ } };

  // ------------------------------------------------------------------ utilitarios
  const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
  const lerp = (a, b, t) => a + (b - a) * t;
  const E = {
    lin: (t) => t, quadOut: (t) => 1 - (1 - t) * (1 - t), quadIn: (t) => t * t,
    cubicOut: (t) => 1 - Math.pow(1 - t, 3), cubicIn: (t) => t * t * t,
    cubicInOut: (t) => t < .5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2,
    sineInOut: (t) => -(Math.cos(Math.PI * t) - 1) / 2,
    backOut: (t) => { const c1 = 1.70158, c3 = c1 + 1; return 1 + c3 * Math.pow(t - 1, 3) + c1 * Math.pow(t - 1, 2); },
  };
  function seeded(seed) { let a = seed >>> 0; return () => { a |= 0; a = a + 0x6D2B79F5 | 0; let t = Math.imul(a ^ a >>> 15, 1 | a); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; }; }
  let seedCounter = 1;
  const rnd = () => seeded(seedCounter++ * 9973);

  // ------------------------------------------------------------------ cena
  const ROOT = document.querySelector('.xroot');
  const part = (n) => ROOT.querySelector(`[data-part="${n}"]`);
  const STAGE = document.getElementById('lab-stage');
  let K = 1;
  function rel(el) {
    const r = el.getBoundingClientRect(), R = ROOT.getBoundingClientRect(), k = R.width / 512;
    return { x: (r.left - R.left) / k, y: (r.top - R.top) / k, w: r.width / k, h: r.height / k };
  }

  const grid = part('bank_grid');
  const SLOT = [...grid.children].map(rel);
  [...grid.children].forEach((b) => { b.style.visibility = 'hidden'; });
  const gi = (slot) => slot < 10 ? Math.floor(slot / 5) * 6 + (slot % 5) : (slot === 10 ? 5 : 11);
  const slotPos = (slot) => SLOT[gi(slot)];
  const CW = SLOT[0].w, CH = SLOT[0].h;
  const gridRect = rel(grid);
  const FUSE = { x: gridRect.x + gridRect.w / 2, y: gridRect.y + gridRect.h / 2 };

  const slotLayer = document.createElement('div'); slotLayer.className = 'lab-layer';
  const cardLayer = document.createElement('div'); cardLayer.className = 'lab-layer';
  const canvas = document.createElement('canvas'); canvas.className = 'lab-canvas';
  const numLayer = document.createElement('div'); numLayer.className = 'lab-layer lab-nums';
  const endLayer = document.createElement('div'); endLayer.className = 'lab-layer lab-end';
  ROOT.append(slotLayer, cardLayer, canvas, numLayer, endLayer);
  const ctx = canvas.getContext('2d');

  // sons: placeholders do original (nomes confirmados no binario, ver heroes/docideias/sons-de-batalha.md)
  const SFX = window.LAB_SFX || {};
  function sfx(name, start, vol = 1) {
    if (!SFX[name]) return;
    at(start, 1, { begin() {
      if (!P.sfxOn || SNAP || TL.t - start > 120) return;
      const a = new Audio(SFX[name]); a.volume = clamp(P.sfxVol * vol, 0, 1); a.play().catch(() => {});
      if (name.startsWith('bgm')) { V.music && V.music.pause(); V.music = a; }
    } });
  }
  function sizeCanvas() {
    const k = ROOT.getBoundingClientRect().width / 512;
    const R = Math.min(4, Math.max(1, k * (window.devicePixelRatio || 1)));
    canvas.width = 512 * R; canvas.height = 800 * R; ctx.setTransform(R, 0, 0, R, 0, 0);
  }
  for (let s = 0; s < 12; s++) {
    const d = document.createElement('div'); d.className = 'lab-slot' + (s >= 10 ? ' entry' : '');
    const p = slotPos(s); Object.assign(d.style, { left: p.x + 'px', top: p.y + 'px', width: p.w + 'px', height: p.h + 'px' });
    slotLayer.appendChild(d);
  }

  // referencias do HUD
  const figEl = (slot) => part('stage_fig_' + slot);
  const spriteEl = (slot) => part('stage_sprite_' + slot);
  const ringFill = (slot) => { const s = part('stage_ring_' + slot); return s ? s.querySelectorAll('ellipse')[1] : null; };
  function figPoint(slot, fy = .55) { const f = figEl(slot); const r = rel(f); return { x: r.x + r.w / 2, y: r.y + r.w * fy }; }
  function footPoint(slot) { const f = figEl(slot); const r = rel(f); return { x: r.x + r.w / 2, y: r.y + r.w * .97 }; }
  const ENEMY_SLOTS = ['E1', 'E2', 'E3'];
  const queueBox = part('bank_queue');
  const teamFill = part('team_hp_fill'), teamText = part('team_hp_text'), teamLabel = part('team_hp_label');
  const leaderBtn = part('button_leader');
  const ALLY_SLOTS = ['A1', 'A2', 'A3', 'A4', 'A5'];
  const IDLE_SPRITES = [...ROOT.querySelectorAll('[data-part^="stage_sprite_"]')].map((el, i) => {
    el.style.transformOrigin = '50% 97%';
    const slot = el.getAttribute('data-part').slice('stage_sprite_'.length);
    return { el, slot, enemy: slot.startsWith('E'), phase: i * 1.37 + (slot.charCodeAt(1) % 3) * .6 };
  });

  // ------------------------------------------------------------------ linha do tempo
  const TL = { t: 0, speed: 1, paused: false, items: [], cursor: 0, busyUntil: 0, tail: 0 };
  function at(start, dur, h) { TL.items.push({ start, dur: Math.max(1, dur), h, s: 0 }); }
  function tick(t) {
    ctx.clearRect(0, 0, 512, 800);
    TL.items.sort((a, b) => a.start - b.start);
    const keep = [];
    for (const it of TL.items) {
      if (t < it.start) { keep.push(it); continue; }
      if (!it.s) { it.s = 1; it.h.begin && it.h.begin(); }
      const p = Math.min(1, (t - it.start) / it.dur);
      it.h.update && it.h.update(p, t - it.start);
      if (p >= 1) { it.h.end && it.h.end(); } else keep.push(it);
    }
    TL.items = keep;
    drawLeaderAura(t);
    drawAuras(t);
    drawIdle(t);
    drawEnd(t);
    hud.clock.textContent = (TL.t / 1000).toFixed(2) + 's';
  }
  let last = performance.now();
  function loop(now) {
    const dt = Math.min(50, now - last); last = now;
    if (!TL.paused) { TL.t += dt * TL.speed; tick(TL.t); }
    requestAnimationFrame(loop);
  }

  // ------------------------------------------------------------------ cartas
  function applyCard(el) {
    const s = el._s;
    el.style.transform = `translate(${s.x}px,${s.y}px) rotate(${s.rot}deg) scale(${s.sc})`;
    el.style.opacity = s.op;
    el._w.style.opacity = s.white;
    el.style.filter = s.glow > .2 ? `drop-shadow(0 0 ${s.glow}px ${s.glowCol}) drop-shadow(0 0 ${s.glow * .45}px ${s.glowCol})` : 'none';
    el.classList.toggle('sel', !!s.frame);
    el._o.textContent = s.ord || '';
    el._o.style.display = s.ord ? 'block' : 'none';
    el._v.style.opacity = s.valOp;
  }
  function makeCard(c, pos, hidden) {
    const el = document.createElement('div'); el.className = 'lc';
    el.dataset.el = ELEM[c.cor];
    el.innerHTML = `<img src="${IMG[ELEM[c.cor]]}" draggable="false"><span class="lc-val mono">${c.valor}</span><span class="lc-ord mono"></span><span class="lc-white"></span>`;
    el._v = el.querySelector('.lc-val'); el._o = el.querySelector('.lc-ord'); el._w = el.querySelector('.lc-white');
    el.style.width = CW + 'px'; el.style.height = CH + 'px';
    el._s = { x: pos.x, y: pos.y, sc: 1, rot: 0, op: 1, white: 0, glow: 0, glowCol: '#fff', frame: false, ord: 0, valOp: 1 };
    el._c = c;
    if (hidden) el.style.display = 'none';
    el.addEventListener('pointerdown', (e) => { e.preventDefault(); onCardTap(el); });
    cardLayer.appendChild(el); applyCard(el);
    return el;
  }
  function tw(el, start, dur, to, ease = E.quadOut, o = {}) {
    at(start, dur, {
      begin() { if (o.show) el.style.display = ''; if (o.set) Object.assign(el._s, o.set); this.f = { ...el._s }; if (o.z != null) el.style.zIndex = o.z; },
      update(p) { const e = ease(p); for (const k in to) el._s[k] = lerp(this.f[k], to[k], e); if (o.fn) o.fn(el, p); applyCard(el); },
      end() { if (o.after) Object.assign(el._s, o.after); applyCard(el); if (o.remove) el.remove(); },
    });
  }
  const V = { hand: new Array(12).fill(null), marked: {}, pulled: [], lastExplode: 0, chain: [], ringVal: { ...ALLY_BASE }, ringShown: { ...ALLY_BASE },
    hop: {}, dead: {}, leaderOn: false, leaderFrom: 0, music: null, stats: { dano: 0, combos: 0, maiorCadeia: 0, criticos: 0 } };
  const newStats = () => ({ dano: 0, combos: 0, maiorCadeia: 0, criticos: 0 });

  function setQueue(fila, start) {
    at(start, 1, {
      begin() {
        queueBox.innerHTML = '';
        fila.slice(0, 4).forEach((c, k) => {
          const s = document.createElement('span');
          s.dataset.el = ELEM[c.cor];
          s.style.cssText = `display:block;width:16px;height:19px;opacity:${(1 - k * .2).toFixed(2)}`;
          s.innerHTML = `<img src="${IMG[ELEM[c.cor]]}" style="width:16px;height:19px;display:block">`;
          queueBox.appendChild(s);
        });
      },
    });
  }
  function queueOrigin() { const r = rel(queueBox); return { x: r.x - CW * .5 + 8, y: r.y - CH * .5 + 9 }; }

  function rebuild(logic) {
    TL.items = []; ctx.clearRect(0, 0, 512, 800); for (const k in AURA) delete AURA[k];
    cardLayer.innerHTML = ''; numLayer.innerHTML = '';
    V.hand = new Array(12).fill(null); V.marked = {}; V.pulled = []; V.chain = []; V.hop = {}; V.dead = {};
    clearEnd();
    setLeader(logic.liderAtivo, logic.liderCd); V.leaderOn = logic.liderAtivo; V.leaderFrom = TL.t;
    logic.mao.forEach((c, s) => { if (c) V.hand[s] = makeCard(c, slotPos(s)); });
    logic.zona.forEach((c, i) => {
      const s = logic.zonaSlots[i]; const p = slotPos(s);
      const el = makeCard(c, p); el._s.y = p.y - P.liftPx; el._s.frame = true; el._s.ord = i + 1; el.style.zIndex = 5; applyCard(el);
      V.marked[s] = el;
    });
    const q0 = TL.t; setQueue(logic.proximas, q0);
    V.ringVal = { ...ALLY_BASE }; for (const k in ALLY_BASE) setRing(k, ALLY_BASE[k], false);
    logic.inimigos.forEach((e, i) => { setRing(ENEMY_SLOTS[i], Math.round(e.hp / e.max * 100), false); setDead(i, !e.vivo); setTurn(i, e.contador, e.vivo); });
    setTeam(logic.hp, logic.hpMax); moveAim(logic.alvo, true); updateCombo(logic.zona.length);
    tick(TL.t);
  }

  // ------------------------------------------------------------------ HUD
  function setRing(slot, pct, glow) {
    const f = ringFill(slot); if (!f) return;
    f.setAttribute('stroke-dasharray', `${clamp(pct, 0, 100)} 100`);
    const svg = part('stage_ring_' + slot);
    if (svg && slot.startsWith('A')) svg.style.filter = glow ? `drop-shadow(0 0 ${4 + glow * 6}px ${f.getAttribute('stroke')})` : 'none';
    V.ringShown[slot] = pct;
  }
  function ringTween(slot, start, dur, toPct, glowTo = 0) {
    at(start, dur, { begin() { this.f = V.ringShown[slot] ?? 0; }, update(p) { setRing(slot, lerp(this.f, toPct, E.cubicOut(p)), glowTo); } });
  }
  function setTeam(hp, max) {
    const r = hp / max; const col = r > .4 ? '#6FE3B8' : (r > .2 ? '#F2A33C' : '#FF6B4A');
    teamFill.style.width = (r * 100).toFixed(1) + '%'; teamFill.style.background = col; teamLabel.style.color = col;
    teamText.innerHTML = `${Math.round(hp)}<span style="color: rgba(245,239,226,.38);">/${max}</span>`;
  }
  function teamTween(start, dur, fromHp, toHp, max) { at(start, dur, { update(p) { setTeam(lerp(fromHp, toHp, E.cubicOut(p)), max); } }); }
  function setTurn(i, n, vivo) {
    const tn = part('chip_turn_' + ENEMY_SLOTS[i]); if (!tn) return;
    const on = n >= 3 ? 'rgba(242,163,60,.55)' : (n === 2 ? '#F2A33C' : '#FF6B4A');
    const col = n >= 3 ? 'rgba(242,163,60,.75)' : (n === 2 ? '#F2A33C' : '#FF6B4A');
    const is = tn.querySelectorAll('i'); is.forEach((x, k) => { x.style.background = k < n ? on : 'rgba(242,163,60,.18)'; });
    tn.querySelector('b').textContent = n; tn.style.color = vivo ? col : 'rgba(245,239,226,.3)';
    tn.style.animation = vivo && n <= 1 ? 'fast .8s ease-in-out infinite' : 'none';
  }
  function setDead(i, dead) { V.dead[ENEMY_SLOTS[i]] = dead; const f = figEl(ENEMY_SLOTS[i]); if (f) { f.style.opacity = dead ? .35 : 1; f.style.filter = dead ? 'grayscale(1)' : 'none'; } }
  function setLeader(on, cd) {
    if (!leaderBtn) return;
    const svg = leaderBtn.querySelector('svg'), tag = leaderBtn.querySelector('span');
    const col = on ? '#1A1105' : (cd > 0 ? 'rgba(245,239,226,.35)' : '#F2A33C');
    leaderBtn.style.background = on ? '#F2A33C' : '#201C13';
    leaderBtn.style.boxShadow = on ? '0 0 12px rgba(242,163,60,.7)' : 'inset 0 0 0 1px rgba(242,163,60,.3)';
    if (svg) svg.setAttribute('fill', on ? '#1A1105' : (cd > 0 ? 'rgba(245,239,226,.3)' : '#F2A33C'));
    if (tag) { tag.style.color = col; tag.textContent = on ? 'LÍDER ON' : (cd > 0 ? 'CD ' + cd : 'LÍDER'); }
  }
  function hop(slot, start, px, dur = 280) { at(start, 1, { begin() { V.hop[slot] = { from: start, px, dur }; } }); }

  // ------------------------------------------------------------------ idle dos personagens
  function drawIdle(t) {
    const defeat = END.active && END.kind === 'derrota';
    for (const s of IDLE_SPRITES) {
      if ((!P.idleOn && !(defeat && !s.enemy)) || V.dead[s.slot]) { s.el.style.scale = ''; s.el.style.translate = ''; s.el.style.rotate = ''; continue; }
      const k = t / 1000 * P.idleSpeed;
      const ph = k * Math.PI * 2 * (s.enemy ? .38 : .5) + s.phase;
      const breath = Math.sin(ph) * P.idleBreath * (s.enemy ? 1.15 : 1);
      let y = -(0.5 + 0.5 * Math.sin(ph * .5 + s.phase)) * P.idleBobPx;
      const h = V.hop[s.slot];
      if (h) { const p = (t - h.from) / h.dur; if (p >= 1) delete V.hop[s.slot]; else if (p >= 0) y -= Math.sin(p * Math.PI) * h.px; }
      if (END.active && END.kind === 'derrota' && !s.enemy) {
        const p = E.cubicOut(clamp((t - END.from) / 700, 0, 1)), side = s.phase % 2 > 1 ? 1 : -1;
        s.el.style.scale = `${1 + .04 * p} ${1 - .1 * p}`; s.el.style.translate = `0 ${(3 * p).toFixed(2)}px`; s.el.style.rotate = (side * 6 * p).toFixed(2) + 'deg';
        continue;
      }
      if (END.active && END.kind === 'vitoria' && !s.enemy) {
        const p = ((t - END.from - 600 - s.phase * 90) % 620) / 620;
        if (t - END.from > 600 + s.phase * 90 && p >= 0) y -= Math.abs(Math.sin(p * Math.PI)) * 10;
      }
      s.el.style.scale = `${1 - breath * .45} ${1 + breath}`;
      s.el.style.translate = `0 ${y.toFixed(2)}px`;
      s.el.style.rotate = s.enemy ? (Math.sin(ph * .7 + 1) * P.idleSwayDeg).toFixed(2) + 'deg' : '';
    }
  }
  function drawLeaderAura(t) {
    if (!V.leaderOn || !P.leaderAura) return;
    const k = clamp((t - V.leaderFrom) / 400, 0, 1) * P.leaderAura;
    ctx.save(); ctx.globalCompositeOperation = 'lighter';
    ALLY_SLOTS.forEach((slot, i) => {
      const f = rel(figEl(slot)); const cx = f.x + f.w / 2, foot = f.y + f.w * .97;
      const pulse = .75 + .25 * Math.sin(t / 260 + i);
      ctx.strokeStyle = hexA('#FFD36A', clamp(.55 * k * pulse, 0, 1)); ctx.lineWidth = 1.6;
      ctx.beginPath(); ctx.ellipse(cx, foot - f.w * .03, f.w * .36 * (1 + .05 * Math.sin(t / 300 + i)), f.w * .13, 0, 0, Math.PI * 2); ctx.stroke();
      const ph = ((t / 900) + i * .2) % 1;
      glowDot(cx + Math.sin(i * 2.1 + t / 500) * f.w * .22, foot - ph * f.w * .6, 1.8, '#FFD36A', clamp(Math.sin(ph * Math.PI) * k, 0, 1));
    });
    ctx.restore();
  }
  function updateCombo(n) { const pips = part('bank_combo').children; [...pips].forEach((s, k) => { s.style.background = k < n ? '#F2A33C' : 'rgba(242,163,60,.18)'; }); }
  const aim = part('visor_aim');
  function moveAim(i, instant) {
    const r = rel(figEl(ENEMY_SLOTS[i])); const size = Math.round(r.w * .97) * .96;
    const target = { left: r.x + r.w / 2, top: r.y + Math.round(r.w * .97) / 2, size };
    ENEMY_SLOTS.forEach((s, k) => { const ch = part('chip_' + s); if (ch) ch.style.boxShadow = k === i ? '0 0 0 1.3px #FF6B4A, 0 0 10px rgba(255,107,74,.55)' : ''; });
    if (instant) { Object.assign(aim.style, { left: target.left + 'px', top: target.top + 'px', width: size + 'px', height: size + 'px' }); return; }
    const f = { left: parseFloat(aim.style.left), top: parseFloat(aim.style.top), size: parseFloat(aim.style.width) };
    at(TL.t, 160, { update(p) { const e = E.cubicOut(p); Object.assign(aim.style, { left: lerp(f.left, target.left, e) + 'px', top: lerp(f.top, target.top, e) + 'px', width: lerp(f.size, size, e) + 'px', height: lerp(f.size, size, e) + 'px' }); } });
  }

  // ------------------------------------------------------------------ efeitos de canvas
  function glowDot(x, y, r, col, a) {
    const g = ctx.createRadialGradient(x, y, 0, x, y, r * 3.2);
    g.addColorStop(0, `rgba(255,255,255,${a})`); g.addColorStop(.25, hexA(col, a)); g.addColorStop(1, hexA(col, 0));
    ctx.fillStyle = g; ctx.beginPath(); ctx.arc(x, y, r * 3.2, 0, Math.PI * 2); ctx.fill();
  }
  function hexA(hex, a) { const n = parseInt(hex.slice(1), 16); return `rgba(${n >> 16 & 255},${n >> 8 & 255},${n & 255},${a})`; }
  function burst(start, x, y, col, n, speedMin, speedMax, life, size, gravity) {
    const r = rnd(); const ps = [];
    for (let i = 0; i < n; i++) {
      const a = r() * Math.PI * 2, v = lerp(speedMin, speedMax, Math.pow(r(), .7));
      ps.push({ vx: Math.cos(a) * v, vy: Math.sin(a) * v, l: life * lerp(.55, 1, r()), s: size * lerp(.6, 1.4, r()), w: r() < .35 });
    }
    at(start, life, {
      update(p, ms) {
        ctx.save(); ctx.globalCompositeOperation = 'lighter';
        for (const q of ps) {
          if (ms > q.l) continue; const tt = ms / 1000, k = 1 - ms / q.l;
          const px = x + q.vx * tt, py = y + q.vy * tt + .5 * gravity * tt * tt;
          glowDot(px, py, q.s * (.5 + .5 * k), q.w ? '#FFFFFF' : col, k * .95);
        }
        ctx.restore();
      },
    });
  }
  function flash(start, x, y) {
    at(start, P.flashMs, { update(p) { const r = P.flashRadius * (.35 + .65 * E.cubicOut(p)); const g = ctx.createRadialGradient(x, y, 0, x, y, r);
      g.addColorStop(0, `rgba(255,255,255,${Math.pow(1 - p, 1.6)})`); g.addColorStop(1, 'rgba(255,255,255,0)');
      ctx.save(); ctx.globalCompositeOperation = 'lighter'; ctx.fillStyle = g; ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.fill(); ctx.restore(); } });
  }
  function shock(start, x, y, col) {
    at(start, P.ringMs, { update(p) { const e = E.cubicOut(p); ctx.save(); ctx.globalCompositeOperation = 'lighter';
      ctx.strokeStyle = hexA(col, 1 - p); ctx.lineWidth = Math.max(.1, P.ringWidth * (1 - p)); ctx.beginPath(); ctx.arc(x, y, lerp(12, P.ringRadius, e), 0, Math.PI * 2); ctx.stroke();
      ctx.strokeStyle = `rgba(255,255,255,${(1 - p) * .6})`; ctx.lineWidth = Math.max(.1, P.ringWidth * .35 * (1 - p)); ctx.beginPath(); ctx.arc(x, y, lerp(8, P.ringRadius * .78, e), 0, Math.PI * 2); ctx.stroke(); ctx.restore(); } });
  }
  function orb(start, dur, from, to, col, arc, size, trail) {
    const r = rnd(); const side = r() < .5 ? -1 : 1;
    const mx = (from.x + to.x) / 2, my = (from.y + to.y) / 2, dx = to.x - from.x, dy = to.y - from.y, L = Math.hypot(dx, dy) || 1;
    const cx = mx + (-dy / L) * arc * side * lerp(.5, 1, r()), cy = my + (dx / L) * arc * side * lerp(.5, 1, r()) - arc * .35;
    const pt = (u) => ({ x: (1 - u) * (1 - u) * from.x + 2 * (1 - u) * u * cx + u * u * to.x, y: (1 - u) * (1 - u) * from.y + 2 * (1 - u) * u * cy + u * u * to.y });
    at(start, dur, { update(p) { const u = E.cubicInOut(p); ctx.save(); ctx.globalCompositeOperation = 'lighter';
      const steps = 12; for (let i = steps; i >= 0; i--) { const uu = Math.max(0, u - trail * (i / steps)); const q = pt(uu); glowDot(q.x, q.y, size * (1 - i / steps * .8), col, (1 - i / steps) * .75); }
      ctx.restore(); } });
  }
  function streak(start, dur, from, to, col) {
    at(start, dur, { update(p) { const u = E.quadIn(p); const hx = lerp(from.x, to.x, u), hy = lerp(from.y, to.y, u), tu = Math.max(0, u - .28);
      const tx = lerp(from.x, to.x, tu), ty = lerp(from.y, to.y, tu);
      ctx.save(); ctx.globalCompositeOperation = 'lighter'; const g = ctx.createLinearGradient(tx, ty, hx, hy);
      g.addColorStop(0, hexA(col, 0)); g.addColorStop(1, hexA(col, .95)); ctx.strokeStyle = g; ctx.lineWidth = 3.2; ctx.lineCap = 'round';
      ctx.beginPath(); ctx.moveTo(tx, ty); ctx.lineTo(hx, hy); ctx.stroke(); glowDot(hx, hy, 3.4, col, 1); ctx.restore(); } });
  }
  function floatText(start, life, x, y, html, cls, anim) {
    const el = document.createElement('div'); el.className = 'lab-float ' + (cls || ''); el.innerHTML = html; el.style.display = 'none';
    numLayer.appendChild(el);
    at(start, life, { begin() { el.style.display = ''; }, update(p) { anim(el, p, x, y); }, end() { el.remove(); } });
  }
  // energia que fica no personagem ate o ataque final
  const AURA = {};
  function drawAuras(t) {
    ctx.save(); ctx.globalCompositeOperation = 'lighter';
    for (const slot in AURA) {
      const a = AURA[slot]; if (t < a.from) continue;
      const k = clamp((t - a.from) / 250, 0, 1) * a.level;
      const f = rel(figEl(slot)); const cx = f.x + f.w / 2, foot = f.y + f.w * .97;
      const g = ctx.createRadialGradient(cx, foot - f.w * .05, 0, cx, foot - f.w * .05, f.w * .42);
      g.addColorStop(0, hexA(a.col, clamp(.6 * k * P.auraGlow, 0, 1))); g.addColorStop(1, hexA(a.col, 0));
      ctx.fillStyle = g; ctx.beginPath(); ctx.ellipse(cx, foot - f.w * .05, f.w * .42, f.w * .2, 0, 0, Math.PI * 2); ctx.fill();
      const n = Math.round(P.auraMotes * k);
      for (let i = 0; i < n; i++) {
        const ph = ((t / 1000) * (0.45 + (i % 3) * .12) + i / n) % 1;
        const ang = i * 2.399 + t / 1400;
        const x = cx + Math.cos(ang) * f.w * .3 * (1 - ph * .4), y = foot - ph * f.w * .75;
        glowDot(x, y, 2 + (i % 2) * .8, a.col, clamp(Math.sin(ph * Math.PI) * k * P.auraGlow, 0, 1));
      }
    }
    ctx.restore();
  }
  function shakeEl(el, start, dur, amp, prop = 'translateX') {
    at(start, dur, { update(p) { const k = (1 - p); el.style.transform = `${prop}(${Math.sin(p * Math.PI * 7) * amp * k}px)`; }, end() { el.style.transform = ''; } });
  }

  // ------------------------------------------------------------------ vitoria / derrota
  const END = { active: false, kind: null, from: 0, title: null, letters: [], confetti: [], anchor: null };
  const visorEl = part('visor');
  const CONFETTI_COLS = ['#FF5A3D', '#4DA8FF', '#5BD75B', '#FFC93C', '#B06BFF', '#FFFFFF'];
  function clearEnd() {
    END.active = false; END.kind = null; END.title = null; END.letters = []; END.confetti = [];
    endLayer.innerHTML = ''; endLayer.style.pointerEvents = 'none';
    visorEl.style.filter = ''; leaderBtn && (leaderBtn.style.opacity = '');
    if (V.music) { V.music.pause(); V.music = null; }
  }
  function playEnd(kind, start) {
    const win = kind === 'vitoria';
    const vr = rel(visorEl);
    const anchor = { x: 256, y: vr.y + vr.h * .3 };
    const st = V.stats.combos ? V.stats : { dano: 4280, combos: 9, maiorCadeia: 4, criticos: 2 };
    at(start, 1, { begin() {
      clearEnd();
      Object.assign(END, { active: true, kind, from: start, anchor });
      endLayer.style.pointerEvents = 'auto';
      const word = win ? 'VITÓRIA' : 'DERROTA';
      const wrap = document.createElement('div'); wrap.className = 'end-wrap ' + (win ? 'win' : 'lose');
      wrap.innerHTML = `
        <div class="end-title" style="left:${anchor.x}px;top:${anchor.y}px;font-size:${P.endTitlePx}px">${[...word].map((ch) => `<span class="end-letter">${ch}</span>`).join('')}</div>
        <div class="end-sub tick" style="left:${anchor.x}px;top:${anchor.y + P.endTitlePx * .72}px">${win ? 'SETOR 03 · ILHA DIGITAL · LIMPO' : 'EQUIPE CAÍDA · SINAL PERDIDO'}</div>
        <div class="end-panel" style="left:256px;top:${vr.y + vr.h + 70}px">
          <div class="end-stats">
            <div><span class="tick">DANO TOTAL</span><b data-v="${st.dano}">0</b></div>
            <div><span class="tick">COMBOS</span><b data-v="${st.combos}">0</b></div>
            <div><span class="tick">MAIOR CADEIA</span><b data-v="${st.maiorCadeia}">0</b></div>
            <div><span class="tick">CRÍTICOS</span><b data-v="${st.criticos}">0</b></div>
          </div>
          <button class="end-btn" type="button">${win ? 'JOGAR DE NOVO' : 'TENTAR DE NOVO'}</button>
        </div>`;
      endLayer.appendChild(wrap);
      END.title = wrap.querySelector('.end-title');
      END.letters = [...wrap.querySelectorAll('.end-letter')];
      END.letters.forEach((l) => { l.style.opacity = 0; });
      const sub = wrap.querySelector('.end-sub'), panel = wrap.querySelector('.end-panel');
      sub.style.opacity = 0; panel.style.opacity = 0;
      wrap.querySelector('.end-btn').addEventListener('pointerdown', (e) => { e.stopPropagation(); newGame(lastPreset); });
      const r = rnd();
      END.confetti = win ? Array.from({ length: P.endConfetti }, () => ({ x: r() * 512, y: -r() * 700 - 20, vy: lerp(70, 170, r()), sway: lerp(8, 26, r()), f: lerp(1.5, 4, r()), ph: r() * 6.28,
        rot: r() * 6.28, vr: lerp(-6, 6, r()), w: lerp(3, 6, r()), h: lerp(5, 10, r()), col: CONFETTI_COLS[Math.floor(r() * CONFETTI_COLS.length)] })) : [];
    } });

    // letras
    const n = (win ? 'VITÓRIA' : 'DERROTA').length;
    const lettersStart = start + (win ? 180 : 420);
    for (let i = 0; i < n; i++) {
      at(lettersStart + i * P.endLetterMs, win ? 420 : 300, {
        update(p) { const l = END.letters[i]; if (!l) return;
          if (win) { const e = E.backOut(p); l.style.opacity = Math.min(1, p * 3); l.style.transform = `translateY(${lerp(-38, 0, e)}px) scale(${lerp(2.4, 1, e)})`; }
          else { const e = E.cubicOut(p); l.style.opacity = Math.min(1, p * 2); l.style.transform = `translateY(${lerp(10, 0, e)}px) scaleY(${lerp(.2, 1, e)})`; }
        },
      });
    }
    const lettersEnd = lettersStart + (n - 1) * P.endLetterMs + (win ? 420 : 300);
    at(lettersEnd - 120, 1, { begin() { shakeEl(visorEl, TL.t, win ? 260 : 420, win ? 3 : 6); } });
    const sub = () => endLayer.querySelector('.end-sub'), panel = () => endLayer.querySelector('.end-panel');
    at(lettersEnd, 400, { update(p) { const s = sub(); if (s) { s.style.opacity = p; s.style.translate = `0 ${lerp(8, 0, E.cubicOut(p))}px`; } } });
    at(lettersEnd + 350, 420, { update(p) { const s = panel(); if (s) { s.style.opacity = p; s.style.translate = `0 ${lerp(16, 0, E.cubicOut(p))}px`; } } });
    at(lettersEnd + 500, 1000, { update(p) { endLayer.querySelectorAll('.end-stats b').forEach((b) => { b.textContent = Math.round(+b.dataset.v * E.cubicOut(p)); }); } });
    sfx('se_countup', lettersEnd + 500, .8);

    if (win) {
      burst(start + 120, anchor.x, anchor.y, '#FFD36A', 90, 80, 520, 1100, 3, 120);
      shock(start + 120, anchor.x, anchor.y, '#FFD36A');
      ALLY_SLOTS.forEach((s, i) => { const f = figPoint(s, .5); burst(start + 300 + i * 90, f.x, f.y, colorOf([0, 4, 1, 3, 2][i]), 18, 40, 180, 600, 2.2, -40); });
      sfx('bgm_06_battle_win', start, .9);
    } else {
      at(start, P.endDesatMs, { update(p) { visorEl.style.filter = `grayscale(${(.9 * E.cubicOut(p)).toFixed(3)}) brightness(${lerp(1, .62, E.cubicOut(p)).toFixed(3)}) contrast(1.08)`; } });
      shakeEl(visorEl, start, 520, 7);
      sfx('bgm_07_battle_lose', start, .9);
    }
  }
  function drawEnd(t) {
    if (!END.active) return;
    const tt = t - END.from, win = END.kind === 'vitoria', a = END.anchor;
    const fade = clamp(tt / 450, 0, 1);
    // escurece: forte no banco de cartas, leve no visor
    ctx.fillStyle = `rgba(8,6,4,${(.78 * fade).toFixed(3)})`; ctx.fillRect(0, 470, 512, 330);
    ctx.fillStyle = win ? `rgba(8,6,4,${(.22 * fade).toFixed(3)})` : `rgba(20,2,2,${(.3 * fade).toFixed(3)})`; ctx.fillRect(0, 0, 512, 470);
    if (win) {
      if (tt < 320) { ctx.fillStyle = `rgba(255,248,225,${(.75 * Math.pow(1 - tt / 320, 2)).toFixed(3)})`; ctx.fillRect(0, 0, 512, 800); }
      if (P.endRays > 0) {
        ctx.save(); ctx.globalCompositeOperation = 'lighter'; ctx.translate(a.x, a.y); ctx.rotate(tt / 4200);
        const R = 360, rays = 14, k = P.endRays * clamp((tt - 100) / 600, 0, 1);
        for (let i = 0; i < rays; i++) {
          const ang = i / rays * Math.PI * 2, wdt = .09 + .04 * Math.sin(tt / 500 + i);
          const g = ctx.createRadialGradient(0, 0, 10, 0, 0, R);
          g.addColorStop(0, hexA(i % 2 ? '#FFD36A' : '#6FE3B8', .42 * k)); g.addColorStop(1, hexA('#FFD36A', 0));
          ctx.fillStyle = g; ctx.beginPath(); ctx.moveTo(0, 0); ctx.arc(0, 0, R, ang - wdt, ang + wdt); ctx.closePath(); ctx.fill();
        }
        const core = ctx.createRadialGradient(0, 0, 0, 0, 0, 90); core.addColorStop(0, hexA('#FFE9A8', .35 * k)); core.addColorStop(1, hexA('#FFE9A8', 0));
        ctx.fillStyle = core; ctx.beginPath(); ctx.arc(0, 0, 90, 0, Math.PI * 2); ctx.fill();
        ctx.restore();
      }
      const s = tt / 1000;
      for (const c of END.confetti) {
        const y = c.y + c.vy * s; if (y > 820) continue;
        const x = c.x + Math.sin(s * c.f + c.ph) * c.sway;
        ctx.save(); ctx.translate(x, y); ctx.rotate(c.rot + c.vr * s); ctx.scale(1, Math.cos(s * c.f * 2 + c.ph));
        ctx.fillStyle = c.col; ctx.globalAlpha = y > 700 ? clamp((820 - y) / 120, 0, 1) : 1; ctx.fillRect(-c.w / 2, -c.h / 2, c.w, c.h); ctx.restore();
      }
      if (tt > 900) {
        const n = END.letters.length, sweep = (((tt - 900) / 2000) % 1) * (n + 5) - 2.5;
        END.letters.forEach((l, i) => {
          const w = clamp(1 - Math.abs(sweep - i) / 1.6, 0, 1);
          l.style.color = `rgb(255,${Math.round(lerp(211, 255, w))},${Math.round(lerp(106, 245, w))})`;
        });
      }
    } else {
      const beat = Math.max(0, Math.sin(tt / 1000 * Math.PI * 1.6)) ** 6;
      const vg = ctx.createRadialGradient(256, 300, 120, 256, 300, 480);
      vg.addColorStop(0, 'rgba(255,40,40,0)'); vg.addColorStop(1, `rgba(255,40,40,${((.22 + .3 * beat * clamp(1 - tt / 5000, .25, 1)) * fade).toFixed(3)})`);
      ctx.fillStyle = vg; ctx.fillRect(0, 0, 512, 800);
      drawEcg(tt, a.y + P.endTitlePx * 1.2 + 26);
      if (END.title) {
        const glitch = tt < 900 || (tt % 2300) < 140 || (tt % 3700) < 90;
        const n = Math.sin(tt * 12.9898) * 43758.5453, rnd1 = n - Math.floor(n), n2 = Math.sin(tt * 78.233) * 12345.678, rnd2 = n2 - Math.floor(n2);
        const dx = glitch ? (rnd1 - .5) * 2 * P.endGlitchPx : .6;
        END.title.style.textShadow = `${dx.toFixed(1)}px 0 #FF2A4A, ${(-dx).toFixed(1)}px 0 #3AD6FF, 0 3px 0 #0B0906, 0 0 18px rgba(255,60,60,.45)`;
        END.title.style.translate = glitch ? `${((rnd2 - .5) * P.endGlitchPx).toFixed(1)}px 0` : '0 0';
        END.title.style.clipPath = glitch && rnd2 > .6 ? `inset(${Math.floor(rnd1 * 50)}% 0 ${Math.floor(rnd2 * 30)}% 0)` : 'none';
      }
    }
  }
  function drawEcg(tt, y) {
    const x0 = 56, x1 = 456, speed = 340, head = x0 + tt / 1000 * speed;
    const wave = (x) => {
      const beats = [[150, 1], [290, .45]];
      let v = 0;
      for (const [bx, amp] of beats) { const d = x - bx; if (d > -6 && d < 22) v += amp * (d < 0 ? -.15 * (d + 6) / 6 : d < 5 ? -1 * Math.sin(d / 5 * Math.PI) * 1.2 : d < 10 ? .55 * Math.sin((d - 5) / 5 * Math.PI) : .12 * Math.sin((d - 10) / 12 * Math.PI)); }
      return v * 22;
    };
    const end = Math.min(head, x1);
    ctx.save(); ctx.globalCompositeOperation = 'lighter'; ctx.lineWidth = 1.6; ctx.lineJoin = 'round';
    ctx.strokeStyle = 'rgba(255,90,74,.9)'; ctx.shadowColor = '#FF4A3A'; ctx.shadowBlur = 8;
    ctx.beginPath(); ctx.moveTo(x0, y);
    for (let x = x0; x <= end; x += 2) ctx.lineTo(x, y + wave(x));
    ctx.stroke();
    if (head < x1 + 40) glowDot(end, y + wave(end), 2.4, '#FF6B4A', 1);
    else if (Math.floor(tt / 500) % 2) glowDot(x1, y, 2.2, '#FF6B4A', .9);
    ctx.restore();
  }

  // ------------------------------------------------------------------ eventos -> linha do tempo
  const LOG = [];
  function log(t, ev) {
    LOG.unshift(`${(t / 1000).toFixed(2)}s  ${ev.tipo}${ev.slot != null ? ' #' + ev.slot : ''}${ev.cor != null ? ' ' + ELEM[ev.cor] : ''}${ev.dano_parcial ? ' ' + ev.dano_parcial : ''}${ev.cura ? ' +' + ev.cura : ''}${ev.critico ? ' CRIT' : ''}`);
    LOG.length = Math.min(LOG.length, 80);
    hud.log.textContent = LOG.join('\n');
  }

  function play(result, logic) {
    if (!result || result.tipo === 'ignorado') return;
    let c = Math.max(TL.t, TL.cursor);
    const closing = result.n_combos > 0;
    for (const ev of result.eventos) {
      const tc = c; at(tc, 1, { begin: () => log(tc, ev) });
      c = H[ev.tipo] ? H[ev.tipo](ev, c, logic, result) : c;
    }
    TL.cursor = Math.max(c, TL.tail);
    if (closing) TL.busyUntil = TL.cursor;
    at(TL.cursor, 1, { begin: () => updateCombo(logic.zona.length) });
    if (closing) {
      V.stats.combos += result.n_combos; V.stats.dano += result.dano_total || 0;
      V.stats.maiorCadeia = Math.max(V.stats.maiorCadeia, result.n_combos);
      V.stats.criticos += result.eventos.filter((e) => e.tipo === 'combo' && e.critico).length;
    }
    hud.undo.disabled = !logic.podeDesfazer;
    hud.state.textContent = `HP time ${logic.hp}/${logic.hpMax} · alvo ${logic.inimigos[logic.alvo].nome} · inimigos ${logic.inimigos.map((e) => e.hp).join(' / ')} · contadores ${logic.inimigos.map((e) => e.contador).join('/')} · líder ${logic.liderAtivo ? 'ON' : (logic.liderCd ? 'CD ' + logic.liderCd : 'pronto')}`;
  }

  const H = {
    selecao(ev, c) {
      const el = V.hand[ev.slot]; V.hand[ev.slot] = null; V.marked[ev.slot] = el; el._slot = ev.slot;
      const p = slotPos(ev.slot);
      tw(el, c, P.selectMs, { y: p.y - P.liftPx, sc: 1.0 }, E.backOut, { set: { frame: true, ord: ev.ordem }, z: 5 });
      at(c, 1, { begin: () => updateCombo(ev.ordem) });
      sfx('se_touch', c);
      return c + P.selectMs * .5;
    },
    deselecao(ev, c) {
      const el = V.marked[ev.slot]; if (!el) return c; delete V.marked[ev.slot]; V.hand[ev.slot] = el;
      const p = slotPos(ev.slot);
      tw(el, c, P.selectMs, { y: p.y, x: p.x }, E.quadOut, { set: { frame: false, ord: 0 }, z: 1 });
      sfx('se_touch', c, .5);
      const rest = Object.values(V.marked).sort((a, b) => a._s.ord - b._s.ord);
      rest.forEach((m, i) => at(c, 1, { begin() { m._s.ord = i + 1; applyCard(m); } }));
      at(c, 1, { begin: () => updateCombo(rest.length) });
      return c + P.selectMs * .5;
    },
    carta_desce(ev, c) {
      const o = queueOrigin(); const el = makeCard(ev, o, true); el._s.sc = .3; el._s.op = 0; el._slot = ev.slot; V.hand[ev.slot] = el;
      setQueue(ev.fila, c);
      const p = slotPos(ev.slot);
      tw(el, c, P.dropMs, { x: p.x, y: p.y, sc: 1, op: 1 }, E.quadOut, { show: true, z: 3 });
      return c + P.dropMs * .35;
    },
    carta_volta(ev, c) {
      const el = V.hand[ev.slot]; V.hand[ev.slot] = null; if (!el) return c;
      setQueue(ev.fila, c + P.returnMs);
      const o = queueOrigin();
      tw(el, c, P.returnMs, { x: o.x, y: o.y, sc: .3, op: 0 }, E.quadIn, { remove: true });
      return c;
    },
    abandono(ev, c) {
      const els = [...cardLayer.children];
      at(c, 150, { update(p) { const d = Math.sin(p * Math.PI * 4) * 5 * (1 - p); els.forEach((el) => { el.style.marginLeft = d + 'px'; }); }, end() { els.forEach((el) => { el.style.marginLeft = ''; }); } });
      floatText(c, 700, FUSE.x, gridRect.y - 6, 'ABANDONO · TURNO PASSOU', 'tick-red', (el, p, x, y) => { el.style.left = x + 'px'; el.style.top = y + 'px'; el.style.opacity = p < .8 ? 1 : (1 - p) / .2; });
      return c + 80;
    },
    puxa_do_deck(ev, c) {
      const o = queueOrigin(); const el = makeCard(ev, o, true); el._s.sc = .3; el._s.op = 0; V.pulled.push(el);
      setQueue(ev.fila, c);
      return c;
    },
    trio_sobe(ev, c, logic, result) {
      const cor = (ev.cartas.find((x) => x.cor !== 6) || { cor: 6 }).cor;
      const col = colorOf(cor);
      // trio fechado pelo toque = as 3 ja estavam marcadas; senao e trio da cascata
      const marcadas = ev.slots.map((s) => s >= 0 && !!V.marked[s]);
      const els = ev.slots.map((s) => {
        if (s < 0) return V.pulled.shift();
        const el = V.marked[s] || V.hand[s]; delete V.marked[s]; if (V.hand[s] === el) V.hand[s] = null; return el;
      });
      const cascade = marcadas.some((m) => !m);
      let t = c;
      if (cascade && P.cascadeFlashMs > 0) {
        els.forEach((el, i) => { if (!marcadas[i]) tw(el, t, P.cascadeFlashMs, {}, E.lin, { show: true, set: { frame: true }, z: 6, fn: (e, p) => { e.style.outline = `2px solid ${hexA('#F2A33C', Math.abs(Math.sin(p * Math.PI * 2)))}`; }, after: {} }); });
        t += P.cascadeFlashMs;
        els.forEach((el) => at(t, 1, { begin() { el.style.outline = ''; } }));
      }
      // 1) ir ao centro e alinhar
      const gap = CW * P.lineGap;
      els.forEach((el, i) => {
        tw(el, t, P.gatherMs, { x: FUSE.x - CW / 2 + (i - 1) * gap, y: FUSE.y - CH / 2, sc: P.gatherScale, op: 1, rot: 0 }, E.cubicOut, { show: true, set: { frame: false, ord: 0 }, z: 20 });
      });
      t += P.gatherMs + P.holdMs;
      // 2) juntar e fundir, branqueando
      els.forEach((el, i) => {
        tw(el, t, P.mergeMs, { x: FUSE.x - CW / 2, sc: P.gatherScale * .96 }, E.cubicInOut, {
          set: { glowCol: col },
          fn: (e, p) => {
            const w = clamp((p - P.whiteStart) / Math.max(.01, 1 - P.whiteStart), 0, 1);
            e._s.white = E.quadIn(w); e._s.glow = P.glowPx * E.quadOut(p); e._s.valOp = 1 - w;
            e._s.rot = Math.sin(p * Math.PI * 9 + i) * P.wobbleDeg * p;
          },
        });
      });
      t += P.mergeMs;
      // 3) carga
      els.forEach((el, i) => {
        tw(el, t, P.chargeMs, { sc: P.gatherScale * 1.12, rot: 0 }, E.quadIn, {
          set: { white: 1, valOp: 0 },
          fn: (e, p) => { e._s.x = FUSE.x - CW / 2 + Math.sin(p * 60 + i) * P.shakePx; e._s.y = FUSE.y - CH / 2 + Math.cos(p * 53 + i) * P.shakePx; e._s.glow = P.glowPx * (1 + p * .6); },
        });
      });
      t += P.chargeMs;
      // 4) explosao
      els.forEach((el) => tw(el, t, Math.min(160, P.flashMs), { sc: P.gatherScale * 1.7, op: 0 }, E.cubicOut, { remove: true }));
      flash(t, FUSE.x, FUSE.y);
      shock(t, FUSE.x, FUSE.y, col);
      burst(t, FUSE.x, FUSE.y, col, P.particles, P.pSpeedMin, P.pSpeedMax, P.pLifeMs, P.pSize, P.gravity);
      V.lastExplode = t; V.lastColor = cor;
      sfx(cor === 6 ? 'se_wildattack1' : 'se_gousei', t - P.chargeMs * .5);
      return t + Math.min(P.flashMs, 160) + P.betweenTriosMs;
    },
    combo(ev, c) {
      V.chain.push(ev);
      const t0 = V.lastExplode + P.energyDelayMs;
      const targets = [];
      if (ev.todas_as_cores) Object.keys(ev.parciais).forEach((k) => targets.push({ slot: SLOT_OF_COR[k], cor: +k, add: ev.parciais[k] }));
      else if (ev.cor === 5) targets.push({ team: true, cor: 5, add: ev.cura });
      else targets.push({ slot: SLOT_OF_COR[ev.cor], cor: ev.cor, add: ev.dano_parcial });
      let end = t0;
      targets.forEach((tg, ti) => {
        const col = colorOf(tg.cor);
        const to = tg.team ? (() => { const r = rel(part('team_hp_bar')); return { x: r.x + r.w * .5, y: r.y + r.h / 2 }; })() : figPoint(tg.slot, .62);
        for (let k = 0; k < P.orbs; k++) {
          const st = t0 + ti * 40 + k * P.orbStaggerMs;
          orb(st, P.energyMs, FUSE, to, col, P.arcPx, P.orbSize, P.trail);
          end = Math.max(end, st + P.energyMs);
        }
        const arrive = t0 + ti * 40 + P.energyMs;
        burst(arrive, to.x, to.y, col, P.impactParticles, 30, 150, 420, 2, 60);
        if (!tg.team) {
          V.ringVal[tg.slot] = clamp((V.ringVal[tg.slot] ?? 0) + tg.add / P.ringTeto * 100, 0, 100);
          ringTween(tg.slot, arrive, 320, V.ringVal[tg.slot], 1);
          const lvl = clamp((V.ringVal[tg.slot] - ALLY_BASE[tg.slot]) / 40 + .45, .45, 1);
          at(arrive, 1, { begin() { const prev = AURA[tg.slot]; AURA[tg.slot] = { col, from: prev ? prev.from : arrive, level: lvl }; } });
          hop(tg.slot, arrive, P.hopPx);
          const chip = part('chip_' + tg.slot);
          at(arrive, 260, { update(p) { chip.style.scale = String(1 + .16 * Math.sin(p * Math.PI)); }, end() { chip.style.scale = ''; } });
        }
      });
      if (ev.cadeia >= 1 && P.chainLabelMs > 0) {
        floatText(V.lastExplode, P.chainLabelMs, FUSE.x, gridRect.y + 4, `CADEIA ×${ev.cadeia + 1}`, 'tick-amber', (el, p, x, y) => {
          el.style.left = x + 'px'; el.style.top = (y - 10 * E.cubicOut(p)) + 'px'; el.style.opacity = p < .75 ? 1 : (1 - p) / .25; el.style.scale = String(lerp(1.3, 1, E.cubicOut(Math.min(1, p * 4))));
        });
      }
      if (ev.critico) {
        floatText(V.lastExplode, P.chainLabelMs || 600, FUSE.x, FUSE.y - CH * .75, 'CRÍTICO', 'tick-red big', (el, p, x, y) => {
          el.style.left = x + 'px'; el.style.top = (y - 16 * E.cubicOut(p)) + 'px'; el.style.opacity = p < .7 ? 1 : (1 - p) / .3; el.style.scale = String(lerp(1.6, 1, E.backOut(Math.min(1, p * 3))));
        });
      }
      TL.tail = Math.max(TL.tail, end);
      return c;
    },
    renovacao(ev, c) {
      const els = [...Object.values(V.hand), ...Object.values(V.marked)].filter(Boolean);
      V.hand = new Array(12).fill(null);
      els.forEach((el, i) => tw(el, c + i * 12, 220, { y: el._s.y + 40, op: 0 }, E.quadIn, { remove: true }));
      sfx('se_card_shuffle3', c);
      floatText(c, 800, FUSE.x, FUSE.y - 10, 'RENOVAÇÃO', 'tick-amber big', (el, p, x, y) => { el.style.left = x + 'px'; el.style.top = y + 'px'; el.style.opacity = p < .7 ? 1 : (1 - p) / .3; });
      return c + 260;
    },
    nova_carta(ev, c) {
      const p = slotPos(ev.slot);
      if (ev.chuva) {
        const o = queueOrigin(); const el = makeCard(ev, o, true); el._s.sc = .3; el._s.op = 0; el._slot = ev.slot; V.hand[ev.slot] = el;
        setQueue(ev.fila, c);
        tw(el, c, P.rainMs, { x: p.x, y: p.y, sc: 1, op: 1 }, E.quadOut, { show: true, z: 2 });
        return c + P.rainStaggerMs;
      }
      const el = makeCard(ev, { x: p.x, y: p.y - 70 }, true); el._s.op = 0; el._slot = ev.slot; V.hand[ev.slot] = el;
      setQueue(ev.fila, c);
      tw(el, c, 180, { y: p.y, op: 1 }, E.quadOut, { show: true });
      return c + 30;
    },
    entra_na_mao(ev, c) {
      const el = V.hand[ev.de]; if (!el) return c; V.hand[ev.de] = null; V.hand[ev.para] = el; el._slot = ev.para;
      const p = slotPos(ev.para);
      tw(el, c, 160, { x: p.x, y: p.y }, E.quadOut);
      return c + 60;
    },
    redistribuicao(ev, c) {
      c += P.rainMs;
      const olds = V.hand.filter(Boolean);
      const pile = { x: FUSE.x - CW / 2, y: FUSE.y - CH / 2 };
      const r = rnd();
      sfx('se_card_shuffle', c);
      olds.forEach((el, i) => tw(el, c, P.pileMs, { x: pile.x + (r() - .5) * 10, y: pile.y + (r() - .5) * 8, rot: (r() - .5) * 14, sc: .96 }, E.cubicIn, { remove: true }));
      c += P.pileMs;
      V.hand = new Array(12).fill(null);
      ev.mao.forEach((d, s) => {
        if (!d) return;
        const el = makeCard(d, { x: pile.x, y: pile.y }, true); el._s.rot = (r() - .5) * 14; el._s.sc = .96; el._slot = s; V.hand[s] = el;
        const p = slotPos(s); const st = c + s * P.dealStaggerMs;
        tw(el, st, P.dealMs, { x: p.x, y: p.y, rot: 0, sc: 1 }, E.backOut, { show: true, z: 2 });
      });
      setQueue(ev.fila, c);
      return c + 10 * P.dealStaggerMs + P.dealMs;
    },
    ataque_final(ev, c, logic) {
      c = Math.max(c, TL.tail) + P.preFinalMs;
      const tIdx = ev.golpes.length ? ev.golpes[0].inimigo : ev.alvo;
      const tSlot = ENEMY_SLOTS[tIdx];
      const center = figPoint(tSlot, .5);
      const hits = [];
      if (P.perColor) ev.contribuicoes.forEach((k) => hits.push({ cor: k.cor, valor: k.valor, cura: k.cura, critico: false }));
      else ev.combos.forEach((k) => {
        if (k.parciais) Object.keys(k.parciais).forEach((cc) => hits.push({ cor: +cc, valor: k.parciais[cc], critico: k.critico }));
        else hits.push({ cor: k.cor, valor: k.dano_parcial ?? k.cura, cura: k.cor === 5, critico: k.critico });
      });
      const r = rnd();
      let t = c, lastImpact = c;
      const sprite = spriteEl(tSlot);
      hits.forEach((h, i) => {
        const col = colorOf(h.cor);
        if (h.cura) {
          const tb = rel(part('team_hp_text'));
          floatText(t, P.numLifeMs, tb.x + tb.w / 2, tb.y - 4, `+${h.valor}`, 'num', (el, p, x, y) => numAnim(el, p, x, y, 0, col, false));
          t += P.strikeStaggerMs * .6; return;
        }
        const from = figPoint(SLOT_OF_COR[h.cor], .5);
        streak(t, P.strikeMs, from, center, col);
        hop(SLOT_OF_COR[h.cor], t, P.hopPx * .7, 220);
        ringTween(SLOT_OF_COR[h.cor], t, 260, ALLY_BASE[SLOT_OF_COR[h.cor]], 0);
        { const sl = SLOT_OF_COR[h.cor]; at(t, 1, { begin() { delete AURA[sl]; } }); burst(t, from.x, from.y, col, 10, 30, 140, 300, 2, -60); }
        const imp = t + P.strikeMs; lastImpact = imp;
        burst(imp, center.x, center.y, col, 16, 40, 200, 360, 2.2, 40);
        at(imp, 90, { update(p) { sprite.style.filter = `brightness(${1 + 1.2 * (1 - p)})`; }, end() { sprite.style.filter = ''; } });
        shakeEl(sprite, imp, 170, P.hitShakePx);
        const ang = r() * Math.PI * 2, rad = Math.sqrt(r());
        const VR = rel(part('visor'));
        const nx = clamp(center.x + Math.cos(ang) * P.numRx * rad, VR.x + 24, VR.x + VR.w - 24), ny = clamp(center.y - 10 + Math.sin(ang) * P.numRy * rad, VR.y + 40, VR.y + VR.h - 20);
        const drift = (r() - .5) * 2 * P.numDrift, rise = P.numRise * lerp(.8, 1.8, r());
        floatText(imp, P.numLifeMs, nx, ny, `${h.valor}${h.critico ? '!' : ''}`, 'num' + (h.critico ? ' crit' : ''), (el, p, x, y) => numAnim(el, p, x, y, 1, col, h.critico, drift, rise, center));
        t += P.strikeStaggerMs;
      });
      ev.golpes.forEach((g) => { const e = logic.inimigos[g.inimigo]; ringTween(ENEMY_SLOTS[g.inimigo], lastImpact, 420, Math.round(g.hp / e.max * 100)); });
      if (ev.dano_total > 0 && P.showTotal) {
        floatText(lastImpact + 180, 1300, clamp(center.x, 70, 442), footPoint(tSlot).y - 34, `<span class="tick">TOTAL</span><b>−${ev.dano_total}</b>`, 'total', (el, p, x, y) => {
          el.style.left = x + 'px'; el.style.top = (y - 18 * E.cubicOut(p)) + 'px'; el.style.scale = String(lerp(1.5, 1, E.backOut(Math.min(1, p * 3.2)))); el.style.opacity = p < .78 ? 1 : (1 - p) / .22;
        });
      }
      if (ev.lider) {
        floatText(lastImpact + 120, 1300, clamp(center.x, 70, 442), footPoint(tSlot).y - 74, `♛ LÍDER ×${window.ComboLogic.LIDER_BONUS}`, 'tick-amber lead', (el, p, x, y) => {
          el.style.left = x + 'px'; el.style.top = (y - 12 * E.cubicOut(p)) + 'px'; el.style.scale = String(lerp(1.4, 1, E.backOut(Math.min(1, p * 3.2)))); el.style.opacity = p < .78 ? 1 : (1 - p) / .22;
        });
      }
      if (ev.cura_total > 0) teamTween(c, 400, ev.hp_antes, ev.hp_jogador, logic.hpMax);
      ev.inimigos.forEach((e, i) => { if (!e.vivo) at(lastImpact + 300, 1, { begin: () => setDead(i, true) }); });
      at(lastImpact + 200, 1, { begin: () => moveAim(logic.alvo) });
      for (const k in V.ringVal) V.ringVal[k] = ALLY_BASE[k];
      V.chain = [];
      TL.tail = 0;
      return lastImpact + 380 + (P.showTotal ? 500 : 0);
    },
    turno_inimigo(ev, c) {
      at(c, 1, { begin() { ev.contadores.forEach((x, i) => setTurn(i, x.contador, x.vivo)); } });
      return c + 60;
    },
    ataque_inimigo(ev, c, logic) {
      const slot = ENEMY_SLOTS[ev.inimigo]; const sp = spriteEl(slot);
      at(c, P.enemyAtkMs, { update(p) { const k = p < .35 ? E.quadOut(p / .35) : 1 - E.quadIn((p - .35) / .65); sp.style.transform = `translateX(${-P.enemyLungePx * k}px)`; }, end() { sp.style.transform = ''; } });
      const hit = c + P.enemyAtkMs * .35;
      const visor = part('visor'); shakeEl(visor, hit, 180, 3);
      const hpBefore = ev.hp_jogador + ev.dano;
      teamTween(hit, 380, hpBefore, ev.hp_jogador, logic.hpMax);
      const bar = part('team_hp_bar');
      at(hit, 260, { update(p) { bar.style.boxShadow = `0 0 ${14 * (1 - p)}px rgba(255,107,74,${1 - p})`; }, end() { bar.style.boxShadow = ''; } });
      const tb = rel(part('team_hp_text'));
      floatText(hit, P.numLifeMs, tb.x + tb.w / 2, tb.y - 6, `−${ev.dano}`, 'num', (el, p, x, y) => numAnim(el, p, x, y, 1, '#FF6B4A', false, 0, P.numRise * .7));
      return c + P.enemyAtkMs + 120;
    },
    fim(ev, c) {
      playEnd(ev.resultado, c + P.endDelayMs);
      return c + P.endDelayMs;
    },
    lider(ev, c) {
      const b = rel(leaderBtn), from = { x: b.x + b.w / 2, y: b.y + b.h / 2 };
      at(c, 1, { begin() { setLeader(ev.ativo, 0); V.leaderOn = ev.ativo; V.leaderFrom = c; } });
      at(c, 320, { update(p) { leaderBtn.style.scale = String(1 + .35 * Math.sin(p * Math.PI) * (1 - p * .3)); }, end() { leaderBtn.style.scale = ''; } });
      if (!ev.ativo) {
        floatText(c, 700, 256, from.y - 18, 'LIDERANÇA CANCELADA', 'tick-amber', (el, p, x, y) => { el.style.left = x + 'px'; el.style.top = y + 'px'; el.style.opacity = p < .7 ? 1 : (1 - p) / .3; });
        return c + 120;
      }
      sfx('se_arrart2', c);
      flash(c, from.x, from.y); shock(c, from.x, from.y, '#FFD36A');
      burst(c, from.x, from.y, '#FFD36A', 34, 60, 260, 520, 2.4, 60);
      ALLY_SLOTS.forEach((slot, i) => {
        const to = figPoint(slot, .62);
        for (let k = 0; k < P.leaderOrbs; k++) orb(c + 80 + i * 45 + k * 60, P.leaderMs * .8, from, to, '#FFD36A', P.arcPx * .8, P.orbSize * .9, P.trail);
        const arrive = c + 80 + i * 45 + P.leaderMs * .8;
        burst(arrive, to.x, to.y, '#FFD36A', 10, 30, 130, 380, 2, -40);
        hop(slot, arrive, P.hopPx * 1.2);
      });
      floatText(c + 60, P.leaderMs + 900, 256, from.y - 22, `♛ LIDERANÇA · +${Math.round((ev.bonus - 1) * 100)}% NESTA CORRENTE`, 'tick-amber lead', (el, p, x, y) => {
        el.style.left = x + 'px'; el.style.top = (y - 8 * E.cubicOut(p)) + 'px'; el.style.scale = String(lerp(1.5, 1, E.backOut(Math.min(1, p * 4)))); el.style.opacity = p < .8 ? 1 : (1 - p) / .2;
      });
      return c + P.leaderMs;
    },
    lider_recarga(ev, c) {
      shakeEl(leaderBtn, c, 260, 3);
      floatText(c, 800, 256, rel(leaderBtn).y - 18, `LIDERANÇA RECARREGA · ${ev.cd} ${ev.cd > 1 ? 'CORRENTES' : 'CORRENTE'}`, 'tick-red', (el, p, x, y) => { el.style.left = x + 'px'; el.style.top = y + 'px'; el.style.opacity = p < .7 ? 1 : (1 - p) / .3; });
      return c + 60;
    },
    lider_estado(ev, c) {
      at(Math.max(c, TL.tail), 1, { begin() { setLeader(ev.ativo, ev.cd); V.leaderOn = ev.ativo; } });
      return c;
    },
  };
  function figWidth(slot) { return rel(figEl(slot)).w; }
  function numAnim(el, p, x, y, dir, col, crit, drift = 0, rise = P.numRise, origin = null) {
    const popT = Math.min(1, p / .18);
    const s = p < .18 ? lerp(.35, P.numPop, E.cubicOut(popT)) : lerp(P.numPop, 1, E.cubicOut(Math.min(1, (p - .18) / .2)));
    // salto: sai do centro do inimigo, faz um arco ate o ponto sorteado e depois sobe
    const j = origin ? clamp(p / Math.max(.01, P.numJump), 0, 1) : 1;
    const bx = origin ? lerp(origin.x, x, E.quadOut(j)) : x;
    const by = origin ? lerp(origin.y, y, E.quadOut(j)) - Math.sin(j * Math.PI) * P.numHop : y;
    const rp = origin ? clamp((p - P.numJump) / Math.max(.01, 1 - P.numJump), 0, 1) : p;
    el.style.left = (bx + drift * E.quadOut(rp)) + 'px';
    el.style.top = (by - rise * E.cubicOut(rp)) + 'px';
    el.style.scale = String(s * (crit ? P.critScale : 1));
    el.style.opacity = p < .65 ? 1 : (1 - p) / .35;
    el.style.color = col; el.style.fontSize = P.numSize + 'px';
  }

  // ------------------------------------------------------------------ jogo
  let logic;
  let chainStart = null;
  function snapshotFull(l) {
    return JSON.stringify({ l: l.snapshot(), alvo: l.alvo, bag: { cartas: l.bag.cartas, pos: l.bag.pos } });
  }
  function restoreFull(json) {
    const s = JSON.parse(json);
    const l = new Logic({ seed: 1 });
    Object.assign(l, s.l); l.alvo = s.alvo; l.bag.cartas = s.bag.cartas; l.bag.pos = s.bag.pos; l.snapshots = [];
    return l;
  }
  let lastPreset = null;
  function newGame(preset) {
    lastPreset = preset;
    V.stats = newStats();
    const p = preset && PRESETS[preset];
    logic = p ? new Logic({ seed: 42, mao: p.mao, fila: p.fila }) : new Logic({});
    TL.cursor = TL.t; TL.busyUntil = 0; TL.tail = 0;
    chainStart = null;
    rebuild(logic);
    hud.hint.textContent = p ? `Toques sugeridos (casas): ${p.toques.join(', ')} — casas 10 e 11 são as de entrada.` : 'Mão aleatória da BAG.';
    play({ tipo: 'jogada', eventos: [], n_combos: 0 }, logic);
  }
  function onCardTap(el) {
    if (TL.t < TL.busyUntil || END.active) return;
    const markedSlot = Object.keys(V.marked).find((k) => V.marked[k] === el);
    if (!logic.zona.length) chainStart = { json: snapshotFull(logic), taps: [] };
    let r;
    if (markedSlot != null) { r = logic.desmarcar(+markedSlot); chainStart && chainStart.taps.push(['desmarcar', +markedSlot]); }
    else {
      const slot = V.hand.indexOf(el); if (slot < 0) return;
      r = logic.tocar(slot); chainStart && chainStart.taps.push(['tocar', slot]);
    }
    play(r, logic);
    if (r.n_combos > 0) hud.replay.disabled = false;
  }
  function tapSlot(slot) { const el = V.marked[slot] || V.hand[slot]; if (el) onCardTap(el); }
  function replay() {
    if (!chainStart) return;
    const saved = chainStart;
    logic = restoreFull(saved.json); rebuild(logic); TL.cursor = TL.t; TL.busyUntil = 0; TL.tail = 0;
    let delay = 0;
    saved.taps.forEach(([fn, slot]) => { setTimeout(() => { const r = logic[fn](slot); play(r, logic); }, delay); delay += 380 / TL.speed; });
    chainStart = saved;
  }

  if (leaderBtn) leaderBtn.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    if (TL.t < TL.busyUntil || END.active) return;
    play(logic.alternarLider(), logic);
  });

  // alvo: toque no inimigo
  ROOT.querySelectorAll('[data-part="visor"] > button[data-loop="enemies"]').forEach((b) => {
    b.addEventListener('pointerdown', () => { const i = +b.getAttribute('data-i'); if (!logic.inimigos[i].vivo) return; logic.alvo = i; moveAim(i); });
  });

  // ------------------------------------------------------------------ painel
  const hud = {};
  function buildPanel() {
    const pan = document.getElementById('lab-panel');
    pan.innerHTML = `
      <div class="pn-title">Laboratório de combo <span class="tick">ILHA DIGITAL · TERMINAL</span></div>
      <div class="pn-row"><span class="tick">TEMPO</span><b id="lab-clock" class="mono">0.00s</b></div>
      <div class="pn-btns">
        <button id="b-pause">Pausar</button><button id="b-step">+1 quadro</button>
        <label class="spd">velocidade <input id="b-speed" type="range" min="0.05" max="2" step="0.05" value="1"><span id="b-speed-v" class="mono">1.00×</span></label>
      </div>
      <div class="pn-sec">Mão de teste</div>
      <div class="pn-btns">
        <select id="b-preset">${Object.entries(PRESETS).map(([k, v]) => `<option value="${k}">${v.nome}</option>`).join('')}</select>
        <button id="b-apply">Aplicar</button><button id="b-auto">Aplicar e jogar</button>
      </div>
      <div class="pn-btns"><button id="b-random">Mão aleatória (BAG)</button><button id="b-undo">Desfazer</button><button id="b-replay" disabled>Repetir última corrente</button></div>
      <div class="pn-btns"><button id="b-win">Testar vitória</button><button id="b-lose">Testar derrota</button><button id="b-lead">Ativar líder</button></div>
      <div id="lab-hint" class="pn-hint"></div>
      <div id="lab-state" class="pn-hint mono"></div>
      <div class="pn-sec">Tom das cartas <span class="tick">prévia · filtro sobre a arte atual</span></div>
      <div id="lab-tone"></div>
      <div class="pn-sec">Parâmetros <span class="tick">salvos neste navegador</span></div>
      <div id="lab-params"></div>
      <div class="pn-btns"><button id="b-reset">Restaurar padrão</button><button id="b-export">Exportar JSON</button><button id="b-copy">Copiar</button></div>
      <textarea id="lab-json" class="mono" rows="6" readonly></textarea>
      <div class="pn-sec">Eventos da lógica</div>
      <pre id="lab-log" class="mono"></pre>`;
    hud.clock = pan.querySelector('#lab-clock'); hud.log = pan.querySelector('#lab-log'); hud.hint = pan.querySelector('#lab-hint');
    hud.state = pan.querySelector('#lab-state'); hud.undo = pan.querySelector('#b-undo'); hud.replay = pan.querySelector('#b-replay');
    const params = pan.querySelector('#lab-params');
    SCHEMA.forEach(([g, rows], gi2) => {
      const d = document.createElement('details'); if (gi2 === 1 || gi2 === 5) d.open = true;
      d.innerHTML = `<summary>${g}</summary>`;
      rows.forEach(([k, label, mn, mx, st]) => {
        const row = document.createElement('label'); row.className = 'pr';
        row.innerHTML = `<span>${label}</span><input type="range" min="${mn}" max="${mx}" step="${st}" value="${P[k]}"><b class="mono">${P[k]}</b>`;
        const inp = row.querySelector('input'), out = row.querySelector('b');
        inp.addEventListener('input', () => { P[k] = +inp.value; out.textContent = inp.value; saveP(); });
        row._sync = () => { inp.value = P[k]; out.textContent = P[k]; };
        d.appendChild(row);
      });
      params.appendChild(d);
    });
    const $ = (id) => pan.querySelector(id);
    $('#b-pause').onclick = () => { TL.paused = !TL.paused; $('#b-pause').textContent = TL.paused ? 'Continuar' : 'Pausar'; };
    $('#b-step').onclick = () => { TL.paused = true; $('#b-pause').textContent = 'Continuar'; TL.t += 1000 / 60; tick(TL.t); };
    $('#b-speed').oninput = (e) => { TL.speed = +e.target.value; $('#b-speed-v').textContent = TL.speed.toFixed(2) + '×'; };
    $('#b-apply').onclick = () => newGame($('#b-preset').value);
    $('#b-auto').onclick = () => { const k = $('#b-preset').value; newGame(k); PRESETS[k].toques.forEach((s, i) => setTimeout(() => tapSlot(s), 350 + i * 380 / TL.speed)); };
    $('#b-random').onclick = () => newGame(null);
    $('#b-undo').onclick = () => { if (TL.t < TL.busyUntil) return; if (logic.desfazer()) { rebuild(logic); play({ tipo: 'jogada', eventos: [], n_combos: 0 }, logic); } };
    $('#b-replay').onclick = replay;
    $('#b-win').onclick = () => { playEnd('vitoria', TL.t); };
    $('#b-lose').onclick = () => { playEnd('derrota', TL.t); };
    $('#b-lead').onclick = () => { if (TL.t >= TL.busyUntil && !END.active) play(logic.alternarLider(), logic); };
    $('#b-reset').onclick = () => { P = { ...DEFAULTS }; saveP(); params.querySelectorAll('.pr').forEach((r) => r._sync()); };
    const exportJson = () => JSON.stringify({ animacao: P, tom_cartas: toneChanged() }, null, 1);
    $('#b-export').onclick = () => { $('#lab-json').value = exportJson(); };
    $('#b-copy').onclick = async () => { $('#lab-json').value = exportJson(); try { await navigator.clipboard.writeText($('#lab-json').value); $('#b-copy').textContent = 'Copiado'; } catch (e) { $('#lab-json').select(); } setTimeout(() => { $('#b-copy').textContent = 'Copiar'; }, 1200); };
  }

  // ------------------------------------------------------------------ tom das cartas
  // Filtro CSS sobre a arte (matiz / saturacao / brilho). Serve para achar o tom; o valor final
  // e aplicado de verdade no gerador (cards/build_cards.py, tabela PAL) e as PNGs sao reexportadas.
  const TONE_KEY = 'ilhaDigital.comboLab.tone.v1';
  const TONE = {}; ELEM.forEach((e) => { TONE[e] = { h: 0, s: 1, b: 1 }; });
  try { const t = JSON.parse(localStorage.getItem(TONE_KEY) || '{}'); for (const e in t) if (TONE[e]) Object.assign(TONE[e], t[e]); } catch (e) { /* sem storage */ }
  const toneStyle = document.createElement('style'); document.head.appendChild(toneStyle);
  function applyTone() {
    toneStyle.textContent = ELEM.map((e) => { const t = TONE[e];
      return `[data-el="${e}"] img { filter: hue-rotate(${t.h}deg) saturate(${t.s}) brightness(${t.b}); }`; }).join('\n');
    try { localStorage.setItem(TONE_KEY, JSON.stringify(TONE)); } catch (e) { /* ignore */ }
  }
  function toneChanged() { const o = {}; for (const e in TONE) { const t = TONE[e]; if (t.h || t.s !== 1 || t.b !== 1) o[e] = { ...t }; } return o; }
  function buildTone() {
    const box = document.getElementById('lab-tone'); let cur = 'light';
    box.innerHTML = `<div class="tone-row">${ELEM.map((e) => `<button class="tone-card" data-el="${e}" data-pick="${e}" title="${e}"><img src="${IMG[e]}"><span class="tick">${e}</span></button>`).join('')}</div>
      <div class="tone-ctl"></div>`;
    const ctl = box.querySelector('.tone-ctl');
    const rows = [['h', 'Matiz (graus)', -60, 60, 1], ['s', 'Saturação', 0.3, 1.8, 0.02], ['b', 'Brilho', 0.5, 1.6, 0.02]];
    function draw() {
      box.querySelectorAll('.tone-card').forEach((b) => b.classList.toggle('on', b.dataset.pick === cur));
      ctl.innerHTML = rows.map(([k, l, mn, mx, st]) => `<label class="pr"><span>${cur} · ${l}</span><input type="range" min="${mn}" max="${mx}" step="${st}" value="${TONE[cur][k]}" data-k="${k}"><b class="mono">${TONE[cur][k]}</b></label>`).join('')
        + `<div class="pn-btns"><button data-reset>Zerar ${cur}</button></div>`;
      ctl.querySelectorAll('input').forEach((i) => i.addEventListener('input', () => { TONE[cur][i.dataset.k] = +i.value; i.nextElementSibling.textContent = i.value; applyTone(); }));
      ctl.querySelector('[data-reset]').onclick = () => { TONE[cur] = { h: 0, s: 1, b: 1 }; applyTone(); draw(); };
    }
    box.querySelectorAll('.tone-card').forEach((b) => { b.onclick = () => { cur = b.dataset.pick; draw(); }; });
    draw(); applyTone();
  }

  // ------------------------------------------------------------------ escala da tela
  function fit() {
    const wrap = document.getElementById('lab-wrap');
    const avail = Math.max(320, window.innerHeight - 24);
    K = Math.min(1.35, avail / 800);
    if (window.innerWidth < 900) K = Math.min(K, (window.innerWidth - 16) / 512);
    if (SNAP) K = window.innerWidth / 512;
    STAGE.style.transform = `scale(${K})`;
    wrap.style.width = 512 * K + 'px'; wrap.style.height = 800 * K + 'px';
    sizeCanvas();
    if (TL.paused && hud.clock) tick(TL.t); // redimensionar o canvas limpa o desenho
  }

  // ------------------------------------------------------------------ inicio
  const hash = new URLSearchParams(location.hash.slice(1));
  const SNAP = hash.get('snap') != null;
  buildPanel();
  buildTone();
  fit(); window.addEventListener('resize', fit);
  if (hash.get('snap') != null) {
    // modo captura: joga a mao de teste em tempo simulado e congela no instante pedido
    const preset = hash.get('demo') || 'vermelho_roxo'; const T = +hash.get('snap');
    Object.keys(DEFAULTS).forEach((k) => { if (hash.get(k) != null) P[k] = +hash.get(k); });
    TL.paused = true; newGame(preset);
    if (hash.get('lead') != null) { TL.t = 100; tick(TL.t); play(logic.alternarLider(), logic); }
    if (hash.get('end')) { TL.t = 150; tick(TL.t); playEnd(hash.get('end'), 150); }
    const gap = +(hash.get('gap') || 380);
    const taps = PRESETS[preset].toques.map((s, i) => ({ t: 200 + i * gap, s }));
    for (const tp of taps) { if (tp.t > T) break; TL.t = tp.t; tick(TL.t); TL.busyUntil = 0; tapSlot(tp.s); TL.busyUntil = 0; }
    TL.t = T; tick(T);
    document.body.dataset.canvas = String(canvas.toDataURL().length);
    document.body.classList.add('snap');
  } else {
    newGame('vermelho_roxo');
    requestAnimationFrame((n) => { last = n; loop(n); });
  }
  window.LAB = { TL, P, get logic() { return logic; }, tick, newGame, tapSlot };
}
(function () {
  const go = () => { if (!window.__labBooted) { window.__labBooted = true; bootLab(); } };
  Promise.race([document.fonts ? document.fonts.ready : Promise.resolve(), new Promise((r) => setTimeout(r, 1200))]).then(go, go);
})();
