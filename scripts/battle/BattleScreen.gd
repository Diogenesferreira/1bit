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

# --- casas ------------------------------------------------------------
# A BAG tem respiro proprio dentro da moldura; nao precisa compartilhar o
# alinhamento da HAND, cuja grade ocupa toda a largura disponivel.
const BAG_X0 := 50.0
const BAG_Y := 978.0
const BAG_PASSO := 88.0
const NEXT_CASA := Rect2(819, 978, 78, 108)

# Grade do Designer (spec/layout_batalha.json): 6 col x 138, gap 12, 2 lin x
# 191, gap 12 -> 888 x 394 exatos, centrada na coluna de conteudo.
const CAMPO_TAM := Vector2(138, 191)
const CAMPO_X0 := 27.0
const CAMPO_PASSO := 150.0
const CAMPO_LINHAS := [1152.0, 1355.0]
const CAMPO_ICONE := 138.0
const ENTRADA_TAM := CAMPO_TAM
const FUSAO_CENTRO := Vector2(471, 1349)
const VOO_BAG_TAM := Vector2(78, 108)
const VOO_BAG_ICONE := 78.0
const FUSAO_TAM := CAMPO_TAM
const FUSAO_ICONE := CAMPO_ICONE
const FUSAO_PASSO := 148.0

# --- HUD --------------------------------------------------------------
# Centro vertical do espaco entre o divisor da HAND (y=1561) e a moldura
# interna inferior (y=1673): 44 px de respiro em cima e embaixo.
# hp_row do JSON: y 19 + 1541, pad-top 14 -> barra em 1574; largura = conteudo.
const LIFE_POSITION := Vector2(27, 1574)
const LIFE_WIDTH := 888

var estado: EstadoBatalha

var _arena: Control
var _cenario: TextureRect
var _inimigos: Array[EnemyUnit] = []
var _aliados: Array[AllyUnit] = []
var _casas_bag: Array[BagSlot] = []
var _icone_next: CardIcon
var _casas_campo: Array[FieldSlot] = []
var _sfx: BattleSfx

var _top_bar: TopBar
var _stage_plate: StagePlate
var _life_bar: PlayerLifeBar
var _flash: ColorRect
var _voos: Control  # camada das cartas em transito

var _animando := false
var _shake_ms := -100000
var _shake_amp := 5.0
var _chain_visual := 0
var _dano_visual_acumulado: Dictionary = {}
var _total_por_alvo: Dictionary = {}
var _entrada_origem_visual: Dictionary = {}
var _vertical_extra := 0.0


func _ready() -> void:
	# No Android, garanta em runtime a mesma politica configurada no projeto.
	# Telas mais altas preservam a largura logica e ampliam o campo de batalha.
	var window := get_window()
	window.content_scale_size = Vector2i(CANVAS)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	_vertical_extra = maxf(0.0, get_viewport_rect().size.y - CANVAS.y)
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
	arena.size = Unidades.ARENA_TAM + Vector2(0, _vertical_extra)
	arena.clip_contents = true
	arena.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(arena)
	_arena = arena
	_cenario = _criar_cenario(estado.estagio)
	arena.add_child(_cenario)
	_montar_scrim(arena)
	_moldura_arena(Rect2(0, 0, 888, 558 + _vertical_extra), arena)
	_montar_progresso_palco(arena)
	_montar_faixa_aliados(arena)

	_construir_inimigos()
	for i in estado.aliados.size():
		var d: Dictionary = estado.aliados[i]
		var a := AllyUnit.new()
		arena.add_child(a)
		a.montar(d, i)
		a.position.y += _vertical_extra
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

	# Flash de tela: overlay bone que aparece e some (spec/PALETA: #f4ecd8),
	# nao mais a inversao dura do prototipo.
	_flash = ColorRect.new()
	_flash.name = "ScreenFlash"
	_flash.z_index = 200
	_flash.color = Color("f4ecd8")
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.modulate.a = 0.0
	_flash.visible = false
	add_child(_flash)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _asset_altura(arquivo: String, pos: Vector2, altura: float, pai: Node,
		alpha := 1.0) -> TextureRect:
	var textura := Arte.tex(arquivo)
	var largura: float = roundf(float(textura.get_width()) * altura / float(textura.get_height()))
	var imagem := Arte.imagem(arquivo, Rect2(pos.round(), Vector2(largura, altura)), pai)
	imagem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	imagem.modulate.a = alpha
	return imagem


func _montar_progresso_palco(arena: Control) -> void:
	_stage_plate = StagePlate.new()
	_stage_plate.name = "StagePlate"
	_stage_plate.position = Vector2(22, 504 + _vertical_extra)
	_stage_plate.stage = estado.estagio
	_stage_plate.stage_total = estado.estagios_totais
	arena.add_child(_stage_plate)


func _criar_cenario(estagio: int) -> TextureRect:
	var c := TextureRect.new()
	c.name = "BattleBackground"
	c.texture = Arte.backdrop(estagio)
	c.position = Vector2.ZERO
	c.size = Vector2(888, 558 + _vertical_extra)
	c.stretch_mode = TextureRect.STRETCH_SCALE
	c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	c.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


# (Re)cria os nos de inimigo a partir de estado.inimigos. Chamado na montagem
# e a cada troca de estagio.
func _construir_inimigos() -> void:
	for u: EnemyUnit in _inimigos:
		u.queue_free()
	_inimigos.clear()
	var stage_scale := (558.0 + _vertical_extra) / 558.0
	for i in estado.inimigos.size():
		var d: Dictionary = estado.inimigos[i]
		var u := EnemyUnit.new()
		_arena.add_child(u)
		u.montar(d, i, estado.inimigos.size())
		u.position.y = round(u.position.y * stage_scale)
		u.tocado.connect(_ao_tocar_inimigo)
		_inimigos.append(u)


# Flash bone, troca o conjunto de inimigos perto do pico, atualiza a trilha.
func _anim_troca_estagio(ev: Dictionary) -> void:
	var fl := ColorRect.new()
	fl.color = Color("f4ecd8")
	fl.z_index = 190
	fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fl)
	fl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fl.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(fl, "modulate:a", 0.85, 0.06) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(fl, "modulate:a", 0.0, 0.39) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await _espera(0.12)
	_construir_inimigos()
	# Crossfade do backdrop: o novo entra por cima do antigo, ainda atras
	# dos inimigos, e o antigo sai depois de 600 ms.
	if _cenario != null and _arena != null:
		var novo := _criar_cenario(estado.estagio)
		novo.modulate.a = 0.0
		_arena.add_child(novo)
		_arena.move_child(novo, 1)
		var antigo := _cenario
		_cenario = novo
		var ct := create_tween()
		ct.tween_property(novo, "modulate:a", 1.0, 0.6)
		ct.tween_callback(antigo.queue_free)
	if _stage_plate != null:
		_stage_plate.set_stage(int(ev.get("estagio", estado.estagio)),
			int(ev.get("estagios_totais", estado.estagios_totais)))
	_atualizar_hud()
	await t.finished
	fl.queue_free()


# Scrim do palco (spec/layout_batalha.json): escurece de leve o topo e mais
# o rodape, pra assentar as unidades sobre qualquer backdrop.
func _montar_scrim(arena: Control) -> void:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	grad.colors = PackedColorArray([
		Color(0.031, 0.035, 0.031, 0.15),
		Color(0.031, 0.035, 0.031, 0.05),
		Color(0.031, 0.035, 0.031, 0.55)])
	var gtex := GradientTexture2D.new()
	gtex.gradient = grad
	gtex.fill_from = Vector2(0, 0)
	gtex.fill_to = Vector2(0, 1)
	gtex.width = 8
	gtex.height = 96
	var tr := TextureRect.new()
	tr.name = "StageScrim"
	tr.texture = gtex
	tr.position = Vector2.ZERO
	tr.size = Vector2(888, 558 + _vertical_extra)
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arena.add_child(tr)


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
	var bottom := logica.size.y - 22.0
	var pontos := [Vector2(6, 6), Vector2(866, 6), Vector2(6, bottom), Vector2(866, bottom)]
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
	faixa.position = Vector2(0, 607 + _vertical_extra)
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
	painel.position = Vector2(25, _screen_y(947))
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
	aba_bag.position = Vector2(37, _screen_y(936))
	aba_bag.size = Vector2(60, 22)
	aba_bag.color = Color("0d0e0c")
	aba_bag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(aba_bag)
	_asset_altura("ui_v10/ui/lbl_bag.png", Vector2(43, _screen_y(936)), 20, self)
	var cena := load("res://scenes/battle/BagSlot.tscn") as PackedScene
	for i in EstadoBatalha.BAG_VISIVEL:
		var casa := cena.instantiate() as BagSlot
		casa.indice = i
		casa.position = Vector2(BAG_X0 + float(i) * BAG_PASSO, _screen_y(BAG_Y))
		add_child(casa)
		_casas_bag.append(casa)

	var divisor := ColorRect.new()
	divisor.position = Vector2(781, _screen_y(965))
	divisor.size = Vector2(2, 124)
	divisor.color = Color(0.79, 0.75, 0.66, 0.25)
	add_child(divisor)
	_asset_altura("ui_v10/ui/lbl_next.png", Vector2(836, _screen_y(955)), 14, self, 0.8)
	_icone_next = CardIcon.new()
	_icone_next.name = "NextCard"
	add_child(_icone_next)
	_icone_next.configurar(NEXT_CASA.size, BagSlot.LADO_ICONE, 0, false, 0.3, 13)
	_icone_next.fixar_em(_next_rect().position)


func _montar_area_hand() -> void:
	# HAND nao e um painel fechado: este Control serve somente de base para
	# o divisor entre as cartas e o HP. A unica linha superior nasce no D.
	var painel := Control.new()
	painel.name = "HandPanel"
	painel.position = Vector2(25, _screen_y(1115))
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
	_asset_altura("ui_v10/ui/lbl_hand.png", Vector2(31, _screen_y(1118)), 24, self)
	var regra := ColorRect.new()
	# Regua centralizada na altura visual de HAND: 10 px apos o rotulo e
	# terminando 10 px antes da borda direita do painel.
	regra.position = Vector2(116, _screen_y(1130))
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
	_top_bar = TopBar.new()
	_top_bar.name = "TopBar"
	_top_bar.position = Vector2(27, 19)
	_top_bar.row_width = 886
	add_child(_top_bar)


func _montar_hud_rodape() -> void:
	_life_bar = PlayerLifeBar.new()
	_life_bar.name = "PlayerLifeBar"
	_life_bar.position = LIFE_POSITION + Vector2(0, _vertical_extra)
	_life_bar.row_width = LIFE_WIDTH
	_life_bar.hp_max = estado.hp_max
	_life_bar.hp_current = estado.hp
	add_child(_life_bar)


# ------------------------------------------------------------ posicoes

func _screen_y(base_y: float) -> float:
	return base_y + _vertical_extra


func _next_rect() -> Rect2:
	return Rect2(NEXT_CASA.position + Vector2(0, _vertical_extra), NEXT_CASA.size)


func _fusion_center() -> Vector2:
	return FUSAO_CENTRO + Vector2(0, _vertical_extra)


func _pos_casa(idx: int) -> Vector2:
	var linha: int
	var coluna: int
	if idx < EstadoBatalha.TAMANHO_MAO:
		linha = idx / EstadoBatalha.ROW_SIZE
		coluna = idx % EstadoBatalha.ROW_SIZE
	else:
		linha = idx - EstadoBatalha.TAMANHO_MAO
		coluna = EstadoBatalha.ROW_SIZE
		return Vector2(CAMPO_X0 + float(coluna) * CAMPO_PASSO,
			_screen_y(CAMPO_LINHAS[linha]))
	return Vector2(CAMPO_X0 + float(coluna) * CAMPO_PASSO,
		_screen_y(CAMPO_LINHAS[linha]))


func _centro_casa(idx: int) -> Vector2:
	return _pos_casa(idx) + _casas_campo[idx].size / 2.0


func _centro_next() -> Vector2:
	return _next_rect().get_center()


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
		var d: Dictionary = estado.inimigos[i] if i < estado.inimigos.size() else {}
		u.definir_turno(int(d.get("turno", estado.contador_inimigo)),
			int(d.get("turno_max", estado.contador_inimigo_max)))
		u.definir_selecionado(i == estado.alvo_selecionado)
	for a: AllyUnit in _aliados:
		a.atualizar()

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
	_total_por_alvo.clear()
	for u: EnemyUnit in _inimigos:
		u.definir_total(0)
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
			"troca_estagio": await _anim_troca_estagio(ev)

	if res.has("ataque_inimigo"):
		await _anim_ataque_inimigo(int(res.ataque_inimigo))

	_animando = false
	_sincronizar()
	if estado.fim:
		_anunciar_fim()


func _espera(s: float) -> void:
	await get_tree().create_timer(s).timeout


# Tremor de tela por leitura de relogio (amp 5, 380 ms) - ANIMACOES_V2 secao 2.
func _tremor_tela() -> void:
	_shake_ms = Time.get_ticks_msec()


func _process(_delta: float) -> void:
	var dt := Time.get_ticks_msec() - _shake_ms
	if dt < 380:
		var decay := 1.0 - float(dt) / 380.0
		var p := float(dt) / 34.0
		position = Vector2(sin(p * 3.1) * _shake_amp * decay,
			cos(p * 4.7) * _shake_amp * 0.45 * decay).round()
	elif position != Vector2.ZERO:
		position = Vector2.ZERO


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
				_next_rect().position)
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
	var centro := _fusion_center()
	var vel := _velocidade_chain()

	# --- fase 1/2: as 3 sobem, vao pro centro lado a lado, leque -6/0/+6 ---
	var icones: Array[CardIcon] = []
	var leque := create_tween().set_parallel()
	var dur_leque := _tempo_chain(0.49)
	for i in cartas.size():
		var off := float(i) - 1.0
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
		icone.pivot_offset = FUSAO_TAM / 2.0
		icone.fixar_em(de - FUSAO_TAM / 2.0)
		icone.mostrar(String(cartas[i].tipo), int(cartas[i].valor), false)
		icones.append(icone)
		var destino := centro + Vector2(off * 88.0, 0) - FUSAO_TAM / 2.0
		leque.tween_method(_mover_control_round.bind(icone, icone.position, destino),
			0.0, 1.0, dur_leque).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		leque.tween_property(icone, "rotation", deg_to_rad(off * -6.0), dur_leque) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await leque.finished

	# --- fase 3: leque zera, empilha (+-10), brilho radial cresce atras ---
	var glow := _glow_fusao(centro, tipo_fusao)
	var aquece := create_tween().set_parallel()
	var dur_aquece := _tempo_chain(0.42)
	_sfx.fusao(_pitch_chain())
	for i in icones.size():
		var off := float(i) - 1.0
		var alvo := centro + Vector2(off * 10.0, 0) - FUSAO_TAM / 2.0
		aquece.tween_method(_mover_control_round.bind(icones[i], icones[i].position, alvo),
			0.0, 1.0, dur_aquece).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		aquece.tween_property(icones[i], "rotation", 0.0, dur_aquece)
		aquece.tween_property(icones[i], "modulate", Color(2.6, 2.6, 2.6, 1.0), dur_aquece)
	aquece.tween_property(glow, "size", Vector2(190, 220), dur_aquece)
	aquece.tween_property(glow, "position", centro - Vector2(95, 110), dur_aquece)
	await aquece.finished

	# --- fase 4: estouro ---
	_piscar_tela()
	_tremor_tela()
	_sfx.contagem(_pitch_chain())
	var punch := create_tween().set_parallel()
	for icone: CardIcon in icones:
		punch.tween_property(icone, "position", centro - FUSAO_TAM / 2.0, 0.10 / vel)
		punch.tween_property(icone, "scale", Vector2(1.18, 1.18), 0.10 / vel)
	await punch.finished
	await _estouro_fusao(centro, tipo_fusao, vel)

	# --- fase 5: cartas somem, feixe vertical sobe da mao ---
	var some := create_tween().set_parallel()
	for icone: CardIcon in icones:
		some.tween_property(icone, "modulate:a", 0.0, 0.18 / vel)
	some.tween_property(glow, "modulate:a", 0.0, 0.3 / vel)
	_feixe_fusao(centro, tipo_fusao, vel)
	await some.finished
	for icone: CardIcon in icones:
		icone.queue_free()
	glow.queue_free()
	for i in _casas_campo.size():
		_casas_campo[i].position = _pos_casa(i)


# Mancha radial atras do maco durante o aquecimento.
func _glow_fusao(centro: Vector2, tipo: String) -> Panel:
	var g := Panel.new()
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.size = Vector2(70, 90)
	g.position = centro - g.size / 2.0
	var est := StyleBoxFlat.new()
	est.bg_color = Color(0, 0, 0, 0)
	var cor := Arte.cor_elemental_clara(tipo)
	est.shadow_color = Color(cor.r, cor.g, cor.b, 0.6)
	est.shadow_size = 26
	est.set_corner_radius_all(40)
	g.add_theme_stylebox_override("panel", est)
	_voos.add_child(g)
	_voos.move_child(g, 0)
	return g


# Nucleo radial 230 + 2 ondas de choque + 12 estilhacos.
func _estouro_fusao(centro: Vector2, tipo: String, vel: float) -> void:
	var cor := Arte.cor_elemental(tipo)
	var lit := Arte.cor_elemental_clara(tipo)
	var nucleo := Panel.new()
	nucleo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nucleo.size = Vector2(230, 230)
	nucleo.position = centro - Vector2(115, 115)
	nucleo.pivot_offset = Vector2(115, 115)
	nucleo.scale = Vector2(0.3, 0.3)
	var ne := StyleBoxFlat.new()
	ne.bg_color = Arte.BRANCO
	ne.border_color = cor.lerp(Arte.BRANCO, 0.35)
	ne.set_border_width_all(4)
	ne.set_corner_radius_all(115)
	ne.shadow_color = Color(lit.r, lit.g, lit.b, 0.8)
	ne.shadow_size = 30
	nucleo.add_theme_stylebox_override("panel", ne)
	_voos.add_child(nucleo)
	var tn := create_tween().set_parallel()
	tn.tween_property(nucleo, "scale", Vector2(1.0, 1.0), 0.20 / vel) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tn.tween_property(nucleo, "modulate:a", 0.0, 0.34 / vel).set_delay(0.06 / vel)

	for onda in 2:
		var anel := Panel.new()
		anel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		anel.size = Vector2(120, 120)
		anel.position = centro - Vector2(60, 60)
		anel.pivot_offset = Vector2(60, 60)
		var ae := StyleBoxFlat.new()
		ae.bg_color = Color(0, 0, 0, 0)
		ae.border_color = lit if onda == 0 else Arte.BRANCO
		ae.set_border_width_all(3)
		ae.set_corner_radius_all(60)
		anel.add_theme_stylebox_override("panel", ae)
		_voos.add_child(anel)
		var ta := create_tween().set_parallel()
		ta.tween_property(anel, "scale", Vector2(2.6, 2.6), 0.55 / vel) \
			.set_delay(float(onda) * 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		ta.tween_property(anel, "modulate:a", 0.0, 0.55 / vel).set_delay(float(onda) * 0.08)
		ta.chain().tween_callback(anel.queue_free)

	for i in 12:
		var frag := ColorRect.new()
		frag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frag.size = Vector2(6, 6)
		var ang := deg_to_rad(float(i) * 30.0)
		var raio := 95.0 + float(i % 3) * 25.0
		frag.color = (lit if i % 2 else cor)
		frag.position = centro - Vector2(3, 3)
		_voos.add_child(frag)
		var destino := centro + Vector2(cos(ang), sin(ang)) * raio - Vector2(3, 3)
		var tf := create_tween().set_parallel()
		tf.tween_method(_mover_control_round.bind(frag, frag.position, destino),
			0.0, 1.0, 0.5 / vel).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tf.tween_property(frag, "modulate:a", 0.0, 0.5 / vel)
		tf.chain().tween_callback(frag.queue_free)

	await _espera(0.34 / vel)
	nucleo.queue_free()


# Feixe vertical 28x300 que sobe do centro da mao (fase 5).
func _feixe_fusao(centro: Vector2, tipo: String, vel: float) -> void:
	var feixe := ColorRect.new()
	feixe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feixe.color = Arte.cor_elemental_clara(tipo)
	feixe.size = Vector2(28, 300)
	feixe.position = centro - Vector2(14, 300)
	_voos.add_child(feixe)
	var t := create_tween()
	t.tween_property(feixe, "modulate:a", 0.0, 0.5 / vel).from(0.9)
	t.tween_callback(feixe.queue_free)


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
	_flutuar(txt, _fusion_center() + Vector2(0, -72), 20)
	var cargas: Array = ev.get("cargas", [])
	if bool(ev.get("todos", false)):
		_sfx.ataque_wild(_pitch_chain())
	if not cargas.is_empty() or bool(ev.cura):
		_sfx.contagem(_pitch_chain())
	for carga: Dictionary in cargas:
		var atacante := int(carga.atacante)
		if atacante < 0 or atacante >= _aliados.size():
			continue
		await _anim_energia(String(ev.tipo_carta), _fusion_center(),
			_aliados[atacante].centro_no_canvas())
		_aliados[atacante].adicionar_carga(int(carga.get("skill_incremento", 1)))
		_aliados[atacante].piscar()
		var total := int(_dano_visual_acumulado.get(atacante, 0)) + int(carga.get("valor", 0))
		_dano_visual_acumulado[atacante] = total
		var tipo_aliado := String(_aliados[atacante].dados.def.elemento)
		_flutuar_placa("+%d" % total,
			_aliados[atacante].centro_no_canvas() + Vector2(0, -74), tipo_aliado)
	if bool(ev.cura):
		await _anim_energia("capsule", _fusion_center(), Vector2(50, _screen_y(1635)))
	# Chip TOTAL no alvo: soma do que a corrente vai bater nele.
	var alvo := int(ev.get("alvo", -1))
	if alvo >= 0 and alvo < _inimigos.size() and not bool(ev.cura):
		var soma_elo := 0
		for carga: Dictionary in cargas:
			soma_elo += int(carga.get("valor", 0))
		var total_alvo := int(_total_por_alvo.get(alvo, 0)) + soma_elo
		_total_por_alvo[alvo] = total_alvo
		_inimigos[alvo].definir_total(total_alvo)
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
	_flutuar("RENOVACAO", Vector2(CANVAS.x / 2.0, _screen_y(CAMPO_LINHAS[0] - 40.0)), 24)
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
	var lane := 0
	for golpe: Dictionary in ev.golpes:
		var alvo := int(golpe.alvo)
		_inimigos[alvo].piscar()
		_inimigos[alvo].tremer(int(golpe.get("hp", 1)) > 0)
		_inimigos[alvo].definir_total(0)
		var centro := _inimigos[alvo].centro_no_canvas()
		# Um impacto + um numero por elemento que bateu, cada um na sua cor,
		# espalhado em 8 posicoes (SCATTER), passo de 90 ms. Dano ja veio
		# somado da regra (C7).
		var parcelas: Array = golpe.get("parcelas",
			[{"tipo": String(golpe.get("tipo", "light")), "dano": int(golpe.dano)}])
		for parc: Dictionary in parcelas:
			var impacto := ElementImpact.new()
			_voos.add_child(impacto)
			impacto.iniciar(String(parc.tipo), centro)
			_dano_subindo("-%d" % int(parc.dano), centro, String(parc.tipo), lane)
			lane += 1
			await _espera(0.09)
	if int(ev.cura_total) > 0:
		_flutuar("+%d" % int(ev.cura_total), Vector2(120, _screen_y(1615)), 22)
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
	_flutuar("-%d" % dano, Vector2(180, _screen_y(1640)), 24)
	_atualizar_hud()
	await _espera(0.35)
func _piscar_tela() -> void:
	_flash.visible = true
	var t := create_tween()
	t.tween_property(_flash, "modulate:a", 0.85, 0.45 * 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(_flash, "modulate:a", 0.0, 0.45 * 0.88) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(func() -> void: _flash.visible = false)


# Texto que sobe e some. Sempre branco: a paleta so tem dois tons.
func _flutuar(txt: String, pos: Vector2, tamanho: int) -> void:
	var l := Arte.rotulo(txt, Vector2.ZERO, tamanho, Arte.TEXTO_NO_ESCURO, 460.0, true, self)
	l.position = pos - Vector2(230, 0)
	var t := create_tween().set_parallel()
	t.tween_property(l, "position:y", l.position.y - 46.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.25)
	await t.finished
	l.queue_free()


# Numero de dano por elo, na cor do elemento, sobre placa opaca, numa das 8
# posicoes de SCATTER (spec/ANIMACOES_V2.md secao 3, curva b1Rise).
const POPUP_SCATTER := [
	Vector2(0, 14), Vector2(-19, 40), Vector2(17, 26), Vector2(-12, 58),
	Vector2(21, 52), Vector2(-24, 8), Vector2(9, 66), Vector2(-8, 82),
]

func _dano_subindo(txt: String, centro_inimigo: Vector2, tipo: String, lane: int) -> void:
	var sc: Vector2 = POPUP_SCATTER[lane % POPUP_SCATTER.size()]
	var lit := Arte.cor_elemental_clara(tipo)
	var tam := Vector2(float(txt.length()) * 15.0 + 16.0, 34.0)
	var placa := Control.new()
	placa.size = tam
	placa.pivot_offset = tam / 2.0
	placa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placa.z_index = 80
	add_child(placa)
	var bg := ColorRect.new()
	bg.color = Color(0.031, 0.035, 0.031, 0.82)
	bg.size = tam
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placa.add_child(bg)
	for r: Rect2 in [Rect2(0, 0, tam.x, 2), Rect2(0, tam.y - 2, tam.x, 2),
			Rect2(0, 0, 2, tam.y), Rect2(tam.x - 2, 0, 2, tam.y)]:
		var b := ColorRect.new()
		b.color = lit
		b.position = r.position
		b.size = r.size
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		placa.add_child(b)
	var l := Arte.rotulo(txt, Vector2(8, 4), 22, lit, tam.x - 16.0, true, placa)
	l.add_theme_color_override("font_shadow_color", Color("14140f"))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	var alvo_y := centro_inimigo.y - 30.0 - sc.y
	placa.position = Vector2(centro_inimigo.x + sc.x - tam.x / 2.0, alvo_y)
	placa.scale = Vector2(0.7, 0.7)
	var pop := create_tween()
	pop.tween_property(placa, "scale", Vector2(1.12, 1.12), 0.17) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(placa, "scale", Vector2.ONE, 0.13).set_trans(Tween.TRANS_QUAD)
	var t := create_tween().set_parallel()
	t.tween_property(placa, "position:y", alvo_y - 32.0, 0.6) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(placa, "modulate:a", 0.0, 0.42).set_delay(0.45)
	await t.finished
	placa.queue_free()


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
