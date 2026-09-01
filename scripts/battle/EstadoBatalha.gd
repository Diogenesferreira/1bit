extends RefCounted
class_name EstadoBatalha

# A REGRA da batalha, separada da tela. Rodando so isto da para jogar
# partidas inteiras headless - e o que tests/test_batalha.gd faz.
#
# Esta e a mecanica dos MDs (ideias/regra-de-campo.md + mecanica-do-
# binario.md), portada para os elementos e as unidades do handoff. NAO
# e mais o "fusion lane" do prototipo HTML, que so aceitava 3 cartas
# soltas e nao tinha cascata.
#
# O CAMPO tem 12 casas: 2 fileiras de 5 (a mao) + a COLUNA 6 de cada
# fileira, que e a casa de ENTRADA e comeca VAZIA.
#
# Um toque:
#   1a e 2a carta marcadas -> saem da mao logica, levantam visualmente
#     na propria casa e, a cada marcacao, UMA carta do topo do saco DESCE na
#     casa de ENTRADA da fileira. Essa carta ja pode fechar o trio - e
#     assim que "combinar com a proxima da BAG" acontece.
#   3a carta -> fecha o trio na hora (nada desce).
#   Tocar de novo numa marcada -> desmarca, e a carta que desceu por
#     causa dela volta pro topo do saco.
#   Tocar num tipo diferente -> ABANDONA a cadeia (tudo volta) e comeca
#     cadeia nova com a carta tocada. Abandono gasta turno.
#
# CASCATA: fechado um trio, todo trio que ja estiver pronto no resto da
# mao dispara sozinho, de graca, um atras do outro - sem reposicao, as
# casas vao ficando vazias. Cada elo soma +30% de dano ao proximo. Se
# sobrar no maximo 1 carta, a mao inteira se RENOVA e a corrente
# continua. Quando nao ha mais trio: as cartas das ENTRADAS entram na
# mao, o saco faz a chuva final, a mao e redistribuida (agrupada por
# tipo, valor crescente) e so entao o dano acumulado na corrente
# INTEIRA e aplicado de uma vez.
#
# O que a tela recebe e uma LISTA DE EVENTOS ja resolvida - ela so
# reproduz em ordem, nunca consulta o estado no meio da animacao.

# --- campo -----------------------------------------------------------
const ROW_SIZE := 5
const NUM_ROWS := 2
const TAMANHO_MAO := ROW_SIZE * NUM_ROWS   # 10 casas de mao
const ENTRADA_0 := TAMANHO_MAO             # coluna 6 da fileira de cima
const ENTRADA_1 := TAMANHO_MAO + 1         # coluna 6 da fileira de baixo
const TOTAL_SLOTS := TAMANHO_MAO + NUM_ROWS  # 12
const LANE_CASAS := 3 # legado de compatibilidade; nao existe lane visual
# A regra mantem 12 cartas conhecidas. A UI mostra as 5 primeiras para
# continuar legivel no telefone, como no conceito da alpha.
const QTD_PROXIMAS := 12
const BAG_VISIVEL := 8
const INIMIGOS_FASE_PADRAO := 3

# --- dano ------------------------------------------------------------
# Numeros pequenos porque os inimigos do handoff tem 8 a 16 de HP (46
# somados). Uma corrente media faz ~3 combos, entao ~4 de dano; a
# arena inteira sai em ~12 correntes. tests/test_batalha.gd mede.
const ESCALA_DANO_ALPHA := 0.18
const BONUS_CASCATA := 0.3    # +30% por elo, como na regra de campo
const MULT_CRITICO := 1.5
const ESCALA_CURA_ALPHA := 0.24
const SCORE_POR_COMBO := 25
const GEMS_POR_COMBO := 25

# Turno do inimigo: cada corrente que fecha combo OU cada abandono
# desconta 1. Em 0 o inimigo bate e o contador volta pro maximo.
const CONTADOR_INIMIGO_MAX := 3

# Qual aliado ataca com cada tipo. O lineup v2 possui exatamente um
# representante para cada uma das cinco afinidades.
const ATACANTE := {
	"dragon": 0,   # Draco de Brasa
	"knight": 1,   # Guardiao de Ferro
	"nature": 2,   # Maga do Bosque
	"light": 3,    # Cleriga Astral
	"dark": 4,     # Oraculo Chacal
}

var rng := RandomNumberGenerator.new()
var saco: Saco

var mao: Array[Carta] = []       # 12 casas: 10 de mao + 2 de ENTRADA (null = vazia)
var proximas: Array[Carta] = []  # a fila visivel do BAG; proximas[0] e a que desce
var zona: Array[Carta] = []      # o trio em montagem (0 a 3 cartas)
var zona_slots: Array[int] = []  # de que casa saiu cada marcada (-1 = veio do saco)
var zona_descidas: Array[int] = []  # em que ENTRADA desceu a carta de cada marcada

var inimigos: Array[Dictionary] = []
var aliados: Array[Dictionary] = []
var alvo_selecionado := -1

var hp := 1
var hp_max := 1
var contador_inimigo := CONTADOR_INIMIGO_MAX
var contador_inimigo_max := CONTADOR_INIMIGO_MAX

var rodada := 1
var rodadas_totais := 3
var andar := 7
var score := 1250
var gems := 1250
var moedas := 320

var fim := false
var vitoria := false

# Quantas vezes _garantir_saida precisou recolorir uma carta orfa. E o
# preco da garantia de mao jogavel - se subir muito, o desenho e que
# esta errado, nao o parametro.
var saidas_forcadas := 0

# Desfazer: uma pilha de fotos, uma por toque que NAO fechou combo.
var pode_desfazer := false
var _snapshots: Array = []


func _init(semente: int = 0) -> void:
	if semente == 0:
		rng.randomize()
	else:
		rng.seed = semente
	saco = Saco.new(rng)

	for i in mini(INIMIGOS_FASE_PADRAO, Unidades.INIMIGOS.size()):
		var d: Dictionary = Unidades.INIMIGOS[i]
		inimigos.append({"def": d, "hp": int(d.hp_max), "hp_max": int(d.hp_max)})
	if not inimigos.is_empty():
		alvo_selecionado = 0
	for d: Dictionary in Unidades.ALIADOS:
		aliados.append({"def": d, "hp": int(d.hp_max), "hp_max": int(d.hp_max),
			"skill": 0, "skill_max": 8})
	hp_max = 0
	for a: Dictionary in aliados:
		hp_max += int(a.hp_max)
	hp = hp_max

	for i in TAMANHO_MAO:
		mao.append(saco.comprar())
	# nunca existe mao de abertura sem trio possivel
	_garantir_saida(mao)
	mao.sort_custom(_antes_de)
	for i in NUM_ROWS:
		mao.append(null)  # as ENTRADAS comecam vazias
	for i in QTD_PROXIMAS:
		proximas.append(saco.comprar())


# ------------------------------------------------------------ consultas

func linha_de(idx: int) -> int:
	if idx < TAMANHO_MAO:
		return idx / ROW_SIZE
	return idx - TAMANHO_MAO  # ENTRADA: uma por fileira


func tipo_zona() -> String:
	if zona.is_empty():
		return ""
	return Carta.tipo_do_trio(zona)


func marcada(slot: int) -> bool:
	return zona_slots.has(slot)


func pode_tocar(idx: int) -> bool:
	return not fim and idx >= 0 and idx < mao.size() and mao[idx] != null


func vivos() -> Array[int]:
	var r: Array[int] = []
	for i in inimigos.size():
		if int(inimigos[i].hp) > 0:
			r.append(i)
	return r


func selecionar_alvo(indice: int) -> bool:
	if fim or indice < 0 or indice >= inimigos.size() or int(inimigos[indice].hp) <= 0:
		return false
	alvo_selecionado = indice
	return true


func comprar_carta() -> Carta:
	var carta: Carta = proximas.pop_front()
	proximas.append(saco.comprar())
	return carta


# Fotografia da fila do saco no instante logo DEPOIS de a carta sair.
# Vai junto de todo evento que mexe no saco porque a tela reproduz os
# eventos quando a logica JA RODOU A CORRENTE INTEIRA - sem estas fotos
# a fileira desenhada nunca bate com a carta que esta descendo.
func _foto_da_fila() -> Array:
	var foto: Array = []
	for c: Carta in proximas:
		foto.append({"tipo": c.tipo, "valor": c.valor})
	return foto


func _carta_ev(c: Carta) -> Dictionary:
	return {"tipo": c.tipo, "valor": c.valor}


# --------------------------------------------------------------- toque

# Toque do jogador numa casa do campo. Devolve a corrente INTEIRA ja
# resolvida, como lista de eventos na ordem de animar:
#
#   {tipo:"abandono"}                              a cadeia trocou de cor
#   {tipo:"selecao", slot, carta, lane}            carta marcada (lane e legado)
#   {tipo:"deselecao", slot, carta}                desmarcada, voltou pra casa
#   {tipo:"carta_desce", slot, carta, fila}        carta do saco desceu na ENTRADA
#   {tipo:"carta_volta", slot, fila}               desmarcou: a que desceu voltou
#   {tipo:"puxa_do_deck", carta, lane, fila}       a cascata usou a carta do saco
#   {tipo:"trio_sobe", slots, cartas}              as 3 se fundem na mao
#   {tipo:"combo", tipo_carta, cadeia, critico, atacante, alvo, cura}
#   {tipo:"renovacao"}                             sobrou <=1 carta: mao nova
#   {tipo:"nova_carta", slot, carta, chuva, fila}  carta nova numa casa
#   {tipo:"entra_na_mao", de, para}                ENTRADA entrou na mao
#   {tipo:"redistribuicao", mao}                   mao arrumada por tipo/valor
#   {tipo:"ataque_final", golpes, dano_total, cura_total, hp_inimigos, hp}
func tocar(idx: int) -> Dictionary:
	if not pode_tocar(idx):
		return {"tipo": "ignorado"}

	var foto := _tirar_snapshot()
	var resultado := {
		"tipo": "jogada", "eventos": [], "n_combos": 0,
		"dano_total": 0, "cura_total": 0,
	}
	var acumulado: Array = []  # golpes da corrente, aplicados so no fim

	# tocar noutro tipo abandona a cadeia atual
	if not zona.is_empty() and not Carta.combina(mao[idx].tipo, tipo_zona()):
		_abandonar(resultado)

	# se a carta tocada era uma que tinha DESCIDO por causa de uma
	# marcada, o abandono acabou de devolve-la ao saco: o toque so
	# abandonou mesmo
	if mao[idx] != null:
		var carta: Carta = mao[idx]
		zona.append(carta)
		zona_slots.append(idx)
		mao[idx] = null
		resultado.eventos.append({
			"tipo": "selecao", "slot": idx, "carta": _carta_ev(carta),
			"lane": zona.size() - 1,
		})

		if zona.size() >= 3:
			# na terceira o trio fecha na hora - nada desce
			zona_descidas.append(-1)
			_fechar_trio(resultado, acumulado)
			_fase_cascata(resultado, acumulado)
			_completar_mao(resultado)
		else:
			# nas duas primeiras, uma carta do saco desce na ENTRADA
			zona_descidas.append(_descer_carta(linha_de(idx), resultado))

	_resolver_ataque_final(resultado, acumulado)
	_turno_inimigo(resultado)

	if int(resultado.n_combos) > 0:
		_snapshots.clear()
		pode_desfazer = false
	else:
		_snapshots.append(foto)
		pode_desfazer = true
	return resultado


# Toque numa carta ja marcada/levantada: desmarca.
func desmarcar(slot: int) -> Dictionary:
	var pos := zona_slots.find(slot)
	if fim or pos == -1:
		return {"tipo": "ignorado"}
	var resultado := {
		"tipo": "jogada", "eventos": [], "n_combos": 0,
		"dano_total": 0, "cura_total": 0,
	}
	var foto := _tirar_snapshot()
	_devolver_marcada(pos, resultado)
	_snapshots.append(foto)
	pode_desfazer = true
	return resultado


# Uma carta do saco desce na casa de ENTRADA da fileira dada. Se ela ja
# estiver ocupada, desce na da outra fileira - por isso as duas de uma
# cadeia ficam uma em cima da outra. Devolve o slot usado, ou -1.
func _descer_carta(l: int, resultado: Dictionary) -> int:
	var candidatos := [ENTRADA_0, ENTRADA_1] if l == 0 else [ENTRADA_1, ENTRADA_0]
	for slot: int in candidatos:
		if mao[slot] == null and not zona_slots.has(slot):
			var nova := comprar_carta()
			mao[slot] = nova
			resultado.eventos.append({
				"tipo": "carta_desce", "slot": slot, "carta": _carta_ev(nova),
				"fila": _foto_da_fila(),
			})
			return slot
	return -1


# Desfaz uma marcacao: a marcada volta pra casa e a carta que desceu por
# causa dela volta pro topo do saco (desfazendo comprar_carta()).
func _devolver_marcada(pos: int, resultado: Dictionary) -> void:
	var slot: int = zona_slots[pos]
	var carta: Carta = zona[pos]
	var descida: int = zona_descidas[pos] if pos < zona_descidas.size() else -1
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
	if pos < zona_descidas.size():
		zona_descidas.remove_at(pos)
	resultado.eventos.append({
		"tipo": "deselecao", "slot": slot, "carta": _carta_ev(carta),
	})


func _abandonar(resultado: Dictionary) -> void:
	resultado.eventos.append({"tipo": "abandono"})
	for pos in range(zona.size() - 1, -1, -1):
		_devolver_marcada(pos, resultado)


# ------------------------------------------------------------- combos

# Fecha o trio que esta na zona: as 3 sobem juntas e se fundem.
func _fechar_trio(resultado: Dictionary, acumulado: Array) -> void:
	var cartas: Array = []
	for c: Carta in zona:
		cartas.append(_carta_ev(c))
	resultado.eventos.append({
		"tipo": "trio_sobe", "slots": zona_slots.duplicate(), "cartas": cartas,
	})
	zona_slots.clear()
	zona_descidas.clear()
	_disparar_zona(resultado, acumulado)


# Fecha o trio e ACUMULA a contribuicao dele. Nada e aplicado agora: o
# dano da corrente inteira so desconta em _resolver_ataque_final.
func _disparar_zona(resultado: Dictionary, acumulado: Array) -> void:
	var tipo := Carta.tipo_do_trio(zona)
	var cadeia: int = int(resultado.n_combos)
	var valores: Array[int] = []
	var soma := 0.0
	for c: Carta in zona:
		valores.append(c.valor)
		soma += float(c.valor)
	var nota_critico := _nota_critico(zona)
	zona.clear()

	# Wild substitui valores que faltam; ele nao concede critico sozinho.
	valores.sort()
	var critico := nota_critico > 0
	var media := soma / 3.0

	score += SCORE_POR_COMBO
	gems += GEMS_POR_COMBO

	var ev := {
		"tipo": "combo", "tipo_carta": tipo, "cadeia": cadeia, "critico": critico,
		"nota_critico": nota_critico, "valores": valores.duplicate(),
		"atacante": -1, "alvo": -1, "cura": false, "cargas": [],
	}

	if tipo == Carta.CURA:
		var cura := maxf(1.0, media * ESCALA_CURA_ALPHA) \
			* (1.0 + BONUS_CASCATA * float(cadeia))
		if critico:
			cura *= MULT_CRITICO
		acumulado.append({"cura": true, "valor": cura})
		ev.cura = true
	elif tipo == Carta.CORINGA:
		# Trio so de Wild carrega todos os aliados disponiveis; no fim da
		# corrente todos contribuem contra o alvo escolhido.
		var alvo := _alvo_da_corrente(acumulado)
		for i in aliados.size():
			if int(aliados[i].hp) <= 0:
				continue
			var ataque := float(aliados[i].def.get("ataque", 1))
			var forca := maxf(1.0, (ataque + media) * ESCALA_DANO_ALPHA) \
				* (1.0 + BONUS_CASCATA * float(cadeia))
			if critico:
				forca *= MULT_CRITICO
			acumulado.append({"cura": false, "alvo": alvo, "valor": forca,
				"atacante": i, "tipo": String(aliados[i].def.elemento)})
			ev.cargas.append({"atacante": i, "valor": maxi(1, int(round(forca)))})
		ev["todos"] = true
		ev.alvo = alvo
	else:
		# A corrente INTEIRA bate no inimigo selecionado pelo jogador e os
		# elos da cascata somam em cima dele. Assim
		# uma corrente de 3 combos vira um "-4" visivel num bicho so, em
		# vez de tres "-1" espalhados que nao parecem nada.
		var alvo := _alvo_da_corrente(acumulado)
		if alvo >= 0:
			var atacante := int(ATACANTE.get(tipo, -1))
			var ataque := float(aliados[atacante].def.get("ataque", 1)) \
				if atacante >= 0 else 1.0
			var forca := maxf(1.0, (ataque + media) * ESCALA_DANO_ALPHA) \
				* (1.0 + BONUS_CASCATA * float(cadeia))
			if critico:
				forca *= MULT_CRITICO
			acumulado.append({"cura": false, "alvo": alvo, "valor": forca,
				"atacante": atacante, "tipo": tipo})
			ev.alvo = alvo
			ev.atacante = atacante
			ev.cargas.append({"atacante": atacante,
				"valor": maxi(1, int(round(forca)))})

	# O medidor tem oito blocos discretos: combo comum acende um; critico,
	# dois. Wild aplica a mesma regra a todos. O dano fica separado para a
	# carga nao depender dos atributos ou do balanceamento dos inimigos.
	var incremento_skill := 1 if tipo == Carta.CORINGA else (2 if critico else 1)
	for carga: Dictionary in ev.cargas:
		var aliado := int(carga.atacante)
		if aliado < 0 or aliado >= aliados.size():
			continue
		var max_skill := int(aliados[aliado].get("skill_max", 8))
		aliados[aliado].skill = mini(max_skill,
			int(aliados[aliado].get("skill", 0)) + incremento_skill)
		carga["skill_incremento"] = incremento_skill

	resultado.eventos.append(ev)
	resultado.n_combos = int(resultado.n_combos) + 1


# Nota confirmada no binario: trinca de valores vale valor*10 e uma
# sequencia vale o maior valor*3. Wild cobre lacunas, sem critico gratis.
func _nota_critico(cartas: Array) -> int:
	var contagens := {}
	var wilds := 0
	for c: Carta in cartas:
		if c.tipo == Carta.CORINGA:
			wilds += 1
		else:
			contagens[c.valor] = int(contagens.get(c.valor, 0)) + 1
	var nota := 0
	for valor in range(1, 10):
		if int(contagens.get(valor, 0)) + wilds >= 3:
			nota = maxi(nota, valor * 10)
	for inicio in range(1, 8):
		var faltam := 0
		for valor in range(inicio, inicio + 3):
			if int(contagens.get(valor, 0)) == 0:
				faltam += 1
		if faltam <= wilds:
			nota = maxi(nota, (inicio + 2) * 3)
	return nota


# Fase cascata: todo trio ja pronto entre as cartas AINDA NA MAO dispara
# sozinho. Aqui os espacos NAO sao repostos - a mao vai esgotando e a
# corrente e naturalmente limitada. Quando nao ha mais trio:
#   - sobrou no maximo 1 carta -> RENOVACAO: a mao inteira desce de novo
#     e a corrente pode continuar (o momento raro de virada);
#   - sobrou mais de 1 -> a corrente acaba.
# Quem a corrente esta batendo. O primeiro combo usa a escolha do jogador;
# do segundo em diante, todo mundo bate no mesmo.
func _alvo_da_corrente(acumulado: Array) -> int:
	for g: Dictionary in acumulado:
		if not bool(g.cura):
			return int(g.alvo)
	var lista := vivos()
	if lista.is_empty():
		return -1
	if lista.has(alvo_selecionado):
		return alvo_selecionado
	alvo_selecionado = lista[0]
	return alvo_selecionado


func _fase_cascata(resultado: Dictionary, acumulado: Array) -> void:
	while true:
		var plano := _melhor_trio()
		if not plano.is_empty():
			for idx: int in plano.slots:
				zona.append(mao[idx])
				zona_slots.append(idx)
				zona_descidas.append(-1)
				mao[idx] = null
			if bool(plano.usa_saco):
				var puxada := comprar_carta()
				zona.append(puxada)
				zona_slots.append(-1)  # -1 = veio do saco, nao da mao
				zona_descidas.append(-1)
				resultado.eventos.append({
					"tipo": "puxa_do_deck", "carta": _carta_ev(puxada),
					"lane": zona.size() - 1, "fila": _foto_da_fila(),
				})
			_fechar_trio(resultado, acumulado)
			continue

		var restantes := 0
		for c: Carta in mao:
			if c != null:
				restantes += 1
		if restantes > 1:
			break

		resultado.eventos.append({"tipo": "renovacao"})
		mao[ENTRADA_0] = null
		mao[ENTRADA_1] = null
		for i in TAMANHO_MAO:
			var nova := comprar_carta()
			mao[i] = nova
			resultado.eventos.append({
				"tipo": "nova_carta", "slot": i, "carta": _carta_ev(nova),
				"chuva": false, "fila": _foto_da_fila(),
			})


# Separa os slots ocupados por tipo, com os CORINGAS a parte.
func _mao_por_tipo() -> Dictionary:
	var por_tipo: Dictionary = {}
	var coringas: Array[int] = []
	for i in mao.size():
		if mao[i] == null:
			continue
		if mao[i].tipo == Carta.CORINGA:
			coringas.append(i)
		else:
			if not por_tipo.has(mao[i].tipo):
				por_tipo[mao[i].tipo] = [] as Array[int]
			(por_tipo[mao[i].tipo] as Array[int]).append(i)
	return {"por_tipo": por_tipo, "coringas": coringas}


# Prioridade confirmada no binario: primeiro contagens 2/5/8, depois
# 4/7, por fim 3/6/9 (resto por 3: 2, 1, 0). Dentro da passada vence a
# maior nota de critico. Em empate, usar o topo da BAG poupa a mao.
func _melhor_trio() -> Dictionary:
	var mapa := _mao_por_tipo()
	var por_tipo: Dictionary = mapa.por_tipo
	var coringas: Array[int] = mapa.coringas
	var topo: Carta = proximas[0]
	var melhor: Dictionary = {}
	var melhor_faixa := 99
	var melhor_nota := -1
	for tipo: String in por_tipo:
		if not _tipo_disponivel(tipo):
			continue
		var qtd: int = (por_tipo[tipo] as Array[int]).size()
		var plano := _melhor_combinacao(tipo, por_tipo[tipo], coringas, topo)
		if plano.is_empty():
			continue
		var resto := qtd % 3
		var faixa := 0 if resto == 2 else (1 if resto == 1 else 2)
		var nota := int(plano.nota)
		if melhor.is_empty() or faixa < melhor_faixa \
				or (faixa == melhor_faixa and nota > melhor_nota) \
				or (faixa == melhor_faixa and nota == melhor_nota \
					and bool(plano.usa_saco) and not bool(melhor.usa_saco)):
			melhor = plano
			melhor_faixa = faixa
			melhor_nota = nota
	if not melhor.is_empty():
		return {"slots": melhor.slots, "usa_saco": melhor.usa_saco}

	# trio so de coringas (raro)
	var so_coringas := coringas.size() + (1 if topo.tipo == Carta.CORINGA else 0)
	if so_coringas >= 3:
		var slots: Array[int] = []
		var usa_saco := topo.tipo == Carta.CORINGA
		for s: int in coringas:
			if slots.size() + (1 if usa_saco else 0) >= 3:
				break
			slots.append(s)
		return {"slots": slots, "usa_saco": usa_saco}

	return {}


func _tipo_disponivel(tipo: String) -> bool:
	if tipo == Carta.CURA:
		return true
	var atacante := int(ATACANTE.get(tipo, -1))
	return atacante >= 0 and atacante < aliados.size() \
		and int(aliados[atacante].hp) > 0 \
		and not bool(aliados[atacante].get("indisponivel", false))


func _melhor_combinacao(tipo: String, slots_tipo: Array, coringas: Array[int],
		topo: Carta) -> Dictionary:
	var itens: Array = []
	for slot: int in slots_tipo:
		itens.append({"slot": slot, "carta": mao[slot], "saco": false})
	for slot: int in coringas:
		itens.append({"slot": slot, "carta": mao[slot], "saco": false})
	if Carta.combina(topo.tipo, tipo):
		itens.append({"slot": -1, "carta": topo, "saco": true})
	if itens.size() < 3:
		return {}
	var melhor: Dictionary = {}
	for a in range(itens.size() - 2):
		for b in range(a + 1, itens.size() - 1):
			for c in range(b + 1, itens.size()):
				var cartas: Array = [itens[a].carta, itens[b].carta, itens[c].carta]
				if Carta.tipo_do_trio(cartas) != tipo:
					continue
				var usa_saco := bool(itens[a].saco) or bool(itens[b].saco) \
					or bool(itens[c].saco)
				var nota := _nota_critico(cartas)
				if melhor.is_empty() or nota > int(melhor.nota) \
						or (nota == int(melhor.nota) and usa_saco \
							and not bool(melhor.usa_saco)):
					var slots: Array[int] = []
					for item: Dictionary in [itens[a], itens[b], itens[c]]:
						if not bool(item.saco):
							slots.append(int(item.slot))
					melhor = {"slots": slots, "usa_saco": usa_saco, "nota": nota}
	return melhor


# ----------------------------------------------------- fim da corrente

# Chuva final: o que estava nas ENTRADAS entra na mao, o saco preenche o
# resto e a mao inteira e redistribuida.
func _completar_mao(resultado: Dictionary) -> void:
	for entrada: int in [ENTRADA_0, ENTRADA_1]:
		if mao[entrada] == null:
			continue
		for i in TAMANHO_MAO:
			if mao[i] == null:
				mao[i] = mao[entrada]
				mao[entrada] = null
				resultado.eventos.append({"tipo": "entra_na_mao", "de": entrada, "para": i})
				break
	for i in TAMANHO_MAO:
		if mao[i] == null:
			var nova := comprar_carta()
			mao[i] = nova
			resultado.eventos.append({
				"tipo": "nova_carta", "slot": i, "chuva": true,
				"carta": _carta_ev(nova), "fila": _foto_da_fila(),
			})
	_redistribuir(resultado)


# As cartas se juntam e sao espalhadas de novo pela mao AGRUPADAS POR
# TIPO e, dentro do tipo, em ordem crescente de valor - e o que o jogo
# original faz para facilitar enxergar o proximo combo.
func _redistribuir(resultado: Dictionary) -> void:
	var cartas: Array[Carta] = []
	for c: Carta in mao:
		if c != null:
			cartas.append(c)
	_garantir_saida(cartas)
	cartas.sort_custom(_antes_de)
	var estado: Array = []
	for i in mao.size():
		mao[i] = cartas[i] if i < cartas.size() else null
		if mao[i] == null:
			estado.append(null)
		else:
			estado.append(_carta_ev(mao[i]))
	resultado.eventos.append({"tipo": "redistribuicao", "mao": estado})


func _antes_de(a: Carta, b: Carta) -> bool:
	if a.tipo != b.tipo:
		return Carta.ordem_de(a.tipo) < Carta.ordem_de(b.tipo)
	return a.valor < b.valor


# Existe pelo menos um trio POSSIVEL neste conjunto? Basta um tipo cujo
# total (contando os coringas) chegue a 3.
func _tem_saida(cartas: Array) -> bool:
	var por_tipo: Dictionary = {}
	var coringas := 0
	for c: Carta in cartas:
		if c == null:
			continue
		if c.tipo == Carta.CORINGA:
			coringas += 1
		else:
			por_tipo[c.tipo] = int(por_tipo.get(c.tipo, 0)) + 1
	if coringas >= 3:
		return true
	for tipo: String in por_tipo:
		if int(por_tipo[tipo]) + coringas >= 3:
			return true
	return false


# MAO SEM SAIDA nunca chega ao jogador. Quando o sorteio entrega uma
# assim, o conserto e CIRURGICO: em vez de resortear a mao inteira (que
# enviesaria a distribuicao), uma unica carta ORFA vira o tipo mais
# abundante. Resolve o travamento e ainda tira um orfao da mao, que e
# exatamente o que a cascata tenta fazer.
func _garantir_saida(cartas: Array) -> void:
	var protecao := 0
	while not _tem_saida(cartas) and protecao < TAMANHO_MAO:
		protecao += 1
		var por_tipo: Dictionary = {}
		for i in cartas.size():
			var c: Carta = cartas[i]
			if c == null or c.tipo == Carta.CORINGA:
				continue
			if not por_tipo.has(c.tipo):
				por_tipo[c.tipo] = [] as Array[int]
			(por_tipo[c.tipo] as Array[int]).append(i)

		# A orfa e escolhida SEMPRE entre os OUTROS tipos, nunca o
		# proprio alvo. Sem isso, a mao mais travada de todas - 2 de
		# cada um dos 5 tipos, empate perfeito - escolhia o mesmo tipo
		# como alvo e como orfao e voltava ao jogador sem trio nenhum.
		var tipos: Array = por_tipo.keys()
		tipos.sort()
		var alvo := ""
		for t: String in tipos:
			if alvo == "" or (por_tipo[t] as Array[int]).size() > (por_tipo[alvo] as Array[int]).size():
				alvo = t
		var orfao := ""
		for t: String in tipos:
			if t == alvo:
				continue
			if orfao == "" or (por_tipo[t] as Array[int]).size() < (por_tipo[orfao] as Array[int]).size():
				orfao = t
		if alvo == "" or orfao == "":
			break
		var idx: int = (por_tipo[orfao] as Array[int])[0]
		cartas[idx] = Carta.new(alvo, cartas[idx].valor)
		saidas_forcadas += 1


# So aqui, no fim da corrente inteira, o que foi acumulado desconta de
# fato do inimigo e cura o time.
func _resolver_ataque_final(resultado: Dictionary, acumulado: Array) -> void:
	if acumulado.is_empty():
		return

	var por_alvo: Dictionary = {}
	var dominante_por_alvo: Dictionary = {}
	var cura_f := 0.0
	for g: Dictionary in acumulado:
		if bool(g.cura):
			cura_f += float(g.valor)
		else:
			por_alvo[int(g.alvo)] = float(por_alvo.get(g.alvo, 0.0)) + float(g.valor)
			var dominante: Dictionary = dominante_por_alvo.get(int(g.alvo), {})
			if dominante.is_empty() or float(g.valor) > float(dominante.valor):
				dominante_por_alvo[int(g.alvo)] = {"valor": float(g.valor),
					"tipo": String(g.get("tipo", "light"))}

	var golpes: Array = []
	var dano_total := 0
	for alvo: int in por_alvo:
		var bruto := float(por_alvo[alvo])
		var defesa := float(inimigos[alvo].def.get("defesa", 0))
		var reducao := _reducao_por_defesa(defesa)
		var dano := maxi(1, int(round(bruto * (1.0 - reducao))))
		inimigos[alvo].hp = maxi(0, int(inimigos[alvo].hp) - dano)
		dano_total += dano
		var dominante: Dictionary = dominante_por_alvo.get(alvo, {"tipo": "light"})
		golpes.append({"alvo": alvo, "dano": dano, "bruto": bruto,
			"tipo": String(dominante.tipo), "reducao": reducao,
			"hp": int(inimigos[alvo].hp)})

	# Quando o alvo cai, deixa o proximo inimigo vivo selecionado.
	if alvo_selecionado >= 0 and int(inimigos[alvo_selecionado].hp) <= 0:
		var restantes := vivos()
		alvo_selecionado = restantes[0] if not restantes.is_empty() else -1

	var cura := int(round(cura_f))
	if cura > 0:
		hp = mini(hp_max, hp + cura)

	resultado.dano_total = dano_total
	resultado.cura_total = cura

	var hps: Array = []
	for u: Dictionary in inimigos:
		hps.append(int(u.hp))
	resultado.eventos.append({
		"tipo": "ataque_final", "golpes": golpes, "dano_total": dano_total,
		"cura_total": cura, "hp_inimigos": hps, "hp": hp,
	})

	if vivos().is_empty():
		fim = true
		vitoria = true


# A tabela original vinha do servidor e se perdeu. Para a alpha usamos
# uma curva percentual de retorno decrescente, nunca subtracao direta.
func _reducao_por_defesa(defesa: float) -> float:
	return clampf(defesa / (defesa + 60.0), 0.0, 0.75)


# O turno do inimigo passa quando um combo dispara OU quando um abandono
# acontece. Toques que so avancam rumo a um combo real sao de graca.
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
	if int(resultado.n_combos) == 0 and not abandonou:
		return
	contador_inimigo -= 1
	if contador_inimigo > 0:
		return
	var inimigos_vivos := vivos()
	var ataque := 10.0
	if not inimigos_vivos.is_empty():
		ataque = float(inimigos[inimigos_vivos[0]].def.get("ataque", 10))
	var defesa_media := 0.0
	var defensores := 0
	for a: Dictionary in aliados:
		if int(a.hp) <= 0:
			continue
		defesa_media += float(a.def.get("defesa", 0))
		defensores += 1
	defesa_media /= maxf(1.0, float(defensores))
	var dano_inimigo := maxi(5, int(round(ataque - defesa_media * 0.5 \
		+ float(rng.randi_range(-1, 1)))))
	hp = maxi(0, hp - dano_inimigo)
	contador_inimigo = contador_inimigo_max
	resultado["ataque_inimigo"] = dano_inimigo
	if hp <= 0:
		fim = true
		vitoria = false
		resultado["fim"] = "derrota"


# ------------------------------------------------------------ desfazer

func _tirar_snapshot() -> Dictionary:
	var hps: Array[int] = []
	for u: Dictionary in inimigos:
		hps.append(int(u.hp))
	return {
		"mao": mao.duplicate(), "proximas": proximas.duplicate(),
		"zona": zona.duplicate(), "zona_slots": zona_slots.duplicate(),
		"zona_descidas": zona_descidas.duplicate(),
		"contador": contador_inimigo, "hp": hp, "hps": hps,
	}


# Desfaz o ultimo toque que ainda nao fechou trio. Pode ser chamado
# varias vezes, voltando toque a toque ate antes da cadeia. Quando um
# combo dispara, a pilha zera - dali nao volta mais.
func desfazer() -> bool:
	if _snapshots.is_empty():
		return false
	var s: Dictionary = _snapshots.pop_back()
	mao = (s.mao as Array[Carta]).duplicate()
	proximas = (s.proximas as Array[Carta]).duplicate()
	zona = (s.zona as Array[Carta]).duplicate()
	zona_slots = (s.zona_slots as Array[int]).duplicate()
	zona_descidas = (s.zona_descidas as Array[int]).duplicate()
	contador_inimigo = int(s.contador)
	hp = int(s.hp)
	for i in inimigos.size():
		inimigos[i].hp = int((s.hps as Array)[i])
	pode_desfazer = not _snapshots.is_empty()
	return true
