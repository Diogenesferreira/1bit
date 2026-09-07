## Numero de dano que sobe sobre o inimigo.
## Contrato: spec/ANIMACOES_V2.md secao 3.
##
## O popup NAO e empilhado em coluna: cada elo da cadeia nasce numa das 8
## posicoes de SCATTER, na cor do proprio elemento daquele elo. E placa opaca
## atras do numero — sem ela o dano se perde em blur sobre a arte do inimigo.
class_name DamagePopup
extends Control

const EL_BASE := {"dragon":Color("a8443a"),"knight":Color("5a86a8"),"nature":Color("7d9455"),"light":Color("c9a842"),"dark":Color("7a5f9a")}
const EL_LIT  := {"dragon":Color("d9705f"),"knight":Color("8ab6d4"),"nature":Color("a8c07a"),"light":Color("f0d478"),"dark":Color("a37fd0")}

## x em % do centro do inimigo, y em px acima da base do sprite
const SCATTER := [
	Vector2(0, 14), Vector2(-19, 40), Vector2(17, 26), Vector2(-12, 58),
	Vector2(21, 52), Vector2(-24, 8), Vector2(9, 66), Vector2(-8, 82),
]
const DUR := 0.95

var _bg: ColorRect
var _label: BitmapFontLabel
var _t := 0.0
var _base := Vector2.ZERO

## lane = indice do elo na cadeia (define a posicao no SCATTER)
static func spawn(parent: Node, sprite_w: float, sprite_h: float, valor: int,
		elemento: String, lane: int, grande := false) -> DamagePopup:
	var p := DamagePopup.new()
	parent.add_child(p)
	p._build(sprite_w, sprite_h, valor, elemento, lane, grande)
	return p

func _build(sprite_w: float, sprite_h: float, valor: int, elemento: String,
		lane: int, grande: bool) -> void:
	var sc: Vector2 = SCATTER[lane % SCATTER.size()]
	var base_col: Color = EL_BASE.get(elemento, Color("c9c0a8"))
	var lit: Color = EL_LIT.get(elemento, Color("e8e3d4"))

	_label = BitmapFontLabel.new()
	_label.glyph_height = 32 if grande else 26
	_label.tracking = 1
	_label.text = "+%d" % valor
	_label.modulate = lit

	var pad := Vector2(10, 3)
	var size_px := Vector2(_label.custom_minimum_size.x + pad.x * 2,
		float(_label.glyph_height) + pad.y * 2)

	_bg = ColorRect.new()
	_bg.color = Color(0.031, 0.035, 0.031, 0.82)   # rgba(8,9,8,.82)
	_bg.size = size_px
	add_child(_bg)
	_borda(size_px, lit)
	_label.position = pad
	add_child(_label)

	# posicao: centro do sprite + deslocamento do SCATTER
	_base = Vector2(sprite_w * 0.5 + sprite_w * sc.x / 100.0 - size_px.x * 0.5,
		sprite_h - sprite_h * 0.42 - sc.y - size_px.y)
	position = _base
	set_anchors_preset(Control.PRESET_TOP_LEFT)

func _borda(size_px: Vector2, c: Color) -> void:
	for r in [Rect2(0, 0, size_px.x, 2), Rect2(0, size_px.y - 2, size_px.x, 2),
			Rect2(0, 0, 2, size_px.y), Rect2(size_px.x - 2, 0, 2, size_px.y)]:
		var b := ColorRect.new()
		b.color = c
		b.position = r.position
		b.size = r.size
		add_child(b)

## Curva b1Rise: nasce em .7, estica a 1.12 em 18%, assenta em 32%, sobe 32 px.
func _process(delta: float) -> void:
	_t += delta
	var p := clampf(_t / DUR, 0.0, 1.0)
	var s := 0.7
	if p < 0.18:
		s = lerpf(0.7, 1.12, p / 0.18)
	elif p < 0.32:
		s = lerpf(1.12, 1.0, (p - 0.18) / 0.14)
	else:
		s = 1.0
	scale = Vector2(s, s)
	position = _base + Vector2(0, -32.0 * maxf(0.0, (p - 0.32) / 0.68))
	modulate.a = 1.0 if p < 0.32 else 1.0 - (p - 0.32) / 0.68
	if p >= 1.0:
		queue_free()
