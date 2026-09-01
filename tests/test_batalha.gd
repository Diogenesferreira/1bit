extends SceneTree

# Teste da batalha, em duas partes:
#
#   1. REGRA pura (EstadoBatalha), sem tela: partidas inteiras em
#      milissegundos, conferindo as invariantes da mecanica de trio +
#      cascata (entradas, carta do saco no trio, chuva final, mao
#      sempre jogavel).
#   2. TELA de verdade (BattleScreen.tscn): monta a cena, toca nas
#      casas como um jogador e confere se o desenho bate com o estado.
#      Rodando com janela, ainda salva prints em user://.
#
#   Godot --headless --path . --script res://tests/test_batalha.gd
#   Godot           --path . --script res://tests/test_batalha.gd   (com prints)

const PARTIDAS := 30
const MAX_TURNOS := 300
const TURNOS_NA_TELA := 5

var falhas: Array[String] = []
var tela: BattleScreen
var prints := 0

# medidas da parte 1
var vitorias := 0
var derrotas := 0
var travadas := 0
var turnos_totais := 0
var combos_totais := 0
var maior_corrente := 0
var turnos_com_cascata := 0
var criticos := 0
var renovacoes := 0
var usou_saco_no_trio := 0
var desceu_na_entrada := 0
var saidas_forcadas := 0
var dano_total := 0
var cura_total := 0


func _initialize() -> void:
	Engine.time_scale = 4.0
	print("=== 1 Bit Heroes / trio + cascata ===")
	_parte_regra()
	_parte_tela()


func _falhar(msg: String) -> void:
	if falhas.size() < 20:
		falhas.append(msg)
	print("  FALHA: " + msg)


# ------------------------------------------------------- 1. a regra

func _parte_regra() -> void:
	_testar_regras_canonicas()
	for p in PARTIDAS:
		_simular(p)
	print("")
	print("-- regra (sem tela) --")
	print("partidas .................. %d  (vitorias %d / derrotas %d / sem fim %d)" % [
		PARTIDAS, vitorias, derrotas, travadas])
	print("turnos .................... %d  (media %.1f por partida)" % [
		turnos_totais, float(turnos_totais) / float(PARTIDAS)])
	print("combos .................... %d  (media %.2f por turno)" % [
		combos_totais, float(combos_totais) / maxf(1.0, float(turnos_totais))])
	print("turnos com CASCATA ........ %d  (%.1f%% dos turnos)" % [
		turnos_com_cascata, 100.0 * float(turnos_com_cascata) / maxf(1.0, float(turnos_totais))])
	print("maior corrente ............ %d combos num turno so" % maior_corrente)
	print("trios que usaram o SACO ... %d" % usou_saco_no_trio)
	print("cartas descidas na ENTRADA. %d" % desceu_na_entrada)
	print("criticos .................. %d  (%.1f%% dos combos)" % [
		criticos, 100.0 * float(criticos) / maxf(1.0, float(combos_totais))])
	print("renovacoes de mao ......... %d" % renovacoes)
	print("saidas forcadas ........... %.2f por partida" % [float(saidas_forcadas) / float(PARTIDAS)])
	print("dano / cura ............... %d / %d" % [dano_total, cura_total])


func _testar_regras_canonicas() -> void:
	var e := EstadoBatalha.new(777)
	if EstadoBatalha.QTD_PROXIMAS != 12 or EstadoBatalha.BAG_VISIVEL != 8:
		_falhar("alpha: BAG deve manter 12 conhecidas e mostrar 5")
	var soma_hp := 0
	for a: Dictionary in e.aliados:
		soma_hp += int(a.hp_max)
	if e.hp_max != soma_hp:
		_falhar("alpha: HP compartilhado nao e a soma dos aliados")
	var crit_wild: Array = [Carta.new("dragon", 5), Carta.new("dragon", 5),
		Carta.new(Carta.CORINGA, 2)]
	if e._nota_critico(crit_wild) != 50:
		_falhar("alpha: Wild nao completou o critico 5-5-5")
	var sem_crit: Array = [Carta.new("dragon", 1), Carta.new("dragon", 4),
		Carta.new(Carta.CORINGA, 9)]
	if e._nota_critico(sem_crit) != 0:
		_falhar("alpha: Wild concedeu critico sem conseguir completar valores")
	if e._reducao_por_defesa(20.0) <= e._reducao_por_defesa(10.0):
		_falhar("alpha: curva de defesa nao cresce com o atributo")
	# 2 dragoes + topo devem vir antes de uma cor com 3 cartas: resto 2
	# e a primeira passada confirmada no binario.
	e.mao = [Carta.new("dragon", 1), Carta.new("dragon", 2),
		Carta.new("nature", 6), Carta.new("nature", 7), Carta.new("nature", 8),
		Carta.new("knight", 1), Carta.new("knight", 4), Carta.new("knight", 7),
		Carta.new(Carta.CURA, 3), Carta.new("dark", 4), null, null]
	e.proximas[0] = Carta.new("dragon", 3)
	var plano := e._melhor_trio()
	if plano.is_empty() or not bool(plano.usa_saco) \
			or not (plano.slots as Array).has(0) or not (plano.slots as Array).has(1):
		_falhar("alpha: cascata nao priorizou a passada de resto 2")
	# A energia do combo deve permanecer no medidor do aliado correto e
	# nunca ultrapassar o limite visual/canonico de 100.
	var indice_dragao := int(EstadoBatalha.ATACANTE.dragon)
	e.aliados[indice_dragao].skill = 7
	e.zona = [Carta.new("dragon", 9), Carta.new("dragon", 9),
		Carta.new("dragon", 9)]
	e._disparar_zona({"eventos": [], "n_combos": 0}, [])
	if int(e.aliados[indice_dragao].skill) != int(e.aliados[indice_dragao].skill_max):
		_falhar("alpha: carga persistente da skill nao respeitou o limite")
	var medidor := EstadoBatalha.new(778)
	medidor.zona = [Carta.new("dragon", 1), Carta.new("dragon", 2),
		Carta.new("dragon", 4)]
	medidor._disparar_zona({"eventos": [], "n_combos": 0}, [])
	if int(medidor.aliados[indice_dragao].skill) != 1:
		_falhar("alpha: combo comum nao acendeu exatamente um bloco")
	medidor.zona = [Carta.new("dragon", 5), Carta.new("dragon", 5),
		Carta.new("dragon", 5)]
	medidor._disparar_zona({"eventos": [], "n_combos": 0}, [])
	if int(medidor.aliados[indice_dragao].skill) != 3:
		_falhar("alpha: combo critico nao acendeu exatamente dois blocos")
	medidor.zona = [Carta.new(Carta.CORINGA, 1), Carta.new(Carta.CORINGA, 2),
		Carta.new(Carta.CORINGA, 3)]
	medidor._disparar_zona({"eventos": [], "n_combos": 0}, [])
	for aliado: Dictionary in medidor.aliados:
		var esperado := 4 if aliado == medidor.aliados[indice_dragao] else 1
		if int(aliado.skill) != esperado:
			_falhar("alpha: Wild nao acendeu um bloco para cada aliado")


func _simular(n: int) -> void:
	var e := EstadoBatalha.new(2000 + n)
	_checar_mao(e, "partida %d, mao inicial" % n)
	var turnos := 0
	while not e.fim and turnos < MAX_TURNOS:
		turnos += 1
		var res := _jogar_turno(e, n, turnos)
		if res.is_empty():
			break
		_medir(res)
		if not e.fim:
			_checar_mao(e, "partida %d turno %d" % [n, turnos])
		_checar_limites(e, "partida %d turno %d" % [n, turnos])

	turnos_totais += turnos
	saidas_forcadas += e.saidas_forcadas
	if e.fim and e.vitoria:
		vitorias += 1
	elif e.fim:
		derrotas += 1
	else:
		travadas += 1
		_falhar("partida %d: %d turnos sem acabar" % [n, MAX_TURNOS])


# Um jogador razoavel: escolhe um tipo que da trio e toca 3 cartas,
# reavaliando a mao entre os toques - assim a carta que DESCEU na
# ENTRADA entra no trio quando serve, que e o ponto da mecanica.
func _jogar_turno(e: EstadoBatalha, n: int, turno: int) -> Dictionary:
	var alvo := _tipo_que_da_trio(e)
	if alvo == "":
		_falhar("partida %d turno %d: mao sem trio possivel" % [n, turno])
		return {}
	var res := {}
	for passo in 3:
		var idx := _slot_que_combina(e, alvo)
		if idx == -1:
			_falhar("partida %d turno %d: sem 3a carta de '%s'" % [n, turno, alvo])
			return res
		res = e.tocar(idx)
		if String(res.tipo) == "ignorado":
			_falhar("partida %d turno %d: toque em %d ignorado" % [n, turno, idx])
			return res
		_medir_eventos(res)
		if passo < 2:
			# depois da 1a e da 2a marcacao, uma carta TEM que ter
			# descido numa casa de ENTRADA (a menos que as duas ja
			# estejam ocupadas)
			var entradas := 0
			for slot: int in [EstadoBatalha.ENTRADA_0, EstadoBatalha.ENTRADA_1]:
				if e.mao[slot] != null:
					entradas += 1
			if entradas < passo + 1:
				_falhar("partida %d turno %d: apos %d marcacoes so %d carta(s) na ENTRADA" % [
					n, turno, passo + 1, entradas])
	return res


func _contagem_por_tipo(e: EstadoBatalha) -> Dictionary:
	var por_tipo: Dictionary = {}
	var coringas := 0
	for c: Carta in e.mao:
		if c == null:
			continue
		if c.tipo == Carta.CORINGA:
			coringas += 1
		else:
			por_tipo[c.tipo] = int(por_tipo.get(c.tipo, 0)) + 1
	return {"por_tipo": por_tipo, "coringas": coringas}


func _tipo_que_da_trio(e: EstadoBatalha) -> String:
	var m := _contagem_por_tipo(e)
	var por_tipo: Dictionary = m.por_tipo
	var coringas: int = m.coringas
	var melhor := ""
	var melhor_qtd := 0
	for tipo: String in por_tipo:
		var qtd: int = int(por_tipo[tipo])
		if qtd + coringas < 3:
			continue
		if melhor == "" or qtd > melhor_qtd:
			melhor = tipo
			melhor_qtd = qtd
	if melhor == "" and coringas >= 3:
		melhor = Carta.CORINGA
	return melhor


# Primeira casa livre cuja carta serve para o tipo alvo. As casas de
# ENTRADA entram na busca: e por elas que a carta do saco fecha o trio.
func _slot_que_combina(e: EstadoBatalha, alvo: String) -> int:
	for i in e.mao.size():
		var c: Carta = e.mao[i]
		if c == null or e.marcada(i):
			continue
		if Carta.combina(c.tipo, alvo):
			return i
	return -1


func _medir(res: Dictionary) -> void:
	var n := int(res.n_combos)
	combos_totais += n
	maior_corrente = maxi(maior_corrente, n)
	if n > 1:
		turnos_com_cascata += 1
	dano_total += int(res.dano_total)
	cura_total += int(res.cura_total)


# Eventos de TODOS os toques (o turno tem 3; so o ultimo fecha combo).
func _medir_eventos(res: Dictionary) -> void:
	for ev: Dictionary in res.eventos:
		match String(ev.tipo):
			"combo":
				if bool(ev.critico):
					criticos += 1
			"renovacao":
				renovacoes += 1
			"puxa_do_deck":
				usou_saco_no_trio += 1
			"carta_desce":
				desceu_na_entrada += 1


# Depois de uma corrente inteira a mao tem que estar CHEIA (10 casas),
# com as 2 ENTRADAS vazias e com pelo menos um trio possivel.
func _checar_mao(e: EstadoBatalha, onde: String) -> void:
	if e.mao.size() != EstadoBatalha.TOTAL_SLOTS:
		_falhar("%s: campo com %d casas (esperado %d)" % [onde, e.mao.size(), EstadoBatalha.TOTAL_SLOTS])
		return
	if not e.zona.is_empty():
		_falhar("%s: sobrou carta marcada depois da corrente" % onde)
	for i in EstadoBatalha.TAMANHO_MAO:
		if e.mao[i] == null:
			_falhar("%s: casa %d vazia depois da chuva final" % [onde, i])
			return
	for slot: int in [EstadoBatalha.ENTRADA_0, EstadoBatalha.ENTRADA_1]:
		if e.mao[slot] != null:
			_falhar("%s: ENTRADA %d ficou ocupada no fim da corrente" % [onde, slot])
			return
	if not e._tem_saida(e.mao):
		_falhar("%s: mao entregue ao jogador SEM trio possivel" % onde)
	if e.proximas.size() != EstadoBatalha.QTD_PROXIMAS:
		_falhar("%s: fila do saco com %d (esperado %d)" % [onde, e.proximas.size(), EstadoBatalha.QTD_PROXIMAS])
	for c: Carta in e.mao:
		if c != null and (c.valor < 1 or c.valor > 9):
			_falhar("%s: carta com valor %d" % [onde, c.valor])
			return


func _checar_limites(e: EstadoBatalha, onde: String) -> void:
	if e.hp < 0 or e.hp > e.hp_max:
		_falhar("%s: hp do time em %d" % [onde, e.hp])
	if e.contador_inimigo < 0 or e.contador_inimigo > e.contador_inimigo_max:
		_falhar("%s: contador do inimigo em %d" % [onde, e.contador_inimigo])
	for u: Dictionary in e.inimigos:
		if int(u.hp) < 0 or int(u.hp) > int(u.hp_max):
			_falhar("%s: inimigo %s com hp %d" % [onde, u.def.chave, int(u.hp)])


# -------------------------------------------------------- 2. a tela

func _parte_tela() -> void:
	print("")
	print("-- tela (BattleScreen.tscn) --")
	tela = (load("res://scenes/battle/BattleScreen.tscn") as PackedScene).instantiate()
	root.add_child(tela)
	await process_frame
	await process_frame

	if tela.estado == null:
		_falhar("a tela nao criou o EstadoBatalha")
		_fim()
		return
	_checar_montagem()
	await _print("01_abertura")
	await _parte_toques()

	var e: EstadoBatalha = tela.estado
	var turnos := 0
	var combos := 0
	while turnos < TURNOS_NA_TELA and not e.fim:
		var alvo := _tipo_que_da_trio(e)
		if alvo == "":
			_falhar("tela: mao sem trio possivel")
			break
		turnos += 1
		for passo in 3:
			var idx := _slot_que_combina(e, alvo)
			if idx == -1:
				break
			await tela._ao_tocar_casa(idx)
			if tela._animando:
				_falhar("tela: ficou presa em _animando depois do toque %d" % idx)
				break
			if passo == 0:
				# A carta continua na propria mao e sobe para indicar selecao.
				if not tela._casas_campo[idx].cheia():
					_falhar("tela: a carta marcada desapareceu da mao")
				if tela._casas_campo[idx].position.y >= tela._pos_casa(idx).y:
					_falhar("tela: a carta marcada nao levantou na propria mao")
				var entradas := 0
				for slot: int in [EstadoBatalha.ENTRADA_0, EstadoBatalha.ENTRADA_1]:
					if e.mao[slot] != null:
						entradas += 1
				if entradas == 0:
					_falhar("tela: nenhuma carta entrou no estado transitório")
				for slot: int in [EstadoBatalha.ENTRADA_0, EstadoBatalha.ENTRADA_1]:
					if tela._casas_campo[slot].visible:
						_falhar("tela: ENTRADA técnica apareceu como sexta coluna")
				if turnos == 1:
					await _print("02_marcada_e_entrada")
		combos += 1
		_checar_sincronia("turno %d" % turnos)
		if turnos == 1:
			await _print("03_pos_cascata")

	var sobrou := 0
	var hp_max_total := 0
	for u: Dictionary in e.inimigos:
		sobrou += int(u.hp)
		hp_max_total += int(u.hp_max)
	if sobrou >= hp_max_total:
		_falhar("tela: nenhum inimigo tomou dano (soma de HP ainda em %d)" % sobrou)

	print("turnos jogados ............ %d" % turnos)
	print("hp inimigos ............... %s" % [_hps()])
	print("hp time / contador ........ %d/%d / %d" % [e.hp, e.hp_max, e.contador_inimigo])
	print("score ..................... %d" % e.score)
	await _print("04_final")
	_fim()


# ------------------------------------- 3. cliques de verdade (mouse)
#
# Aqui o toque nao chama funcao nenhuma da tela: empurra um evento de
# mouse pelo viewport, na posicao da casa. E o mesmo caminho do dedo do
# jogador - se a casa nao estiver clicavel, este teste quebra.

func _parte_toques() -> void:
	var e: EstadoBatalha = tela.estado
	var idx := -1
	for i in EstadoBatalha.TAMANHO_MAO:
		if e.mao[i] != null:
			idx = i
			break
	if idx == -1:
		_falhar("cliques: nao achei carta na mao")
		return

	var fila_antes := _fila_texto(e)
	var carta_antes: String = e.mao[idx].tipo

	# --- 1) clicar na carta: ela levanta na propria mao e uma carta do
	#        saco desce numa ENTRADA
	await _clicar(tela._centro_casa(idx))
	if not e.marcada(idx):
		_falhar("cliques: cliquei na carta e ela nao ficou marcada")
		return
	if not tela._casas_campo[idx].cheia():
		_falhar("cliques: a carta marcada sumiu em vez de levantar")
	elif tela._casas_campo[idx].position.y >= tela._pos_casa(idx).y:
		_falhar("cliques: a carta marcada nao levantou na mao")
	if e.mao[EstadoBatalha.ENTRADA_0] == null and e.mao[EstadoBatalha.ENTRADA_1] == null:
		_falhar("cliques: nenhuma carta desceu na ENTRADA")

	# --- 2) clicar de novo na carta levantada: ela baixa e a
	#        que desceu volta pro topo do saco
	await _clicar(tela._centro_casa(idx))
	if e.marcada(idx):
		_falhar("cliques: cliquei na casa vazia e a carta NAO voltou")
	elif e.mao[idx] == null or e.mao[idx].tipo != carta_antes:
		_falhar("cliques: voltou outra carta para a casa %d" % idx)
	if not tela._casas_campo[idx].cheia():
		_falhar("cliques: a carta voltou na regra mas nao no desenho")
	for slot: int in [EstadoBatalha.ENTRADA_0, EstadoBatalha.ENTRADA_1]:
		if e.mao[slot] != null:
			_falhar("cliques: a carta que desceu nao voltou pro saco (ENTRADA %d cheia)" % slot)
	if _fila_texto(e) != fila_antes:
		_falhar("cliques: a fila do BAG nao voltou ao que era antes do toque")

	# --- 3) repetir o desfazer clicando na propria carta levantada
	await _clicar(tela._centro_casa(idx))
	if not e.marcada(idx):
		_falhar("cliques: segunda marcacao nao pegou")
		return
	await _clicar(tela._casas_campo[idx].centro())
	if e.marcada(idx):
		_falhar("cliques: cliquei na carta levantada e ela nao voltou")
	if _fila_texto(e) != fila_antes:
		_falhar("cliques: desmarcando pela mao, a fila do BAG nao voltou")

	# --- 4) fechar um trio de verdade e conferir que o inimigo PERDE vida
	var hp_antes := _hp_somado(e)
	var alvo := _tipo_que_da_trio(e)
	var fechou := false
	for passo in 3:
		var i := _slot_que_combina(e, alvo)
		if i == -1:
			break
		await _clicar(tela._centro_casa(i))
		fechou = passo == 2
	if not fechou:
		_falhar("cliques: nao consegui fechar um trio com 3 cliques")
		return
	var hp_depois := _hp_somado(e)
	if hp_depois >= hp_antes:
		_falhar("cliques: trio fechou e o HP dos inimigos nao caiu (%d -> %d)" % [hp_antes, hp_depois])
	else:
		print("trio fechado no clique .... HP dos inimigos %d -> %d (-%d)" % [
			hp_antes, hp_depois, hp_antes - hp_depois])
	_checar_sincronia("depois dos cliques")


# Empurra um clique de mouse pelo viewport, em coordenadas do canvas, e
# espera a animacao inteira terminar.
func _clicar(pos: Vector2) -> void:
	for pressionado: bool in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressionado
		ev.position = pos
		root.push_input(ev, true)
		await process_frame
	var guarda := 0
	while tela._animando and guarda < 2000:
		guarda += 1
		await process_frame
	if guarda >= 2000:
		_falhar("cliques: a tela travou animando depois do clique")


func _fila_texto(e: EstadoBatalha) -> String:
	var partes: Array[String] = []
	for c: Carta in e.proximas:
		partes.append("%s%d" % [c.tipo, c.valor])
	return ",".join(partes)


func _hp_somado(e: EstadoBatalha) -> int:
	var t := 0
	for u: Dictionary in e.inimigos:
		t += int(u.hp)
	return t


func _fim() -> void:
	print("")
	if falhas.is_empty():
		print("OK: regra e tela em sincronia, nenhum erro de execucao.")
	else:
		print("FALHAS: %d" % falhas.size())
	if prints > 0:
		print("prints em: %s" % ProjectSettings.globalize_path("user://"))
	quit(1 if not falhas.is_empty() else 0)


func _hps() -> Array:
	var r: Array = []
	for u: Dictionary in tela.estado.inimigos:
		r.append("%s %d/%d" % [u.def.chave, int(u.hp), int(u.hp_max)])
	return r


func _checar_montagem() -> void:
	if tela._casas_campo.size() != EstadoBatalha.TOTAL_SLOTS:
		_falhar("CAMPO com %d casas (esperado %d: 10 de mao + 2 de ENTRADA)" % [
			tela._casas_campo.size(), EstadoBatalha.TOTAL_SLOTS])
	if tela._casas_bag.size() != EstadoBatalha.BAG_VISIVEL:
		_falhar("BAG com %d casas (esperado %d)" % [tela._casas_bag.size(), EstadoBatalha.BAG_VISIVEL])
	if tela._icone_next == null or tela._icone_next.tipo != tela.estado.proximas[0].tipo:
		_falhar("NEXT nao mostra a primeira carta da fila")
	elif tela._icone_next.position.x < tela._casas_bag[-1].position.x:
		_falhar("NEXT deve ficar no extremo direito da fila")
	if tela._casas_bag[-1].tipo_atual() != tela.estado.proximas[1].tipo:
		_falhar("casa mais proxima do NEXT nao mostra a segunda carta da fila")
	if tela._inimigos.size() != tela.estado.inimigos.size():
		_falhar("%d inimigos na arena" % tela._inimigos.size())
	if tela._aliados.size() != Unidades.ALIADOS.size():
		_falhar("%d aliados na arena" % tela._aliados.size())
	# as 10 casas de mao cheias, as 2 ENTRADAS vazias
	for i in EstadoBatalha.TAMANHO_MAO:
		if not tela._casas_campo[i].cheia():
			_falhar("casa %d da mao nasceu vazia" % i)
			break
	for slot: int in [EstadoBatalha.ENTRADA_0, EstadoBatalha.ENTRADA_1]:
		if tela._casas_campo[slot].cheia():
			_falhar("a casa de ENTRADA %d nasceu ocupada (deve comecar vazia)" % slot)
	_checar_sincronia("montagem")


func _checar_sincronia(onde: String) -> void:
	for i in EstadoBatalha.TAMANHO_MAO:
		# Uma carta selecionada sai da mao logica, mas permanece desenhada
		# e levantada ate a fusao acontecer.
		var no_estado: bool = tela.estado.mao[i] != null or tela.estado.marcada(i)
		var na_tela: bool = tela._casas_campo[i].cheia()
		if no_estado != na_tela:
			_falhar("%s: casa %d - estado %s, tela %s" % [onde, i,
				"cheia" if no_estado else "vazia", "cheia" if na_tela else "vazia"])
			return
		if tela.estado.mao[i] != null and tela._casas_campo[i].tipo_atual() != tela.estado.mao[i].tipo:
			_falhar("%s: casa %d mostra '%s' e o estado diz '%s'" % [onde, i,
				tela._casas_campo[i].tipo_atual(), tela.estado.mao[i].tipo])
			return
	for slot: int in [EstadoBatalha.ENTRADA_0, EstadoBatalha.ENTRADA_1]:
		if tela._casas_campo[slot].visible:
			_falhar("%s: ENTRADA técnica %d apareceu como sexta coluna" % [onde, slot])
			return
	var levantadas := 0
	for i in EstadoBatalha.TAMANHO_MAO:
		if tela._casas_campo[i].position.y < tela._pos_casa(i).y:
			levantadas += 1
	if levantadas != tela.estado.zona.size():
		_falhar("%s: mao com %d cartas levantadas e zona com %d" % [
			onde, levantadas, tela.estado.zona.size()])
	if tela._txt_hp.text != "%d/%d" % [tela.estado.hp, tela.estado.hp_max]:
		_falhar("%s: HUD de HP mostra '%s' e o estado diz %d/%d" % [onde,
			tela._txt_hp.text, tela.estado.hp, tela.estado.hp_max])


func _print(nome: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img == null:
		return
	img.save_png("user://batalha_%s.png" % nome)
	prints += 1
