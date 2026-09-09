class_name BattleState
extends RefCounted

enum Phase { PLAYER_INPUT, RESOLVING, VICTORY, DEFEAT }
var phase: Phase = Phase.PLAYER_INPUT
var board: BoardState
var party_max_hp: int = 3200
var party_hp: int = 2840
var enemy_max_hp: Array[int] = [4000, 900, 1200]
var enemy_hp: Array[int] = [1850, 900, 1200]
var skill_charge: Array[int] = [75, 75, 75, 75, 75]
var leader_index: int = 0
var leader_turns_left: int = 0
var target: int = 0
var round_index: int = 3
var total_rounds: int = 3
var turn_index: int = 1
var selected: Array[int] = []

func _init(seed_value: int = 0) -> void:
	board = BoardState.new(seed_value)

func living_enemies() -> Array[int]:
	var result: Array[int] = []
	for i in enemy_hp.size():
		if enemy_hp[i] > 0:
			result.append(i)
	return result
