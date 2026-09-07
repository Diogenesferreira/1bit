## Monta a tela de batalha inteira em px de design (viewport base 940x1685).
## Rode uma vez, depois "Save Branch as Scene" para congelar como BattleScreen.tscn.
## Todas as medidas vem de battle_layout.gd — nao invente numeros aqui.
extends Control

const L := preload("res://scripts/battle_layout.gd")
const ART := "res://art/"

@export var formation: int = 3          # 1 (boss) / 2 / 3 / 5
@export var party := ["dragon", "knight", "nature", "light", "dark"]
@export var active_slot: int = 2
@export var bag := ["wild", "nature", "heal", "knight", "dragon", "dark", "knight", "light"]
@export var hand := ["dragon", "knight", "nature", "light", "dark", "heal", "knight", "wild", "nature", ""]
@export var hand_values := [2, 5, 4, 1, 7, 5, 2, 8, 3, 0]

var stage: Control
var enemies: Array[EnemyPlate] = []
var seals: Array[PartySeal] = []

func _ready() -> void:
	custom_minimum_size = L.DESIGN
	size = L.DESIGN
	_panel()
	_header()
	_stage()
	_rule(L.SEC.party_rule.y, "lbl_party")
	_party()
	_bag()
	_rule(L.SEC.hand_rule.y, "lbl_hand")
	_hand()
	_footer()

# ---------------------------------------------------------------- helpers
func _rect(parent: Node, r: Rect2i, c: Color) -> ColorRect:
	var n := ColorRect.new(); n.color = c; n.position = r.position; n.size = r.size
	parent.add_child(n); return n

func _pic(parent: Node, path: String, pos: Vector2i, sz: Vector2i) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(ART + path)
	t.position = pos; t.size = sz
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(t); return t

func _label(parent: Node, txt: String, pos: Vector2i, h: int, tint := L.C_BONE) -> BitmapFontLabel:
	var n := BitmapFontLabel.new()
	n.glyph_height = h; n.tint = tint; n.text = txt; n.position = pos
	parent.add_child(n); return n

# ---------------------------------------------------------------- chrome
func _panel() -> void:
	_rect(self, Rect2i(0, 0, L.DESIGN.x, L.DESIGN.y), L.C_WINDOW)
	_rect(self, Rect2i(0, 0, L.DESIGN.x, L.DESIGN.y), L.C_PANEL).size = L.DESIGN
	# bordas: 2px #2b2b28 externa + 1px bone .30 interna (use NinePatchRect ou 4 ColorRect)

# ---------------------------------------------------------------- 1. conta
func _header() -> void:
	var y: int = L.SEC.header.y
	var av := _rect(self, Rect2i(L.CONTENT_X, y + 3, 58, 58), Color("141512"))
	_rect(av, Rect2i(3, 3, 52, 52), L.C_SLOT_BG)                 # foto entra aqui
	_rect(av, Rect2i(-2, -2, 8, 8), L.C_BONE)
	_rect(av, Rect2i(52, 52, 8, 8), L.C_BONE)

	var x := L.CONTENT_X + 58 + 16
	_label(self, "VAELDRIN", Vector2i(x, y + 6), 17)
	_label(self, "LV", Vector2i(x + 190, y + 8), 11, L.C_BONE_DIM)
	_label(self, "24", Vector2i(x + 216, y + 7), 12)

	var by := y + 36
	_label(self, "XP", Vector2i(x, by + 1), 11, L.C_BONE_DIM)
	var well := _rect(self, Rect2i(x + 30, by, 214, 13), L.C_WELL)
	_rect(well, Rect2i(2, 2, int(210 * 0.62), 9), L.C_BONE)       # fill 62%
	_label(self, "1360", Vector2i(x + 254, by + 1), 11, L.C_BONE_DIM)

	# direita: moeda (reserva 82) / gema (68) / energia (86) / menu
	var rx := L.CONTENT_X + L.CONTENT_W
	_menu(rx - 34, y + 22)
	_counter("12/20", rx - 34 - 16 - 86, y + 20, L.C_GOLD, 16)
	_counter("36",    rx - 34 - 16 - 86 - 16 - 68, y + 22, L.C_GEM, 14)
	_counter("1240",  rx - 34 - 16 - 86 - 16 - 68 - 16 - 82, y + 22, L.C_GOLD, 14)

func _counter(txt: String, x: int, y: int, tint: Color, h: int) -> void:
	_label(self, txt, Vector2i(x + 24, y), h, L.C_BONE)           # icone: 17x17/15x18/16x26 antes

func _menu(x: int, y: int) -> void:
	for i in 3:
		_rect(self, Rect2i(x, y + i * 11, 34, 5), L.C_BONE)

# ---------------------------------------------------------------- 2. palco
func _stage() -> void:
	var s: Dictionary = L.SEC.stage
	stage = Control.new()
	stage.position = Vector2i(L.CONTENT_X, s.y)
	stage.size = Vector2i(L.CONTENT_W, s.h)
	stage.clip_contents = true
	add_child(stage)
	_rect(stage, Rect2i(0, 0, L.CONTENT_W, s.h), L.C_FIELD)
	# backdrop: TextureRect em cover ocupando 888x558

	_stage_progress()
	spawn_formation(formation)

func _stage_progress() -> void:
	var box := Control.new()
	box.position = Vector2i(22, L.SEC.stage.h - 20 - 35)
	stage.add_child(box)
	_rect(box, Rect2i(0, 0, 270, 35), Color(0.031, 0.035, 0.031, 0.72))
	_label(box, "STAGE", Vector2i(12, 12), 11, L.C_BONE_DIM)
	_label(box, "2/3", Vector2i(78, 11), 12)
	# 3 nos: feito 12x12 bone / atual 15x15 #7d9455 borda bone / boss 17x17 #2a1512 borda #c04a3e
	_label(box, "BOSS", Vector2i(222, 13), 10)

## Troca a formacao: 1 (boss) / 2 / 3 / 5.
func spawn_formation(n: int) -> void:
	for e in enemies: e.queue_free()
	enemies.clear()
	var conf: Dictionary = L.FORMATIONS[n]
	var k: int = conf.k
	var ps := L.plate_size(k)
	for i in conf.list.size():
		var slot: Dictionary = conf.list[i]
		var holder := Control.new()
		holder.position = Vector2i(clampi(slot.cx - ps.x / 2, 8, L.STAGE_SIZE.x - ps.x - 8), slot.y)
		stage.add_child(holder)
		var plate := EnemyPlate.new()
		plate.k = k
		plate.element = ["nature", "dark", "knight", "light", "dragon"][i % 5]
		plate.turn = 1 + i % 3
		holder.add_child(plate)
		enemies.append(plate)
		var sprite := TextureRect.new()                          # arte do inimigo
		sprite.position = Vector2i((ps.x - conf.sprite) / 2, ps.y + L.PLATE_SPRITE_GAP)
		sprite.size = Vector2i(conf.sprite, conf.sprite)
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		holder.add_child(sprite)

# ---------------------------------------------------------------- 3/5. reguas
func _rule(y: int, label_asset: String) -> void:
	_pic(self, "ui/%s.png" % label_asset, Vector2i(L.CONTENT_X, y), Vector2i(150, 18))
	_rect(self, Rect2i(L.CONTENT_X + 162, y + 9, L.CONTENT_W - 200, 1), Color(0.79, 0.75, 0.66, 0.28))

# ---------------------------------------------------------------- 4. party
func _party() -> void:
	var y: int = L.SEC.party.y
	_rect(self, Rect2i(L.CONTENT_X, y, L.CONTENT_W, L.SEC.party.h), L.C_STRIP)
	var total := 5 * L.SEAL_DISPLAY + 4 * 8
	var x := L.CONTENT_X + (L.CONTENT_W - total) / 2
	for i in 5:
		var s := PartySeal.new()
		s.element = party[i]
		s.charge = [3, 5, 8, 2, 6][i]
		s.active = (i == active_slot)
		s.position = Vector2i(x + i * (L.SEAL_DISPLAY + 8), y + 25 - (16 if i == active_slot else 0))
		add_child(s)
		seals.append(s)

# ---------------------------------------------------------------- 5. bag
func _bag() -> void:
	var y: int = L.SEC.bag.y
	_rect(self, Rect2i(L.CONTENT_X, y, L.CONTENT_W, L.SEC.bag.h), L.C_FIELD)
	_pic(self, "ui/lbl_bag.png", Vector2i(L.CONTENT_X + 12, y - 9), Vector2i(120, 16))
	var queue_w := 600
	var step := (queue_w - L.CARD_BAG.x) / 7
	for i in bag.size():
		_card(Vector2i(L.CONTENT_X + 16 + i * step, y + 30), bag[i], L.CARD_BAG, -1)
	# divisor + seta + NEXT (mesma carta 78x108, sem moldura extra)
	_pic(self, "ui/lbl_next.png", Vector2i(L.CONTENT_X + 760, y + 14), Vector2i(56, 14))
	_card(Vector2i(L.CONTENT_X + 748, y + 32), bag.back(), L.CARD_BAG, -1)

# ---------------------------------------------------------------- 7. mao
func _hand() -> void:
	var y: int = L.SEC.hand.y
	var total := L.HAND_COLS * L.CARD_HAND.x + (L.HAND_COLS - 1) * L.HAND_GAP
	var x0 := L.CONTENT_X + (L.CONTENT_W - total) / 2
	for i in hand.size():
		var col := i % L.HAND_COLS
		var row := i / L.HAND_COLS
		var at := Vector2i(x0 + col * (L.CARD_HAND.x + L.HAND_GAP), y + row * (L.CARD_HAND.y + L.HAND_GAP))
		if hand[i] == "":
			_rect(self, Rect2i(at.x, at.y, L.CARD_HAND.x, L.CARD_HAND.y), Color(0, 0, 0, 0))
		else:
			_card(at, hand[i], L.CARD_HAND, hand_values[i])

func _card(pos: Vector2i, element: String, sz: Vector2i, value: int) -> Control:
	var holder := Control.new()
	holder.position = pos; holder.size = sz
	add_child(holder)
	var v := "v3" if element in ["light", "dark", "wild"] else "v1"
	_pic(holder, "ui/card_face_%s_%s.png" % [element, v], Vector2i.ZERO, sz)
	if value >= 0:
		var scale_f := sz.x / float(L.CARD_BAG.x)
		var at := AtlasTexture.new()
		at.atlas = load(ART + "enemy/enemy_digits_sheet_v1.png")
		at.region = Rect2(value * 42, 0, 42, 48)
		var d := TextureRect.new()
		d.texture = at
		d.position = Vector2i(int(7 * scale_f), int(7 * scale_f))
		d.size = Vector2i(int(10.5 * scale_f), int(12 * scale_f))
		d.stretch_mode = TextureRect.STRETCH_SCALE
		d.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		holder.add_child(d)
	return holder

# ---------------------------------------------------------------- 8. life
func _footer() -> void:
	var y: int = L.SEC.footer.y
	# coracao 28x26 (Polygon2D ou sprite) em C_HP na esquerda
	_label(self, "HP", Vector2i(L.CONTENT_X + 42, y + 14), 12, L.C_BONE_DIM)
	var bar_x := L.CONTENT_X + 80
	var bar_w := L.CONTENT_W - 80 - 120
	var well := _rect(self, Rect2i(bar_x, y + 9, bar_w, 22), L.C_WELL)
	_rect(well, Rect2i(3, 3, int((bar_w - 6) * 0.76), 16), L.C_HP)     # vermelho solido
	_label(self, "1840/2400", Vector2i(bar_x + bar_w + 14, y + 13), 15)
