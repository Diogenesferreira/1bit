extends Control
class_name BagSlot

# Uma casa da fileira do BAG: moldura pequena + icone da carta.
# Nao e clicavel - a fila do saco e so vitrine do que vem descer.

const TAM := Vector2(78, 108)
const LADO_ICONE := 78.0

var indice := 0

@onready var _frame: TextureRect = $Frame
@onready var _icone: CardIcon = $Icone


func _ready() -> void:
	size = TAM
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.size = TAM
	_frame.visible = false
	# A BAG e uma fila de leitura: cartas rigorosamente paradas e alinhadas.
	_icone.configurar(TAM, LADO_ICONE, indice, false, 0.3, 13)
	_icone.fixar_em(Vector2.ZERO)


func mostrar(tipo: String, valor: int, animar := false) -> void:
	_icone.mostrar(tipo, valor, animar)


func limpar() -> void:
	_icone.limpar()


func tipo_atual() -> String:
	return _icone.tipo


func valor_atual() -> int:
	return _icone.valor
