"""Mede a captura do Godot contra a tela padrão entregue no kit."""
import json
from pathlib import Path
from PIL import Image, ImageChops, ImageStat

root = Path(__file__).resolve().parents[1]
reference = root / "design/ilha-digital-godot-kit/reference/screens/screen_padrao_1024x1600.png"
capture = root / "output/verification/terminal_padrao.png"
with Image.open(reference) as ref_image, Image.open(capture) as got_image:
    ref = ref_image.convert("RGB")
    got = got_image.convert("RGB")
    assert ref.size == got.size == (1024, 1600)
    diff = ImageChops.difference(ref, got)
    stat = ImageStat.Stat(diff)
    mean = sum(stat.mean) / 3.0
    similarity = 1.0 - mean / 255.0
    exact = sum(1 for pixel in diff.get_flattened_data() if pixel == (0, 0, 0)) / (1024 * 1600)
    report = {
        "reference": str(reference.relative_to(root)),
        "capture": str(capture.relative_to(root)),
        "resolution": [1024, 1600],
        "mean_absolute_rgb_error": round(mean, 4),
        "global_similarity": round(similarity, 6),
        "exact_pixel_ratio": round(exact, 6),
        "method": "Godot OpenGL capture compared against the kit reference",
    }
    output = root / "output/verification/terminal_visual_report.json"
    output.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))
    raise SystemExit(0 if similarity >= 0.90 else 1)
