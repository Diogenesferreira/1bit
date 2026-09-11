"""Rasteriza card-*.svg em PNG transparente para o Godot (@1x 76x88, @2x, @4x).

Uso: python export_png.py   -> design/battle-screen/export/cards/card-<elem>@<n>x.png
"""
import subprocess
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE.parent / "export" / "cards"
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
ORDER = ["dragon", "knight", "nature", "light", "dark", "capsule", "wild"]
BASE_W, BASE_H = 76, 88


def shot(svg: Path, png: Path, w: int, h: int):
    with tempfile.TemporaryDirectory() as tmp:
        page = Path(tmp) / "p.html"
        page.write_text(
            f'<!doctype html><html><body style="margin:0;background:transparent;overflow:hidden">'
            f'<img src="{svg.as_uri()}" style="display:block;width:{w}px;height:{h}px"></body></html>',
            encoding="utf-8")
        subprocess.run([CHROME, "--headless", "--disable-gpu", "--hide-scrollbars",
                        "--allow-file-access-from-files", "--default-background-color=00000000",
                        f"--window-size={w},{h}", f"--screenshot={png}", page.as_uri()],
                       check=True, capture_output=True)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for el in ORDER:
        svg = HERE / f"card-{el}.svg"
        for n in (1, 2, 4):
            png = OUT / f"card-{el}@{n}x.png"
            shot(svg, png, BASE_W * n, BASE_H * n)
        print("ok", el)
    print("->", OUT)


if __name__ == "__main__":
    main()
