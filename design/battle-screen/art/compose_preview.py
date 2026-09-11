"""Compoe o visor (cenario recortado + personagens pelos pes) para conferir escala e posicao.

Uso: python compose_preview.py <saida.png> [escala] [trio|solo]
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw

SRC = Path(__file__).resolve().parent / "_src"
S = 2                                   # desenho em 2x do mockup
VIS_X, VIS_Y, VIS_W, VIS_H = 12, 116, 488, 368

CHARS = {
    "A1": "ally_01_crimson_clamp_256.png", "A2": "ally_02_bone_raider_256.png",
    "A3": "ally_03_panda_gunner_256.png", "A4": "ally_04_twin_apes_256.png",
    "A5": "ally_05_flora_fairy_256.png",
    "E1": "boss_01_long_ear_guardian_512.png", "E2": "enemy_01_dusk_dragon_256.png",
    "E3": "enemy_02_twin_tail_256.png", "BOSS": "boss_01_long_ear_guardian_512.png",
}
# (x%, pe y%, largura do quadro em pt)
POS = {
    "A1": (15, 50, 58), "A2": (36, 46, 56), "A3": (27, 66, 62), "A4": (12, 84, 68), "A5": (36, 86, 68),
    "E1": (78, 52, 88), "E2": (65, 83, 64), "E3": (89, 85, 64), "BOSS": (74, 76, 131),
}
ORDER_TRIO = ["A2", "A1", "E1", "A3", "E2", "A4", "E3", "A5"]   # de tras para frente
ORDER_SOLO = ["A2", "A1", "A3", "BOSS", "A4", "A5"]


def main():
    out = Path(sys.argv[1])
    k = float(sys.argv[2]) if len(sys.argv) > 2 else 1.0
    mode = sys.argv[3] if len(sys.argv) > 3 else "trio"
    sheets = []
    for bg_name in ("bg_ilha_digital_tropical_1024x1600.png", "bg_ilha_digital_deserto_1024x1600.png"):
        bg = Image.open(SRC / bg_name).convert("RGBA")
        vis = bg.crop((VIS_X * S, VIS_Y * S, (VIS_X + VIS_W) * S, (VIS_Y + VIS_H) * S))
        d = ImageDraw.Draw(vis)
        for slot in (ORDER_SOLO if mode == "solo" else ORDER_TRIO):
            xp, yp, wpt = POS[slot]
            spr = Image.open(SRC / CHARS[slot]).convert("RGBA")
            size = round(wpt * k * S)
            foot = spr.height * (248 / 256)
            spr = spr.resize((size, size), Image.LANCZOS)
            fx, fy = xp / 100 * VIS_W * S, yp / 100 * VIS_H * S
            sx, sy = round(fx - size / 2), round(fy - foot * size / spr.width * (1 if spr.width else 1))
            sy = round(fy - size * (248 / 256))
            # sombra
            d.ellipse((fx - size * .32, fy - size * .05, fx + size * .32, fy + size * .05), fill=(20, 30, 16, 110))
            vis.alpha_composite(spr, (sx, sy))
            # placa aproximada
            pw, ph = 88 * S, (27 if slot.startswith("A") else 19) * S
            d.rectangle((fx - pw / 2, fy + 2 * S, fx + pw / 2, fy + 2 * S + ph), outline=(242, 163, 60, 200), width=2)
        sheets.append(vis)
    W = sum(v.width for v in sheets) + 20
    canvas = Image.new("RGB", (W, sheets[0].height), (22, 19, 13))
    x = 0
    for v in sheets:
        canvas.paste(v, (x, 0), v)
        x += v.width + 20
    canvas.save(out)
    print("ok", out, "escala", k, mode)


if __name__ == "__main__":
    main()
