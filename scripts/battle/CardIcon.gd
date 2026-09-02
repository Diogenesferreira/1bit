extends Control
class_name CardIcon

# Face final das cartas. O mesmo PNG 78x108 e usado a 1x na BAG/NEXT e
# exatamente 2x na mao, conforme spec/ASSETS.md.

const DUR_CARD_IN := 0.18
const DUR_SELECAO := 0.17
const SUBIDA_SELECAO := 10.0

var tipo := ""
var valor := 0
var _caixa := Vector2(78, 108)
var _wiggle := false
var _selecionada := false
var _base := Vector2.ZERO
var _tempo := 0.0
var _face: TextureRect
var _numero: TextureRect
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
	_numero_atlas = AtlasTexture.new()
	_numero_atlas.atlas = Arte.tex("ui_v10/enemy/enemy_digits_sheet_v1.png")
	_numero_atlas.region = Rect2(0, 0, 42, 48)
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
			_numero.position = Vector2(7, 7)
			_numero.size = Vector2(10.5, 12)
		_aplicar_rim()
	set_process(_wiggle or _selecionada)


func mostrar(p_tipo: String, p_valor: int, animar := true) -> void:
	tipo = p_tipo
	valor = p_valor
	_face.texture = Arte.card_face(tipo)
	_face.visible = true
	_numero_atlas.region = Rect2(clampi(valor, 0, 9) * 42, 0, 42, 48)
	_numero.visible = valor > 0
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
		_rim.visible = false


func vazio() -> bool:
	return tipo == ""


func definir_selecionada(v: bool) -> void:
	_selecionada = v
	_aplicar_rim()
	if _tween_selecao != null and _tween_selecao.is_valid():
		_tween_selecao.kill()
	z_index = 12 if v else 0
	_face.modulate = Color(1.05, 1.05, 1.05, 1.0) if v else Color.WHITE
	_tween_selecao = create_tween().set_parallel()
	_tween_selecao.tween_property(self, "position",
		_base + Vector2(0, -SUBIDA_SELECAO) if v else _base, DUR_SELECAO) \
		.set_trans(Tween.TRANS_BACK if v else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	set_process(_wiggle or _selecionada)


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
