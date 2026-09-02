extends Control
class_name BattleScreen

# A TELA DE BATALHA do handoff (ideias/godot_handoff_battle_screen/),
# recriada nativa em Godot. Toda posicao, tamanho e duracao de animacao
# vem de `scene_data.json` + `design_reference/Battle Screen.dc.html`.
#
# A REGRA nao mora aqui: quem decide e EstadoBatalha.gd (a mecanica de
# trio + cascata dos MDs). Um toque devolve a corrente INTEIRA ja
# resolvida numa lista de eventos, e esta tela so reproduz esses
# eventos em ordem - nunca consulta o estado no meio da animacao.
# Enquanto uma corrente anima, toques sao ignorados (`_animando`).
#
# A grade visivel tem 2 fileiras de 6 slots: cinco cartas iniciais e a sexta
# casa de ENTRADA vazia em cada fileira, alimentada diretamente por NEXT.

const CANVAS := Vector2(940, 1685)
const COR_REGUA_HAND := Color(0.79, 0.75, 0.66, 0.32)

# --- tempos ----------------------------------------------------------
const DUR_VOO := 0.22
const DUR_FUSAO_ALINHAR := 0.42
const DUR_FUSAO_CONVERGIR := 0.40
const DUR_QUEDA := 0.18         # NEXT descendo ate a casa consumida
const DUR_PULSO := 0.28
const DUR_FLASH_TELA := 0.10
const ESPERA_ENTRE_COMBOS := 0.18
const DUR_CHUVA := 0.05         # intervalo entre as cartas da chuva final

# --- layout -----------------------------------------------------------
const MOLDURAS := []

const ROTULOS := []

# --- casas ------------------------------------------------------------
const BAG_X0 := 31.0
const BAG_Y := 978.0
const BAG_PASSO := 88.0
const NEXT_CASA := Rect2(819, 978, 78, 108)

# Grade revisada do Designer: 6 colunas de 138x191, gap real de 10 px.
# Largura total 878 px, centralizada na coluna de conteudo de 890 px.
const CAMPO_TAM := Vector2(138, 191)
const CAMPO_X0 := 31.0
const CAMPO_PASSO := 148.0
const CAMPO_LINHAS := [1153.0, 1354.0]
const CAMPO_ICONE := 138.0
const ENTRADA_TAM := CAMPO_TAM
const FUSAO_CENTRO := Vector2(470, 1376)
const VOO_BAG_TAM := Vector2(78, 108)
const VOO_BAG_ICONE := 78.0
const FUSAO_TAM := CAMPO_TAM
const FUSAO_ICONE := CAMPO_ICONE
const FUSAO_PASSO := 148.0

# --- HUD --------------------------------------------------------------
const CAVEIRA_LADO := 20.0
const BARRA_JOGADOR := Rect2(114, 1579, 626, 22)
const BARRA_JOGADOR_RECUO := 3.0
const BARRA_JOGADOR_UTIL := 620.0

var estado: EstadoBatalha

var _inimigos: Array[EnemyUnit] = []
var _aliados: Array[AllyUnit] = []
var _casas_bag: Array[BagSlot] = []
var _icone_next: CardIcon
var _casas_campo: Array[FieldSlot] = []

var _txt_andar: Label
var _txt_score: Label
var _txt_rodada: Label
var _txt_gems: Label
var _txt_moedas: Label
var _txt_hp: BitmapFontLabel
var _txt_energia: Label
var _barra_hp_recorte: Control
var _flash: ColorRect
var _voos: Control  # camada das cartas em transito

var _animando := false
var _dano_visual_acumulado: Dictionary = {}
var _entrada_origem_visual: Dictionary = {}


func _ready() -> void:
	estado = EstadoBatalha.new()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = CANVAS
	_montar()
	_sincronizar()


# ---------------------------------------------------------- montagem

func _montar() -> void:
	var fundo := ColorRect.new()
	fundo.name = "BackgroundFinal"
	fundo.color = Color("080908")
	fundo.size = CANVAS
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	var painel := Panel.new()
	painel.position = Vector2.ZERO
	painel.size = CANVAS
	var painel_estilo := StyleBoxFlat.new()
	painel_estilo.bg_color = Color("0d0e0c")
	painel_estilo.border_color = Color("2b2b28")
	painel_estilo.set_border_width_all(2)
	painel.add_theme_stylebox_override("panel", painel_estilo)
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(painel)
	var moldura_interna := Panel.new()
	moldura_interna.position = Vector2(12, 12)
	moldura_interna.size = Vector2(916, 1661)
	var interna_estilo := StyleBoxFlat.new()
	interna_estilo.bg_color = Color(0, 0, 0, 0)
	interna_estilo.border_color = Color(0.79, 0.75, 0.66, 0.30)
	interna_estilo.set_border_width_all(1)
	moldura_interna.add_theme_stylebox_override("panel", interna_estilo)
	moldura_interna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(moldura_interna)
	_montar_hud_topo()

	var arena := Control.new()
	arena.name = "ArenaLayer"
	arena.position = Unidades.ARENA
	arena.size = Unidades.ARENA_TAM
	arena.clip_contents = true
	arena.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(arena)
	var cenario := Arte.imagem("test_roster/battle_background_ruined_forest.png",
		Rect2(Vector2.ZERO, Vector2(888, 558)), arena)
	cenario.name = "BattleBackground"
	_moldura_arena(Rect2(0, 0, 888, 558), arena)
	_montar_progresso_palco(arena)
	_montar_faixa_aliados(arena)

	for i in estado.inimigos.size():
		var d: Dictionary = estado.inimigos[i]
		var u := EnemyUnit.new()
		arena.add_child(u)
		u.montar(d, i, estado.inimigos.size())
		u.tocado.connect(_ao_tocar_inimigo)
		_inimigos.append(u)
	for i in estado.aliados.size():
		var d: Dictionary = estado.aliados[i]
		var a := AllyUnit.new()
		arena.add_child(a)
		a.montar(d, i)
		a.skill_clicada.connect(_ao_skill_clicada)
		_aliados.append(a)

	_montar_bag()
	_montar_area_hand()
	_montar_campo()
	_montar_hud_rodape()

	# camada das cartas em transito: acima das casas, abaixo do flash
	_voos = Control.new()
	_voos.name = "Voos"
	_voos.set_anchors_preset(Control.PRESET_FULL_RECT)
	_voos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Numerais das cartas da HAND usam z_index local. Esta camada inteira precisa
	# ficar acima deles para a fusao nunca se misturar com o que ficou no grid.
	_voos.z_index = 100
	add_child(_voos)

	_flash = ColorRect.new()
	_flash.name = "ScreenFlash"
	_flash.size = CANVAS
	_flash.z_index = 200
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.visible = false
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/inverter_tela.gdshader")
	mat.set_shader_parameter("quantidade", 1.0)
	_flash.material = mat
	add_child(_flash)


func _bitmap(txt: String, pos: Vector2, altura: int, cor: Color, pai: Node,
		espaco := 0) -> BitmapFontLabel:
	var label := BitmapFontLabel.new()
	label.position = pos.round()
	label.glyph_height = altura
	label.tint = cor
	label.letter_spacing = espaco
	label.text = txt
	pai.add_child(label)
	return label


func _asset_altura(arquivo: String, pos: Vector2, altura: float, pai: Node,
		alpha := 1.0) -> TextureRect:
	var textura := Arte.tex(arquivo)
	var largura: float = roundf(float(textura.get_width()) * altura / float(textura.get_height()))
	var imagem := Arte.imagem(arquivo, Rect2(pos.round(), Vector2(largura, altura)), pai)
	imagem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	imagem.modulate.a = alpha
	return imagem


func _montar_progresso_palco(arena: Control) -> void:
	var placa := Panel.new()
	placa.position = Vector2(22, 505)
	placa.size = Vector2(270, 35)
	placa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.03, 0.035, 0.03, 0.72)
	estilo.border_color = Color(0.79, 0.75, 0.66, 0.40)
	estilo.set_border_width_all(1)
	placa.add_theme_stylebox_override("panel", estilo)
	arena.add_child(placa)
	_asset_altura("ui_v10/ui/lbl_stage.png", Vector2(12, 12), 11, placa, 0.65)
	_asset_altura("ui_v10/ui/val_stage.png", Vector2(78, 11), 12, placa)
	var divisor_stage := ColorRect.new()
	divisor_stage.position = Vector2(118, 8)
	divisor_stage.size = Vector2(1, 18)
	divisor_stage.color = Color(0.79, 0.75, 0.66, 0.28)
	placa.add_child(divisor_stage)
	for x in [143.0, 178.0]:
		var conector := ColorRect.new()
		conector.position = Vector2(x, 17)
		conector.size = Vector2(20, 2)
		conector.color = Color(0.79, 0.75, 0.66, 0.50 if x == 143.0 else 0.28)
		placa.add_child(conector)
	for i in 3:
		var no := ColorRect.new()
		var lado: float = [12.0, 15.0, 17.0][i]
		no.position = Vector2(137 + i * 36, 18) - Vector2.ONE * lado / 2.0
		no.size = Vector2.ONE * lado
		no.rotation = PI / 4.0
		no.color = [Color("e8e3d4"), Color("7d9455"), Color("6b241f")][i]
		no.mouse_filter = Control.MOUSE_FILTER_IGNORE
		placa.add_child(no)
	_asset_altura("ui_v10/ui/lbl_boss.png", Vector2(225, 13), 10, placa, 0.85)


func _moldura_arena(logica: Rect2, pai: Control) -> void:
	var painel := Panel.new()
	painel.position = Unidades.ponto_logico(logica.position)
	painel.size = Unidades.tamanho_logico(logica.size)
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0)
	estilo.border_color = Color(0.79, 0.75, 0.66, 0.35)
	estilo.set_border_width_all(1)
	painel.add_theme_stylebox_override("panel", estilo)
	pai.add_child(painel)
	# Quatro cantos em L da arte final, todos dentro do recorte do palco.
	var pontos := [Vector2(6, 6), Vector2(866, 6), Vector2(6, 536), Vector2(866, 536)]
	for i in 4:
		var canto := Control.new()
		canto.position = pontos[i]
		canto.size = Vector2(16, 16)
		canto.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pai.add_child(canto)
		var horizontal := ColorRect.new()
		horizontal.size = Vector2(16, 2)
		horizontal.position.y = 14 if i >= 2 else 0
		horizontal.color = Color("c9c0a8")
		canto.add_child(horizontal)
		var vertical := ColorRect.new()
		vertical.size = Vector2(2, 16)
		vertical.position.x = 14 if i % 2 == 1 else 0
		vertical.color = Color("c9c0a8")
		canto.add_child(vertical)


func _montar_faixa_aliados(arena: Control) -> void:
	# A arena pertence aos inimigos. Os aliados vivem nesta faixa de interface,
	# que também será reutilizada como linguagem visual no menu de personagens.
	var faixa := Panel.new()
	faixa.name = "AllyRail"
	faixa.position = Vector2(0, 607)
	faixa.size = Vector2(Unidades.ARENA_TAM.x, 222)
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("121311")
	estilo.border_color = Color(0.79, 0.75, 0.66, 0.22)
	estilo.border_width_top = 1
	estilo.border_width_bottom = 1
	faixa.add_theme_stylebox_override("panel", estilo)
	arena.add_child(faixa)
	_asset_altura("ui_v10/ui/lbl_party.png", Vector2(-1, -35), 24, faixa)
	var regra := ColorRect.new()
	regra.position = Vector2(102, -24)
	regra.size = Vector2(750, 2)
	regra.color = COR_REGUA_HAND
	regra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	faixa.add_child(regra)
	for i in 3:
		var ponto := ColorRect.new()
		ponto.position = Vector2(856 + i * 12, -26)
		ponto.size = Vector2(7, 7)
		ponto.color = Color(0.79, 0.75, 0.66, 0.5)
		faixa.add_child(ponto)


func _montar_bag() -> void:
	var painel := Panel.new()
	painel.position = Vector2(25, 947)
	painel.size = Vector2(890, 160)
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("101210")
	estilo.border_color = Color(0.79, 0.75, 0.66, 0.35)
	estilo.set_border_width_all(2)
	painel.add_theme_stylebox_override("panel", estilo)
	add_child(painel)
	# Aba BAG: o fundo opaco apaga o trecho da borda atrás das letras,
	# reproduzindo o encaixe do mock HTML.
	var aba_bag := ColorRect.new()
	aba_bag.position = Vector2(37, 936)
	aba_bag.size = Vector2(60, 22)
	aba_bag.color = Color("0d0e0c")
	aba_bag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(aba_bag)
	_asset_altura("ui_v10/ui/lbl_bag.png", Vector2(43, 936), 20, self)
	var cena := load("res://scenes/battle/BagSlot.tscn") as PackedScene
	for i in EstadoBatalha.BAG_VISIVEL:
		var casa := cena.instantiate() as BagSlot
		casa.indice = i
		casa.position = Vector2(BAG_X0 + float(i) * BAG_PASSO, BAG_Y)
		add_child(casa)
		_casas_bag.append(casa)

	var divisor := ColorRect.new()
	divisor.position = Vector2(781, 965)
	divisor.size = Vector2(2, 124)
	divisor.color = Color(0.79, 0.75, 0.66, 0.25)
	add_child(divisor)
	_asset_altura("ui_v10/ui/lbl_next.png", Vector2(836, 955), 14, self, 0.8)
	_icone_next = CardIcon.new()
	_icone_next.name = "NextCard"
	add_child(_icone_next)
	_icone_next.configurar(NEXT_CASA.size, BagSlot.LADO_ICONE, 0, false, 0.3, 13)
	_icone_next.fixar_em(NEXT_CASA.position)


func _montar_area_hand() -> void:
	# HAND nao e um painel fechado: este Control serve somente de base para
	# o divisor entre as cartas e o HP. A unica linha superior nasce no D.
	var painel := Control.new()
	painel.name = "HandPanel"
	painel.position = Vector2(25, 1115)
	painel.size = Vector2(890, 541)
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(painel)
	var divisor_rodape := ColorRect.new()
	divisor_rodape.position = Vector2(6, 446)
	divisor_rodape.size = Vector2(878, 2)
	divisor_rodape.color = COR_REGUA_HAND
	divisor_rodape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(divisor_rodape)


func _montar_campo() -> void:
	_asset_altura("ui_v10/ui/lbl_hand.png", Vector2(31, 1118), 24, self)
	var regra := ColorRect.new()
	# Regua centralizada na altura visual de HAND: 10 px apos o rotulo e
	# terminando 10 px antes da borda direita do painel.
	regra.position = Vector2(116, 1130)
	regra.size = Vector2(789, 2)
	regra.color = COR_REGUA_HAND
	regra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(regra)
	var cena := load("res://scenes/battle/FieldSlot.tscn") as PackedScene
	for i in EstadoBatalha.TOTAL_SLOTS:
		var casa := cena.instantiate() as FieldSlot
		add_child(casa)
		var entrada := i >= EstadoBatalha.TAMANHO_MAO
		var tamanho := ENTRADA_TAM if entrada else CAMPO_TAM
		casa.configurar(i, tamanho, tamanho.x, entrada)
		casa.position = _pos_casa(i)
		casa.visible = true
		casa.tocado.connect(_ao_tocar_casa)
		_casas_campo.append(casa)


func _montar_hud_topo() -> void:
	var avatar := Panel.new()
	avatar.position = Vector2(27, 28)
	avatar.size = Vector2(58, 58)
	var ae := StyleBoxFlat.new()
	ae.bg_color = Color("141512")
	ae.border_color = Color("8f886f")
	ae.set_border_width_all(2)
	avatar.add_theme_stylebox_override("panel", ae)
	add_child(avatar)
	var avatar_atlas := Arte.tex_recortada("characters_v4/ally_dragon_v1.png",
		Rect2(260, 20, 730, 730))
	var retrato := TextureRect.new()
	retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	retrato.texture = avatar_atlas
	retrato.position = Vector2(32, 33)
	retrato.size = Vector2(48, 48)
	retrato.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(retrato)
	_asset_altura("ui_v10/ui/val_account.png", Vector2(100, 37), 17, self)
	_txt_andar = Arte.rotulo("", Vector2.ZERO, 1, Color(0, 0, 0, 0), 1, false, self)
	var lv_box := Panel.new()
	lv_box.position = Vector2(216, 35)
	lv_box.size = Vector2(53, 19)
	var lv_style := StyleBoxFlat.new()
	lv_style.bg_color = Color(0, 0, 0, 0)
	lv_style.border_color = Color(0.79, 0.75, 0.66, 0.35)
	lv_style.set_border_width_all(1)
	lv_box.add_theme_stylebox_override("panel", lv_style)
	add_child(lv_box)
	_asset_altura("ui_v10/ui/lbl_lv.png", Vector2(5, 4), 11, lv_box, 0.6)
	_asset_altura("ui_v10/ui/val_lv.png", Vector2(29, 3), 12, lv_box)
	_asset_altura("ui_v10/ui/lbl_xp.png", Vector2(100, 66), 11, self, 0.6)
	var xp_trilho := Panel.new()
	xp_trilho.position = Vector2(130, 65)
	xp_trilho.size = Vector2(214, 13)
	var xp_style := StyleBoxFlat.new()
	xp_style.bg_color = Color("121211")
	xp_style.border_color = Color(0.79, 0.75, 0.66, 0.5)
	xp_style.set_border_width_all(1)
	xp_trilho.add_theme_stylebox_override("panel", xp_style)
	add_child(xp_trilho)
	var xp_fill := ColorRect.new()
	xp_fill.position = Vector2(3, 3)
	xp_fill.size = Vector2(128, 7)
	xp_fill.color = Color("c9c0a8")
	xp_trilho.add_child(xp_fill)
	_asset_altura("ui_v10/ui/val_xp.png", Vector2(354, 66), 11, self, 0.7)
	var moeda := Polygon2D.new()
	moeda.position = Vector2(516, 52)
	moeda.polygon = PackedVector2Array([Vector2(-8, -5), Vector2(0, -9),
		Vector2(8, -5), Vector2(8, 5), Vector2(0, 9), Vector2(-8, 5)])
	moeda.color = Color("c9a842")
	add_child(moeda)
	_asset_altura("ui_v10/ui/val_coin.png", Vector2(535, 45), 14, self)
	var gema := Polygon2D.new()
	gema.position = Vector2(638, 52)
	gema.polygon = PackedVector2Array([Vector2(0, -9), Vector2(8, 0),
		Vector2(0, 9), Vector2(-8, 0)])
	gema.color = Color("7a5f9a")
	add_child(gema)
	_asset_altura("ui_v10/ui/val_gem.png", Vector2(653, 45), 14, self)
	var divisor := ColorRect.new()
	divisor.position = Vector2(737, 35)
	divisor.size = Vector2(1, 34)
	divisor.color = Color(0.79, 0.75, 0.66, 0.25)
	add_child(divisor)
	var raio := Polygon2D.new()
	raio.position = Vector2(764, 51)
	raio.polygon = PackedVector2Array([Vector2(3, -13), Vector2(-7, 2),
		Vector2(0, 2), Vector2(-3, 13), Vector2(8, -3), Vector2(1, -3)])
	raio.color = Color("c9a842")
	add_child(raio)
	_asset_altura("ui_v10/ui/val_energy.png", Vector2(782, 44), 16, self)
	_txt_energia = Arte.rotulo("", Vector2.ZERO, 1, Color(0, 0, 0, 0), 1, false, self)
	for i in 3:
		var barra := ColorRect.new()
		barra.position = Vector2(879, 42 + i * 11)
		barra.size = Vector2(34, 5)
		barra.color = Color("c9c0a8")
		add_child(barra)


func _caveira(pos: Vector2) -> void:
	var c := TextureRect.new()
	c.texture = Arte.caveira()
	c.position = pos
	c.size = Vector2(CAVEIRA_LADO, CAVEIRA_LADO)
	c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)


func _montar_hud_rodape() -> void:
	var coracao := Polygon2D.new()
	coracao.position = Vector2(44, 1577)
	coracao.polygon = PackedVector2Array([Vector2(14, 26), Vector2(0, 12), Vector2(0, 5),
		Vector2(5, 0), Vector2(14, 5), Vector2(23, 0), Vector2(28, 5), Vector2(28, 12)])
	coracao.color = Color("c04a3e")
	add_child(coracao)
	_bitmap("HP", Vector2(82, 1582), 16, Color("c9c0a8"), self)
	_txt_hp = _bitmap("", Vector2(750, 1582), 16, Color("e8e3d4"), self)

	var caixa := Panel.new()
	caixa.position = BARRA_JOGADOR.position
	caixa.size = BARRA_JOGADOR.size
	caixa.clip_contents = true
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var caixa_estilo := StyleBoxFlat.new()
	caixa_estilo.bg_color = Color("121211")
	caixa_estilo.border_color = Color(0.79, 0.75, 0.66, 0.55)
	caixa_estilo.set_border_width_all(1)
	caixa.add_theme_stylebox_override("panel", caixa_estilo)
	add_child(caixa)
	_barra_hp_recorte = Control.new()
	_barra_hp_recorte.position = Vector2(BARRA_JOGADOR_RECUO, BARRA_JOGADOR_RECUO)
	_barra_hp_recorte.size = Vector2(BARRA_JOGADOR_UTIL,
		BARRA_JOGADOR.size.y - BARRA_JOGADOR_RECUO * 2.0)
	_barra_hp_recorte.clip_contents = true
	_barra_hp_recorte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_child(_barra_hp_recorte)
	var vida := ColorRect.new()
	vida.position = Vector2.ZERO
	vida.size = _barra_hp_recorte.size
	vida.color = Color("c04a3e")
	_barra_hp_recorte.add_child(vida)
	var brilho := ColorRect.new()
	brilho.position = Vector2.ZERO
	brilho.size = Vector2(_barra_hp_recorte.size.x, 2)
	brilho.color = Color("d9695c")
	_barra_hp_recorte.add_child(brilho)
	var sombra := ColorRect.new()
	sombra.position = Vector2(0, _barra_hp_recorte.size.y - 2)
	sombra.size = Vector2(_barra_hp_recorte.size.x, 2)
	sombra.color = Color("8f3229")
	_barra_hp_recorte.add_child(sombra)


# ------------------------------------------------------------ posicoes

func _pos_casa(idx: int) -> Vector2:
	var linha: int
	var coluna: int
	if idx < EstadoBatalha.TAMANHO_MAO:
		linha = idx / EstadoBatalha.ROW_SIZE
		coluna = idx % EstadoBatalha.ROW_SIZE
	else:
		linha = idx - EstadoBatalha.TAMANHO_MAO
		coluna = EstadoBatalha.ROW_SIZE
		return Vector2(CAMPO_X0 + float(coluna) * CAMPO_PASSO, CAMPO_LINHAS[linha])
	return Vector2(CAMPO_X0 + float(coluna) * CAMPO_PASSO, CAMPO_LINHAS[linha])


func _centro_casa(idx: int) -> Vector2:
	return _pos_casa(idx) + _casas_campo[idx].size / 2.0


func _centro_next() -> Vector2:
	return NEXT_CASA.get_center()


# -------------------------------------------------------- sincronia

func _sincronizar(sincronizar_fila := true) -> void:
	if sincronizar_fila:
		_atualizar_fila(estado.proximas)
	_desenhar_campo()
	_atualizar_hud()


func _desenhar_campo() -> void:
	for i in EstadoBatalha.TOTAL_SLOTS:
		var c: Carta = estado.mao[i]
		_casas_campo[i].visible = true
		_casas_campo[i].position = _pos_casa(i)
		if c == null:
			# Cartas marcadas deixam de existir na mao da regra, mas continuam
			# visiveis e levantadas ate o trio fechar ou o jogador desmarcar.
			if not estado.marcada(i):
				_casas_campo[i].limpar()
				_casas_campo[i].position = _pos_casa(i)
		else:
			_casas_campo[i].mostrar(c.tipo, c.valor, false)


# Aceita tanto a fila viva (Array[Carta]) quanto uma foto vinda de
# evento (Array de Dictionary) - as duas tem tipo e valor.
func _atualizar_fila(fila: Array) -> void:
	if fila.is_empty():
		_icone_next.limpar()
	else:
		var proxima: Variant = fila[0]
		_icone_next.mostrar(String(proxima.tipo), 0, false)

	# A fila corre da esquerda para a direita. O ultimo item visivel, na
	# extrema direita da BAG, e o mesmo que aparece em NEXT.
	for i in _casas_bag.size():
		var indice_fila := _casas_bag.size() - 1 - i
		if indice_fila >= fila.size():
			_casas_bag[i].limpar()
			continue
		var item: Variant = fila[indice_fila]
		_casas_bag[i].mostrar(String(item.tipo), 0)


func _atualizar_hud() -> void:
	for i in _inimigos.size():
		var u: EnemyUnit = _inimigos[i]
		u.atualizar()
		u.definir_turno(estado.contador_inimigo, estado.contador_inimigo_max)
		u.definir_selecionado(i == estado.alvo_selecionado)
	for a: AllyUnit in _aliados:
		a.atualizar()

	_txt_andar.text = ""
	_txt_hp.text = "%d/%d" % [estado.hp, estado.hp_max]
	_txt_energia.text = ""

	var fracao := clampf(float(estado.hp) / maxf(1.0, float(estado.hp_max)), 0.0, 1.0)
	_barra_hp_recorte.size.x = BARRA_JOGADOR_UTIL * fracao

	var liberado := not _animando and not estado.fim
	for i in _casas_campo.size():
		_casas_campo[i].habilitado = liberado


# ------------------------------------------------------------- toques

func _ao_tocar_inimigo(indice: int) -> void:
	if _animando or estado.fim:
		return
	if estado.selecionar_alvo(indice):
		_atualizar_hud()


func _ao_skill_clicada(indice: int) -> void:
	if _animando or estado.fim or indice < 0 or indice >= _aliados.size():
		return
	# Confirmacao provisoria de interface. A carga nao e consumida ate as
	# cinco habilidades receberem seus efeitos canonicos.
	_flutuar_placa("SKILL!", _aliados[indice].centro_no_canvas() + Vector2(0, -105))

func _ao_tocar_casa(idx: int) -> void:
	if _animando or estado.fim:
		return
	# Se a carta daquela casa esta marcada (levantada visualmente), o
	# toque DESMARCA: a carta volta pra casa e a que
	# tinha descido do saco volta pro topo da fila.
	var res: Dictionary
	if estado.marcada(idx):
		res = estado.desmarcar(idx)
	else:
		res = estado.tocar(idx)
	if String(res.tipo) == "ignorado":
		return
	await _reproduzir(res)


# --------------------------------------------------------- reproducao

func _reproduzir(res: Dictionary) -> void:
	_animando = true
	_dano_visual_acumulado.clear()
	_atualizar_hud()
	for ev: Dictionary in res.eventos:
		match String(ev.tipo):
			"selecao": await _anim_selecao(ev)
			"deselecao": await _anim_deselecao(ev)
			"carta_desce": await _anim_desce(ev)
			"carta_volta": await _anim_volta(ev)
			"abandono": await _anim_abandono()
			"puxa_do_deck": await _anim_puxa(ev)
			"trio_sobe": await _anim_trio(ev)
			"combo": await _anim_combo(ev)
			"renovacao": await _anim_renovacao()
			"nova_carta": await _anim_nova_carta(ev)
			"entra_na_mao": await _anim_entra_na_mao(ev)
			"redistribuicao": await _anim_redistribuicao(ev)
			"ataque_final": await _anim_ataque_final(ev)

	if res.has("ataque_inimigo"):
		await _anim_ataque_inimigo(int(res.ataque_inimigo))

	_animando = false
	_sincronizar()
	if estado.fim:
		_anunciar_fim()


func _espera(s: float) -> void:
	await get_tree().create_timer(s).timeout


# Carta viajando de um ponto a outro. Devolve depois de pousar.
func _voar(carta: Dictionary, de: Vector2, para: Vector2, dur := DUR_VOO) -> void:
	var icone := CardIcon.new()
	_voos.add_child(icone)
	icone.configurar(VOO_BAG_TAM, VOO_BAG_ICONE, 0, false, 0.3, 13)
	icone.fixar_em(de - VOO_BAG_TAM / 2.0)
	icone.mostrar(String(carta.tipo), int(carta.valor), false)
	var t := create_tween()
	t.tween_property(icone, "position", para - VOO_BAG_TAM / 2.0, dur) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await t.finished
	icone.queue_free()


func _anim_selecao(ev: Dictionary) -> void:
	var slot := int(ev.slot)
	var casa := _casas_campo[slot]
	casa.definir_selecionada(true)
	await _espera(0.12)


func _anim_deselecao(ev: Dictionary) -> void:
	var slot := int(ev.slot)
	var casa := _casas_campo[slot]
	casa.definir_selecionada(false)
	casa.position = _pos_casa(slot)
	casa.visible = true
	await _espera(0.12)


# A primeira e a segunda selecao puxam NEXT para a sexta casa da fileira.
# A carta que viaja e exatamente a ultima carta visivel a direita da BAG.
func _anim_desce(ev: Dictionary) -> void:
	var slot := int(ev.slot)
	_casas_campo[slot].position = _pos_casa(slot)
	var destino := _centro_casa(slot)
	await _voar(ev.carta, _centro_next(), destino, DUR_QUEDA)
	_casas_campo[slot].visible = true
	_casas_campo[slot].mostrar(String(ev.carta.tipo), int(ev.carta.valor))
	_atualizar_fila(ev.fila)


func _anim_volta(ev: Dictionary) -> void:
	var slot := int(ev.slot)
	var carta := {"tipo": _casas_campo[slot].tipo_atual(),
		"valor": _casas_campo[slot].valor_atual()}
	_casas_campo[slot].limpar()
	if String(carta.tipo) != "":
		await _voar(carta, _centro_casa(slot), _centro_next(), DUR_QUEDA)
	_atualizar_fila(ev.fila)
	_entrada_origem_visual.erase(slot)
	_casas_campo[slot].visible = true


func _anim_abandono() -> void:
	for i in _casas_campo.size():
		var casa := _casas_campo[i]
		casa.definir_selecionada(false)
		casa.position = _pos_casa(i)
	await _espera(0.13)


# A cascata puxou a carta do topo do saco para completar o trio.
func _anim_puxa(ev: Dictionary) -> void:
	_atualizar_fila(ev.fila)
	await _espera(0.05)


# As cartas nunca saem para uma lane permanente: copias visuais se
# encontram dentro da propria area da mao, colapsam e viram energia.
func _anim_trio(ev: Dictionary) -> void:
	var cartas: Array = ev.cartas
	var slots: Array = ev.slots
	var tipo_fusao := "wild"
	for carta_tipo: Dictionary in cartas:
		if String(carta_tipo.tipo) != Carta.CORINGA:
			tipo_fusao = String(carta_tipo.tipo)
			break
	var icones: Array[CardIcon] = []
	for i in cartas.size():
		var slot := int(slots[i])
		var de := _centro_next()
		if slot >= 0:
			de = _centro_casa(slot)
			_casas_campo[slot].definir_selecionada(false)
			_casas_campo[slot].limpar()
			if slot >= EstadoBatalha.TAMANHO_MAO:
				_entrada_origem_visual.erase(slot)
		var icone := CardIcon.new()
		_voos.add_child(icone)
		icone.configurar(FUSAO_TAM, FUSAO_ICONE, 0, false, 0.3, 13)
		icone.fixar_em(de - FUSAO_TAM / 2.0)
		icone.mostrar(String(cartas[i].tipo), int(cartas[i].valor), false)
		icones.append(icone)
	var chegada := create_tween().set_parallel()
	for i in icones.size():
		var destino := FUSAO_CENTRO + Vector2((float(i) - 1.0) * FUSAO_PASSO, 0)
		var destino_pos := destino - FUSAO_TAM / 2.0
		chegada.tween_method(_mover_control_round.bind(icones[i], icones[i].position,
			destino_pos), 0.0, 1.0, DUR_FUSAO_ALINHAR) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await chegada.finished
	var fundir := create_tween().set_parallel()
	for icone: CardIcon in icones:
		fundir.tween_method(_mover_control_round.bind(icone, icone.position,
			FUSAO_CENTRO - FUSAO_TAM / 2.0), 0.0, 1.0, DUR_FUSAO_CONVERGIR) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await fundir.finished
	await _pulso_fusao(tipo_fusao)
	_piscar_tela()
	for icone: CardIcon in icones:
		icone.queue_free()
	for i in _casas_campo.size():
		_casas_campo[i].position = _pos_casa(i)


func _pulso_fusao(tipo: String) -> void:
	var grupo := Control.new()
	grupo.position = FUSAO_CENTRO
	grupo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_voos.add_child(grupo)
	var nucleo := Panel.new()
	nucleo.position = Vector2(-32, -32)
	nucleo.size = Vector2(64, 64)
	nucleo.pivot_offset = nucleo.size / 2.0
	var estilo := StyleBoxFlat.new()
	var cor_elemento := Arte.cor_elemental(tipo)
	estilo.bg_color = Arte.BRANCO
	estilo.border_color = cor_elemento.lerp(Arte.BRANCO, 0.32)
	estilo.set_border_width_all(6)
	estilo.set_corner_radius_all(2)
	estilo.shadow_color = Color(1, 1, 1, 0.9)
	estilo.shadow_size = 22
	nucleo.add_theme_stylebox_override("panel", estilo)
	grupo.add_child(nucleo)
	for i in 26:
		var pixel := ColorRect.new()
		var cor_pixel := cor_elemento
		if tipo == Carta.CORINGA:
			cor_pixel = Arte.cor_elemental(Arte.ELEMENTOS[i % Arte.ELEMENTOS.size()])
		pixel.color = cor_pixel.lerp(Arte.BRANCO, 0.18 if i % 3 else 0.55)
		pixel.size = Vector2.ONE * (4.0 if i % 3 else 8.0)
		var angulo := TAU * float(i) / 26.0
		var raio := 24.0
		pixel.position = Vector2(cos(angulo), sin(angulo)) * raio - pixel.size / 2.0
		grupo.add_child(pixel)
		var destino := Vector2(cos(angulo), sin(angulo)) * (112.0 + float(i % 3) * 6.0) - pixel.size / 2.0
		var pt := create_tween().set_parallel()
		pt.tween_method(_mover_control_round.bind(pixel, pixel.position, destino),
			0.0, 1.0, 0.54).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		pt.tween_property(pixel, "modulate:a", 0.0, 0.54)
	var t := create_tween().set_parallel()
	t.tween_property(nucleo, "modulate:a", 0.0, 0.20)
	await t.finished
	await _espera(0.34)
	grupo.queue_free()


func _anim_combo(ev: Dictionary) -> void:
	var cadeia := int(ev.cadeia)
	var txt := "COMBO" if cadeia == 0 else "COMBO x%d" % (cadeia + 1)
	if bool(ev.critico):
		txt = "CRITICO! " + txt
	if bool(ev.get("todos", false)):
		txt = "WILD! " + txt
	elif bool(ev.cura):
		txt = "CURA " + txt
	_flutuar(txt, FUSAO_CENTRO + Vector2(0, -72), 20)
	var cargas: Array = ev.get("cargas", [])
	for carga: Dictionary in cargas:
		var atacante := int(carga.atacante)
		if atacante < 0 or atacante >= _aliados.size():
			continue
		await _anim_energia(String(ev.tipo_carta), FUSAO_CENTRO,
			_aliados[atacante].centro_no_canvas())
		_aliados[atacante].adicionar_carga(int(carga.get("skill_incremento", 1)))
		_aliados[atacante].piscar()
		var total := int(_dano_visual_acumulado.get(atacante, 0)) + int(carga.get("valor", 0))
		_dano_visual_acumulado[atacante] = total
		var tipo_aliado := String(_aliados[atacante].dados.def.elemento)
		_flutuar_placa("+%d" % total,
			_aliados[atacante].centro_no_canvas() + Vector2(0, -74), tipo_aliado)
	if bool(ev.cura):
		await _anim_energia("capsule", FUSAO_CENTRO, Vector2(50, 1635))
	await _espera(ESPERA_ENTRE_COMBOS)


func _anim_energia(tipo: String, de: Vector2, para: Vector2) -> void:
	var fluxo := FusionStream.new()
	_voos.add_child(fluxo)
	fluxo.iniciar(tipo, de, para)
	await fluxo.finalizado
	await _pulso_impacto(para)


func _mover_control_round(f: float, item: Control, de: Vector2, para: Vector2) -> void:
	item.position = de.lerp(para, f).round()


func _pulso_impacto(posicao: Vector2) -> void:
	var impacto := Panel.new()
	impacto.position = posicao - Vector2(24, 24)
	impacto.size = Vector2(48, 48)
	impacto.pivot_offset = impacto.size / 2.0
	impacto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(1, 1, 1, 0.12)
	estilo.border_color = Arte.BRANCO
	estilo.set_border_width_all(5)
	estilo.set_corner_radius_all(10)
	estilo.shadow_color = Color(1, 1, 1, 0.85)
	estilo.shadow_size = 18
	impacto.add_theme_stylebox_override("panel", estilo)
	_voos.add_child(impacto)
	impacto.scale = Vector2(0.3, 0.3)
	var t := create_tween().set_parallel()
	t.tween_property(impacto, "scale", Vector2(1.7, 1.7), 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(impacto, "modulate:a", 0.0, 0.2).set_delay(0.07)
	await t.finished
	impacto.queue_free()


func _anim_renovacao() -> void:
	_flutuar("RENOVACAO", Vector2(CANVAS.x / 2.0, CAMPO_LINHAS[0] - 40.0), 24)
	await _espera(0.2)


func _anim_nova_carta(ev: Dictionary) -> void:
	var slot := int(ev.slot)
	var destino := _centro_casa(slot)
	await _voar(ev.carta, _centro_next(), destino, DUR_QUEDA)
	_casas_campo[slot].visible = true
	_casas_campo[slot].mostrar(String(ev.carta.tipo), int(ev.carta.valor))
	_atualizar_fila(ev.fila)
	await _espera(DUR_CHUVA if bool(ev.get("chuva", false)) else 0.01)


func _anim_entra_na_mao(ev: Dictionary) -> void:
	var de := int(ev.de)
	var para := int(ev.para)
	var destino := _centro_casa(para)
	var origem := _centro_casa(de)
	_casas_campo[de].limpar()
	# A carta da entrada passa para uma das cinco casas jogaveis da fileira.
	var carta_estado: Carta = estado.mao[para]
	if carta_estado != null:
		await _voar({"tipo": carta_estado.tipo, "valor": carta_estado.valor},
			origem, destino, DUR_QUEDA)
		_casas_campo[para].mostrar(carta_estado.tipo, carta_estado.valor)
		_casas_campo[para].visible = true
	_entrada_origem_visual.erase(de)
	_casas_campo[de].visible = true


func _anim_redistribuicao(ev: Dictionary) -> void:
	var m: Array = ev.mao
	_entrada_origem_visual.clear()
	for i in EstadoBatalha.TAMANHO_MAO:
		_casas_campo[i].visible = true
		if i >= m.size() or m[i] == null:
			_casas_campo[i].limpar()
		else:
			_casas_campo[i].mostrar(String(m[i].tipo), int(m[i].valor))
	for i in range(EstadoBatalha.TAMANHO_MAO, _casas_campo.size()):
		_casas_campo[i].visible = true
		_casas_campo[i].position = _pos_casa(i)
		_casas_campo[i].limpar()
	await _espera(0.12)


# So aqui o dano da corrente inteira aparece: um numero por inimigo
# atingido, mais a cura, se houve.
func _anim_ataque_final(ev: Dictionary) -> void:
	for a: AllyUnit in _aliados:
		if a.tem_carga():
			a.piscar()
	await _espera(0.12)
	for golpe: Dictionary in ev.golpes:
		var alvo := int(golpe.alvo)
		_inimigos[alvo].piscar()
		var centro := _inimigos[alvo].centro_no_canvas()
		var impacto := ElementImpact.new()
		_voos.add_child(impacto)
		impacto.iniciar(String(golpe.get("tipo", "light")), centro)
		_flutuar("-%d" % int(golpe.dano), centro + Vector2(0, -72.0), 22)
	if int(ev.cura_total) > 0:
		_flutuar("+%d" % int(ev.cura_total), Vector2(120, 1615), 22)
	_atualizar_hud()
	await _espera(0.3)
	for a: AllyUnit in _aliados:
		a.limpar_carga()


func _anim_ataque_inimigo(dano: int) -> void:
	var vivos: Array[AllyUnit] = []
	for a: AllyUnit in _aliados:
		if int(a.dados.hp) > 0:
			vivos.append(a)
	if not vivos.is_empty():
		vivos[randi() % vivos.size()].piscar()
	_flutuar("-%d" % dano, Vector2(180, 1640), 24)
	_atualizar_hud()
	await _espera(0.35)
func _piscar_tela() -> void:
	_flash.visible = true
	await _espera(DUR_FLASH_TELA)
	_flash.visible = false


# Texto que sobe e some. Sempre branco: a paleta so tem dois tons.
func _flutuar(txt: String, pos: Vector2, tamanho: int) -> void:
	var l := Arte.rotulo(txt, Vector2.ZERO, tamanho, Arte.TEXTO_NO_ESCURO, 460.0, true, self)
	l.position = pos - Vector2(230, 0)
	var t := create_tween().set_parallel()
	t.tween_property(l, "position:y", l.position.y - 46.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.25)
	await t.finished
	l.queue_free()


# Resultado acumulado da corrente, no formato de placa do conceito.
func _flutuar_placa(txt: String, pos: Vector2, tipo := "light") -> void:
	var placa := DamagePopup.new()
	placa.position = pos - DamagePopup.TAM / 2.0
	placa.z_index = 80
	add_child(placa)
	placa.montar(txt, tipo)
	placa.scale = Vector2(1.28, 1.28)
	var t := create_tween().set_parallel()
	t.tween_property(placa, "scale", Vector2.ONE, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(placa, "position:y", placa.position.y - 34.0, 0.72) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(placa, "modulate:a", 0.0, 0.3).set_delay(0.5)
	await t.finished
	placa.queue_free()


func _anunciar_fim() -> void:
	if has_node("FimDeJogo"):
		return
	var txt := "VICTORY" if estado.vitoria else "DEFEAT"
	var l := Arte.rotulo(txt, Vector2(0, 640), 48, Arte.TEXTO_NO_CLARO, CANVAS.x, true, self)
	l.name = "FimDeJogo"
	l.pivot_offset = Vector2(CANVAS.x / 2.0, 24)
	var t := create_tween()
	t.tween_property(l, "scale", Vector2(1.15, 1.15), 0.35).set_trans(Tween.TRANS_BACK)
