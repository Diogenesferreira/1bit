extends Control

# Tela de entrada. Nesta rodada ela existe para duas coisas: escolher o
# estilo ANTES de entrar (o mockup tem dois e os dois estao montados) e
# abrir a batalha. Home, mapa e resultado ficam para depois.

const TELA := Vector2(1080, 1920)

var _fundo: TextureRect
var _botao_tema: Button
var _leque: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_montar()


func _montar() -> void:
	_fundo = TextureRect.new()
	_fundo.texture = Tema.cenario()
	_fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fundo.stretch_mode = TextureRect.STRETCH_SCALE
	_fundo.size = TELA
	_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fundo)

	var veu := ColorRect.new()
	veu.color = Color(0, 0, 0, 0.45)
	veu.size = TELA
	veu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veu)

	var titulo := _texto("HEROES", 132, Tema.acento())
	titulo.position = Vector2(0, 300)
	titulo.size.x = TELA.x
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(titulo)

	var sub := _texto("card battler", 40, Tema.texto())
	sub.position = Vector2(0, 452)
	sub.size.x = TELA.x
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)

	# leque de cartas girado, como no mockup da tela de titulo
	_leque = Control.new()
	_leque.position = Vector2(TELA.x / 2.0, 900)
	_leque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_leque)
	_montar_leque()

	var jogar := Button.new()
	jogar.text = "PARTIR EM MISSAO"
	jogar.position = Vector2(TELA.x / 2.0 - 320, 1340)
	jogar.size = Vector2(640, 130)
	jogar.add_theme_font_size_override("font_size", 44)
	jogar.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://batalha.tscn"))
	add_child(jogar)

	_botao_tema = Button.new()
	_botao_tema.text = "ESTILO: %s" % Tema.nome().to_upper()
	_botao_tema.position = Vector2(TELA.x / 2.0 - 320, 1500)
	_botao_tema.size = Vector2(640, 110)
	_botao_tema.add_theme_font_size_override("font_size", 36)
	_botao_tema.pressed.connect(_ao_trocar_tema)
	add_child(_botao_tema)


func _montar_leque() -> void:
	for no in _leque.get_children():
		no.queue_free()
	var cores := [
		CardData.Cor.VERMELHO, CardData.Cor.AZUL, CardData.Cor.CORINGA,
		CardData.Cor.VERDE, CardData.Cor.ROXO,
	]
	for i in cores.size():
		var arte := TextureRect.new()
		arte.texture = Tema.carta(cores[i])
		arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		arte.stretch_mode = TextureRect.STRETCH_SCALE
		arte.size = Vector2(200, 280)
		arte.pivot_offset = Vector2(100, 140)
		arte.position = Vector2(-100 + (i - 2) * 150, -140)
		arte.rotation = deg_to_rad((i - 2) * 9)
		arte.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_leque.add_child(arte)


func _ao_trocar_tema() -> void:
	Tema.alternar()
	_fundo.texture = Tema.cenario()
	_botao_tema.text = "ESTILO: %s" % Tema.nome().to_upper()
	_montar_leque()


func _texto(txt: String, tamanho: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("shadow_offset_x", 3)
	l.add_theme_constant_override("shadow_offset_y", 3)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
