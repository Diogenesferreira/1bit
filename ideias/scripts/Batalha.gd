extends Control

# A TELA de batalha, redesenhada em cima do pacote "Digital Arena"
# (novo_asset/design_mobile/entrega_godot/UI_SPEC.md, 2026-08-26) - a
# partir de agora a referencia visual do jogo. Ver [[dazzling-spinning-eagle]]
# (plano desta rodada) para o que ficou de fora por falta de sistema real
# por tras (topo decorativo, barra de skill, multi-inimigo).
#
# A divisao entre TELA e BattleLogic nao mudou: um toque devolve a
# corrente INTEIRA ja resolvida numa lista de eventos, e esta tela so
# reproduz esses eventos em ordem - nunca consulta o estado da logica
# durante a animacao. Enquanto uma corrente anima, toques sao ignorados
# (`_animando`).

const TELA := Vector2(1080, 1920)
const PAD := 24.0
const PAINEL_LARG := TELA.x - 2.0 * PAD  # 1032

# --------------------------------------------------------- faixas verticais
# UI_SPEC.md paragrafo 1: 8 faixas, de cima pra baixo, dentro de um
# padding externo de 24px. Os gaps de 16px entre elas estao embutidos nos
# proprios numeros (cada Y de inicio ja soma o gap da faixa anterior).
const TOPO_Y := 24.0
const TOPO_ALT := 96.0
const ARENA_Y := 136.0
const ARENA_ALT := 648.0
const AFFIN_Y := 784.0
const AFFIN_ALT := 64.0
const LIFE_Y := 864.0
const LIFE_ALT := 66.0
const FLOWBAG_Y := 946.0
const FLOWBAG_ALT := 186.0
const ATTACK_Y := 1148.0
const ATTACK_ALT := 684.0  # vai ate ~1832
const FOOTER_Y := 1848.0
const FOOTER_ALT := 56.0

# --------------------------------------------------------------- attack zone
# Grade 2x6 (5 da mao + 1 de ENTRADA por fileira), proporcao de carta
# 204:300, SEM sobreposicao (diferente do leque do tema anterior).
const ATTACK_HEADER_ALT := 52.0
const GRID_PAD := 16.0
const GRID_COLS := 6
const GRID_GAP := 8.0
const GRID_ROW_GAP := 16.0
const GRID_X0 := PAD + GRID_PAD
const GRID_Y0 := ATTACK_Y + ATTACK_HEADER_ALT + GRID_PAD
const GRID_W := PAINEL_LARG - 2.0 * GRID_PAD
const CARD_W := (GRID_W - float(GRID_COLS - 1) * GRID_GAP) / float(GRID_COLS)
const CARD_H := CARD_W * (300.0 / 204.0)
# a grade sobra espaco vertical na faixa (~684 de altura, ~480 usados);
# o resto vira respiro acima/abaixo dela, centralizado
const GRID_ALT_TOTAL := 2.0 * CARD_H + GRID_ROW_GAP
const GRID_FOLGA_Y := maxf(0.0, (ATTACK_ALT - ATTACK_HEADER_ALT - 2.0 * GRID_PAD - GRID_ALT_TOTAL) / 2.0)

# centro de fusao: meio das 5 colunas da mao (sem contar a de ENTRADA),
# entre as duas fileiras - e ali, DENTRO do proprio grid, que o trio se
# funde (diferente do tema anterior, que mandava as cartas ate o palco).
const CENTRO_FUSAO := Vector2(
	GRID_X0 + (5.0 * CARD_W + 4.0 * GRID_GAP) / 2.0,
	GRID_Y0 + GRID_FOLGA_Y + CARD_H + GRID_ROW_GAP / 2.0)

# ------------------------------------------------------------------ flowbag
# Fila reta de 9 cartas pequenas (BattleLogic.QTD_PROXIMAS). A mais a
# direita e proximas[0] - a proxima a descer pra ENTRADA.
const FLOWBAG_HEADER_ALT := 40.0
const FLOWBAG_LABEL_W := 36.0
const FLOWBAG_NEXT_W := 46.0
const FLOWBAG_CASA_GAP := 8.0
const FLOWBAG_CASA_H := FLOWBAG_ALT - FLOWBAG_HEADER_ALT - 2.0 * GRID_PAD
const FLOWBAG_CASA_W := FLOWBAG_CASA_H * (204.0 / 300.0)

# ---------------------------------------------------------------------- vars

var logica: BattleLogic

# slot da mao (0..11) -> no visual da carta que esta NA casa
var _nas_casas: Dictionary = {}
# slot de origem -> no visual da carta MARCADA (pairando acima da casa)
var _marcadas: Dictionary = {}
var _visuais_flowbag: Array[Control] = []
# cor -> quanto aquele aliado ja acumulou nesta corrente (zera no ataque)
var _acumulado: Dictionary = {}
# cor -> {"skill_trilho":Control largura maxima, "skill_fill":Control}
var _aliados: Dictionary = {}
# 1 elemento so por enquanto (BattleLogic ainda nao tem multi-inimigo -
# ver plano); a funcao de layout ja aceita Array pra quando existir.
var _inimigo_sprite: TextureRect
var _inimigo_barra_hp: Control
var _inimigo_label_hp: Label
var _inimigo_label_nivel: Label

var _animando := false

var _label_hp: Label
var _label_hp_max: Label
var _coracao_hp: TextureRect
var _fill_vida: Control
var _fill_vida_larg := 0.0
var _hp_mostrado := -1

var _label_round: Label
var _pips_round: Array[ColorRect] = []
var _label_status: Label

var _camada_cartas: Control
var _camada_efeitos: Control
var _botao_desfazer: Button


func _ready() -> void:
	logica = BattleLogic.new()
	_montar()
	_desenhar_mao_inteira()
	_atualizar_placar()


# ---------------------------------------------------------------- montagem

func _montar() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = TELA

	var fundo := ColorRect.new()
	fundo.color = Tema.FUNDO_PAGINA
	fundo.position = Vector2.ZERO
	fundo.size = TELA
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)

	_montar_topo()
	_montar_arena()
	_montar_affinity_round()
	_montar_life()
	_montar_flowbag_painel()
	# o painel (fundo branco) da ATTACK ZONE tem que existir ANTES de
	# _camada_cartas: senao ele desenha por cima das cartas da mao,
	# escondendo tudo atras de um retangulo branco solido.
	_montar_attack_header()

	_camada_cartas = Control.new()
	_camada_cartas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_camada_cartas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_camada_cartas)

	_camada_efeitos = Control.new()
	_camada_efeitos.set_anchors_preset(Control.PRESET_FULL_RECT)
	_camada_efeitos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_camada_efeitos)

	_montar_flowbag_cartas()
	_montar_footer()


# Cartao branco padrao ("console card") do design: fundo #F7F9FC, borda
# 2px, cantos arredondados, cantoneiras cyan nos 4 vertices. Devolve o
# Panel ja adicionado - quem chama poe o conteudo dentro, em coordenadas
# LOCAIS (0,0 = canto sup. esquerdo do painel).
func _painel_console(rect: Rect2, raio := 16, cantos := true) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var caixa := StyleBoxFlat.new()
	caixa.bg_color = Tema.PAINEL
	caixa.border_color = Tema.BORDA_PAINEL
	caixa.set_border_width_all(2)
	caixa.set_corner_radius_all(raio)
	p.add_theme_stylebox_override("panel", caixa)
	add_child(p)
	if cantos:
		_cantos_tecnicos(p, rect.size)
	return p


# 4 cantoneiras em L, decorativas, nos vertices do painel (spec: "2px
# cyan, 12-16px de lado, opacidade .55").
func _cantos_tecnicos(pai: Control, tamanho: Vector2) -> void:
	var l := 14.0
	var cor := Color(Tema.CYAN, 0.55)
	var cantos := [
		{"p": Vector2(0, 0), "sx": 1, "sy": 1},
		{"p": Vector2(tamanho.x, 0), "sx": -1, "sy": 1},
		{"p": Vector2(0, tamanho.y), "sx": 1, "sy": -1},
		{"p": Vector2(tamanho.x, tamanho.y), "sx": -1, "sy": -1},
	]
	for c: Dictionary in cantos:
		var origem: Vector2 = c.p
		var sx: int = c.sx
		var sy: int = c.sy
		var h := ColorRect.new()
		h.color = cor
		h.size = Vector2(l, 2)
		h.position = origem + Vector2(0 if sx > 0 else -l, 0 if sy > 0 else -2)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pai.add_child(h)
		var v := ColorRect.new()
		v.color = cor
		v.size = Vector2(2, l)
		v.position = origem + Vector2(0 if sx > 0 else -2, 0 if sy > 0 else -l)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pai.add_child(v)


# Tag flutuante tipo "LIFE"/"FLOWBAG"/"AFFINITY": chip navy com losango
# cyan antes do texto, saindo um pouco por cima da borda do painel.
func _tag_flutuante(texto: String, pos: Vector2) -> void:
	var chip := Panel.new()
	chip.position = pos
	var caixa := StyleBoxFlat.new()
	caixa.bg_color = Tema.TEXTO_PRIMARIO
	caixa.set_corner_radius_all(6)
	chip.add_theme_stylebox_override("panel", caixa)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(chip)

	var losango := ColorRect.new()
	losango.color = Tema.CYAN
	losango.size = Vector2(7, 7)
	losango.position = Vector2(8, 9)
	losango.rotation = deg_to_rad(45)
	losango.pivot_offset = Vector2(3.5, 3.5)
	losango.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(losango)

	var l := _texto_ui(texto, 12, Color.WHITE, 700)
	l.position = Vector2(20, 3)
	chip.add_child(l)
	chip.size = Vector2(20 + l.get_minimum_size().x + 8, 24)


# --------------------------------------------------------------------- topo
# Avatar + cartao do jogador (nome/nivel + XP) + 3 chips de recurso +
# botao de menu. Decorativo: nao existe perfil/moeda/energia de verdade
# no projeto ainda, os valores sao fixos (ver plano desta rodada).
func _montar_topo() -> void:
	var avatar := TextureRect.new()
	avatar.texture = Tema.icone_avatar()
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.position = Vector2(PAD, TOPO_Y)
	avatar.size = Vector2(104, TOPO_ALT)
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(avatar)

	var chip_w := 100.0
	var chip_gap := 8.0
	var menu_w := 96.0
	var cartao_x := PAD + 104.0 + 12.0
	var cartao_larg := (PAD + PAINEL_LARG) - cartao_x - (chip_w * 3.0 + chip_gap * 3.0) - menu_w
	var cartao := _painel_console(Rect2(cartao_x, TOPO_Y, cartao_larg, TOPO_ALT), 14, false)

	var nome := _texto_ui("PLAYER ONE", 22, Tema.TEXTO_PRIMARIO, 700)
	nome.position = Vector2(14, 8)
	cartao.add_child(nome)

	var nivel := _texto_ui("Lv. 12", 16, Tema.TEXTO_SECUNDARIO, 600)
	nivel.position = Vector2(cartao_larg - 74, 10)
	cartao.add_child(nivel)

	var trilho_xp := Panel.new()
	var caixa_xp := StyleBoxFlat.new()
	caixa_xp.bg_color = Color("CCD5E1")
	caixa_xp.set_corner_radius_all(5)
	trilho_xp.add_theme_stylebox_override("panel", caixa_xp)
	trilho_xp.position = Vector2(14, 60)
	trilho_xp.size = Vector2(cartao_larg - 28, 10)
	trilho_xp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cartao.add_child(trilho_xp)

	var fill_xp := Panel.new()
	var caixa_fill := StyleBoxFlat.new()
	caixa_fill.bg_color = Color("3E7BD6")
	caixa_fill.set_corner_radius_all(5)
	fill_xp.add_theme_stylebox_override("panel", caixa_fill)
	fill_xp.position = Vector2(14, 60)
	fill_xp.size = Vector2((cartao_larg - 28) * 0.42, 10)
	fill_xp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cartao.add_child(fill_xp)

	var chips := [
		{"icone": Tema.icone_moeda(), "valor": "1250"},
		{"icone": Tema.icone_gema(), "valor": "84"},
		{"icone": Tema.icone_energia(), "valor": "7/10"},
	]
	for i in chips.size():
		var dado: Dictionary = chips[i]
		var x := cartao_x + cartao_larg + 12.0 + i * (chip_w + chip_gap)
		var chip := _painel_console(Rect2(x, TOPO_Y, chip_w, TOPO_ALT), 16, false)
		var icone := TextureRect.new()
		icone.texture = dado.icone
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone.position = Vector2(10, 28)
		icone.size = Vector2(38, 38)
		icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(icone)
		var num := _texto_display(String(dado.valor), 20, Tema.TEXTO_PRIMARIO, 700)
		num.position = Vector2(52, 34)
		chip.add_child(num)

	var menu_x := (PAD + PAINEL_LARG) - menu_w
	var botao_menu := Button.new()
	botao_menu.flat = true
	botao_menu.position = Vector2(menu_x, TOPO_Y)
	botao_menu.size = Vector2(menu_w, TOPO_ALT)
	botao_menu.tooltip_text = "Sair"
	botao_menu.pressed.connect(func() -> void: get_tree().quit())
	add_child(botao_menu)
	var icone_menu := TextureRect.new()
	icone_menu.texture = Tema.icone_menu()
	icone_menu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone_menu.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone_menu.position = Vector2(menu_x + (menu_w - 44) / 2.0, TOPO_Y + (TOPO_ALT - 44) / 2.0)
	icone_menu.size = Vector2(44, 44)
	icone_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icone_menu)


# -------------------------------------------------------------------- arena
func _montar_arena() -> void:
	var janela := Rect2(0, ARENA_Y, TELA.x, ARENA_ALT)
	var recorte := Control.new()
	recorte.clip_contents = true
	recorte.position = janela.position
	recorte.size = janela.size
	recorte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(recorte)

	var fundo := TextureRect.new()
	fundo.texture = Tema.fundo_arena()
	fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fundo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fundo.position = Vector2(0, -janela.position.y)
	fundo.size = janela.size
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	recorte.add_child(fundo)

	# fade branco no terco de baixo, pra AFFINITY/ROUND/aliados lerem bem
	var grad := Gradient.new()
	grad.set_color(0, Color(Tema.PAINEL, 0.0))
	grad.set_color(1, Color(Tema.PAINEL, 1.0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	var fade := TextureRect.new()
	fade.texture = tex
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	fade.position = Vector2(0, janela.size.y * 0.66)
	fade.size = Vector2(janela.size.x, janela.size.y * 0.34)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	recorte.add_child(fade)

	_montar_inimigo(recorte)
	_montar_aliados(recorte)


# 1 inimigo por enquanto (BattleLogic ainda nao suporta varios - ver
# plano). Layout usa a entrada count=1 do spec (x:50%, w:300, y:46).
func _montar_inimigo(recorte: Control) -> void:
	var largura := 300.0
	var proporcao := 380.0 / 308.0  # aspect de mon_dark.png
	var altura := largura * proporcao
	var chao := 470.0 - 46.0
	var pos := Vector2(TELA.x / 2.0 - largura / 2.0, chao - altura)

	var sombra := ColorRect.new()
	sombra.color = Color(0.08, 0.04, 0.0, 0.42)
	sombra.size = Vector2(largura * 0.6, largura * 0.16)
	sombra.position = Vector2(pos.x + (largura - sombra.size.x) / 2.0, chao - sombra.size.y / 2.0)
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	recorte.add_child(sombra)

	_inimigo_sprite = TextureRect.new()
	_inimigo_sprite.texture = Tema.sprite_inimigo()
	_inimigo_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_inimigo_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_inimigo_sprite.position = pos
	_inimigo_sprite.size = Vector2(largura, altura)
	_inimigo_sprite.pivot_offset = Vector2(largura, altura) / 2.0
	_inimigo_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	recorte.add_child(_inimigo_sprite)

	# placa de HP colada a cabeca: icone + nivel + gauge + numero
	var placa_y := pos.y - 46.0
	var placa := Control.new()
	placa.position = Vector2(TELA.x / 2.0 - 110.0, placa_y)
	placa.size = Vector2(220, 40)
	placa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	recorte.add_child(placa)

	var icone := TextureRect.new()
	icone.texture = Tema.icone_elemento(CardData.Cor.ROXO)
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.size = Vector2(30, 30)
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placa.add_child(icone)

	_inimigo_label_nivel = _texto_ui("Lv.%d" % logica.inimigo.nivel, 14, Color.WHITE, 700)
	_inimigo_label_nivel.position = Vector2(34, 2)
	placa.add_child(_inimigo_label_nivel)

	var gauge_trilho := Panel.new()
	var caixa_g := StyleBoxFlat.new()
	caixa_g.bg_color = Color("2a0a0a")
	caixa_g.set_corner_radius_all(4)
	gauge_trilho.add_theme_stylebox_override("panel", caixa_g)
	gauge_trilho.position = Vector2(34, 22)
	gauge_trilho.size = Vector2(150, 13)
	gauge_trilho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placa.add_child(gauge_trilho)

	_inimigo_barra_hp = Control.new()
	_inimigo_barra_hp.position = Vector2(34, 22)
	_inimigo_barra_hp.size = Vector2(150, 13)
	_inimigo_barra_hp.clip_contents = true
	_inimigo_barra_hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placa.add_child(_inimigo_barra_hp)
	var gauge_fill := Panel.new()
	var caixa_f := StyleBoxFlat.new()
	caixa_f.bg_color = Color("e0483c")
	caixa_f.set_corner_radius_all(4)
	gauge_fill.name = "fill"
	gauge_fill.add_theme_stylebox_override("panel", caixa_f)
	gauge_fill.size = Vector2(150, 13)
	gauge_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inimigo_barra_hp.add_child(gauge_fill)

	_inimigo_label_hp = _texto_ui("", 12, Tema.TEXTO_SECUNDARIO, 600)
	_inimigo_label_hp.position = Vector2(34, 36)
	placa.add_child(_inimigo_label_hp)


# Fileira de 5 aliados (as 5 cores de ataque - cura nao tem aliado, ver
# [[decisoes-copia-fiel]]), ancorada no fundo/laterais da arena.
func _montar_aliados(recorte: Control) -> void:
	var y0 := ARENA_ALT - 22.0
	var esquerda := 22.0
	var direita := TELA.x - 22.0
	var gap := 14.0
	var n := BattleLogic.CORES_DE_ATAQUE.size()
	var largura := (direita - esquerda - float(n - 1) * gap) / float(n)
	var altura := largura / 0.735

	for i in n:
		var cor: int = BattleLogic.CORES_DE_ATAQUE[i]
		var x := esquerda + i * (largura + gap)
		var y := y0 - altura
		_montar_aliado(recorte, cor, Rect2(x, y, largura, altura))


func _montar_aliado(recorte: Control, cor: int, rect: Rect2) -> void:
	var moldura := Panel.new()
	var caixa := StyleBoxFlat.new()
	caixa.bg_color = Color.WHITE
	caixa.border_color = Tema.cor_elemento(cor)
	caixa.set_border_width_all(3)
	caixa.set_corner_radius_all(12)
	caixa.shadow_size = 4
	caixa.shadow_color = Color(0, 0, 0, 0.25)
	moldura.add_theme_stylebox_override("panel", caixa)
	moldura.position = rect.position
	moldura.size = rect.size
	moldura.clip_contents = true
	moldura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	recorte.add_child(moldura)

	var retrato := TextureRect.new()
	retrato.texture = Tema.retrato_aliado(cor)
	retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	retrato.position = Vector2(2, 2)
	retrato.size = rect.size - Vector2(4, 12)
	retrato.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moldura.add_child(retrato)

	var skill_trilho := Panel.new()
	var caixa_t := StyleBoxFlat.new()
	caixa_t.bg_color = Tema.VOID_TRILHO
	skill_trilho.add_theme_stylebox_override("panel", caixa_t)
	skill_trilho.position = Vector2(0, rect.size.y - 8)
	skill_trilho.size = Vector2(rect.size.x, 8)
	skill_trilho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moldura.add_child(skill_trilho)

	var skill_fill := Control.new()
	skill_fill.position = Vector2(0, rect.size.y - 8)
	skill_fill.size = Vector2(0, 8)
	skill_fill.clip_contents = true
	skill_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moldura.add_child(skill_fill)
	var skill_fill_cor := Panel.new()
	var caixa_sf := StyleBoxFlat.new()
	caixa_sf.bg_color = Tema.cor_elemento(cor)
	skill_fill_cor.add_theme_stylebox_override("panel", caixa_sf)
	skill_fill_cor.size = Vector2(rect.size.x, 8)
	skill_fill_cor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skill_fill.add_child(skill_fill_cor)

	_aliados[cor] = {"largura": rect.size.x, "skill_fill": skill_fill, "moldura": moldura}


# ------------------------------------------------------------ affinity/round
# Cadeia de afinidade: ordem REAL, achada limpa no APK ([[afinidade-elemental]]) -
# nao a ordem de exemplo do mockup, que estava trocada. Trio fechado
# Fogo->Natureza->Agua->Fogo, mais o par mutuo Luz<->Trevas. Puramente
# decorativo por enquanto: BattleLogic ainda nao aplica o multiplicador
# de vantagem (Fase 1 do roadmap).
const CICLO_AFINIDADE := [CardData.Cor.VERMELHO, CardData.Cor.VERDE, CardData.Cor.AZUL, CardData.Cor.VERMELHO]
const PAR_AFINIDADE := [CardData.Cor.AMARELO, CardData.Cor.ROXO]

func _montar_affinity_round() -> void:
	var rect := Rect2(PAD, AFFIN_Y, PAINEL_LARG, AFFIN_ALT)
	var painel := _painel_console(rect, 16, false)
	# cantos so embaixo (o painel "continua" a arena, sem topo proprio)
	_tag_flutuante("AFFINITY", Vector2(PAD + 4, AFFIN_Y - 13))

	var cadeia := Control.new()
	cadeia.position = Vector2(16, 0)
	cadeia.size = Vector2(rect.size.x * 0.62, AFFIN_ALT)
	painel.add_child(cadeia)

	var x := 0.0
	var icone_tam := 32.0
	for i in CICLO_AFINIDADE.size():
		if i > 0:
			var seta := _texto_ui(">", 20, Tema.CYAN, 700)
			seta.position = Vector2(x, AFFIN_ALT / 2.0 - 14)
			cadeia.add_child(seta)
			x += 18
		var icone := TextureRect.new()
		icone.texture = Tema.icone_elemento(CICLO_AFINIDADE[i])
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone.position = Vector2(x, (AFFIN_ALT - icone_tam) / 2.0)
		icone.size = Vector2(icone_tam, icone_tam)
		icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cadeia.add_child(icone)
		x += icone_tam + 6

	var separador := _texto_ui("|", 20, Tema.TEXTO_SECUNDARIO, 600)
	separador.position = Vector2(x + 6, AFFIN_ALT / 2.0 - 14)
	cadeia.add_child(separador)
	x += 26

	for i in PAR_AFINIDADE.size():
		if i > 0:
			var duplo := _texto_ui("<>", 18, Tema.CYAN, 700)
			duplo.position = Vector2(x, AFFIN_ALT / 2.0 - 12)
			cadeia.add_child(duplo)
			x += 24
		var icone2 := TextureRect.new()
		icone2.texture = Tema.icone_elemento(PAR_AFINIDADE[i])
		icone2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone2.position = Vector2(x, (AFFIN_ALT - icone_tam) / 2.0)
		icone2.size = Vector2(icone_tam, icone_tam)
		icone2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cadeia.add_child(icone2)
		x += icone_tam + 6

	var divisor := ColorRect.new()
	divisor.color = Tema.BORDA_PAINEL_ALT
	divisor.position = Vector2(rect.size.x * 0.64, 10)
	divisor.size = Vector2(2, AFFIN_ALT - 20)
	divisor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(divisor)

	var round_area := Control.new()
	round_area.position = Vector2(rect.size.x * 0.68, 0)
	round_area.size = Vector2(rect.size.x * 0.32 - 16, AFFIN_ALT)
	painel.add_child(round_area)

	var rotulo := _texto_ui("ROUND", 12, Tema.TEXTO_SECUNDARIO, 600)
	rotulo.position = Vector2(0, 8)
	round_area.add_child(rotulo)

	_label_round = _texto_display("1/3", 24, Tema.TEXTO_PRIMARIO, 700)
	_label_round.position = Vector2(0, 24)
	round_area.add_child(_label_round)

	for i in logica.contador_inimigo_max:
		var pip := ColorRect.new()
		pip.color = Tema.BORDA_PAINEL_ALT
		pip.size = Vector2(10, 10)
		pip.position = Vector2(64 + i * 16, 30)
		pip.rotation = deg_to_rad(45)
		pip.pivot_offset = Vector2(5, 5)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		round_area.add_child(pip)
		_pips_round.append(pip)


# -------------------------------------------------------------------- life
func _montar_life() -> void:
	var rect := Rect2(PAD, LIFE_Y, PAINEL_LARG, LIFE_ALT)
	var painel := _painel_console(rect, 16)
	_tag_flutuante("LIFE", Vector2(PAD + 4, LIFE_Y - 13))

	_coracao_hp = TextureRect.new()
	_coracao_hp.texture = Tema.icone_coracao()
	_coracao_hp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_coracao_hp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_coracao_hp.position = Vector2(14, (LIFE_ALT - 44) / 2.0)
	_coracao_hp.size = Vector2(44, 44)
	_coracao_hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(_coracao_hp)

	_label_hp = _texto_display("", 26, Tema.TEXTO_PRIMARIO, 700)
	_label_hp.position = Vector2(70, 8)
	painel.add_child(_label_hp)

	_label_hp_max = _texto_ui("", 18, Tema.TEXTO_SECUNDARIO, 600)
	_label_hp_max.position = Vector2(70, 34)
	painel.add_child(_label_hp_max)

	var barra_x := 260.0
	var barra_larg := rect.size.x - barra_x - 16.0
	var trilho := Panel.new()
	var caixa_t := StyleBoxFlat.new()
	caixa_t.bg_color = Color("CCD5E1")
	caixa_t.set_corner_radius_all(11)
	trilho.add_theme_stylebox_override("panel", caixa_t)
	trilho.position = Vector2(barra_x, (LIFE_ALT - 22) / 2.0)
	trilho.size = Vector2(barra_larg, 22)
	trilho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(trilho)

	_fill_vida = Control.new()
	_fill_vida.position = Vector2(barra_x, (LIFE_ALT - 22) / 2.0)
	_fill_vida.size = Vector2(barra_larg, 22)
	_fill_vida.clip_contents = true
	_fill_vida.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(_fill_vida)
	var fill_cor := Panel.new()
	fill_cor.name = "fill"
	var caixa_f := StyleBoxFlat.new()
	caixa_f.bg_color = Tema.VIDA_CHEIA
	caixa_f.set_corner_radius_all(11)
	fill_cor.add_theme_stylebox_override("panel", caixa_f)
	fill_cor.size = Vector2(barra_larg, 22)
	fill_cor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill_vida.add_child(fill_cor)
	_fill_vida_larg = barra_larg


# ----------------------------------------------------------------- flowbag
func _montar_flowbag_painel() -> void:
	var rect := Rect2(PAD, FLOWBAG_Y, PAINEL_LARG, FLOWBAG_ALT)
	_painel_console(rect)
	_tag_flutuante("FLOWBAG", Vector2(PAD + 4, FLOWBAG_Y - 13))

	var next_fusions := _texto_ui("NEXT FUSIONS", 13, Tema.TEXTO_SECUNDARIO, 600)
	next_fusions.position = Vector2(PAD + 120, FLOWBAG_Y + 10)
	add_child(next_fusions)

	var rotulo_bag := _texto_ui("BAG", 14, Tema.TEXTO_SECUNDARIO, 700)
	rotulo_bag.rotation = deg_to_rad(180)
	rotulo_bag.position = Vector2(
		PAD + GRID_PAD + FLOWBAG_LABEL_W - 6,
		FLOWBAG_Y + FLOWBAG_HEADER_ALT + GRID_PAD + FLOWBAG_CASA_H - 6)
	add_child(rotulo_bag)

	var seta := _texto_ui("v", 16, Tema.CYAN, 700)
	seta.position = Vector2(
		PAD + PAINEL_LARG - GRID_PAD - FLOWBAG_NEXT_W + 4,
		FLOWBAG_Y + FLOWBAG_HEADER_ALT + GRID_PAD)
	add_child(seta)
	var rotulo_next := _texto_ui("NEXT", 11, Tema.CYAN, 700)
	rotulo_next.position = seta.position + Vector2(-4, 20)
	add_child(rotulo_next)


# posicao ABSOLUTA da casa i (0=esquerda..8=direita) do FLOWBAG.
func _pos_flowbag(i: int) -> Vector2:
	var x0 := PAD + GRID_PAD + FLOWBAG_LABEL_W + 6.0
	var y := FLOWBAG_Y + FLOWBAG_HEADER_ALT + GRID_PAD
	return Vector2(x0 + i * (FLOWBAG_CASA_W + FLOWBAG_CASA_GAP), y)


func _montar_flowbag_cartas() -> void:
	for j in BattleLogic.QTD_PROXIMAS:
		var no := Control.new()
		no.size = Vector2(FLOWBAG_CASA_W, FLOWBAG_CASA_H)
		no.position = _pos_flowbag(j)
		no.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var arte := TextureRect.new()
		arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		arte.stretch_mode = TextureRect.STRETCH_SCALE
		arte.size = no.size
		arte.mouse_filter = Control.MOUSE_FILTER_IGNORE
		no.add_child(arte)
		var num := _texto_display("", 14, Color.WHITE, 700)
		num.position = Vector2(4, 2)
		no.add_child(num)
		# a casa mais a direita (ultima montada) e sempre proximas[0] - a
		# proxima a descer pra ENTRADA (ver _atualizar_flowbag_de). Ganha
		# o contorno cyan de "NEXT" (spec 6).
		if j == BattleLogic.QTD_PROXIMAS - 1:
			var contorno := Panel.new()
			var caixa := StyleBoxFlat.new()
			caixa.bg_color = Color(0, 0, 0, 0)
			caixa.border_color = Tema.CYAN
			caixa.set_border_width_all(3)
			caixa.set_corner_radius_all(8)
			caixa.shadow_size = 6
			caixa.shadow_color = Color(Tema.CYAN, 0.6)
			contorno.add_theme_stylebox_override("panel", caixa)
			contorno.size = no.size
			contorno.mouse_filter = Control.MOUSE_FILTER_IGNORE
			no.add_child(contorno)
		add_child(no)
		_visuais_flowbag.append(no)


func _atualizar_flowbag_de(fila: Array) -> void:
	var n := _visuais_flowbag.size()
	for i in n:
		var no: Control = _visuais_flowbag[i]
		var arte := no.get_child(0) as TextureRect
		var label := no.get_child(1) as Label
		# casa i mostra proximas[n-1-i]: a da direita (i=n-1) e proximas[0]
		var j := n - 1 - i
		if j >= fila.size():
			arte.texture = null
			label.text = ""
			continue
		var item: Variant = fila[j]
		var cor: int = item.cor
		var valor: int = item.valor
		arte.texture = Tema.carta(cor)
		label.text = str(valor)


# ------------------------------------------------------------- attack zone

func _montar_attack_header() -> void:
	var rect := Rect2(PAD, ATTACK_Y, PAINEL_LARG, ATTACK_ALT)
	_painel_console(rect)

	var tag := _texto_ui("ATTACK ZONE", 18, Tema.TEXTO_PRIMARIO, 700)
	tag.position = Vector2(PAD + 16, ATTACK_Y + 14)
	add_child(tag)

	_label_status = _texto_ui("TAP TO CHAIN", 14, Tema.TEXTO_SECUNDARIO, 600)
	_label_status.position = Vector2(PAD + PAINEL_LARG - 220, ATTACK_Y + 16)
	_label_status.size = Vector2(190, 24)
	_label_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_label_status)

	_botao_desfazer = Button.new()
	_botao_desfazer.flat = true
	_botao_desfazer.text = "UNDO"
	_botao_desfazer.position = Vector2(PAD + PAINEL_LARG - 220, ATTACK_Y + 14)
	_botao_desfazer.size = Vector2(60, 28)
	_botao_desfazer.tooltip_text = "Desfazer o ultimo toque"
	_botao_desfazer.pressed.connect(_ao_desfazer)
	add_child(_botao_desfazer)


# --------------------------------------------------------------------- rodape
func _montar_footer() -> void:
	var y := FOOTER_Y + FOOTER_ALT / 2.0 - 1.5
	var esq := ColorRect.new()
	esq.color = Color("CCD5E1")
	esq.size = Vector2(110, 3)
	esq.position = Vector2(TELA.x / 2.0 - 160, y)
	esq.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(esq)
	var dir := ColorRect.new()
	dir.color = Color("CCD5E1")
	dir.size = Vector2(110, 3)
	dir.position = Vector2(TELA.x / 2.0 + 50, y)
	dir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dir)

	var cta := _texto_ui("TAP TO CHAIN", 22, Tema.TEXTO_PRIMARIO, 700)
	cta.name = "cta"
	cta.position = Vector2(0, FOOTER_Y + 12)
	cta.size = Vector2(TELA.x, 32)
	cta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(cta)


# ------------------------------------------------------------------ textos

func _texto_ui(t: String, tam: int, cor: Color, peso: int = 600) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", Tema.fonte_ui(peso))
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _texto_display(t: String, tam: int, cor: Color, peso: int = 900) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", Tema.fonte_display(peso))
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


# ------------------------------------------------------------------ cartas

func _pos_slot(idx: int) -> Vector2:
	var linha: int
	var coluna: int
	if idx < BattleLogic.TAMANHO_MAO:
		linha = idx / BattleLogic.ROW_SIZE
		coluna = idx % BattleLogic.ROW_SIZE
	else:
		linha = idx - BattleLogic.TAMANHO_MAO
		coluna = BattleLogic.ROW_SIZE  # 6a coluna = ENTRADA
	var x := GRID_X0 + coluna * (CARD_W + GRID_GAP)
	var y := GRID_Y0 + GRID_FOLGA_Y + linha * (CARD_H + GRID_ROW_GAP)
	return Vector2(x, y)


# Carta da leva "design_mobile": aro 2px na cor do elemento + glow duplo
# quando marcada, losango no canto sup. direito. Sem sobreposicao (grid
# 2x6 reto), diferente do leque do tema anterior.
func _criar_visual(cor: int, valor: int) -> Control:
	var no := Control.new()
	no.size = Vector2(CARD_W, CARD_H)
	no.pivot_offset = Vector2(CARD_W, CARD_H) / 2.0
	no.mouse_filter = Control.MOUSE_FILTER_STOP

	var aro := Panel.new()
	aro.name = "Aro"
	var caixa_aro := StyleBoxFlat.new()
	caixa_aro.bg_color = Color(0, 0, 0, 0)
	caixa_aro.border_color = Tema.cor_elemento(cor)
	caixa_aro.set_border_width_all(3)
	caixa_aro.set_corner_radius_all(10)
	caixa_aro.shadow_size = 10
	caixa_aro.shadow_color = Tema.glow_forte(cor)
	aro.add_theme_stylebox_override("panel", caixa_aro)
	aro.position = Vector2(-4, -4)
	aro.size = Vector2(CARD_W, CARD_H) + Vector2(8, 8)
	aro.visible = false
	aro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	no.add_child(aro)

	var arte := TextureRect.new()
	arte.texture = Tema.carta(cor)
	arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arte.stretch_mode = TextureRect.STRETCH_SCALE
	arte.size = Vector2(CARD_W, CARD_H)
	arte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	no.add_child(arte)

	var numero := _texto_display(str(valor), 26, Color.WHITE, 900)
	numero.position = Vector2(10, 4)
	no.add_child(numero)

	var marcador := ColorRect.new()
	marcador.name = "Marcador"
	marcador.color = Tema.cor_elemento(cor)
	marcador.size = Vector2(14, 14)
	marcador.position = Vector2(CARD_W - 20, 6)
	marcador.rotation = deg_to_rad(45)
	marcador.pivot_offset = Vector2(7, 7)
	marcador.visible = false
	marcador.mouse_filter = Control.MOUSE_FILTER_IGNORE
	no.add_child(marcador)

	no.set_meta("cor", cor)
	no.set_meta("valor", valor)
	return no


func _por_carta_na_casa(idx: int, cor: int, valor: int) -> Control:
	var no := _criar_visual(cor, valor)
	no.position = _pos_slot(idx)
	no.gui_input.connect(_ao_tocar_casa.bind(idx))
	_camada_cartas.add_child(no)
	_nas_casas[idx] = no
	return no


func _limpar_cartas() -> void:
	for no: Control in _nas_casas.values():
		no.queue_free()
	for no: Control in _marcadas.values():
		no.queue_free()
	_nas_casas.clear()
	_marcadas.clear()


func _desenhar_mao_inteira() -> void:
	_limpar_cartas()
	for i in logica.mao.size():
		var c: CardData = logica.mao[i]
		if c != null:
			_por_carta_na_casa(i, c.cor, c.valor)
	_atualizar_flowbag_de(logica.proximas)


# ------------------------------------------------------------------ toques

func _ao_tocar_casa(evento: InputEvent, idx: int) -> void:
	if not (evento is InputEventMouseButton):
		return
	var clique := evento as InputEventMouseButton
	if not clique.pressed or clique.button_index != MOUSE_BUTTON_LEFT:
		return
	if _animando or logica.fim:
		return

	var resultado: Dictionary
	if _marcadas.has(idx):
		resultado = logica.desmarcar(idx)
	else:
		resultado = logica.tocar(idx)
	if resultado.tipo == "ignorado":
		return
	await _reproduzir(resultado)


func _ao_desfazer() -> void:
	if _animando or logica.fim:
		return
	if not logica.desfazer():
		return
	_desenhar_mao_inteira()
	_redesenhar_marcadas()
	_atualizar_placar()


func _redesenhar_marcadas() -> void:
	for i in logica.zona.size():
		var slot: int = logica.zona_slots[i]
		if slot < 0:
			continue
		var c: CardData = logica.zona[i]
		var no := _criar_visual(c.cor, c.valor)
		no.position = _pos_slot(slot) + Vector2(0, -10)
		no.z_index = 10
		no.gui_input.connect(_ao_tocar_casa.bind(slot))
		_camada_cartas.add_child(no)
		_marcadas[slot] = no
		_marcar_visual(no)


# --------------------------------------------------------------- reproducao

func _reproduzir(resultado: Dictionary) -> void:
	_animando = true
	for evento: Dictionary in resultado.eventos:
		match evento.tipo:
			"selecao":
				await _anim_selecao(evento)
			"deselecao":
				await _anim_deselecao(evento)
			"carta_desce":
				await _anim_desce(evento)
			"carta_volta":
				await _anim_volta(evento)
			"abandono":
				await _anim_abandono()
			"trio_sobe":
				await _anim_trio_sobe(evento)
			"puxa_do_deck":
				await _anim_puxa_do_deck(evento)
			"combo":
				await _anim_combo(evento)
			"renovacao":
				await _anim_renovacao()
			"nova_carta":
				await _anim_nova_carta(evento)
			"entra_na_mao":
				await _anim_entra_na_mao(evento)
			"redistribuicao":
				await _anim_redistribuicao(evento)
			"ataque_final":
				await _anim_ataque_final(evento)

	if resultado.has("ataque_inimigo"):
		await _anim_ataque_inimigo(int(resultado.ataque_inimigo))

	_atualizar_placar()
	_animando = false

	if resultado.has("fim"):
		_mostrar_fim(String(resultado.fim))


func _espera(s: float) -> void:
	await get_tree().create_timer(s).timeout


# rim + glow + losango, sem o "piscar" do tema anterior - o design novo
# marca por contorno solido, nao por opacidade piscando.
func _marcar_visual(no: Control) -> void:
	(no.get_node("Aro") as Panel).visible = true
	(no.get_node("Marcador") as ColorRect).visible = true


func _desmarcar_visual(no: Control) -> void:
	(no.get_node("Aro") as Panel).visible = false
	(no.get_node("Marcador") as ColorRect).visible = false


func _anim_selecao(ev: Dictionary) -> void:
	var slot: int = ev.slot
	var no: Control = _nas_casas.get(slot)
	if no == null:
		no = _por_carta_na_casa(slot, ev.cor, ev.valor)
	_nas_casas.erase(slot)
	_marcadas[slot] = no
	no.z_index = 10
	var t := create_tween()
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(no, "position", _pos_slot(slot) + Vector2(0, -10), 0.12)
	await t.finished
	_marcar_visual(no)
	_atualizar_status_cadeia()


func _anim_deselecao(ev: Dictionary) -> void:
	var slot: int = ev.slot
	var no: Control = _marcadas.get(slot)
	if no == null:
		return
	_desmarcar_visual(no)
	_marcadas.erase(slot)
	_nas_casas[slot] = no
	no.z_index = 0
	var t := create_tween()
	t.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(no, "position", _pos_slot(slot), 0.12)
	await t.finished
	_atualizar_status_cadeia()


# Carta nova da BAG descendo na casa de ENTRADA: nasce na posicao da
# ultima casa do FLOWBAG (a "NEXT") e viaja ate a ENTRADA - spec 6,
# "animacao de queda".
func _anim_desce(ev: Dictionary) -> void:
	var slot: int = ev.slot
	var destino := _pos_slot(slot)
	var origem := _pos_flowbag(_visuais_flowbag.size() - 1)
	var no := _criar_visual(ev.cor, ev.valor)
	no.position = origem
	no.scale = Vector2(0.5, 0.5)
	no.modulate.a = 0.0
	no.gui_input.connect(_ao_tocar_casa.bind(slot))
	_camada_cartas.add_child(no)
	_nas_casas[slot] = no
	_atualizar_flowbag_de(ev.fila)
	var t := create_tween().set_parallel()
	t.tween_property(no, "position", destino, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(no, "scale", Vector2.ONE, 0.42)
	t.tween_property(no, "modulate:a", 1.0, 0.2)
	await t.finished


func _anim_volta(ev: Dictionary) -> void:
	var slot: int = ev.slot
	var no: Control = _nas_casas.get(slot)
	_atualizar_flowbag_de(ev.fila)
	if no == null:
		return
	_nas_casas.erase(slot)
	var destino := _pos_flowbag(_visuais_flowbag.size() - 1)
	var t := create_tween().set_parallel()
	t.tween_property(no, "position", destino, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(no, "scale", Vector2(0.5, 0.5), 0.18)
	t.tween_property(no, "modulate:a", 0.0, 0.18)
	await t.finished
	no.queue_free()


func _anim_abandono() -> void:
	var t := create_tween()
	t.tween_property(_camada_cartas, "position", Vector2(-9, 0), 0.05)
	t.tween_property(_camada_cartas, "position", Vector2(9, 0), 0.05)
	t.tween_property(_camada_cartas, "position", Vector2.ZERO, 0.05)
	await t.finished


# Gather -> burst DENTRO do proprio grid da ATTACK ZONE (spec 7), nao
# mais voando ate o palco do inimigo como no tema anterior.
func _anim_trio_sobe(ev: Dictionary) -> void:
	var voando: Array[Control] = []
	var slots: Array = ev.slots
	var cartas: Array = ev.cartas

	for i in slots.size():
		var slot: int = slots[i]
		var no: Control = null
		if slot >= 0 and _marcadas.has(slot):
			no = _marcadas[slot]
			_marcadas.erase(slot)
		elif slot >= 0 and _nas_casas.has(slot):
			no = _nas_casas[slot]
			_nas_casas.erase(slot)
		else:
			var dado: Dictionary = cartas[i]
			no = _criar_visual(dado.cor, dado.valor)
			no.position = _pos_flowbag(_visuais_flowbag.size() - 1)
			_camada_cartas.add_child(no)
		_desmarcar_visual(no)
		no.z_index = 20
		voando.append(no)

	# a cor vem do PAYLOAD do evento, nao de logica.zona - a essa altura
	# do replay a logica ja rodou a corrente INTEIRA de uma vez so, entao
	# logica.zona reflete o estado FINAL, nao o deste trio historico.
	var cor := CardData.Cor.CORINGA
	for dado: Dictionary in cartas:
		if int(dado.cor) != CardData.Cor.CORINGA:
			cor = int(dado.cor)
			break
	var brilho := Tema.glow_forte(cor)

	# gather
	var g := create_tween().set_parallel()
	for i in voando.size():
		var no := voando[i]
		var alvo := CENTRO_FUSAO + Vector2((i - 1) * 34, 0) - Vector2(CARD_W, CARD_H) / 2.0
		g.tween_property(no, "position", alvo, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		g.tween_property(no, "scale", Vector2(1.16, 1.16), 0.2)
	await g.finished

	# burst: anel de carga + flash, cartas somem
	var anel := Panel.new()
	var caixa_anel := StyleBoxFlat.new()
	caixa_anel.bg_color = Color(0, 0, 0, 0)
	caixa_anel.border_color = brilho
	caixa_anel.set_border_width_all(4)
	caixa_anel.set_corner_radius_all(115)
	anel.add_theme_stylebox_override("panel", caixa_anel)
	anel.size = Vector2(230, 230)
	anel.position = CENTRO_FUSAO - anel.size / 2.0
	anel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anel.scale = Vector2(0.3, 0.3)
	anel.pivot_offset = anel.size / 2.0
	_camada_efeitos.add_child(anel)
	var ta := create_tween().set_parallel()
	ta.tween_property(anel, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	ta.tween_property(anel, "modulate:a", 0.0, 0.2).set_delay(0.06)

	var f := create_tween().set_parallel()
	for no in voando:
		f.tween_property(no, "scale", Vector2(0.15, 0.15), 0.16)
		f.tween_property(no, "modulate:a", 0.0, 0.16)
	await f.finished
	for no in voando:
		no.queue_free()
	anel.queue_free()


func _anim_puxa_do_deck(ev: Dictionary) -> void:
	_atualizar_flowbag_de(ev.fila)
	await _espera(0.04)


func _anim_combo(ev: Dictionary) -> void:
	var cor: int = ev.cor
	var ganho: int = int(ev.get("dano_parcial", ev.get("cura", 0)))

	if ev.get("todas_as_cores", false):
		for c: int in _aliados:
			_acumular(c, int(ganho / 5.0))
	elif _aliados.has(cor):
		_acumular(cor, ganho)

	var texto := "+%d" % ganho
	if ev.get("critico", false):
		texto = "CRITICO %s" % texto
	_flutuar(texto, CENTRO_FUSAO + Vector2(CARD_W / 2.0, -40), Tema.CYAN, 32)
	await _espera(0.1)


# barra de skill do aliado = quanto ele ja acumulou nesta corrente, contra
# um teto COSMETICO (nao existe sistema de skill/ultimate real ainda -
# ver plano). So um indicador visual de "quanto esse trio valeu".
const SKILL_TETO := 500.0

func _acumular(cor: int, ganho: int) -> void:
	if not _aliados.has(cor):
		return
	_acumulado[cor] = int(_acumulado.get(cor, 0)) + ganho
	var dados: Dictionary = _aliados[cor]
	var fracao: float = clampf(float(_acumulado[cor]) / SKILL_TETO, 0.0, 1.0)
	var fill: Control = dados.skill_fill
	var t := create_tween()
	t.tween_property(fill, "size:x", float(dados.largura) * fracao, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var moldura: Control = dados.moldura
	var pulso := create_tween()
	pulso.tween_property(moldura, "scale", Vector2(1.05, 1.05), 0.08)
	pulso.tween_property(moldura, "scale", Vector2.ONE, 0.12)


func _anim_renovacao() -> void:
	_flutuar("RENOVACAO", CENTRO_FUSAO, Tema.CYAN, 34)
	_limpar_cartas()
	await _espera(0.2)


func _anim_nova_carta(ev: Dictionary) -> void:
	var slot: int = ev.slot
	var destino := _pos_slot(slot)
	var no := _criar_visual(ev.cor, ev.valor)
	no.position = destino - Vector2(0, 160)
	no.modulate.a = 0.0
	no.gui_input.connect(_ao_tocar_casa.bind(slot))
	_camada_cartas.add_child(no)
	_nas_casas[slot] = no
	_atualizar_flowbag_de(ev.fila)
	var t := create_tween().set_parallel()
	t.tween_property(no, "position", destino, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(no, "modulate:a", 1.0, 0.12)
	if ev.get("chuva", false):
		return
	await t.finished


func _anim_entra_na_mao(ev: Dictionary) -> void:
	var de: int = ev.de
	var para: int = ev.para
	var no: Control = _nas_casas.get(de)
	if no == null:
		return
	_nas_casas.erase(de)
	_nas_casas[para] = no
	for con in no.gui_input.get_connections():
		no.gui_input.disconnect(con["callable"])
	no.gui_input.connect(_ao_tocar_casa.bind(para))
	var t := create_tween()
	t.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(no, "position", _pos_slot(para), 0.14)
	await t.finished


func _anim_redistribuicao(ev: Dictionary) -> void:
	await _espera(0.18)
	_limpar_cartas()
	var estado: Array = ev.mao
	for i in estado.size():
		var dado: Variant = estado[i]
		if dado == null:
			continue
		var no := _por_carta_na_casa(i, dado.cor, dado.valor)
		no.scale = Vector2(0.6, 0.6)
		no.modulate.a = 0.0
		var t := create_tween()
		t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(no, "scale", Vector2.ONE, 0.18).set_delay(i * 0.018)
		t.parallel().tween_property(no, "modulate:a", 1.0, 0.14).set_delay(i * 0.018)
	_atualizar_flowbag_de(logica.proximas)
	await _espera(0.3)


func _anim_ataque_final(ev: Dictionary) -> void:
	var dano: int = int(ev.dano_total)
	var cura: int = int(ev.cura_total)

	if dano > 0:
		var pos_dano := Vector2(TELA.x / 2.0, ARENA_Y + 150)
		_flutuar(str(dano), pos_dano, Tema.DANO_MAGENTA, 58, true)
		var t := create_tween()
		t.tween_property(_inimigo_sprite, "position:x", _inimigo_sprite.position.x - 16, 0.05)
		t.tween_property(_inimigo_sprite, "position:x", _inimigo_sprite.position.x + 16, 0.05)
		t.tween_property(_inimigo_sprite, "position:x", _inimigo_sprite.position.x, 0.05)
		t.parallel().tween_property(_inimigo_sprite, "modulate", Color(2, 0.6, 0.6), 0.06)
		t.tween_property(_inimigo_sprite, "modulate", Color.WHITE, 0.14)
	if cura > 0:
		_flutuar("+%d" % cura, Vector2(TELA.x / 2.0, ARENA_Y + 150), Tema.VIDA_CHEIA, 46, true)

	await _espera(0.35)
	for cor: int in _aliados:
		var dados: Dictionary = _aliados[cor]
		var fill: Control = dados.skill_fill
		var t2 := create_tween()
		t2.tween_property(fill, "size:x", 0.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_acumulado.clear()


func _anim_ataque_inimigo(dano: int) -> void:
	_flutuar("-%d" % dano, Vector2(TELA.x / 2.0, LIFE_Y - 40), Tema.DANO_MAGENTA, 40, true)
	var t := create_tween()
	t.tween_property(self, "position:x", 14.0, 0.05)
	t.tween_property(self, "position:x", -14.0, 0.05)
	t.tween_property(self, "position:x", 0.0, 0.05)
	await t.finished


func _flutuar(t: String, pos: Vector2, cor: Color, tam: int, display := false) -> void:
	var l := _texto_display(t, tam, cor, 900) if display else _texto_ui(t, tam, cor, 700)
	l.position = pos - Vector2(200, 0)
	l.size = Vector2(400, 60)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_camada_efeitos.add_child(l)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", l.position.y - 46, 0.7)
	tw.parallel().tween_property(l, "scale", Vector2(1.12, 1.12), 0.18)
	tw.chain().tween_property(l, "scale", Vector2.ONE, 0.12)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.25)
	tw.finished.connect(l.queue_free)


# ------------------------------------------------------------------ placar

# Le _marcadas (o que a TELA ja mostrou marcado ate agora no replay), nao
# logica.zona - a logica ja resolveu a corrente inteira de uma vez so,
# entao zona reflete o estado FINAL, nao o instante que esta sendo
# animado. _marcadas cresce/encolhe em sincronia exata com os eventos
# (_anim_selecao/_anim_deselecao/_anim_trio_sobe), entao reflete certo o
# "agora" da animacao.
func _atualizar_status_cadeia() -> void:
	if _marcadas.is_empty():
		_label_status.text = "TAP TO CHAIN"
		return
	var alguma: Control = _marcadas.values()[0]
	var cor: int = alguma.get_meta("cor")
	_label_status.text = "CHAIN %s • %d/3" % [CardData.nome_cor(cor).to_upper(), _marcadas.size()]


func _atualizar_placar() -> void:
	var inimigo := logica.inimigo
	_inimigo_label_hp.text = "%d / %d" % [inimigo.hp, inimigo.hp_max]
	var fracao_inimigo := float(inimigo.hp) / maxf(1.0, float(inimigo.hp_max))
	(_inimigo_barra_hp.get_node("fill") as Control).size.x = 150.0 * fracao_inimigo

	_label_round.text = "%d/%d" % [
		logica.contador_inimigo_max - logica.contador_inimigo + 1,
		logica.contador_inimigo_max,
	]
	for i in _pips_round.size():
		var aceso: bool = i < (logica.contador_inimigo_max - logica.contador_inimigo)
		(_pips_round[i] as ColorRect).color = Tema.CYAN if aceso else Tema.BORDA_PAINEL_ALT

	_atualizar_vida(logica.hp_jogador, logica.hp_jogador_max)
	_atualizar_status_cadeia()


func _atualizar_vida(hp: int, hp_max: int) -> void:
	var fracao := float(hp) / maxf(1.0, float(hp_max))
	var cor := Tema.VIDA_CHEIA.lerp(Tema.VIDA_BAIXA, 1.0 - fracao)
	(_fill_vida.get_node("fill") as Panel).get_theme_stylebox("panel").set("bg_color", cor)
	_coracao_hp.modulate = cor
	_label_hp.add_theme_color_override("font_color", cor)
	_label_hp.text = str(hp)
	_label_hp_max.text = "/ %d" % hp_max

	_hp_mostrado = hp
	var t := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(_fill_vida.get_node("fill"), "size:x", _fill_vida_larg * fracao, 0.42)


func _mostrar_fim(texto: String) -> void:
	var veu := ColorRect.new()
	veu.color = Color(0, 0, 0, 0.72)
	veu.position = Vector2.ZERO
	veu.size = TELA
	_camada_efeitos.add_child(veu)
	var l := _texto_display(texto, 80, Color.WHITE, 900)
	l.position = Vector2(0, TELA.y / 2.0 - 60)
	l.size = Vector2(TELA.x, 120)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_camada_efeitos.add_child(l)
