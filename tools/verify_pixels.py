"""Compara a captura real do Godot com a arte aprovada. Não edita imagens."""
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageChops

root = Path(__file__).resolve().parents[1]
original_path = root / "assets/reference/ilha_digital_approved.png"
capture_path = root / "output/verification/initial.png"
with Image.open(original_path) as source, Image.open(capture_path) as capture:
    source = source.convert("RGB")
    capture = capture.convert("RGB")
    assert source.size == capture.size == (1024, 1536)
    difference = ImageChops.difference(source, capture)
    identical = difference.getbbox() is None
    report = {
        "reference": str(original_path.relative_to(root)),
        "capture": str(capture_path.relative_to(root)),
        "size": list(source.size),
        "exact_rgb_match": identical,
        "difference_bounding_box": difference.getbbox(),
        "reference_sha256": hashlib.sha256(original_path.read_bytes()).hexdigest(),
        "method": "RGB comparison of actual Godot SubViewport capture at native resolution",
        "scope": "Initial screen with fresh default account; gameplay values change after input.",
    }
    (root / "output/verification/pixel_report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))
    raise SystemExit(0 if identical else 1)
