extends SceneTree

var falhas: Array[String] = []


func _initialize() -> void:
	call_deferred("_executar")


func _executar() -> void:
	root.size = Vector2i(940, 1685)
	var tela := (load("res://scenes/battle/BattleScreen.tscn") as PackedScene).instantiate() as BattleScreen
	root.add_child(tela)
	await process_frame
	tela._chain_visual = 0
	var velocidade_inicial := tela._velocidade_chain()
	tela._chain_visual = 3
	if tela._velocidade_chain() <= velocidade_inicial:
		falhas.append("a velocidade visual nao cresce com a chain")
	tela._chain_visual = 99
	if tela._velocidade_chain() > BattleScreen.CHAIN_VELOCIDADE_MAX:
		falhas.append("a aceleracao da chain ultrapassou o limite visual")
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
