extends Control
class_name PlayerLifeBar

# Contrato do rodape LIFE. Somente a calha muda de largura.
const ROW_H := 24
const GAP := 14
const HEART := Vector2(27, 24)
const LABEL_GLYPH := 24
const VALUE_GLYPH := 24
const TEXT_SPACING := 2
const WELL_BORDER := 3
const BONE := Color("c9c0a8")
const EDGE := Color("2a2620")
const DRAIN_TIME := 0.42

var hp_max := 2400
var hp_current := 1840
var row_width := 468

var _well: Control
var _fill: TextureRect
var _tip: ColorRect
var _value: BitmapFontLabel
var _well_inner := 0
var _drain_tween: Tween


func _ready() -> void:
	custom_minimum_size = Vector2(row_width, ROW_H)
	size = custom_minimum_size
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	_build()


func _build() -> void:
	_texture(self, Arte.tex("ui_v11/ui/hp_heart_card.png"), Rect2(0, 0, HEART.x, HEART.y))

	var label := BitmapFontLabel.new()
	label.glyph_height = LABEL_GLYPH
	label.letter_spacing = TEXT_SPACING
	label.text = "HP"
	label.tint = Color(1, 1, 1, 0.85)
	label.position = Vector2(HEART.x + GAP, (ROW_H - LABEL_GLYPH) / 2.0)
	add_child(label)

	_value = BitmapFontLabel.new()
	_value.glyph_height = VALUE_GLYPH
	_value.letter_spacing = TEXT_SPACING
	_value.tint = Color("e8e3d4")
	add_child(_value)

	var label_width := _text_width("HP", LABEL_GLYPH, TEXT_SPACING)
	# A reserva acompanha o HP maximo da partida. Com hp_max=9999, os nove
	# glifos de 9999/9999 cabem sem empurrar ou cobrir a calha.
	var reserved_value_width := _text_width(
		"%d/%d" % [hp_max, hp_max], VALUE_GLYPH, TEXT_SPACING)
	var well_x := int(HEART.x) + GAP + label_width + GAP
	var well_width := row_width - well_x - GAP - reserved_value_width
	_well = Control.new()
	_well.position = Vector2(well_x, 0)
	_well.size = Vector2(well_width, ROW_H)
	_well.custom_minimum_size = _well.size
	_well.clip_contents = true
	_well.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_well)

	_texture(_well, Arte.tex("ui_v11/ui/hp_tile_field.png"),
		Rect2(0, 0, well_width, ROW_H), true)
	_well_inner = well_width - 2 * WELL_BORDER
	_fill = _texture(_well, Arte.tex("ui_v11/ui/hp_tile_fill.png"),
		Rect2(WELL_BORDER, WELL_BORDER, _well_inner, ROW_H - 2 * WELL_BORDER), true)
	_tip = _rect(_well, Rect2(WELL_BORDER, WELL_BORDER,
		WELL_BORDER, ROW_H - 2 * WELL_BORDER), EDGE)
	_border(_well, Rect2(0, 0, well_width, ROW_H), WELL_BORDER, BONE)
	_apply(float(hp_current))


func set_hp(value: int) -> void:
	if _drain_tween != null:
		_drain_tween.kill()
	hp_current = clampi(value, 0, hp_max)
	_apply(float(hp_current))


func drain_to(value: int) -> void:
	var target := clampi(value, 0, hp_max)
	if target == hp_current:
		return
	if _drain_tween != null:
		_drain_tween.kill()
	var from := hp_current
	hp_current = target
	_drain_tween = create_tween()
	_drain_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_drain_tween.tween_method(_apply, float(from), float(target), DRAIN_TIME)


func _apply(value: float) -> void:
	var ratio := clampf(value / maxf(1.0, float(hp_max)), 0.0, 1.0)
	var fill_width := int(round(_well_inner * ratio))
	if _fill != null:
		_fill.size.x = fill_width
		_fill.visible = fill_width > 0
	if _tip != null:
		_tip.position.x = WELL_BORDER + fill_width
		_tip.visible = fill_width > 0 and fill_width < _well_inner
	if _value != null:
		var text_value := "%d/%d" % [int(round(value)), hp_max]
		_value.text = text_value
		_value.position = Vector2(row_width - _text_width(
			text_value, VALUE_GLYPH, TEXT_SPACING),
			(ROW_H - VALUE_GLYPH) / 2.0)


func _text_width(value: String, glyph_height: int, spacing: int) -> int:
	var glyph_width := int(round(glyph_height * 12.0 / 16.0))
	return maxi(0, value.length() * (glyph_width + spacing) - spacing)


func _rect(parent: Node, rect: Rect2, color: Color) -> ColorRect:
	var node := ColorRect.new()
	node.position = rect.position
	node.size = rect.size
	node.color = color
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node


func _border(parent: Node, rect: Rect2, width: float, color: Color) -> void:
	_rect(parent, Rect2(rect.position, Vector2(rect.size.x, width)), color)
	_rect(parent, Rect2(rect.position + Vector2(0, rect.size.y - width),
		Vector2(rect.size.x, width)), color)
	_rect(parent, Rect2(rect.position, Vector2(width, rect.size.y)), color)
	_rect(parent, Rect2(rect.position + Vector2(rect.size.x - width, 0),
		Vector2(width, rect.size.y)), color)


func _texture(parent: Node, texture: Texture2D, rect: Rect2, tiled := false) -> TextureRect:
	var node := TextureRect.new()
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.texture = texture
	node.position = rect.position
	node.size = rect.size
	node.stretch_mode = TextureRect.STRETCH_TILE if tiled else TextureRect.STRETCH_SCALE
	node.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED if tiled \
		else CanvasItem.TEXTURE_REPEAT_DISABLED
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node
