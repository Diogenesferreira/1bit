import json
import export as ex
from export import A, KIT, one
comps_path = KIT / "data" / "components.json"
old = json.loads(comps_path.read_text(encoding="utf-8"))
h, cd = A / "hud", A / "cards"
redo = [
    (h / "toast" / "toast_box_amber.png", "toast", "alertas", "caixa 9-slice do aviso"),
    (h / "toast" / "toast_box_red.png", "toast", "aviso_vermelho", "caixa 9-slice do aviso"),
    (h / "toast" / "toast_box_mint.png", "toast", "aviso_menta", "caixa 9-slice do aviso"),
    (cd / "card_order_badge.png", "card_order_1", "cartas_selecionadas", "selo do indice do combo"),
    (cd / "card_value_plate.png", "card_value_1", "padrao", "placa do numero de poder"),
]
for out, part, state, note in redo:
    one(out, part, state, box=True, note=note)
new_files = {c["file"] for c in ex.components}
merged = [c for c in old if c["file"] not in new_files] + ex.components
comps_path.write_text(json.dumps(merged, ensure_ascii=False, indent=1), encoding="utf-8")
print("components:", len(merged))
