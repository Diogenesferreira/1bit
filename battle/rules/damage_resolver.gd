class_name DamageResolver
extends RefCounted

static func combo_power(values: Array[int], indices: Array[int]) -> int:
	var total := 0
	for index in indices:
		total += values[index]
	return total

static func reduction_for_defense(defense: int) -> float:
	# O binario confirma reducao percentual, mas a tabela original ainda nao
	# foi recuperada. Esta curva provisoria e monotona e nunca anula o ataque.
	var safe_defense := maxi(0, defense)
	return clampf(float(safe_defense) / (float(safe_defense) + 100.0), 0.0, 0.80)

static func damage_after_defense(amount: int, defense: int) -> int:
	if amount <= 0:
		return 0
	return maxi(1, floori(amount * (1.0 - reduction_for_defense(defense))))

static func apply_damage(state: BattleState, amount: int) -> void:
	# Dano excedente encadeia para o próximo inimigo vivo.
	if state.living_enemies().is_empty():
		return
	if state.target < 0 or state.target >= state.enemy_hp.size() or state.enemy_hp[state.target] <= 0:
		state.target = state.living_enemies()[0]
	var defense := state.enemy_defense[state.target] if state.target < state.enemy_defense.size() else 0
	var remaining := damage_after_defense(amount, defense)
	while remaining > 0 and not state.living_enemies().is_empty():
		if state.enemy_hp[state.target] <= 0:
			state.target = state.living_enemies()[0]
		var dealt := mini(remaining, state.enemy_hp[state.target])
		state.enemy_hp[state.target] -= dealt
		remaining -= dealt
