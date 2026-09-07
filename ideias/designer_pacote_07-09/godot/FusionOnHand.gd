## Fusao de cartas — vive na FAIXA DA MAO, nunca no palco.
## Contrato completo: spec/FUSAO_NA_MAO.md (substitui a secao 6 de ANIMACOES.md).
## Se ja existir uma cena FusionFX ancorada no palco, ela deve ser REANCORADA
## aqui, dentro do HandRow, com a geometria abaixo — nao adaptada no lugar velho.
class_name FusionOnHand
extends Control

const EL_BASE := {"dragon":Color("a8443a"),"knight":Color("5a86a8"),"nature":Color("7d9455"),"light":Color("c9a842"),"dark":Color("7a5f9a")}
const EL_LIT  := {"dragon":Color("d9705f"),"knight":Color("8ab6d4"),"nature":Color("a8c07a"),"light":Color("f0d478"),"dark":Color("a37fd0")}

const T_RISE := 0.07
const T_STACK := 0.56
const T_BURST := 0.98
const T_BEAM := 1.28
const T_DONE := 1.78

@export var element: String = "dragon"
var _t := 0.0
var _phase := 1
var _cards: Array[TextureRect] = []
var _glow: ColorRect
var _burst: ColorRect
var _beam: ColorRect
var _running := false

signal charge_delivered(element: String, amount: int)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow = _rect(Rect2(0, 0, 0, 0), Color(0, 0, 0, 0)); _glow.visible = false
	_burst = _rect(Rect2(0, 0, 0, 0), Color(0, 0, 0, 0)); _burst.visible = false
	_beam = _rect(Rect2(0, 0, 0, 0), Color(0, 0, 0, 0)); _beam.visible = false
	for i in 3:
		var t := TextureRect.new()
		t.stretch_mode = TextureRect.STRETCH_SCALE
		t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		t.size = Vector2(78, 108)
		add_child(t)
		_cards.append(t)

## Chame com a POSIÇÃO CENTRAL da mão (x do meio da faixa, y da base das cartas)
## e a posição do card do aliado (para o feixe apontar certo).
func play(el: String, hand_center: Vector2, ally_top: Vector2) -> void:
	element = el
	_running = true
	_t = 0.0
	_phase = 1
	var base: Color = EL_BASE[el]
	var lit: Color = EL_LIT[el]
	for i in 3:
		_cards[i].texture = load("res://art/ui/card_face_%s_v1.png" % el)
		_cards[i].modulate = Color(1, 1, 1, 1)
		_cards[i].self_modulate = lit
	visible = true

	var t := create_tween()
	t.tween_callback(func(): _phase = 2).set_delay(T_RISE)
	t.parallel().tween_property(self, "_t", 1.0, T_STACK)  # dummy para manter o tween vivo; posicoes no _process
	t.tween_callback(func(): _phase = 3)
	t.tween_callback(func(): _phase = 4; _burst_fx(hand_center, lit))
	t.tween_interval(T_BURST - T_STACK)
	t.tween_callback(func(): _phase = 5; _beam_fx(hand_center, ally_top, lit))
	t.tween_interval(T_BEAM - T_BURST)
	t.tween_callback(func():
		charge_delivered.emit(el, 3)
		_running = false
		visible = false
	).set_delay(T_DONE - T_BEAM)

func _process(_dt: float) -> void:
	if not _running: return
	# posiciona as 3 cartas conforme a fase — leque abrindo (fase 2) -> empilhado (fase 3+)
	for i in 3:
		var off := i - 1
		var risen := _phase >= 2
		var stacked := _phase >= 3
		var beam := _phase >= 5
		var dx := (off * 10.0) if stacked else (off * 60.0)
		var dy := -128.0 if risen else 0.0
		var rot := (off * -6.0) if (risen and not stacked) else 0.0
		_cards[i].position = Vector2(dx - 39, dy - 108)  # -39/-108 = metade da carta (78x108)
		_cards[i].rotation = deg_to_rad(rot)
		_cards[i].visible = not beam

## Estouro: mancha circular com blur (usa CanvasItem material `blur.gdshader`
## ou simplesmente shrinking alpha se nao houver shader de blur disponivel).
func _burst_fx(hand_center: Vector2, lit: Color) -> void:
	_burst.visible = true
	_burst.color = lit
	_burst.size = Vector2(150, 150)
	_burst.position = hand_center - Vector2(75, 150 + 36)
	var t := create_tween()
	t.tween_property(_burst, "modulate:a", 0.0, 0.5).from(1.0)
	t.parallel().tween_property(_burst, "scale", Vector2(1.6, 1.6), 0.5).from(Vector2(0.4, 0.4))
	t.tween_callback(func(): _burst.visible = false)

func _beam_fx(hand_center: Vector2, ally_top: Vector2, lit: Color) -> void:
	_beam.visible = true
	_beam.color = lit
	var h: float = maxf(60.0, hand_center.y - ally_top.y)
	_beam.size = Vector2(20, h)
	_beam.position = Vector2(hand_center.x - 10, ally_top.y)
	var t := create_tween()
	t.tween_property(_beam, "modulate:a", 0.0, 0.5).from(0.9)
	t.tween_callback(func(): _beam.visible = false)

func _rect(r: Rect2, c: Color) -> ColorRect:
	var n := ColorRect.new()
	n.color = c
	n.position = r.position
	n.size = r.size
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(n)
	return n
