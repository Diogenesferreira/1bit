extends RefCounted
class_name CardData

# Uma carta do tabuleiro de batalha.
# Cores de ataque + a carta marrom de cura (nao causa dano) + o
# CORINGA, que combina com qualquer cor.
enum Cor { VERMELHO, AZUL, VERDE, AMARELO, ROXO, CURA, CORINGA }

# Duas cartas podem entrar no mesmo trio? O coringa combina com tudo.
static func combina(a: int, b: int) -> bool:
	return a == b or a == Cor.CORINGA or b == Cor.CORINGA

var cor: int
var valor: int  # 1 a 9, como no jogo original

func _init(p_cor: int, p_valor: int) -> void:
	cor = p_cor
	valor = p_valor

# Sorteia uma carta nova: as 5 cores de ataque tem peso igual, a de
# cura e mais rara (2 em 19) e o coringa e o mais raro (1 em 19).
static func aleatoria(rng: RandomNumberGenerator) -> CardData:
	var sorteio := rng.randi_range(1, 19)
	var cor_sorteada: int
	if sorteio <= 15:
		cor_sorteada = (sorteio - 1) % 5
	elif sorteio <= 18:
		cor_sorteada = Cor.CURA
	else:
		cor_sorteada = Cor.CORINGA
	return CardData.new(cor_sorteada, rng.randi_range(1, 9))

static func nome_cor(p_cor: int) -> String:
	match p_cor:
		Cor.VERMELHO: return "Fogo"
		Cor.AZUL: return "Agua"
		Cor.VERDE: return "Natureza"
		Cor.AMARELO: return "Luz"
		Cor.ROXO: return "Trevas"
		Cor.CURA: return "Cura"
		Cor.CORINGA: return "Coringa"
	return "?"

static func cor_visual(p_cor: int) -> Color:
	match p_cor:
		Cor.VERMELHO: return Color("c0392b")
		Cor.AZUL: return Color("2a6fdb")
		Cor.VERDE: return Color("2e8b3d")
		Cor.AMARELO: return Color("e0c020")
		Cor.ROXO: return Color("6b2d8b")
		Cor.CURA: return Color("a08055")
		Cor.CORINGA: return Color("d8d8e8")
	return Color.GRAY
