extends Node2D
class_name FragmentSealSquare
# Selo de Fragmento QUADRADO - modelo 1A (barra de skill na base)
# Textura 330x330, 1 px logico = 6 px. Abertura do personagem: x36 y30, 258x198.
# Folha de carga: 330x2970, 9 quadros (0..8 encaixes).

const SIZE := 330
const OPENING := Rect2(36, 30, 258, 198)
const COLORS := {
	"dragon": Color("a8443a"), "knight": Color("5a86a8"), "nature": Color("7d9455"),
	"light": Color("c9a842"), "dark": Color("7a5f9a")
}

@export_enum("dragon", "knight", "nature", "light", "dark") var element: String = "nature":
	set(v):
		element = v
		if is_inside_tree():
			_reload_textures()

@export_range(0, 8) var charge: int = 0:
	set(v):
		var old := charge
		charge = clampi(v, 0, 8)
		if is_inside_tree():
			_apply_charge(old)

signal ready_state_changed(is_ready: bool)

var _portrait: Sprite2D
var _clip: Control
var _frame: Sprite2D
var _charge: Sprite2D
var _glow: Sprite2D
var _pulse: Tween

func _ready() -> void:
	# 1. retrato recortado pela abertura
	_clip = Control.new()
	_clip.clip_contents = true
	_clip.position = OPENING.position
	_clip.size = OPENING.size
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_clip)

	_portrait = Sprite2D.new()
	_portrait.centered = false
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_clip.add_child(_portrait)

	# 2. moldura vazia
	_frame = _mk_sprite()
	# 3. encaixes acesos (folha)
	_charge = _mk_sprite()
	_charge.region_enabled = true
	# 4. brilho de pronta (aditivo)
	_glow = _mk_sprite()
	_glow.region_enabled = true
	_glow.region_rect = Rect2(0, 8 * SIZE, SIZE, SIZE)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = mat
	_glow.modulate.a = 0.0

	_reload_textures()
	_apply_charge(charge)

func _mk_sprite() -> Sprite2D:
	var s := Sprite2D.new()
	s.centered = false
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(s)
	return s

func _reload_textures() -> void:
	_frame.texture = load("res://frames_square/seal_sq_%s_empty_v1.png" % element)
	var sheet: Texture2D = load("res://charge_sheets_square/seal_sq_%s_charge_sheet_v1.png" % element)
	_charge.texture = sheet
	_glow.texture = sheet

# --- API ---
func set_portrait(tex: Texture2D, offset := Vector2.ZERO) -> void:
	_portrait.texture = tex
	# ancora o sprite embaixo/centro da abertura
	if tex:
		var ts := tex.get_size()
		_portrait.position = Vector2((OPENING.size.x - ts.x) * 0.5, OPENING.size.y - ts.y) + offset

func add_charge(amount := 1) -> void:
	charge = charge + amount

func spend() -> void:
	if charge < 8:
		return
	charge = 0
	var t := create_tween()
	for i in 2:
		t.tween_property(_frame, "modulate", Color(1.6, 1.6, 1.6), 0.06)
		t.tween_property(_frame, "modulate", Color.WHITE, 0.06)

func is_ready_skill() -> bool:
	return charge >= 8

func shake() -> void:
	var t := create_tween()
	var base := position
	for i in 10:
		t.tween_property(self, "position", base + Vector2(12 * (1 if i % 2 == 0 else -1), 0), 0.026)
	t.tween_property(self, "position", base, 0.026)

# --- interno ---
func _apply_charge(old: int) -> void:
	_charge.region_rect = Rect2(0, charge * SIZE, SIZE, SIZE)
	if charge > old and charge < 8:
		var t := create_tween()
		t.tween_property(_charge, "modulate", Color(1.8, 1.8, 1.8), 0.06)
		t.tween_property(_charge, "modulate", Color.WHITE, 0.06)
	if charge >= 8:
		_start_pulse()
	else:
		_stop_pulse()
	emit_signal("ready_state_changed", charge >= 8)

func _start_pulse() -> void:
	if _pulse and _pulse.is_valid():
		return
	_glow.self_modulate = COLORS.get(element, Color.WHITE)
	_pulse = create_tween().set_loops()
	_pulse.tween_property(_glow, "modulate:a", 0.8, 0.65).set_trans(Tween.TRANS_SINE)
	_pulse.tween_property(_glow, "modulate:a", 0.0, 0.65).set_trans(Tween.TRANS_SINE)

func _stop_pulse() -> void:
	if _pulse and _pulse.is_valid():
		_pulse.kill()
	_pulse = null
	_glow.modulate.a = 0.0
