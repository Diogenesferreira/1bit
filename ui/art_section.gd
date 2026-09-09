class_name ArtSection
extends Control
## A arte aprovada é a fonte de cada painel. Não há redesenho na abertura.
const ATLAS: Texture2D = preload("res://assets/reference/ilha_digital_approved.png")
const INK := Color("071526")
var patches: Dictionary = {}

func set_text_patch(key: String, rectangle: Rect2, value: String, font_size: int = 24, tint: Color = Color.WHITE) -> void:
	patches[key] = {"rect": rectangle, "text": value, "size": font_size, "tint": tint}
	queue_redraw()

func set_bar_patch(key: String, rectangle: Rect2, ratio: float, tint: Color) -> void:
	patches[key] = {"rect": rectangle, "ratio": clampf(ratio, 0.0, 1.0), "tint": tint}
	queue_redraw()

func _draw() -> void:
	for patch in patches.values():
		var rectangle: Rect2 = patch["rect"]
		draw_rect(rectangle, INK)
		if patch.has("ratio"):
			var fill := Rect2(rectangle.position, Vector2(rectangle.size.x * patch["ratio"], rectangle.size.y))
			draw_rect(fill, patch["tint"])
			if fill.size.x > 0:
				draw_rect(Rect2(fill.position, Vector2(fill.size.x, 2)), Color(1, 1, 1, 0.4))
		else:
			var font := ThemeDB.fallback_font
			var font_size: int = patch["size"]
			var baseline := rectangle.position + Vector2(1, (rectangle.size.y + font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0)
			draw_string(font, baseline, patch["text"], HORIZONTAL_ALIGNMENT_LEFT, rectangle.size.x - 2, font_size, patch["tint"])
