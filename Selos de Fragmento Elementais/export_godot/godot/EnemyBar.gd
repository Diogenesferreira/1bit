# EnemyBar.gd — life + turno do inimigo (Godot 4)
#
# Árvore de nós esperada (todos Sprite2D, centered = false, position = ZERO):
#
#   EnemyBar          (Node2D, este script)
#     Plate           -> enemy_turn_plate_{el}_v1.png
#     Digit           -> enemy_digits_sheet_v1.png  (AtlasTexture 42x48), position = (138, 12)
#     Label           -> enemy_label_turn_v1.png,                          position = (186, 12)
#     Well            -> enemy_hp_well_v1.png
#     Fill            -> enemy_hp_fill_v1.png       (AtlasTexture, recorte por largura)

extends Node2D

const CANVAS := Vector2(384, 144)
const HP_X := 12.0          # inicio da area util da barra
const HP_W := 360.0         # largura util da barra
const DIGIT_CELL := Vector2(42, 48)
const MAX_TURNS := 5        # a arte suporta 1..5 (um digito)

const COLORS := {
	"dragon": Color("#a8443a"),
	"knight": Color("#5a86a8"),
	"nature": Color("#7d9455"),
	"light": Color("#c9a842"),
	"dark": Color("#7a5f9a"),
}

@export_enum("dragon", "knight", "nature", "light", "dark") var element: String = "dragon"
@export_range(0.0, 1.0, 0.01) var hp: float = 1.0 : set = set_hp
@export_range(1, 5) var turns_max: int = 3
@export_range(0, 5) var turns_left: int = 3 : set = set_turns_left

signal enemy_attacks
signal enemy_died

var _low_time := 0.0

func _ready() -> void:
	var base := "res://art/enemy/"
	$Plate.texture = load(base + "enemy_turn_plate_%s_v1.png" % element)
	$Well.texture = load(base + "enemy_hp_well_v1.png")
	$Label.texture = load(base + "enemy_label_turn_v1.png")

	var digits: Texture2D = load(base + "enemy_digits_sheet_v1.png")
	var da := AtlasTexture.new()
	da.atlas = digits
	$Digit.texture = da

	var fill: Texture2D = load(base + "enemy_hp_fill_v1.png")
	var fa := AtlasTexture.new()
	fa.atlas = fill
	$Fill.texture = fa

	turns_max = clampi(turns_max, 1, MAX_TURNS)
	set_turns_left(turns_max)
	_apply_hp(true)

# ---------- HP ----------

func set_hp(value: float) -> void:
	hp = clampf(value, 0.0, 1.0)
	if is_inside_tree():
		_apply_hp(false)

func take_damage(fraction: float) -> void:
	# dreno de 420 ms, ease-out
	var target := clampf(hp - fraction, 0.0, 1.0)
	var tw := create_tween()
	tw.tween_method(_set_hp_raw, hp, target, 0.42).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(func():
		hp = target
		if target <= 0.0:
			_die())

func _set_hp_raw(v: float) -> void:
	hp = v
	_apply_hp(false)

func _apply_hp(instant: bool) -> void:
	var w: float = HP_X + hp * HP_W
	($Fill.texture as AtlasTexture).region = Rect2(0, 0, w, CANVAS.y)

func _die() -> void:
	# 200 ms snap: greyscale a 45% de brilho
	modulate = Color(0.45, 0.45, 0.45)
	emit_signal("enemy_died")

# ---------- Turnos (1..5) ----------

func set_turns_left(value: int) -> void:
	turns_left = clampi(value, 0, MAX_TURNS)
	if is_inside_tree():
		($Digit.texture as AtlasTexture).region = Rect2(
			turns_left * DIGIT_CELL.x, 0, DIGIT_CELL.x, DIGIT_CELL.y)

func advance_turn() -> void:
	# chame no fim do turno do jogador
	if turns_left <= 1:
		set_turns_left(0)
		_flash()
		emit_signal("enemy_attacks")
		set_turns_left(turns_max)
	else:
		set_turns_left(turns_left - 1)

func _flash() -> void:
	# 120 ms: placa pisca em bone e volta
	var tw := create_tween()
	tw.tween_property($Plate, "modulate", Color("#c9c0a8"), 0.06)
	tw.tween_property($Plate, "modulate", Color.WHITE, 0.06)

# ---------- HP baixo: pulso de 700 ms ----------

func _process(delta: float) -> void:
	if hp > 0.25 or hp <= 0.0:
		$Fill.modulate = Color.WHITE
		return
	_low_time += delta
	var t: float = fmod(_low_time, 0.7) / 0.7
	var pulse: float = 0.5 - 0.5 * cos(t * TAU)
	$Fill.modulate = Color(1.0, 1.0, 1.0).lerp(Color(1.35, 1.05, 1.0), pulse)
