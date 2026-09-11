"""Extrai o contorno dos emblemas das cartas de referencia e redesenha em vetor.

Nao copia pixels: separa a massa clara do emblema, descarta arco/moldura/textura,
contorna (com furos internos) e simplifica em poligono facetado no grid 100x100.
Saida: traced.json  +  mask-<elem>.png para conferencia.

Uso: python trace_refs.py
"""
import json
import math
from collections import deque
from pathlib import Path

from PIL import Image, ImageFilter

HERE = Path(__file__).resolve().parent
REFS = Path(r"C:\Users\Jinsa\OneDrive\Meus Documentos\heroes\assetsemodelosideias\Nova pasta")

# lum_min: limiar de claridade do emblema | open_k: abertura morfologica (some com o arco fino)
# eps: tolerancia de simplificacao em px da referencia | box: recorte (x0,y0,x1,y1) em fracao
JOBS = {
    "dragon": dict(file="01_dragao_vermelho.png", lum_min=150, open_k=5, eps=1.1, box=(.12, .16, .92, .86)),
    "knight": dict(file="02_cavaleiro_azul.png", lum_min=150, open_k=5, eps=1.1, box=(.14, .16, .90, .84)),
    "nature": dict(file="03_natureza_verde.png", lum_min=140, open_k=5, eps=1.1, box=(.12, .16, .92, .86)),
    "dark":   dict(file="06_trevas_roxo.png",    lum_min=150, open_k=5, eps=1.1, box=(.12, .18, .94, .86)),
}

N8 = [(-1, 0), (-1, -1), (0, -1), (1, -1), (1, 0), (1, 1), (0, 1), (-1, 1)]
N4 = [(1, 0), (-1, 0), (0, 1), (0, -1)]


def build_mask(job):
    im = Image.open(REFS / job["file"]).convert("RGB")
    W, H = im.size
    x0, y0, x1, y1 = (int(job["box"][0] * W), int(job["box"][1] * H), int(job["box"][2] * W), int(job["box"][3] * H))
    im = im.crop((x0, y0, x1, y1))
    w, h = im.size
    px = im.load()
    m = Image.new("L", (w, h), 0)
    mp = m.load()
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            lum = 0.299 * r + 0.587 * g + 0.114 * b
            if lum >= job["lum_min"]:
                mp[x, y] = 255
    k = job["open_k"]
    m = m.filter(ImageFilter.MinFilter(k)).filter(ImageFilter.MaxFilter(k))
    return m


def components(mask, value, min_area):
    w, h = mask.size
    mp = mask.load()
    seen = set()
    comps = []
    for y in range(h):
        for x in range(w):
            if (mp[x, y] > 127) != value or (x, y) in seen:
                continue
            q = deque([(x, y)])
            seen.add((x, y))
            comp = set()
            touches_border = False
            while q:
                cx, cy = q.popleft()
                comp.add((cx, cy))
                if cx in (0, w - 1) or cy in (0, h - 1):
                    touches_border = True
                for dx, dy in N4:
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen and (mp[nx, ny] > 127) == value:
                        seen.add((nx, ny))
                        q.append((nx, ny))
            if len(comp) >= min_area:
                comps.append((comp, touches_border))
    return comps


def moore(comp):
    s = min(comp, key=lambda p: (p[1], p[0]))
    contour = [s]
    p, bdir = s, 0
    for _ in range(len(comp) * 8 + 16):
        for k in range(1, 9):
            d = (bdir + k) % 8
            q = (p[0] + N8[d][0], p[1] + N8[d][1])
            if q in comp:
                prev = (bdir + k - 1) % 8
                bp = (p[0] + N8[prev][0], p[1] + N8[prev][1])
                bdir = N8.index((bp[0] - q[0], bp[1] - q[1]))
                p = q
                break
        else:
            break
        if p == s:
            break
        contour.append(p)
    return contour


def rdp(pts, eps):
    if len(pts) < 3:
        return pts
    keep = [False] * len(pts)
    keep[0] = keep[-1] = True
    stack = [(0, len(pts) - 1)]
    while stack:
        a, b = stack.pop()
        ax, ay = pts[a]
        bx, by = pts[b]
        dx, dy = bx - ax, by - ay
        L = math.hypot(dx, dy) or 1e-9
        best, bi = -1, -1
        for i in range(a + 1, b):
            px, py = pts[i]
            dist = abs(dy * px - dx * py + bx * ay - by * ax) / L
            if dist > best:
                best, bi = dist, i
        if best > eps:
            keep[bi] = True
            stack.append((a, bi))
            stack.append((bi, b))
    return [p for p, k in zip(pts, keep) if k]


def closed_rdp(pts, eps):
    if len(pts) < 8:
        return pts
    far = max(range(len(pts)), key=lambda i: (pts[i][0] - pts[0][0]) ** 2 + (pts[i][1] - pts[0][1]) ** 2)
    a = rdp(pts[: far + 1], eps)
    b = rdp(pts[far:] + [pts[0]], eps)
    return a[:-1] + b[:-1]


def trace(elem, job):
    mask = build_mask(job)
    mask.save(HERE / f"mask-{elem}.png")
    w, h = mask.size
    fg = components(mask, True, min_area=120)
    # descarta pedacos colados na borda do recorte (restos de arco/moldura)
    fg = [c for c, border in fg if not border]
    holes = [c for c, border in components(mask, False, min_area=14) if not border]

    outers = [closed_rdp(moore(c), job["eps"]) for c in fg]
    inners = [closed_rdp(moore(c), job["eps"] * .8) for c in holes]
    allpts = [p for poly in outers for p in poly]
    minx = min(p[0] for p in allpts); maxx = max(p[0] for p in allpts)
    miny = min(p[1] for p in allpts); maxy = max(p[1] for p in allpts)
    s = 100 / max(maxx - minx, maxy - miny)
    ox = (100 - (maxx - minx) * s) / 2
    oy = (100 - (maxy - miny) * s) / 2

    def fmt(poly):
        pts = [((x - minx) * s + ox, (y - miny) * s + oy) for x, y in poly]
        return "M" + " L".join(f"{x:.1f} {y:.1f}" for x, y in pts) + " Z"

    d = " ".join(fmt(p) for p in outers + inners if len(p) >= 3)
    return dict(d=d, parts=len(outers), holes=len(inners), nodes=sum(len(p) for p in outers + inners))


def main():
    out = {}
    for elem, job in JOBS.items():
        r = trace(elem, job)
        out[elem] = r["d"]
        print(f"{elem:7s} partes={r['parts']} furos={r['holes']} nos={r['nodes']}")
    (HERE / "traced.json").write_text(json.dumps(out, indent=1), encoding="utf-8")
    print("traced.json ok")


if __name__ == "__main__":
    main()
