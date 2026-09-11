"""Gera a arte das 7 cartas como SVG (152x176 = 2x do slot 76x88).

Uso:  python build_cards.py            -> escreve card-*.svg ao lado deste arquivo
      python build_cards.py --compare  -> tambem escreve compare.html (refs x cartas)
"""
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
REFS = Path(r"C:\Users\Jinsa\OneDrive\Meus Documentos\heroes\assetsemodelosideias\Nova pasta")

W, H = 152, 176

# mid = cor do meio, dark = cantos, lens = brilho dentro do arco, tint = pe do degrade do emblema
PAL = {
    "dragon":  dict(mid="#B0271B", dark="#4E0A06", lens="#E0492F", tint="#FFB09C", shade="#5A0D07"),
    "knight":  dict(mid="#1C69A8", dark="#08284A", lens="#3592DA", tint="#D6ECFF", shade="#082C4E"),
    "nature":  dict(mid="#1D7634", dark="#082E14", lens="#31A04E", tint="#BFF0BF", shade="#0A3517"),
    "light":   dict(mid="#AE8612", dark="#3F2E02", lens="#D9B12E", tint="#FFE6A0", shade="#4A3604"),
    "dark":    dict(mid="#6424A6", dark="#1E0839", lens="#8B45D2", tint="#DEC6FF", shade="#26093F"),
    "capsule": dict(mid="#7A5A2E", dark="#2A1C0A", lens="#A07B45", tint="#F1D9A8", shade="#2E200C"),
    "wild":    dict(mid="#121218", dark="#040406", lens="#1C1C26", tint="#D8D8EA", shade="#000000"),
}

UI = {"dragon": "#FF5A3D", "knight": "#4DA8FF", "nature": "#5BD75B",
      "light": "#FFC93C", "dark": "#B06BFF", "capsule": "#C89A5A"}

# ---------------------------------------------------------------------------
# EMBLEMAS - grid 100x100. "body" recebe o degrade; "cut" sao recortes escuros
# ---------------------------------------------------------------------------
EMB = {}


def blade(bx, by, tx, ty, w, bend=0.0):
    """Lamina afilada e curva: base (bx,by) com meia-largura w, ponta (tx,ty).
    bend desloca a curva para a esquerda (+) ou direita (-) do sentido base->ponta."""
    import math
    dx, dy = tx - bx, ty - by
    L = math.hypot(dx, dy) or 1
    nx, ny = -dy / L, dx / L
    mx, my = bx + dx * 0.5 + nx * bend, by + dy * 0.5 + ny * bend
    ax, ay = bx + nx * w, by + ny * w
    cx, cy = bx - nx * w, by - ny * w
    return (f"M{ax:.1f} {ay:.1f} Q{mx + nx * w * .6:.1f} {my + ny * w * .6:.1f} {tx:.1f} {ty:.1f} "
            f"Q{mx - nx * w * .6:.1f} {my - ny * w * .6:.1f} {cx:.1f} {cy:.1f} Z")


EMB["dragon"] = dict(parts=[
    # cabeca compacta de perfil, mandibula aberta para baixo-esquerda,
    # pescoco e corpo em S descendo ate a ponta de baixo
    "M10 50 C18 42 26 38 34 36 C38 28 46 22 56 22 C66 22 74 28 76 38 "
    "C78 48 76 58 70 66 C64 76 62 86 66 99 C55 91 50 81 52 70 "
    "C54 62 56 58 52 56 C44 58 34 62 17 71 C25 61 33 55 40 52 "
    "L36 51 L34 55 L31 50 L28 54 L25 49 L21 52 L20 48 C16 49 13 50 10 50 Z",
    # chifres grossos em chama
    blade(48, 25, 68, 1, 6.5, -9),
    blade(61, 25, 90, 6, 6, -8),
    # juba de chamas no lado direito, decrescendo
    blade(73, 35, 97, 20, 5.5, -7),
    blade(76, 49, 100, 40, 6, -7),
    blade(73, 61, 98, 58, 6, -6),
    blade(69, 73, 94, 78, 5.5, -5),
    blade(65, 85, 86, 97, 4.8, -3),
    # barba e floreio esquerdo
    blade(44, 58, 35, 79, 4.2, 4),
    blade(54, 78, 35, 92, 4.2, 5),
], cuts=[
    "M36 38 C41 32 48 30 55 31 C51 36 44 39 36 38 Z",
    "M15 48 L22 45 L21 49 Z",
    "M60 38 C66 36 71 39 73 44 C68 44 63 42 60 38 Z",
    "M60 66 C64 71 64 79 60 86 C60 79 60 72 60 66 Z",
])

EMB["knight"] = dict(parts=[
    # elmo alto: cupula redonda, viseira em bico para baixo-esquerda,
    # guarda do queixo em ponta longa e nuca abrindo para tras
    "M56 11 C70 11 81 21 81 35 C81 44 77 50 72 54 L85 62 C75 64 67 66 60 70 "
    "L50 99 C46 88 42 78 40 70 L21 77 C27 69 31 63 34 58 L12 57 "
    "C21 51 29 47 36 45 C34 37 36 27 40 21 C44 15 50 11 56 11 Z",
    # crista alada: tres penas em leque
    blade(63, 23, 84, 0, 7, -6),
    blade(70, 27, 99, 7, 7, -5),
    blade(76, 34, 100, 25, 6.5, -3),
], cuts=[
    "M35 40 C48 37 62 37 79 40 L78 45 C62 43 48 43 36 45 Z",
    "M42 56 L62 51 L61 55 L44 60 Z",
    "M44 18 C54 14 66 16 74 24 C66 20 56 19 46 22 Z",
])

EMB["nature"] = dict(parts=[
    # chama-broto cheia inclinada para a esquerda
    "M58 2 C64 10 68 18 66 28 C73 22 76 14 74 7 C84 18 82 34 70 44 "
    "C64 50 62 56 62 64 L52 64 C52 52 46 42 44 32 C42 20 48 9 58 2 Z",
    blade(60, 48, 95, 29, 10, -9),
    blade(60, 62, 93, 60, 8, -6),
    blade(49, 36, 25, 21, 7, 6),
    "M52 60 L62 60 C62 76 60 88 56 98 L50 98 C53 86 52 74 52 60 Z",
    # espiral da base: crescentes grandes do lado esquerdo
    "M56 98 C35 102 13 90 9 67 C19 84 36 92 56 91 Z",
    "M54 90 C37 88 23 77 21 59 C29 74 41 81 55 83 Z",
    "M54 81 C43 77 35 67 37 51 C42 63 48 70 57 74 Z",
], cuts=[
    "M63 45 C73 38 83 34 91 31 C83 38 74 43 63 45 Z",
    "M63 60 C71 58 80 58 89 59 C80 61 71 62 63 60 Z",
    "M50 33 C44 29 37 26 30 23 C37 29 43 32 50 33 Z",
])

EMB["dark"] = dict(parts=[
    # serpe: cabeca compacta de boca aberta
    "M6 58 C13 51 21 47 30 46 C38 44 46 46 50 52 C48 58 42 62 34 62 "
    "L13 71 C20 64 26 60 30 58 L25 58 L23 61 L20 57 L17 60 L15 56 C12 57 9 58 6 58 Z",
    blade(40, 45, 51, 24, 4.8, 5),
    blade(33, 46, 32, 29, 3.2, 3),
    "M44 46 C50 42 56 42 62 46 L58 58 C54 54 50 52 46 54 Z",
    # asa enorme com tres recortes de membrana
    "M55 49 C61 30 78 12 99 2 C94 14 95 24 100 31 C92 30 86 37 88 47 "
    "C80 45 74 51 76 61 C70 63 64 61 59 57 Z",
    # corpo descendo e afinando em cauda
    "M58 54 C68 62 70 74 64 84 C58 92 50 96 43 99 C48 90 50 84 50 78 C48 70 46 64 48 58 Z",
    blade(50, 88, 28, 98, 4.2, -4),
    blade(62, 80, 79, 95, 3.8, 3),
    blade(51, 71, 32, 81, 3.8, 4),
    blade(48, 62, 37, 73, 3, 2),
], cuts=[
    "M30 50 C34 48 38 48 41 49 C38 52 34 53 30 50 Z",
    "M60 51 L97 5 L62 54 Z",
    "M62 54 L98 30 L64 57 Z",
    "M64 57 L87 46 L66 59 Z",
])

EMB["light"] = dict(parts=[
    "M50 1 C52 26 55 40 59 41 C60 45 74 48 99 50 C74 52 60 55 59 59 C55 60 52 74 50 99 "
    "C48 74 45 60 41 59 C40 55 26 52 1 50 C26 48 40 45 41 41 C45 40 48 26 50 1 Z",
    "M63 37 L82 17 L71 41 Z", "M63 63 L82 83 L71 59 Z",
    "M37 63 L18 83 L29 59 Z", "M37 37 L18 17 L29 41 Z",
    "M86 32 L89 37 L86 42 L83 37 Z", "M14 58 L17 63 L14 68 L11 63 Z", "M71 88 L73 91 L71 94 L69 91 Z",
], cuts=[
    "M50 42 C52 47 53 48 58 50 C53 52 52 53 50 58 C48 53 47 52 42 50 C47 48 48 47 50 42 Z",
], cut_fill="#FFFFFF", cut_opacity=0.9)

TRACED = HERE / "traced.json"
if TRACED.exists():
    import json as _json
    for _el, _d in _json.loads(TRACED.read_text(encoding="utf-8")).items():
        EMB[_el] = dict(parts=[_d], cuts=[], evenodd=True)


def emblem_group(elem, tx=25, ty=33, s=1.02, grad="emb", extra="", cuts=True):
    e = EMB[elem]
    out = [f'<g transform="translate({tx} {ty}) scale({s})" {extra}>']
    rule = ' fill-rule="evenodd"' if e.get("evenodd") else ""
    for d in e["parts"]:
        out.append(f'<path d="{d}" fill="url(#{grad})"{rule}/>')
    if cuts:
        fill = e.get("cut_fill", PAL[elem]["shade"])
        op = e.get("cut_opacity", 0.8)
        for d in e.get("cuts", []):
            out.append(f'<path d="{d}" fill="{fill}" fill-opacity="{op}"/>')
    out.append("</g>")
    return "".join(out)


def capsule_art():
    # capsula diagonal partida ao meio, com pixels escapando pela fenda
    return """
<g transform="translate(76 86) rotate(-42)">
  <path d="M-4 -19 L-40 -19 A19 19 0 0 0 -40 19 L-4 19 Z" fill="url(#embC)"/>
  <path d="M4 -19 L40 -19 A19 19 0 0 1 40 19 L4 19 Z" fill="url(#embC)" opacity=".92"/>
  <path d="M-44 -12 L-8 -12" stroke="#fff" stroke-width="5" stroke-linecap="round" opacity=".75"/>
  <path d="M10 -12 L42 -12" stroke="#fff" stroke-width="5" stroke-linecap="round" opacity=".6"/>
  <path d="M-4 -19 L-4 19 M4 -19 L4 19" stroke="#2E200C" stroke-width="1.2" opacity=".35"/>
</g>
<g stroke-width="1.6">
  <rect x="58" y="62" width="15" height="15" fill="#FFF6E2" fill-opacity=".22" stroke="#FFF6E2"/>
  <rect x="70" y="76" width="12" height="12" fill="#2A1C0A" fill-opacity=".35" stroke="#2A1C0A" stroke-opacity=".7"/>
  <rect x="80" y="58" width="13" height="13" fill="#FFF6E2" fill-opacity=".3" stroke="#FFF6E2"/>
  <rect x="46" y="74" width="10" height="10" fill="#2A1C0A" fill-opacity=".3" stroke="#2A1C0A" stroke-opacity=".6"/>
  <rect x="64" y="46" width="9" height="9" fill="#FFF6E2" fill-opacity=".45" stroke="#FFF6E2"/>
  <rect x="88" y="80" width="9" height="9" fill="#2A1C0A" fill-opacity=".3" stroke="#2A1C0A" stroke-opacity=".6"/>
  <rect x="54" y="90" width="7" height="7" fill="#FFF6E2" fill-opacity=".5" stroke="#FFF6E2"/>
  <rect x="94" y="48" width="6" height="6" fill="#FFF6E2" fill-opacity=".4" stroke="#FFF6E2"/>
  <rect x="42" y="58" width="6" height="6" fill="#FFF6E2" fill-opacity=".55" stroke="#FFF6E2"/>
  <rect x="78" y="96" width="5" height="5" fill="#FFF6E2" fill-opacity=".5" stroke="#FFF6E2"/>
</g>"""


def atom(cx, cy, r):
    rings = "".join(
        f'<ellipse cx="{cx}" cy="{cy}" rx="{r}" ry="{r*0.38:.2f}" transform="rotate({a} {cx} {cy})" fill="none" stroke="url(#rainbowS)" stroke-width="2"/>'
        for a in (0, 60, 120))
    star = (f'<path d="M{cx} {cy-r*0.42:.2f} L{cx+r*0.13:.2f} {cy-r*0.13:.2f} L{cx+r*0.42:.2f} {cy} '
            f'L{cx+r*0.13:.2f} {cy+r*0.13:.2f} L{cx} {cy+r*0.42:.2f} L{cx-r*0.13:.2f} {cy+r*0.13:.2f} '
            f'L{cx-r*0.42:.2f} {cy} L{cx-r*0.13:.2f} {cy-r*0.13:.2f} Z" fill="#fff"/>')
    return rings + star


def wild_art():
    minis = []
    spots = [("dragon", 30, 34), ("knight", 84, 32), ("dark", 26, 86), ("nature", 88, 84), ("capsule", 26, 132)]
    for el, x, y in spots:
        if el == "capsule":
            minis.append(f"""<g transform="translate({x+18} {y}) rotate(-42) scale(.42)">
  <path d="M-4 -19 L-40 -19 A19 19 0 0 0 -40 19 L-4 19 Z" fill="url(#mc_capsule)"/>
  <path d="M4 -19 L40 -19 A19 19 0 0 1 40 19 L4 19 Z" fill="url(#mc_capsule)"/></g>""")
        else:
            minis.append(emblem_group(el, tx=x, ty=y - 2, s=0.36, grad=f"m_{el}",
                                      extra='filter="url(#glow)"', cuts=False))
    center = emblem_group("light", tx=55, ty=66, s=0.42, grad="m_light", extra='filter="url(#glow)"', cuts=False)
    return "".join(minis) + center + atom(22, 22, 13) + atom(130, 154, 13)


def defs(elem):
    p = PAL[elem]
    d = [
        f'<linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">'
        f'<stop offset="0" stop-color="{p["dark"]}"/><stop offset=".45" stop-color="{p["mid"]}"/>'
        f'<stop offset=".6" stop-color="{p["mid"]}"/><stop offset="1" stop-color="{p["dark"]}"/></linearGradient>',
        f'<radialGradient id="lensG" cx=".5" cy=".5" r=".55"><stop offset="0" stop-color="{p["lens"]}" stop-opacity=".95"/>'
        f'<stop offset=".7" stop-color="{p["lens"]}" stop-opacity=".35"/><stop offset="1" stop-color="{p["lens"]}" stop-opacity="0"/></radialGradient>',
        f'<linearGradient id="emb" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2="100"><stop offset="0" stop-color="#FFFFFF"/>'
        f'<stop offset=".45" stop-color="#FFFFFF" stop-opacity=".98"/><stop offset="1" stop-color="{p["tint"]}"/></linearGradient>',
        '<linearGradient id="fadeTR" x1="1" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff"/><stop offset=".55" stop-color="#fff" stop-opacity="0"/></linearGradient>',
        f'<linearGradient id="embC" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="{p["tint"]}"/></linearGradient>',
        '<mask id="mTR"><rect width="152" height="176" fill="url(#fadeTR)"/></mask>',
        '<linearGradient id="fadeBL" x1="0" y1="1" x2="1" y2="0"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="#fff" stop-opacity="0"/></linearGradient>',
        '<mask id="mBL"><rect width="152" height="176" fill="url(#fadeBL)"/></mask>',
        '<pattern id="px" width="9" height="9" patternUnits="userSpaceOnUse"><rect x="3" y="3" width="3" height="3" fill="#fff"/></pattern>',
        '<pattern id="hatch" width="7" height="7" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><rect width="1.2" height="7" fill="#fff"/></pattern>',
        '<clipPath id="card"><rect x="5" y="5" width="142" height="166" rx="15"/></clipPath>',
        '<filter id="sh" x="-25%" y="-25%" width="150%" height="150%">'
        '<feDropShadow dx="0" dy="3" stdDeviation="2.6" flood-color="#000" flood-opacity=".55"/></filter>',
    ]
    if elem == "wild":
        d.append('<linearGradient id="rainbow" x1="0" y1="0" x2="1" y2="1">'
                 '<stop offset="0" stop-color="#FF4A3A"/><stop offset=".2" stop-color="#FFB02E"/>'
                 '<stop offset=".4" stop-color="#4FD65A"/><stop offset=".6" stop-color="#2EC9E0"/>'
                 '<stop offset=".8" stop-color="#3D7BFF"/><stop offset="1" stop-color="#B04CFF"/></linearGradient>')
        d.append('<linearGradient id="rainbowS" x1="0" y1="0" x2="1" y2="1">'
                 '<stop offset="0" stop-color="#FF5A3D"/><stop offset=".33" stop-color="#FFC93C"/>'
                 '<stop offset=".66" stop-color="#46E0E8"/><stop offset="1" stop-color="#B06BFF"/></linearGradient>')
        d.append('<filter id="glow" x="-40%" y="-40%" width="180%" height="180%">'
                 '<feDropShadow dx="0" dy="0" stdDeviation="1.6" flood-color="#000" flood-opacity=".8"/></filter>')
        for el in ("dragon", "knight", "nature", "light", "dark", "capsule"):
            d.append(f'<linearGradient id="m_{el}" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2="100">'
                     f'<stop offset="0" stop-color="#FFFFFF"/><stop offset=".35" stop-color="{UI[el]}"/>'
                     f'<stop offset="1" stop-color="{PAL[el]["mid"]}"/></linearGradient>')
        d.append('<linearGradient id="mc_capsule" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#C89A5A"/></linearGradient>')
    return "<defs>" + "".join(d) + "</defs>"


LENS = 'cx="76" cy="88" rx="58" ry="112" transform="rotate(-27 76 88)"'


def card_svg(elem):
    p = PAL[elem]
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', defs(elem)]
    parts.append('<g clip-path="url(#card)">')
    parts.append(f'<rect width="{W}" height="{H}" fill="url(#bg)"/>')
    if elem == "wild":
        parts.append(f'<ellipse {LENS} fill="url(#rainbow)"/>')
        parts.append(f'<ellipse {LENS} fill="#000" fill-opacity=".12"/>')
    else:
        parts.append(f'<ellipse {LENS} fill="url(#lensG)"/>')
    # textura: pixels no canto sup-dir, hachura no inf-esq, faixas diagonais nas pontas
    parts.append('<rect width="152" height="176" fill="url(#px)" opacity=".2" mask="url(#mTR)"/>')
    parts.append('<rect width="152" height="176" fill="url(#hatch)" opacity=".1" mask="url(#mBL)"/>')
    parts.append('<g fill="#fff" opacity=".09">'
                 '<path d="M5 34 L34 5 L42 5 L5 42 Z"/><path d="M5 52 L52 5 L56 5 L5 56 Z"/>'
                 '<path d="M147 142 L118 171 L110 171 L147 134 Z"/><path d="M147 124 L100 171 L96 171 L147 120 Z"/></g>')
    parts.append('<g fill="#000" opacity=".18"><circle cx="30" cy="150" r="1.5"/><circle cx="40" cy="160" r="1.5"/>'
                 '<path d="M14 136 L28 136 L36 144 L52 144" stroke="#000" stroke-width="1.2" fill="none"/></g>')
    # arco
    parts.append(f'<ellipse {LENS} fill="none" stroke="#FFFFFF" stroke-width="5"/>')
    # emblema
    parts.append('<g filter="url(#sh)">')
    if elem == "capsule":
        parts.append(capsule_art())
    elif elem == "wild":
        parts.append(wild_art())
    else:
        parts.append(emblem_group(elem))
    parts.append('</g>')
    parts.append('</g>')
    # moldura
    parts.append('<rect x="5" y="5" width="142" height="166" rx="15" fill="none" stroke="#FFFFFF" stroke-width="5"/>')
    parts.append('<rect x="2" y="2" width="148" height="172" rx="18" fill="none" stroke="#000" stroke-opacity=".6" stroke-width="2.5"/>')
    parts.append("</svg>")
    return "".join(parts)


ORDER = ["dragon", "knight", "nature", "light", "dark", "capsule", "wild"]
REF = {"dragon": "01_dragao_vermelho.png", "knight": "02_cavaleiro_azul.png", "nature": "03_natureza_verde.png",
       "light": "04_luz_amarela.png", "dark": "06_trevas_roxo.png", "capsule": "07_capzula_roxo.png",
       "wild": "08_wild_card.png"}


def main():
    for el in ORDER:
        (HERE / f"card-{el}.svg").write_text(card_svg(el), encoding="utf-8")
    print("svgs:", ", ".join(f"card-{e}.svg" for e in ORDER))

    if "--compare" in sys.argv:
        out = Path(sys.argv[sys.argv.index("--compare") + 1])
        rows = []
        for el in ORDER:
            ref = (REFS / REF[el]).as_uri()
            mine = (HERE / f"card-{el}.svg").as_uri()
            rows.append(f'<div class="p"><img class="r" src="{ref}"><img class="m" src="{mine}">'
                        f'<img class="s" src="{mine}"><div>{el}</div></div>')
        html = ('<!doctype html><html><body style="margin:0;background:#16130D;color:#aaa;font:11px system-ui">'
                '<style>.w{display:flex;gap:14px;padding:12px;flex-wrap:wrap}.p{display:flex;gap:6px;align-items:flex-end}'
                '.r{width:132px;height:189px}.m{width:152px;height:176px}.s{width:76px;height:88px}</style>'
                '<div class="w">' + "".join(rows) + "</div></body></html>")
        out.write_text(html, encoding="utf-8")
        print("compare:", out)


if __name__ == "__main__":
    main()
