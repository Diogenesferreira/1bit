extends Control
class_name FieldSlot

# Uma casa do campo. Cada fileira possui seis slots permanentes: cinco cartas
# iniciais e uma ENTRADA alimentada por NEXT.

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
	custom_minimum_size = tam
	size = tam
	mouse_filter = Control.MOUSE_FILTER_STOP
	_frame.size = tam
	_frame.visible = false
	# Cartas da mao ficam rigorosamente paradas na grade; selecao usa apenas rim.
	_icone.configurar(tam, lado_icone, p_indice, false, 0.25, 16)
	_icone.fixar_em(Vector2.ZERO)
	queue_redraw()


func mostrar(tipo: String, valor: int, animar := true) -> void:
	_icone.mostrar(tipo, valor, animar)
	queue_redraw()


func definir_selecionada(valor: bool) -> void:
	_icone.definir_selecionada(valor)


func limpar() -> void:
	_icone.limpar()
	queue_redraw()


func cheia() -> bool:
	return not _icone.vazio()


func tipo_atual() -> String:
	return _icone.tipo


func valor_atual() -> int:
	return _icone.valor


func _draw() -> void:
	# O berco pontilhado existe nos 12 slots e fica atras da face da carta.
	draw_rect(Rect2(Vector2.ONE, size - Vector2.ONE * 2.0), Color("0b0d0a"), true)
	var cor := Color(0.79, 0.75, 0.66, 0.34)
	var passo := 12.0
	var traco := 7.0
	var x := 2.0
	while x < size.x - 2.0:
		var fim := minf(x + traco, size.x - 2.0)
		draw_line(Vector2(x, 2), Vector2(fim, 2), cor, 2.0)
		draw_line(Vector2(x, size.y - 2), Vector2(fim, size.y - 2), cor, 2.0)
		x += passo
	var y := 2.0
	while y < size.y - 2.0:
		var fim := minf(y + traco, size.y - 2.0)
		draw_line(Vector2(2, y), Vector2(2, fim), cor, 2.0)
		draw_line(Vector2(size.x - 2, y), Vector2(size.x - 2, fim), cor, 2.0)
		y += passo
	var centro := size / 2.0
	var diamante := PackedVector2Array([
		centro + Vector2(0, -9), centro + Vector2(9, 0),
		centro + Vector2(0, 9), centro + Vector2(-9, 0), centro + Vector2(0, -9),
	])
	draw_polyline(diamante, cor, 2.0, false)


# Centro da casa, em coordenadas do canvas - de onde as cartas saem e
# para onde voltam nas animacoes.
func centro() -> Vector2:
	return position + size / 2.0


func posicao_carta_no_canvas() -> Vector2:
	return position + _icone.position


func centro_carta_no_canvas() -> Vector2:
	return posicao_carta_no_canvas() + size / 2.0


func _gui_input(evento: InputEvent) -> void:
	if not habilitado:
		return
	if evento is InputEventMouseButton:
		var clique := evento as InputEventMouseButton
		if clique.pressed and clique.button_index == MOUSE_BUTTON_LEFT:
			tocado.emit(indice)
	elif evento is InputEventScreenTouch and evento.pressed:
		tocado.emit(indice)
