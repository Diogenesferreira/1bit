extends Control
class_name TopBar

const ROW_H := 72
const EMBLEM := 68
const GAP := 16
const ICON_CELL := 20
const TRACK := 1
const BOX_COIN := 90
const BOX_GEM := 64
const BOX_ENERGY := 90
const BOX_LV := 38
const BOX_XP := 51
const BONE := Color("c9c0a8")
const PLATE_BG := Color("121211")
const ENERGY_BG := Color("141512")
const BORDER_SOFT := Color(0.79, 0.75, 0.66, 0.32)
const BORDER_HARD := Color(0.79, 0.75, 0.66, 0.55)

var account_name := "VAELDRIN"
var account_level := 24
var xp_current := 1360
var xp_ratio := 0.62
var coins := 1240
var gems := 36
var energy := 12
var energy_max := 20
var row_width := 886

var _lv: BitmapFontLabel
var _xp_value: BitmapFontLabel
var _xp_fill: ColorRect
var _coin: BitmapFontLabel
var _gem: BitmapFontLabel
var _energy: BitmapFontLabel


func _ready() -> void:
	custom_minimum_size = Vector2(row_width, ROW_H)
	size = custom_minimum_size
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	_build()


func _build() -> void:
	var emblem_y := int((ROW_H - EMBLEM) / 2.0)
	_rect(self, Rect2(0, emblem_y, EMBLEM, EMBLEM), ENERGY_BG)
	_border(self, Rect2(0, emblem_y, EMBLEM, EMBLEM), 2,
		Color(0.79, 0.75, 0.66, 0.6))
	_rect(self, Rect2(3, emblem_y + 3, EMBLEM - 6, EMBLEM - 6), Color("0b0d0a"))
	var portrait := _texture(self, Arte.tex_recortada("characters_v4/ally_dragon_v1.png",
		Rect2(260, 20, 730, 730)), Rect2(3, emblem_y + 3, 62, 62))
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_rect(self, Rect2(-2, emblem_y - 2, 9, 9), BONE)
	_rect(self, Rect2(EMBLEM - 7, emblem_y + EMBLEM - 7, 9, 9), BONE)

	var column_x := EMBLEM + GAP
	var name_label := _label(account_name, 17, 2)
	name_label.position = Vector2(column_x, 20)
	var chip_x := column_x + int(name_label.custom_minimum_size.x) + 12
	var chip_width := 7 + 24 + 6 + BOX_LV + 7
	_rect(self, Rect2(chip_x, 19, chip_width, 22), PLATE_BG)
	_border(self, Rect2(chip_x, 19, chip_width, 22), 1, BORDER_SOFT)
	var lv_label := _label("LV", 16, TRACK)
	lv_label.tint = Color(1, 1, 1, 0.55)
	lv_label.position = Vector2(chip_x + 7, 22)
	_lv = _label("", 16, TRACK)
	_lv.position = Vector2(chip_x + 37, 22)
	_lv.align_right_in = BOX_LV

	var xp_label := _label("XP", 16, TRACK)
	xp_label.tint = Color(1, 1, 1, 0.55)
	xp_label.position = Vector2(column_x, 47)
	var xp_well := Rect2(column_x + 34, 47, 214, 13)
	_rect(self, xp_well, PLATE_BG)
	_border(self, xp_well, 1, Color(0.79, 0.75, 0.66, 0.5))
	_xp_fill = _rect(self, Rect2(xp_well.position + Vector2(2, 2), Vector2(0, 9)), BONE)
	_xp_value = _label("", 16, TRACK)
	_xp_value.tint = Color(1, 1, 1, 0.8)
	_xp_value.position = Vector2(xp_well.end.x + 9, 47)
	_xp_value.align_right_in = BOX_XP

	var energy_width := 10 + ICON_CELL + 7 + BOX_ENERGY + 10
	var coin_width := 10 + ICON_CELL + 7 + BOX_COIN + 10
	var gem_width := 10 + ICON_CELL + 7 + BOX_GEM + 10
	var menu_width := 38
	var energy_x := row_width - menu_width - 12 - energy_width
	var rack_x := energy_x - 12 - (coin_width + 1 + gem_width)
	var rack_y := int((ROW_H - 30) / 2.0)
	_rect(self, Rect2(rack_x, rack_y, coin_width + 1 + gem_width, 30), PLATE_BG)
	_border(self, Rect2(rack_x, rack_y, coin_width + 1 + gem_width, 30), 1, BORDER_SOFT)
	_rect(self, Rect2(rack_x + coin_width, rack_y, 1, 30),
		Color(0.79, 0.75, 0.66, 0.25))
	_coin = _counter(rack_x, rack_y, "ui_v11/ui/icon_coin.png", BOX_COIN)
	_gem = _counter(rack_x + coin_width + 1, rack_y, "ui_v11/ui/icon_gem.png", BOX_GEM)

	_rect(self, Rect2(energy_x, rack_y, energy_width, 30), ENERGY_BG)
	_border(self, Rect2(energy_x, rack_y, energy_width, 30), 1, BORDER_HARD)
	_energy = _counter(energy_x, rack_y, "ui_v11/ui/icon_energy.png", BOX_ENERGY)
	for i in 3:
		_rect(self, Rect2(row_width - 34, int(ROW_H / 2.0) - 13 + i * 11, 34, 5), BONE)
	refresh()


func _counter(x: int, y: int, icon_path: String, box_width: int) -> BitmapFontLabel:
	_texture(self, Arte.tex(icon_path), Rect2(x + 10, y + 5, ICON_CELL, ICON_CELL))
	var label := _label("", 16, TRACK)
	label.position = Vector2(x + 10 + ICON_CELL + 7, y + 7)
	label.align_right_in = box_width
	return label


func refresh() -> void:
	_lv.text = str(clampi(account_level, 1, 999))
	_coin.text = str(coins)
	_gem.text = str(gems)
	_energy.text = "%d/%d" % [energy, energy_max]
	_xp_value.text = str(xp_current)
	_xp_fill.size.x = int(round(210 * clampf(xp_ratio, 0.0, 1.0)))


func set_energy(value: int, maximum: int) -> void:
	energy = value
	energy_max = maximum
	_energy.text = "%d/%d" % [value, maximum]


func _label(text_value: String, height: int, spacing: int) -> BitmapFontLabel:
	var label := BitmapFontLabel.new()
	label.glyph_height = height
	label.letter_spacing = spacing
	label.text = text_value
	add_child(label)
	return label


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
	_rect(parent, Rect2(rect.position + Vector2(0, rect.size.y - width), Vector2(rect.size.x, width)), color)
	_rect(parent, Rect2(rect.position, Vector2(width, rect.size.y)), color)
	_rect(parent, Rect2(rect.position + Vector2(rect.size.x - width, 0), Vector2(width, rect.size.y)), color)


func _texture(parent: Node, texture: Texture2D, rect: Rect2) -> TextureRect:
	var node := TextureRect.new()
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.texture = texture
	node.position = rect.position
	node.size = rect.size
	node.stretch_mode = TextureRect.STRETCH_SCALE
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node
