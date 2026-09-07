## Barra superior da conta — modelo de 02/09/2026.
## Contrato em `spec/TOP_BAR.md`. Regras que valem aqui:
##   1. Todo valor numérico mora numa caixa de LARGURA RESERVADA e é ancorado à
##      DIREITA. O layout nunca desloca quando o número cresce.
##   2. Nenhum PNG de texto. Tudo via BitmapFontLabel na folha 1:1.
##   3. Ícones normalizados numa célula de 20x20, centralizados.
class_name TopBar
extends Control

const ART := "res://art/"
const ROW_H := 72
const EMBLEM := 68
const GAP := 16
const ICON_CELL := 20
const GLYPH := Vector2i(12, 16)      # célula da folha 1:1
const TRACK := 1                     # tracking entre glifos

## Largura reservada por contador = max_digitos * 13 - 1
const BOX_COIN := 90                 # 7 dígitos
const BOX_GEM := 64                  # 5 dígitos
const BOX_ENERGY := 90               # "999/999"
const BOX_LV := 38                   # 3 dígitos
const BOX_XP := 51                   # 4 dígitos

const BONE := Color("c9c0a8")
const PLATE_BG := Color("121211")
const ENERGY_BG := Color("141512")
const BORDER_SOFT := Color(0.79, 0.75, 0.66, 0.32)
const BORDER_HARD := Color(0.79, 0.75, 0.66, 0.55)
const GOLD := Color("c9a842")
const PURPLE := Color("7a5f9a")

@export var account_name: String = "VAELDRIN"
@export_range(1, 999) var account_level: int = 24
@export var xp_current: int = 1360
@export_range(0.0, 1.0) var xp_ratio: float = 0.62
@export var coins: int = 1240
@export var gems: int = 36
@export var energy: int = 12
@export var energy_max: int = 20
@export var row_width: int = 468

var _lv: BitmapFontLabel
var _xp_val: BitmapFontLabel
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
	# ---- emblema da conta (68x68, borda 2px + pips de canto de 9px) ----
	var ey := int((ROW_H - EMBLEM) / 2.0)
	_rect(self, Rect2i(0, ey, EMBLEM, EMBLEM), ENERGY_BG)
	_border(self, Rect2i(0, ey, EMBLEM, EMBLEM), 2, Color(0.79, 0.75, 0.66, 0.6))
	var slot := Rect2i(3, ey + 3, EMBLEM - 6, EMBLEM - 6)
	_rect(self, slot, Color("0b0d0a"))
	# o slot fica vazio: instancie aqui o TextureRect com a foto/emblema da conta,
	# em (3, ey+3) 62x62, texture_filter NEAREST. Nada de escala fracionária.
	_rect(self, Rect2i(-2, ey - 2, 9, 9), BONE)
	_rect(self, Rect2i(EMBLEM - 7, ey + EMBLEM - 7, 9, 9), BONE)

	# ---- coluna nome/LV + XP ----
	var col_x := EMBLEM + GAP
	var name_lbl := _label(account_name, 17, 2)
	name_lbl.position = Vector2(col_x, 20)
	var name_w := int(name_lbl.custom_minimum_size.x)

	# chip de LV: mesma borda e mesmo fundo dos contadores
	var chip_x := col_x + name_w + 12
	var chip_w := 7 + 24 + 6 + BOX_LV + 7
	_rect(self, Rect2i(chip_x, 19, chip_w, 22), PLATE_BG)
	_border(self, Rect2i(chip_x, 19, chip_w, 22), 1, BORDER_SOFT)
	var lv_lbl := _label("LV", 16, TRACK)
	lv_lbl.modulate = Color(1, 1, 1, 0.55)
	lv_lbl.position = Vector2(chip_x + 7, 22)
	_lv = _label("", 16, TRACK)
	_lv.position = Vector2(chip_x + 7 + 24 + 6, 22)

	# linha do XP
	var xp_lbl := _label("XP", 16, TRACK)
	xp_lbl.modulate = Color(1, 1, 1, 0.55)
	xp_lbl.position = Vector2(col_x, 47)
	var well := Rect2i(col_x + 25 + 9, 47, 214, 13)
	_rect(self, well, Color("121211"))
	_border(self, well, 1, Color(0.79, 0.75, 0.66, 0.5))
	_xp_fill = _rect(self, Rect2i(well.position.x + 2, well.position.y + 2, 0, 9), BONE)
	_xp_val = _label("", 16, TRACK)
	_xp_val.modulate = Color(1, 1, 1, 0.8)
	_xp_val.position = Vector2(well.position.x + well.size.x + 9, 47)

	# ---- rack da carteira (moeda | gema) ancorado à DIREITA da linha ----
	var energy_w := 10 + ICON_CELL + 7 + BOX_ENERGY + 10
	var coin_w := 10 + ICON_CELL + 7 + BOX_COIN + 10
	var gem_w := 10 + ICON_CELL + 7 + BOX_GEM + 10
	var menu_w := 34 + 4
	var energy_x := row_width - menu_w - 12 - energy_w
	var rack_x := energy_x - 12 - (coin_w + 1 + gem_w)
	var ry := int((ROW_H - 30) / 2.0)

	_rect(self, Rect2i(rack_x, ry, coin_w + 1 + gem_w, 30), PLATE_BG)
	_border(self, Rect2i(rack_x, ry, coin_w + 1 + gem_w, 30), 1, BORDER_SOFT)
	_rect(self, Rect2i(rack_x + coin_w, ry, 1, 30), Color(0.79, 0.75, 0.66, 0.25))
	_coin = _counter(rack_x, ry, "ui/icon_coin.png", BOX_COIN)
	_gem = _counter(rack_x + coin_w + 1, ry, "ui/icon_gem.png", BOX_GEM)

	# ---- plate da energia: borda mais forte, separado por espaço ----
	_rect(self, Rect2i(energy_x, ry, energy_w, 30), ENERGY_BG)
	_border(self, Rect2i(energy_x, ry, energy_w, 30), 1, BORDER_HARD)
	_energy = _counter(energy_x, ry, "ui/icon_energy.png", BOX_ENERGY)

	# ---- menu (três traços de 34x5, passo 11) ----
	for i in 3:
		_rect(self, Rect2i(row_width - 34, int(ROW_H / 2.0) - 13 + i * 11, 34, 5), BONE)

	refresh()

## Uma célula de contador: ícone 20x20 + valor de largura reservada, à direita.
func _counter(x: int, y: int, icon: String, box: int) -> BitmapFontLabel:
	_tex(self, ART + icon, Rect2i(x + 10, y + 5, ICON_CELL, ICON_CELL))
	var lbl := _label("", 16, TRACK)
	lbl.position = Vector2(x + 10 + ICON_CELL + 7, y + 7)
	lbl.align_right_in = box            # ver BitmapFontLabel.align_right_in
	return lbl

# ------------------------------------------------------------------ API
func refresh() -> void:
	_lv.text = str(clampi(account_level, 1, 999))
	_coin.text = str(coins)
	_gem.text = str(gems)
	_energy.text = "%d/%d" % [energy, energy_max]
	_xp_val.text = str(xp_current)
	_xp_fill.size.x = int(round(210 * clampf(xp_ratio, 0.0, 1.0)))

func set_coins(v: int) -> void: coins = v; _coin.text = str(v)
func set_gems(v: int) -> void: gems = v; _gem.text = str(v)
func set_energy(v: int, m: int) -> void:
	energy = v; energy_max = m
	_energy.text = "%d/%d" % [v, m]

## XP sobe em 200 ms, ease-out (contador do contrato).
func xp_to(ratio: float, value: int) -> void:
	xp_ratio = clampf(ratio, 0.0, 1.0)
	xp_current = value
	var t := create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_xp_fill, "size:x", 210 * xp_ratio, 0.20)
	_xp_val.text = str(value)

# --------------------------------------------------------------- helpers
func _label(txt: String, gh: int, track: int) -> BitmapFontLabel:
	var l := BitmapFontLabel.new()
	l.glyph_height = gh
	l.tracking = track
	l.text = txt
	add_child(l)
	return l

func _rect(parent: Node, r: Rect2i, c: Color) -> ColorRect:
	var n := ColorRect.new()
	n.color = c
	n.position = r.position
	n.size = r.size
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(n)
	return n

func _border(parent: Node, r: Rect2i, w: int, c: Color) -> void:
	_rect(parent, Rect2i(r.position.x, r.position.y, r.size.x, w), c)
	_rect(parent, Rect2i(r.position.x, r.position.y + r.size.y - w, r.size.x, w), c)
	_rect(parent, Rect2i(r.position.x, r.position.y, w, r.size.y), c)
	_rect(parent, Rect2i(r.position.x + r.size.x - w, r.position.y, w, r.size.y), c)

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
