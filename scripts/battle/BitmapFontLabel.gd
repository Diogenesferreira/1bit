@tool
extends Control
class_name BitmapFontLabel

# Texto da UI montado diretamente com o atlas final 1:1. Em 16 px, cada pixel
# da textura corresponde a exatamente um pixel do canvas.

const ORDER := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ/-:"
const CELL := Vector2i(12, 16)

@export var text: String = "": set = _set_text
@export var glyph_height := 16: set = _set_height
@export var tint := Color("c9c0a8"): set = _set_tint
@export var letter_spacing := 0: set = _set_spacing
@export var align_right_in := 0: set = _set_align_right

var _sheet: Texture2D


func _ready() -> void:
	_sheet = Arte.tex("ui_v11/ui/font_1x_v1.png")
	_rebuild()


func _set_text(value: String) -> void:
	text = value.to_upper()
	_rebuild()


func _set_height(value: int) -> void:
	glyph_height = value
	_rebuild()


func _set_tint(value: Color) -> void:
	tint = value
	_rebuild()


func _set_spacing(value: int) -> void:
	letter_spacing = value
	_rebuild()


func _set_align_right(value: int) -> void:
	align_right_in = maxi(0, value)
	_rebuild()


func _rebuild() -> void:
	if _sheet == null:
		_sheet = Arte.tex("ui_v11/ui/font_1x_v1.png")
		if _sheet == null:
			return
	for child in get_children():
		remove_child(child)
		child.free()
	var scale_factor := float(glyph_height) / float(CELL.y)
	var glyph_width := int(round(float(CELL.x) * scale_factor))
	var advance := glyph_width + letter_spacing
	var text_width := maxi(0, text.length() * advance - letter_spacing)
	var x := maxi(0, align_right_in - text_width)
	for character in text:
		var index := ORDER.find(character)
		if index >= 0:
			var atlas := AtlasTexture.new()
			atlas.atlas = _sheet
			atlas.region = Rect2(index * CELL.x, 0, CELL.x, CELL.y)
			var glyph := TextureRect.new()
			glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			glyph.stretch_mode = TextureRect.STRETCH_SCALE
			glyph.texture = atlas
			glyph.position = Vector2(x, 0)
			glyph.size = Vector2(glyph_width, glyph_height)
			glyph.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			glyph.modulate = tint
			glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(glyph)
		x += advance
	var final_width := maxi(text_width, align_right_in)
	custom_minimum_size = Vector2(final_width, glyph_height)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
