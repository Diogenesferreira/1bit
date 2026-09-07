## Rotulo em pixel art montado a partir de ui/font_1x_v1.png (folha 1:1, 480x16).
## Use no lugar de qualquer val_*.png para numeros que mudam em runtime.
@tool
class_name BitmapFontLabel
extends Control

const SHEET_PATH := "res://art/ui/font_1x_v1.png"
const ORDER := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ/-:"
const CELL := Vector2i(12, 16)   # folha 1:1 — 1 px de textura = 1 px de tela

@export var text: String = "0": set = _set_text
## altura final em px de design; 48, 24, 16 ou 12 mantem o pixel inteiro
@export var glyph_height: int = 24: set = _set_h
@export var tint: Color = Color("c9c0a8"): set = _set_tint
## Espaco extra entre glifos, em px de tela. HTML: gap dos flex. 0 = numerais colados.
@export var tracking: int = 0: set = _set_tracking
## Largura reservada. > 0 ancora o texto à DIREITA dentro dessa caixa: o nó fica
## com essa largura e os glifos são empurrados para o fim. Use em todo contador
## cujo número cresce (moeda, gema, energia, LV) — o layout não desloca.
@export var align_right_in: int = 0: set = _set_align_right

var _sheet: Texture2D

func _ready() -> void:
	_sheet = load(SHEET_PATH)
	_rebuild()

func _set_text(v: String) -> void: text = v.to_upper(); _rebuild()
func _set_h(v: int) -> void: glyph_height = v; _rebuild()
func _set_tint(v: Color) -> void: tint = v; _rebuild()

func _rebuild() -> void:
	if _sheet == null:
		_sheet = load(SHEET_PATH)
		if _sheet == null: return
	for c in get_children(): c.queue_free()
	var scale_f := float(glyph_height) / float(CELL.y)
	var adv := int(round(CELL.x * scale_f)) + tracking
	var x := 0
	for ch in text:
		var idx := ORDER.find(ch)
		if idx >= 0:
			var at := AtlasTexture.new()
			at.atlas = _sheet
			at.region = Rect2(idx * CELL.x, 0, CELL.x, CELL.y)
			var tr := TextureRect.new()
			tr.texture = at
			tr.position = Vector2(x, 0)
			tr.size = Vector2(adv, glyph_height)
			tr.stretch_mode = TextureRect.STRETCH_SCALE
			tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tr.modulate = tint
			add_child(tr)
		x += adv
	if x > 0: x -= tracking          # nao conta tracking depois do ultimo glifo
	if align_right_in > x:
		var shift := align_right_in - x
		for c in get_children(): c.position.x += shift
		x = align_right_in
	custom_minimum_size = Vector2(x, glyph_height)
	size = custom_minimum_size

func _set_tracking(v: int) -> void:
	tracking = v
	_rebuild()

func _set_align_right(v: int) -> void:
	align_right_in = v
	_rebuild()
