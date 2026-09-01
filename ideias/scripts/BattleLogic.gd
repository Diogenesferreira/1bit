extends RefCounted
class_name BattleLogic

# Toda a regra da batalha fica aqui, separada da tela.
# Isso permite testar a logica sem abrir o jogo.
#
# Mecanica (corrigida a partir de screenshots do jogo original):
#
# - A mao e 2 FILEIRAS de 5 cartas. As cartas NAO deslizam: cada uma
#   fica na casa dela e, quando sai, deixa a casa VAZIA no lugar exato
#   (e o que aparece nos prints do jogo original).
#
# - Tocar numa carta a MARCA: ela sai da casa (que fica VAZIA) e fica
#   pairando logo acima dela, piscando. Ao mesmo tempo uma carta NOVA
#   do deck DESCE no espaco da direita, na casa de entrada da fileira
#   - ela ja pode ser marcada, entao da pra montar o trio contando com
#   ela. Tocar de novo na marcada desfaz: ela volta pra casa e a que
#   desceu volta pro deck.
#
# - Como a 3a marcada fecha o trio na hora, so DUAS cartas descem
#   durante a cadeia (uma em cada fileira, uma EM CIMA da outra).
#
# - As casas que ficaram vazias CONTINUAM vazias ate o fim da corrente:
#   so na chuva final elas sao preenchidas e a mao e redistribuida.
#
# - Cartas que descem do deck NUNCA entram sozinhas na cadeia: quem
#   escolhe e sempre o jogador.
#
# - O DANO NAO E APLICADO COMBO A COMBO. Cada trio que fecha (manual
#   ou automatico, via cascata) so ACUMULA um valor parcial no
#   Digimon daquela cor/elemento. Isso pode se repetir varias vezes
#   numa unica corrente (cascata: todo trio ja pronto no resto da mao
#   dispara sozinho, sem custo). SO NO FINAL da corrente inteira, a
#   soma de tudo que foi acumulado e descontada do inimigo de uma vez
#   (a defesa dele entra aqui, no total, nao em cada combo).
#
# - Trio de numeros iguais (4-4-4) ou sequencia (2-3-4) = CRITICO 1.5x
#   (aplicado na contribuicao daquele trio especifico).
#
# - Tocar numa cor diferente da cadeia ativa ABANDONA a cadeia atual
#   (as cartas ja selecionadas voltam ao normal, sem valer nada) e
#   comeca uma cadeia nova com a carta tocada - nunca trava o jogo.
#
# - Um turno do inimigo passa quando pelo menos um combo disparou OU
#   quando um ABANDONO aconteceu. So fica de graca continuar tocando
#   cartas da MESMA cor rumo a um combo real.

const ROW_SIZE := 5
const NUM_ROWS := 2
const TAMANHO_MAO := ROW_SIZE * NUM_ROWS  # 10 casas fixas
# Cada fileira tem UMA casa de entrada no espaco vazio da direita:
# e ali que a carta do deck desce quando voce marca uma carta. Como
# sao duas fileiras, as duas que descem numa cadeia ficam uma EM CIMA
# da outra, na mesma coluna da direita.
const ENTRADA_0 := TAMANHO_MAO      # entrada da fileira de cima
const ENTRADA_1 := TAMANHO_MAO + 1  # entrada da fileira de baixo
const TOTAL_SLOTS := TAMANHO_MAO + NUM_ROWS  # 12
const QTD_PROXIMAS := 9  # quantas cartas do deck ficam visiveis na fila do FLOWBAG (Batalha.gd) - o layout "Digital Arena" usa uma grade reta de 9 casas. So muda quanto do saco DETERMINISTICO (ver Bag.gd) fica visivel pro jogador; nao muda sorteio, regra ou pontuacao.

const CORES_DE_ATAQUE := [
	CardData.Cor.VERMELHO, CardData.Cor.AZUL, CardData.Cor.VERDE,
	CardData.Cor.AMARELO, CardData.Cor.ROXO,
]

# Trio so de coringas: o dano vai para TODOS os aliados (confirmado nos
# videos), mas a PROPORCAO ainda nao. Com 1.0 cada aliado bate cheio -
# o trio vale ~5 combos. Baixe para 0.2 se quiser que o total fique
# igual ao de um combo normal, so que espalhado pelos 5.
const FRACAO_TRIO_CORINGA := 1.0

var rng := RandomNumberGenerator.new()
# De onde vem toda carta nova. Ver Bag.gd: composicao fixa e
# embaralhada, no lugar do sorteio sem memoria de antes.
var bag: Bag

# Time: uma cor de carta -> um Digimon
var time: Dictionary = {}
var inimigo: Digimon
var contador_inimigo_max := 3
var contador_inimigo := 3

# HP unico do time (soma dos HPs dos membros), como no jogo original
var hp_jogador_max := 0
var hp_jogador := 0

var mao: Array[CardData] = []       # 2 fileiras de 5 (0-4 e 5-9), null = casa vazia
var proximas: Array[CardData] = []  # fila de compra do deck
var zona: Array[CardData] = []      # trio em montagem (0 a 2 cartas antes de fechar)
var zona_slots: Array[int] = []     # de que casa saiu cada carta marcada
# em que casa de entrada desceu a carta de cada marcada (-1 se nao
# desceu nenhuma - caso da 3a, que fecha o trio na hora)
var zona_descidas: Array[int] = []

var fim := false
var vitoria := false

# Undo: pilha de snapshots, um por toque que nao fechou combo.
# Da para desfazer VARIOS toques, voltando ate o estado de antes da
# cadeia comecar. Quando um combo dispara, a pilha zera (sem volta).
var pode_desfazer := false
var _snapshots: Array = []

# Quantas vezes _garantir_saida precisou recolorir uma carta. E o preco
# da garantia de mao jogavel: cada intervencao dessas foge da
# composicao do saco. So serve para medir (ver TestBalance) - se este
# numero for alto, a garantia esta cara demais e o desenho precisa
# mudar, nao o parametro.
var saidas_forcadas := 0

func _init() -> void:
	rng.randomize()
	bag = Bag.new(rng)

	time[CardData.Cor.VERMELHO] = Digimon.new("Agumon", 1, 70, 38, 5, 10)
	time[CardData.Cor.AZUL] = Digimon.new("Gabumon", 1, 68, 36, 6, 9)
	time[CardData.Cor.VERDE] = Digimon.new("Palmon", 1, 72, 34, 5, 8)
	time[CardData.Cor.AMARELO] = Digimon.new("Patamon", 1, 60, 40, 4, 12)
	time[CardData.Cor.ROXO] = Digimon.new("Impmon", 1, 65, 42, 4, 11)

	for digimon: Digimon in time.values():
		hp_jogador_max += digimon.hp
	hp_jogador = hp_jogador_max

	inimigo = Digimon.new("Kuwagamon", 5, 3500, 70, 18, 7)
	contador_inimigo = contador_inimigo_max

	for i in TAMANHO_MAO:
		mao.append(bag.comprar())
	# nos videos do jogo original NUNCA aparece uma mao inicial sem
	# sequencia: a abertura da partida e sempre jogavel
	_garantir_saida(mao)
	# a mao inicial ja vem arrumada (cores agrupadas, valores
	# crescentes), como nos prints do jogo original
	mao.sort_custom(_antes_de)
	for i in NUM_ROWS:
		mao.append(null)  # casas de entrada comecam vazias
	for i in QTD_PROXIMAS:
		proximas.append(bag.comprar())

func comprar_carta() -> CardData:
	var carta: CardData = proximas.pop_front()
	proximas.append(bag.comprar())
	return carta

# Fotografia da fila de compra no instante logo DEPOIS de a carta sair.
# Vai junto de todo evento que mexe no deck porque a tela reproduz os
# eventos quando a logica JA RODOU A CORRENTE INTEIRA - a essa altura
# `proximas` esta no estado final, varias cartas a frente. Sem estas
# fotos a regua desenhada nunca bate com a carta que esta descendo (a
# pilha parece travada). Com elas a fila anda um passo por carta, no
# ritmo da animacao.
func _foto_da_fila() -> Array:
	var foto: Array = []
	for c: CardData in proximas:
		foto.append({"cor": c.cor, "valor": c.valor})
	return foto

# Cor de um conjunto de cartas: a primeira que nao e coringa. Se todas
# forem coringa, o proprio CORINGA.
static func cor_do_trio(cartas: Array) -> int:
	for c: CardData in cartas:
		if c.cor != CardData.Cor.CORINGA:
			return c.cor
	return CardData.Cor.CORINGA

# Cor da cadeia em montagem (-1 se nao ha nada marcado). Com so
# coringas marcados, a cadeia ainda aceita qualquer cor.
func cor_zona() -> int:
	if zona.is_empty():
		return -1
	return cor_do_trio(zona)

func linha_de(idx: int) -> int:
	if idx < TAMANHO_MAO:
		return idx / ROW_SIZE
	return idx - TAMANHO_MAO  # casas de entrada: uma por fileira

# Toque na carta que esta pairando (marcada) sobre a casa dada:
# desmarca. E uma acao separada de tocar() porque a casa ficou vazia -
# quem responde ao toque ali e a carta marcada, nao a casa.
func desmarcar(slot: int) -> Dictionary:
	var resultado := {
		"tipo": "jogada", "eventos": [], "n_combos": 0,
		"dano_total": 0, "cura_total": 0,
	}
	var pos := zona_slots.find(slot)
	if fim or pos == -1:
		return {"tipo": "ignorado"}
	var snapshot := _tirar_snapshot()
	_devolver_marcada(pos, resultado)
	_snapshots.append(snapshot)
	pode_desfazer = true
	return resultado

# Uma carta do deck desce na casa de ENTRADA (o espaco da direita) da
# fileira dada. Se ela ja estiver ocupada, desce na da outra fileira -
# e por isso que as duas de uma cadeia ficam uma em cima da outra.
# Devolve o slot usado, ou -1 se as duas entradas estavam ocupadas.
func _descer_carta(l: int, resultado: Dictionary) -> int:
	var candidatos := [ENTRADA_0, ENTRADA_1] if l == 0 else [ENTRADA_1, ENTRADA_0]
	for slot: int in candidatos:
		# a casa tem que estar livre E nao pode ser a de uma carta que
		# esta marcada: senao a nova desceria bem embaixo dela
		if mao[slot] == null and not zona_slots.has(slot):
			var nova := comprar_carta()
			mao[slot] = nova
			resultado.eventos.append({
				"tipo": "carta_desce", "slot": slot,
				"cor": nova.cor, "valor": nova.valor,
				"fila": _foto_da_fila(),
			})
			return slot
	return -1

# Desfaz uma marcacao: a marcada volta pra casa dela e a carta que
# desceu por causa dela volta pro topo do deck (desfazendo
# comprar_carta() exatamente).
func _devolver_marcada(pos: int, resultado: Dictionary) -> void:
	var slot: int = zona_slots[pos]
	var carta: CardData = zona[pos]
	var descida: int = zona_descidas[pos]
	if descida != -1 and mao[descida] != null:
		proximas.pop_back()
		proximas.push_front(mao[descida])
		mao[descida] = null
		resultado.eventos.append({
			"tipo": "carta_volta", "slot": descida, "fila": _foto_da_fila(),
		})
	mao[slot] = carta
	zona.remove_at(pos)
	zona_slots.remove_at(pos)
	zona_descidas.remove_at(pos)
	# o evento leva a carta junto: a tela reproduz os eventos depois de
	# a logica ja ter terminado tudo, entao nao pode consultar mao[slot]
	resultado.eventos.append({
		"tipo": "deselecao", "slot": slot, "cor": carta.cor, "valor": carta.valor,
	})

# Trocar de cor no meio da cadeia: todas as marcadas voltam pras casas
# delas (e as cartas que tinham descido voltam pro deck).
func _abandonar(resultado: Dictionary) -> void:
	resultado.eventos.append({"tipo": "abandono"})
	for pos in range(zona.size() - 1, -1, -1):
		_devolver_marcada(pos, resultado)

# Toque do jogador numa carta da mao.
# Devolve os eventos na ordem exata para a tela animar:
#   {tipo:"abandono"}                                cadeia trocada
#   {tipo:"selecao", slot, cor, valor}               carta marcada (sobe no lugar)
#   {tipo:"deselecao", slot}                         toque de novo tirou a selecao
#   {tipo:"carta_desce", slot, cor, valor, fila}     carta nova desceu na casa da marcada
#   {tipo:"carta_volta", slot, fila}                 desmarcou: a nova voltou pro deck
# Todo evento que mexe no deck leva "fila": a regua de compra como ela
# ficou NAQUELE instante. E por ela que a tela anda a pilha (ver
# _foto_da_fila).
#   {tipo:"trio_sobe", slots, cartas, vazios}        as 3 vao pro centro e se fundem
#   {tipo:"combo", cor, cadeia, critico, dano_parcial/cura}  trio fechou, valor so ACUMULA
#   {tipo:"redistribuicao", mao}                     mao reorganizada por cor/numero
#   {tipo:"ataque_final", contribuicoes, dano_total, cura_total, hp_inimigo, hp_jogador}
func tocar(idx: int) -> Dictionary:
	if fim or idx < 0 or idx >= mao.size() or mao[idx] == null:
		return {"tipo": "ignorado"}

	var snapshot := _tirar_snapshot()

	var resultado := {
		"tipo": "jogada",
		"eventos": [],
		"n_combos": 0,
		"dano_total": 0,
		"cura_total": 0,
	}
	var acumulado: Dictionary = {}  # cor -> valor parcial somado nesta corrente

	# Tocar noutra cor abandona a cadeia atual: as cartas ja
	# selecionadas voltam ao normal (nao valem nada) e uma cadeia
	# nova comeca com a carta tocada.
	if not zona.is_empty() and not CardData.combina(mao[idx].cor, cor_zona()):
		_abandonar(resultado)

	# Caso de borda: se a carta tocada era uma que tinha DESCIDO por
	# causa de uma marcada, o abandono acabou de devolve-la pro deck -
	# nao ha o que marcar, o toque so abandonou mesmo.
	if mao[idx] != null:
		# A carta marcada SAI da casa, que fica vazia.
		var carta: CardData = mao[idx]
		zona.append(carta)
		zona_slots.append(idx)
		mao[idx] = null
		resultado.eventos.append({
			"tipo": "selecao", "slot": idx, "cor": carta.cor, "valor": carta.valor,
		})

		if zona.size() >= 3:
			# na terceira o trio fecha na hora - nada desce
			zona_descidas.append(-1)
			_fechar_trio(resultado, acumulado)
			_fase_cascata(resultado, acumulado)
			_completar_mao(resultado)
		else:
			# nas duas primeiras, uma carta do deck desce no espaco da
			# direita (casa de entrada) e ja pode ser usada no trio
			zona_descidas.append(_descer_carta(linha_de(idx), resultado))
	_resolver_ataque_final(resultado, acumulado)
	_turno_inimigo(resultado)

	if resultado.n_combos > 0:
		_snapshots.clear()
		pode_desfazer = false
	else:
		_snapshots.append(snapshot)
		pode_desfazer = true
	return resultado

func _tirar_snapshot() -> Dictionary:
	return {
		"mao": mao.duplicate(),
		"proximas": proximas.duplicate(),
		"zona": zona.duplicate(),
		"zona_slots": zona_slots.duplicate(),
		"zona_descidas": zona_descidas.duplicate(),
		"contador_inimigo": contador_inimigo,
		"hp_jogador": hp_jogador,
		"hp_inimigo": inimigo.hp,
	}

# Desfaz o ultimo toque que ainda nao fechou trio. Pode ser chamado
# varias vezes seguidas, voltando toque a toque ate antes da cadeia.
func desfazer() -> bool:
	if _snapshots.is_empty():
		return false
	var s: Dictionary = _snapshots.pop_back()
	mao = (s.mao as Array[CardData]).duplicate()
	proximas = (s.proximas as Array[CardData]).duplicate()
	zona = (s.zona as Array[CardData]).duplicate()
	zona_slots = (s.zona_slots as Array[int]).duplicate()
	zona_descidas = (s.zona_descidas as Array[int]).duplicate()
	contador_inimigo = s.contador_inimigo
	hp_jogador = s.hp_jogador
	inimigo.hp = s.hp_inimigo
	pode_desfazer = not _snapshots.is_empty()
	return true

# Fecha o trio que esta selecionado (zona/zona_slots): as 3 cartas
# sobem juntas para o centro e se fundem. Um slot -1 quer dizer que a
# carta veio do topo do DECK, nao da mao.
func _fechar_trio(resultado: Dictionary, acumulado: Dictionary) -> void:
	var cartas: Array = []
	for c: CardData in zona:
		cartas.append({"cor": c.cor, "valor": c.valor})
	# casas que ficaram vazias na mao
	var vazios: Array[int] = []
	for i in zona_slots.size():
		var slot: int = zona_slots[i]
		if slot >= 0 and mao[slot] == null:
			vazios.append(slot)
	resultado.eventos.append({
		"tipo": "trio_sobe", "slots": zona_slots.duplicate(),
		"cartas": cartas, "vazios": vazios,
	})
	zona_slots.clear()
	zona_descidas.clear()
	_disparar_zona(resultado, acumulado)

# Fase cascata: todo trio presente entre as cartas AINDA NA MAO
# dispara sozinho, de graca - mas aqui os espacos consumidos NAO sao
# repostos (ficam vazios na direita das fileiras, como nos prints do
# jogo original). Sem reposicao, a mao vai esgotando e a corrente e
# naturalmente limitada. Quando nao ha mais trio:
#   - sobrou no maximo 1 carta -> RENOVACAO: a mao inteira desce de
#     novo e a corrente pode continuar (o momento raro de virada);
#   - sobrou mais de 1 -> a corrente acaba; a chuva final de cartas
#     (em _completar_mao) preenche os vazios SEM gerar combo novo.
func _fase_cascata(resultado: Dictionary, acumulado: Dictionary) -> void:
	while true:
		var plano := _melhor_trio()
		if not plano.is_empty():
			for idx: int in plano.slots:
				zona.append(mao[idx])
				zona_slots.append(idx)
				zona_descidas.append(-1)
				mao[idx] = null
			if plano.usa_deck:
				var puxada := comprar_carta()
				zona.append(puxada)
				zona_slots.append(-1)  # -1 = veio do deck, nao da mao
				zona_descidas.append(-1)
				resultado.eventos.append({
					"tipo": "puxa_do_deck", "cor": puxada.cor, "valor": puxada.valor,
					"fila": _foto_da_fila(),
				})
			_fechar_trio(resultado, acumulado)
			continue

		var restantes := 0
		for c: CardData in mao:
			if c != null:
				restantes += 1
		if restantes > 1:
			break

		# sobrou no maximo 1 carta: renova a mao INTEIRA (a que sobrou
		# tambem e descartada) e a corrente pode continuar na mao nova
		resultado.eventos.append({"tipo": "renovacao"})
		mao[ENTRADA_0] = null
		mao[ENTRADA_1] = null
		for i in TAMANHO_MAO:
			var nova := comprar_carta()
			mao[i] = nova
			resultado.eventos.append({
				"tipo": "nova_carta", "slot": i,
				"cor": nova.cor, "valor": nova.valor,
				"fila": _foto_da_fila(),
			})

# Separa os slots ocupados por cor, com os CORINGAS a parte (eles
# entram em qualquer trio).
func _mao_por_cor() -> Dictionary:
	var por_cor: Dictionary = {}
	var coringas: Array[int] = []
	for i in mao.size():
		if mao[i] == null:
			continue
		if mao[i].cor == CardData.Cor.CORINGA:
			coringas.append(i)
		else:
			if not por_cor.has(mao[i].cor):
				por_cor[mao[i].cor] = []
			(por_cor[mao[i].cor] as Array).append(i)
	return {"por_cor": por_cor, "coringas": coringas}

# Qual trio a cascata fecha agora. Devolve {} se nao ha nenhum, ou
#   {"slots": [casas da mao], "usa_deck": bool}
#
# REGRA (tirada dos videos do jogo original): entre todos os trios
# possiveis, fecha o da cor que tem MENOS cartas na mao.
#
# A razao nao e estetica. Carta sozinha ENTOPE a mao: ela nunca fecha
# trio por conta propria e fica ocupando casa ate o fim da corrente. Ao
# gastar sempre a cor mais escassa, a cascata desentope a mao e abre
# espaco para os proximos combos - que e o que faz as correntes longas
# existirem. O coringa e a ferramenta que torna isso possivel, porque
# uma cor com 1 ou 2 cartas so fecha trio com ajuda dele.
#
# A carta do topo do DECK conta como candidata quando serve (mesma cor
# ou coringa) e tem preferencia sobre os coringas da mao na hora de
# completar: puxa-la faz a fila andar e traz carta nova para a corrente.
func _melhor_trio() -> Dictionary:
	var mapa := _mao_por_cor()
	var por_cor: Dictionary = mapa.por_cor
	var coringas: Array[int] = mapa.coringas
	var topo: CardData = proximas[0]

	var melhor_cor := -1
	var melhor_qtd := 0
	for cor: int in por_cor:
		var qtd: int = (por_cor[cor] as Array).size()
		var ajuda := coringas.size()
		if CardData.combina(topo.cor, cor):
			ajuda += 1
		if qtd + ajuda < 3:
			continue
		# menor quantidade na mao vence; empate fica com a menor cor,
		# so para o resultado ser estavel entre partidas
		if melhor_cor == -1 or qtd < melhor_qtd or (qtd == melhor_qtd and cor < melhor_cor):
			melhor_cor = cor
			melhor_qtd = qtd

	if melhor_cor != -1:
		var slots: Array[int] = []
		for s: int in (por_cor[melhor_cor] as Array):
			if slots.size() == 3:
				break
			slots.append(s)
		# o deck entra antes dos coringas da mao: assim a fila anda e a
		# mao guarda o coringa para desentupir outra cor depois
		var usa_deck := false
		if slots.size() < 3 and CardData.combina(topo.cor, melhor_cor):
			usa_deck = true
		for s: int in coringas:
			if slots.size() + (1 if usa_deck else 0) >= 3:
				break
			slots.append(s)
		return {"slots": slots, "usa_deck": usa_deck}

	# trio so de coringas (raro): bate com o time inteiro
	var so_coringas := coringas.size() + (1 if topo.cor == CardData.Cor.CORINGA else 0)
	if so_coringas >= 3:
		var slots: Array[int] = []
		var usa_deck := topo.cor == CardData.Cor.CORINGA
		for s: int in coringas:
			if slots.size() + (1 if usa_deck else 0) >= 3:
				break
			slots.append(s)
		return {"slots": slots, "usa_deck": usa_deck}

	return {}

# Chuva final: preenche os espacos vazios que a cascata deixou,
# descendo cartas novas pela direita - sem gerar combos novos. Depois
# a mao inteira e reorganizada e redistribuida (ver _redistribuir).
func _completar_mao(resultado: Dictionary) -> void:
	# 1) o que estava esperando nas casas de entrada entra na mao
	for entrada: int in [ENTRADA_0, ENTRADA_1]:
		if mao[entrada] == null:
			continue
		for i in TAMANHO_MAO:
			if mao[i] == null:
				mao[i] = mao[entrada]
				mao[entrada] = null
				resultado.eventos.append({"tipo": "entra_na_mao", "de": entrada, "para": i})
				break
	# 2) o deck completa o que ainda falta (a mao sempre volta cheia)
	for i in TAMANHO_MAO:
		if mao[i] == null:
			var nova := comprar_carta()
			mao[i] = nova
			# "chuva": marca as cartas do fim da corrente, que a tela
			# leva do deck direto para o monte da redistribuicao
			resultado.eventos.append({
				"tipo": "nova_carta", "slot": i, "chuva": true,
				"cor": nova.cor, "valor": nova.valor,
				"fila": _foto_da_fila(),
			})
	_redistribuir(resultado)

# Fim da corrente: as cartas se juntam e sao espalhadas de novo pela
# mao AGRUPADAS POR COR e, dentro da cor, em ordem numerica crescente
# - e o que o jogo original faz para facilitar enxergar os combos.
func _redistribuir(resultado: Dictionary) -> void:
	var cartas: Array[CardData] = []
	for c: CardData in mao:
		if c != null:
			cartas.append(c)
	# a mao so volta para o jogador se tiver como jogar nela
	_garantir_saida(cartas)
	cartas.sort_custom(_antes_de)
	var estado: Array = []
	for i in mao.size():
		mao[i] = cartas[i] if i < cartas.size() else null
		if mao[i] == null:
			estado.append(null)
		else:
			estado.append({"cor": mao[i].cor, "valor": mao[i].valor})
	resultado.eventos.append({"tipo": "redistribuicao", "mao": estado})

# Existe pelo menos um trio POSSIVEL neste conjunto de cartas? Basta
# uma cor cujo total (contando os coringas, que entram em qualquer
# trio) chegue a 3.
func _tem_saida(cartas: Array) -> bool:
	var por_cor: Dictionary = {}
	var coringas := 0
	for c: CardData in cartas:
		if c == null:
			continue
		if c.cor == CardData.Cor.CORINGA:
			coringas += 1
		else:
			por_cor[c.cor] = int(por_cor.get(c.cor, 0)) + 1
	if coringas >= 3:
		return true
	for cor: int in por_cor:
		if int(por_cor[cor]) + coringas >= 3:
			return true
	return false

# MAO SEM SAIDA nunca acontece: nos videos do jogo original nao existe
# uma mao onde nao da para fazer nada. Quando o sorteio entrega uma
# assim, o conserto e CIRURGICO - em vez de resortear a mao inteira
# (que enviesaria a distribuicao toda), uma unica carta ORFA vira a cor
# mais abundante. Isso resolve o travamento e ainda tira um orfao da
# mao, que e exatamente o que a cascata tenta fazer.
#
# Isto e um PISO, nao generosidade: garante que existe um caminho, nao
# que ele seja bom. O jogador ainda precisa enxergar o trio e gastar o
# turno nele.
func _garantir_saida(cartas: Array) -> void:
	var protecao := 0
	while not _tem_saida(cartas) and protecao < TAMANHO_MAO:
		protecao += 1
		var por_cor: Dictionary = {}
		for i in cartas.size():
			var c: CardData = cartas[i]
			if c == null or c.cor == CardData.Cor.CORINGA:
				continue
			if not por_cor.has(c.cor):
				por_cor[c.cor] = []
			(por_cor[c.cor] as Array).append(i)

		# cor mais abundante = a que esta mais perto de fechar trio;
		# cor mais escassa = de onde sai a carta sacrificada (o orfao)
		#
		# A orfa e escolhida SEMPRE entre as OUTRAS cores, nunca a
		# propria alvo. Sem isso, a mao mais travada de todas - 2 de
		# cada uma das 5 cores, empate perfeito - escolhia a mesma cor
		# como alvo e como orfa, caia no `break` e voltava ao jogador
		# sem trio nenhum (acontecia em ~22% das partidas).
		var cores: Array = por_cor.keys()
		cores.sort()  # empate resolvido pela ordem fixa da cor
		var cor_alvo := -1
		for cor: int in cores:
			if cor_alvo == -1 or (por_cor[cor] as Array).size() > (por_cor[cor_alvo] as Array).size():
				cor_alvo = cor
		var cor_orfa := -1
		for cor: int in cores:
			if cor == cor_alvo:
				continue
			if cor_orfa == -1 or (por_cor[cor] as Array).size() < (por_cor[cor_orfa] as Array).size():
				cor_orfa = cor
		if cor_alvo == -1 or cor_orfa == -1:
			break
		var idx: int = (por_cor[cor_orfa] as Array)[0]
		cartas[idx] = CardData.new(cor_alvo, cartas[idx].valor)
		saidas_forcadas += 1

func _antes_de(a: CardData, b: CardData) -> bool:
	if a.cor != b.cor:
		return a.cor < b.cor
	return a.valor < b.valor

# Fecha o trio atual na zona e ACUMULA a contribuicao dele (nao
# aplica dano/cura ainda - isso so acontece em _resolver_ataque_final,
# no fim de toda a corrente).
func _disparar_zona(resultado: Dictionary, acumulado: Dictionary) -> void:
	# a cor do trio e a da primeira carta que NAO e coringa (o coringa
	# so acompanha); trio so de coringas cai no caso especial abaixo
	var cor := cor_do_trio(zona)
	var cadeia: int = resultado.n_combos
	var soma := 0
	var valores: Array[int] = []
	for c: CardData in zona:
		soma += c.valor
		valores.append(c.valor)
	zona.clear()

	# Critico: 3 numeros iguais (4-4-4) ou sequencia (2-3-4)
	valores.sort()
	var critico := (valores[0] == valores[1] and valores[1] == valores[2]) \
		or (valores[1] == valores[0] + 1 and valores[2] == valores[1] + 1)

	var ev := {"tipo": "combo", "cor": cor, "cadeia": cadeia, "critico": critico}

	if cor == CardData.Cor.CORINGA:
		# TRIO SO DE CORINGAS (raro): o dano vai para TODOS os aliados.
		# A PROPORCAO ainda esta em aberto - hoje cada um bate cheio
		# (FRACAO_TRIO_CORINGA = 1.0), o que faz o trio valer ~5 combos.
		# Baixar essa constante e o unico ajuste necessario.
		var total_coringa := 0
		for cor_ataque: int in CORES_DE_ATAQUE:
			var aliado: Digimon = time[cor_ataque]
			var parcial_f := (aliado.ataque + soma * 10) * (1.0 + 0.3 * cadeia)
			if critico:
				parcial_f *= 1.5
			var parcial_cor := maxi(int(parcial_f * FRACAO_TRIO_CORINGA), 1)
			acumulado[cor_ataque] = int(acumulado.get(cor_ataque, 0)) + parcial_cor
			total_coringa += parcial_cor
		ev["dano_parcial"] = total_coringa
		ev["atacante"] = "TIME INTEIRO"
		ev["todas_as_cores"] = true
		resultado.eventos.append(ev)
		resultado.n_combos += 1
		return

	if cor == CardData.Cor.CURA:
		var cura := soma * 12
		if critico:
			cura = int(cura * 1.5)
		acumulado[cor] = int(acumulado.get(cor, 0)) + cura
		ev["cura"] = cura
	else:
		var digimon: Digimon = time[cor]
		var dano_f := (digimon.ataque + soma * 10) * (1.0 + 0.3 * cadeia)
		if critico:
			dano_f *= 1.5
		var parcial := maxi(int(dano_f), 1)
		acumulado[cor] = int(acumulado.get(cor, 0)) + parcial
		ev["dano_parcial"] = parcial
		ev["atacante"] = digimon.nome

	resultado.eventos.append(ev)
	resultado.n_combos += 1

# So aqui, no fim da corrente inteira, o que foi acumulado por
# Digimon/cor de fato desconta do inimigo (a defesa dele entra no
# TOTAL somado, uma unica vez) e cura o time.
func _resolver_ataque_final(resultado: Dictionary, acumulado: Dictionary) -> void:
	if acumulado.is_empty():
		return

	var contribuicoes: Array = []
	var dano_bruto := 0
	var cura_total := 0
	for cor: int in acumulado.keys():
		var valor: int = acumulado[cor]
		if cor == CardData.Cor.CURA:
			cura_total += valor
			contribuicoes.append({"cor": cor, "valor": valor, "cura": true})
		else:
			dano_bruto += valor
			contribuicoes.append({"cor": cor, "valor": valor, "cura": false})

	var dano_total := 0
	if dano_bruto > 0:
		dano_total = maxi(dano_bruto - inimigo.defesa, 1)
		inimigo.hp = maxi(inimigo.hp - dano_total, 0)
	if cura_total > 0:
		hp_jogador = mini(hp_jogador + cura_total, hp_jogador_max)

	resultado.dano_total = dano_total
	resultado.cura_total = cura_total

	resultado.eventos.append({
		"tipo": "ataque_final",
		"contribuicoes": contribuicoes,
		"dano_bruto": dano_bruto,
		"dano_total": dano_total,
		"cura_total": cura_total,
		"hp_inimigo": inimigo.hp,
		"hp_jogador": hp_jogador,
	})

	if inimigo.hp <= 0:
		fim = true
		vitoria = true

# O turno do inimigo passa quando um combo dispara OU quando um
# abandono acontece (trocar de cor no meio de uma cadeia). Taps que
# so avancam rumo a um combo real (sem abandonar nada) sao de graca.
func _turno_inimigo(resultado: Dictionary) -> void:
	if fim:
		if vitoria:
			resultado["fim"] = "vitoria"
		return
	var abandonou := false
	for ev: Dictionary in resultado.eventos:
		if ev.tipo == "abandono":
			abandonou = true
			break
	if resultado.n_combos == 0 and not abandonou:
		return
	contador_inimigo -= 1
	_ataque_do_inimigo_se_zerou(resultado)

func _ataque_do_inimigo_se_zerou(resultado: Dictionary) -> void:
	if contador_inimigo > 0:
		return
	var defesa_media := 0.0
	for digimon: Digimon in time.values():
		defesa_media += digimon.defesa
	defesa_media /= time.size()
	var dano_inimigo := maxi(inimigo.ataque - int(defesa_media / 2.0) + rng.randi_range(-5, 8), 5)
	hp_jogador = maxi(hp_jogador - dano_inimigo, 0)
	contador_inimigo = contador_inimigo_max
	resultado["ataque_inimigo"] = dano_inimigo
	if hp_jogador <= 0:
		fim = true
		vitoria = false
		resultado["fim"] = "derrota"
