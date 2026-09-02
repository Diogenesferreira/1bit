extends RefCounted
class_name Arte

# Ponte unica entre o codigo e o pacote de arte do handoff
# (ideias/godot_handoff_battle_screen/, copiado para res://assets/battle/).
#
# Tudo que e nome de arquivo, tamanho nativo de icone, cor da paleta ou
# fonte passa por aqui - nenhum outro script cita caminho de asset.

const PASTA := "res://assets/battle/"
const UI_FINAL := "ui_v10/"
const PARTY_FINAL := "ui_v11/"
const MOLDURA_SELO_FRAGMENTO := "ui_v5/fragment_seal_frame_master_v1.png"
const SELO_V6_EMPTY := {
	"dragon": "ui_v10/seals_1a/seal_1a_dragon_empty.png",
	"knight": "ui_v10/seals_1a/seal_1a_knight_empty.png",
	"nature": "ui_v10/seals_1a/seal_1a_nature_empty.png",
	"light": "ui_v10/seals_1a/seal_1a_light_empty.png",
	"dark": "ui_v10/seals_1a/seal_1a_dark_empty.png",
}
const SELO_V6_CHARGE := {
	"dragon": "ui_v10/seals_1a/seal_1a_dragon_charge_sheet.png",
	"knight": "ui_v10/seals_1a/seal_1a_knight_charge_sheet.png",
	"nature": "ui_v10/seals_1a/seal_1a_nature_charge_sheet.png",
	"light": "ui_v10/seals_1a/seal_1a_light_charge_sheet.png",
	"dark": "ui_v10/seals_1a/seal_1a_dark_charge_sheet.png",
}
const HUD_INIMIGO_V6_PLATE := {
	"dragon": "ui_v10/enemy/enemy_turn_plate_dragon_v1.png",
	"knight": "ui_v10/enemy/enemy_turn_plate_knight_v1.png",
	"nature": "ui_v10/enemy/enemy_turn_plate_nature_v1.png",
	"light": "ui_v10/enemy/enemy_turn_plate_light_v1.png",
	"dark": "ui_v10/enemy/enemy_turn_plate_dark_v1.png",
}

# Paleta 1-bit (scene_data.json / palette): so dois tons.
const ESCURO := Color("0d0e0c")
const BRANCO := Color("c9c0a8")
const TEXTO_NO_CLARO := Color("1a1a1a")   # sobre o chao da arena
const TEXTO_NO_ESCURO := Color("ffffff")  # sobre o fundo do HUD

# A interface continua essencialmente 1-bit. Estas cores aparecem apenas
# como acentos nos glifos, na selecao, na fusao e no rastro de energia.
const CORES_ELEMENTAIS := {
	"dragon": Color("a8443a"),
	"knight": Color("5a86a8"),
	"nature": Color("7d9455"),
	"light": Color("c9a842"),
	"dark": Color("7a5f9a"),
	"capsule": Color("b09a72"),
	"wild": Color("e8e3d4"),
}
const CORES_ELEMENTAIS_CLARAS := {
	"dragon": Color("d9705f"),
	"knight": Color("8ab6d4"),
	"nature": Color("a8c07a"),
	"light": Color("f0d478"),
	"dark": Color("a37fd0"),
	"heal": Color("d0bb92"),
}
const PARTY_SYMBOL_BOUNDS := {
	"dragon": Rect2(18, 9, 27, 42),
	"knight": Rect2(15, 9, 33, 45),
	"nature": Rect2(15, 9, 33, 36),
	"light": Rect2(3, 3, 54, 54),
	"dark": Rect2(3, 0, 54, 60),
}

const CARD_FACE_FINAL := {
	"dragon": "ui_v10/ui/card_face_dragon_v1.png",
	"knight": "ui_v10/ui/card_face_knight_v1.png",
	"nature": "ui_v10/ui/card_face_nature_v1.png",
	"light": "ui_v10/ui/card_face_light_v3.png",
	"dark": "ui_v10/ui/card_face_dark_v3.png",
	"capsule": "ui_v10/ui/card_face_heal_v1.png",
	"wild": "ui_v10/ui/card_face_wild_v3.png",
}

# Os 5 elementos de unidade.
const ELEMENTOS := ["dragon", "knight", "nature", "light", "dark"]

# O que pode sair do saco. Alem dos 5 elementos, o handoff tem
# "capsule" e "wild" como icones - eles aparecem na fila inicial mas o
# sorteio de reposicao so devolve elemento (igual ao prototipo).
const TIPOS_DE_CARTA := ["dragon", "nature", "light", "dark", "knight", "capsule", "wild"]
const TIPOS_SORTEADOS := ["dragon", "nature", "light", "dark", "knight"]

# Tamanho nativo de cada icone de carta. O prototipo escala pelo LADO
# MAIOR para caber na casa, entao a proporcao precisa ser exata.
const ICONE_NATIVO := {
	"dragon": Vector2(111, 99),
	"capsule": Vector2(97, 97),
	"nature": Vector2(92, 102),
	"light": Vector2(104, 105),
	"dark": Vector2(110, 103),
	"wild": Vector2(107, 100),
	"knight": Vector2(99, 104),
}

# Os emblemas pequenos de afinidade continuam usando o pacote original.
# As cartas ganham uma colecao propria, com silhuetas maiores, reticula e
# pontilhado pensados para leitura no celular.
const ICONE_CARTA_ALPHA := {
	"dragon": "card_icons_alpha/card_icon_dragon_v2.png",
	"capsule": "card_icons_alpha/card_icon_capsule_v2.png",
	"nature": "card_icons_alpha/card_icon_nature_v2.png",
	"light": "card_icons_alpha/card_icon_light_v2.png",
	"dark": "card_icons_alpha/card_icon_dark_v2.png",
	"wild": "card_icons_alpha/card_icon_wild_v2.png",
	"knight": "card_icons_alpha/card_icon_knight_v2.png",
}

# Molduras raster canonicas dos Selos de Fragmento. Todas compartilham a
# mesma geometria 330x330; somente a tinta elemental muda. O personagem e
# renderizado atras do PNG e a carga dinamica por cima.
const SELO_FRAGMENTO := {
	"dragon": "ui_v3/fragment_seal_dragon_v1.png",
	"knight": "ui_v3/fragment_seal_knight_v1.png",
	"nature": "ui_v3/fragment_seal_nature_v1.png",
	"light": "ui_v3/fragment_seal_light_v1.png",
	"dark": "ui_v3/fragment_seal_dark_v1.png",
}

static var _cache: Dictionary = {}

static func tex(arquivo: String) -> Texture2D:
	if not _cache.has(arquivo):
		_cache[arquivo] = load(PASTA + arquivo)
	return _cache[arquivo]


static func tex_recortada(arquivo: String, regiao: Rect2) -> Texture2D:
	var chave := "%s@%s" % [arquivo, regiao]
	if not _cache.has(chave):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex(arquivo)
		atlas.region = regiao
		atlas.filter_clip = true
		_cache[chave] = atlas
	return _cache[chave]

static func icone_carta(tipo: String) -> Texture2D:
	return tex("icon_%s.png" % tipo)

static func icone_carta_alpha(tipo: String) -> Texture2D:
	return tex(String(ICONE_CARTA_ALPHA.get(tipo, ICONE_CARTA_ALPHA["wild"])))

static func card_face(tipo: String) -> Texture2D:
	return tex(String(CARD_FACE_FINAL.get(tipo, CARD_FACE_FINAL["wild"])))


static func selo_fragmento(tipo: String) -> Texture2D:
	return tex(String(SELO_FRAGMENTO.get(tipo, SELO_FRAGMENTO["dragon"])))


static func moldura_selo_fragmento() -> Texture2D:
	return tex(MOLDURA_SELO_FRAGMENTO)


static func selo_v6_empty(tipo: String) -> Texture2D:
	return tex(String(SELO_V6_EMPTY.get(tipo, SELO_V6_EMPTY["dragon"])))


static func selo_v6_charge(tipo: String) -> Texture2D:
	return tex(String(SELO_V6_CHARGE.get(tipo, SELO_V6_CHARGE["dragon"])))


static func party_field(tipo: String) -> Texture2D:
	return tex(PARTY_FINAL + "card_party/field_%s.png" % tipo)


static func party_scene(tipo: String) -> Texture2D:
	return tex(PARTY_FINAL + "card_party/scene_%s.png" % tipo)


static func party_symbol(tipo: String) -> Texture2D:
	var selected := tipo if PARTY_SYMBOL_BOUNDS.has(tipo) else "dragon"
	return tex_recortada(PARTY_FINAL + "card_party/sym_%s.png" % selected,
		PARTY_SYMBOL_BOUNDS[selected])


static func party_hero(tipo: String) -> Texture2D:
	return tex(PARTY_FINAL + "char80/char_%s.png" % tipo)


static func party_digits() -> Texture2D:
	return tex(PARTY_FINAL + "ui/digits_1x_v1.png")


static func hud_inimigo_v6_plate(tipo: String) -> Texture2D:
	return tex(String(HUD_INIMIGO_V6_PLATE.get(tipo, HUD_INIMIGO_V6_PLATE["dragon"])))


static func nativo_carta_alpha(tipo: String) -> Vector2:
	return icone_carta_alpha(tipo).get_size()

static func nativo(tipo: String) -> Vector2:
	return ICONE_NATIVO.get(tipo, Vector2(100, 100))

# Escala do prototipo: o lado maior do icone vira `lado`.
static func escala_icone(tipo: String, lado: float) -> Vector2:
	var n := nativo(tipo)
	var f := lado / maxf(n.x, n.y)
	return n * f

static func escala_icone_carta_alpha(tipo: String, lado: float) -> Vector2:
	var n := nativo_carta_alpha(tipo)
	var f := lado / maxf(n.x, n.y)
	return n * f


static func cor_elemental(tipo: String) -> Color:
	return CORES_ELEMENTAIS.get(tipo, BRANCO)


static func cor_elemental_clara(tipo: String) -> Color:
	return CORES_ELEMENTAIS_CLARAS.get(tipo, BRANCO)


static func cor_elemental_variada(tipo: String, indice: int) -> Color:
	if tipo == "wild":
		return cor_elemental(ELEMENTOS[posmod(indice, ELEMENTOS.size())])
	return cor_elemental(tipo)


static func material_carta_elemental(tipo: String, intensidade := 0.52) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/card_element_tint.gdshader")
	material.set_shader_parameter("cor_primaria", cor_elemental(tipo))
	material.set_shader_parameter("intensidade", intensidade)
	material.set_shader_parameter("multicolor", tipo == "wild")
	return material


# Marcador cromatico usado sobre unidades. Sem glifo: a forma quadrada e a
# propria cor viram o vocabulario rapido de tipo durante a batalha.
static func marcador_elemento(tipo: String, r: Rect2, pai: Node) -> Panel:
	var painel := Panel.new()
	painel.position = r.position
	painel.size = r.size
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cor := cor_elemental(tipo)
	var estilo := StyleBoxFlat.new()
	# Mistura com o cinza da interface, nao com branco puro: aspecto de
	# tinta fosca impressa sobre o HUD, sem parecer um LED.
	estilo.bg_color = cor.lerp(Color("73737b"), 0.30)
	estilo.border_color = Color("c4c4c9").lerp(cor, 0.10)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(3)
	estilo.shadow_color = Color(0, 0, 0, 0.58)
	estilo.shadow_size = 2
	painel.add_theme_stylebox_override("panel", estilo)
	pai.add_child(painel)
	var brilho := ColorRect.new()
	brilho.position = Vector2(4, 4)
	brilho.size = Vector2(maxf(2.0, r.size.x * 0.13), maxf(2.0, r.size.y * 0.13))
	brilho.color = Color(1, 1, 1, 0.24)
	brilho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(brilho)
	return painel

static var _fonte: Font

# Press Start 2P (Google Fonts, OFL) - a fonte do design. Se o .ttf nao
# estiver em assets/fontes/, cai numa monoespacada do sistema para nada
# quebrar; o layout continua igual, so o desenho da letra muda.
static func fonte() -> Font:
	if _fonte == null:
		var caminho := "res://assets/fontes/PressStart2P-Regular.ttf"
		if ResourceLoader.exists(caminho):
			_fonte = load(caminho)
		else:
			var sf := SystemFont.new()
			sf.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])
			_fonte = sf
	return _fonte


# --- helpers de montagem ---------------------------------------------

# TextureRect posicionado em pixels do canvas lógico atual, do jeito que o
# handoff especifica (left/top/width/height).
static func imagem(arquivo: String, r: Rect2, pai: Node = null) -> TextureRect:
	var t := TextureRect.new()
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.texture = tex(arquivo)
	t.position = r.position
	t.size = r.size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if pai != null:
		pai.add_child(t)
	return t


static func rotulo(txt: String, pos: Vector2, tamanho: int, cor: Color, largura := 0.0,
		centro := false, pai: Node = null) -> Label:
	var l := Label.new()
	l.text = txt
	l.position = pos
	if largura > 0.0:
		l.size.x = largura
	l.add_theme_font_override("font", fonte())
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	if centro:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if pai != null:
		pai.add_child(l)
	return l


# Material de inversao (o `filter: invert(1)` do prototipo). Cada no
# ganha o seu, porque o "hit flash" anima a quantidade por unidade.
static func material_inversor(quantidade := 1.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/inverter.gdshader")
	m.set_shader_parameter("quantidade", quantidade)
	return m


static func material_hud_inimigo_neutro() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/hud_inimigo_neutro.gdshader")
	return m


# Componente universal de affinity usado por aliados e inimigos.
static func affinity(tipo: String, r: Rect2, pai: Node) -> Panel:
	var painel := Panel.new()
	painel.position = r.position
	painel.size = r.size
	painel.clip_contents = true
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = ESCURO
	estilo.border_color = BRANCO
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(3)
	painel.add_theme_stylebox_override("panel", estilo)
	pai.add_child(painel)

	var icone := Sprite2D.new()
	icone.texture = icone_carta(tipo)
	painel.add_child(icone)
	icone.position = r.size / 2.0
	var lado := maxf(4.0, minf(r.size.x, r.size.y) - 8.0)
	var tam := escala_icone(tipo, lado)
	icone.scale = tam / nativo(tipo)
	return painel


# Caveirinha das pontas da fileira de pips (no prototipo e um SVG
# inline; aqui e desenhada em 16x16 e ampliada com filtro nearest, para
# continuar pixel art de verdade).
static var _caveira: Texture2D

static func caveira() -> Texture2D:
	if _caveira != null:
		return _caveira
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_bloco(img, 3, 2, 10, 8, BRANCO)   # cranio
	_bloco(img, 5, 10, 6, 2, BRANCO)   # maxilar
	_bloco(img, 6, 12, 4, 2, BRANCO)   # queixo
	_bloco(img, 5, 4, 2, 3, ESCURO)    # olho esquerdo
	_bloco(img, 9, 4, 2, 3, ESCURO)    # olho direito
	_bloco(img, 7, 8, 2, 2, ESCURO)    # boca
	_caveira = ImageTexture.create_from_image(img)
	return _caveira

static func _bloco(img: Image, x: int, y: int, w: int, h: int, cor: Color) -> void:
	for j in range(y, y + h):
		for i in range(x, x + w):
			img.set_pixel(i, j, cor)
