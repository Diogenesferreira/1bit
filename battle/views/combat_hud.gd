extends Control

func render(state: BattleState) -> void:
	$Fields/PartyHP.set_value("%d / %d" % [state.party_hp, state.party_max_hp])
	$Fields/PartyBar.set_state(state.party_hp, state.party_max_hp)
	var hp: int = state.enemy_hp[state.target]
	var maximum: int = state.enemy_max_hp[state.target]
	$Fields/EnemyHP.set_value("%d / %d" % [hp, maximum])
	$Fields/EnemyBar.set_state(hp, maximum)
	$Fields/Target.set_value("CHEFE HP" if state.target == 0 else "INIMIGO %d HP" % (state.target + 1))
	$Fields/Round.set_value("%d / %d" % [state.round_index, state.total_rounds])
