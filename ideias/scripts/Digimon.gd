extends RefCounted
class_name Digimon

# Dados base do Digimon
var nome: String
var nivel: int
var hp: int
var hp_max: int
var ataque: int
var defesa: int
var velocidade: int

# Skills
var skill_basico: Skill
var skill_especial: Skill

func _init(p_nome: String, p_nivel: int, p_hp: int, p_ataque: int, p_defesa: int, p_velocidade: int) -> void:
	nome = p_nome
	nivel = p_nivel
	hp = p_hp
	hp_max = p_hp
	ataque = p_ataque
	defesa = p_defesa
	velocidade = p_velocidade

func tomar_dano(dano: int) -> void:
	var dano_real: int = maxi(dano - defesa / 2, 1)
	hp = maxi(hp - dano_real, 0)
	print("%s tomou %d de dano! HP: %d/%d" % [nome, dano_real, hp, hp_max])

func atacar(alvo: Digimon) -> void:
	var dano: int = ataque + randi_range(-5, 5)
	print("%s atacou %s!" % [nome, alvo.nome])
	alvo.tomar_dano(dano)

func esta_vivo() -> bool:
	return hp > 0
