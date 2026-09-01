extends Control
class_name ElementImpact

signal finalizado

const DURACAO := 0.90

var tipo := "dragon"
var cor := Color.WHITE
var _tempo := 0.0


func iniciar(p_tipo: String, centro: Vector2) -> void:
	tipo = p_tipo
	cor = Arte.cor_elemental(tipo)
	position = centro.round()
	size = Vector2.ZERO
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(delta: float) -> void:
	_tempo += delta
	queue_redraw()
	if _tempo >= DURACAO:
		set_process(false)
		finalizado.emit()
		queue_free()


func _draw() -> void:
	var k := clampf(_tempo / DURACAO, 0.0, 1.0)
	if k < 0.10:
		draw_rect(Rect2(-52, -52, 104, 104), Color(Arte.BRANCO, 1.0 - k / 0.10))
	match tipo:
		"dragon": _fogo(k)
		"knight": _aco(k)
		"nature": _natureza(k)
		"light": _luz(k)
		"dark": _trevas(k)
		_: _luz(k)


func _fogo(k: float) -> void:
	for i in 10:
		var fase := clampf((k - float(i) * 0.018) / 0.62, 0.0, 1.0)
		var altura: float = round(sin(fase * PI) * (42.0 + float(i % 4) * 8.0))
		var x: float = round((float(i) - 4.5) * 11.0)
		draw_rect(Rect2(x - 4, -altura, 8, altura), Color(cor, 1.0 - fase * 0.7))
		if altura > 12:
			draw_rect(Rect2(x - 2, -altura, 4, altura * 0.42), Color("f0d7a0"))
	for i in 18:
		var y: float = -round(fmod(k * 78.0 + float(i * 13), 58.0))
		var x: float = round((float((i * 29) % 97) - 48.0) + sin(k * 8.0 + i) * 4.0)
		draw_rect(Rect2(x, y, 4, 4), Color(cor, 1.0 - k))


func _aco(k: float) -> void:
	for onda in 3:
		var fase := clampf((k - float(onda) * 0.12) / 0.68, 0.0, 1.0)
		var raio := 6.0 + 48.0 * fase
		for i in 28:
			var a := TAU * float(i) / 28.0
			var p := Vector2(cos(a), sin(a) * 0.60) * raio
			draw_rect(Rect2(p.round() - Vector2(2, 2), Vector2(4, 4)), Color(cor, 1.0 - fase))
	for i in 14:
		var a := TAU * float(i) / 14.0
		var p := Vector2(cos(a), sin(a)) * (10.0 + 58.0 * k)
		draw_rect(Rect2(p.round() - Vector2(2, 2), Vector2(5, 5)), Color("5f7d94", 1.0 - k))


func _natureza(k: float) -> void:
	for i in 7:
		var fase := clampf((k - float(i) * 0.05) / 0.50, 0.0, 1.0)
		var h: float = round(58.0 * sin(fase * PI * 0.82))
		var x := (float(i) - 3.0) * 15.0
		var pontos := PackedVector2Array([Vector2(x - 6, 4), Vector2(x, -h), Vector2(x + 6, 4)])
		draw_colored_polygon(pontos, cor)
		draw_line(Vector2(x, -h), Vector2(x, -h + 12), Arte.BRANCO, 3.0, false)
	for i in 16:
		var x := (float((i * 31) % 101) - 50.0) + sin(k * 7.0 + i) * 8.0
		var y := -56.0 + fmod(k * 82.0 + float(i * 11), 72.0)
		draw_rect(Rect2(Vector2(x, y).round(), Vector2(6, 3)), Color(cor, 1.0 - k * 0.5))


func _luz(k: float) -> void:
	for i in 8:
		var a := TAU * float(i) / 8.0
		var ponta := Vector2(cos(a), sin(a)) * (24.0 + 54.0 * k)
		draw_line(Vector2.ZERO, ponta.round(), Color("f5ecd0", 1.0 - k), 4.0, false)
	for onda in 2:
		var fase := clampf((k - float(onda) * 0.16) / 0.72, 0.0, 1.0)
		for i in 30:
			var a := TAU * float(i) / 30.0
			var p := Vector2(cos(a), sin(a) * 0.70) * (6.0 + 44.0 * fase)
			draw_rect(Rect2(p.round() - Vector2.ONE, Vector2(3, 3)), Color(cor, 1.0 - fase))


func _trevas(k: float) -> void:
	for i in 80:
		if i % 3 == 0:
			continue
		var base_raio := 72.0 * (1.0 - k) if k < 0.42 else 72.0 * (k - 0.42) / 0.58
		var a := float(i) * 2.399963 + k * 5.0
		var p := Vector2(cos(a), sin(a)) * (base_raio * (0.35 + float(i) / 120.0))
		var lado := 3.0 if i % 4 else 6.0
		draw_rect(Rect2(p.round() - Vector2.ONE * lado / 2.0, Vector2.ONE * lado), Color(cor, 1.0 - k * 0.55))
	for i in 3:
		draw_rect(Rect2(-18.0 + i * 18.0, 18.0 + k * 34.0, 5, 10), Color(cor, 1.0 - k))
