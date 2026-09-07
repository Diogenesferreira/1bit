extends RefCounted
class_name LayoutBatalha

# Fonte unica de layout da tela de batalha, portada de
# `spec/layout_batalha.json` + `spec/LAYOUT_GERAL.md` (pacote do Designer 07/09).
#
# NUNCA digite numero de posicao/tamanho solto em BattleScreen: leia daqui.
# A tela e uma pilha vertical de 8 secoes com gap 14, dentro de uma coluna de
# conteudo de 888 px. Nada reflui, nada depende da largura da janela.

const CANVAS := Vector2(940, 1685)

# --- moldura -> coluna de conteudo -----------------------------------
const FRAME_OUTER_BORDER := 2
const FRAME_OUTER_PAD := 10
const FRAME_INNER_BORDER := 1
const FRAME_INNER_PAD := 14
# 2 + 10 + 1 + 14 = 27 da borda da janela ate o conteudo
const CONTENT_X := FRAME_OUTER_BORDER + FRAME_OUTER_PAD + FRAME_INNER_BORDER + FRAME_INNER_PAD
const CONTENT_W := 888
const SECTION_GAP := 14

# --- pilha vertical (alturas do JSON) -------------------------------
const H_TOP_BAR := 72
const H_STAGE := 560          # +1 de borda desenhada por fora
const H_PARTY_LABEL := 18
const H_PARTY_STRIP := 226
const H_BAG := 138
const H_HAND_LABEL := 34
const H_HAND_GRID := 394
const H_HP_ROW := 38

# Y de cada secao dentro da COLUNA DE CONTEUDO (origem 0), acumulando gap 14.
const Y_TOP_BAR := 0
const Y_STAGE := Y_TOP_BAR + H_TOP_BAR + SECTION_GAP                 # 86
const Y_PARTY_LABEL := Y_STAGE + H_STAGE + 1 + SECTION_GAP           # 661
const Y_PARTY_STRIP := Y_PARTY_LABEL + H_PARTY_LABEL + SECTION_GAP   # 693
const Y_BAG := Y_PARTY_STRIP + H_PARTY_STRIP + SECTION_GAP           # 933
const Y_HAND_LABEL := Y_BAG + H_BAG + SECTION_GAP                    # 1085
const Y_HAND_GRID := Y_HAND_LABEL + H_HAND_LABEL + SECTION_GAP       # 1133
const Y_HP_ROW := Y_HAND_GRID + H_HAND_GRID + SECTION_GAP            # 1541

# --- cores (paleta fechada de spec/PALETA.md) -----------------------
const C_WINDOW := Color("080908")
const C_PANEL := Color("0d0e0c")
const C_FIELD := Color("101210")
const C_STRIP := Color("121311")
const C_WELL := Color("121211")
const C_SLOT_BG := Color("0b0d0a")
const C_INK := Color("14140f")
const C_BONE := Color("c9c0a8")
const C_BONE_LIGHT := Color("e8e3d4")
const C_BONE_DIM := Color("8f886f")
const C_HP_BASE := Color("a8443a")
const C_HP_LIT := Color("d9705f")
const C_GOLD := Color("c9a842")
const C_FLASH := Color("f4ecd8")
const C_FRAME_OUT := Color("2b2b28")

# --- palco ---------------------------------------------------------
const STAGE_SIZE := Vector2i(888, 560)
const BACKDROP_NATIVE := Vector2i(222, 140)
const BACKDROP_SCALE := 4
const STAGE_CORNER_TICK := 16
const STAGE_CORNER_THICK := 2
const STAGE_CORNER_INSET := 6

# --- carta -------------------------------------------------------
const CARD_NATIVE := Vector2i(78, 108)
const CARD_BAG := Vector2i(78, 108)
const CARD_HAND := Vector2i(138, 191)
const HAND_COLS := 6
const HAND_ROWS := 2
const HAND_GAP := 12
# ordem de desenho das 12 casas: coluna 6 de cada fileira = ENTRADA (10, 11)
const HAND_GRID_ORDER := [0, 1, 2, 3, 4, 10, 5, 6, 7, 8, 9, 11]
const HAND_SELECT_LIFT := 14

# --- placa de inimigo: derivada do fator k (so 4 ou 6) -----------
static func plate_size(k: int) -> Vector2i:
	return Vector2i(32 * k, 12 * k)

static func plate_digit_rect(k: int) -> Rect2i:
	return Rect2i(int(round(11.5 * k)), k, int(round(3.5 * k)), 4 * k)

static func plate_label_rect(k: int) -> Rect2i:
	return Rect2i(int(round(15.5 * k)), k, 12 * k, 4 * k)

const PLATE_SPRITE_GAP := 7

# --- formacoes: cx = centro da placa, y = topo, dentro do palco ---
const FORMATIONS := {
	1: {"k": 6, "sprite": 330, "list": [
		{"cx": 444, "y": 34, "el": "dragon", "turn": 1}]},
	2: {"k": 6, "sprite": 236, "list": [
		{"cx": 256, "y": 44, "el": "nature", "turn": 2},
		{"cx": 632, "y": 44, "el": "dark", "turn": 1}]},
	3: {"k": 4, "sprite": 190, "list": [
		{"cx": 154, "y": 26, "el": "nature", "turn": 2},
		{"cx": 444, "y": 214, "el": "dark", "turn": 3},
		{"cx": 734, "y": 26, "el": "knight", "turn": 1}]},
	5: {"k": 4, "sprite": 150, "list": [
		{"cx": 124, "y": 18, "el": "nature", "turn": 2},
		{"cx": 444, "y": 18, "el": "dark", "turn": 1},
		{"cx": 764, "y": 18, "el": "light", "turn": 3},
		{"cx": 278, "y": 272, "el": "knight", "turn": 2},
		{"cx": 610, "y": 272, "el": "dragon", "turn": 1}]},
}

static func formacao(qtd: int) -> Dictionary:
	return FORMATIONS.get(clampi(qtd, 1, 5), FORMATIONS[3])

# --- party card (espaco PARTY_CARD, 152x188) --------------------
const PARTY_CARD := Vector2i(152, 188)
const PARTY_CARD_GAP := 16
const PARTY_STRIP_PAD_TOP := 22
const PARTY_ART_BASELINE := 136
# tamanho de desenho do heroi por elemento (tabelado, nunca multiplicador)
const CHAR_DRAW := {
	"dragon": Vector2i(114, 108), "knight": Vector2i(88, 116),
	"nature": Vector2i(112, 108), "light": Vector2i(108, 112),
	"dark": Vector2i(104, 108), "heal": Vector2i(96, 108),
}
const LEADER_MARK := 14

# --- 5 cards do party centralizados na coluna de conteudo -------
static func party_card_x(indice: int) -> int:
	var total := 5 * PARTY_CARD.x + 4 * PARTY_CARD_GAP
	var x0 := int(round((CONTENT_W - total) / 2.0))
	return x0 + indice * (PARTY_CARD.x + PARTY_CARD_GAP)

# --- grade da mao: 6 col x 2 lin de 138x191, gap 12, centralizada ---
static func hand_cell_pos(coluna: int, linha: int) -> Vector2:
	var total_w := HAND_COLS * CARD_HAND.x + (HAND_COLS - 1) * HAND_GAP
	var x0 := round((CONTENT_W - total_w) / 2.0)
	return Vector2(x0 + coluna * (CARD_HAND.x + HAND_GAP),
		linha * (CARD_HAND.y + HAND_GAP))

# slot -> (coluna, linha) na grade de 6x2
static func hand_slot_grid(slot: int) -> Vector2i:
	var pos := HAND_GRID_ORDER.find(slot)
	if pos < 0:
		pos = slot
	return Vector2i(pos % HAND_COLS, pos / HAND_COLS)

# --- BAG: 8 cartas 78x108 + divisor + NEXT ---------------------
const BAG_CARDS := 8
const BAG_PAD_X := 16
const BAG_PAD_TOP := 16

# --- tempos (s) ---------------------------------------------------
const T_SELECT := 0.12
const T_DEAL := 0.18
const T_DRAIN := 0.42
const T_TURN := 0.42
const T_FLASH := 0.45
const T_STAGE_SWAP := 0.48
const T_BACKDROP_FADE := 0.6
