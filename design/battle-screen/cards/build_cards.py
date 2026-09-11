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
    # mid/dark = fundo | glow = brilho atras do emblema | tint = pe do degrade | shade = recortes
    "dragon":  dict(mid="#7E3223", dark="#24110B", glow="#C0573F", tint="#EDB9A9", shade="#3A140C"),
    "knight":  dict(mid="#2E587C", dark="#0E1A26", glow="#4F88B6", tint="#C8DBEA", shade="#0F2233"),
    "nature":  dict(mid="#3A6536", dark="#111D10", glow="#5E9A56", tint="#CDE3C5", shade="#12230F"),
    "light":   dict(mid="#AC8A12", dark="#2B2204", glow="#EEC42C", tint="#F9ECA5", shade="#2F2504"),
    "dark":    dict(mid="#553A7A", dark="#181122", glow="#8660B4", tint="#D9CAEA", shade="#1D1229"),
    "capsule": dict(mid="#5E3A24", dark="#1A0F09", glow="#94593A", tint="#E4C4AC", shade="#20110A"),
    "wild":    dict(mid="#1B1914", dark="#080706", glow="#3A3527", tint="#CFC8B8", shade="#050404"),
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

EMB["wild"] = dict(parts=[
    # infinito com lacos afilados para o centro (furos pelo evenodd)
    "M50 50 C60 36 72 27 85 31 C99 35 101 64 86 69 C73 73 60 64 50 50 "
    "C40 36 28 27 15 31 C1 35 -1 64 14 69 C27 73 40 64 50 50 Z "
    "M57 50 C64 41 74 36 83 39 C92 42 92 58 83 61 C74 64 64 59 57 50 Z "
    "M43 50 C36 41 26 36 17 39 C8 42 8 58 17 61 C26 64 36 59 43 50 Z",
    # faisca de 4 pontas cruzando o no
    "M50 4 C52 34 54 44 63 50 C54 56 52 66 50 96 C48 66 46 56 37 50 C46 44 48 34 50 4 Z",
], cuts=[], evenodd=True, halo="M50 -2 C53 32 56 43 68 50 C56 57 53 68 50 102 C47 68 44 57 32 50 C44 43 47 32 50 -2 Z")


TRACED = HERE / "traced.json"
if TRACED.exists():
    import json as _json
    for _el, _d in _json.loads(TRACED.read_text(encoding="utf-8")).items():
        EMB[_el] = dict(parts=[_d], cuts=[], evenodd=True)


def emblem_group(elem, tx=25, ty=33, s=1.02, grad="emb", extra="", cuts=True):
    e = EMB[elem]
    out = [f'<g transform="translate({tx} {ty}) scale({s})" {extra}>']
    rule = ' fill-rule="evenodd"' if e.get("evenodd") else ""
    for i, d in enumerate(e["parts"]):
        if i == len(e["parts"]) - 1 and e.get("halo"):
            out.append(f'<path d="{e["halo"]}" fill="#0B0A08"/>')
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
<g transform="translate(76 86) rotate(-42) scale(.9)">
  <path d="M-4 -19 L-40 -19 A19 19 0 0 0 -40 19 L-4 19 Z" fill="url(#embC)"/>
  <path d="M4 -19 L40 -19 A19 19 0 0 1 40 19 L4 19 Z" fill="url(#embC)" opacity=".92"/>
  <path d="M-44 -12 L-8 -12" stroke="#FBF6EA" stroke-width="5" stroke-linecap="round" opacity=".5"/>
  <path d="M10 -12 L42 -12" stroke="#FBF6EA" stroke-width="5" stroke-linecap="round" opacity=".4"/>
  <path d="M-4 -19 L-4 19 M4 -19 L4 19" stroke="#2E200C" stroke-width="1.2" opacity=".35"/>
</g>
<g stroke-width="1.6">
  <rect x="58" y="62" width="15" height="15" fill="#F5EFE2" fill-opacity=".22" stroke="#F5EFE2" stroke-opacity=".8"/>
  <rect x="70" y="76" width="12" height="12" fill="#2A1C0A" fill-opacity=".35" stroke="#2A1C0A" stroke-opacity=".7"/>
  <rect x="80" y="58" width="13" height="13" fill="#F5EFE2" fill-opacity=".3" stroke="#F5EFE2" stroke-opacity=".8"/>
  <rect x="46" y="74" width="10" height="10" fill="#2A1C0A" fill-opacity=".3" stroke="#2A1C0A" stroke-opacity=".6"/>
  <rect x="64" y="46" width="9" height="9" fill="#F5EFE2" fill-opacity=".45" stroke="#F5EFE2" stroke-opacity=".8"/>
  <rect x="88" y="80" width="9" height="9" fill="#2A1C0A" fill-opacity=".3" stroke="#2A1C0A" stroke-opacity=".6"/>
  <rect x="54" y="90" width="7" height="7" fill="#F5EFE2" fill-opacity=".5" stroke="#F5EFE2" stroke-opacity=".8"/>
  <rect x="94" y="48" width="6" height="6" fill="#F5EFE2" fill-opacity=".4" stroke="#F5EFE2" stroke-opacity=".8"/>
  <rect x="42" y="58" width="6" height="6" fill="#F5EFE2" fill-opacity=".55" stroke="#F5EFE2" stroke-opacity=".8"/>
  <rect x="78" y="96" width="5" height="5" fill="#F5EFE2" fill-opacity=".5" stroke="#F5EFE2" stroke-opacity=".8"/>
</g>"""


ACCENT = "#F2A33C"   # ambar do Terminal
CREAM = "#F5EFE2"    # texto/linha do Terminal
CX, CY, R = 76, 86, 50

# cores dos 5 elementos nos detalhes da Wild (apagadas de proposito)
WILD_TICKS = [("#C0573F", -90), ("#C49E45", -18), ("#5E9A56", 54), ("#4F88B6", 126), ("#8660B4", 198)]


def defs(elem):
    p = PAL[elem]
    d = [
        f'<linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">'
        f'<stop offset="0" stop-color="{p["mid"]}"/><stop offset=".55" stop-color="{p["dark"]}"/>'
        f'<stop offset="1" stop-color="#0B0A08"/></linearGradient>',
        f'<radialGradient id="glow" cx="{CX}" cy="{CY}" r="62" gradientUnits="userSpaceOnUse">'
        f'<stop offset="0" stop-color="{p["glow"]}" stop-opacity=".75"/><stop offset=".6" stop-color="{p["glow"]}" stop-opacity=".22"/>'
        f'<stop offset="1" stop-color="{p["glow"]}" stop-opacity="0"/></radialGradient>',
        f'<linearGradient id="emb" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2="100">'
        f'<stop offset="0" stop-color="#FBF7EE"/><stop offset=".45" stop-color="#F4EEE1"/><stop offset="1" stop-color="{p["tint"]}"/></linearGradient>',
        f'<linearGradient id="embC" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FBF7EE"/><stop offset="1" stop-color="{p["tint"]}"/></linearGradient>',
        '<linearGradient id="fadeTR" x1="1" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="#fff" stop-opacity="0"/></linearGradient>',
        '<mask id="mTR"><rect width="152" height="176" fill="url(#fadeTR)"/></mask>',
        '<pattern id="px" width="9" height="9" patternUnits="userSpaceOnUse"><rect x="3" y="3" width="2.5" height="2.5" fill="#fff"/></pattern>',
        '<pattern id="scan" width="4" height="3" patternUnits="userSpaceOnUse"><rect width="4" height="1" fill="#000"/></pattern>',
        '<clipPath id="card"><rect x="4" y="4" width="144" height="168" rx="14"/></clipPath>',
        '<filter id="sh" x="-25%" y="-25%" width="150%" height="150%">'
        '<feDropShadow dx="0" dy="3" stdDeviation="2.6" flood-color="#000" flood-opacity=".6"/></filter>',
    ]
    return "<defs>" + "".join(d) + "</defs>"


def ring(elem):
    """Anel de instrumento no lugar do arco: mostrador com marcacoes e trecho de leitura em ambar."""
    import math
    out = [f'<circle cx="{CX}" cy="{CY}" r="{R}" fill="none" stroke="{CREAM}" stroke-opacity=".30" stroke-width="1.4"/>',
           f'<circle cx="{CX}" cy="{CY}" r="{R - 7}" fill="none" stroke="{CREAM}" stroke-opacity=".12" stroke-width="1" stroke-dasharray="2 4"/>']
    for i in range(48):
        ang = math.radians(i * 7.5 - 90)
        major = i % 6 == 0
        r0, r1 = R + 2, R + (8 if major else 5)
        x0, y0 = CX + r0 * math.cos(ang), CY + r0 * math.sin(ang)
        x1, y1 = CX + r1 * math.cos(ang), CY + r1 * math.sin(ang)
        out.append(f'<path d="M{x0:.1f} {y0:.1f} L{x1:.1f} {y1:.1f}" stroke="{CREAM}" '
                   f'stroke-opacity="{.55 if major else .22}" stroke-width="{1.6 if major else 1}"/>')
    a0, a1 = math.radians(-150), math.radians(-30)
    rr = R + 11
    x0, y0 = CX + rr * math.cos(a0), CY + rr * math.sin(a0)
    x1, y1 = CX + rr * math.cos(a1), CY + rr * math.sin(a1)
    out.append(f'<path d="M{x0:.1f} {y0:.1f} A{rr} {rr} 0 0 1 {x1:.1f} {y1:.1f}" fill="none" stroke="{ACCENT}" '
               f'stroke-opacity=".55" stroke-width="1.6" stroke-dasharray="1 3"/>')
    if elem == "wild":
        for col, deg in WILD_TICKS:
            ang = math.radians(deg)
            x, y = CX + R * math.cos(ang), CY + R * math.sin(ang)
            out.append(f'<rect x="{x - 3:.1f}" y="{y - 3:.1f}" width="6" height="6" transform="rotate(45 {x:.1f} {y:.1f})" '
                       f'fill="{col}" stroke="#0B0A08" stroke-width="1"/>')
    return "".join(out)


def brackets():
    L, k = 13, 12
    pts = [(k, k, 1, 1), (152 - k, k, -1, 1), (k, 176 - k, 1, -1), (152 - k, 176 - k, -1, -1)]
    return "".join(f'<path d="M{x} {y + dy * L} L{x} {y} L{x + dx * L} {y}" fill="none" stroke="{ACCENT}" '
                   f'stroke-opacity=".7" stroke-width="2"/>' for x, y, dx, dy in pts)


def card_svg(elem):
    p = PAL[elem]
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', defs(elem)]
    parts.append('<g clip-path="url(#card)">')
    parts.append(f'<rect width="{W}" height="{H}" fill="url(#bg)"/>')
    parts.append(f'<circle cx="{CX}" cy="{CY}" r="66" fill="url(#glow)"/>')
    parts.append('<rect width="152" height="176" fill="url(#px)" opacity=".09" mask="url(#mTR)"/>')
    top = p["glow"] if elem != "wild" else CREAM
    parts.append(f'<rect x="4" y="4" width="144" height="3" fill="{top}" opacity="{.85 if elem != "wild" else .35}"/>')
    parts.append(ring(elem))
    parts.append(brackets())
    parts.append('<g filter="url(#sh)">')
    if elem == "capsule":
        parts.append(capsule_art())
    else:
        s_ = 0.94 if elem != "wild" else 0.9
        parts.append(emblem_group(elem, tx=CX - 50 * s_, ty=CY - 50 * s_, s=s_))
    parts.append('</g>')
    parts.append('<rect width="152" height="176" fill="url(#scan)" opacity=".16"/>')
    parts.append('</g>')
    parts.append(f'<rect x="4" y="4" width="144" height="168" rx="14" fill="none" stroke="{CREAM}" stroke-opacity=".55" stroke-width="3"/>')
    parts.append('<rect x="1.5" y="1.5" width="149" height="173" rx="16.5" fill="none" stroke="#000" stroke-opacity=".7" stroke-width="2.5"/>')
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
            ref = (HERE.parent / "export" / "cards" / f"card-{el}@2x.png").as_uri()
            mine = (HERE / f"card-{el}.svg").as_uri()
            rows.append(f'<div class="p"><img class="r" src="{ref}"><img class="m" src="{mine}">'
                        f'<img class="s" src="{mine}"><div>{el}</div></div>')
        html = ('<!doctype html><html><body style="margin:0;background:#16130D;color:#aaa;font:11px system-ui">'
                '<style>.w{display:flex;gap:14px;padding:12px;flex-wrap:wrap}.p{display:flex;gap:6px;align-items:flex-end}'
                '.r{width:152px;height:176px}.m{width:152px;height:176px}.s{width:76px;height:88px}</style>'
                '<div class="w">' + "".join(rows) + "</div></body></html>")
        out.write_text(html, encoding="utf-8")
        print("compare:", out)


if __name__ == "__main__":
    main()
