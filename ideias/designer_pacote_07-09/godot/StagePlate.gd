## Plate de STAGE (canto inferior esquerdo do palco) — modelo de 02/09/2026.
## Contrato em `spec/TOP_BAR.md`, seção 4.
##
## O que estava errado antes: rótulo e valor eram PNGs (`lbl_stage`, `val_stage`)
## exibidos a 11 e 12px a partir de fontes de 48px de altura — reescala
## fracionária — sobre um plate translúcido (.72) em cima de um fundo escuro e
## ocupado. Ilegível. Agora: folha 1:1 e plate OPACO.
class_name StagePlate
extends Control

const ART := "res://art/"
const PAD := Vector2i(13, 9)
const GAP := 12
const NODE_GAP := 0            # os nós se tocam nas pontas do conector
const BONE := Color("c9c0a8")
const PLATE_BG := Color("0b0d0a")            # OPACO. não use alpha aqui.
const PLATE_BORDER := Color(0.79, 0.75, 0.66, 0.55)
const NODE_DONE := Color("c9c0a8")
const NODE_CURR := Color("7d9455")
const NODE_BOSS_EDGE := Color("c04a3e")
const NODE_BOSS_BG := Color("2a1512")

@export_range(1, 9) var stage: int = 2
@export_range(1, 9) var stage_total: int = 3
@export var boss_last: bool = true

func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	_build()

func _build() -> void:
	var lbl := _label("STAGE", 16, 2, Color(1, 1, 1, 0.6))
	var val := _label("%d/%d" % [stage, stage_total], 16, 1, Color.WHITE)
	var trail_w := _trail_width()
	var w := PAD.x + int(lbl.custom_minimum_size.x) + GAP + int(val.custom_minimum_size.x) \
		+ GAP + 1 + GAP + trail_w + PAD.x
	var h := 16 + PAD.y * 2

	custom_minimum_size = Vector2(w, h)
	size = custom_minimum_size

	# fundo desenhado ANTES dos filhos de texto já criados? não: reordene.
	var bg := _rect(Rect2i(0, 0, w, h), PLATE_BG)
	move_child(bg, 0)
	_border(Rect2i(0, 0, w, h), 1, PLATE_BORDER)

	var x := PAD.x
	lbl.position = Vector2(x, PAD.y)
	x += int(lbl.custom_minimum_size.x) + GAP
	val.position = Vector2(x, PAD.y)
	x += int(val.custom_minimum_size.x) + GAP
	_rect(Rect2i(x, PAD.y - 1, 1, 18), Color(0.79, 0.75, 0.66, 0.28))
	x += 1 + GAP
	_build_trail(x, int(h / 2.0))

## Trilha de nós: losangos de 12/15/17px ligados por conectores de 20x2.
## concluído = losango cheio bone (12)
## atual     = losango 15 com borda 2px bone e miolo verde
## boss      = losango 17 com borda 2px vermelha e miolo escuro
func _build_trail(x0: int, cy: int) -> void:
	var x := x0
	for i in range(1, stage_total + 1):
		var is_boss := boss_last and i == stage_total
		# o boss vence na FORMA: 17px e borda vermelha mesmo sendo o stage atual.
		# "atual" nao troca a forma — so acrescenta o glow (aplicado pelo chamador).
		var d := 17 if is_boss else (15 if i == stage else 12)
		var r := Rect2i(x, cy - int(d / 2.0), d, d)
		if is_boss:
			_diamond(r, NODE_BOSS_BG, 2, NODE_BOSS_EDGE)
		elif i < stage:
			_diamond(r, NODE_DONE, 0, NODE_DONE)
		elif i == stage:
			_diamond(r, NODE_CURR, 2, BONE)
		else:
			_diamond(r, Color("1a1a16"), 2, Color(0.79, 0.75, 0.66, 0.45))
		x += d
		if i < stage_total:
			var a := 0.5 if i < stage else 0.28
			_rect(Rect2i(x, cy - 1, 20, 2), Color(0.79, 0.75, 0.66, a))
			x += 20
	if boss_last:
		var boss := _label("BOSS", 16, 2, Color(1, 1, 1, 0.8))
		boss.position = Vector2(x + 8, cy - 8)

func _trail_width() -> int:
	var w := 0
	for i in range(1, stage_total + 1):
		var is_boss := boss_last and i == stage_total
		w += 17 if is_boss else (15 if i == stage else 12)
		if i < stage_total: w += 20
	if boss_last: w += 8 + 4 * 13 - 1 + 2 * 3
	return w

# --------------------------------------------------------------- helpers
## Losango = quadrado rotacionado 45°. `rotation` num Control rotaciona em torno
## do pivô, então centralize o pivô antes.
func _diamond(r: Rect2i, fill: Color, border_w: int, border_c: Color) -> void:
	var holder := Control.new()
	holder.position = Vector2(r.position) + Vector2(r.size) / 2.0
	holder.pivot_offset = Vector2.ZERO
	holder.rotation = deg_to_rad(45)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	var box := ColorRect.new()
	box.color = fill
	box.position = -Vector2(r.size) / 2.0
	box.size = Vector2(r.size)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(box)
	if border_w > 0:
		for e in [Rect2i(0, 0, r.size.x, border_w),
				Rect2i(0, r.size.y - border_w, r.size.x, border_w),
				Rect2i(0, 0, border_w, r.size.y),
				Rect2i(r.size.x - border_w, 0, border_w, r.size.y)]:
			var b := ColorRect.new()
			b.color = border_c
			b.position = -Vector2(r.size) / 2.0 + Vector2(e.position)
			b.size = Vector2(e.size)
			b.mouse_filter = Control.MOUSE_FILTER_IGNORE
			holder.add_child(b)

func _label(txt: String, gh: int, track: int, mod: Color) -> BitmapFontLabel:
	var l := BitmapFontLabel.new()
	l.glyph_height = gh
	l.tracking = track
	l.text = txt
	l.modulate = mod
	add_child(l)
	return l

func _rect(r: Rect2i, c: Color) -> ColorRect:
	var n := ColorRect.new()
	n.color = c
	n.position = r.position
	n.size = r.size
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(n)
	return n

func _border(r: Rect2i, w: int, c: Color) -> void:
	_rect(Rect2i(r.position.x, r.position.y, r.size.x, w), c)
	_rect(Rect2i(r.position.x, r.position.y + r.size.y - w, r.size.x, w), c)
	_rect(Rect2i(r.position.x, r.position.y, w, r.size.y), c)
	_rect(Rect2i(r.position.x + r.size.x - w, r.position.y, w, r.size.y), c)
