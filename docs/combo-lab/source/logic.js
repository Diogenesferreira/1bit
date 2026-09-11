/* Porta da regra de C:/Users/Jinsa/OneDrive/Meus Documentos/heroes/scripts/BattleLogic.gd + Bag.gd
 * para o laboratorio de animacao. Mesmos nomes de evento e mesmos campos.
 * Diferencas de adaptacao ao layout Terminal (documentadas em COMBO_E_ANIMACOES.md):
 *  - 3 inimigos, cada um com seu contador; o dano final vai para o ALVO selecionado (excedente passa ao proximo vivo)
 *  - valores de HP/ataque dos inimigos iguais aos do mockup
 * Corrigido pelo que foi lido no binario (heroes/docideias/mecanica-do-binario.md), a frente do BattleLogic.gd:
 *  - cascata escolhe a cor por contagem % 3, desempate pela nota de critico
 *  - coringa substitui valor para formar trinca no critico
 *  - defesa reduz em porcentagem (curva estimada)
 */
(function (global) {
  const COR = { VERMELHO: 0, AZUL: 1, VERDE: 2, AMARELO: 3, ROXO: 4, CURA: 5, CORINGA: 6 };
  const ELEM = ['dragon', 'knight', 'nature', 'light', 'dark', 'capsule', 'wild'];
  const CORES_ATAQUE = [0, 1, 2, 3, 4];
  const ROW_SIZE = 5, NUM_ROWS = 2, TAMANHO_MAO = 10, ENTRADA_0 = 10, ENTRADA_1 = 11, QTD_PROXIMAS = 9;
  const FRACAO_TRIO_CORINGA = 1.0;
  const LIDER_BONUS = 1.25, LIDER_CD = 3;
  // ESTIMATIVA: o original interpola uma tabela de degraus (MasterTable_BattleDamageReduction) que veio do servidor e se perdeu
  const DEF_K = 100;
  const reducaoDefesa = (def) => Math.min(Math.max(def / (def + DEF_K), 0), 1);

  function rng32(seed) {
    let a = seed >>> 0;
    return function () { a |= 0; a = a + 0x6D2B79F5 | 0; let t = Math.imul(a ^ a >>> 15, 1 | a); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; };
  }
  const combina = (a, b) => a === b || a === COR.CORINGA || b === COR.CORINGA;
  const carta = (cor, valor) => ({ cor, valor });

  class Bag {
    constructor(rand) { this.r = rand; this.cartas = []; this.pos = 0; this.encher(); }
    ri(a, b) { return a + Math.floor(this.r() * (b - a + 1)); }
    comprar() { if (this.pos >= this.cartas.length) this.encher(); return this.cartas[this.pos++]; }
    encher() {
      const T = 100; this.cartas = new Array(T).fill(null); this.pos = 0;
      const ocupadas = {};
      const espalhar = (cor, qtd) => {
        const faixa = T / qtd;
        for (let i = 0; i < qtd; i++) {
          const ini = Math.floor(i * faixa), fim = Math.max(ini, Math.min(Math.floor((i + 1) * faixa), T) - 1);
          let p = this.ri(ini, fim), tent = 0;
          while (ocupadas[p] && tent < T) { p = (p + 1) % T; tent++; }
          ocupadas[p] = true; this.cartas[p] = carta(cor, this.ri(1, 9));
        }
      };
      espalhar(COR.CORINGA, 8); espalhar(COR.CURA, 12);
      const ataque = [];
      for (const c of CORES_ATAQUE) for (let i = 0; i < 16; i++) ataque.push(carta(c, this.ri(1, 9)));
      for (let i = ataque.length - 1; i > 0; i--) { const j = this.ri(0, i); [ataque[i], ataque[j]] = [ataque[j], ataque[i]]; }
      let k = 0; for (let i = 0; i < T; i++) if (!this.cartas[i]) this.cartas[i] = ataque[k++];
      let rep = 1;
      for (let i = 1; i < T; i++) {
        if (this.cartas[i].cor !== this.cartas[i - 1].cor) { rep = 1; continue; }
        rep++; if (rep <= 3) continue;
        for (let j = i + 1; j < T; j++) {
          if (this.cartas[j].cor === this.cartas[i].cor) continue;
          if (this.cartas[j - 1].cor === this.cartas[i].cor) continue;
          [this.cartas[i], this.cartas[j]] = [this.cartas[j], this.cartas[i]]; break;
        }
        rep = 1;
      }
    }
  }

  class Logic {
    constructor(opts = {}) {
      this.rand = rng32(opts.seed ?? (Date.now() & 0xffffffff));
      this.bag = new Bag(this.rand);
      // aliado por cor (ataque do BattleLogic original)
      this.time = {
        0: { slot: 'A1', nome: 'Crimson Clamp', ataque: 38 }, 1: { slot: 'A3', nome: 'Panda Gunner', ataque: 36 },
        2: { slot: 'A5', nome: 'Flora Fairy', ataque: 34 }, 3: { slot: 'A4', nome: 'Twin Apes', ataque: 40 },
        4: { slot: 'A2', nome: 'Bone Raider', ataque: 42 },
      };
      this.inimigos = [
        { slot: 'E1', nome: 'Long Ear Guardian', hp: 1850, max: 4000, defesa: 18, dano: 220, contador: 2, contadorMax: 3, vivo: true },
        { slot: 'E2', nome: 'Dusk Dragon', hp: 1200, max: 1200, defesa: 12, dano: 130, contador: 1, contadorMax: 3, vivo: true },
        { slot: 'E3', nome: 'Twin Tail', hp: 1400, max: 1400, defesa: 12, dano: 150, contador: 3, contadorMax: 3, vivo: true },
      ];
      this.alvo = 0;
      this.liderAtivo = false; this.liderCd = 0;
      this.hpMax = 3200; this.hp = 2840;
      this.mao = []; this.proximas = []; this.zona = []; this.zonaSlots = []; this.zonaDescidas = [];
      this.snapshots = []; this.fim = false; this.vitoria = false; this.saidasForcadas = 0;
      if (opts.mao) {
        this.mao = opts.mao.map((c) => c ? { ...c } : null);
        while (this.mao.length < TAMANHO_MAO) this.mao.push(this.bag.comprar());
      } else {
        for (let i = 0; i < TAMANHO_MAO; i++) this.mao.push(this.bag.comprar());
        this.garantirSaida(this.mao);
        this.mao.sort(Logic.antesDe);
      }
      this.mao.push(null, null);
      const fila = (opts.fila || []).map((c) => ({ ...c }));
      while (fila.length < QTD_PROXIMAS) fila.push(this.bag.comprar());
      this.proximas = fila;
      this.filaExtra = (opts.filaExtra || []).map((c) => ({ ...c }));
    }
    static antesDe(a, b) { return a.cor !== b.cor ? a.cor - b.cor : a.valor - b.valor; }
    ri(a, b) { return a + Math.floor(this.rand() * (b - a + 1)); }
    comprar() {
      const c = this.proximas.shift();
      this.proximas.push(this.filaExtra.length ? this.filaExtra.shift() : this.bag.comprar());
      return c;
    }
    foto() { return this.proximas.map((c) => ({ cor: c.cor, valor: c.valor })); }
    static corDoTrio(cartas) { for (const c of cartas) if (c.cor !== COR.CORINGA) return c.cor; return COR.CORINGA; }
    corZona() { return this.zona.length ? Logic.corDoTrio(this.zona) : -1; }
    linhaDe(i) { return i < TAMANHO_MAO ? Math.floor(i / ROW_SIZE) : i - TAMANHO_MAO; }

    snapshot() {
      return JSON.parse(JSON.stringify({ mao: this.mao, proximas: this.proximas, zona: this.zona, zonaSlots: this.zonaSlots, zonaDescidas: this.zonaDescidas,
        inimigos: this.inimigos, hp: this.hp, filaExtra: this.filaExtra, liderAtivo: this.liderAtivo, liderCd: this.liderCd }));
    }
    desfazer() {
      if (!this.snapshots.length) return false;
      Object.assign(this, this.snapshots.pop());
      return true;
    }
    get podeDesfazer() { return this.snapshots.length > 0; }

    novoResultado() { return { tipo: 'jogada', eventos: [], n_combos: 0, dano_total: 0, cura_total: 0 }; }

    alternarLider() {
      if (this.fim) return { tipo: 'ignorado' };
      const r = this.novoResultado();
      if (this.liderCd > 0) { r.eventos.push({ tipo: 'lider_recarga', cd: this.liderCd }); return r; }
      this.liderAtivo = !this.liderAtivo;
      r.eventos.push({ tipo: 'lider', ativo: this.liderAtivo, bonus: LIDER_BONUS });
      return r;
    }
    avancarLider(r) {
      this.liderCd = this.liderAtivo ? LIDER_CD : Math.max(0, this.liderCd - 1);
      this.liderAtivo = false;
      r.eventos.push({ tipo: 'lider_estado', ativo: false, cd: this.liderCd });
    }

    desmarcar(slot) {
      const pos = this.zonaSlots.indexOf(slot);
      if (this.fim || pos === -1) return { tipo: 'ignorado' };
      const snap = this.snapshot();
      const r = this.novoResultado();
      this.devolverMarcada(pos, r);
      this.snapshots.push(snap);
      return r;
    }
    descerCarta(l, r) {
      const cand = l === 0 ? [ENTRADA_0, ENTRADA_1] : [ENTRADA_1, ENTRADA_0];
      for (const s of cand) {
        if (this.mao[s] === null && !this.zonaSlots.includes(s)) {
          const nova = this.comprar(); this.mao[s] = nova;
          r.eventos.push({ tipo: 'carta_desce', slot: s, cor: nova.cor, valor: nova.valor, fila: this.foto() });
          return s;
        }
      }
      return -1;
    }
    devolverMarcada(pos, r) {
      const slot = this.zonaSlots[pos], c = this.zona[pos], desc = this.zonaDescidas[pos];
      if (desc !== -1 && this.mao[desc] !== null) {
        this.proximas.pop(); this.proximas.unshift(this.mao[desc]); this.mao[desc] = null;
        r.eventos.push({ tipo: 'carta_volta', slot: desc, fila: this.foto() });
      }
      this.mao[slot] = c;
      this.zona.splice(pos, 1); this.zonaSlots.splice(pos, 1); this.zonaDescidas.splice(pos, 1);
      r.eventos.push({ tipo: 'deselecao', slot, cor: c.cor, valor: c.valor });
    }
    abandonar(r) {
      r.eventos.push({ tipo: 'abandono' });
      for (let p = this.zona.length - 1; p >= 0; p--) this.devolverMarcada(p, r);
    }

    tocar(idx) {
      if (this.fim || idx < 0 || idx >= this.mao.length || this.mao[idx] === null) return { tipo: 'ignorado' };
      const snap = this.snapshot();
      const r = this.novoResultado();
      const acum = {}; const acumCombos = [];
      if (this.zona.length && !combina(this.mao[idx].cor, this.corZona())) this.abandonar(r);
      if (this.mao[idx] !== null) {
        const c = this.mao[idx];
        this.zona.push(c); this.zonaSlots.push(idx); this.mao[idx] = null;
        r.eventos.push({ tipo: 'selecao', slot: idx, cor: c.cor, valor: c.valor, ordem: this.zona.length });
        if (this.zona.length >= 3) {
          this.zonaDescidas.push(-1);
          this.fecharTrio(r, acum, acumCombos);
          this.faseCascata(r, acum, acumCombos);
          this.completarMao(r);
        } else {
          this.zonaDescidas.push(this.descerCarta(this.linhaDe(idx), r));
        }
      }
      this.resolverAtaqueFinal(r, acum, acumCombos);
      if (r.n_combos > 0) this.avancarLider(r);
      this.turnoInimigo(r);
      if (r.n_combos > 0) this.snapshots = []; else this.snapshots.push(snap);
      return r;
    }

    fecharTrio(r, acum, acumCombos) {
      const cartas = this.zona.map((c) => ({ cor: c.cor, valor: c.valor }));
      const vazios = this.zonaSlots.filter((s) => s >= 0 && this.mao[s] === null);
      r.eventos.push({ tipo: 'trio_sobe', slots: this.zonaSlots.slice(), cartas, vazios });
      this.zonaSlots = []; this.zonaDescidas = [];
      this.dispararZona(r, acum, acumCombos);
    }

    faseCascata(r, acum, acumCombos) {
      for (let guard = 0; guard < 60; guard++) {
        const plano = this.melhorTrio();
        if (plano) {
          for (const i of plano.slots) { this.zona.push(this.mao[i]); this.zonaSlots.push(i); this.zonaDescidas.push(-1); this.mao[i] = null; }
          if (plano.usaDeck) {
            const p = this.comprar();
            this.zona.push(p); this.zonaSlots.push(-1); this.zonaDescidas.push(-1);
            r.eventos.push({ tipo: 'puxa_do_deck', cor: p.cor, valor: p.valor, fila: this.foto() });
          }
          this.fecharTrio(r, acum, acumCombos);
          continue;
        }
        const restantes = this.mao.filter((c) => c !== null).length;
        if (restantes > 1) break;
        r.eventos.push({ tipo: 'renovacao' });
        this.mao[ENTRADA_0] = null; this.mao[ENTRADA_1] = null;
        for (let i = 0; i < TAMANHO_MAO; i++) {
          const n = this.comprar(); this.mao[i] = n;
          r.eventos.push({ tipo: 'nova_carta', slot: i, cor: n.cor, valor: n.valor, fila: this.foto() });
        }
      }
    }

    maoPorCor() {
      const porCor = {}, coringas = [];
      this.mao.forEach((c, i) => {
        if (!c) return;
        if (c.cor === COR.CORINGA) coringas.push(i); else (porCor[c.cor] = porCor[c.cor] || []).push(i);
      });
      return { porCor, coringas };
    }

    // ChkChainCritical do original: nota, nao sim/nao (trinca = valor*10, sequencia ~ valor do meio*3, par 1-2 = 6)
    notaCritico(cor) {
      const cnt = new Array(11).fill(0); let w = 0;
      this.mao.forEach((c) => { if (!c) return; if (c.cor === COR.CORINGA) w++; else if (c.cor === cor) cnt[c.valor]++; });
      let nota = 0;
      for (let v = 1; v <= 9; v++) if (cnt[v] > 0 && cnt[v] + w >= 3) nota = Math.max(nota, v * 10);
      for (let v = 2; v <= 8; v++) if (cnt[v - 1] && cnt[v] && cnt[v + 1]) nota = Math.max(nota, v * 3);
      if (!nota && cnt[1] && cnt[2]) nota = 6;
      return nota;
    }
    slotsCriticos(slotsCor) {
      const porValor = {};
      for (const s of slotsCor) (porValor[this.mao[s].valor] = porValor[this.mao[s].valor] || []).push(s);
      for (let v = 9; v >= 1; v--) if ((porValor[v] || []).length >= 3) return porValor[v].slice(0, 3);
      for (let v = 8; v >= 2; v--) if (porValor[v - 1] && porValor[v] && porValor[v + 1]) return [porValor[v - 1][0], porValor[v][0], porValor[v + 1][0]];
      return null;
    }

    // CheckCardChain do original: passadas por contagem % 3 (2,5,8 -> 4,7 -> 3,6,9); empate pela nota de critico
    melhorTrio() {
      const { porCor, coringas } = this.maoPorCor();
      const topo = this.proximas[0];
      const cands = [];
      for (const k of Object.keys(porCor)) {
        const cor = +k, qtd = porCor[k].length;
        const ajuda = coringas.length + (combina(topo.cor, cor) ? 1 : 0);
        if (qtd + ajuda < 3) continue;
        cands.push({ cor, passada: qtd === 1 ? 3 : [2, 1, 0].indexOf(qtd % 3), nota: this.notaCritico(cor) });
      }
      cands.sort((a, b) => a.passada - b.passada || b.nota - a.nota || a.cor - b.cor);
      const melhor = cands.length ? cands[0].cor : -1;
      if (melhor !== -1) {
        const crit = this.slotsCriticos(porCor[melhor]);
        if (crit) return { slots: crit, usaDeck: false };
        const slots = [];
        for (const s of porCor[melhor]) { if (slots.length === 3) break; slots.push(s); }
        let usaDeck = false;
        if (slots.length < 3 && combina(topo.cor, melhor)) usaDeck = true;
        for (const s of coringas) { if (slots.length + (usaDeck ? 1 : 0) >= 3) break; slots.push(s); }
        return { slots, usaDeck };
      }
      const so = coringas.length + (topo.cor === COR.CORINGA ? 1 : 0);
      if (so >= 3) {
        const slots = []; const usaDeck = topo.cor === COR.CORINGA;
        for (const s of coringas) { if (slots.length + (usaDeck ? 1 : 0) >= 3) break; slots.push(s); }
        return { slots, usaDeck };
      }
      return null;
    }

    completarMao(r) {
      for (const ent of [ENTRADA_0, ENTRADA_1]) {
        if (this.mao[ent] === null) continue;
        for (let i = 0; i < TAMANHO_MAO; i++) {
          if (this.mao[i] === null) { this.mao[i] = this.mao[ent]; this.mao[ent] = null; r.eventos.push({ tipo: 'entra_na_mao', de: ent, para: i }); break; }
        }
      }
      for (let i = 0; i < TAMANHO_MAO; i++) {
        if (this.mao[i] === null) {
          const n = this.comprar(); this.mao[i] = n;
          r.eventos.push({ tipo: 'nova_carta', slot: i, chuva: true, cor: n.cor, valor: n.valor, fila: this.foto() });
        }
      }
      this.redistribuir(r);
    }

    redistribuir(r) {
      const cartas = this.mao.filter((c) => c !== null);
      this.garantirSaida(cartas);
      cartas.sort(Logic.antesDe);
      const estado = [];
      for (let i = 0; i < this.mao.length; i++) {
        this.mao[i] = i < cartas.length ? cartas[i] : null;
        estado.push(this.mao[i] ? { cor: this.mao[i].cor, valor: this.mao[i].valor } : null);
      }
      r.eventos.push({ tipo: 'redistribuicao', mao: estado, fila: this.foto() });
    }

    temSaida(cartas) {
      const porCor = {}; let cor = 0;
      for (const c of cartas) { if (!c) continue; if (c.cor === COR.CORINGA) cor++; else porCor[c.cor] = (porCor[c.cor] || 0) + 1; }
      if (cor >= 3) return true;
      return Object.values(porCor).some((n) => n + cor >= 3);
    }

    garantirSaida(cartas) {
      let prot = 0;
      while (!this.temSaida(cartas) && prot < TAMANHO_MAO) {
        prot++;
        const porCor = {};
        cartas.forEach((c, i) => { if (!c || c.cor === COR.CORINGA) return; (porCor[c.cor] = porCor[c.cor] || []).push(i); });
        let alvo = -1, orfa = -1;
        for (const k of Object.keys(porCor)) {
          const n = porCor[k].length;
          if (alvo === -1 || n > porCor[alvo].length) alvo = +k;
          if (orfa === -1 || n < porCor[orfa].length) orfa = +k;
        }
        if (alvo === -1 || orfa === alvo) break;
        const i = porCor[orfa][0];
        cartas[i] = carta(alvo, cartas[i].valor);
        this.saidasForcadas++;
      }
    }

    dispararZona(r, acum, acumCombos) {
      const cor = Logic.corDoTrio(this.zona);
      const cadeia = r.n_combos;
      const valores = this.zona.map((c) => c.valor).sort((a, b) => a - b);
      const soma = valores.reduce((a, b) => a + b, 0);
      // coringa substitui valor para formar trinca (confirmado no binario); sozinho nao garante critico
      const semCoringa = this.zona.filter((c) => c.cor !== COR.CORINGA).map((c) => c.valor);
      this.zona = [];
      const trincaComCoringa = semCoringa.length > 0 && semCoringa.length < 3 && semCoringa.every((v) => v === semCoringa[0]);
      const critico = trincaComCoringa || (valores[0] === valores[1] && valores[1] === valores[2]) || (valores[1] === valores[0] + 1 && valores[2] === valores[1] + 1);
      const ev = { tipo: 'combo', cor, cadeia, critico, soma };
      if (cor === COR.CORINGA) {
        let total = 0; const parciais = {};
        for (const ca of CORES_ATAQUE) {
          let f = (this.time[ca].ataque + soma * 10) * (1 + 0.3 * cadeia);
          if (critico) f *= 1.5;
          const p = Math.max(Math.floor(f * FRACAO_TRIO_CORINGA), 1);
          acum[ca] = (acum[ca] || 0) + p; parciais[ca] = p; total += p;
        }
        Object.assign(ev, { dano_parcial: total, atacante: 'TIME INTEIRO', todas_as_cores: true, parciais });
      } else if (cor === COR.CURA) {
        let cura = soma * 12; if (critico) cura = Math.floor(cura * 1.5);
        acum[cor] = (acum[cor] || 0) + cura; ev.cura = cura;
      } else {
        let f = (this.time[cor].ataque + soma * 10) * (1 + 0.3 * cadeia);
        if (critico) f *= 1.5;
        const p = Math.max(Math.floor(f), 1);
        acum[cor] = (acum[cor] || 0) + p;
        Object.assign(ev, { dano_parcial: p, atacante: this.time[cor].nome });
      }
      acumCombos.push(ev);
      r.eventos.push(ev);
      r.n_combos++;
    }

    resolverAtaqueFinal(r, acum, acumCombos) {
      if (!Object.keys(acum).length) return;
      const contribuicoes = []; let bruto = 0, cura = 0;
      for (const k of Object.keys(acum)) {
        const cor = +k, v = acum[k];
        if (cor === COR.CURA) { cura += v; contribuicoes.push({ cor, valor: v, cura: true }); }
        else { bruto += v; contribuicoes.push({ cor, valor: v, cura: false }); }
      }
      let total = 0, reducao = 0; const golpes = [];
      const lider = this.liderAtivo && bruto > 0;
      if (lider) bruto = Math.floor(bruto * LIDER_BONUS);
      if (bruto > 0) {
        let alvo = this.inimigos[this.alvo].vivo ? this.alvo : this.inimigos.findIndex((e) => e.vivo);
        reducao = alvo >= 0 ? reducaoDefesa(this.inimigos[alvo].defesa) : 0;
        total = Math.max(Math.floor(bruto * (1 - reducao)), 1);
        let resto = total;
        while (resto > 0 && alvo >= 0) {
          const e = this.inimigos[alvo];
          const d = Math.min(e.hp, resto); e.hp -= d; resto -= d;
          golpes.push({ inimigo: alvo, dano: d, hp: e.hp });
          if (e.hp <= 0) { e.hp = 0; e.vivo = false; }
          if (resto > 0) alvo = this.inimigos.findIndex((x) => x.vivo); else break;
        }
        if (!this.inimigos[this.alvo].vivo) { const nx = this.inimigos.findIndex((x) => x.vivo); if (nx >= 0) this.alvo = nx; }
      }
      const hpAntes = this.hp;
      if (cura > 0) this.hp = Math.min(this.hp + cura, this.hpMax);
      r.dano_total = total; r.cura_total = cura;
      r.eventos.push({ tipo: 'ataque_final', contribuicoes, combos: acumCombos.map((c) => ({ cor: c.cor, critico: c.critico, dano_parcial: c.dano_parcial, cura: c.cura, parciais: c.parciais })),
        dano_bruto: bruto, dano_total: total, reducao, lider, cura_total: cura, golpes, alvo: this.alvo, hp_antes: hpAntes, hp_jogador: this.hp,
        inimigos: this.inimigos.map((e) => ({ hp: e.hp, vivo: e.vivo })) });
      if (this.inimigos.every((e) => !e.vivo)) { this.fim = true; this.vitoria = true; }
    }

    turnoInimigo(r) {
      if (this.fim) { if (this.vitoria) { r.fim = 'vitoria'; r.eventos.push({ tipo: 'fim', resultado: 'vitoria' }); } return; }
      const abandonou = r.eventos.some((e) => e.tipo === 'abandono');
      if (r.n_combos === 0 && !abandonou) return;
      const ataques = [];
      for (let i = 0; i < this.inimigos.length; i++) {
        const e = this.inimigos[i];
        if (!e.vivo) continue;
        e.contador--;
        if (e.contador <= 0) {
          const dano = Math.max(e.dano + this.ri(-5, 8), 5);
          this.hp = Math.max(this.hp - dano, 0);
          e.contador = e.contadorMax;
          ataques.push({ inimigo: i, dano });
        }
      }
      r.eventos.push({ tipo: 'turno_inimigo', contadores: this.inimigos.map((e) => ({ contador: e.contador, vivo: e.vivo })) });
      for (const a of ataques) r.eventos.push({ tipo: 'ataque_inimigo', inimigo: a.inimigo, dano: a.dano, hp_jogador: this.hp });
      if (ataques.length) r.ataque_inimigo = ataques.reduce((s, a) => s + a.dano, 0);
      if (this.hp <= 0) { this.fim = true; this.vitoria = false; r.fim = 'derrota'; r.eventos.push({ tipo: 'fim', resultado: 'derrota' }); }
    }
  }

  const C = (cor, valor) => ({ cor, valor });
  const R = 0, B = 1, G = 2, Y = 3, P = 4, CU = 5, W = 6;
  // maos de teste (ja na ordem da mao: cor, depois numero). Toques sugeridos em "toques".
  const PRESETS = {
    vermelho_roxo: { nome: 'Vermelho → cascata Roxo', mao: [C(R, 3), C(R, 5), C(R, 6), C(B, 1), C(G, 8), C(Y, 5), C(P, 2), C(P, 4), C(P, 7), C(CU, 4)],
      fila: [C(G, 2), C(Y, 9), C(B, 3), C(G, 6), C(B, 7), C(Y, 2), C(G, 4), C(R, 8), C(B, 5)], toques: [0, 1, 2] },
    cascata_longa: { nome: 'Cascata longa com coringas', mao: [C(R, 2), C(R, 4), C(B, 5), C(B, 6), C(G, 3), C(Y, 7), C(Y, 8), C(P, 1), C(W, 5), C(W, 9)],
      fila: [C(R, 6), C(B, 2), C(G, 7), C(Y, 1), C(P, 3), C(G, 9), C(P, 6), C(B, 8), C(R, 1)], toques: [0, 1, 10] },
    critico: { nome: 'Crítico (sequência 4-5-6)', mao: [C(R, 4), C(R, 5), C(R, 6), C(B, 2), C(B, 8), C(G, 1), C(Y, 3), C(Y, 9), C(P, 5), C(CU, 2)],
      fila: [C(G, 3), C(P, 8), C(B, 4), C(Y, 6), C(G, 5), C(R, 7), C(P, 1), C(B, 9), C(Y, 2)], toques: [0, 1, 2] },
    cura: { nome: 'Cura (3 Capsules)', mao: [C(R, 3), C(B, 5), C(G, 6), C(Y, 2), C(P, 7), C(CU, 2), C(CU, 5), C(CU, 8), C(R, 9), C(B, 1)].sort((a, b) => a.cor - b.cor || a.valor - b.valor),
      fila: [C(G, 4), C(Y, 8), C(P, 3), C(B, 6), C(R, 2), C(G, 9), C(Y, 5), C(P, 1), C(B, 7)], toques: [7, 8, 9] },
    so_coringas: { nome: 'Trio só de coringas', mao: [C(R, 3), C(B, 5), C(G, 6), C(Y, 2), C(P, 7), C(CU, 4), C(W, 2), C(W, 5), C(W, 8), C(R, 1)].sort((a, b) => a.cor - b.cor || a.valor - b.valor),
      fila: [C(G, 4), C(Y, 8), C(P, 3), C(B, 6), C(R, 2), C(G, 9), C(Y, 5), C(P, 1), C(B, 7)], toques: [7, 8, 9] },
    abandono: { nome: 'Abandono (troca de cor)', mao: [C(R, 3), C(R, 5), C(B, 2), C(B, 6), C(G, 8), C(Y, 5), C(P, 2), C(P, 4), C(P, 7), C(CU, 4)],
      fila: [C(G, 2), C(Y, 9), C(B, 3), C(G, 6), C(B, 7), C(Y, 2), C(G, 4), C(R, 8), C(B, 5)], toques: [0, 2] },
  };

  global.ComboLogic = { Logic, Bag, COR, ELEM, PRESETS, TAMANHO_MAO, ENTRADA_0, ENTRADA_1, ROW_SIZE, LIDER_BONUS, LIDER_CD };
})(window);
