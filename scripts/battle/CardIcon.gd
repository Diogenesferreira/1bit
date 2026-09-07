extends Control
class_name CardIcon

# Face final das cartas. O mesmo PNG 78x108 e usado a 1x na BAG/NEXT e
# exatamente 2x na mao, conforme spec/ASSETS.md.

const DUR_CARD_IN := 0.18
const DUR_SELECAO := 0.12
const SUBIDA_SELECAO := 14.0
const DUR_PULSO_SELECAO := 0.34

var tipo := ""
var valor := 0
var _caixa := Vector2(78, 108)
var _wiggle := false
var _selecionada := false
var _base := Vector2.ZERO
var _tempo := 0.0
var _face: TextureRect
var _numero: TextureRect
var _numero_bg: ColorRect
var _numero_atlas: AtlasTexture
var _rim: Panel
var _tween_selecao: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face = TextureRect.new()
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_SCALE
	_face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_face)
	_rim = Panel.new()
	_rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rim)
	# Folha dedicada do valor da carta (spec: digits_card_1x_v1, celula 19x21),
	# desenhada 1:1 na mao -> nitida. A antiga (enemy digits 42x48) reduzia e borrava.
	_numero_atlas = AtlasTexture.new()
	_numero_atlas.atlas = Arte.tex("ui_v11/ui/digits_card_1x_v1.png")
	_numero_atlas.region = Rect2(0, 0, 19, 21)
	_numero_atlas.filter_clip = true
	# Chapinha escura atras do numero: garante leitura em qualquer face de carta.
	_numero_bg = ColorRect.new()
	_numero_bg.color = Color(0.043, 0.047, 0.039, 0.62)
	_numero_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_numero_bg.z_index = 2
	add_child(_numero_bg)
	_numero = TextureRect.new()
	_numero.texture = _numero_atlas
	_numero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_numero.stretch_mode = TextureRect.STRETCH_SCALE
	_numero.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_numero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_numero)
	_numero.z_index = 3
	configurar(_caixa, 78.0)
	limpar()


func configurar(caixa: Vector2, _lado: float, _indice := 0, wiggle := false,
		_passo := 0.3, tam_num := 16) -> void:
	_caixa = caixa
	_wiggle = wiggle
	size = caixa
	pivot_offset = caixa / 2.0
	if _face != null:
		_face.size = caixa
		_rim.position = Vector2(-2, -2)
		_rim.size = caixa + Vector2(4, 4)
		if caixa.x >= 120:
			_numero.position = Vector2(12, 12)
			_numero.size = Vector2(19, 21)
		else:
			_numero.position = Vector2(6, 6)
			_numero.size = Vector2(11, 12)
		if _numero_bg != null:
			_numero_bg.position = _numero.position - Vector2(3, 2)
			_numero_bg.size = _numero.size + Vector2(6, 4)
		_aplicar_rim()
	set_process(_wiggle or _selecionada)


func mostrar(p_tipo: String, p_valor: int, animar := true) -> void:
	tipo = p_tipo
	valor = p_valor
	_face.texture = Arte.card_face(tipo)
	_face.visible = true
	_numero_atlas.region = Rect2(clampi(valor, 0, 9) * 19, 0, 19, 21)
	_numero.visible = valor > 0
	if _numero_bg != null:
		_numero_bg.visible = valor > 0
	_aplicar_rim()
	if animar:
		scale = Vector2(0.82, 0.82)
		modulate.a = 0.0
		var t := create_tween().set_parallel()
		t.tween_property(self, "scale", Vector2.ONE, DUR_CARD_IN) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(self, "modulate:a", 1.0, DUR_CARD_IN)
	else:
		scale = Vector2.ONE
		modulate.a = 1.0


func limpar() -> void:
	if _tween_selecao != null and _tween_selecao.is_valid():
		_tween_selecao.kill()
	tipo = ""
	valor = 0
	_selecionada = false
	position = _base
	scale = Vector2.ONE
	modulate = Color.WHITE
	z_index = 0
	if _face:
		_face.modulate = Color.WHITE
		_face.visible = false
		_numero.visible = false
		if _numero_bg != null:
			_numero_bg.visible = false
		_rim.visible = false


func vazio() -> bool:
	return tipo == ""


func definir_selecionada(v: bool) -> void:
	var virou := v and not _selecionada
	_selecionada = v
	_aplicar_rim()
	if _tween_selecao != null and _tween_selecao.is_valid():
		_tween_selecao.kill()
	z_index = 12 if v else 0
	_face.modulate = Color(1.14, 1.14, 1.14, 1.0) if v else Color.WHITE
	_tween_selecao = create_tween().set_parallel()
	_tween_selecao.tween_property(self, "position",
		_base + Vector2(0, -SUBIDA_SELECAO) if v else _base, DUR_SELECAO) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if virou:
		_pulso_selecao()
	set_process(_wiggle or _selecionada)


# Anel unico que abre e some no instante da selecao (ANIMACOES.md secao 5).
func _pulso_selecao() -> void:
	var anel := Panel.new()
	anel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anel.position = Vector2(-2, -2)
	anel.size = _caixa + Vector2(4, 4)
	anel.pivot_offset = anel.size / 2.0
	anel.z_index = 2
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0)
	estilo.border_color = Arte.cor_elemental_clara(tipo)
	estilo.set_border_width_all(2)
	anel.add_theme_stylebox_override("panel", estilo)
	add_child(anel)
	anel.modulate.a = 0.95
	var t := create_tween().set_parallel()
	t.tween_property(anel, "scale", Vector2(1.22, 1.22), DUR_PULSO_SELECAO) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(anel, "modulate:a", 0.0, DUR_PULSO_SELECAO) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await t.finished
	anel.queue_free()


func inverter_quantidade(v: float) -> void:
	modulate = Color.WHITE.lerp(Color(2.0, 2.0, 2.0, 1.0), clampf(v, 0.0, 1.0))


func fixar_em(p: Vector2) -> void:
	_base = p.round()
	position = _base


func _aplicar_rim() -> void:
	if _rim == null:
		return
	_rim.visible = _selecionada and not vazio()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0)
	var cor := Arte.cor_elemental(tipo).lerp(Color.WHITE, 0.34)
	estilo.border_color = cor
	estilo.set_border_width_all(4)
	_rim.add_theme_stylebox_override("panel", estilo)


func _process(delta: float) -> void:
	_tempo += delta
	if _selecionada:
		_rim.modulate.a = 0.88 + 0.12 * absf(sin(_tempo * 4.5))
	if _wiggle and not vazio():
		position = (_base + Vector2(0, round(sin(_tempo * 2.1)))).round()
