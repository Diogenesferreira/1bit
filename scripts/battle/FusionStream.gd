extends Control
class_name FusionStream

signal finalizado

const TOTAL := 48
const ATRASO_MAX := 0.30
const DUR_MIN := 0.38
const DUR_EXTRA := 0.18
const DUR_TOTAL := ATRASO_MAX + DUR_MIN + DUR_EXTRA

var tipo := "nature"
var origem := Vector2.ZERO
var alvo := Vector2.ZERO
var _tempo := 0.0
var _velocidade := 1.0


func iniciar(p_tipo: String, de: Vector2, para: Vector2, velocidade := 1.0) -> void:
	tipo = p_tipo
	origem = de
	alvo = para
	_velocidade = maxf(velocidade, 0.1)
	size = Vector2.ZERO
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(delta: float) -> void:
	_tempo += delta * _velocidade
	queue_redraw()
	if _tempo >= DUR_TOTAL:
		set_process(false)
		finalizado.emit()
		queue_free()


func _draw() -> void:
	for i in TOTAL:
		var atraso := float(i) / float(TOTAL - 1) * ATRASO_MAX
		var duracao := DUR_MIN + float(i % 7) / 6.0 * DUR_EXTRA
		var f := clampf((_tempo - atraso) / duracao, 0.0, 1.0)
		if _tempo < atraso or f >= 1.0:
			continue
		var cor := Arte.cor_elemental(tipo)
		if tipo == Carta.CORINGA:
			cor = Arte.cor_elemental(Arte.ELEMENTOS[i % Arte.ELEMENTOS.size()])
		var espalhamento := (float((i * 37) % 101) / 100.0) * 2.0 - 1.0
		var controle := (origem + alvo) / 2.0 + Vector2(espalhamento * 92.0,
			-35.0 - float((i * 19) % 53))
		for rastro in 3:
			var amostra := clampf(f - float(rastro) * 0.07, 0.0, 1.0)
			var ponto := _bezier(origem, controle, alvo, amostra).round()
			var lado := float(7 - rastro * 2)
			var alpha := (1.0 if rastro == 0 else 0.50 / float(rastro)) \
				* (1.0 - smoothstep(0.88, 1.0, f))
			var tinta := cor.lerp(Arte.BRANCO, 0.18) if rastro == 0 \
				else Color(Arte.BRANCO, alpha)
			if rastro == 0:
				tinta.a = alpha
			draw_rect(Rect2(ponto - Vector2.ONE * lado / 2.0, Vector2.ONE * lado), tinta)


func _bezier(de: Vector2, controle: Vector2, para: Vector2, f: float) -> Vector2:
	var inv := 1.0 - f
	return inv * inv * de + 2.0 * inv * f * controle + f * f * para
