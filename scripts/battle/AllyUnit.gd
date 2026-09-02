extends Control
class_name AllyUnit

signal skill_clicada(indice: int)

var dados: Dictionary = {}
var indice := -1

var _card: PartyCard
var _skill_max := 8.0
var _skill_visual := 0.0
var _carga := 0


func montar(p_dados: Dictionary, p_indice := -1) -> void:
	dados = p_dados
	indice = p_indice
	var definition: Dictionary = dados.def
	var card_rect := Unidades.card_aliado(indice)
	position = card_rect.position
	size = card_rect.size
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_card = PartyCard.new()
	add_child(_card)
	_card.montar(String(definition.elemento), String(definition.get("nome", definition.chave)),
		int(definition.get("nivel", 1)), indice == 2, bool(definition.get("guest", false)))
	_card.skill_activated.connect(func() -> void: skill_clicada.emit(indice))
	_skill_visual = float(dados.get("skill", 0))
	atualizar()


func atualizar() -> void:
	_skill_max = maxf(1.0, float(dados.get("skill_max", 8)))
	var segments := ceili(clampf(_skill_visual / _skill_max, 0.0, 1.0) * 8.0) \
		if _skill_visual > 0.0 else 0
	_card.set_charge(segments)
	_card.set_disabled(int(dados.hp) <= 0)


func centro_no_canvas() -> Vector2:
	return Unidades.ARENA + position + _card.hero_center()


func adicionar_carga(incremento_skill: int) -> void:
	_carga += incremento_skill
	_skill_visual = minf(_skill_max, _skill_visual + float(incremento_skill))
	atualizar()


func definir_skill_visual(valor: float) -> void:
	_skill_visual = clampf(valor, 0.0, _skill_max)
	atualizar()


func limpar_carga() -> void:
	_carga = 0
	atualizar()


func tem_carga() -> bool:
	return _carga > 0


func piscar() -> void:
	await _card.piscar()
