extends SceneTree

# Ferramenta de inspeção: informa o retângulo não transparente dos retratos.

const ARQUIVOS := ["red", "blue", "nature", "light", "dark"]


func _initialize() -> void:
	for nome in ARQUIVOS:
		var imagem := Image.load_from_file("res://personagem_novo/%s.png" % nome)
		var usado := imagem.get_used_rect()
		var solido := _limites_alpha(imagem, 0.5)
		print(nome, ": usado=", usado, " solido=", solido, " alpha_cantos=", [
			imagem.get_pixel(0, 0).a,
			imagem.get_pixel(imagem.get_width() - 1, 0).a,
			imagem.get_pixel(0, imagem.get_height() - 1).a,
			imagem.get_pixel(imagem.get_width() - 1, imagem.get_height() - 1).a,
		])
	quit()


func _limites_alpha(imagem: Image, minimo: float) -> Rect2i:
	var minimo_xy := Vector2i(imagem.get_width(), imagem.get_height())
	var maximo_xy := Vector2i(-1, -1)
	for y in imagem.get_height():
		for x in imagem.get_width():
			if imagem.get_pixel(x, y).a < minimo:
				continue
			minimo_xy.x = mini(minimo_xy.x, x)
			minimo_xy.y = mini(minimo_xy.y, y)
			maximo_xy.x = maxi(maximo_xy.x, x)
			maximo_xy.y = maxi(maximo_xy.y, y)
	return Rect2i(minimo_xy, maximo_xy - minimo_xy + Vector2i.ONE)
