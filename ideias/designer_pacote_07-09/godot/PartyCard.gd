## Carta de personagem da faixa do party — v2 (02/09/2026, alinhamento corrigido)
##
## LEIA `spec/POSICIONAMENTO.md` ANTES DE MEXER. As três regras que causaram o
## desalinhamento na primeira integração:
##   1. Tudo que é visual mora DENTRO de `_frame` (Control com clip_contents),
##      em coordenadas locais do frame — não em coordenadas do card.
##   2. O herói é ancorado pelos PÉS (baseline), nunca pelo topo.
##   3. Os tamanhos de desenho são TABELADOS (CHAR_DRAW), não calculados por
##      multiplicador — o lógico de cada sprite não é o mesmo.
class_name PartyCard
extends Control

const ART := "res://art/"
const CARD := Vector2i(152, 188)
const INSET := 2                  # espessura do contorno externo
const FRAME := Vector2i(148, 184) # CARD - 2*INSET
const ART_BASELINE := 136         # y, em espaço do FRAME, onde ficam os pés
const SCENE := Vector2i(150, 138)
const FIELD_CELL := 24

const EL_COLOR := {
	"dragon": Color("a8443a"), "knight": Color("5a86a8"), "nature": Color("7d9455"),
	"light": Color("c9a842"), "dark": Color("7a5f9a"), "heal": Color("b09a72"),
}
const EL_LIGHT := {
	"dragon": Color("d9705f"), "knight": Color("8ab6d4"), "nature": Color("a8c07a"),
	"light": Color("f0d478"), "dark": Color("a37fd0"), "heal": Color("d0bb92"),
}
const GOLD := Color("c9a842")

## Tamanho de desenho do sprite, em px lógicos. Copiado 1:1 do HTML de referência.
## NÃO derive isto de um multiplicador: cada arte tem lógico próprio.
const CHAR_DRAW := {
	"dragon": Vector2i(114, 108), "knight": Vector2i(88, 116), "nature": Vector2i(112, 108),
	"light": Vector2i(108, 112), "dark": Vector2i(104, 108), "heal": Vector2i(96, 108),
}

signal skill_activated(element: String)

@export var element: String = "dragon"
@export var hero_name: String = "IGNAR"
@export_range(0, 99) var level: int = 1
@export_range(0, 8) var charge: int = 0
@export var leader: bool = false
@export var guest: bool = false

var _frame: Control
var _pips: Array[ColorRect] = []
var _name_label: BitmapFontLabel
var _level_digits: Control

func _ready() -> void:
	# tamanho FIXO e igual para os cinco slots
	custom_minimum_size = CARD
	size = CARD
	set_anchors_preset(Control.PRESET_TOP_LEFT)   # nunca deixe um preset esticar o card
	_build()

func _build() -> void:
	var ring: Color = EL_COLOR[element]   # o anel segue SEMPRE o elemento

	_rect(self, Rect2i(Vector2i.ZERO, CARD), Color("0d0e0c"))
	_border(self, Rect2i(Vector2i.ZERO, CARD), INSET, Color("14140f"))

	# ---- frame: a única coisa que clipa. Pai de todo o conteúdo interno. ----
	_frame = Control.new()
	_frame.position = Vector2(INSET, INSET)
	_frame.size = FRAME
	_frame.custom_minimum_size = FRAME
	_frame.clip_contents = true            # <-- sem isto o herói vaza pra fora do card
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)

	# fundo em tile, cobrindo o frame inteiro
	var field := _tex(_frame, ART + "card_party/field_%s.png" % element, Rect2i(Vector2i.ZERO, FRAME))
	field.stretch_mode = TextureRect.STRETCH_TILE

	# cena: 150x138 no topo, centralizada (sobra 1px de cada lado, o clip resolve)
	_tex(_frame, ART + "card_party/scene_%s.png" % element,
		Rect2i(int(round((FRAME.x - SCENE.x) / 2.0)), 0, SCENE.x, SCENE.y))

	# ---- herói: ancorado pelos PÉS na baseline, centralizado no eixo x ----
	var draw: Vector2i = CHAR_DRAW.get(element, Vector2i(104, 108))
	_tex(_frame, ART + "char80/char_%s.png" % element, Rect2i(
		int(round((FRAME.x - draw.x) / 2.0)), ART_BASELINE - draw.y, draw.x, draw.y))

	# anel interno por cima de tudo que está no frame
	_border(_frame, Rect2i(Vector2i.ZERO, FRAME), 2, ring)

	# ---- fora do frame (sangram ou ficam por cima): filhos do CARD ----
	_rect(self, Rect2i(-3, -3, 30, 30), Color("0d0e0c"))
	_border(self, Rect2i(-3, -3, 30, 30), 2, ring)
	_tex(self, ART + "card_party/sym_%s.png" % element, Rect2i(-1, -1, 26, 26))

	_build_skill_bar(ring)
	_build_name_plate(ring)
	if leader: _build_leader_plaque()
	if guest:
		var d := _rect(self, Rect2i(CARD.x - 16, 6, 10, 10), ring)
		d.rotation = deg_to_rad(45)

	set_charge(charge)
	set_level(level)
	set_hero_name(hero_name)

func _build_skill_bar(ring: Color) -> void:
	var bar := Rect2i(9, CARD.y - 41, CARD.x - 18, 10)   # bottom 31, altura 10
	_rect(self, bar, Color("121211"))
	_border(self, bar, 1, ring if leader else Color(0.79, 0.75, 0.66, 0.45))
	var seg := 16   # 8 pastilhas de 14 + gap 2 = 128 = bar.w - 6
	for i in 8:
		var pip := ColorRect.new()
		pip.position = Vector2(bar.position.x + 2 + i * seg, bar.position.y + 2)
		pip.size = Vector2(14, 6)
		add_child(pip)
		_pips.append(pip)

func _build_name_plate(ring: Color) -> void:
	var plate := Rect2i(2, CARD.y - 26, CARD.x - 4, 24)
	_rect(self, plate, Color("0d0e0c"))
	_rect(self, Rect2i(plate.position.x, plate.position.y, plate.size.x, 1), ring)  # filete

	_level_digits = Control.new()
	_level_digits.position = Vector2(plate.position.x + 6, plate.position.y + 3)
	add_child(_level_digits)

	_name_label = BitmapFontLabel.new()
	_name_label.glyph_height = 16
	_name_label.tracking = 1
	_name_label.position = Vector2(plate.position.x + 43, plate.position.y + 4)
	add_child(_name_label)

## Marca de lider: losango de 14 px no canto sup-direito. NAO existe mais
## placa "LEADER" nem coroa — ver spec/CONTRADICOES.md item 1.
func _build_leader_plaque() -> void:
	var mark := ColorRect.new()
	mark.color = GOLD
	mark.size = Vector2(14, 14)
	mark.position = Vector2(-4, -4)
	mark.pivot_offset = Vector2(7, 7)
	mark.rotation = deg_to_rad(45)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mark)

## Faixa de carga + botao de skill, so quando a barra enche (carga = 8).
func _build_skill_ready(el_lit: Color) -> void:
	var strip := _rect(self, Rect2i(2, 145, 148, 2), el_lit)
	strip.name = "charge_strip"
	var btn := Button.new()
	btn.flat = true
	btn.position = Vector2(125, 122)
	btn.size = Vector2(22, 22)
	btn.tooltip_text = "Ativar skill"
	btn.pressed.connect(func(): skill_activated.emit(element))
	add_child(btn)
	_rect(btn, Rect2i(0, 0, 22, 22), Color("0d0e0c"))
	_border(btn, Rect2i(0, 0, 22, 22), 2, el_lit)
	var glyph := _rect(btn, Rect2i(6, 6, 9, 9), el_lit)
	glyph.pivot_offset = Vector2(4.5, 4.5)
	glyph.rotation = deg_to_rad(45)

# ------------------------------------------------------------------ API
func set_charge(n: int) -> void:
	charge = clampi(n, 0, 8)
	for i in _pips.size():
		_pips[i].color = EL_LIGHT[element] if i < charge else Color("1a1a16")

## Anima uma pastilha por vez (200 ms cada) — animação 6 do contrato.
func charge_to(target: int) -> void:
	var t := create_tween()
	for step in range(charge + 1, clampi(target, 0, 8) + 1):
		t.tween_callback(set_charge.bind(step))
		t.tween_interval(0.20)

func set_level(n: int) -> void:
	level = clampi(n, 0, 99)
	for c in _level_digits.get_children(): c.queue_free()
	var txt := str(level)
	var cw := 12
	var chip := ColorRect.new()
	chip.color = EL_COLOR[element]
	chip.size = Vector2(maxf(30.0, txt.length() * cw + 8), 18)
	_level_digits.add_child(chip)
	var x := chip.size.x - 4 - txt.length() * cw
	for ch in txt:
		var at := AtlasTexture.new()
		at.atlas = load(ART + "ui/digits_1x_v1.png")   # folha 1:1 (120x14), célula 12x14
		at.region = Rect2(int(ch) * 12, 0, 12, 14)
		var d := TextureRect.new()
		d.texture = at
		d.position = Vector2(x, 2)
		d.size = Vector2(cw, 14)
		d.stretch_mode = TextureRect.STRETCH_SCALE
		d.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_level_digits.add_child(d)
		x += cw

func set_hero_name(v: String) -> void:
	hero_name = v.to_upper()
	if _name_label: _name_label.text = hero_name

func set_element(v: String) -> void:
	element = v
	for c in get_children(): c.queue_free()
	_pips.clear()
	_build()

# --------------------------------------------------------------- helpers
## Todos os helpers recebem o PAI explicitamente — a origem de cada rect é
## sempre o canto superior esquerdo desse pai. Nunca misture os dois espaços.
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
