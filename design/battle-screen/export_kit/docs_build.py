"""Gera data/*.json complementares e docs/*.md do kit, a partir do layout medido.

Rodar DEPOIS de export.py.
"""
import json
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
SCREEN = HERE.parent
KIT = SCREEN.parent.parent / "docs" / "ilha-digital-godot-kit"
DATA = KIT / "data"
DOCS = KIT / "docs"

VIS = {"x": 24, "y": 232, "w": 976, "h": 736, "radius": 32}

POS = {  # espelho de this.POS em Main.dc.html (x%, y% do pe no visor, largura do quadro em pt)
    "A1": (15, 46, 100), "A2": (37, 42, 96), "A3": (26, 65, 106), "A4": (12, 90, 114), "A5": (40, 91, 114),
    "E1": (76, 50, 168), "E2": (62, 88, 126), "E3": (87, 90, 126), "BOSS": (72, 80, 224),
}
ROSTER = {
    "A1": ("ally_01_crimson_clamp_256.png", "Crimson Clamp", "dragon", "aliado"),
    "A2": ("ally_02_bone_raider_256.png", "Bone Raider", "dark", "aliado"),
    "A3": ("ally_03_panda_gunner_256.png", "Panda Gunner", "knight", "aliado"),
    "A4": ("ally_04_twin_apes_256.png", "Twin Apes", "light", "aliado"),
    "A5": ("ally_05_flora_fairy_256.png", "Flora Fairy", "nature", "aliado"),
    "E1": ("boss_01_long_ear_guardian_512.png", "Long Ear Guardian", "light", "chefe (trio)"),
    "E2": ("enemy_01_dusk_dragon_256.png", "Dusk Dragon", "dark", "inimigo"),
    "E3": ("enemy_02_twin_tail_256.png", "Twin Tail", "nature", "inimigo"),
    "BOSS": ("boss_01_long_ear_guardian_512.png", "Long Ear Guardian", "light", "chefe sozinho"),
}

PALETTE = {
    "shell": "#16130D", "surface": "#201C13", "surface_popup": "#100D09",
    "amber": "#F2A33C", "cream": "#F5EFE2", "cream_emblem": "#F4EEE1",
    "mint": "#6FE3B8", "danger": "#FF6B4A", "ring_enemy_hp": "#FF4A3A", "danger_imminent_bg": "#FF4A2E",
    "text_primary": "#F5EFE2",
    "text_alpha": {"65%": "rgba(245,239,226,.65)", "55%": "rgba(245,239,226,.55)", "45%": "rgba(245,239,226,.45)", "40%": "rgba(245,239,226,.40)", "35%": "rgba(245,239,226,.35)"},
    "amber_alpha": {"border_20%": "rgba(242,163,60,.20)", "border_28%": "rgba(242,163,60,.28)", "corner_75%": "rgba(242,163,60,.75)", "segment_off_18%": "rgba(242,163,60,.18)"},
    "element_ui": {"dragon": "#FF5A3D", "knight": "#4DA8FF", "nature": "#5BD75B", "light": "#FFC93C", "dark": "#B06BFF", "capsule": "#C89A5A", "wild": "#CFCFE4"},
    "element_card": {
        "dragon": {"mid": "#7E3223", "dark": "#24110B", "glow": "#C0573F", "tint": "#EDB9A9"},
        "knight": {"mid": "#2E587C", "dark": "#0E1A26", "glow": "#4F88B6", "tint": "#C8DBEA"},
        "nature": {"mid": "#3A6536", "dark": "#111D10", "glow": "#5E9A56", "tint": "#CDE3C5"},
        "light": {"mid": "#AC8A12", "dark": "#2B2204", "glow": "#EEC42C", "tint": "#F9ECA5"},
        "dark": {"mid": "#553A7A", "dark": "#181122", "glow": "#8660B4", "tint": "#D9CAEA"},
        "capsule": {"mid": "#5E3A24", "dark": "#1A0F09", "glow": "#94593A", "tint": "#E4C4AC"},
        "wild": {"mid": "#1B1914", "dark": "#080706", "glow": "#3A3527", "tint": "#CFC8B8"},
    },
    "team_hp_thresholds": {"above_40%": "#6FE3B8", "40%_to_20%": "#F2A33C", "below_20%": "#FF6B4A"},
    "turn_counter": {"3": "rgba(242,163,60,.75)", "2": "#F2A33C", "1_imminent": "#FF6B4A (pisca 0.8s)"},
}

CARDS = {
    "dragon": {"power": 4, "element": True}, "knight": {"power": 7, "element": True}, "nature": {"power": 6, "element": True},
    "light": {"power": 9, "element": True}, "dark": {"power": 8, "element": True},
    "capsule": {"power": 5, "element": False, "note": "so carta; 3 capsules curam"},
    "wild": {"power": 10, "element": False, "note": "so carta; substitui qualquer elemento"},
}


def stage_positions():
    out = {"visor": VIS, "foot_anchor_in_png": {"256": [128, 248], "512": [256, 504]},
           "rules": {"frame_px": "w_pt * 2", "sprite_top_left": "(foot_x - frame/2, foot_y - frame*0.97)",
                     "ring_rx": "frame * 0.34", "ring_ry": "ring_rx * 0.3", "ring_center": "no pe",
                     "chip_top": "foot_y + ring_ry + 2", "hit_area": "largura frame*0.62, altura frame*0.97*0.9, acima do pe"},
           "slots": {}}
    for slot, (x, y, w) in POS.items():
        f = w * 2
        fx = VIS["x"] + x / 100 * VIS["w"]
        fy = VIS["y"] + y / 100 * VIS["h"]
        rx = round(w * .34) * 2
        ry = round(w * .34 * .3) * 2
        file, name, el, role = ROSTER[slot]
        out["slots"][slot] = {
            "role": role, "name": name, "element": el, "sprite": ("characters/" if slot.startswith("A") else "enemies/") + file,
            "foot_pct_in_visor": [x, y], "frame_pt": w,
            "foot_px_1024": [round(fx, 1), round(fy, 1)], "frame_px_1024": f,
            "sprite_rect_px_1024": [round(fx - f / 2, 1), round(fy - round(w * .97) * 2, 1), f, f],
            "ring_px_1024": {"cx": round(fx, 1), "cy": round(fy, 1), "rx": rx, "ry": ry,
                             "textures": f"hud/stage/ring_{slot}_under|progress|over.png"},
            "chip_top_px_1024": round(fy + ry + 2, 1),
        }
    return out


def table(rows, headers):
    s = "| " + " | ".join(headers) + " |\n|" + "---|" * len(headers) + "\n"
    for r in rows:
        s += "| " + " | ".join(str(c) for c in r) + " |\n"
    return s


def main():
    lay = json.loads((DATA / "layout_1024x1600.json").read_text(encoding="utf-8"))
    comps = json.loads((DATA / "components.json").read_text(encoding="utf-8"))
    typo = json.loads((DATA / "typography.json").read_text(encoding="utf-8"))
    L = lay["padrao"]

    # pelicula de scanline: o recorte por alfa perde as 2 ultimas linhas transparentes -> volta ao tamanho do visor
    scan = KIT / "assets" / "background" / "visor_film_scanline_976x736.png"
    im = Image.open(scan).convert("RGBA")
    if im.size != (976, 736):
        full = Image.new("RGBA", (976, 736), (0, 0, 0, 0)); full.paste(im, (0, 0)); full.save(scan, optimize=True)
        for c in comps:
            if c["file"].endswith("visor_film_scanline_976x736.png"):
                c["texture_rect_1024"].update({"x": 24, "y": 232, "w": 976, "h": 736})
        (DATA / "components.json").write_text(json.dumps(comps, ensure_ascii=False, indent=1), encoding="utf-8")

    (DATA / "palette.json").write_text(json.dumps(PALETTE, ensure_ascii=False, indent=1), encoding="utf-8")
    sp = stage_positions()
    (DATA / "stage_positions.json").write_text(json.dumps(sp, ensure_ascii=False, indent=1), encoding="utf-8")
    (DATA / "cards.json").write_text(json.dumps(
        {el: {**v, "textures": {n: f"cards/card_{el}@{n}.png" for n in ("1x", "2x", "4x")}, "svg_source": f"source/cards/card_{el}.svg",
              "emblem": f"icons/elements/emblem_{el}.svg", "size_1x": [76, 88], "size_in_screen_1024": [152, 176],
              "colors": PALETTE["element_card"][el]} for el, v in CARDS.items()}, ensure_ascii=False, indent=1), encoding="utf-8")
    man = json.loads((SCREEN / "art" / "_src" / "characters_manifest.json").read_text(encoding="utf-8"))
    by_file = {v[0]: (k, v) for k, v in ROSTER.items() if k != "BOSS"}
    for c in man["characters"]:
        if c["file"] in by_file:
            k, v = by_file[c["file"]]
            c.update({"slot": k, "name": v[1], "element_suggested": v[2]})
    (DATA / "characters_manifest.json").write_text(json.dumps(man, ensure_ascii=False, indent=1), encoding="utf-8")

    # mascara arredondada do visor (Godot recorta Control em retangulo)
    m = Image.new("L", (VIS["w"], VIS["h"]), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, VIS["w"] - 1, VIS["h"] - 1), radius=VIS["radius"], fill=255)
    rgba = Image.new("RGBA", m.size, (255, 255, 255, 0)); rgba.putalpha(m)
    rgba.save(KIT / "assets" / "background" / "visor_mask_976x736.png")

    DOCS.mkdir(exist_ok=True)
    sec = lambda k: L[k]
    blocks = ["header", "strip", "visor", "team", "bank", "bank_grid", "nav", "toast"]

    # ---------------- README
    counts = {}
    for p in (KIT / "assets").rglob("*"):
        if p.is_file():
            top = p.relative_to(KIT / "assets").parts[0]
            counts[top] = counts.get(top, 0) + 1
    readme = f"""# Ilha Digital — kit de UI para Godot

Tudo o que existe na tela de batalha **Terminal** do canvas, separado para recriar do zero no Godot 4.
Nada aqui depende do projeto antigo. Regras de batalha e animações ficam para uma etapa futura.

- Resolução de referência: **1024 × 1600** (2× do mockup 512 × 800). Todas as medidas dos docs e dos JSON estão nessa escala.
- Cada textura foi recortada do render real da tela (mesmo HTML/CSS do canvas), com fundo transparente.
- Onde uma peça tem texto, existe a versão `_ref` (com texto, para conferir) e a versão sem texto (caixa), para 9-slice.

## Estrutura

```
assets/
  background/   cenários 1024x1600, recortes do visor 976x736, película (scanline, vinheta), máscara do visor   ({counts.get('background', 0)})
  hud/          header, faixa de instrumentos, visor, anel de chão + chips, pop-up do alvo, HP da equipe, banco, avisos ({counts.get('hud', 0)})
  cards/        7 cartas em 1x/2x/4x + moldura de selecionada, selo de índice, placa de valor                   ({counts.get('cards', 0)})
  characters/   5 aliados (PNG 256, pé em 128,248)                                                                 ({counts.get('characters', 0)})
  enemies/      2 inimigos (256) + chefe (512, pé em 256,504)                                                       ({counts.get('enemies', 0)})
  icons/        emblemas dos elementos, selos, moedas, navegação, menu e coroa (SVG + PNG 48/96)                   ({counts.get('icons', 0)})
  buttons/      botões de navegação (normal/principal) e botão de líder (normal/ativo/recarga)                     ({counts.get('buttons', 0)})
fonts/          Instrument Sans e Martian Mono (variáveis, OFL)
data/           layout medido por estado, tipografia, paleta, posições do palco, cartas, personagens, componentes
reference/      a tela inteira em cada estado, overlay com os retângulos das peças e
                sequences/ — cada interação quadro a quadro (cartas, líder, skill, ataque, HP, abatido, pop-up, avisos)
source/         SVG-fonte das cartas
docs/           guia completo
```

## Leia nesta ordem
1. `docs/01_visao_geral.md` — anatomia da tela, camadas e estados
2. `docs/02_layout.md` — posição e tamanho de cada bloco
3. `docs/03_tema.md` — cores, tipografia, espessuras, efeitos
4. `docs/04_componentes.md` — cada componente, estados e texturas
5. `docs/05_palco.md` — cenário, personagens, anel de chão, mira e pop-up
6. `docs/06_godot.md` — como importar e montar no Godot 4
7. `docs/07_interacoes_e_animacoes.md` — o que cada toque faz, estados, tempos, curvas e as referências quadro a quadro
"""
    (KIT / "README.md").write_text(readme, encoding="utf-8")

    # ---------------- 01 visão geral
    states = {
        "padrao": "tela como abre: Tropical, indicador anel, pop-up fechado",
        "alvo_chefe": "toque no chefe: mira + pop-up ao lado (não cabe acima)",
        "alvo_inimigo": "toque em E2: mira + pop-up acima",
        "chefe_sozinho": "formação do último nível",
        "deserto": "cenário Deserto",
        "cartas_selecionadas": "duas cartas escolhidas, combo 2/3, líder ativo",
        "skill_pronta": "aliado com skill 100%: anel com brilho e chip PRONTA",
        "alertas": "ataque iminente, HP da equipe em alerta, líder em recarga, aviso âmbar",
        "aviso_vermelho": "aviso de ataque sofrido",
        "aviso_menta": "aviso de cura",
        "indicador_minimo": "variação antiga: fio fino sob os pés",
        "indicador_placa": "variação antiga: placas",
    }
    d1 = f"""# 01 · Visão geral

Tela de batalha vertical **1024 × 1600**, fundo `#16130D`.

## Blocos (de cima para baixo)
{table([(k, L[k]['x'], L[k]['y'], L[k]['w'], L[k]['h']) for k in blocks if k in L], ['bloco', 'x', 'y', 'w', 'h'])}
O aviso (`toast`) só existe quando aparece — ver estado `alertas`.

## Camadas do visor (de trás para frente)
1. **Cenário** — `background/bg_*_visor_976x736.png` (recorte x 24–1000 / y 232–968 da arte 1024×1600)
2. **Personagens** — para cada posição: anel de chão (under/progress/over) e por cima o sprite
3. **Película** — `visor_film_scanline_976x736.png` e depois `visor_film_vignette_976x736.png`
4. **HUD do visor** — cantoneiras, SETOR/ROUND, mira, chips, pop-up do alvo

O visor tem cantos de raio 32 — use `visor_mask_976x736.png` (ver 06_godot.md) e por cima `hud/visor/visor_frame.png`.

## Estados renderizados (`reference/screens/`)
{table([(f'`screen_{k}_1024x1600.png`', v) for k, v in states.items()], ['arquivo', 'o que mostra'])}
`reference/overlays/layout_debug_1024x1600.png` mostra os retângulos das peças principais com o nome de cada uma.
"""
    (DOCS / "01_visao_geral.md").write_text(d1, encoding="utf-8")

    # ---------------- 02 layout
    groups = [
        ("Header", "header"), ("Faixa de instrumentos", "strip"), ("Visor", "visor_"), ("Palco", "stage_fig_"),
        ("Chips", "chip_"), ("Pop-up do alvo", "popup_"), ("HP da equipe", "team"), ("Banco", "bank"), ("Cartas", "card_slot_"),
        ("Navegação", "button_nav_"), ("Líder", "button_leader"), ("Ícones", "icon_"),
    ]
    d2 = "# 02 · Layout (px em 1024 × 1600)\n\nMedido direto do render da tela. O arquivo completo, com todos os estados, é `data/layout_1024x1600.json`.\n\n"
    for title, pref in groups:
        src_state = "alvo_inimigo" if pref == "popup_" else ("cartas_selecionadas" if pref == "button_leader" else "padrao")
        rows = [(k, v["x"], v["y"], v["w"], v["h"], v.get("text", "")) for k, v in lay[src_state].items()
                if k == pref or k.startswith(pref)]
        if rows:
            d2 += f"## {title}" + (f" (estado `{src_state}`)" if src_state != "padrao" else "") + "\n\n" + table(rows, ["peça", "x", "y", "w", "h", "texto"]) + "\n"
    (DOCS / "02_layout.md").write_text(d2, encoding="utf-8")

    # ---------------- 03 tema
    trows = [(k, v.get("example", ""), v["family"], v.get("size_1024", ""), v["weight"], v.get("letterSpacing_1024", v.get("letterSpacing")), v["transform"], v["color"])
             for k, v in sorted(typo.items())]
    d3 = f"""# 03 · Tema

## Cores
| token | valor | uso |
|---|---|---|
| shell | `#16130D` | fundo da tela |
| surface | `#201C13` | faixa de instrumentos, botões de navegação, botão de líder |
| amber | `#F2A33C` | acento: cantoneiras, XP, seleção, botão FASES, líder ativo |
| cream | `#F5EFE2` | texto principal e linhas |
| mint | `#6FE3B8` | HP da equipe acima de 40%, SYNC, energia |
| danger | `#FF6B4A` | alvo, mira, ataque iminente, HP baixo |
| ring_enemy_hp | `#FF4A3A` | anel de vida dos inimigos |

Cores de elemento dos **anéis de chão** (vivas, para ler sobre o cenário): Dragon `#FF5A3D` · Knight `#4DA8FF` · Nature `#5BD75B` · Light `#FFC93C` · Dark `#B06BFF`.
Cores das **cartas e selos** (sóbrias): ver `data/palette.json → element_card`.

Opacidades de texto sobre o `shell`: 65%, 55%, 45%, 40%, 35% do cream (`data/palette.json → text_alpha`).

## Fontes (`fonts/`)
- **Instrument Sans** — nome do jogador, nome do alvo, LV dos chips, títulos.
- **Martian Mono** — todos os números, rótulos em caixa-alta (BITS, ROUND, ATQ…), avisos.

Rótulo padrão "tick": Martian Mono 14px (7pt), peso 400, espaçamento 1px, CAIXA-ALTA.

## Tipografia medida (px em 1024)
{table(trows, ['peça', 'exemplo', 'fonte', 'tamanho', 'peso', 'espaçamento', 'caixa', 'cor'])}

## Espessuras e efeitos
- Contornos finos: 2px (1pt) · cantoneiras: 3px (1.5pt), braço 32px no visor, 18px no avatar
- Barras segmentadas: segmento 10px + vão 4px (XP, HP da equipe, pop-up)
- Anel de chão: trilho 10px `rgba(8,10,12,.75)` com miolo `rgba(10,14,10,.38)`; progresso 6.4px; marcas 7.2px tracejadas
- Película: linhas pretas 15% a cada 6px; vinheta radial até 62% do shell nas bordas
- Pop-up: fundo `rgba(16,13,9,.94)`, contorno `rgba(255,107,74,.5)`, raio 16, sombra 0 12 36 60% preto
- Brilho de skill pronta: sombra da cor do elemento, raio 10px
"""
    (DOCS / "03_tema.md").write_text(d3, encoding="utf-8")

    # ---------------- 04 componentes
    by_dir = {}
    for c in comps:
        by_dir.setdefault(str(Path(c["file"]).parent).replace("\\", "/"), []).append(c)
    d4 = "# 04 · Componentes e texturas\n\n`texture_rect` = onde a textura se encaixa na tela 1024×1600 (já inclui sombra/brilho). `node` = retângulo do elemento sem a sombra — use para posicionar o Control e o 9-slice.\n\n"
    d4 += "Modos: **completo** (com ícones/texto, para conferência), **caixa** (só fundo/borda/sombra, sem conteúdo), **under / progress / over** (camadas de TextureProgressBar, todas no mesmo retângulo).\n\n"
    for folder in sorted(by_dir):
        rows = []
        for c in by_dir[folder]:
            t = c["texture_rect_1024"]; n = c["node_rect_1024"] or {}
            rows.append((f"`{Path(c['file']).name}`", c["mode"], c["state"], f"{t['x']},{t['y']} {t['w']}×{t['h']}",
                         f"{n.get('x','')},{n.get('y','')} {n.get('w','')}×{n.get('h','')}" if n else "", c.get("corner_radius_1024") or "", c["note"]))
        d4 += f"## `{folder}`\n\n" + table(rows, ["arquivo", "modo", "estado", "texture_rect", "node", "raio", "nota"]) + "\n"
    d4 += """## Ícones (`assets/icons/`)
Cada ícone existe como `.svg` (fonte, cor final embutida) e PNG 48 e 96.
- `elements/emblem_<elemento>` — emblemas creme das cartas (dragon, knight, nature, light, dark, wild, capsule)
- `elements/badge_<elemento>.png` — selo redondo do chip (fundo na cor da carta + emblema)
- `currency/` — bits, gemas, energia
- `nav/` — equipe, invocar, loja; fases em versão normal e principal
- `ui/` — menu e coroa (normal, ativa, recarga)

## Cartas (`assets/cards/`)
- `card_<elemento>@1x|2x|4x.png` — arte completa **sem número** (76×88 no 1x; na tela 1024 usa 152×176 = @2x)
- `card_value_plate.png` — placa do número (texto Martian Mono 19px branco, peso 600)
- `card_frame_selected.png` — anel âmbar da carta selecionada; a carta sobe 10px
- `card_order_badge.png` — selo 28×28 âmbar com o índice do combo (texto `#1A1105`, 16px, 600)
- Na fila, a mesma arte reduzida para 32×38.
"""
    (DOCS / "04_componentes.md").write_text(d4, encoding="utf-8")

    # ---------------- 05 palco
    rows = [(k, v["name"], v["role"], v["element"], f"{v['foot_pct_in_visor'][0]}% · {v['foot_pct_in_visor'][1]}%",
             f"{v['foot_px_1024'][0]}, {v['foot_px_1024'][1]}", v["frame_px_1024"], f"{v['ring_px_1024']['rx']}×{v['ring_px_1024']['ry']}", v["chip_top_px_1024"])
            for k, v in sp["slots"].items()]
    d5 = f"""# 05 · Palco

## Cenário
- Arte fonte: `background/bg_<nome>_1024x1600.png`. O visor mostra só **x 24–1000, y 232–968** → já recortado em `bg_<nome>_visor_976x736.png`.
- Horizonte por volta de 27–38% da altura do visor; chão andável dos 40% para baixo.
- O cenário **Trevas** veio corrompido no zip original e não entrou.

## Personagens
PNG com fundo transparente. **Pé** em (128, 248) nos quadros 256 e (256, 504) no quadro 512 do chefe.
Posicione cada sprite pelo pé; a largura do quadro na tela já cria a perspectiva (atrás menor, frente maior).

{table(rows, ['slot', 'nome', 'papel', 'elemento', 'pé no visor', 'pé em px', 'quadro px', 'anel rx×ry', 'topo do chip'])}
- Trio: A1–A5 + E1 (chefe) + E2 + E3. Chefe sozinho: A1–A5 + BOSS (E2/E3 somem).
- Ordem de desenho (trás → frente): A2, A1, E1, A3, E2, A4, E3, A5 (sozinho: A2, A1, A3, BOSS, A4, A5).
- Elementos atribuídos por aparência, para teste.
- Personagem abatido: 35% de opacidade + escala de cinza.

## Anel de chão
- Centro no pé. `rx = quadro × 0.34`, `ry = rx × 0.3` (valores prontos na tabela).
- Texturas por slot: `hud/stage/ring_<slot>_under.png` (trilho + sombra), `_progress.png` (anel cheio em branco), `_over.png` (marcas).
- Aliado: progresso = **skill**, cor do elemento (vivas, ver 03_tema). Com 100%: brilho da cor do elemento + chip com moldura âmbar e "PRONTA".
- Inimigo: progresso = **vida**, `#FF4A3A`. Começa no ponto mais à direita e enche no sentido horário (a frente enche primeiro).

## Chip
- Pilula `hud/stage/chip_ally_box.png` / `chip_enemy_box.png`, altura 30px, centralizada no pé, topo = pé + ry + 2.
- Conteúdo: selo 26px (`icons/elements/badge_<elemento>.png`), "LV" Instrument Sans 12px 70%, número Martian Mono 15px peso 600 com **largura mínima de 30px** (3 dígitos).
- Inimigo: 3 segmentos 10×5 + número de turnos. Cores: 3 = âmbar 75%, 2 = âmbar, 1 = `#FF6B4A` piscando.
- Alvo: `chip_frame_target.png` (anel vermelho). Skill pronta: `chip_frame_ready.png`.

## Mira
4 cantoneiras vermelhas `#FF6B4A` (braço 34px, traço 3px), quadrado de lado `round(quadro×0.97)×0.96`, centrado no meio da altura do personagem. Pisca de 60% a 100% em 1.4s.
Referências: `hud/visor/aim_chefe.png`, `aim_inimigo.png`, `aim_chefe_sozinho.png`.

## Pop-up do alvo
- **Fechado por padrão.** Toque no inimigo → abre e marca o alvo. Toque no mesmo → fecha. Outro inimigo → troca.
- Largura 344px. Se couber acima da cabeça (topo da cabeça − 148 − 24 > 52): abre **acima**, centralizado no alvo (limitado às bordas), seta `popup_target_arrow_down.png`.
- Senão abre **ao lado esquerdo**, no topo do visor (y = visor + 56), seta `popup_target_arrow_right.png`.
- Conteúdo: "ALVO · LV40" (tick vermelho) · % (tick 42%) · nome (Instrument Sans 21px 700) · barra de vida segmentada · "1850 / 4000 HP" (Martian Mono 16px 55%) · caixa ATQ com 3 segmentos e número.

Todos os números estão em `data/stage_positions.json`.
"""
    (DOCS / "05_palco.md").write_text(d5, encoding="utf-8")

    # ---------------- 06 godot
    d6 = """# 06 · Montando no Godot 4

## Projeto
- `display/window/size/viewport_width = 1024`, `viewport_height = 1600`
- `display/window/stretch/mode = canvas_items`, `aspect = keep` (ou `expand` se quiser ocupar telas mais altas)
- Orientação retrato.

## Importação de texturas
- HUD, botões, ícones, película e máscara: **Filter Linear**, **Mipmaps desligado** (são usados em 1:1).
- Cartas @2x, personagens e inimigos (aparecem reduzidos): Filter Linear, **Mipmaps ligado**.
- Se preferir o visual pixel duro nos personagens: Filter Nearest (teste nos dois).

## Fontes
Importe `fonts/*.ttf`. Crie `FontVariation` para os pesos usados:
- InstrumentSans: 700 (nome do jogador, nome do alvo, LV dos chips)
- MartianMono: 400 (rótulos tick), 500, 600 (números)
Ajuste `spacing_glyph` conforme o espaçamento em 03_tema.md (px em 1024).

## Árvore sugerida (nomes = nomes das peças em data/layout)
```
BattleScreen (Control 1024x1600, fundo ColorRect #16130D)
├─ Header            (Control 0,0 1024x132)
│  ├─ Avatar         TextureRect avatar + avatar_frame.png
│  ├─ Player         Label nome / rank, TextureProgressBar xp (xp_bar_under/progress)
│  └─ Sync           sync_dot.png, Label SYNC, TextureButton icon_menu
├─ Strip             NinePatchRect strip_bg.png + 3 células (ícone, Label, Label) + strip_rule.png
├─ Visor             Control 24,232 976x736
│  ├─ Clip           (máscara arredondada, ver abaixo)
│  │  ├─ Background  TextureRect bg_*_visor_976x736.png
│  │  ├─ Stage       Node2D/Control: por slot → Ring (3x TextureProgressBar) + Sprite
│  │  ├─ Scanline    TextureRect visor_film_scanline
│  │  └─ Vignette    TextureRect visor_film_vignette
│  ├─ Frame          visor_frame.png
│  ├─ Corners        visor_corner_tl/tr/bl/br
│  ├─ Sector/Round   Labels
│  ├─ Aim            4 cantoneiras (ou aim_*.png)
│  ├─ Chips          por slot: NinePatchRect chip_*_box + badge + Labels (+ turno)
│  └─ PopupTarget    NinePatchRect popup_target_box + seta + Labels + TextureProgressBar
├─ Team              Label, TextureProgressBar team_hp, Label, TextureButton líder
├─ Bank              cabeçalho (Label, combo, bank_rule, fila) + GridContainer 6x2 de cartas
├─ Nav               4 TextureButton (button_nav_normal / primary) + ícone + Label
└─ Toast             NinePatchRect toast_box_* + Label
```

## Cantos arredondados do visor
Control só recorta em retângulo. Duas opções:
1. `CanvasGroup` no `Clip` com shader que multiplica o alpha por `visor_mask_976x736.png`.
2. Ou `clip_children = CLIP_CHILDREN_ONLY` num `TextureRect` com a própria máscara (Godot 4.1+).

## 9-slice
Use `NinePatchRect` (ou `StyleBoxTexture`) nas texturas de modo **caixa**. Margem = raio do canto + folga da sombra.
O `texture_rect` e o `node` de cada textura estão em `data/components.json`: a diferença entre eles é a folga da sombra de cada lado.

## Barras (TextureProgressBar)
- XP, HP da equipe, vida do pop-up: `fill_mode = LEFT_TO_RIGHT`, `texture_under` = `*_under.png`, `texture_progress` = `*_progress*.png`.
- HP da equipe: use `team_hp_progress.png` (branco) com `tint_progress` pela regra de limiar, ou as versões já coloridas.

## Anel de chão (TextureProgressBar)
- `texture_under` = `ring_<slot>_under.png`, `texture_progress` = `ring_<slot>_progress.png`, `texture_over` = `ring_<slot>_over.png`
- `fill_mode = CLOCKWISE`, `radial_initial_angle = 90`, `radial_fill_degrees = 360`
- `tint_progress` = cor do elemento (aliado) ou `#FF4A3A` (inimigo)
- Posição: use o `texture_rect` do `components.json` (as 3 camadas compartilham o mesmo retângulo).

## Animações que já existem no mockup (para a etapa de animação)

Resumo abaixo. O detalhamento completo — gatilhos, estados, linha do tempo do combo, textos dos avisos e referências quadro a quadro — está em **`07_interacoes_e_animacoes.md`**.

- Mira: opacidade 0.6 ↔ 1.0, 1.4s, ease-in-out, loop
- Ataque iminente (chip, caixa ATQ): opacidade 1 ↔ 0.5, 0.8s, loop
- Pop-up e aviso: entrada com opacidade 0→1 e deslocamento 10px→0 em 0.16–0.18s
- Carta selecionada: sobe 10px em 0.12s
- Barras e anéis: transição do valor em 0.3s
"""
    (DOCS / "06_godot.md").write_text(d6, encoding="utf-8")
    import shutil
    for f in (HERE / "static_docs").glob("*.md"):
        shutil.copy(f, DOCS / f.name)
    print("docs + data ok")


if __name__ == "__main__":
    main()
