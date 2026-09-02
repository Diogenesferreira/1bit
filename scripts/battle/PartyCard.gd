extends Control
class_name PartyCard

signal skill_activated

# Modelo final de 02/09/2026: os cinco cards tem exatamente 152x188.
# O lider se distingue apenas pelo anel/halo dourado e pela placa LEADER.
const CARD_SIZE := Vector2(152, 188)
const GOLD := Color("c9a842")
const DEAD_ALPHA := 0.12
const HERO_SCALE := 1.5
const HERO_BASE_Y := 140.0
const SYMBOL_SIZE := Vector2(20, 20)
const CHAR_LOGICAL := {
	"dragon": Vector2i(57, 54),
	"knight": Vector2i(44, 58),
	"nature": Vector2i(60, 58),
	"light": Vector2i(54, 56),
	"dark": Vector2i(52, 54),
	"heal": Vector2i(46, 54),
}

var element := "dragon"
var hero_name := "IGNAR"
var level := 1
var charge := 0
var leader := false
var guest := false

var _hero: TextureRect
var _pips: Array[ColorRect] = []
var _name_label: BitmapFontLabel
var _level_digits: Control
var _disabled := false


func montar(p_element: String, p_name: String, p_level: int,
		p_leader := false, p_guest := false) -> void:
	element = p_element
	hero_name = p_name.to_upper()
	level = clampi(p_level, 0, 99)
	leader = p_leader
	guest = p_guest
	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	pivot_offset = CARD_SIZE / 2.0
	_build()


func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.free()
	_pips.clear()
	var ring := GOLD if leader else Arte.cor_elemental(element)

	if leader:
		_build_leader_glow()
	_rect(Rect2(Vector2.ZERO, CARD_SIZE), Color("0d0e0c"))
	_border(Rect2(Vector2.ZERO, CARD_SIZE), 2, Color("14140f"))
	var inner := Rect2(2, 2, CARD_SIZE.x - 4, CARD_SIZE.y - 4)
	_texture(Arte.party_field(element), inner, true)
	_texture(Arte.party_scene(element), Rect2(1, 2, 150, 138))
	_border(inner, 2, ring)

	var logical: Vector2i = CHAR_LOGICAL.get(element, Vector2i(52, 54))
	# Os PNGs char80 foram entregues em 4x. No card eles usam 1,5x logico;
	# os 2x anteriores faziam os bustos dominarem toda a cena.
	var draw := Vector2(round(logical.x * HERO_SCALE), round(logical.y * HERO_SCALE))
	_hero = _texture(Arte.party_hero(element), Rect2(
		Vector2(round((CARD_SIZE.x - draw.x) / 2.0), HERO_BASE_Y - draw.y), draw))

	# Selo elemental espelhado pela placa LEADER no outro canto.
	_rect(Rect2(-3, -3, 30, 30), Color("0d0e0c"), 20)
	_border(Rect2(-3, -3, 30, 30), 2, ring, 21)
	# O atlas de simbolos e 3x (60x60). O glifo volta a 20x20, centralizado
	# no encaixe de 30x30, enquanto a moldura permanece exatamente no lugar.
	var symbol := _texture(Arte.party_symbol(element), Rect2(Vector2(2, 2), SYMBOL_SIZE))
	symbol.z_index = 22

	_build_skill_bar(ring)
	_build_name_plate(ring)
	if leader:
		_build_leader_plaque()
	if guest:
		_build_guest_marker()

	set_charge(charge)
	set_level(level)
	set_hero_name(hero_name)
	set_disabled(_disabled)


func _build_leader_glow() -> void:
	var halo := Panel.new()
	halo.position = Vector2(2, 2)
	halo.size = CARD_SIZE - Vector2(4, 4)
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	halo.z_index = -1
	var style := StyleBoxFlat.new()
	style.bg_color = Color(GOLD, 0.035)
	style.border_color = Color(GOLD, 0.30)
	style.set_border_width_all(2)
	style.shadow_color = Color(GOLD, 0.40)
	style.shadow_size = 8
	halo.add_theme_stylebox_override("panel", style)
	add_child(halo)


func _build_skill_bar(ring: Color) -> void:
	var bar := Rect2(9, CARD_SIZE.y - 41, CARD_SIZE.x - 18, 10)
	_rect(bar, Color("121211"), 24)
	_border(bar, 1, ring if leader else Color(0.79, 0.75, 0.66, 0.45), 25)
	const PIP_SIZE := Vector2(14, 6)
	const PIP_GAP := 2.0
	var total_width := PIP_SIZE.x * 8.0 + PIP_GAP * 7.0
	var x0: float = bar.position.x + round((bar.size.x - total_width) / 2.0)
	for i in 8:
		var pip := ColorRect.new()
		pip.position = Vector2(x0 + i * (PIP_SIZE.x + PIP_GAP), bar.position.y + 2)
		pip.size = PIP_SIZE
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pip.z_index = 26
		add_child(pip)
		_pips.append(pip)


func _build_name_plate(ring: Color) -> void:
	var plate := Rect2(2, CARD_SIZE.y - 26, CARD_SIZE.x - 4, 24)
	_rect(plate, Color("0d0e0c"), 30)
	_rect(Rect2(plate.position, Vector2(plate.size.x, 1)), ring, 31)

	_level_digits = Control.new()
	_level_digits.position = plate.position + Vector2(6, 3)
	_level_digits.z_index = 32
	_level_digits.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_level_digits)

	_name_label = BitmapFontLabel.new()
	_name_label.glyph_height = 16
	_name_label.letter_spacing = 1
	_name_label.position = plate.position + Vector2(43, 4)
	_name_label.z_index = 32
	add_child(_name_label)


func _build_leader_plaque() -> void:
	const WIDTH := 117.0
	var x := CARD_SIZE.x + 3.0 - WIDTH
	var plaque := Rect2(x, -14, WIDTH, 22)
	_rect(plaque, Color("0d0e0c"), 40)
	_border(plaque, 1, GOLD, 41)
	_rect(Rect2(x + 8, -5, 4, 4), GOLD, 42)
	_rect(Rect2(x + WIDTH - 12, -5, 4, 4), GOLD, 42)
	var label := BitmapFontLabel.new()
	label.text = "LEADER"
	label.glyph_height = 16
	label.letter_spacing = 3
	label.position = Vector2(x + 16, -11)
	label.z_index = 42
	add_child(label)


func _build_guest_marker() -> void:
	var marker := Panel.new()
	marker.position = Vector2(CARD_SIZE.x - 18, 8)
	marker.size = Vector2(10, 10)
	marker.rotation = deg_to_rad(45)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.z_index = 35
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color("c9c0a8")
	style.set_border_width_all(2)
	marker.add_theme_stylebox_override("panel", style)
	add_child(marker)


func set_charge(value: int) -> void:
	charge = clampi(value, 0, 8)
	var lit := Arte.cor_elemental_clara(element)
	for i in _pips.size():
		_pips[i].color = lit if i < charge else Color("1a1a16")
	_refresh_interaction()


func set_level(value: int) -> void:
	level = clampi(value, 0, 99)
	if _level_digits == null:
		return
	for child in _level_digits.get_children():
		_level_digits.remove_child(child)
		child.free()
	var value_text := str(level)
	var chip_width := maxf(30.0, value_text.length() * 12.0 + 8.0)
	var chip := ColorRect.new()
	chip.color = GOLD if leader else Arte.cor_elemental(element)
	chip.size = Vector2(chip_width, 18)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level_digits.add_child(chip)
	var x := chip_width - 4.0 - value_text.length() * 12.0
	for character in value_text:
		var atlas := AtlasTexture.new()
		atlas.atlas = Arte.party_digits()
		atlas.region = Rect2(int(character) * 12, 0, 12, 14)
		var digit := TextureRect.new()
		digit.texture = atlas
		digit.position = Vector2(x, 2)
		digit.size = Vector2(12, 14)
		digit.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		digit.stretch_mode = TextureRect.STRETCH_SCALE
		digit.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		digit.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_level_digits.add_child(digit)
		x += 12.0


func set_hero_name(value: String) -> void:
	hero_name = value.to_upper()
	if _name_label != null:
		_name_label.text = hero_name


func set_disabled(value: bool) -> void:
	_disabled = value
	if _hero != null:
		_hero.modulate.a = DEAD_ALPHA if _disabled else 1.0
	_refresh_interaction()


func hero_center() -> Vector2:
	return _hero.position + _hero.size / 2.0 if _hero != null else CARD_SIZE / 2.0


func piscar() -> void:
	if _hero == null:
		return
	if _hero.material == null:
		_hero.material = Arte.material_inversor(0.0)
	var material := _hero.material as ShaderMaterial
	var tween := create_tween()
	tween.tween_method(func(value: float) -> void:
		material.set_shader_parameter("quantidade", value), 0.0, 1.0, 0.11)
	tween.tween_method(func(value: float) -> void:
		material.set_shader_parameter("quantidade", value), 1.0, 0.0, 0.11)
	await tween.finished


func _refresh_interaction() -> void:
	var ready := charge >= 8 and not _disabled
	mouse_filter = Control.MOUSE_FILTER_STOP if ready else Control.MOUSE_FILTER_IGNORE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if ready else Control.CURSOR_ARROW
	tooltip_text = "SKILL PRONTA - toque para usar" if ready else ""


func _gui_input(event: InputEvent) -> void:
	var pressed: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed
	pressed = pressed or (event is InputEventScreenTouch and event.pressed)
	if not pressed or charge < 8 or _disabled:
		return
	accept_event()
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.06, 1.06), 0.07) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.11) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	skill_activated.emit()


func _rect(rect: Rect2, color: Color, z := 0) -> ColorRect:
	var node := ColorRect.new()
	node.position = rect.position
	node.size = rect.size
	node.color = color
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.z_index = z
	add_child(node)
	return node


func _border(rect: Rect2, width: float, color: Color, z := 0) -> void:
	_rect(Rect2(rect.position, Vector2(rect.size.x, width)), color, z)
	_rect(Rect2(rect.position + Vector2(0, rect.size.y - width),
		Vector2(rect.size.x, width)), color, z)
	_rect(Rect2(rect.position, Vector2(width, rect.size.y)), color, z)
	_rect(Rect2(rect.position + Vector2(rect.size.x - width, 0),
		Vector2(width, rect.size.y)), color, z)


func _texture(texture: Texture2D, rect: Rect2, tiled := false) -> TextureRect:
	var node := TextureRect.new()
	node.texture = texture
	node.position = rect.position
	node.size = rect.size
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_TILE if tiled else TextureRect.STRETCH_SCALE
	node.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED if tiled \
		else CanvasItem.TEXTURE_REPEAT_DISABLED
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)
	return node
