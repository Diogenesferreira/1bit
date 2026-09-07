## Barra de LIFE do jogador — v2 (07/09/2026).
##
## MUDOU: o preenchimento nao e mais tile de PNG (hp_tile_fill.png) — e dither
## procedural de faixas de 3 px, igual a barra de energia. Ver
## spec/LIFE_BAR_V2.md e spec/CONTRADICOES.md item 2.
##
## Contrato de layout em `spec/LIFE_BAR.md`. As regras que valem aqui, iguais
## às do PartyCard:
##   1. `_well` é o único nó que clipa; o fill é filho dele.
##   2. O fill cresce da ESQUERDA por largura, nunca por `scale`.
##   3. Label e valor são BitmapFontLabel (folha 1:1), não PNG estático — o
##      valor muda em runtime e PNG reescalado borra.
class_name PlayerLifeBar
extends Control

const ART := "res://art/"
const ROW_H := 24                 # altura da linha inteira = altura da calha
const GAP := 14                   # espaço entre os quatro blocos
const HEART := Vector2i(27, 24)
const LABEL_GLYPH := 12           # "HP" em glyph_height 12 -> 18px de largura
const VALUE_GLYPH := 16           # "1840/2400" em 16 -> 9 glifos
const WELL_BORDER := 3
const FIELD_CELL := Vector2i(24, 24)
const FILL_CELL := Vector2i(24, 18)

const BONE := Color("c9c0a8")
const VOID := Color("14140f")
const EDGE := Color("2a2620")     # filete escuro na ponta do fill
const DRAIN_TIME := 0.42          # 420ms — animação de dreno do contrato

@export var hp_max: int = 2400
@export var hp_current: int = 1840
@export var row_width: int = 468  # largura total disponível; a calha é o resto

var _well: Control
var _fill: TextureRect
var _tip: ColorRect
var _value: BitmapFontLabel
var _well_inner: int = 0          # largura útil da calha (sem as bordas)

func _ready() -> void:
	custom_minimum_size = Vector2(row_width, ROW_H)
	size = custom_minimum_size
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	_build()

func _build() -> void:
	# --- bloco 1: coração (x = 0) ---
	_tex(self, ART + "ui/hp_heart_card.png", Rect2i(0, 0, HEART.x, HEART.y))

	# --- bloco 2: rótulo "HP" ---
	var label := BitmapFontLabel.new()
	label.glyph_height = LABEL_GLYPH
	label.tracking = 1
	label.text = "HP"
	label.modulate = Color(1, 1, 1, 0.65)
	var label_w := 2 * (LABEL_GLYPH * 12 / 16) + 1     # 2 glifos + 1 de tracking = 19
	label.position = Vector2(HEART.x + GAP, int((ROW_H - LABEL_GLYPH) / 2.0))
	add_child(label)

	# --- bloco 4 primeiro: o valor, para saber quanto sobra para a calha ---
	_value = BitmapFontLabel.new()
	_value.glyph_height = VALUE_GLYPH
	_value.tracking = 1
	add_child(_value)
	var value_w := _value_width()

	# --- bloco 3: a calha, ocupando o resto (equivale ao flex:1 do HTML) ---
	var well_x := HEART.x + GAP + label_w + GAP
	var well_w := row_width - well_x - GAP - value_w
	_well = Control.new()
	_well.position = Vector2(well_x, 0)
	_well.size = Vector2(well_w, ROW_H)
	_well.custom_minimum_size = _well.size
	_well.clip_contents = true          # <-- o fill nunca vaza da calha
	_well.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_well)

	# fundo em tile + borda de 3px (a borda é DESENHADA POR DENTRO, box-sizing:border-box)
	var field := _tex(_well, ART + "ui/hp_tile_field.png", Rect2i(0, 0, well_w, ROW_H))
	field.stretch_mode = TextureRect.STRETCH_TILE

	_well_inner = well_w - 2 * WELL_BORDER
	# dither de 3 px gerado em runtime: base | lit | base | lit ...
	_fill = _tex_dither(_well, Rect2i(WELL_BORDER, WELL_BORDER, _well_inner, ROW_H - 2 * WELL_BORDER),
		Color("a8443a"), Color("d9705f"))

	_tip = ColorRect.new()
	_tip.color = EDGE
	_tip.size = Vector2(WELL_BORDER, ROW_H - 2 * WELL_BORDER)
	_tip.position = Vector2(WELL_BORDER, WELL_BORDER)
	_well.add_child(_tip)

	_border(_well, Rect2i(0, 0, well_w, ROW_H), WELL_BORDER, BONE)

	_value.position = Vector2(row_width - value_w, int((ROW_H - VALUE_GLYPH) / 2.0))
	_apply(hp_current)

func _value_width() -> int:
	var txt := "%d/%d" % [hp_current, hp_max]
	return txt.length() * 13 - 1        # glifo 12 + tracking 1

# ------------------------------------------------------------------ API
func set_hp(v: int) -> void:
	hp_current = clampi(v, 0, hp_max)
	_apply(hp_current)

## Dreno animado, 420 ms, ease-out — animação da barra de vida no contrato.
func drain_to(v: int) -> void:
	var from := hp_current
	hp_current = clampi(v, 0, hp_max)
	var t := create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_method(_apply, float(from), float(hp_current), DRAIN_TIME)

func _apply(v: float) -> void:
	var ratio := clampf(v / maxf(1.0, float(hp_max)), 0.0, 1.0)
	var w := int(round(_well_inner * ratio))
	if _fill:
		_fill.size.x = w
		_fill.visible = w > 0
	if _tip:
		_tip.position.x = WELL_BORDER + w
		_tip.visible = w > 0 and w < _well_inner
	if _value:
		_value.text = "%d/%d" % [int(round(v)), hp_max]

# --------------------------------------------------------------- helpers
func _border(parent: Node, r: Rect2i, w: int, c: Color) -> void:
	_rect(parent, Rect2i(r.position.x, r.position.y, r.size.x, w), c)
	_rect(parent, Rect2i(r.position.x, r.position.y + r.size.y - w, r.size.x, w), c)
	_rect(parent, Rect2i(r.position.x, r.position.y, w, r.size.y), c)
	_rect(parent, Rect2i(r.position.x + r.size.x - w, r.position.y, w, r.size.y), c)

func _rect(parent: Node, r: Rect2i, c: Color) -> ColorRect:
	var n := ColorRect.new()
	n.color = c
	n.position = r.position
	n.size = r.size
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(n)
	return n

func _tex(parent: Node, path: String, r: Rect2i) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(path)
	t.position = r.position
	t.size = r.size
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t
