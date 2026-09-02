extends Control
class_name StagePlate

const PAD := Vector2i(13, 9)
const GAP := 12
const BONE := Color("c9c0a8")
const PLATE_BG := Color("0b0d0a")
const PLATE_BORDER := Color(0.79, 0.75, 0.66, 0.55)
const NODE_DONE := Color("c9c0a8")
const NODE_CURRENT := Color("7d9455")
const NODE_BOSS_EDGE := Color("c04a3e")
const NODE_BOSS_BG := Color("2a1512")

var stage := 2
var stage_total := 3
var boss_last := true


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	_build()


func _build() -> void:
	var label := _label("STAGE", 16, 2, Color(1, 1, 1, 0.6))
	var value := _label("%d/%d" % [stage, stage_total], 16, 1, Color.WHITE)
	var width := PAD.x + int(label.custom_minimum_size.x) + GAP \
		+ int(value.custom_minimum_size.x) + GAP + 1 + GAP + _trail_width() + PAD.x
	var height := 16 + PAD.y * 2
	custom_minimum_size = Vector2(width, height)
	size = custom_minimum_size
	var background := _rect(Rect2(0, 0, width, height), PLATE_BG)
	move_child(background, 0)
	_border(Rect2(0, 0, width, height), 1, PLATE_BORDER)

	var x := PAD.x
	label.position = Vector2(x, PAD.y)
	x += int(label.custom_minimum_size.x) + GAP
	value.position = Vector2(x, PAD.y)
	x += int(value.custom_minimum_size.x) + GAP
	_rect(Rect2(x, PAD.y - 1, 1, 18), Color(0.79, 0.75, 0.66, 0.28))
	x += 1 + GAP
	_build_trail(x, int(height / 2.0))


func _build_trail(x_start: int, center_y: int) -> void:
	var x := x_start
	for i in range(1, stage_total + 1):
		var is_boss := boss_last and i == stage_total
		var side := 12
		if i == stage:
			side = 15
		elif is_boss:
			side = 17
		var rect := Rect2(x, center_y - int(side / 2.0), side, side)
		if i < stage:
			_diamond(rect, NODE_DONE, 0, NODE_DONE)
		elif i == stage:
			_diamond(rect, NODE_CURRENT, 2, BONE)
		else:
			_diamond(rect, NODE_BOSS_BG if is_boss else Color("1a1a16"), 2,
				NODE_BOSS_EDGE if is_boss else Color(0.79, 0.75, 0.66, 0.45))
		x += side
		if i < stage_total:
			var alpha := 0.5 if i < stage else 0.28
			_rect(Rect2(x, center_y - 1, 20, 2), Color(0.79, 0.75, 0.66, alpha))
			x += 20
	if boss_last:
		var boss := _label("BOSS", 16, 2, Color(1, 1, 1, 0.8))
		boss.position = Vector2(x + 8, center_y - 8)


func _trail_width() -> int:
	var width := 0
	for i in range(1, stage_total + 1):
		var is_boss := boss_last and i == stage_total
		width += 15 if i == stage else (17 if is_boss else 12)
		if i < stage_total:
			width += 20
	if boss_last:
		width += 8 + 4 * 13 - 1 + 2 * 3
	return width


func _diamond(rect: Rect2, fill: Color, border_width: int, border_color: Color) -> void:
	var holder := Control.new()
	holder.position = rect.position + rect.size / 2.0
	holder.rotation = deg_to_rad(45)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	var box := _rect(holder, Rect2(-rect.size / 2.0, rect.size), fill)
	box.z_index = 1
	if border_width > 0:
		var local := Rect2(-rect.size / 2.0, rect.size)
		_border_on(holder, local, border_width, border_color, 2)


func _label(text_value: String, height: int, spacing: int, color: Color) -> BitmapFontLabel:
	var label := BitmapFontLabel.new()
	label.glyph_height = height
	label.letter_spacing = spacing
	label.text = text_value
	label.tint = color
	add_child(label)
	return label


func _rect(parent_or_rect: Variant, rect_or_color: Variant, color := Color.WHITE) -> ColorRect:
	var parent: Node = self
	var rect: Rect2
	var tint: Color
	if parent_or_rect is Node:
		parent = parent_or_rect
		rect = rect_or_color
		tint = color
	else:
		rect = parent_or_rect
		tint = rect_or_color
	var node := ColorRect.new()
	node.position = rect.position
	node.size = rect.size
	node.color = tint
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node


func _border(rect: Rect2, width: float, color: Color) -> void:
	_border_on(self, rect, width, color)


func _border_on(parent: Node, rect: Rect2, width: float, color: Color, z := 0) -> void:
	for edge in [
		Rect2(rect.position, Vector2(rect.size.x, width)),
		Rect2(rect.position + Vector2(0, rect.size.y - width), Vector2(rect.size.x, width)),
		Rect2(rect.position, Vector2(width, rect.size.y)),
		Rect2(rect.position + Vector2(rect.size.x - width, 0), Vector2(width, rect.size.y)),
	]:
		var node := _rect(parent, edge, color)
		node.z_index = z
