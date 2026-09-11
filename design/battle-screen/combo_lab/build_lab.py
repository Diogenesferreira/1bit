"""Monta docs/combo-lab/combo_lab.html: pagina unica (sem dependencias locais) com
a tela de batalha EXATA do Main.dc.html + logica do BattleLogic + laboratorio de animacao.

Uso: python build_lab.py
"""
import base64
import json
import os
import re
import shutil
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCREEN = HERE.parent
sys.path.insert(0, str(SCREEN / "export_kit"))
from render import RENDERER_JS  # noqa: E402

OUT = SCREEN.parent.parent / "docs" / "combo-lab"
ELEMS = ("dragon", "knight", "nature", "light", "dark", "capsule", "wild")
# audio original (placeholder de referencia, fica fora do repositorio). Nao publicar o HTML gerado com ele.
SFX_DIR = Path(os.environ.get("COMBO_LAB_SFX", SCREEN.parents[2] / "heroes" / "forum_achado" / "Crusader- 17-12-13 (1)" / "sound"))
SFX = {
    "effects": ("se_touch", "se_gousei", "se_wildattack1", "se_countup", "se_card_shuffle", "se_card_shuffle3", "se_arrart2"),
    "music": ("bgm_06_battle_win", "bgm_07_battle_lose"),
}


def data_uri(path: Path) -> str:
    mime = {".png": "image/png", ".webp": "image/webp", ".m4a": "audio/mp4"}[path.suffix.lower()]
    return f"data:{mime};base64," + base64.b64encode(path.read_bytes()).decode("ascii")


def main():
    src = (SCREEN / "Main.dc.html").read_text(encoding="utf-8")
    helmet = re.search(r"<helmet>(.*?)</helmet>", src, re.S).group(1)
    body = re.search(r"</helmet>(.*?)</x-dc>", src, re.S).group(1)
    cls = re.search(r"<script data-dc-script[^>]*>(.*?)</script>", src, re.S).group(1)

    imgs = {"avatar.png": data_uri(SCREEN / "avatar.png")}
    for f in sorted((SCREEN / "art").glob("*.webp")):
        imgs[f.name] = data_uri(f)
    for el in ELEMS:
        imgs[f"card-{el}.png"] = data_uri(SCREEN / "cards" / f"card-{el}.png")

    # o renderizador do kit le a configuracao do hash; aqui o hash e do laboratorio
    renderer = RENDERER_JS.replace(
        "const CFG = JSON.parse(decodeURIComponent(location.hash.slice(1) || '%7B%7D'));", "const CFG = {};")
    assert "const CFG = {};" in renderer

    sfx = {}
    if not os.environ.get("COMBO_LAB_NO_SFX"):
        for sub, names in SFX.items():
            for n in names:
                f = SFX_DIR / sub / f"{n}.m4a"
                if f.exists():
                    sfx[n] = data_uri(f)
        if len(sfx) < sum(len(v) for v in SFX.values()):
            print("aviso: sons encontrados", len(sfx), "em", SFX_DIR)

    esc = lambda t: t.replace("</script", "<\\/script")
    page = (
        "<title>Combo Lab</title>\n"
        + helmet
        + "<style>" + (HERE / "lab.css").read_text(encoding="utf-8") + "</style>\n"
        + "<style id='mode'></style>\n"
        + "<div id='lab-app'><div id='lab-wrap'><div id='lab-stage'><div id='host'></div></div></div><aside id='lab-panel'></aside></div>\n"
        + "<script type='text/plain' id='src'>" + esc(body) + "</script>\n"
        + "<script type='text/plain' id='cls'>" + esc(cls) + "</script>\n"
        + "<script type='application/json' id='imgs'>" + json.dumps(imgs) + "</script>\n"
        + "<script>" + esc(renderer) + "</script>\n"
        + "<script>(function(){const I=JSON.parse(document.getElementById('imgs').textContent);window.LAB_CARD_IMG={};"
          "['dragon','knight','nature','light','dark','capsule','wild'].forEach(function(e){window.LAB_CARD_IMG[e]=I['card-'+e+'.png'];});})();</script>\n"
        + "<script>window.LAB_SFX=" + json.dumps(sfx) + ";</script>\n"
        + "<script>" + esc((HERE / "logic.js").read_text(encoding="utf-8")) + "</script>\n"
        + "<script>" + esc((HERE / "lab.js").read_text(encoding="utf-8")) + "</script>\n"
    )
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "combo_lab.html").write_text(page, encoding="utf-8")
    # fontes do laboratorio (para o Codex/Godot consultar)
    src_dir = OUT / "source"
    src_dir.mkdir(exist_ok=True)
    for f in ("logic.js", "lab.js", "lab.css", "build_lab.py"):
        shutil.copy2(HERE / f, src_dir / f)
    print("ok", OUT / "combo_lab.html", round((OUT / "combo_lab.html").stat().st_size / 1e6, 2), "MB")


if __name__ == "__main__":
    main()
