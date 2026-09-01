extends Control
class_name FieldSlot

# Uma das 12 casas do CAMPO: 2 fileiras de 5 (a mao) + a coluna 6 de
# cada fileira, que e a casa de ENTRADA.
#
# A ENTRADA nasce vazia e so recebe carta quando o jogador marca a 1a e
# a 2a carta de um trio: e ali que a carta do topo do saco DESCE, ja
# pronta pra fechar o trio. Ela e desenhada com a moldura mais apagada
# pra ficar claro que e casa de passagem, nao de mao.

signal tocado(indice: int)

const OPACIDADE_ENTRADA := 0.45

var indice := 0
var entrada := false
var habilitado := true

@onready var _frame: TextureRect = $Frame
@onready var _icone: CardIcon = $Icone


func configurar(p_indice: int, tam: Vector2, lado_icone: float, p_entrada: bool) -> void:
	indice = p_indice
	entrada = p_entrada
	size = tam
	mouse_filter = Control.MOUSE_FILTER_STOP
	_frame.size = tam
	_frame.visible = false
	_icone.configurar(tam, lado_icone, p_indice, true, 0.25, 16)
	_icone.fixar_em(Vector2.ZERO)


func mostrar(tipo: String, valor: int, animar := true) -> void:
	_icone.mostrar(tipo, valor, animar)


func definir_selecionada(valor: bool) -> void:
	_icone.definir_selecionada(valor)


func limpar() -> void:
	_icone.limpar()


func cheia() -> bool:
	return not _icone.vazio()


func tipo_atual() -> String:
	return _icone.tipo


func valor_atual() -> int:
	return _icone.valor


# Centro da casa, em coordenadas do canvas - de onde as cartas saem e
# para onde voltam nas animacoes.
func centro() -> Vector2:
	return position + size / 2.0


func _gui_input(evento: InputEvent) -> void:
	if not habilitado:
		return
	if evento is InputEventMouseButton:
		var clique := evento as InputEventMouseButton
		if clique.pressed and clique.button_index == MOUSE_BUTTON_LEFT:
			tocado.emit(indice)
	elif evento is InputEventScreenTouch and evento.pressed:
		tocado.emit(indice)
