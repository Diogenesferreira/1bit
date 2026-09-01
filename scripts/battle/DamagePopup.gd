extends Control
class_name DamagePopup

const TAM := Vector2(160, 104)

var _cor := Color.WHITE


func montar(texto: String, tipo := "light") -> void:
	size = TAM
	pivot_offset = TAM / 2.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cor = Arte.cor_elemental(tipo)
	Arte.rotulo(texto, Vector2(0, 29), 22, Arte.TEXTO_NO_CLARO,
		TAM.x, true, self).add_theme_color_override("font_shadow_color", _cor)
	queue_redraw()


func _draw() -> void:
	var centro := Vector2(80, 45)
	var preenchimento := PackedVector2Array()
	for i in 52:
		var a := TAU * float(i) / 52.0
		var modulacao := 1.0 + 0.14 * cos(13.0 * a)
		var p := centro + Vector2(cos(a) * 68.0, sin(a) * 36.0) * modulacao
		preenchimento.append(p.round())
	draw_colored_polygon(preenchimento, Color("e8e3d4"))
	var contorno := preenchimento.duplicate()
	contorno.append(preenchimento[0])
	draw_polyline(contorno, Color("201f1d"), 4.0, false)
	var cauda := PackedVector2Array([Vector2(69, 74), Vector2(82, 100), Vector2(92, 73)])
	draw_colored_polygon(cauda, Color("e8e3d4"))
	var cauda_linha := cauda.duplicate()
	cauda_linha.append(cauda[0])
	draw_polyline(cauda_linha, Color("201f1d"), 4.0, false)
