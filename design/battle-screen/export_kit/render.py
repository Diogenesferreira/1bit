"""Renderizador estatico da tela de batalha (Main.dc.html) fora do canvas.

Expande o template {{...}} / <sc-for> / <sc-if> com a propria logica da tela,
marca cada peca com data-part e permite:
  - screenshot da tela inteira em 1024x1600 (2x)
  - screenshot de uma peca isolada, com fundo transparente (inteira ou so a caixa)
  - medir o retangulo de todas as pecas (layout)

Uso como modulo: from render import Renderer
"""
import json
import re
import subprocess
import tempfile
from pathlib import Path
from urllib.parse import quote

HERE = Path(__file__).resolve().parent
SCREEN = HERE.parent
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
SCALE = 2
W, H = 512, 800

# arquivos usados pela tela -> arquivos em alta (exportacao)
def image_map(kit_assets: Path | None = None):
    art = SCREEN / "art"
    src = art / "_src"
    m = {
        "avatar.png": SCREEN / "avatar.png",
        "bg-tropical.webp": art / "_hi" / "bg_tropical_visor_976x736.png",
        "bg-deserto.webp": art / "_hi" / "bg_deserto_visor_976x736.png",
        "chr-a1.webp": src / "ally_01_crimson_clamp_256.png",
        "chr-a2.webp": src / "ally_02_bone_raider_256.png",
        "chr-a3.webp": src / "ally_03_panda_gunner_256.png",
        "chr-a4.webp": src / "ally_04_twin_apes_256.png",
        "chr-a5.webp": src / "ally_05_flora_fairy_256.png",
        "chr-e2.webp": src / "enemy_01_dusk_dragon_256.png",
        "chr-e3.webp": src / "enemy_02_twin_tail_256.png",
        "chr-boss.webp": src / "boss_01_long_ear_guardian_512.png",
    }
    for el in ("dragon", "knight", "nature", "light", "dark", "capsule", "wild"):
        m[f"card-{el}.png"] = SCREEN / "export" / "cards" / f"card-{el}@4x.png"
    return {k: v.as_uri() for k, v in m.items()}


RENDERER_JS = r"""
(function(){
  const CFG = JSON.parse(decodeURIComponent(location.hash.slice(1) || '%7B%7D'));
  const SRC = document.getElementById('src').textContent;
  const CLS = document.getElementById('cls').textContent;
  const IMG = JSON.parse(document.getElementById('imgs').textContent);

  class DCLogic { constructor(p){ this.props = p || {}; } setState(o, cb){ Object.assign(this.state, typeof o === 'function' ? o(this.state) : o); if (cb) cb(); } forceUpdate(){} }
  const Component = new Function('DCLogic', 'setTimeout', 'clearTimeout', CLS + '; return Component;')(DCLogic, function(){ return 0; }, function(){});
  const c = new Component(CFG.props || {});
  if (CFG.state) Object.assign(c.state, CFG.state);
  if (CFG.patch) { for (const [k, v] of Object.entries(CFG.patch)) { const [arr, idx, field] = k.split('.'); c.state[arr][+idx][field] = v; } }
  for (const [fn, ...args] of (CFG.actions || [])) c[fn](...args);
  if (CFG.after) Object.assign(c.state, CFG.after);
  const vals = c.renderVals();

  const HOLE = /\{\{\s*([^}]+?)\s*\}\}/g;
  function look(path, scopes){
    path = path.trim();
    if (path === 'true') return true; if (path === 'false') return false;
    if (/^-?\d+(\.\d+)?$/.test(path)) return Number(path);
    const segs = path.split('.');
    let cur;
    for (let i = scopes.length - 1; i >= 0; i--) { if (scopes[i] && Object.prototype.hasOwnProperty.call(scopes[i], segs[0])) { cur = scopes[i][segs[0]]; break; } }
    for (let j = 1; j < segs.length && cur != null; j++) cur = cur[segs[j]];
    return cur;
  }
  function fill(str, scopes){ return str.replace(HOLE, (m, p) => { const v = look(p, scopes); return v == null ? '' : String(v); }); }

  function expand(node, scopes, out){
    if (node.nodeType === 3) { out.push(document.createTextNode(fill(node.nodeValue, scopes))); return; }
    if (node.nodeType !== 1) return;
    const tag = node.localName;
    if (tag === 'sc-for') {
      const listExpr = node.getAttribute('list').replace(/[{}]/g, '').trim();
      const list = look(listExpr, scopes) || [];
      const as = node.getAttribute('as');
      list.forEach((item, i) => {
        const produced = [];
        for (const ch of node.childNodes) expand(ch, scopes.concat([{ [as]: item, $index: i }]), produced);
        for (const p of produced) { if (p.nodeType === 1) { p.setAttribute('data-loop', listExpr); p.setAttribute('data-i', i); } out.push(p); }
      });
      return;
    }
    if (tag === 'sc-if') {
      const v = look(node.getAttribute('value').replace(/[{}]/g, ''), scopes);
      if (v) for (const ch of node.childNodes) expand(ch, scopes, out);
      return;
    }
    const el = node.namespaceURI === 'http://www.w3.org/2000/svg'
      ? document.createElementNS(node.namespaceURI, node.localName)
      : document.createElement(node.localName);
    for (const at of node.attributes) {
      if (/^on/i.test(at.name) || at.name.startsWith('hint-')) continue;
      let v = fill(at.value, scopes);
      if (at.name === 'src' && IMG[v]) v = IMG[v];
      el.setAttribute(at.name, v);
    }
    for (const ch of node.childNodes) expand(ch, scopes, el.childNodes.length >= 0 ? { push: (n) => el.appendChild(n) } : null);
    out.push(el);
  }

  const doc = new DOMParser().parseFromString('<body>' + SRC + '</body>', 'text/html');
  const host = document.getElementById('host');
  const produced = [];
  for (const ch of doc.body.childNodes) expand(ch, [vals], produced);
  for (const p of produced) host.appendChild(p);

  // ---------------- nomes das pecas ----------------
  const R = [...host.children].find((e) => e.localName === 'div');
  R.classList.add('xroot');
  const tag = (el, name) => { if (el) el.setAttribute('data-part', name); return el; };
  const kids = [...R.children];
  const [defs, header, strip, visor, team, bank, nav] = kids;
  const toast = kids[7];
  tag(header, 'header');
  const av = tag(header.children[0], 'header_avatar'); tag(av.children[0], 'header_avatar_img');
  tag(av.children[1], 'header_avatar_frame'); tag(av.children[2], 'header_avatar_corner_tl'); tag(av.children[3], 'header_avatar_corner_br');
  const pl = tag(header.children[1], 'header_player');
  tag(pl.children[0].children[0], 'header_player_name'); tag(pl.children[0].children[1], 'header_player_rank');
  const xpRow = pl.children[1];
  const xp = tag(xpRow.children[0], 'header_xp_bar'); tag(xp.children[0], 'header_xp_fill'); tag(xp.children[1], 'header_xp_segments');
  tag(xpRow.children[1], 'header_xp_text');
  const sy = tag(header.children[2], 'header_sync');
  tag(sy.children[0], 'header_sync_dot'); tag(sy.children[1], 'header_sync_text'); tag(sy.children[2], 'icon_menu');

  tag(strip, 'strip');
  ['bits', 'rule_1', 'gems', 'rule_2', 'energy'].forEach((n, i) => {
    const cell = tag(strip.children[i], 'strip_' + n);
    if (!n.startsWith('rule')) { tag(cell.children[0].children[0], 'icon_' + n); tag(cell.children[0].children[1], 'strip_' + n + '_label'); tag(cell.children[1], 'strip_' + n + '_value'); }
    if (n === 'energy') tag(cell.children[0].children[2], 'strip_energy_timer');
  });

  tag(visor, 'visor');
  const corners = { 'left: 8px; top: 8px': 'tl', 'right: 8px; top: 8px': 'tr', 'left: 8px; bottom: 8px': 'bl', 'right: 8px; bottom: 8px': 'br' };
  for (const el of [...visor.children]) {
    const st = el.getAttribute('style') || '';
    if (el.localName === 'img') tag(el, 'visor_bg');
    else if (el.getAttribute('data-loop') === 'figs') {
      const id = vals.figs[+el.getAttribute('data-i')].id;
      tag(el, 'stage_fig_' + id);
      const svg = el.querySelector('svg'); if (svg) tag(svg, 'stage_ring_' + id);
      const img = el.querySelector('img'); if (img) tag(img, 'stage_sprite_' + id);
    }
    else if (st.includes('rgba(0,0,0,.15) 0 1px')) tag(el, 'visor_film_scanline');
    else if (st.includes('radial-gradient(115%')) tag(el, 'visor_film_vignette');
    else if (st.includes('animation: ret')) tag(el, 'visor_aim');
    else if (el.classList.contains('chip')) {
      const loop = el.getAttribute('data-loop'); const i = +el.getAttribute('data-i');
      const key = (loop === 'enemies' ? vals.enemies : vals.allies)[i].key;
      tag(el, 'chip_' + key); tag(el.querySelector('.dot'), 'chip_badge_' + key);
      const tn = el.querySelector('.tn'); if (tn) tag(tn, 'chip_turn_' + key);
    }
    else if (st.includes('width: 172px')) {
      tag(el, 'popup_target');
      tag(el.children[2], 'popup_target_hp_bar');
      tag(el.children[3].children[1], 'popup_target_turn');
      tag(el.children[4], 'popup_target_arrow');
    }
    else if ((el.textContent || '').trim().startsWith('SETOR')) tag(el, 'visor_sector');
    else if ((el.textContent || '').includes('ROUND')) tag(el, 'visor_round');
    else { for (const [k, v] of Object.entries(corners)) if (st.includes(k)) tag(el, 'visor_corner_' + v); }
  }

  tag(team, 'team');
  tag(team.children[0], 'team_hp_label');
  const th = tag(team.children[1], 'team_hp_bar'); tag(th.children[0], 'team_hp_fill'); tag(th.children[1], 'team_hp_segments');
  tag(team.children[2], 'team_hp_text');
  const lb = tag(team.children[3], 'button_leader'); tag(lb.children[0], 'icon_crown');

  tag(bank, 'bank');
  const bh = tag(bank.children[0], 'bank_header');
  tag(bh.children[0], 'bank_label'); tag(bh.children[1], 'bank_combo'); tag(bh.children[2], 'bank_rule');
  tag(bh.children[3], 'bank_queue_label'); tag(bh.children[4], 'bank_queue');
  const grid = tag(bank.children[1], 'bank_grid');
  [...grid.children].forEach((b, i) => {
    tag(b, 'card_slot_' + (i + 1));
    const spans = [...b.children].filter((e) => e.localName === 'span');
    tag(spans[0], 'card_value_' + (i + 1)); if (spans[1]) tag(spans[1], 'card_order_' + (i + 1));
    tag(b.querySelector('img'), 'card_art_' + (i + 1));
  });

  tag(nav, 'nav');
  ['equipe', 'invocar', 'loja', 'fases'].forEach((n, i) => { const b = tag(nav.children[i], 'button_nav_' + n); tag(b.children[0], 'icon_nav_' + n); tag(b.children[1], 'button_nav_' + n + '_label'); });
  if (toast) tag(toast, 'toast');

  // ---------------- modos ----------------
  const css = document.getElementById('mode');
  const extra = (CFG.css || '');
  if (CFG.part) {
    const sel = '[data-part="' + CFG.part + '"]';
    const hide = (CFG.hide || []).map((h) => '[data-part="' + h + '"], [data-part="' + h + '"] *').join(',');
    css.textContent = 'html,body{background:transparent!important} .xroot, .xroot *{visibility:hidden!important} '
      + (CFG.box ? sel + '{visibility:visible!important;color:transparent!important;text-shadow:none!important}' : sel + ',' + sel + ' *{visibility:visible!important}')
      + (hide ? hide + '{visibility:hidden!important}' : '') + extra;
  } else {
    css.textContent = extra;
  }

  // medidas
  const out = {};
  for (const el of document.querySelectorAll('[data-part]')) {
    const r = el.getBoundingClientRect();
    const cs = getComputedStyle(el);
    const rec = { x: +(r.left).toFixed(2), y: +(r.top).toFixed(2), w: +(r.width).toFixed(2), h: +(r.height).toFixed(2),
      radius: cs.borderTopLeftRadius, background: cs.backgroundColor, shadow: cs.boxShadow };
    const own = [...el.childNodes].filter((n) => n.nodeType === 3).map((n) => n.nodeValue).join('').trim();
    if (own || (el.children.length === 0 && (el.textContent || '').trim())) {
      rec.text = (el.textContent || '').trim();
      rec.font = { family: cs.fontFamily.split(',')[0].replace(/['"]/g, ''), size: cs.fontSize, weight: cs.fontWeight,
        letterSpacing: cs.letterSpacing, lineHeight: cs.lineHeight, transform: cs.textTransform, color: cs.color, shadow: cs.textShadow };
    }
    if (el.localName === 'svg') rec.svg = el.outerHTML;
    out[el.getAttribute('data-part')] = rec;
  }
  const o = document.createElement('script'); o.type = 'application/json'; o.id = 'out'; o.textContent = JSON.stringify(out);
  document.body.appendChild(o);
})();
"""


class Renderer:
    def __init__(self):
        src = (SCREEN / "Main.dc.html").read_text(encoding="utf-8")
        helmet = re.search(r"<helmet>(.*?)</helmet>", src, re.S).group(1)
        body = re.search(r"</helmet>(.*?)</x-dc>", src, re.S).group(1)
        cls = re.search(r"<script data-dc-script[^>]*>(.*?)</script>", src, re.S).group(1)
        self.tmp = Path(tempfile.mkdtemp(prefix="dcexport_"))
        page = (
            "<!doctype html><html><head><meta charset='utf-8'>" + helmet +
            "<style>*{animation:none!important;transition:none!important} html,body{margin:0;background:#16130D}</style>"
            "<style id='mode'></style></head><body><div id='host'></div>"
            "<script type='text/plain' id='src'>" + body.replace("</script", "<\\/script") + "</script>"
            "<script type='text/plain' id='cls'>" + cls.replace("</script", "<\\/script") + "</script>"
            "<script type='application/json' id='imgs'>" + json.dumps(image_map()) + "</script>"
            "<script>" + RENDERER_JS + "</script></body></html>"
        )
        self.page = self.tmp / "screen.html"
        self.page.write_text(page, encoding="utf-8")

    def _url(self, cfg):
        return self.page.as_uri() + "#" + quote(json.dumps(cfg))

    def shot(self, out_png: Path, cfg: dict, transparent=False):
        out_png.parent.mkdir(parents=True, exist_ok=True)
        args = [CHROME, "--headless", "--disable-gpu", "--hide-scrollbars", "--allow-file-access-from-files",
                f"--force-device-scale-factor={SCALE}", "--virtual-time-budget=6000",
                f"--window-size={W},{H}", f"--screenshot={out_png}"]
        if transparent:
            args.append("--default-background-color=00000000")
        subprocess.run(args + [self._url(cfg)], check=True, capture_output=True, timeout=120)
        return out_png

    def measure(self, cfg: dict):
        r = subprocess.run([CHROME, "--headless", "--disable-gpu", "--allow-file-access-from-files",
                            "--virtual-time-budget=6000", f"--window-size={W},{H}", "--dump-dom", self._url(cfg)],
                           check=True, capture_output=True, timeout=120)
        dom = r.stdout.decode("utf-8", "replace")
        m = re.search(r'<script type="application/json" id="out">(.*?)</script>', dom, re.S)
        return json.loads(m.group(1))


if __name__ == "__main__":
    import sys
    rd = Renderer()
    out = Path(sys.argv[1])
    rd.shot(out, {})
    print("ok", out)
