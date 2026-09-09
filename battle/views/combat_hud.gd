extends ArtSection
var shown_party := 2840
var shown_enemy := 1850
var shown_max := 4000
var shown_target := 0
var shown_round := 3

func render(state: BattleState) -> void:
	if state.party_hp != shown_party:
		set_text_patch("party_value", Rect2(281, 44, 133, 24), "%d / %d" % [state.party_hp, state.party_max_hp], 20)
		set_bar_patch("party_bar", Rect2(88, 47, 186, 14), float(state.party_hp) / state.party_max_hp, Color("21d534"))
		shown_party = state.party_hp
	var hp: int = state.enemy_hp[state.target]
	var maximum: int = state.enemy_max_hp[state.target]
	if hp != shown_enemy or maximum != shown_max:
		set_text_patch("enemy_value", Rect2(807, 44, 147, 24), "%d / %d" % [hp, maximum], 20)
		set_bar_patch("enemy_bar", Rect2(646, 47, 155, 14), float(hp) / maximum, Color("ed2438"))
		shown_enemy = hp
		shown_max = maximum
	if state.target != shown_target:
		set_text_patch("target", Rect2(646, 15, 163, 25), "CHEFE HP" if state.target == 0 else "INIMIGO %d HP" % (state.target + 1), 19, Color("ff4562"))
		shown_target = state.target
	if state.round_index != shown_round:
		set_text_patch("round", Rect2(464, 37, 109, 39), "%d / %d" % [state.round_index, state.total_rounds], 30)
		shown_round = state.round_index
