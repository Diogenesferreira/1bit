extends Control
class_name LaneSlot

# Uma das 3 casas da FUSION LANE - onde o trio em montagem fica.
#
# Toda carta marcada sai da casa dela no campo e vem parar aqui; tocar
# nela de novo desmarca (a carta volta pra casa e a que tinha descido do
# saco volta pro topo). Com as 3 cheias, o trio fecha.
#
# Alem de mostrar as cartas, e ela que faz as duas animacoes de
# resultado do handoff:
#   - fuse_pulse: inversao de cor duas vezes em 0.46s (trio fechou);
#   - shake_x: tremida horizontal de 6px em 0.4s (cadeia abandonada).

signal tocado(indice: int)

const TAM := Vector2(100, 88)
const LADO_ICONE := 66.0
const DUR_PULSO := 0.46
const DUR_TREMIDA := 0.4

var indice := 0

@onready var _frame: TextureRect = $Frame
@onready var _icone: CardIcon = $Icone

var _base := Vector2.ZERO


func _ready() -> void:
	size = TAM
	mouse_filter = Control.MOUSE_FILTER_STOP
	_frame.size = TAM
	_icone.configurar(TAM, LADO_ICONE, indice, false, 0.3, 13)
	_icone.fixar_em(Vector2.ZERO)


func fixar_em(p: Vector2) -> void:
	_base = p
	position = p


func centro() -> Vector2:
	return _base + TAM / 2.0


func mostrar(tipo: String, valor: int, animar := true) -> void:
	_icone.mostrar(tipo, valor, animar)


func limpar() -> void:
	_icone.limpar()


func cheia() -> bool:
	return not _icone.vazio()


func _gui_input(evento: InputEvent) -> void:
	if not (evento is InputEventMouseButton):
		return
	var clique := evento as InputEventMouseButton
	if not clique.pressed or clique.button_index != MOUSE_BUTTON_LEFT:
		return
	if cheia():
		tocado.emit(indice)


func _inverter(v: float) -> void:
	if _frame.material == null:
		_frame.material = Arte.material_inversor(0.0)
	(_frame.material as ShaderMaterial).set_shader_parameter("quantidade", v)
	_icone.inverter_quantidade(v)


func pulsar() -> void:
	var t := create_tween()
	for i in 2:
		t.tween_method(_inverter, 0.0, 1.0, DUR_PULSO / 4.0)
		t.tween_method(_inverter, 1.0, 0.0, DUR_PULSO / 4.0)
	await t.finished


func tremer() -> void:
	var t := create_tween()
	t.tween_property(self, "position", _base + Vector2(-6, 0), DUR_TREMIDA * 0.25)
	t.tween_property(self, "position", _base + Vector2(6, 0), DUR_TREMIDA * 0.5)
	t.tween_property(self, "position", _base, DUR_TREMIDA * 0.25)
	await t.finished
