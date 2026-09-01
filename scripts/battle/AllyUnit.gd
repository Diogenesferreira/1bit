extends Control
class_name AllyUnit

signal skill_clicada(indice: int)

const DUR_FLASH := 0.22

var dados: Dictionary = {}
var indice := -1

var _sprite: Polygon2D
var _sprite_rect := Rect2()
var _medidor: SkillGauge
var _skill_max := 8.0
var _skill_visual := 0.0
var _carga_painel: Panel
var _carga_txt: Label
var _carga := 0
var _selo: Panel


func montar(p_dados: Dictionary, p_indice := -1) -> void:
	dados = p_dados
	indice = p_indice
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var d: Dictionary = dados.def

	var selo_rect := Unidades.selo_aliado(indice)
	position = selo_rect.position + (Vector2(0, -16) if indice == 2 else Vector2.ZERO)
	size = selo_rect.size
	_selo = Panel.new()
	_selo.size = size
	_selo.clip_contents = false
	_selo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo_selo := StyleBoxFlat.new()
	estilo_selo.bg_color = Color(0, 0, 0, 0)
	_selo.add_theme_stylebox_override("panel", estilo_selo)
	add_child(_selo)

	# O retrato usa a abertura em arco oficial. O mesmo componente poderá ser
	# reutilizado no menu sem criar uma segunda versão da moldura.
	var textura: Texture2D
	if d.has("retrato"):
		textura = Arte.tex_recortada(String(d.retrato), d.retrato_recorte as Rect2) \
			if d.has("retrato_recorte") else Arte.tex(String(d.retrato))
	else:
		textura = Arte.tex_recortada(String(d.sprite), d.recorte as Rect2) \
			if d.has("recorte") else Arte.tex(String(d.sprite))
	var deslocamento: Vector2 = d.get("retrato_offset", Vector2.ZERO)
	var retrato := FragmentPortrait.new()
	retrato.size = size
	_selo.add_child(retrato)
	retrato.montar(String(d.elemento), textura,
		float(d.get("retrato_zoom", 1.0)), deslocamento)
	_sprite = retrato.portrait
	_sprite_rect = retrato.portrait_rect

	# A folha oficial possui nove quadros alinhados: 0/8 ate 8/8.
	_medidor = SkillGauge.new()
	_medidor.position = Vector2.ZERO
	_medidor.z_index = 20
	add_child(_medidor)
	_medidor.montar(String(d.elemento), size, false, false, false,
		Arte.selo_v6_charge(String(d.elemento)))
	_medidor.ativada.connect(func() -> void: skill_clicada.emit(indice))
	_skill_visual = float(dados.get("skill", 0))

	# Feedback temporario da energia; o arco representa a carga persistente.
	_carga_painel = Panel.new()
	_carga_painel.position = Vector2(32, -30)
	_carga_painel.size = Vector2(100, 31)
	_carga_painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_carga_painel.z_index = 30
	var carga_estilo := StyleBoxFlat.new()
	carga_estilo.bg_color = Arte.ESCURO
	carga_estilo.border_color = Arte.BRANCO
	carga_estilo.set_border_width_all(2)
	carga_estilo.set_corner_radius_all(3)
	_carga_painel.add_theme_stylebox_override("panel", carga_estilo)
	add_child(_carga_painel)
	_carga_txt = Arte.rotulo("", Vector2(0, 4), 11, Arte.TEXTO_NO_ESCURO,
		_carga_painel.size.x, true, _carga_painel)
	_carga_painel.visible = false
	atualizar()


func atualizar() -> void:
	_skill_max = maxf(1.0, float(dados.get("skill_max", 8)))
	_medidor.atualizar(_skill_visual, _skill_max)
	_sprite.modulate.a = 0.12 if int(dados.hp) <= 0 else 1.0
	_medidor.modulate.a = 0.18 if int(dados.hp) <= 0 else 1.0


func centro_no_canvas() -> Vector2:
	return Unidades.ARENA + position + _sprite_rect.get_center()


func adicionar_carga(incremento_skill: int) -> void:
	_carga += incremento_skill
	_skill_visual = minf(_skill_max, _skill_visual + float(incremento_skill))
	atualizar()
	_carga_txt.text = "+%d" % _carga
	# A carga persistente ja aparece nos oito encaixes. O total de dano usa o
	# balao manga da corrente, portanto este painel auxiliar fica oculto.
	_carga_painel.visible = false
	_carga_painel.scale = Vector2(0.72, 0.72)
	_carga_painel.pivot_offset = _carga_painel.size / 2.0
	create_tween().tween_property(_carga_painel, "scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func definir_skill_visual(valor: float) -> void:
	_skill_visual = clampf(valor, 0.0, _skill_max)
	atualizar()


func limpar_carga() -> void:
	_carga = 0
	_carga_painel.visible = false
	atualizar()


func tem_carga() -> bool:
	return _carga > 0


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
