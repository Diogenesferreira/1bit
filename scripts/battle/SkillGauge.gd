extends Control
class_name SkillGauge

signal ativada

# Medidor elemental universal dos aliados: oito blocos em arco e o tipo
# no centro. Nao executa a skill; apenas representa a carga persistente.

const TOTAL_SEGMENTOS := 8
const ESCALA_MOLDURA_FONTE := 1254.0
const SEGMENTOS_MOLDURA := [
	[Vector2(166, 366), Vector2(216, 326), Vector2(273, 358), Vector2(241, 407), Vector2(178, 406)],
	[Vector2(247, 247), Vector2(296, 210), Vector2(350, 247), Vector2(328, 294), Vector2(270, 288)],
	[Vector2(357, 142), Vector2(412, 111), Vector2(466, 151), Vector2(447, 197), Vector2(392, 198)],
	[Vector2(492, 62), Vector2(563, 57), Vector2(570, 119), Vector2(515, 131), Vector2(486, 108)],
	[Vector2(678, 56), Vector2(736, 60), Vector2(762, 104), Vector2(735, 130), Vector2(680, 114)],
	[Vector2(809, 106), Vector2(865, 132), Vector2(908, 179), Vector2(866, 216), Vector2(820, 195)],
	[Vector2(941, 207), Vector2(995, 238), Vector2(1032, 294), Vector2(982, 326), Vector2(931, 289)],
	[Vector2(1026, 337), Vector2(1073, 364), Vector2(1100, 414), Vector2(1042, 420), Vector2(1003, 382)],
]
const SOCKET_MOLDURA := [
	Vector2(89, 461), Vector2(237, 461), Vector2(254, 478), Vector2(254, 552),
	Vector2(237, 570), Vector2(89, 570), Vector2(72, 552), Vector2(72, 478),
]
var tipo := ""
var _acesos := 0
var _cheio := false
var _tempo := 0.0
var _pronto_txt: Label
var _base_em_asset := false
var _asset_ja_colorido := false
var _moldura_usuario := false
var _folha_carga := false
var _carga_atlas: AtlasTexture
var _brilho_atlas: AtlasTexture
var _carga_arte: TextureRect
var _brilho_arte: TextureRect


func montar(p_tipo: String, p_tamanho := Vector2(96, 96), p_base_em_asset := false,
		p_asset_ja_colorido := false, p_moldura_usuario := false,
		p_folha_carga: Texture2D = null) -> void:
	tipo = p_tipo
	size = p_tamanho
	_base_em_asset = p_base_em_asset
	_asset_ja_colorido = p_asset_ja_colorido
	_moldura_usuario = p_moldura_usuario
	_folha_carga = p_folha_carga != null
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _folha_carga:
		_montar_folha_carga(p_folha_carga)
	_pronto_txt = Arte.rotulo("SKILL", Vector2(0, 9), 11, Arte.BRANCO,
		size.x, true, self)
	_pronto_txt.z_index = 4
	_pronto_txt.add_theme_color_override("font_shadow_color", Arte.ESCURO)
	_pronto_txt.add_theme_constant_override("shadow_offset_x", 2)
	_pronto_txt.add_theme_constant_override("shadow_offset_y", 2)
	_pronto_txt.visible = false
	atualizar(0.0, 1.0)


func atualizar(valor: float, maximo: float) -> void:
	var fracao := clampf(valor / maxf(1.0, maximo), 0.0, 1.0)
	_acesos = ceili(fracao * float(TOTAL_SEGMENTOS)) if fracao > 0.0 else 0
	_cheio = fracao >= 1.0
	if _folha_carga:
		_carga_atlas.region = Rect2(0, _acesos * 330, 330, 330)
		_brilho_atlas.region = Rect2(0, TOTAL_SEGMENTOS * 330, 330, 330)
		_brilho_arte.visible = _cheio
	# O halo da moldura e o arco completo ja comunicam que o selo virou
	# botao. Sem texto permanente, o retrato continua limpo no celular.
	_pronto_txt.visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP if _cheio else Control.MOUSE_FILTER_IGNORE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _cheio else Control.CURSOR_ARROW
	tooltip_text = "SKILL PRONTA — clique para usar" if _cheio else ""
	queue_redraw()
	set_process(_cheio)
	if not _cheio:
		modulate = Color.WHITE


func _gui_input(event: InputEvent) -> void:
	if not _cheio:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		accept_event()
		_feedback_clique()
		ativada.emit()


func _feedback_clique() -> void:
	pivot_offset = size / 2.0
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(1.14, 1.14), 0.09) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector2.ONE, 0.14) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	if _folha_carga:
		return
	if _moldura_usuario:
		_desenhar_moldura_usuario()
		return
	# No Selo de Fragmento o arco envolve o topo do retrato. O calculo relativo
	# tambem preserva o componente antigo de 96 px usado nas pranchas de teste.
	var centro := Vector2(size.x / 2.0, size.y * (0.455 if _base_em_asset else 0.47))
	var raio := size.x * 0.36 if _base_em_asset \
		else minf(size.x * 0.405, size.y * 0.40)
	var meio_tangente := maxf(4.5, size.x * (0.040 if _base_em_asset else 0.047))
	var meio_radial := maxf(3.0, size.x * (0.022 if _base_em_asset else 0.027))
	if _cheio:
		draw_rect(Rect2(Vector2(3, 3), size - Vector2(6, 6)),
			Color(Arte.cor_elemental(tipo), 0.30), false, 7.0)
		draw_rect(Rect2(Vector2(7, 7), size - Vector2(14, 14)),
			Color(Arte.BRANCO, 0.72), false, 2.0)
	# Oito blocos no semicirculo superior, como no conceito aprovado.
	for i in TOTAL_SEGMENTOS:
		var angulo := deg_to_rad(200.0 + float(i) * 140.0 / float(TOTAL_SEGMENTOS - 1))
		var radial := Vector2(cos(angulo), sin(angulo))
		var tangente := Vector2(-radial.y, radial.x)
		var centro_bloco := centro + radial * raio
		var pontos := PackedVector2Array([
			centro_bloco - tangente * meio_tangente - radial * meio_radial,
			centro_bloco + tangente * meio_tangente - radial * meio_radial,
			centro_bloco + tangente * (meio_tangente - 1.5) + radial * meio_radial,
			centro_bloco - tangente * (meio_tangente - 1.5) + radial * meio_radial,
		])
		var aceso := i < _acesos
		if _asset_ja_colorido:
			# O recorte canonico ja contem a arte colorida do segmento. A carga
			# apaga os blocos ainda indisponiveis em vez de redesenhar o arco.
			if aceso:
				continue
			draw_colored_polygon(pontos, Color("17171d"))
			var apagado := pontos.duplicate()
			apagado.append(pontos[0])
			draw_polyline(apagado, Color("77777f"), 1.5, false)
			continue
		if _base_em_asset and not aceso:
			continue
		var cor: Color = Arte.cor_elemental(tipo) if aceso else Color("303039")
		var borda := Arte.BRANCO if aceso else Color("8a8a92")
		if _cheio:
			# Duplo halo claro: continua pixelado, mas deixa inequivoco que
			# o mostrador passou de indicador para botao.
			var halo := PackedVector2Array()
			for ponto in pontos:
				halo.append(centro_bloco + (ponto - centro_bloco) * 1.24)
			var halo_fechado := halo.duplicate()
			halo_fechado.append(halo[0])
			draw_polyline(halo_fechado, Color(1, 1, 1, 0.34), 3.0, false)
		if not _base_em_asset:
			draw_colored_polygon(pontos, Color("111117"))
		var miolo := PackedVector2Array()
		for ponto in pontos:
			miolo.append(centro_bloco + (ponto - centro_bloco) * (0.62 if _base_em_asset else 0.72))
		draw_colored_polygon(miolo, cor)
		if not _base_em_asset:
			var contorno := pontos.duplicate()
			contorno.append(pontos[0])
			draw_polyline(contorno, borda, 2.0, false)


func _desenhar_moldura_usuario() -> void:
	var escala := Vector2(size.x, size.y) / ESCALA_MOLDURA_FONTE
	var cor_acesa := Arte.cor_elemental(tipo)
	for i in TOTAL_SEGMENTOS:
		var pontos := PackedVector2Array()
		for ponto: Vector2 in SEGMENTOS_MOLDURA[i]:
			pontos.append(ponto * escala)
		var cor := cor_acesa if i < _acesos else Color("1b1b21")
		draw_colored_polygon(pontos, cor)
	var socket := PackedVector2Array()
	for ponto: Vector2 in SOCKET_MOLDURA:
		socket.append(ponto * escala)
	draw_colored_polygon(socket, cor_acesa.lerp(Color("77777d"), 0.18))


func _process(delta: float) -> void:
	_tempo += delta
	var pulso := 0.5 - 0.5 * cos(fmod(_tempo, 1.3) / 1.3 * TAU)
	if _folha_carga:
		var cor := Arte.cor_elemental(tipo)
		_brilho_arte.modulate = Color(cor.r, cor.g, cor.b, 0.85 * pulso)
		_carga_arte.modulate = Color.WHITE.lerp(Color(1.12, 1.12, 1.12), pulso)
		return
	modulate.a = 0.78 + 0.22 * absf(sin(_tempo * 4.2))


func _montar_folha_carga(folha: Texture2D) -> void:
	_carga_atlas = AtlasTexture.new()
	_carga_atlas.atlas = folha
	_carga_atlas.region = Rect2(0, 0, 330, 330)
	_carga_arte = TextureRect.new()
	_carga_arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_carga_arte.texture = _carga_atlas
	_carga_arte.size = size
	_carga_arte.stretch_mode = TextureRect.STRETCH_SCALE
	_carga_arte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_carga_arte)
	_brilho_atlas = AtlasTexture.new()
	_brilho_atlas.atlas = folha
	_brilho_atlas.region = Rect2(0, TOTAL_SEGMENTOS * 330, 330, 330)
	_brilho_arte = TextureRect.new()
	_brilho_arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_brilho_arte.texture = _brilho_atlas
	_brilho_arte.size = size
	_brilho_arte.stretch_mode = TextureRect.STRETCH_SCALE
	_brilho_arte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var aditivo := CanvasItemMaterial.new()
	aditivo.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_brilho_arte.material = aditivo
	_brilho_arte.visible = false
	add_child(_brilho_arte)
