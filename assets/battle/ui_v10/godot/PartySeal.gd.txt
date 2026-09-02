## Selo 1A de um personagem: foto + moldura + arco de carga (0..8).
class_name PartySeal
extends Control

const ART := "res://art/seals_1a/"
const DISPLAY := BattleLayout.SEAL_DISPLAY      # 165
const SRC := 330

@export var element: String = "nature"
@export var portrait: Texture2D
@export var charge: int = 0: set = set_charge  # 0..8
@export var active: bool = false

var _photo: TextureRect
var _frame: TextureRect
var _arc: TextureRect

func _ready() -> void:
	custom_minimum_size = Vector2(DISPLAY, DISPLAY)
	size = custom_minimum_size

	var win := BattleLayout.SEAL_WINDOW
	var bg := ColorRect.new()
	bg.color = BattleLayout.C_SLOT_BG
	bg.position = win.position
	bg.size = win.size
	add_child(bg)

	_photo = TextureRect.new()
	_photo.texture = portrait
	_photo.position = win.position
	_photo.size = win.size
	_photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_photo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_photo)

	_frame = _full(ART + "seal_1a_%s_empty.png" % element)
	_arc = _full("")                                  # recebe AtlasTexture abaixo
	set_charge(charge)
	if active:
		var s := ShaderMaterial.new()                  # ou use um CanvasGroup com glow
		material = s
		modulate = Color(1.06, 1.06, 1.06)

func _full(path: String) -> TextureRect:
	var t := TextureRect.new()
	if path != "": t.texture = load(path)
	t.position = Vector2.ZERO
	t.size = Vector2(DISPLAY, DISPLAY)
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(t)
	return t

func set_charge(n: int) -> void:
	charge = clampi(n, 0, BattleLayout.SEAL_FRAMES - 1)
	if _arc == null: return
	var at := AtlasTexture.new()
	at.atlas = load(ART + "seal_1a_%s_charge_sheet.png" % element)
	at.region = Rect2(0, charge * SRC, SRC, SRC)
	_arc.texture = at

## 1 encaixe por vez, 200 ms cada (animacao 6 do contrato).
func charge_to(target: int) -> void:
	var t := create_tween()
	for step in range(charge + 1, clampi(target, 0, 8) + 1):
		t.tween_callback(set_charge.bind(step))
		t.tween_interval(BattleLayout.T_CHARGE_STEP)
