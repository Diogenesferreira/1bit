"""Sequencias de referencia quadro a quadro para animacao/gameplay.

Para cada quadro: tela inteira 1024x1600 + recortes das pecas que mudam + uma tira comparativa.
Saida: ilha-digital-godot-kit/reference/sequences/<sequencia>/
"""
import json
from pathlib import Path

from PIL import Image, ImageDraw

from render import Renderer, SCREEN

KIT = SCREEN.parent.parent / "docs" / "ilha-digital-godot-kit"
OUT = KIT / "reference" / "sequences"
rd = Renderer()

COMBO = [["pick", 0], ["pick", 7], ["pick", 5]]          # dragon + dragon + wild
RESOLVE = COMBO + [["resolve"]]

SEQ = {
    "01_selecao_de_cartas": {
        "parts": ["bank", "team", "chip_A1", "chip_E1", "chip_E2", "chip_E3", "toast"],
        "frames": [
            ("f0_nenhuma", {}),
            ("f1_uma_carta", {"actions": [["pick", 0]]}),
            ("f2_duas_cartas", {"actions": [["pick", 0], ["pick", 7]]}),
            ("f3_tres_cartas_antes_de_resolver", {"actions": COMBO}),
            ("f4_depois_do_combo", {"actions": RESOLVE}),
            ("f5_desmarcar_toque_de_novo", {"actions": [["pick", 0], ["pick", 7], ["pick", 7]]}),
        ],
    },
    "02_lider": {
        "parts": ["button_leader", "toast"],
        "frames": [
            ("f0_disponivel", {}),
            ("f1_ativado", {"actions": [["crown"]]}),
            ("f2_cancelado", {"actions": [["crown"], ["crown"]]}),
            ("f3_combo_com_lider_recarga_3", {"actions": [["crown"]] + RESOLVE}),
            ("f4_recarga_2", {"after": {"leaderCd": 2}}),
            ("f5_recarga_1", {"after": {"leaderCd": 1}}),
            ("f6_toque_durante_recarga", {"state": {"leaderCd": 3}, "actions": [["crown"]]}),
        ],
    },
    "03_skill_do_aliado": {
        "parts": ["stage_fig_A1", "chip_A1", "toast"],
        "frames": [
            ("f0_carga_45", {}),
            ("f1_carga_79_depois_de_combo_dragon", {"actions": RESOLVE}),
            ("f2_pronta_100", {"patch": {"allies.0.skill": 100}}),
            ("f3_toque_antes_de_pronta", {"actions": [["ally", 0]]}),
            ("f4_disparo_600", {"patch": {"allies.0.skill": 100}, "actions": [["ally", 0]]}),
        ],
    },
    "04_contador_de_ataque": {
        "parts": ["chip_E1", "chip_E2", "chip_E3", "popup_target", "team", "toast"],
        "frames": [
            ("f0_turno_atual", {"actions": [["target", 0]]}),
            ("f1_depois_do_combo_E2_atacou", {"actions": [["target", 0]] + RESOLVE}),
            ("f2_aviso_do_ataque", {"actions": [["target", 0]] + RESOLVE, "after": {"toast": "DUSK DRAGON ATACOU · -130", "toastOn": True, "toastTone": "red"}}),
            ("f3_proximo_turno", {"actions": [["target", 0]], "patch": {"enemies.0.atk": 3, "enemies.1.atk": 2, "enemies.2.atk": 1}}),
        ],
    },
    "05_hp_da_equipe": {
        "parts": ["team"],
        "frames": [
            ("f0_89pct_menta", {}),
            ("f1_41pct_menta", {"after": {"teamHp": 1320}}),
            ("f2_34pct_ambar", {"after": {"teamHp": 1100}}),
            ("f3_16pct_vermelho", {"after": {"teamHp": 510}}),
            ("f4_0pct", {"after": {"teamHp": 0}}),
        ],
    },
    "06_inimigo_abatido": {
        "parts": ["stage_fig_E2", "chip_E2", "visor", "toast"],
        "frames": [
            ("f0_vivo", {}),
            ("f1_vida_baixa_10pct", {"patch": {"enemies.1.hp": 120}}),
            ("f2_abatido", {"patch": {"enemies.1.hp": 0, "enemies.1.alive": False}}),
            ("f3_toque_no_abatido", {"patch": {"enemies.1.hp": 0, "enemies.1.alive": False}, "post": [["target", 1]]}),
        ],
    },
    "07_popup_do_alvo": {
        "parts": ["visor"],
        "frames": [
            ("f0_fechado", {}),
            ("f1_toque_abre_acima", {"actions": [["target", 1]]}),
            ("f2_toque_de_novo_fecha", {"actions": [["target", 1], ["target", 1]]}),
            ("f3_troca_de_alvo", {"actions": [["target", 1], ["target", 2]]}),
            ("f4_chefe_abre_ao_lado", {"actions": [["target", 0]]}),
        ],
    },
    "08_avisos": {
        "parts": ["toast"],
        "frames": [
            ("f0_dano", {"actions": RESOLVE}),
            ("f1_invalido_capsule", {"actions": [["pick", 0], ["pick", 6], ["pick", 7], ["resolve"]]}),
            ("f2_invalido_elementos", {"actions": [["pick", 0], ["pick", 1], ["pick", 2], ["resolve"]]}),
            ("f3_cura", {"after": {"toast": "CURA +770", "toastOn": True, "toastTone": "mint"}}),
            ("f4_ataque_sofrido", {"after": {"toast": "LONG EAR GUARDIAN + DUSK DRAGON ATACOU · -350", "toastOn": True, "toastTone": "red"}}),
            ("f5_vitoria", {"after": {"toast": "VITÓRIA · SETOR LIMPO", "toastOn": True, "toastTone": "mint"}}),
            ("f6_derrota", {"after": {"toast": "DERROTA · EQUIPE CAÍDA", "toastOn": True, "toastTone": "red"}}),
            ("f7_tela_reservada", {"actions": [["nav", "EQUIPE"]]}),
            ("f8_nova_partida", {"actions": [["nav", "FASES"]]}),
        ],
    },
}


def cfg_of(frame):
    c = dict(frame)
    post = c.pop("post", None)
    if post:
        c["actions"] = list(c.get("actions", [])) + post
    return c


def main():
    import sys
    only = sys.argv[1:]
    OUT.mkdir(parents=True, exist_ok=True)
    idx_path = OUT / "sequences_index.json"
    index = json.loads(idx_path.read_text(encoding="utf-8")) if (only and idx_path.exists()) else {}
    for seq, spec in SEQ.items():
        if only and seq not in only:
            continue
        d = OUT / seq
        d.mkdir(parents=True, exist_ok=True)
        strip_cells = []
        index[seq] = []
        for name, frame in spec["frames"]:
            cfg = cfg_of(frame)
            full = d / f"{name}_tela.png"
            rd.shot(full, cfg)
            m = rd.measure(cfg)
            im = Image.open(full).convert("RGB")
            crops = {}
            for part in spec["parts"]:
                r = m.get(part)
                if not r:
                    continue
                pad = 18
                box = (max(0, int(r["x"] * 2) - pad), max(0, int(r["y"] * 2) - pad),
                       min(1024, int((r["x"] + r["w"]) * 2) + pad), min(1600, int((r["y"] + r["h"]) * 2) + pad))
                c = im.crop(box)
                p = d / f"{name}_{part}.png"
                c.save(p, optimize=True)
                crops[part] = c
            index[seq].append({"frame": name, "config": cfg, "files": sorted(x.name for x in d.glob(f"{name}_*.png"))})
            strip_cells.append((name, crops))
            print(seq, name, list(crops))
        # tira comparativa: uma linha por peca, uma coluna por quadro
        parts = spec["parts"]
        colw = 360
        rows = []
        for part in parts:
            cells = [c.get(part) for _, c in strip_cells]
            if not any(cells):
                continue
            h = max((min(c.height, int(c.height * colw / c.width)) if c else 40) for c in cells)
            rows.append((part, cells, max(h, 40)))
        head = 34
        W = 150 + colw * len(strip_cells)
        H = head + sum(h + 12 for _, _, h in rows)
        S = Image.new("RGB", (W, H), (22, 19, 13))
        dr = ImageDraw.Draw(S)
        for i, (name, _) in enumerate(strip_cells):
            dr.text((150 + i * colw + 6, 10), name[:48], fill=(242, 163, 60))
        y = head
        for part, cells, h in rows:
            dr.text((8, y + 4), part, fill=(245, 239, 226))
            for i, c in enumerate(cells):
                if c:
                    sc = min(1.0, (colw - 12) / c.width, h / c.height)
                    t = c.resize((int(c.width * sc), int(c.height * sc)))
                    S.paste(t, (150 + i * colw + 6, y))
            y += h + 12
        S.save(OUT / f"{seq}_tira.png", optimize=True)
    (OUT / "sequences_index.json").write_text(json.dumps(index, ensure_ascii=False, indent=1), encoding="utf-8")
    print("ok")


if __name__ == "__main__":
    main()
