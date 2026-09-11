class_name BattleState
extends RefCounted

enum Phase { PLAYER_INPUT, RESOLVING, VICTORY, DEFEAT }
var phase: Phase = Phase.PLAYER_INPUT
var board: BoardState
var party_max_hp: int = 3200
var party_hp: int = 2840
var enemy_max_hp: Array[int] = [4000, 1200, 1400]
var enemy_hp: Array[int] = [1850, 1200, 1400]
var enemy_defense: Array[int] = [18, 12, 12]
var enemy_attack: Array[int] = [220, 130, 150]
var enemy_countdowns: Array[int] = [2, 1, 3]
var enemy_countdown_max: Array[int] = [3, 3, 3]
var skill_charge: Array[int] = [75, 75, 75, 75, 75]
var leader_index: int = 0
var leader_active := false
var leader_turns_left: int = 0
var target: int = 0
var round_index: int = 3
var total_rounds: int = 3
var turn_index: int = 1
var selected: Array[int] = []
var enemy_countdown: int = 3
var available_elements: Array[bool] = [true, true, true, true, true]
var last_chain: Array[Dictionary] = []
var last_enemy_attacks: Array[Dictionary] = []

func _init(seed_value: int = 0) -> void:
	board = BoardState.new(seed_value)

func living_enemies() -> Array[int]:
	var result: Array[int] = []
	for i in enemy_hp.size():
		if enemy_hp[i] > 0:
			result.append(i)
	return result
