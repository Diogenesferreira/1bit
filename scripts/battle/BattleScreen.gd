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
const DUR_VOO := 0.24
const DUR_FUSAO_ALINHAR := 0.30
const DUR_FUSAO_CONVERGIR := 0.26
const DUR_QUEDA := 0.24         # NEXT descendo e crescendo ate a HAND
const DUR_BAG_DESLIZE := 0.14
const DUR_EMBARALHAR := 0.28
const DUR_PULSO := 0.28
const DUR_FLASH_TELA := 0.10
const ESPERA_ENTRE_COMBOS := 0.09
const DUR_CHUVA := 0.02         # intervalo entre as cartas da chuva final
const CHAIN_ACELERACAO := 0.26  # +26% de velocidade por elo concluido
const CHAIN_VELOCIDADE_MAX := 2.35
const EMBARALHAR_VELOCIDADE_MIN := 1.45
const DISTRIBUICAO_FINAL_ACELERACAO := 1.5

# --- layout -----------------------------------------------------------
const MOLDURAS := []

const ROTULOS := []

# --- casas ------------------------------------------------------------
# A BAG tem respiro proprio dentro da moldura; nao precisa compartilhar o
# alinhamento da HAND, cuja grade ocupa toda a largura disponivel.
const BAG_X0 := 50.0
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
const LIFE_POSITION := Vector2(31, 1577)
const LIFE_WIDTH := 878

var estado: EstadoBatalha

var _inimigos: Array[EnemyUnit] = []
var _aliados: Array[AllyUnit] = []
var _casas_bag: Array[BagSlot] = []
var _icone_next: CardIcon
var _casas_campo: Array[FieldSlot] = []
var _sfx: BattleSfx

var _txt_andar: Label
var _txt_score: Label
var _txt_rodada: Label
var _txt_gems: Label
var _txt_moedas: Label
var _txt_energia: Label
var _life_bar: PlayerLifeBar
var _flash: ColorRect
var _voos: Control  # camada das cartas em transito

var _animando := false
var _chain_visual := 0
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
	_sfx = BattleSfx.new()
	_sfx.name = "BattleSfx"
	add_child(_sfx)
	var fundo := ColorRect.new()
	fundo.name = "BackgroundFinal"
	fundo.color = Color("080908")
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var painel := Panel.new()
	var painel_estilo := StyleBoxFlat.new()
	painel_estilo.bg_color = Color("0d0e0c")
	painel_estilo.border_color = Color("2b2b28")
	painel_estilo.set_border_width_all(2)
	painel.add_theme_stylebox_override("panel", painel_estilo)
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(painel)
	painel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var moldura_interna := Panel.new()
	var interna_estilo := StyleBoxFlat.new()
	interna_estilo.bg_color = Color(0, 0, 0, 0)
	interna_estilo.border_color = Color(0.79, 0.75, 0.66, 0.30)
	interna_estilo.set_border_width_all(1)
	moldura_interna.add_theme_stylebox_override("panel", interna_estilo)
	moldura_interna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(moldura_interna)
	moldura_interna.anchor_right = 1.0
	moldura_interna.anchor_bottom = 1.0
	moldura_interna.offset_left = 12.0
	moldura_interna.offset_top = 12.0
	moldura_interna.offset_right = -12.0
	moldura_interna.offset_bottom = -12.0
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
	_flash.z_index = 200
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.visible = false
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/inverter_tela.gdshader")
	mat.set_shader_parameter("quantidade", 1.0)
	_flash.material = mat
	add_child(_flash)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


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
	_life_bar = PlayerLifeBar.new()
	_life_bar.name = "PlayerLifeBar"
	_life_bar.position = LIFE_POSITION
	_life_bar.row_width = LIFE_WIDTH
	_life_bar.hp_max = estado.hp_max
	_life_bar.hp_current = estado.hp
	add_child(_life_bar)


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
	_txt_energia.text = ""
	_life_bar.hp_max = estado.hp_max
	_life_bar.drain_to(estado.hp)

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
	_chain_visual = 0
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


func _velocidade_chain() -> float:
	return minf(1.0 + float(_chain_visual) * CHAIN_ACELERACAO,
		CHAIN_VELOCIDADE_MAX)


func _tempo_chain(base: float) -> float:
	return base / _velocidade_chain()


func _pitch_chain() -> float:
	return minf(1.0 + float(_chain_visual) * 0.035, 1.18)


# Carta viajando de um ponto a outro. Devolve depois de pousar.
func _voar(carta: Dictionary, de: Vector2, para: Vector2, dur := DUR_VOO,
		tam_de := VOO_BAG_TAM, tam_para := VOO_BAG_TAM, altura_arco := 18.0) -> void:
	var icone := CardIcon.new()
	_voos.add_child(icone)
	icone.configurar(tam_de, tam_de.x, 0, false, 0.3, 13)
	icone.fixar_em(de - tam_de / 2.0)
	icone.mostrar(String(carta.tipo), int(carta.valor), false)
	var inicio := icone.position
	var destino := para - tam_de / 2.0
	var escala_final := tam_para.x / tam_de.x
	var t := create_tween().set_parallel()
	t.tween_method(_mover_control_arco.bind(icone, inicio, destino, altura_arco),
		0.0, 1.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(icone, "scale", Vector2.ONE * escala_final, dur) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	icone.queue_free()


func _mover_control_arco(f: float, item: Control, de: Vector2, para: Vector2,
		altura: float) -> void:
	var controle := (de + para) / 2.0 + Vector2(0, -altura)
	var inv := 1.0 - f
	item.position = (de * inv * inv + controle * 2.0 * inv * f + para * f * f).round()


func _criar_carta_overlay(tipo: String, valor: int, tamanho: Vector2,
		posicao: Vector2) -> CardIcon:
	var icone := CardIcon.new()
	_voos.add_child(icone)
	icone.configurar(tamanho, tamanho.x, 0, false, 0.3, 13)
	icone.fixar_em(posicao)
	icone.mostrar(tipo, valor, false)
	return icone


func _item_visual_bag(fila: Array, indice_visual: int) -> Dictionary:
	var indice_fila := _casas_bag.size() - 1 - indice_visual
	if indice_fila < 0 or indice_fila >= fila.size():
		return {}
	var item: Variant = fila[indice_fila]
	return {"tipo": String(item.tipo), "valor": 0}


# A BAG e uma esteira: ao comprar, as cartas existentes deslizam para a
# direita e uma nova aparece pela esquerda. Ao devolver, o sentido se inverte.
func _animar_fila(fila: Array, direcao := 1, duracao := DUR_BAG_DESLIZE) -> void:
	var antigos: Array[Dictionary] = []
	for casa: BagSlot in _casas_bag:
		antigos.append({"tipo": casa.tipo_atual(), "valor": 0})
		casa.limpar()

	var voando: Array[CardIcon] = []
	var t := create_tween().set_parallel()
	if direcao >= 0:
		for i in range(_casas_bag.size() - 1):
			if String(antigos[i].tipo) == "":
				continue
			var icone := _criar_carta_overlay(String(antigos[i].tipo), 0,
				VOO_BAG_TAM, _casas_bag[i].position)
			voando.append(icone)
			t.tween_property(icone, "position", _casas_bag[i + 1].position, duracao) \
				.set_delay(float(i) * 0.008).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var nova := _item_visual_bag(fila, 0)
		if not nova.is_empty():
			var entrada := _criar_carta_overlay(String(nova.tipo), 0, VOO_BAG_TAM,
				_casas_bag[0].position + Vector2(-26, 0))
			entrada.modulate.a = 0.0
			voando.append(entrada)
			t.tween_property(entrada, "position", _casas_bag[0].position, duracao) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			t.tween_property(entrada, "modulate:a", 1.0, duracao * 0.72)
	else:
		for i in range(1, _casas_bag.size()):
			if String(antigos[i].tipo) == "":
				continue
			var icone := _criar_carta_overlay(String(antigos[i].tipo), 0,
				VOO_BAG_TAM, _casas_bag[i].position)
			voando.append(icone)
			t.tween_property(icone, "position", _casas_bag[i - 1].position, duracao) \
				.set_delay(float(_casas_bag.size() - i) * 0.008) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var nova := _item_visual_bag(fila, _casas_bag.size() - 1)
		if not nova.is_empty():
			var entrada := _criar_carta_overlay(String(nova.tipo), 0, VOO_BAG_TAM,
				NEXT_CASA.position)
			voando.append(entrada)
			t.tween_property(entrada, "position", _casas_bag[-1].position, duracao) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await t.finished
	for icone: CardIcon in voando:
		icone.queue_free()
	_atualizar_fila(fila)


func _anim_selecao(ev: Dictionary) -> void:
	var slot := int(ev.slot)
	var casa := _casas_campo[slot]
	_sfx.toque(_pitch_chain())
	casa.definir_selecionada(true)
	await _espera(0.07)


func _anim_deselecao(ev: Dictionary) -> void:
	var slot := int(ev.slot)
	var casa := _casas_campo[slot]
	_sfx.toque(_pitch_chain() * 0.88)
	casa.definir_selecionada(false)
	casa.position = _pos_casa(slot)
	casa.visible = true
	await _espera(0.07)


# A primeira e a segunda selecao puxam NEXT para a sexta casa da fileira.
# A carta que viaja e exatamente a ultima carta visivel a direita da BAG.
func _anim_desce(ev: Dictionary) -> void:
	var slot := int(ev.slot)
	_casas_campo[slot].position = _pos_casa(slot)
	var destino := _centro_casa(slot)
	_sfx.descida(_pitch_chain())
	await _voar(ev.carta, _centro_next(), destino, _tempo_chain(DUR_QUEDA),
		VOO_BAG_TAM, CAMPO_TAM, 42.0)
	_casas_campo[slot].visible = true
	_casas_campo[slot].mostrar(String(ev.carta.tipo), int(ev.carta.valor), false)
	await _animar_fila(ev.fila, 1, _tempo_chain(DUR_BAG_DESLIZE))


func _anim_volta(ev: Dictionary) -> void:
	var slot := int(ev.slot)
	var carta := {"tipo": _casas_campo[slot].tipo_atual(),
		"valor": _casas_campo[slot].valor_atual()}
	_casas_campo[slot].limpar()
	if String(carta.tipo) != "":
		_sfx.descida(_pitch_chain() * 0.86)
		await _voar(carta, _centro_casa(slot), _centro_next(), _tempo_chain(DUR_QUEDA),
			CAMPO_TAM, VOO_BAG_TAM, 42.0)
	await _animar_fila(ev.fila, -1, _tempo_chain(DUR_BAG_DESLIZE))
	_entrada_origem_visual.erase(slot)
	_casas_campo[slot].visible = true


func _anim_abandono() -> void:
	for i in _casas_campo.size():
		var casa := _casas_campo[i]
		casa.definir_selecionada(false)
		casa.position = _pos_casa(i)
	await _espera(0.08)


# A cascata puxou a carta do topo do saco para completar o trio.
func _anim_puxa(ev: Dictionary) -> void:
	await _animar_fila(ev.fila, 1, _tempo_chain(DUR_BAG_DESLIZE))


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
			de = _casas_campo[slot].centro_carta_no_canvas()
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
	var dur_alinhar := _tempo_chain(DUR_FUSAO_ALINHAR)
	for i in icones.size():
		var destino := FUSAO_CENTRO + Vector2((float(i) - 1.0) * FUSAO_PASSO, 0)
		var destino_pos := destino - FUSAO_TAM / 2.0
		chegada.tween_method(_mover_control_round.bind(icones[i], icones[i].position,
			destino_pos), 0.0, 1.0, dur_alinhar) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await chegada.finished
	var fundir := create_tween().set_parallel()
	var dur_convergir := _tempo_chain(DUR_FUSAO_CONVERGIR)
	_sfx.fusao(_pitch_chain())
	for icone: CardIcon in icones:
		fundir.tween_method(_mover_control_round.bind(icone, icone.position,
			FUSAO_CENTRO - FUSAO_TAM / 2.0), 0.0, 1.0, dur_convergir) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await fundir.finished
	await _pulso_fusao(tipo_fusao)
	_piscar_tela()
	for icone: CardIcon in icones:
		icone.queue_free()
	for i in _casas_campo.size():
		_casas_campo[i].position = _pos_casa(i)


func _pulso_fusao(tipo: String) -> void:
	var velocidade := _velocidade_chain()
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
			0.0, 1.0, 0.42 / velocidade).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		pt.tween_property(pixel, "modulate:a", 0.0, 0.42 / velocidade)
	var t := create_tween().set_parallel()
	t.tween_property(nucleo, "modulate:a", 0.0, 0.16 / velocidade)
	# O grupo so pode sair depois do rastro mais longo; caso contrario uma
	# chain acelerada libera os pixels enquanto seus tweens ainda escrevem neles.
	await _espera(0.46 / velocidade)
	grupo.queue_free()


func _anim_combo(ev: Dictionary) -> void:
	var cadeia := int(ev.cadeia)
	_chain_visual = maxi(_chain_visual, cadeia)
	var txt := "COMBO" if cadeia == 0 else "COMBO x%d" % (cadeia + 1)
	if bool(ev.critico):
		txt = "CRITICO! " + txt
	if bool(ev.get("todos", false)):
		txt = "WILD! " + txt
	elif bool(ev.cura):
		txt = "CURA " + txt
	_flutuar(txt, FUSAO_CENTRO + Vector2(0, -72), 20)
	var cargas: Array = ev.get("cargas", [])
	if bool(ev.get("todos", false)):
		_sfx.ataque_wild(_pitch_chain())
	if not cargas.is_empty() or bool(ev.cura):
		_sfx.contagem(_pitch_chain())
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
	await _espera(_tempo_chain(ESPERA_ENTRE_COMBOS))
	# O proximo trio da cascata ja nasce mais rapido. O teto impede que a
	# leitura visual se perca mesmo em correntes que atravessem varias maos.
	_chain_visual = cadeia + 1


func _anim_energia(tipo: String, de: Vector2, para: Vector2) -> void:
	var fluxo := FusionStream.new()
	_voos.add_child(fluxo)
	var velocidade := _velocidade_chain()
	fluxo.iniciar(tipo, de, para, velocidade)
	await fluxo.finalizado
	await _pulso_impacto(para, velocidade)


func _mover_control_round(f: float, item: Control, de: Vector2, para: Vector2) -> void:
	item.position = de.lerp(para, f).round()


func _pulso_impacto(posicao: Vector2, velocidade := 1.0) -> void:
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
	t.tween_property(impacto, "scale", Vector2(1.7, 1.7), 0.16 / velocidade) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(impacto, "modulate:a", 0.0, 0.16 / velocidade) \
		.set_delay(0.04 / velocidade)
	await t.finished
	impacto.queue_free()


func _anim_renovacao() -> void:
	_flutuar("RENOVACAO", Vector2(CANVAS.x / 2.0, CAMPO_LINHAS[0] - 40.0), 24)
	await _espera(_tempo_chain(0.12))


func _anim_nova_carta(ev: Dictionary) -> void:
	var slot := int(ev.slot)
	var destino := _centro_casa(slot)
	var chuva := bool(ev.get("chuva", false))
	var duracao := _tempo_chain(DUR_QUEDA * (0.68 if chuva else 1.0)) \
		/ DISTRIBUICAO_FINAL_ACELERACAO
	_sfx.descida(_pitch_chain())
	await _voar(ev.carta, _centro_next(), destino, duracao,
		VOO_BAG_TAM, CAMPO_TAM, 36.0)
	_casas_campo[slot].visible = true
	_casas_campo[slot].mostrar(String(ev.carta.tipo), int(ev.carta.valor), false)
	await _animar_fila(ev.fila, 1,
		_tempo_chain(DUR_BAG_DESLIZE * (0.68 if chuva else 1.0)) \
		/ DISTRIBUICAO_FINAL_ACELERACAO)
	await _espera((DUR_CHUVA if chuva else 0.01) / DISTRIBUICAO_FINAL_ACELERACAO)


func _anim_entra_na_mao(ev: Dictionary) -> void:
	var de := int(ev.de)
	var para := int(ev.para)
	var destino := _centro_casa(para)
	var origem := _centro_casa(de)
	var tipo := _casas_campo[de].tipo_atual()
	var valor := _casas_campo[de].valor_atual()
	_casas_campo[de].limpar()
	# A carta da entrada passa para uma das cinco casas jogaveis da fileira.
	if tipo != "":
		await _voar({"tipo": tipo, "valor": valor},
			origem, destino, _tempo_chain(DUR_VOO) / DISTRIBUICAO_FINAL_ACELERACAO,
			CAMPO_TAM, CAMPO_TAM, 24.0)
		_casas_campo[para].mostrar(tipo, valor, false)
		_casas_campo[para].visible = true
	_entrada_origem_visual.erase(de)
	_casas_campo[de].visible = true


func _anim_redistribuicao(ev: Dictionary) -> void:
	var m: Array = ev.mao
	_entrada_origem_visual.clear()
	_sfx.embaralhar(_pitch_chain())
	var destinos: Dictionary = {}
	for i in mini(EstadoBatalha.TAMANHO_MAO, m.size()):
		if m[i] == null:
			continue
		var chave := "%s:%d" % [String(m[i].tipo), int(m[i].valor)]
		if not destinos.has(chave):
			destinos[chave] = []
		(destinos[chave] as Array).append(i)

	var voando: Array[CardIcon] = []
	var movimentos: Array[Dictionary] = []
	for i in _casas_campo.size():
		var casa := _casas_campo[i]
		var tipo := casa.tipo_atual()
		if tipo == "":
			continue
		var valor := casa.valor_atual()
		var chave := "%s:%d" % [tipo, valor]
		if not destinos.has(chave) or (destinos[chave] as Array).is_empty():
			continue
		var destino_idx := int((destinos[chave] as Array).pop_front())
		var icone := _criar_carta_overlay(tipo, valor, CAMPO_TAM,
			casa.posicao_carta_no_canvas())
		voando.append(icone)
		movimentos.append({"icone": icone, "de": icone.position,
			"para": _pos_casa(destino_idx), "ordem": i})

	for casa: FieldSlot in _casas_campo:
		casa.limpar()
		casa.visible = true

	if not movimentos.is_empty():
		var t := create_tween().set_parallel()
		var velocidade_embaralhar := maxf(_velocidade_chain(), EMBARALHAR_VELOCIDADE_MIN)
		var duracao_embaralhar := DUR_EMBARALHAR / velocidade_embaralhar \
			/ DISTRIBUICAO_FINAL_ACELERACAO
		for movimento: Dictionary in movimentos:
			var altura := 22.0 + float(int(movimento.ordem) % 3) * 5.0
			t.tween_method(_mover_control_arco.bind(movimento.icone,
				movimento.de, movimento.para, altura), 0.0, 1.0, duracao_embaralhar) \
				.set_delay(float(int(movimento.ordem) % 5) * 0.010 \
				/ velocidade_embaralhar / DISTRIBUICAO_FINAL_ACELERACAO) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await t.finished
	for icone: CardIcon in voando:
		icone.queue_free()

	for i in EstadoBatalha.TAMANHO_MAO:
		if i >= m.size() or m[i] == null:
			_casas_campo[i].limpar()
		else:
			_casas_campo[i].mostrar(String(m[i].tipo), int(m[i].valor), false)
	for i in range(EstadoBatalha.TAMANHO_MAO, _casas_campo.size()):
		_casas_campo[i].visible = true
		_casas_campo[i].position = _pos_casa(i)
		_casas_campo[i].limpar()
	await _espera(0.08)


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
