extends RefCounted
class_name Unidades

# Layout universal de novos modelos refeitos/battle_layout_pixel_spec.md.
# A especificacao usa um modulo logico 540x520; os presets abaixo sao
# convertidos para a arena atual sempre com coordenadas inteiras.

const ARENA := Vector2(26, 104)
const ARENA_TAM := Vector2(888, 829)
const MODULO_LOGICO := ARENA_TAM

const INIMIGOS := [
	{"chave": "eVoidLord", "elemento": "dark", "sprite": "characters_v4/enemy_stage_sword_v1.png",
		"hp_max": 10, "ataque": 15, "defesa": 14},
	{"chave": "eAbyssSerpent", "elemento": "dragon", "sprite": "characters_v4/enemy_stage_bow_v1.png",
		"hp_max": 9, "ataque": 13, "defesa": 10},
	{"chave": "eFlameGhost", "elemento": "light", "sprite": "characters_v4/enemy_stage_spear_v1.png",
		"hp_max": 8, "ataque": 12, "defesa": 8},
	{"chave": "eMechaScorpion", "elemento": "knight", "sprite": "characters_v4/enemy_knight_v1.png",
		"hp_max": 10, "ataque": 14, "defesa": 16},
	{"chave": "eMechaBeast", "elemento": "nature", "sprite": "characters_v4/enemy_nature_v1.png",
		"hp_max": 9, "ataque": 13, "defesa": 12},
]

const ALIADOS := [
	{"chave": "aDracoBrasa", "elemento": "dragon", "sprite": "characters_v2/lineup_v2_transparente.png",
		"recorte": Rect2(123, 152, 172, 194),
		"retrato": "characters_v4/ally_dragon_v1.png", "retrato_zoom": 1.25,
		"retrato_offset": Vector2(0, 8),
		"hp_max": 14, "ataque": 7, "defesa": 3},
	{"chave": "aGuardiaoFerro", "elemento": "knight", "sprite": "characters_v2/lineup_v2_transparente.png",
		"recorte": Rect2(442, 151, 179, 196),
		"retrato": "characters_v4/ally_knight_v1.png", "retrato_zoom": 1.25,
		"retrato_offset": Vector2(0, 8),
		"hp_max": 14, "ataque": 5, "defesa": 5},
	{"chave": "aMagaBosque", "elemento": "nature", "sprite": "characters_v2/lineup_v2_transparente.png",
		"recorte": Rect2(751, 157, 175, 190),
		"retrato": "characters_v4/ally_nature_v1.png", "retrato_zoom": 1.25,
		"retrato_offset": Vector2(0, 8),
		"hp_max": 12, "ataque": 6, "defesa": 3},
	{"chave": "aClerigaAstral", "elemento": "light", "sprite": "characters_v2/lineup_v2_transparente.png",
		"recorte": Rect2(1099, 158, 168, 188),
		"retrato": "characters_v4/ally_light_v1.png", "retrato_zoom": 1.25,
		"retrato_offset": Vector2(0, 8),
		"hp_max": 14, "ataque": 4, "defesa": 4},
	{"chave": "aOraculoChacal", "elemento": "dark", "sprite": "characters_v2/lineup_v2_transparente.png",
		"recorte": Rect2(1405, 142, 172, 202),
		"retrato": "characters_v4/ally_dark_v1.png", "retrato_zoom": 1.25,
		"retrato_offset": Vector2(0, 8),
		"hp_max": 16, "ataque": 6, "defesa": 3},
]

const ENEMY_PRESETS := {
	1: {"xs": [279], "slot_w": 330, "centros": [444], "bases": [443], "sprites": [330], "sprite": 330},
	2: {"xs": [138, 514], "slot_w": 236, "centros": [256, 632], "bases": [359, 359], "sprites": [236, 236], "sprite": 236},
	3: {"xs": [59, 349, 639], "slot_w": 190, "centros": [154, 444, 734], "bases": [271, 459, 271], "sprites": [190, 190, 190], "sprite": 190},
	4: {"xs": [34, 247, 460, 673], "slot_w": 180, "centros": [124, 337, 550, 763], "bases": [260, 415, 260, 415], "sprites": [180, 180, 180, 180], "sprite": 180},
	# Formação em profundidade para a arte real. O primeiro é o boss
	# central ao fundo; os demais ocupam laterais e linha avançada.
	5: {"xs": [49, 369, 689, 203, 535], "slot_w": 150,
		"centros": [124, 444, 764, 278, 610],
		"bases": [223, 223, 223, 427, 427],
		"sprites": [150, 150, 150, 150, 150], "sprite": 150},
}

const PLAYER_CENTROS := [45, 155, 270, 385, 495]
# Formação em W: pontas e centro recuados; intermediários avançados.
const PLAYER_BASES := [458, 490, 445, 490, 458]
const PLAYER_SPRITES := [82, 84, 80, 80, 84]
const PLAYER_XS := [2, 110, 224, 338, 446]

# Contrato universal de HUD: inimigos ancoram no retangulo final do sprite;
# aliados usam uma unica linha-base, independentemente da arte carregada.
const HUD_INIMIGO_GAP := 12.0
const HUD_ALIADO_Y_LOGICO := 496.0
const HUD_SKILL_ALIADO_TAM := Vector2(96, 96)

# Os aliados nao disputam mais espaco fisico com os inimigos. Cada um ocupa
# um Selo de Fragmento fixo na base da arena; assim a leitura permanece igual
# com um inimigo comum, cinco inimigos ou um boss enorme.
const SELO_ALIADO_TAM := Vector2(165, 165)
const SELO_ALIADO_GAP := 8.0
const SELO_ALIADO_Y := 607.0


static func escala() -> Vector2:
	return Vector2.ONE


static func ponto_logico(p: Vector2) -> Vector2:
	var e := escala()
	return Vector2(round(p.x * e.x), round(p.y * e.y))


static func tamanho_logico(p: Vector2) -> Vector2:
	return ponto_logico(p)


static func slot_inimigo(indice: int, total: int) -> Rect2:
	var qtd := clampi(total, 1, 5)
	var p: Dictionary = ENEMY_PRESETS[qtd]
	var xs: Array = p.xs
	return Rect2(ponto_logico(Vector2(float(xs[indice]), 108)),
		tamanho_logico(Vector2(float(p.slot_w), 184)))


static func preset_inimigo(total: int) -> Dictionary:
	return ENEMY_PRESETS[clampi(total, 1, 5)]


static func slot_aliado(indice: int) -> Rect2:
	return Rect2(ponto_logico(Vector2(float(PLAYER_XS[indice]), 365)),
		tamanho_logico(Vector2(93, 130)))


static func hud_inimigo(sprite_rect: Rect2) -> Rect2:
	# O HUD acompanha o inimigo sem dominar sua silhueta. Bosses ainda ganham
	# mais presença, mas a formação de cinco permanece arejada.
	var largura := 128.0 if sprite_rect.size.x <= 190.0 else 192.0
	var tamanho := Vector2(largura, largura * 144.0 / 384.0)
	return Rect2(Vector2(round(sprite_rect.get_center().x - tamanho.x / 2.0),
		round(sprite_rect.position.y - tamanho.y - HUD_INIMIGO_GAP)), tamanho)


static func y_hud_aliado() -> float:
	return ponto_logico(Vector2(0, HUD_ALIADO_Y_LOGICO)).y


static func hud_skill_aliado(sprite_rect: Rect2) -> Rect2:
	var pos := Vector2(sprite_rect.end.x - 30.0, sprite_rect.position.y - 28.0)
	pos.x = clampf(pos.x, 0.0, ARENA_TAM.x - HUD_SKILL_ALIADO_TAM.x)
	pos.y = clampf(pos.y, 0.0, ARENA_TAM.y - HUD_SKILL_ALIADO_TAM.y)
	return Rect2(Vector2(round(pos.x), round(pos.y)), HUD_SKILL_ALIADO_TAM)


static func selo_aliado(indice: int) -> Rect2:
	var largura_total: float = SELO_ALIADO_TAM.x * 5.0 + SELO_ALIADO_GAP * 4.0
	var x0: float = round((ARENA_TAM.x - largura_total) / 2.0)
	return Rect2(Vector2(x0 + float(indice) * (SELO_ALIADO_TAM.x + SELO_ALIADO_GAP),
		SELO_ALIADO_Y), SELO_ALIADO_TAM)


static func ajustar_no_box(tamanho_nativo: Vector2, box_maximo: Vector2) -> Vector2:
	var fator := minf(box_maximo.x / tamanho_nativo.x, box_maximo.y / tamanho_nativo.y)
	return Vector2(round(tamanho_nativo.x * fator), round(tamanho_nativo.y * fator))
