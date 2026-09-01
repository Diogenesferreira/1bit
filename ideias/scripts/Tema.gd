extends RefCounted
class_name Tema

# TEMA "DIGITAL ARENA" — o design entregue em 2026-08-26 pelo usuario
# (Design de game mobile.zip / novo_asset/design_mobile/entrega_godot/,
# UI_SPEC.md). Substitui o tema anterior ("copia fiel" azul-tecnologico
# do Digimon Heroes original): a partir de agora ESTE e a referencia
# visual do jogo. Os assets do tema antigo continuam no disco (nao
# apagados), so pararam de ser referenciados por codigo.
#
# Isto e APRESENTACAO. BattleLogic nao sabe que este arquivo existe.

enum Estilo { ORIGINAL }

static var atual: Estilo = Estilo.ORIGINAL

# CardData.Cor -> nome do arquivo. Os assets vieram nomeados por
# elemento (fire/water/nature/light/dark/stone/special); este e o unico
# lugar onde os dois vocabularios se encontram.
const ARQUIVO := {
	CardData.Cor.VERMELHO: "fire",
	CardData.Cor.AZUL: "water",
	CardData.Cor.VERDE: "nature",
	CardData.Cor.AMARELO: "light",
	CardData.Cor.ROXO: "dark",
	CardData.Cor.CURA: "stone",
	CardData.Cor.CORINGA: "special",
}

# Cor solida de cada elemento (UI_SPEC.md paragrafo 9).
const COR_ELEMENTO := {
	CardData.Cor.VERMELHO: Color("e0483c"),
	CardData.Cor.AZUL: Color("2f8fe0"),
	CardData.Cor.VERDE: Color("3f9d43"),
	CardData.Cor.AMARELO: Color("e8b400"),
	CardData.Cor.ROXO: Color("7b3fd1"),
	CardData.Cor.CURA: Color("b0b8c4"),      # pedra/cura nao tem cor solida no spec; cinza do glow
	CardData.Cor.CORINGA: Color("78dcff"),   # especial/coringa: cyan do glow
}

# Glow forte (rgba .95) e suave (rgba .7) de cada elemento.
const GLOW_FORTE := {
	CardData.Cor.VERMELHO: Color(1.0, 0.274, 0.176, 0.95),
	CardData.Cor.AZUL: Color(0.157, 0.588, 1.0, 0.95),
	CardData.Cor.VERDE: Color(0.235, 0.824, 0.294, 0.95),
	CardData.Cor.AMARELO: Color(1.0, 0.804, 0.196, 0.95),
	CardData.Cor.ROXO: Color(0.627, 0.274, 0.902, 0.95),
	CardData.Cor.CURA: Color(0.745, 0.776, 0.816, 0.95),
	CardData.Cor.CORINGA: Color(0.471, 0.863, 1.0, 0.95),
}

const GLOW_SUAVE := {
	CardData.Cor.VERMELHO: Color(1.0, 0.549, 0.235, 0.7),
	CardData.Cor.AZUL: Color(0.392, 0.784, 1.0, 0.7),
	CardData.Cor.VERDE: Color(0.471, 0.902, 0.471, 0.7),
	CardData.Cor.AMARELO: Color(1.0, 0.902, 0.471, 0.7),
	CardData.Cor.ROXO: Color(0.745, 0.471, 0.941, 0.7),
	CardData.Cor.CURA: Color(0.824, 0.847, 0.878, 0.7),
	CardData.Cor.CORINGA: Color(0.667, 0.922, 1.0, 0.7),
}

# Paleta de UI (UI_SPEC.md paragrafo 0).
const TEXTO_PRIMARIO := Color("1A2A44")
const TEXTO_SECUNDARIO := Color("8AA0B7")
const PAINEL := Color("F7F9FC")
const BORDA_PAINEL := Color("E6EBF2")
const BORDA_PAINEL_ALT := Color("DCE4EF")
const CYAN := Color("2f9fd8")
const FUNDO_PAGINA := Color("EEF2F7")
const VOID_TRILHO := Color("020a16")
const DANO_MAGENTA := Color("ff2f8f")
const VIDA_CHEIA := Color("39C86B")
const VIDA_BAIXA := Color("FF3B30")

static func nome() -> String:
	return "digital-arena"

# So existia para trocar entre temas antigos (classic/neo/original). So
# ha um tema agora; mantida sem efeito para nao quebrar quem ja chama.
static func alternar() -> void:
	pass

static func acento() -> Color:
	return CYAN

static func texto() -> Color:
	return TEXTO_PRIMARIO

static func texto_secundario() -> Color:
	return TEXTO_SECUNDARIO

static func texto_carta() -> Color:
	return Color.WHITE

# O elemento novo nao repete o valor espelhado no rodape (a arte ja e
# outra composicao, sem o "de qualquer fileira" do original).
static func numero_espelhado() -> bool:
	return false

static func rotulo(cor: int) -> String:
	return String(ARQUIVO[cor]).to_upper()

static func carta(cor: int) -> Texture2D:
	return load("res://assets/cartas/%s.png" % ARQUIVO[cor])

# Portrait do aliado (assets/personagens/, leva "design_mobile"). So
# existe para as 5 cores de ataque - cura e coringa nao tem aliado (ver
# [[decisoes-copia-fiel]]).
static func retrato_aliado(cor: int) -> Texture2D:
	return load("res://assets/personagens/%s.png" % ARQUIVO[cor])

static func cor_elemento(cor: int) -> Color:
	return COR_ELEMENTO[cor]

static func glow_forte(cor: int) -> Color:
	return GLOW_FORTE[cor]

static func glow_suave(cor: int) -> Color:
	return GLOW_SUAVE[cor]

# Icone pequeno do elemento (chip da AFFINITY, placa de HP do inimigo).
# So existe para as 5 cores de ataque.
static func icone_elemento(cor: int) -> Texture2D:
	return load("res://assets/ui/elemento_%s.png" % ARQUIVO[cor])

# Fundo da arena (deserto, leva "design_mobile"). Kuwagamon (o inimigo
# atual) nao tem elemento definido no codigo - mon_dark.png e escolha
# estetica, facil de trocar quando isso existir.
static func fundo_arena() -> Texture2D:
	return load("res://assets/bg/deserto.png")

static func sprite_inimigo() -> Texture2D:
	return load("res://assets/inimigos/mon_dark.png")

static func icone_avatar() -> Texture2D:
	return load("res://assets/ui/ic_avatar.png")

static func icone_moeda() -> Texture2D:
	return load("res://assets/ui/ic_coin.png")

static func icone_gema() -> Texture2D:
	return load("res://assets/ui/ic_gem.png")

static func icone_energia() -> Texture2D:
	return load("res://assets/ui/ic_bolt.png")

static func icone_menu() -> Texture2D:
	return load("res://assets/ui/ic_menu.png")

static func icone_coracao() -> Texture2D:
	return load("res://assets/ui/ic_heart.png")

# Tela de titulo (Main.gd) ainda nao tem mockup proprio nesta leva -
# reaproveita o fundo da arena pra nao quebrar.
static func cenario() -> Texture2D:
	return load("res://assets/bg/deserto.png")

# --- tipografia ---
#
# Orbitron (numerais/display, 700-900) e Rajdhani (labels de UI,
# 500-700), baixadas do Google Fonts (licenca OFL) em
# assets/fontes/. Orbitron e fonte variavel (eixo wght); Rajdhani vem em
# arquivos estaticos por peso. Cacheadas em static var pra nao recarregar
# do disco a cada Label.

static var _fonte_orbitron: FontFile
static var _fonte_rajdhani_medium: FontFile
static var _fonte_rajdhani_semibold: FontFile
static var _fonte_rajdhani_bold: FontFile

static func _carregar(caminho: String) -> FontFile:
	return load(caminho) as FontFile

# Numerais/display (HP, dano, valor da carta). peso 700 ou 900.
static func fonte_display(peso: int = 900) -> FontVariation:
	if _fonte_orbitron == null:
		_fonte_orbitron = _carregar("res://assets/fontes/Orbitron[wght].ttf")
	var variacao := FontVariation.new()
	variacao.base_font = _fonte_orbitron
	variacao.variation_opentype = {"wght": peso}
	return variacao

# Labels de UI (tags, status, rotulos). peso 500/600/700.
static func fonte_ui(peso: int = 600) -> FontFile:
	match peso:
		700:
			if _fonte_rajdhani_bold == null:
				_fonte_rajdhani_bold = _carregar("res://assets/fontes/Rajdhani-Bold.ttf")
			return _fonte_rajdhani_bold
		500:
			if _fonte_rajdhani_medium == null:
				_fonte_rajdhani_medium = _carregar("res://assets/fontes/Rajdhani-Medium.ttf")
			return _fonte_rajdhani_medium
		_:
			if _fonte_rajdhani_semibold == null:
				_fonte_rajdhani_semibold = _carregar("res://assets/fontes/Rajdhani-SemiBold.ttf")
			return _fonte_rajdhani_semibold
