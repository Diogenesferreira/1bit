"""Gera o pacote ilha-digital-godot-kit a partir da tela do canvas.

Uso: python export.py   (demora alguns minutos: cada peca e um render do Chrome)
"""
import json
import shutil
import subprocess
import tempfile
from pathlib import Path

from PIL import Image

from render import Renderer, CHROME, SCREEN

KIT = SCREEN.parent.parent / "docs" / "ilha-digital-godot-kit"
A = KIT / "assets"
S2 = 2  # tudo em 1024x1600

STATES = {
    "padrao": {},
    "alvo_chefe": {"actions": [["target", 0]]},
    "alvo_inimigo": {"actions": [["target", 1]]},
    "chefe_sozinho": {"props": {"soloBoss": True}, "actions": [["target", 0]]},
    "deserto": {"props": {"cenario": "deserto"}},
    "cartas_selecionadas": {"actions": [["pick", 0], ["pick", 7], ["crown"]]},
    "skill_pronta": {"patch": {"allies.2.skill": 100}},
    "alertas": {"patch": {"enemies.0.atk": 1}, "after": {"teamHp": 540, "leaderCd": 2, "toast": "DANO 340 · DRAGON", "toastOn": True, "toastTone": "amber"}},
    "aviso_vermelho": {"after": {"toast": "LONG EAR GUARDIAN ATACOU · -220", "toastOn": True, "toastTone": "red"}},
    "aviso_menta": {"after": {"toast": "CURA +770", "toastOn": True, "toastTone": "mint"}},
    "indicador_minimo": {"props": {"indicador": "minimo"}},
    "indicador_placa": {"props": {"indicador": "placa"}},
}

ALLY_EL = {"A1": "dragon", "A2": "dark", "A3": "knight", "A4": "light", "A5": "nature"}
SLOTS = ["A1", "A2", "A3", "A4", "A5", "E1", "E2", "E3"]

rd = Renderer()
TMP = Path(tempfile.mkdtemp(prefix="kitparts_"))
components = []
_measure_cache = {}


def measure(state):
    if state not in _measure_cache:
        _measure_cache[state] = rd.measure(STATES[state])
    return _measure_cache[state]


def rect2(r):
    return {"x": round(r["x"] * S2, 1), "y": round(r["y"] * S2, 1), "w": round(r["w"] * S2, 1), "h": round(r["h"] * S2, 1)}


def render_part(part, state="padrao", box=False, hide=None, css=""):
    cfg = dict(STATES[state])
    cfg.update({"part": part, "box": box, "hide": hide or [], "css": css})
    p = TMP / f"{part}_{state}_{int(box)}_{abs(hash(css)) % 99999}.png"
    rd.shot(p, cfg, transparent=True)
    return Image.open(p).convert("RGBA")


def save_group(items, note=""):
    """items: [(out_path, image, part, state, mode)] -> recorta todos pelo mesmo retangulo (uniao)."""
    boxes = [im.getchannel("A").getbbox() for _, im, *_ in items]
    boxes = [b for b in boxes if b]
    if not boxes:
        print("  !! vazio:", [str(i[0].name) for i in items])
        return
    x0 = min(b[0] for b in boxes); y0 = min(b[1] for b in boxes)
    x1 = max(b[2] for b in boxes); y1 = max(b[3] for b in boxes)
    for out, im, part, state, mode in items:
        out.parent.mkdir(parents=True, exist_ok=True)
        im.crop((x0, y0, x1, y1)).save(out, optimize=True)
        node = measure(state).get(part)
        components.append({
            "file": out.relative_to(KIT).as_posix(), "part": part, "state": state, "mode": mode,
            "texture_rect_1024": {"x": x0, "y": y0, "w": x1 - x0, "h": y1 - y0},
            "node_rect_1024": rect2(node) if node else None,
            "corner_radius_1024": (float(node["radius"].replace("px", "")) * S2 if node and node.get("radius", "0px").endswith("px") else None),
            "note": note,
        })
        print("  ", out.relative_to(KIT))


def one(out, part, state="padrao", box=False, hide=None, css="", note=""):
    save_group([(out, render_part(part, state, box, hide, css), part, state, "caixa" if box else "completo")], note)


def svg_png_batch(items, size):
    """items: [(svg_markup, out_path)] -> uma pagina, um screenshot, recorte por celula."""
    cols = 8
    rows = (len(items) + cols - 1) // cols
    cell = size + 8
    page = TMP / f"icons_{size}.html"
    cells = "".join(f"<div style='position:absolute;left:{(i % cols) * cell}px;top:{(i // cols) * cell}px;width:{size}px;height:{size}px'>{m}</div>"
                    for i, (m, _) in enumerate(items))
    page.write_text("<!doctype html><html><body style='margin:0;background:transparent'>"
                    "<style>svg{width:100%!important;height:100%!important;display:block}</style>" + cells + "</body></html>", encoding="utf-8")
    shot = TMP / f"icons_{size}.png"
    W, Hh = max(cols * cell, 400), max(rows * cell, 200)
    subprocess.run([CHROME, "--headless", "--disable-gpu", "--hide-scrollbars", "--default-background-color=00000000",
                    f"--window-size={W},{Hh}", f"--screenshot={shot}", page.as_uri()], check=True, capture_output=True, timeout=120)
    sheet = Image.open(shot).convert("RGBA")
    for i, (_, out) in enumerate(items):
        x, y = (i % cols) * cell, (i // cols) * cell
        out.parent.mkdir(parents=True, exist_ok=True)
        sheet.crop((x, y, x + size, y + size)).save(out, optimize=True)


def clean_svg(markup: str) -> str:
    import re
    markup = re.sub(r'\s(data-part|data-loop|data-i|style)="[^"]*"', "", markup)
    markup = re.sub(r'\swidth="[^"]*"', "", markup, count=1)
    markup = re.sub(r'\sheight="[^"]*"', "", markup, count=1)
    if "xmlns=" not in markup:
        markup = markup.replace("<svg", '<svg xmlns="http://www.w3.org/2000/svg"', 1)
    return markup


def main():
    if KIT.exists():
        shutil.rmtree(KIT)
    KIT.mkdir(parents=True)
    M = measure("padrao")

    # ------------------------------------------------------------ background
    print("background")
    bg = A / "background"
    bg.mkdir(parents=True)
    for n in ("tropical", "deserto"):
        shutil.copy(SCREEN / "art" / "_src" / f"bg_ilha_digital_{n}_1024x1600.png", bg / f"bg_{n}_1024x1600.png")
        shutil.copy(SCREEN / "art" / "_hi" / f"bg_{n}_visor_976x736.png", bg / f"bg_{n}_visor_976x736.png")
    one(bg / "visor_film_scanline_976x736.png", "visor_film_scanline", note="camada 3: por cima do cenario e dos personagens")
    one(bg / "visor_film_vignette_976x736.png", "visor_film_vignette", note="camada 3: por cima do scanline")

    # ------------------------------------------------------------ hud
    print("hud")
    h = A / "hud"
    one(h / "header" / "avatar_frame.png", "header_avatar", hide=["header_avatar_img"], note="moldura + cantoneiras; a foto vai por baixo")
    one(h / "header" / "avatar_placeholder.png", "header_avatar_img", note="foto provisoria do jogador")
    save_group([
        (h / "header" / "xp_bar_under.png", render_part("header_xp_bar", css='[data-part="header_xp_fill"]{width:0!important}'), "header_xp_bar", "padrao", "under"),
        (h / "header" / "xp_bar_progress.png", render_part("header_xp_bar", css='[data-part="header_xp_fill"]{width:100%!important}'), "header_xp_bar", "padrao", "progress"),
    ], "TextureProgressBar esquerda->direita; segmentos ja desenhados")
    one(h / "header" / "sync_dot.png", "header_sync_dot")
    one(h / "header" / "header_ref.png", "header", note="referencia com textos")

    one(h / "strip" / "strip_bg.png", "strip", box=True, note="faixa de instrumentos: fundo + linhas topo/base")
    one(h / "strip" / "strip_rule.png", "strip_rule_1", note="divisor vertical tracejado")
    one(h / "strip" / "strip_ref.png", "strip", note="referencia com textos")

    one(h / "visor" / "visor_frame.png", "visor", box=True, note="contorno ambar interno + sombra externa; conteudo recortado em raio 32")
    for c in ("tl", "tr", "bl", "br"):
        one(h / "visor" / f"visor_corner_{c}.png", f"visor_corner_{c}")
    one(h / "visor" / "visor_sector_ref.png", "visor_sector")
    one(h / "visor" / "visor_round_ref.png", "visor_round")
    one(h / "visor" / "aim_chefe.png", "visor_aim", "padrao", note="mira no chefe (E1)")
    one(h / "visor" / "aim_inimigo.png", "visor_aim", "alvo_inimigo", note="mira em E2/E3")
    one(h / "visor" / "aim_chefe_sozinho.png", "visor_aim", "chefe_sozinho")

    print("  anel de chao")
    for slot in SLOTS:
        part = f"stage_ring_{slot}"
        hide1 = f'[data-part="{part}"] ellipse:nth-of-type(2), [data-part="{part}"] ellipse:nth-of-type(3){{display:none}}'
        prog = (f'[data-part="{part}"] ellipse:nth-of-type(1), [data-part="{part}"] ellipse:nth-of-type(3){{display:none}}'
                f'[data-part="{part}"] ellipse:nth-of-type(2){{stroke:#ffffff!important;stroke-dasharray:100 100!important}}')
        over = f'[data-part="{part}"] ellipse:nth-of-type(1), [data-part="{part}"] ellipse:nth-of-type(2){{display:none}}'
        save_group([
            (h / "stage" / f"ring_{slot}_under.png", render_part(part, css=hide1), part, "padrao", "under"),
            (h / "stage" / f"ring_{slot}_progress.png", render_part(part, css=prog), part, "padrao", "progress"),
            (h / "stage" / f"ring_{slot}_over.png", render_part(part, css=over), part, "padrao", "over"),
        ], "TextureProgressBar radial horario, angulo inicial 90; progress branco + tint_progress")
    part = "stage_ring_BOSS"
    save_group([
        (h / "stage" / "ring_BOSS_under.png", render_part(part, "chefe_sozinho", css=f'[data-part="{part}"] ellipse:nth-of-type(2), [data-part="{part}"] ellipse:nth-of-type(3){{display:none}}'), part, "chefe_sozinho", "under"),
        (h / "stage" / "ring_BOSS_progress.png", render_part(part, "chefe_sozinho", css=f'[data-part="{part}"] ellipse:nth-of-type(1), [data-part="{part}"] ellipse:nth-of-type(3){{display:none}}[data-part="{part}"] ellipse:nth-of-type(2){{stroke:#ffffff!important;stroke-dasharray:100 100!important}}'), part, "chefe_sozinho", "progress"),
        (h / "stage" / "ring_BOSS_over.png", render_part(part, "chefe_sozinho", css=f'[data-part="{part}"] ellipse:nth-of-type(1), [data-part="{part}"] ellipse:nth-of-type(2){{display:none}}'), part, "chefe_sozinho", "over"),
    ], "anel do chefe sozinho")

    one(h / "stage" / "chip_ally_box.png", "chip_A1", box=True, note="pilula 9-slice do chip de aliado")
    one(h / "stage" / "chip_enemy_box.png", "chip_E2", box=True, note="pilula 9-slice do chip de inimigo")
    one(h / "stage" / "chip_frame_target.png", "chip_E1", "alvo_chefe", box=True, note="chip do inimigo selecionado (anel vermelho)")
    one(h / "stage" / "chip_frame_ready.png", "chip_A3", "skill_pronta", box=True, note="chip do aliado com skill pronta (anel ambar)")
    one(h / "stage" / "chip_ally_ref.png", "chip_A1")
    one(h / "stage" / "chip_ally_ready_ref.png", "chip_A3", "skill_pronta")
    one(h / "stage" / "chip_enemy_ref.png", "chip_E3")
    one(h / "stage" / "chip_enemy_imminent_ref.png", "chip_E2")
    one(h / "stage" / "chip_turn_amber_ref.png", "chip_turn_E1")
    one(h / "stage" / "chip_turn_red_ref.png", "chip_turn_E2")

    one(h / "popup" / "popup_target_box.png", "popup_target", "alvo_inimigo", box=True, note="painel 9-slice")
    one(h / "popup" / "popup_target_arrow_down.png", "popup_target_arrow", "alvo_inimigo", note="seta quando o pop-up abre ACIMA do alvo")
    one(h / "popup" / "popup_target_arrow_right.png", "popup_target_arrow", "alvo_chefe", note="seta quando o pop-up abre AO LADO do alvo")
    save_group([
        (h / "popup" / "popup_hp_under.png", render_part("popup_target_hp_bar", "alvo_inimigo", css='[data-part="popup_target_hp_bar"] > div{width:0!important}'), "popup_target_hp_bar", "alvo_inimigo", "under"),
        (h / "popup" / "popup_hp_progress.png", render_part("popup_target_hp_bar", "alvo_inimigo", css='[data-part="popup_target_hp_bar"] > div{width:100%!important}'), "popup_target_hp_bar", "alvo_inimigo", "progress"),
    ], "barra de vida do pop-up")
    one(h / "popup" / "popup_turn_box_amber.png", "popup_target_turn", "alvo_chefe", box=True)
    one(h / "popup" / "popup_turn_box_red.png", "popup_target_turn", "alvo_inimigo", box=True)
    one(h / "popup" / "popup_target_ref_acima.png", "popup_target", "alvo_inimigo")
    one(h / "popup" / "popup_target_ref_lado.png", "popup_target", "alvo_chefe")

    def team_css(w, color=None):
        c = f'[data-part="team_hp_fill"]{{width:{w}!important' + (f';background:{color}!important' if color else "") + "}"
        return c
    save_group([
        (h / "team" / "team_hp_under.png", render_part("team_hp_bar", css=team_css("0")), "team_hp_bar", "padrao", "under"),
        (h / "team" / "team_hp_progress.png", render_part("team_hp_bar", css=team_css("100%", "#ffffff")), "team_hp_bar", "padrao", "progress"),
        (h / "team" / "team_hp_progress_mint.png", render_part("team_hp_bar", css=team_css("100%", "#6FE3B8")), "team_hp_bar", "padrao", "progress"),
        (h / "team" / "team_hp_progress_amber.png", render_part("team_hp_bar", css=team_css("100%", "#F2A33C")), "team_hp_bar", "padrao", "progress"),
        (h / "team" / "team_hp_progress_red.png", render_part("team_hp_bar", css=team_css("100%", "#FF6B4A")), "team_hp_bar", "padrao", "progress"),
    ], "acima de 40% menta, 40-20% ambar, abaixo de 20% vermelho")
    one(h / "team" / "team_ref.png", "team")

    one(h / "bank" / "bank_rule.png", "bank_rule")
    one(h / "bank" / "bank_combo_off.png", "bank_combo")
    one(h / "bank" / "bank_combo_2of3.png", "bank_combo", "cartas_selecionadas")
    one(h / "bank" / "bank_header_ref.png", "bank_header")

    one(h / "toast" / "toast_box_amber.png", "toast", "alertas", box=True)
    one(h / "toast" / "toast_box_red.png", "toast", "aviso_vermelho", box=True)
    one(h / "toast" / "toast_box_mint.png", "toast", "aviso_menta", box=True)
    one(h / "toast" / "toast_amber_ref.png", "toast", "alertas")
    one(h / "toast" / "toast_red_ref.png", "toast", "aviso_vermelho")
    one(h / "toast" / "toast_mint_ref.png", "toast", "aviso_menta")

    # ------------------------------------------------------------ buttons
    print("buttons")
    b = A / "buttons"
    one(b / "button_nav_normal.png", "button_nav_equipe", box=True, note="EQUIPE / INVOCAR / LOJA")
    one(b / "button_nav_primary.png", "button_nav_fases", box=True, note="FASES (botao principal)")
    for n in ("equipe", "invocar", "loja", "fases"):
        one(b / f"button_nav_{n}_ref.png", f"button_nav_{n}")
    one(b / "button_leader_normal.png", "button_leader", box=True)
    one(b / "button_leader_active.png", "button_leader", "cartas_selecionadas", box=True)
    one(b / "button_leader_cooldown.png", "button_leader", "alertas", box=True)
    one(b / "button_leader_normal_ref.png", "button_leader")
    one(b / "button_leader_active_ref.png", "button_leader", "cartas_selecionadas")
    one(b / "button_leader_cooldown_ref.png", "button_leader", "alertas")

    # ------------------------------------------------------------ cards
    print("cards")
    cd = A / "cards"
    cd.mkdir(parents=True)
    for f in (SCREEN / "export" / "cards").glob("*.png"):
        shutil.copy(f, cd / f.name.replace("card-", "card_"))
    one(cd / "card_frame_selected.png", "card_slot_1", "cartas_selecionadas", box=True, note="anel ambar da carta selecionada (a carta sobe 10px)")
    one(cd / "card_order_badge.png", "card_order_1", "cartas_selecionadas", box=True, note="selo do indice do combo")
    one(cd / "card_value_plate.png", "card_value_1", box=True, note="placa do numero de poder")
    one(cd / "card_slot_selected_ref.png", "card_slot_1", "cartas_selecionadas")
    one(cd / "card_slot_ref.png", "card_slot_2")
    src = KIT / "source" / "cards"
    src.mkdir(parents=True)
    for f in (SCREEN / "cards").glob("card-*.svg"):
        shutil.copy(f, src / f.name.replace("card-", "card_"))

    # ------------------------------------------------------------ characters / enemies
    print("characters")
    ch = A / "characters"; en = A / "enemies"
    ch.mkdir(parents=True); en.mkdir(parents=True)
    s = SCREEN / "art" / "_src"
    for f in s.glob("ally_*.png"):
        shutil.copy(f, ch / f.name)
    for f in list(s.glob("enemy_*.png")) + list(s.glob("boss_*.png")):
        shutil.copy(f, en / f.name)

    # ------------------------------------------------------------ icons
    print("icons")
    ic = A / "icons"
    svgs = {
        "currency/icon_bits": M["icon_bits"]["svg"], "currency/icon_gems": M["icon_gems"]["svg"], "currency/icon_energy": M["icon_energy"]["svg"],
        "ui/icon_menu": M["icon_menu"]["svg"], "ui/icon_crown_normal": M["icon_crown"]["svg"],
        "ui/icon_crown_active": measure("cartas_selecionadas")["icon_crown"]["svg"], "ui/icon_crown_cooldown": measure("alertas")["icon_crown"]["svg"],
    }
    for n in ("equipe", "invocar", "loja"):
        svgs[f"nav/icon_nav_{n}"] = M[f"icon_nav_{n}"]["svg"]
    svgs["nav/icon_nav_fases_primary"] = M["icon_nav_fases"]["svg"]
    svgs["nav/icon_nav_fases_normal"] = M["icon_nav_equipe"]["svg"].split(">", 1)[0] + ">" + M["icon_nav_fases"]["svg"].split(">", 1)[1]
    emb = json.loads((SCREEN / "art" / "emblems_chip.json").read_text(encoding="utf-8"))
    for el, e in emb.items():
        svgs[f"elements/emblem_{el}"] = f'<svg viewBox="0 0 100 100"><path d="{e["d"]}" fill="#F4EEE1" fill-rule="evenodd"/></svg>'
    import importlib.util
    spec = importlib.util.spec_from_file_location("bc", SCREEN / "cards" / "build_cards.py")
    bc = importlib.util.module_from_spec(spec); spec.loader.exec_module(bc)
    svgs["elements/emblem_wild"] = f'<svg viewBox="0 0 100 100"><path d="{" ".join(bc.EMB["wild"]["parts"])}" fill="#F4EEE1" fill-rule="evenodd"/></svg>'
    svgs["elements/emblem_capsule"] = ('<svg viewBox="22 34 108 108"><defs><linearGradient id="embC" x1="0" y1="0" x2="0" y2="1">'
                                       '<stop offset="0" stop-color="#FBF7EE"/><stop offset="1" stop-color="#E6D3B4"/></linearGradient></defs>'
                                       + bc.capsule_art() + "</svg>")
    batch = {48: [], 96: []}
    for name, markup in svgs.items():
        out = ic / f"{name}.svg"
        out.parent.mkdir(parents=True, exist_ok=True)
        clean = clean_svg(markup)
        out.write_text(clean, encoding="utf-8")
        for size in (48, 96):
            batch[size].append((clean, ic / f"{name}_{size}.png"))
        print("  ", out.relative_to(KIT), flush=True)
    for size, items in batch.items():
        svg_png_batch(items, size)
    for slot, el in ALLY_EL.items():
        one(ic / "elements" / f"badge_{el}.png", f"chip_badge_{slot}", note="selo redondo do chip (13pt)")

    # ------------------------------------------------------------ fonts
    print("fonts")
    fo = KIT / "fonts"
    fo.mkdir()
    fsrc = Path(r"C:\Users\Jinsa\AppData\Local\Temp\claude\c--Users-Jinsa-OneDrive-Meus-Documentos-1bitheroes\de07b3a6-091b-44ee-8c9c-75913ce05c23\scratchpad\fonts")
    shutil.copy(fsrc / "instrumentsans__InstrumentSans[wdth,wght].ttf", fo / "InstrumentSans-Variable.ttf")
    shutil.copy(fsrc / "instrumentsans__OFL.txt", fo / "InstrumentSans-OFL.txt")
    shutil.copy(fsrc / "martianmono__MartianMono[wdth,wght].ttf", fo / "MartianMono-Variable.ttf")
    shutil.copy(fsrc / "martianmono__OFL.txt", fo / "MartianMono-OFL.txt")

    # ------------------------------------------------------------ reference screens + layout
    print("reference + data")
    ref = KIT / "reference" / "screens"
    data = KIT / "data"
    data.mkdir()
    layouts = {}
    for st in STATES:
        rd.shot(ref / f"screen_{st}_1024x1600.png", STATES[st])
        layouts[st] = {k: {**rect2(v), **({"text": v["text"]} if v.get("text") else {})} for k, v in measure(st).items()}
        print("   screen", st)
    (data / "layout_1024x1600.json").write_text(json.dumps(layouts, ensure_ascii=False, indent=1), encoding="utf-8")

    typo = {}
    for st in ("padrao", "alvo_chefe", "cartas_selecionadas", "alertas"):
        for k, v in measure(st).items():
            if v.get("font") and k not in typo:
                f = dict(v["font"])
                for key in ("size", "letterSpacing", "lineHeight"):
                    if f.get(key, "").endswith("px"):
                        f[key + "_1024"] = round(float(f[key][:-2]) * S2, 2)
                typo[k] = {"example": v["text"], **f}
    (data / "typography.json").write_text(json.dumps(typo, ensure_ascii=False, indent=1), encoding="utf-8")
    (data / "components.json").write_text(json.dumps(components, ensure_ascii=False, indent=1), encoding="utf-8")

    # debug: retangulos das pecas principais sobre a tela
    from PIL import ImageDraw
    im = Image.open(ref / "screen_padrao_1024x1600.png").convert("RGB")
    d = ImageDraw.Draw(im)
    for k, v in layouts["padrao"].items():
        if k.count("_") <= 1 or k.startswith(("button_nav_", "card_slot_", "stage_fig_", "chip_A", "chip_E", "visor_corner")):
            if k.endswith("_label") or k.startswith("icon_"):
                continue
            d.rectangle((v["x"], v["y"], v["x"] + v["w"], v["y"] + v["h"]), outline=(0, 255, 200), width=2)
            d.text((v["x"] + 3, v["y"] + 2), k, fill=(0, 255, 200))
    (KIT / "reference" / "overlays").mkdir(parents=True, exist_ok=True)
    im.save(KIT / "reference" / "overlays" / "layout_debug_1024x1600.png")

    print("fim:", len(components), "texturas recortadas")


if __name__ == "__main__":
    main()
