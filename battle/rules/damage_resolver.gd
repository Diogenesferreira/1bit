class_name DamageResolver
extends RefCounted

static func combo_power(cards: Array[int], indices: Array[int], definitions: Array[CardDefinition]) -> int:
	var total := 0
	for index in indices:
		total += definitions[cards[index]].power
	return total

static func apply_damage(state: BattleState, amount: int) -> void:
	# Dano excedente encadeia para o próximo inimigo vivo.
	var remaining := maxi(0, amount)
	while remaining > 0 and not state.living_enemies().is_empty():
		if state.enemy_hp[state.target] <= 0:
			state.target = state.living_enemies()[0]
		var dealt := mini(remaining, state.enemy_hp[state.target])
		state.enemy_hp[state.target] -= dealt
		remaining -= dealt
