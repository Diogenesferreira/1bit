extends Control
class_name FragmentPortrait

# Componente canônico do retrato quadrado. A mesma geometria deve ser usada na
# batalha, no menu de personagens e em qualquer inspeção futura do aliado.

const CANVAS := Vector2(330, 330)
const ABERTURA_330 := [
	Vector2(36, 30), Vector2(294, 30), Vector2(294, 228), Vector2(36, 228),
]

var portrait: Polygon2D
var portrait_rect := Rect2()


func montar(tipo: String, textura: Texture2D, zoom := 1.0,
		deslocamento := Vector2.ZERO) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var escala := size / CANVAS
	var abertura := PackedVector2Array()
	for ponto in ABERTURA_330:
		abertura.append(ponto * escala)
	portrait_rect = _limites(abertura)

	# A máscara usa exatamente a janela 258×198 definida pelo pacote v8.
	var fundo := Polygon2D.new()
	fundo.polygon = abertura
	fundo.color = Color("111116")
	fundo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(fundo)

	portrait = Polygon2D.new()
	portrait.polygon = abertura
	portrait.texture = textura
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var nativo := textura.get_size()
	var fator := maxf(portrait_rect.size.x / nativo.x,
		portrait_rect.size.y / nativo.y) * zoom
	var desenhado := nativo * fator
	var origem := portrait_rect.get_center() - desenhado / 2.0 + deslocamento * escala
	var uvs := PackedVector2Array()
	for ponto in abertura:
		uvs.append((ponto - origem) / fator)
	portrait.uv = uvs
	portrait.z_index = 2
	add_child(portrait)

	var moldura := TextureRect.new()
	moldura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	moldura.texture = Arte.selo_v6_empty(tipo)
	moldura.size = size
	moldura.stretch_mode = TextureRect.STRETCH_SCALE
	moldura.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	moldura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moldura.z_index = 10
	add_child(moldura)


func _limites(pontos: PackedVector2Array) -> Rect2:
	var resultado := Rect2(pontos[0], Vector2.ZERO)
	for ponto in pontos:
		resultado = resultado.expand(ponto)
	return resultado
