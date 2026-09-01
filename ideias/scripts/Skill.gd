extends RefCounted
class_name Skill

var nome: String
var dano_base: int
var custo_mp: int

func _init(p_nome: String, p_dano: int, p_custo: int) -> void:
	nome = p_nome
	dano_base = p_dano
	custo_mp = p_custo
