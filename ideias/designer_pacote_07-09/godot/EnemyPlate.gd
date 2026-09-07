## Placa de TURN + barra de HP do inimigo.
## Contrato: spec/ENEMY_HUD.md. Espaco: ENEMY_PLATE (32k x 12k).
##
## k SO pode ser 4 ou 6 — sao as duas reducoes inteiras das folhas de 384x144
## (1/3 e 1/2). Qualquer outro k produz meio pixel na borda.
class_name EnemyPlate
extends Control

const ART := "res://art/"

var k := 4
var elemento := "dragon"
var turno := 1
var hp := 100
var hp_max := 100

var _fill_clip: Control
var _fill: TextureRect
var _hit_at := -1.0

func setup(p_k: int, p_el: String, p_turno: int, p_hp: int, p_hp_max: int) -> void:
	k = p_k; elemento = p_el; turno = p_turno; hp = p_hp; hp_max = p_hp_max

func _ready() -> void:
	var pw := 32 * k
	var ph := 12 * k
	custom_minimum_size = Vector2(pw, ph)
	size = custom_minimum_size
	set_anchors_preset(Control.PRESET_TOP_LEFT)

	_tex(ART + "enemy/enemy_turn_plate_%s_v1.png" % elemento, Rect2i(0, 0, pw, ph))

	var dw := int(round(3.5 * k))
	var dh := 4 * k
	var at := AtlasTexture.new()
	at.atlas = load(ART + "enemy/enemy_digits_sheet_v1.png")
	at.region = Rect2(turno * 42, 0, 42, 48)   # folha nativa: celula 42x48
	var digit := TextureRect.new()
	digit.texture = at
	digit.position = Vector2(int(round(11.5 * k)), k)
	digit.size = Vector2(dw, dh)
	digit.stretch_mode = TextureRect.STRETCH_SCALE
	digit.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(digit)

	_tex(ART + "enemy/enemy_label_turn_v1.png",
		Rect2i(int(round(15.5 * k)), k, 12 * k, dh))
	_tex(ART + "enemy/enemy_hp_well_v1.png", Rect2i(0, 0, pw, ph))

	# FILL_CLIP e o unico no que clipa: o fill cresce por LARGURA
	_fill_clip = Control.new()
	_fill_clip.position = Vector2.ZERO
	_fill_clip.size = Vector2(pw * float(hp) / maxf(1.0, float(hp_max)), ph)
	_fill_clip.clip_contents = true
	_fill_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fill_clip)
	_fill = TextureRect.new()
	_fill.texture = load(ART + "enemy/enemy_hp_fill_v1.png")
	_fill.size = Vector2(pw, ph)
	_fill.stretch_mode = TextureRect.STRETCH_SCALE
	_fill.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_fill_clip.add_child(_fill)

func set_hp(v: int) -> void:
	hp = clampi(v, 0, hp_max)
	var alvo := 32.0 * k * float(hp) / maxf(1.0, float(hp_max))
	var t := create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_fill_clip, "size:x", alvo, 0.42)
	_hit_at = Time.get_ticks_msec() / 1000.0

## Tremor por INTERPOLACAO (spec/ANIMACOES_V2.md secao 2) — nunca por tween,
## senao um segundo golpe dentro dos 300 ms sai sem tremor.
func tremor_offset(vivo: bool) -> Vector2:
	if _hit_at < 0.0:
		return Vector2.ZERO
	var t := Time.get_ticks_msec() / 1000.0 - _hit_at
	if t > 0.3:
		return Vector2.ZERO
	var decay := 1.0 - t / 0.3
	var p := t * 1000.0 / 34.0
	var a := 6.0 if vivo else 2.0
	return Vector2(sin(p * 3.1) * a * decay, cos(p * 4.7) * a * 0.45 * decay)

func _tex(path: String, r: Rect2i) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(path)
	t.position = r.position
	t.size = r.size
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(t)
	return t
