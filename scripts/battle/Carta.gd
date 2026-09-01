extends RefCounted
class_name Carta

# Uma carta do campo. O tipo e o mesmo vocabulario do handoff (os
# icones em assets/battle/icon_*.png); o valor 1-9 vem da mecanica dos
# MDs, e so ele decide CRITICO (tres iguais ou sequencia).
#
# Os 7 tipos do handoff batem um a um com as 7 cores do jogo antigo:
#   dragon/knight/nature/light/dark = as 5 cores de ataque
#   capsule                         = a carta de CURA
#   wild                            = o CORINGA (casa com qualquer cor)

const CURA := "capsule"
const CORINGA := "wild"
const TIPOS_ATAQUE := ["dragon", "knight", "nature", "light", "dark"]

# Ordem fixa para arrumar a mao no fim da corrente (agrupada por tipo,
# valor crescente dentro do tipo) e para desempate estavel.
const ORDEM := {
	"dragon": 0, "knight": 1, "nature": 2, "light": 3, "dark": 4,
	"capsule": 5, "wild": 6,
}

var tipo: String
var valor: int


func _init(p_tipo: String, p_valor: int) -> void:
	tipo = p_tipo
	valor = p_valor


# Duas cartas podem entrar no mesmo trio? O coringa casa com tudo.
static func combina(a: String, b: String) -> bool:
	return a == b or a == CORINGA or b == CORINGA


static func ordem_de(tipo_: String) -> int:
	return int(ORDEM.get(tipo_, 99))


# Tipo de um conjunto: o primeiro que nao e coringa. Se todos forem
# coringa, o proprio CORINGA (trio so de coringas, caso especial).
static func tipo_do_trio(cartas: Array) -> String:
	for c: Carta in cartas:
		if c.tipo != CORINGA:
			return c.tipo
	return CORINGA
