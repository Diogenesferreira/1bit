# BattleUI.gd — montagem da tela de batalha 1-bit
#
# Acompanha README_UI.md. Nada aqui desenha nada à mão: tudo é TextureRect
# sobre os PNGs do pacote, em escala inteira. Requer nearest-neighbor:
#   Project Settings → Rendering → Textures → Default Texture Filter = Nearest
#
# Arvore esperada:
#   BattleUI (Control, este script)
#     TopBar/Floor:TextureRect  TopBar/Rounds:HBoxContainer
#     TopBar/Energy/Bolt:ColorRect  TopBar/Energy/Value:TextureRect
#     Stage:Control
#     Formation:HBoxContainer      (5x SealSlot, ver FragmentSeal.gd)
#     Bag/Queue:HBoxContainer      (8x CardView)
#     Bag/Next/Card:CardView
#     Hand:GridContainer           (5 colunas)
#     Footer/HP:TextureRect  Footer/XPFill:ColorRect

extends Control

const UI := "res://art/ui/"
const SEAL := "res://art/frames/"

const ELEMENTS := ["dragon", "knight", "nature", "light", "dark", "heal", "wild"]

const COLOR := {
	"dragon": Color("a8443a"), "knight": Color("5a86a8"), "nature": Color("7d9455"),
	"light": Color("c9a842"),  "dark": Color("7a5f9a"),   "heal": Color("b09a72"),
	"wild": Color("e8e3d4"),
}
const BONE := Color("c9c0a8")
const BONE_HI := Color("e8e3d4")
const INK := Color("201f1d")

# --- escalas legais (README_UI §4) ---------------------------------------
const CARD_SRC := Vector2i(78, 108)
const CARD_BAG := Vector2i(78, 108)     # 1:1
const CARD_HAND := Vector2i(156, 216)   # 2x
const SEAL_SRC := 330
const SEAL_UI := 165                    # 1/2
const DIGIT_CELL := Vector2i(21, 24)    # sheet 210x24

# --- fonte em bitmap ----------------------------------------------------
const GLYPHS := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ/-:"
const GLYPH_CELL := Vector2i(36, 48)

var _font_sheet: Texture2D
var _digit_sheet: Texture2D

# fila da BAG: elementos, da esquerda para a direita. O ultimo item e sempre
# o que aparece no slot NEXT.
var bag_queue: Array[String] = ["wild", "nature", "heal", "knight", "dragon", "dark", "knight", "light"]

var hp: int = 9999
var hp_max: int = 9999
var energy: int = 12
var energy_max: int = 20


func _ready() -> void:
	_font_sheet = load(UI + "ui_font_sheet_v1.png")
	_digit_sheet = load(UI + "enemy_digits_sheet_v1.png")
	refresh_bag()
	refresh_footer()
	refresh_energy()


# =======================================================================
#  Texto em pixel art a partir do sheet
# =======================================================================
# Devolve uma Texture2D com o rotulo desenhado. `scale_div` = 1 (36x48 por
# caractere), 2 (18x24), 3 (12x16) ou 4 (9x12). Nada fora disso.
func make_label(text: String, scale_div: int = 3) -> ImageTexture:
	assert(scale_div in [1, 2, 3, 4], "escala ilegal — ver README_UI §4")
	var src: Image = _font_sheet.get_image()
	var cw := GLYPH_CELL.x / scale_div
	var ch := GLYPH_CELL.y / scale_div
	var out := Image.create(text.length() * cw + cw / 6, ch, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	for i in text.length():
		var k := GLYPHS.find(text[i].to_upper())
		if k < 0:
			continue
		var cell := src.get_region(Rect2i(k * GLYPH_CELL.x, 0, GLYPH_CELL.x, GLYPH_CELL.y))
		if scale_div > 1:
			cell.resize(cw, ch, Image.INTERPOLATE_NEAREST)
		out.blit_rect(cell, Rect2i(0, 0, cw, ch), Vector2i(i * cw, 0))
	return ImageTexture.create_from_image(out)


# Numeral de carta: AtlasTexture sobre enemy_digits_sheet_v1 (celula 21x24).
func digit_atlas(d: int) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = _digit_sheet
	at.region = Rect2i(d * DIGIT_CELL.x, 0, DIGIT_CELL.x, DIGIT_CELL.y)
	return at


# =======================================================================
#  Cartas
# =======================================================================
func card_texture(element: String) -> Texture2D:
	return load(UI + "card_face_%s_v1.png" % element)


# Monta um TextureRect de carta em escala inteira, com o numeral opcional.
func make_card(element: String, size: Vector2i, value: int = -1, highlight := false) -> Control:
	assert(size == CARD_BAG or size == CARD_HAND, "escala de carta ilegal")
	var root := Control.new()
	root.custom_minimum_size = size
	root.size = size

	var face := TextureRect.new()
	face.texture = card_texture(element)
	face.stretch_mode = TextureRect.STRETCH_SCALE
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face.size = size
	root.add_child(face)

	if value >= 0:
		var mult := size.x / CARD_SRC.x          # 1 na BAG, 2 na mao
		var num := TextureRect.new()
		num.texture = digit_atlas(value)
		num.stretch_mode = TextureRect.STRETCH_SCALE
		num.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# meia escala do numeral quando a carta esta 1:1 (README_UI §3.4)
		var ns := Vector2(DIGIT_CELL) * (0.5 if mult == 1 else 1.0)
		num.position = Vector2(6, 6) * mult
		num.size = ns
		root.add_child(num)

	if highlight:
		# realce que NAO altera o tamanho: moldura desenhada por fora
		var f := ReferenceRect.new()
		f.border_color = BONE
		f.border_width = 2.0
		f.editor_only = false
		f.position = Vector2(-2, -2)
		f.size = Vector2(size) + Vector2(4, 4)
		root.add_child(f)
	return root


# =======================================================================
#  BAG — fila + slot NEXT
# =======================================================================
func refresh_bag() -> void:
	var queue: HBoxContainer = get_node("Bag/Queue")
	for c in queue.get_children():
		c.queue_free()
	# a fila mostra todos os itens; o slot NEXT repete o ultimo
	for el in bag_queue:
		queue.add_child(make_card(el, CARD_BAG))
	queue.alignment = BoxContainer.ALIGNMENT_BEGIN
	# distribuicao por toda a largura: space-between
	queue.add_theme_constant_override("separation", 0)
	_spread(queue)

	var slot: Control = get_node("Bag/Next")
	for c in slot.get_children():
		c.queue_free()
	var last: String = bag_queue.back()
	slot.add_child(make_card(last, CARD_BAG, 2, true))


# Espalha os filhos de um HBox pela largura disponivel (equivalente ao
# justify-content:space-between do HTML).
func _spread(box: HBoxContainer) -> void:
	var n := box.get_child_count()
	if n < 2:
		return
	var total_cards := n * CARD_BAG.x
	var gap := int(floor((box.size.x - total_cards) / float(n - 1)))
	box.add_theme_constant_override("separation", max(gap, 4))


# Saca a primeira carta da fila (a da esquerda) e devolve o elemento.
func draw_card() -> String:
	if bag_queue.is_empty():
		return ""
	var el: String = bag_queue.pop_front()
	refresh_bag()
	return el


# Repoe o fim da fila (o slot NEXT acompanha automaticamente).
func push_card(element: String) -> void:
	bag_queue.append(element)
	refresh_bag()


# =======================================================================
#  Rodape e energia
# =======================================================================
func refresh_footer() -> void:
	hp = clamp(hp, 0, 9999)
	hp_max = clamp(hp_max, 1, 9999)
	var t: TextureRect = get_node("Footer/HP")
	t.texture = make_label("%d/%d" % [hp, hp_max], 2)
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func set_hp(v: int, animate := true) -> void:
	var target := clamp(v, 0, hp_max)
	if not animate:
		hp = target
		refresh_footer()
		return
	# dreno de 420 ms, ease-out (README_UI §5)
	var tw := create_tween()
	tw.tween_method(func(x): hp = int(round(x)); refresh_footer(), float(hp), float(target), 0.42) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func refresh_energy() -> void:
	var t: TextureRect = get_node("TopBar/Energy/Value")
	t.texture = make_label("%d/%d" % [energy, energy_max], 2)
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	get_node("TopBar/Energy/Bolt").color = COLOR["light"]


func set_energy(v: int) -> void:
	energy = clamp(v, 0, energy_max)
	var tw := create_tween()
	tw.tween_callback(refresh_energy).set_delay(0.2)   # 200 ms, ease-out


# =======================================================================
#  Selecao de carta na mao
# =======================================================================
# Sobe 9 px e aplica realce de 2 px na cor do elemento, em 120 ms.
func select_card(card: Control, element: String, selected: bool) -> void:
	var tw := create_tween()
	tw.tween_property(card, "position:y", card.position.y + (-9 if selected else 9), 0.12) \
		.set_ease(Tween.EASE_OUT)
	var rim: ReferenceRect = card.get_node_or_null("Rim")
	if rim == null and selected:
		rim = ReferenceRect.new()
		rim.name = "Rim"
		rim.editor_only = false
		rim.border_width = 2.0
		rim.position = Vector2(-2, -2)
		rim.size = card.size + Vector2(4, 4)
		card.add_child(rim)
	if rim:
		rim.border_color = COLOR[element]
		rim.visible = selected


# Carta gasta: brilho 35% e dessaturada.
func mark_spent(card: Control) -> void:
	card.modulate = Color(0.35, 0.35, 0.35, 1.0)
