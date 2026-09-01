extends RefCounted
class_name Bag

# O SACO de compra do jogo.
#
# Antes cada carta era sorteada do zero (CardData.aleatoria): sorte
# pura, sem memoria. Isso permitia 30 cartas sem um coringa ou uma
# rajada de 6 vermelhas seguidas - coisas que o jogador le como
# sacanagem, nao como azar.
#
# Aqui o jogo tira de um saco de composicao FIXA, embaralhado. A cada
# TAMANHO cartas saem exatamente QTD_CORINGA coringas e QTD_CURA
# curas. Nem mais, nem menos. Quando o saco acaba, monta outro.
#
# Sao DUAS garantias em cima do embaralhamento, e as duas importam:
#
# - ESTRATIFICACAO: coringa e cura nao entram no monte para serem
#   embaralhados junto com o resto. Se entrassem, um embaralhamento
#   honesto poderia por os 8 coringas nas 8 primeiras cartas e deixar
#   as 92 seguintes sem nenhum - a media estaria certa e a sensacao,
#   pessima. Em vez disso o saco e dividido em faixas iguais e cai UM
#   em cada faixa, em posicao sorteada dentro dela. Assim eles vem
#   espalhados: nunca a cada puxada, nunca uma seca longa.
#
# - SEM RAJADA: no maximo MAX_SEQUENCIA cartas seguidas da mesma cor.
#   Embaralhamento honesto ainda entrega "veio um monte de vermelho
#   seguido"; a passagem de reparo desmancha essas filas.
#
# O VALOR (1 a 9) continua sorteado por carta - o saco controla COR,
# que e o que decide combo. Se um dia o critico (trio igual ou
# sequencia) precisar de controle, e aqui que ele entra.

const TAMANHO := 100
const POR_COR_ATAQUE := 16  # 5 cores x 16 = 80
const QTD_CURA := 12
const QTD_CORINGA := 8
const MAX_SEQUENCIA := 3

const CORES_DE_ATAQUE := [
	CardData.Cor.VERMELHO, CardData.Cor.AZUL, CardData.Cor.VERDE,
	CardData.Cor.AMARELO, CardData.Cor.ROXO,
]

var _rng: RandomNumberGenerator
var _cartas: Array[CardData] = []
var _pos := 0  # indice da proxima a sair (evita pop_front, que e O(n))

func _init(p_rng: RandomNumberGenerator) -> void:
	_rng = p_rng
	_encher()

# Quantas cartas ainda restam no saco atual. So para depuracao e para
# a sonda de balanceamento - o jogo nunca fica sem: quando zera, um
# saco novo e montado na hora.
func restantes() -> int:
	return _cartas.size() - _pos

func comprar() -> CardData:
	if _pos >= _cartas.size():
		_encher()
	var carta := _cartas[_pos]
	_pos += 1
	return carta

# Monta um saco novo: reserva as posicoes dos coringas e das curas
# (espalhadas), preenche o resto com as cores de ataque embaralhadas e
# so entao desmancha as rajadas.
func _encher() -> void:
	_cartas.clear()
	_cartas.resize(TAMANHO)
	_pos = 0

	var ocupadas := {}
	_espalhar(CardData.Cor.CORINGA, QTD_CORINGA, ocupadas)
	_espalhar(CardData.Cor.CURA, QTD_CURA, ocupadas)

	# o resto do saco: as 5 cores de ataque, em quantidade igual
	var ataque: Array[CardData] = []
	for cor: int in CORES_DE_ATAQUE:
		for i in POR_COR_ATAQUE:
			ataque.append(CardData.new(cor, _rng.randi_range(1, 9)))
	_embaralhar(ataque)

	var proxima := 0
	for i in TAMANHO:
		if _cartas[i] == null:
			_cartas[i] = ataque[proxima]
			proxima += 1

	_quebrar_rajadas()

# Poe `quantidade` cartas da cor dada espalhadas pelo saco: uma em cada
# faixa de TAMANHO/quantidade posicoes. E isso que impede tanto o
# amontoado quanto a seca.
func _espalhar(cor: int, quantidade: int, ocupadas: Dictionary) -> void:
	var faixa := float(TAMANHO) / float(quantidade)
	for i in quantidade:
		var inicio := int(i * faixa)
		var fim := mini(int((i + 1) * faixa), TAMANHO) - 1
		if fim < inicio:
			fim = inicio
		# dentro da faixa, posicao sorteada; se cair numa ja ocupada
		# (coringa e cura dividem o mesmo saco), anda ate achar vaga
		var pos := _rng.randi_range(inicio, fim)
		var tentativas := 0
		while ocupadas.has(pos) and tentativas < TAMANHO:
			pos = (pos + 1) % TAMANHO
			tentativas += 1
		ocupadas[pos] = true
		_cartas[pos] = CardData.new(cor, _rng.randi_range(1, 9))

func _embaralhar(cartas: Array[CardData]) -> void:
	for i in range(cartas.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp := cartas[i]
		cartas[i] = cartas[j]
		cartas[j] = tmp

# Desmancha filas de mais de MAX_SEQUENCIA cartas da mesma cor: a
# carta excedente troca de lugar com uma de cor diferente mais a
# frente. O saco continua com a mesma composicao - so a ordem muda.
func _quebrar_rajadas() -> void:
	var repeticoes := 1
	for i in range(1, _cartas.size()):
		if _cartas[i].cor != _cartas[i - 1].cor:
			repeticoes = 1
			continue
		repeticoes += 1
		if repeticoes <= MAX_SEQUENCIA:
			continue
		for j in range(i + 1, _cartas.size()):
			if _cartas[j].cor == _cartas[i].cor:
				continue
			# a troca nao pode criar uma rajada nova no lugar de destino
			if _cartas[j - 1].cor == _cartas[i].cor:
				continue
			var tmp := _cartas[i]
			_cartas[i] = _cartas[j]
			_cartas[j] = tmp
			break
		repeticoes = 1
