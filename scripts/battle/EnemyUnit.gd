extends Control
class_name EnemyUnit

signal tocado(indice: int)

const DUR_FLASH := 0.22

var dados: Dictionary = {}
var indice := -1

var _slot := Rect2()
var _sprite_rect := Rect2()
var _sprite: Sprite2D
var _hud_painel: Panel
var _plate_arte: TextureRect
var _life_clip: Control
var _life_arte: TextureRect
var _life_tween: Tween
var _hp_anterior := -1.0
var _life_inicio := 0.0
var _life_largura := 0.0
var _turno_atlas: AtlasTexture
var _turno_arte: TextureRect
var _turno_anterior := -1
var _tempo_life_baixo := 0.0
var _selecao: Panel
var _alvo_painel: Panel
var _seta: Control
var _tween_seta: Tween
var _seta_base := Vector2.ZERO
var _total_chip: Panel
var _total_label: BitmapFontLabel
var _morto := false
var _hit_ms := -100000
var _shake_amp := 7.0
var _base_pos := Vector2.ZERO
var _tem_base := false


func montar(p_dados: Dictionary, p_indice := -1, total := 1) -> void:
	dados = p_dados
	indice = p_indice
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var d: Dictionary = dados.def
	var preset := Unidades.preset_inimigo(total)
	_slot = Unidades.slot_inimigo(indice, total)

	# Sprite preserva proporcao, centraliza no slot e alinha a base em
	# y=268 logico para qualquer quantidade de inimigos.
	var textura: Texture2D = Arte.tex_recortada(String(d.sprite), d.recorte as Rect2) \
		if d.has("recorte") else Arte.tex(String(d.sprite))
	var sprite_logico: float = float((preset.sprites as Array)[indice]) \
		if preset.has("sprites") else float(preset.sprite)
	var maximo := Unidades.tamanho_logico(Vector2.ONE * sprite_logico)
	var sprite_tam := Unidades.ajustar_no_box(textura.get_size(), maximo)
	var centro_x: float = float((preset.centros as Array)[indice]) \
		if preset.has("centros") else _slot.get_center().x / Unidades.escala().x
	var base_logica: float = float((preset.bases as Array)[indice]) \
		if preset.has("bases") else 268.0
	var centro_px := Unidades.ponto_logico(Vector2(centro_x, 0)).x
	var base_y := Unidades.ponto_logico(Vector2(0, base_logica)).y
	var sprite_pos := Vector2(round(centro_px - sprite_tam.x / 2.0), base_y - sprite_tam.y)
	_sprite_rect = Rect2(sprite_pos, sprite_tam)
	_sprite = Sprite2D.new()
	_sprite.texture = textura
	add_child(_sprite)
	_sprite.position = _sprite_rect.get_center()
	_sprite.scale = sprite_tam / textura.get_size()

	# O slot inteiro recebe o toque, sem desenhar uma caixa adicional.
	_selecao = Panel.new()
	var toque := _sprite_rect.grow(8.0)
	_selecao.position = toque.position
	_selecao.size = toque.size
	_selecao.mouse_filter = Control.MOUSE_FILTER_STOP
	_selecao.gui_input.connect(_ao_input)
	var transparente := StyleBoxFlat.new()
	transparente.bg_color = Color(0, 0, 0, 0)
	_selecao.add_theme_stylebox_override("panel", transparente)
	add_child(_selecao)

	# HUD oficial v6: todas as camadas compartilham o canvas 384x144.
	# Numero e palavra TURN sao sprites; nenhuma fonte do sistema participa.
	var hud_rect := Unidades.hud_inimigo(_sprite_rect)
	var hud_tam := hud_rect.size
	_hud_painel = Panel.new()
	_hud_painel.position = hud_rect.position
	_hud_painel.size = hud_tam
	_hud_painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_painel.z_index = 20
	var hud_estilo := StyleBoxFlat.new()
	hud_estilo.bg_color = Color(0, 0, 0, 0)
	_hud_painel.add_theme_stylebox_override("panel", hud_estilo)
	add_child(_hud_painel)
	_plate_arte = _adicionar_arte_hud(Arte.hud_inimigo_v6_plate(String(d.elemento)),
		Vector2.ZERO, hud_tam, _hud_painel)

	_turno_atlas = AtlasTexture.new()
	_turno_atlas.atlas = Arte.tex("ui_v10/enemy/enemy_digits_sheet_v1.png")
	_turno_atlas.region = Rect2(0, 0, 42, 48)
	_turno_atlas.filter_clip = true
	var escala_hud := hud_tam / Vector2(384, 144)
	_turno_arte = _adicionar_arte_hud(_turno_atlas,
		Vector2(138, 12) * escala_hud, Vector2(42, 48) * escala_hud, _hud_painel)
	_adicionar_arte_hud(Arte.tex("ui_v10/enemy/enemy_label_turn_v1.png"),
		Vector2(186, 12) * escala_hud, Vector2(144, 48) * escala_hud, _hud_painel)
	_adicionar_arte_hud(Arte.tex("ui_v10/enemy/enemy_hp_well_v1.png"),
		Vector2.ZERO, hud_tam, _hud_painel)

	# A barra conserva o tamanho do canvas e e revelada por recorte horizontal.
	# Assim seus pixels nunca sao espremidos conforme o HP diminui.
	_life_clip = Control.new()
	_life_clip.size = hud_tam
	_life_clip.clip_contents = true
	_life_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_painel.add_child(_life_clip)
	_life_arte = _adicionar_arte_hud(Arte.tex("ui_v10/enemy/enemy_hp_fill_v1.png"),
		Vector2.ZERO, hud_tam, _life_clip)
	_life_inicio = hud_tam.x * 12.0 / 384.0
	_life_largura = hud_tam.x * 360.0 / 384.0

	# Indicador de alvo fica dentro do slot, logo acima do sprite.
	_alvo_painel = Panel.new()
	_alvo_painel.position = Vector2(round(_sprite_rect.get_center().x - 23.0),
		_hud_painel.position.y + hud_tam.y + 2.0)
	_alvo_painel.size = Vector2(46, 42)
	_alvo_painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var alvo_estilo := StyleBoxFlat.new()
	alvo_estilo.bg_color = Color(0.035, 0.037, 0.047, 0.88)
	alvo_estilo.border_color = Arte.BRANCO
	alvo_estilo.set_border_width_all(2)
	alvo_estilo.set_corner_radius_all(4)
	_alvo_painel.add_theme_stylebox_override("panel", alvo_estilo)
	_alvo_painel.visible = false
	_alvo_painel.z_index = 21
	add_child(_alvo_painel)
	_seta = Control.new()
	_seta.size = Vector2(26, 26)
	_seta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_seta.position = Vector2(round(_sprite_rect.get_center().x - 13.0),
		_hud_painel.position.y + hud_tam.y + 10.0)
	for bloco in [Rect2(10, 1, 6, 11), Rect2(4, 11, 18, 5),
			Rect2(7, 16, 12, 5), Rect2(10, 21, 6, 4)]:
		var pixel := ColorRect.new()
		pixel.position = bloco.position
		pixel.size = bloco.size
		pixel.color = Arte.BRANCO
		pixel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_seta.add_child(pixel)
	_seta.visible = false
	_seta.z_index = 22
	add_child(_seta)
	_seta_base = _seta.position
	move_child(_selecao, get_child_count() - 1)
	atualizar()
	# Entrada curta do HUD: 4 px na captura mobile e fade em 200 ms.
	var hud_y_final := _hud_painel.position.y
	_hud_painel.position.y += 8.0
	_hud_painel.modulate.a = 0.0
	var entrada := create_tween().set_parallel()
	entrada.tween_property(_hud_painel, "position:y", hud_y_final, 0.20) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	entrada.tween_property(_hud_painel, "modulate:a", 1.0, 0.20) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func centro_no_canvas() -> Vector2:
	return Unidades.ARENA + _sprite_rect.get_center()


func _ao_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		tocado.emit(indice)
	elif event is InputEventScreenTouch and event.pressed:
		tocado.emit(indice)


func definir_selecionado(valor: bool) -> void:
	var vivo := int(dados.hp) > 0
	_selecao.mouse_filter = Control.MOUSE_FILTER_STOP if vivo else Control.MOUSE_FILTER_IGNORE
	var mostrar := valor and vivo
	if _seta.visible == mostrar:
		return
	_seta.visible = mostrar
	_alvo_painel.visible = mostrar
	if _tween_seta != null:
		_tween_seta.kill()
		_tween_seta = null
	_seta.position = _seta_base
	_seta.modulate.a = 1.0
	if mostrar:
		_tween_seta = create_tween().set_loops()
		_tween_seta.tween_property(_seta, "position:y", _seta_base.y + 6.0, 0.38) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween_seta.parallel().tween_property(_seta, "modulate:a", 0.45, 0.38)
		_tween_seta.tween_property(_seta, "position:y", _seta_base.y, 0.38) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween_seta.parallel().tween_property(_seta, "modulate:a", 1.0, 0.38)


func atualizar() -> void:
	var fracao := clampf(float(dados.hp) / maxf(1.0, float(dados.hp_max)), 0.0, 1.0)
	var largura_alvo: float = round(_life_inicio + _life_largura * fracao)
	if _hp_anterior < 0.0:
		_life_clip.size.x = largura_alvo
	elif not is_equal_approx(_life_clip.size.x, largura_alvo):
		if _life_tween != null:
			_life_tween.kill()
		_life_tween = create_tween()
		_life_tween.tween_property(_life_clip, "size:x", largura_alvo, 0.42) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_hp_anterior = fracao
	var morto := int(dados.hp) <= 0
	if morto and not _morto:
		_morto = true
		# Cinza de morte na placa e no corpo, nunca no wrapper (ANIMACOES.md 4).
		_sprite.material = Arte.material_dessaturar(1.0)
		_sprite.modulate = Color.WHITE
	elif not morto and _morto:
		_morto = false
		_sprite.material = null
		_sprite.modulate = Color.WHITE
	_hud_painel.modulate = Color(0.45, 0.45, 0.45, 1.0) if morto else Color.WHITE
	if morto:
		_seta.visible = false
		_alvo_painel.visible = false
		_selecao.mouse_filter = Control.MOUSE_FILTER_IGNORE


func definir_turno(atual: int, maximo: int) -> void:
	var limite := mini(maximo, 5)
	var novo := clampi(atual, 0, limite)
	if novo == _turno_anterior:
		return
	_turno_anterior = novo
	_turno_atlas.region = Rect2(novo * 42, 0, 42, 48)
	if novo == 0:
		var t := create_tween()
		t.tween_property(_plate_arte, "modulate", Color("c9c0a8"), 0.06)
		t.tween_property(_plate_arte, "modulate", Color.WHITE, 0.06)


# Chip "TOTAL n" abaixo do HUD: o dano que a corrente vai somar neste alvo.
# So aparece durante a corrente; some ao zerar (spec/ENEMY_HUD.md).
func definir_total(n: int) -> void:
	if n <= 0:
		if _total_chip != null:
			_total_chip.visible = false
		return
	if _total_chip == null:
		_total_chip = Panel.new()
		_total_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_total_chip.z_index = 21
		_total_chip.position = Vector2(_hud_painel.position.x,
			_hud_painel.position.y + _hud_painel.size.y + 4.0)
		var est := StyleBoxFlat.new()
		est.bg_color = Color(0.035, 0.037, 0.047, 0.92)
		est.border_color = Color("c9c0a8")
		est.set_border_width_all(1)
		_total_chip.add_theme_stylebox_override("panel", est)
		add_child(_total_chip)
		_total_label = BitmapFontLabel.new()
		_total_label.glyph_height = 12
		_total_label.letter_spacing = 1
		_total_label.position = Vector2(5, 3)
		_total_chip.add_child(_total_label)
	_total_label.text = "TOTAL %d" % n
	_total_chip.size = _total_label.size + Vector2(10, 6)
	_total_chip.visible = true


func tremer(vivo := true) -> void:
	if not _tem_base:
		_base_pos = position
		_tem_base = true
	_hit_ms = Time.get_ticks_msec()
	_shake_amp = 6.0 if vivo else 2.0


func _process(delta: float) -> void:
	# Tremor por leitura de relogio, nao por tween: um golpe novo na cascata
	# nao reinicia animacao nenhuma (ANIMACOES.md secao 3).
	if _tem_base:
		var dt_ms := Time.get_ticks_msec() - _hit_ms
		if dt_ms < 300:
			var decay := 1.0 - float(dt_ms) / 300.0
			var p := float(dt_ms) / 34.0
			position = (_base_pos + Vector2(
				sin(p * 3.1) * _shake_amp * decay,
				cos(p * 4.7) * _shake_amp * 0.45 * decay)).round()
		elif position != _base_pos:
			position = _base_pos

	if _life_arte == null:
		return
	if _hp_anterior <= 0.0 or _hp_anterior > 0.25:
		_life_arte.modulate = Color.WHITE
		return
	_tempo_life_baixo += delta
	var fase := fmod(_tempo_life_baixo, 0.7) / 0.7
	var pulso := 0.5 - 0.5 * cos(fase * TAU)
	_life_arte.modulate = Color.WHITE.lerp(Color(1.35, 1.05, 1.0), pulso)


func _adicionar_arte_hud(textura: Texture2D, pos: Vector2, tamanho: Vector2,
		pai: Control) -> TextureRect:
	var arte := TextureRect.new()
	arte.position = pos
	arte.size = tamanho
	arte.texture = textura
	arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arte.stretch_mode = TextureRect.STRETCH_SCALE
	arte.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	arte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(arte)
	return arte


func inimigos_compactos() -> bool:
	return _slot.size.x <= Unidades.tamanho_logico(Vector2(63, 0)).x


func piscar() -> void:
	if _sprite.material == null:
		_sprite.material = Arte.material_inversor(0.0)
	var mat := _sprite.material as ShaderMaterial
	var t := create_tween()
	t.tween_method(func(v: float) -> void: mat.set_shader_parameter("quantidade", v),
		0.0, 1.0, DUR_FLASH / 2.0)
	t.tween_method(func(v: float) -> void: mat.set_shader_parameter("quantidade", v),
		1.0, 0.0, DUR_FLASH / 2.0)
	await t.finished
