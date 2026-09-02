extends SceneTree

var falhas: Array[String] = []


func _initialize() -> void:
	call_deferred("_executar")


func _executar() -> void:
	root.size = Vector2i(940, 1685)
	var tela := (load("res://scenes/battle/BattleScreen.tscn") as PackedScene).instantiate() as BattleScreen
	root.add_child(tela)
	await process_frame
	if tela._sfx == null or tela._sfx._players.size() != BattleSfx.POOL_SIZE:
		falhas.append("o banco polifonico de sons da batalha nao foi criado")
	if not BattleSfx.SONS.has("touch") or not BattleSfx.SONS.has("fusion"):
		falhas.append("os sons essenciais de carta nao foram carregados")
	tela._chain_visual = 0
	var velocidade_inicial := tela._velocidade_chain()
	tela._chain_visual = 3
	if tela._velocidade_chain() <= velocidade_inicial:
		falhas.append("a velocidade visual nao cresce com a chain")
	tela._chain_visual = 99
	if tela._velocidade_chain() > BattleScreen.CHAIN_VELOCIDADE_MAX:
		falhas.append("a aceleracao da chain ultrapassou o limite visual")
	if not is_equal_approx(BattleScreen.DISTRIBUICAO_FINAL_ACELERACAO, 1.5):
		falhas.append("a distribuicao final nao esta configurada em 1.5x")
	if tela._top_bar == null or tela._top_bar.position != Vector2(27, 19) \
			or tela._top_bar.size != Vector2(886, TopBar.ROW_H):
		falhas.append("a barra superior nao ocupa o contrato 886x72")
	else:
		if tela._top_bar._coin.size.x != TopBar.BOX_COIN \
				or tela._top_bar._gem.size.x != TopBar.BOX_GEM \
				or tela._top_bar._energy.size.x != TopBar.BOX_ENERGY:
			falhas.append("os contadores superiores perderam a largura reservada")
		if tela._top_bar._coin.align_right_in != TopBar.BOX_COIN \
				or tela._top_bar._energy.align_right_in != TopBar.BOX_ENERGY:
			falhas.append("os valores superiores nao estao ancorados a direita")
	if tela._stage_plate == null or tela._stage_plate.position != Vector2(22, 504):
		falhas.append("o STAGE nao esta no canto inferior esquerdo da arena")
	else:
		var stage_background := tela._stage_plate.get_child(0) as ColorRect
		if stage_background == null or not is_equal_approx(stage_background.color.a, 1.0) \
				or stage_background.color != StagePlate.PLATE_BG:
			falhas.append("o fundo do STAGE nao esta opaco")
	if tela._life_bar == null:
		falhas.append("o novo componente LIFE nao foi criado")
	else:
		if tela._life_bar.position != BattleScreen.LIFE_POSITION \
				or tela._life_bar.row_width != BattleScreen.LIFE_WIDTH:
			falhas.append("o LIFE nao ocupa a faixa inferior correta")
		if not tela._life_bar._well.clip_contents:
			falhas.append("a calha do LIFE nao esta recortando o fill")
		if tela._life_bar._fill.get_parent() != tela._life_bar._well \
				or tela._life_bar._tip.get_parent() != tela._life_bar._well:
			falhas.append("fill ou ponta do LIFE estao fora da calha")
		if tela._life_bar._fill.stretch_mode != TextureRect.STRETCH_TILE:
			falhas.append("a textura do LIFE esta sendo esticada")
		if tela._life_bar._value.text != "%d/%d" % [tela.estado.hp, tela.estado.hp_max]:
			falhas.append("o valor do LIFE nao reflete o HP real")
		if PlayerLifeBar.LABEL_GLYPH != 24 or PlayerLifeBar.VALUE_GLYPH != 24:
			falhas.append("os textos do LIFE voltaram ao tamanho ilegivel")
		var width_9999 := tela._life_bar._text_width("9999/9999",
			PlayerLifeBar.VALUE_GLYPH, PlayerLifeBar.TEXT_SPACING)
		if width_9999 > BattleScreen.LIFE_WIDTH - 120:
			falhas.append("o LIFE nao reserva espaco valido para 9999/9999")
		var life_max := PlayerLifeBar.new()
		life_max.row_width = BattleScreen.LIFE_WIDTH
		life_max.hp_max = 9999
		life_max.hp_current = 9999
		root.add_child(life_max)
		await process_frame
		if life_max._value.text != "9999/9999" \
				or not is_equal_approx(life_max._value.position.x + life_max._value.size.x,
					float(BattleScreen.LIFE_WIDTH)):
			falhas.append("9999/9999 nao fica inteiro e ancorado a direita")
		if life_max._well.position.x + life_max._well.size.x + PlayerLifeBar.GAP \
				> life_max._value.position.x:
			falhas.append("9999/9999 invade a calha do LIFE")
		life_max.queue_free()
	tela._chain_visual = 0
	if not is_equal_approx(tela._casas_bag[0].position.x, BattleScreen.BAG_X0):
		falhas.append("a primeira carta da BAG nao respeita o recuo configurado")
	if tela._casas_bag[0].position.x <= tela._casas_campo[0].position.x:
		falhas.append("a BAG perdeu o respiro interno em relacao a HAND")
	if tela._casas_bag[0]._icone._wiggle:
		falhas.append("as cartas da BAG ainda estao oscilando")
	if BattleScreen.FUSAO_TAM != BattleScreen.CAMPO_TAM:
		falhas.append("a fusao reduz o tamanho original das cartas da HAND")
	if tela._voos.z_index <= tela._casas_campo[0].z_index:
		falhas.append("a camada de fusao nao esta acima das cartas da HAND")
	if tela._aliados.size() != 5:
		falhas.append("a nova PARTY nao possui cinco cards")
	else:
		for i in tela._aliados.size():
			var ally := tela._aliados[i]
			if ally.size != PartyCard.CARD_SIZE or ally._card.size != PartyCard.CARD_SIZE:
				falhas.append("o card %d da PARTY nao mede 152x188" % i)
			if ally.position != Unidades.card_aliado(i).position:
				falhas.append("o card %d da PARTY esta fora do encaixe final" % i)
			if ally._card.leader != (i == 2):
				falhas.append("a marcacao de LEADER esta no slot errado")
		if tela._aliados[2]._card.size != tela._aliados[0]._card.size:
			falhas.append("o LEADER voltou a ter tamanho diferente dos aliados")
		if BitmapFontLabel.CELL != Vector2i(12, 16):
			falhas.append("a PARTY nao esta usando a fonte bitmap 1:1")
		var draws_esperados := {
			"dragon": Vector2(114, 108), "knight": Vector2(88, 116),
			"nature": Vector2(112, 108), "light": Vector2(108, 112),
			"dark": Vector2(104, 108), "heal": Vector2(96, 108),
		}
		if PartyCard.CHAR_DRAW != draws_esperados:
			falhas.append("tabela literal de desenho da PARTY foi alterada")
		for ally in tela._aliados:
			var card: PartyCard = ally._card
			if card.get_parent() != ally:
				falhas.append("PartyCard perdeu o wrapper AllyUnit")
				break
			if card._frame == null or not card._frame.clip_contents:
				falhas.append("FRAME da PARTY nao esta recortando o personagem")
				break
			if card._hero.get_parent() != card._frame:
				falhas.append("personagem da PARTY nao esta no espaco do FRAME")
				break
			var draw: Vector2 = PartyCard.CHAR_DRAW[card.element]
			var esperado := Vector2(round((PartyCard.FRAME_SIZE.x - draw.x) / 2.0),
				PartyCard.ART_BASELINE - draw.y)
			if card._hero.size != draw or card._hero.position != esperado:
				falhas.append("personagem %s nao respeita tabela/baseline: pos=%s size=%s esperado=%s/%s" % [card.element, card._hero.position, card._hero.size, esperado, draw])
				break
		var skill_touch_state := [false]
		tela._aliados[2]._card.skill_activated.connect(func() -> void: skill_touch_state[0] = true)
		tela._aliados[2]._card.set_charge(8)
		var touch := InputEventScreenTouch.new()
		touch.pressed = true
		tela._aliados[2]._card._gui_input(touch)
		if not skill_touch_state[0]:
			falhas.append("o novo card de LEADER nao responde ao toque da skill")
		tela._aliados[2]._card.set_charge(0)

	# Telefones 20:9 expandem a altura logica alem do canvas de referencia.
	# Fundo, moldura e flash precisam acompanhar essa area sem deformar a UI.
	root.size = Vector2i(940, 2094)
	await process_frame
	var fundo := tela.get_node("BackgroundFinal") as ColorRect
	if fundo.size != Vector2(940, 2094):
		falhas.append("o fundo nao preenche uma tela 20:9")
	if tela._flash.size != Vector2(940, 2094):
		falhas.append("o flash nao acompanha a tela expandida")

	var trio: Array[int] = []
	for i in EstadoBatalha.TAMANHO_MAO:
		var base: Carta = tela.estado.mao[i]
		if base == null:
			continue
		var candidatos: Array[int] = []
		for j in EstadoBatalha.TAMANHO_MAO:
			var outra: Carta = tela.estado.mao[j]
			if outra != null and Carta.combina(outra.tipo, base.tipo):
				candidatos.append(j)
		if candidatos.size() >= 3:
			trio = candidatos.slice(0, 3)
			break
	if trio.size() != 3:
		falhas.append("a mao inicial nao ofereceu um trio visual")
		_encerrar()
		return

	var next_inicial := tela._icone_next.tipo
	var bag_inicial: Array[String] = []
	for casa: BagSlot in tela._casas_bag:
		bag_inicial.append(casa.tipo_atual())
	if tela._casas_bag[-1].tipo_atual() != next_inicial:
		falhas.append("a ultima carta a direita da BAG nao corresponde a NEXT")
	await tela._ao_tocar_casa(trio[0])
	var icone_selecionado: CardIcon = tela._casas_campo[trio[0]]._icone
	if not is_equal_approx(icone_selecionado.position.y, -CardIcon.SUBIDA_SELECAO):
		falhas.append("a carta selecionada nao subiu para ganhar destaque")
	if not icone_selecionado._rim.visible:
		falhas.append("a marcacao da carta selecionada nao ficou visivel")
	var entradas_apos_primeira := 0
	for slot in [EstadoBatalha.ENTRADA_0, EstadoBatalha.ENTRADA_1]:
		if tela._casas_campo[slot].cheia():
			entradas_apos_primeira += 1
	if entradas_apos_primeira != 1:
		falhas.append("a primeira carta de NEXT nao entrou na sexta casa")
	for i in range(1, tela._casas_bag.size()):
		if tela._casas_bag[i].tipo_atual() != bag_inicial[i - 1]:
			falhas.append("a BAG nao deslizou da esquerda para a direita")
			break
	await tela._ao_tocar_casa(trio[1])
	var entradas := 0
	for i in range(EstadoBatalha.TAMANHO_MAO, tela._casas_campo.size()):
		if not tela._casas_campo[i].visible:
			falhas.append("uma sexta casa de ENTRADA desapareceu")
		elif tela._casas_campo[i].size != tela._casas_campo[int(i / 6) * 6].size:
			falhas.append("a ENTRADA nao tem o mesmo tamanho da carta da HAND")
		elif tela._casas_campo[i].cheia():
			entradas += 1
	if entradas != 2:
		falhas.append("as duas cartas de NEXT nao ocuparam as ENTRADAS")

	await tela._ao_tocar_casa(trio[2])
	var visiveis := 0
	for i in tela._casas_campo.size():
		if tela._casas_campo[i].visible:
			visiveis += 1
	if visiveis != 12:
		falhas.append("campo terminou com %d casas visiveis, esperado 12" % visiveis)
	for i in EstadoBatalha.TAMANHO_MAO:
		if not tela._casas_campo[i].cheia():
			falhas.append("casa %d nao foi reposta por NEXT" % i)
		if i % EstadoBatalha.ROW_SIZE > 0:
			var anterior := tela._casas_campo[i - 1]
			var gap := tela._casas_campo[i].position.x - anterior.position.x - anterior.size.x
			if not is_equal_approx(gap, 10.0):
				falhas.append("gap da HAND em %d e %.1f px; esperado 10 px" % [i, gap])
	for linha in 2:
		var quinta := tela._casas_campo[linha * EstadoBatalha.ROW_SIZE + 4]
		var entrada := tela._casas_campo[EstadoBatalha.TAMANHO_MAO + linha]
		var gap_entrada := entrada.position.x - quinta.position.x - quinta.size.x
		if not is_equal_approx(gap_entrada, 10.0):
			falhas.append("gap do 6o slot na linha %d e %.1f px; esperado 10 px" % [linha, gap_entrada])
	_encerrar()


func _encerrar() -> void:
	if falhas.is_empty():
		print("OK: HAND 2x6 (5 cartas + ENTRADA), gap 10 e fluxo BAG -> NEXT validados")
		quit(0)
	else:
		for falha in falhas:
			push_error(falha)
		quit(1)
