"""Prototipo do palco (HTML puro) para testar escala e indicadores antes de levar ao canvas.

Uso: python stage_proto.py <saida.html> [anel|minimo] [trio|solo] [alvo 0-2]
"""
import sys, json
from pathlib import Path

ART = Path(__file__).resolve().parent
W, H = 488, 368
EMBL = json.loads((Path(__file__).resolve().parent / "emblems_chip.json").read_text())

SPR = {"A1": "chr-a1", "A2": "chr-a2", "A3": "chr-a3", "A4": "chr-a4", "A5": "chr-a5",
       "E1": "chr-boss", "E2": "chr-e2", "E3": "chr-e3", "BOSS": "chr-boss"}
POS = {  # pe x%, pe y%, quadro pt
    "A1": (15, 46, 100), "A2": (37, 42, 96), "A3": (26, 65, 106), "A4": (12, 90, 114), "A5": (40, 91, 114),
    "E1": (76, 50, 168), "E2": (62, 88, 126), "E3": (87, 90, 126), "BOSS": (72, 80, 224),
}
UI = {"dragon": "#FF5A3D", "knight": "#4DA8FF", "nature": "#5BD75B", "light": "#FFC93C", "dark": "#B06BFF"}
ALLY = [("A1", "dragon", 45), ("A2", "dark", 30), ("A3", "knight", 100), ("A4", "light", 30), ("A5", "nature", 62)]
ENEMY = [("E1", "light", 46, 2), ("E2", "dark", 78, 1), ("E3", "nature", 100, 3)]


def ring(cx, fy, w, color, pct, glow=False, red=False):
    rx = w * .34
    ry = rx * .3
    col = "#FF4A3A" if red else color
    g = f"filter:drop-shadow(0 0 5px {col});" if glow else ""
    return (f'<svg style="position:absolute;left:{cx - rx - 6}px;top:{fy - ry - 6}px;width:{2 * rx + 12}px;height:{2 * ry + 12}px;overflow:visible;{g}">'
            f'<ellipse cx="{rx + 6}" cy="{ry + 6}" rx="{rx}" ry="{ry}" fill="rgba(10,14,10,.38)" stroke="rgba(8,10,12,.75)" stroke-width="5"/>'
            f'<ellipse cx="{rx + 6}" cy="{ry + 6}" rx="{rx}" ry="{ry}" fill="none" stroke="{col}" stroke-width="3.2" pathLength="100" stroke-dasharray="{pct} 100"/>'
            f'<ellipse cx="{rx + 6}" cy="{ry + 6}" rx="{rx}" ry="{ry}" fill="none" stroke="rgba(8,10,12,.9)" stroke-width="3.6" pathLength="100" stroke-dasharray=".7 4.3"/>'
            f'</svg>')


def dot_of(el):
    e = EMBL[el]
    return (f'<span class="dot" style="background:radial-gradient(circle at 35% 30%,{e["glow"]},{e["mid"]})">'
            f'<svg viewBox="0 0 100 100" width="10" height="10"><path d="{e["d"]}" fill="#F4EEE1" fill-rule="evenodd"/></svg></span>')


def chip(cx, fy, w, color, lv, extra="", frame=""):
    ry = w * .34 * .3
    return (f'<div class="chip" style="left:{cx}px;top:{fy + ry + 1}px;{frame}">'
            f'{dot_of(color)}<span class="lv"><em>LV</em><b>{lv}</b></span>{extra}</div>')


def main():
    out = Path(sys.argv[1])
    mode = sys.argv[2] if len(sys.argv) > 2 else "anel"
    form = sys.argv[3] if len(sys.argv) > 3 else "trio"
    tgt = int(sys.argv[4]) if len(sys.argv) > 4 else 0
    scene, hud = [], []
    order = ["A2", "A1", "E1", "A3", "E2", "A4", "E3", "A5"] if form == "trio" else ["A2", "A1", "A3", "BOSS", "A4", "A5"]
    info = {s: ("ally", e, p, None) for s, e, p in ALLY}
    for s, e, p, t in ENEMY:
        info[s] = ("enemy", e, p, t)
    if form == "solo":
        info["BOSS"] = info["E1"]
    for slot in order:
        xp, yp, w = POS[slot]
        cx, fy = xp / 100 * W, yp / 100 * H
        kind, el, pct, turns = info[slot]
        top = fy - w * .97
        if mode == "anel":
            scene.append(ring(cx, fy, w, UI[el], pct, glow=(kind == "ally" and pct >= 100), red=(kind == "enemy")))
        else:
            scene.append(f'<span style="position:absolute;left:{cx - w * .3}px;top:{fy - w * .03}px;width:{w * .6}px;height:{w * .07}px;border-radius:50%;background:rgba(10,14,10,.4)"></span>')
        scene.append(f'<img src="{(ART / (SPR[slot] + ".webp")).as_uri()}" style="position:absolute;left:{cx - w / 2}px;top:{top}px;width:{w}px;height:{w}px">')
        if mode == "anel":
            extra = ""
            if kind == "enemy":
                segs = "".join(f'<i style="background:{"#FF6B4A" if turns == 1 else "#F2A33C"};opacity:{1 if k < turns else .25}"></i>' for k in range(3))
                extra = f'<span class="turn{" hot" if turns == 1 else ""}">{segs}<b>{turns}</b></span>'
            elif pct >= 100:
                extra = '<span class="ready">PRONTA</span>'
            hud.append(chip(cx, fy, w, el, 120 if kind == "enemy" else 38, extra))
        else:
            bar_col = "#FF4A3A" if kind == "enemy" else UI[el]
            hud.append(f'<div class="mini" style="left:{cx}px;top:{fy + 3}px;width:{w * .5}px"><span style="background:{UI[el]}" class="pip"></span>'
                       f'<span class="mb"><i style="width:{pct}%;background:{bar_col}"></i></span></div>')
    # mira + pop-up no alvo
    tslot = "BOSS" if (form == "solo") else ENEMY[tgt][0]
    xp, yp, w = POS[tslot]
    cx, fy = xp / 100 * W, yp / 100 * H
    size = w * .92
    hud.append(f'<div class="aim" style="left:{cx - size / 2}px;top:{fy - w * .97 + w * .5 - size / 2}px;width:{size}px;height:{size}px"><i></i><i></i><i></i><i></i></div>')
    head = fy - w * .97 + w * .12
    popw, poph = 172, 74
    if head - poph - 12 > 26:
        px, py, arrow = min(max(cx, popw / 2 + 6), W - popw / 2 - 6), head - poph - 10, "down"
    else:
        px, py, arrow = cx - w * .38 - popw / 2 - 8, max(28, fy - w * .6 - poph / 2), "right"
    hud.append(f'<div class="pop" style="left:{px - popw / 2}px;top:{py}px"><div class="ph"><span>ALVO · LV40</span><span>46%</span></div>'
               f'<div class="pn">Long Ear Guardian</div><div class="pb"><i style="width:46%"></i></div>'
               f'<div class="pf"><span>1850 / 4000 HP</span><span class="turn">ATQ <i style="background:#F2A33C"></i><i style="background:#F2A33C"></i><i style="opacity:.25;background:#F2A33C"></i><b>2</b></span></div>'
               f'<span class="arrow {arrow}"></span></div>')

    bg = (ART / "bg-tropical.webp").as_uri()
    html = f"""<!doctype html><html><head><meta charset="utf-8">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Instrument+Sans:wght@500;700&family=Martian+Mono:wght@400;600&display=swap">
<style>
body{{margin:0;background:#16130D;font-family:'Instrument Sans',system-ui;color:#F5EFE2}}
.v{{position:relative;width:{W}px;height:{H}px;border-radius:16px;overflow:hidden;margin:10px;box-shadow:inset 0 0 0 1px rgba(242,163,60,.28)}}
.film{{position:absolute;inset:0;background:repeating-linear-gradient(180deg,rgba(0,0,0,.15) 0 1px,transparent 1px 3px)}}
.vig{{position:absolute;inset:0;background:radial-gradient(115% 88% at 50% 42%,rgba(0,0,0,0) 42%,rgba(22,19,13,.62) 100%)}}
.chip{{position:absolute;transform:translateX(-50%);display:flex;align-items:center;gap:3px;height:15px;padding:0 5px 0 1px;border-radius:8px;background:rgba(12,14,16,.86);box-shadow:0 0 0 1px rgba(255,255,255,.18);white-space:nowrap}}
.dot{{width:13px;height:13px;border-radius:50%;display:flex;align-items:center;justify-content:center;box-shadow:0 0 0 1px rgba(245,239,226,.55)}}
.lv{{font:700 8px 'Instrument Sans';color:#fff;display:inline-flex;align-items:baseline}} .lv b{{display:inline-block;min-width:15px;font-family:'Martian Mono';font-size:7.5px;font-weight:600;text-align:left}} .lv em{{font-style:normal;font-size:6px;opacity:.65;margin-right:1px}}
.turn{{display:inline-flex;align-items:center;gap:1.5px;margin-left:3px;font:600 7px 'Martian Mono';color:#F2A33C}}
.turn i{{display:inline-block;width:5px;height:2.5px;border-radius:1px}} .turn b{{margin-left:2px}}
.turn.hot{{color:#FF6B4A;animation:p .8s infinite}}
.ready{{margin-left:3px;font:600 6px 'Martian Mono';color:#F2A33C;letter-spacing:.4px}}
.mini{{position:absolute;transform:translateX(-50%);display:flex;align-items:center;gap:2px}}
.pip{{width:5px;height:5px;border-radius:50%}} .mb{{flex:1;height:3px;background:rgba(8,10,12,.75);border-radius:2px;overflow:hidden}} .mb i{{display:block;height:100%}}
.aim{{position:absolute}} .aim i{{position:absolute;width:15px;height:15px;border:0 solid #FF6B4A}}
.aim i:nth-child(1){{left:0;top:0;border-left-width:1.5px;border-top-width:1.5px}} .aim i:nth-child(2){{right:0;top:0;border-right-width:1.5px;border-top-width:1.5px}}
.aim i:nth-child(3){{left:0;bottom:0;border-left-width:1.5px;border-bottom-width:1.5px}} .aim i:nth-child(4){{right:0;bottom:0;border-right-width:1.5px;border-bottom-width:1.5px}}
.pop{{position:absolute;width:172px;padding:8px 10px 9px;background:rgba(16,13,9,.94);border-radius:8px;box-shadow:inset 0 0 0 1px rgba(255,107,74,.5),0 6px 18px rgba(0,0,0,.6)}}
.ph,.pf{{display:flex;justify-content:space-between;align-items:center;font:400 7px 'Martian Mono';color:#FF6B4A}} .ph span+span{{color:rgba(245,239,226,.45)}}
.pn{{font-size:10.5px;font-weight:700;margin:3px 0 5px}} .pb{{height:5px;background:rgba(245,239,226,.1)}} .pb i{{display:block;height:100%;background:#FF6B4A}}
.pf{{margin-top:6px;color:rgba(245,239,226,.55);font-size:8px}}
.arrow{{position:absolute;width:9px;height:9px;background:rgba(16,13,9,.94);transform:rotate(45deg)}}
.arrow.down{{left:81px;bottom:-5px;box-shadow:1px 1px 0 0 rgba(255,107,74,.5)}} .arrow.right{{right:-5px;top:32px;box-shadow:1px -1px 0 0 rgba(255,107,74,.5)}}
@keyframes p{{50%{{opacity:.45}}}}
</style></head><body><div class="v"><img src="{bg}" style="position:absolute;inset:0;width:100%;height:100%">
{''.join(scene)}<div class="film"></div><div class="vig"></div>{''.join(hud)}</div></body></html>"""
    out.write_text(html, encoding="utf-8")
    print("ok", out)


if __name__ == "__main__":
    main()
