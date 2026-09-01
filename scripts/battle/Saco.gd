extends RefCounted
class_name Saco

# O SACO de compra (o BAG da tela), portado do `Bag.gd` dos MDs.
#
# Nao e sorteio puro. O saco tem composicao FIXA e embaralhada: a cada
# TAMANHO cartas saem exatamente QTD_CORINGA coringas e QTD_CURA curas.
# Nem mais, nem menos. Quando acaba, monta outro.
#
# Duas garantias em cima do embaralhamento, e as duas importam:
#
# - ESTRATIFICACAO: coringa e cura nao entram no monte para embaralhar
#   junto. Um embaralhamento honesto poderia por os 8 coringas nas 8
#   primeiras cartas e deixar 92 sem nenhum - a media estaria certa e a
#   sensacao, pessima. Em vez disso o saco e dividido em faixas iguais
#   e cai UM em cada faixa, em posicao sorteada dentro dela.
#
# - SEM RAJADA: no maximo MAX_SEQUENCIA cartas seguidas do mesmo tipo.
#   A passagem de reparo desmancha as filas que o embaralhamento cria.
#
# O VALOR (1 a 9) e sorteado por carta: o saco controla TIPO, que e o
# que decide combo.

const TAMANHO := 100
const POR_TIPO_ATAQUE := 16  # 5 tipos x 16 = 80
const QTD_CURA := 12
const QTD_CORINGA := 8
const MAX_SEQUENCIA := 3

var _rng: RandomNumberGenerator
var _cartas: Array[Carta] = []
var _pos := 0  # indice da proxima a sair (evita pop_front, que e O(n))


func _init(p_rng: RandomNumberGenerator) -> void:
	_rng = p_rng
	_encher()


func restantes() -> int:
	return _cartas.size() - _pos


func comprar() -> Carta:
	if _pos >= _cartas.size():
		_encher()
	var carta := _cartas[_pos]
	_pos += 1
	return carta


func _encher() -> void:
	_cartas.clear()
	_cartas.resize(TAMANHO)
	_pos = 0

	var ocupadas := {}
	_espalhar(Carta.CORINGA, QTD_CORINGA, ocupadas)
	_espalhar(Carta.CURA, QTD_CURA, ocupadas)

	var ataque: Array[Carta] = []
	for tipo: String in Carta.TIPOS_ATAQUE:
		for i in POR_TIPO_ATAQUE:
			ataque.append(Carta.new(tipo, _rng.randi_range(1, 9)))
	_embaralhar(ataque)

	var proxima := 0
	for i in TAMANHO:
		if _cartas[i] == null:
			_cartas[i] = ataque[proxima]
			proxima += 1

	_quebrar_rajadas()


# Poe `quantidade` cartas do tipo dado espalhadas pelo saco: uma em cada
# faixa de TAMANHO/quantidade posicoes. E isso que impede tanto o
# amontoado quanto a seca.
func _espalhar(tipo: String, quantidade: int, ocupadas: Dictionary) -> void:
	var faixa := float(TAMANHO) / float(quantidade)
	for i in quantidade:
		var inicio := int(i * faixa)
		var fim := mini(int((i + 1) * faixa), TAMANHO) - 1
		if fim < inicio:
			fim = inicio
		var pos := _rng.randi_range(inicio, fim)
		var tentativas := 0
		while ocupadas.has(pos) and tentativas < TAMANHO:
			pos = (pos + 1) % TAMANHO
			tentativas += 1
		ocupadas[pos] = true
		_cartas[pos] = Carta.new(tipo, _rng.randi_range(1, 9))


func _embaralhar(cartas: Array[Carta]) -> void:
	for i in range(cartas.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp := cartas[i]
		cartas[i] = cartas[j]
		cartas[j] = tmp


# Desmancha filas de mais de MAX_SEQUENCIA cartas do mesmo tipo: a
# excedente troca de lugar com uma de tipo diferente mais a frente. O
# saco continua com a mesma composicao - so a ordem muda.
func _quebrar_rajadas() -> void:
	var repeticoes := 1
	for i in range(1, _cartas.size()):
		if _cartas[i].tipo != _cartas[i - 1].tipo:
			repeticoes = 1
			continue
		repeticoes += 1
		if repeticoes <= MAX_SEQUENCIA:
			continue
		for j in range(i + 1, _cartas.size()):
			if _cartas[j].tipo == _cartas[i].tipo:
				continue
			if _cartas[j - 1].tipo == _cartas[i].tipo:
				continue
			var tmp := _cartas[i]
			_cartas[i] = _cartas[j]
			_cartas[j] = tmp
			break
		repeticoes = 1
