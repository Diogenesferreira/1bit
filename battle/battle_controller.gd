class_name BattleController
extends Node

signal state_changed
signal selection_changed
signal message_changed(message: String)
signal battle_finished(won: bool)

const CARD_PATHS := ["dragon", "knight", "nature", "light", "dark", "capsule", "wild"]
var definitions: Array[CardDefinition] = []
var stage: StageDefinition = preload("res://data/stages/ilha_digital.tres")
var state := BattleState.new()
var _generation: int = 0

func _ready() -> void:
	for card_name in CARD_PATHS:
		definitions.append(load("res://data/cards/%s.tres" % card_name))
	state.party_max_hp = _party_max_hp()
	state.party_hp = mini(state.party_hp, state.party_max_hp)
	state.total_rounds = stage.total_rounds
	if not stage.enemies.is_empty():
		state.enemy_max_hp.clear()
		for enemy in stage.enemies:
			state.enemy_max_hp.append(enemy.max_hp)

func _party_max_hp() -> int:
	var total := 0
	for ally in stage.allies:
		total += ally.max_hp
	return clampi(total if total > 0 else 3200, 1, stage.hp_cap)

func select_card(index: int) -> void:
	if state.phase != BattleState.Phase.PLAYER_INPUT or index < 0 or index >= 12:
		return
	if index in state.selected:
		state.selected.erase(index)
	else:
		state.selected.append(index)
	selection_changed.emit()
	if state.selected.size() == 3:
		var result := MatchResolver.resolve(state.board.cards, state.selected, state.leader_index)
		if not result.get("valid", false):
			state.selected.clear()
			selection_changed.emit()
			message_changed.emit("COMBINE 3 DO MESMO ELEMENTO")
			return
		state.phase = BattleState.Phase.RESOLVING
		var generation := _generation
		await get_tree().create_timer(0.12).timeout
		if generation != _generation:
			return
		resolve_selected()

func resolve_selected() -> void:
	var result := MatchResolver.resolve(state.board.cards, state.selected, state.leader_index)
	if not result.get("valid", false):
		return
	var element: int = result["element"]
	var power := DamageResolver.combo_power(state.board.cards, state.selected, definitions)
	if element == CardDefinition.Kind.CAPSULE:
		var healing := mini(power * stage.heal_per_power, state.party_max_hp - state.party_hp)
		state.party_hp += healing
		message_changed.emit("CAPSULE  +%d HP" % healing)
	else:
		var damage := power * stage.damage_per_power
		DamageResolver.apply_damage(state, damage)
		state.skill_charge[element] = mini(stage.skill_threshold, state.skill_charge[element] + stage.skill_gain)
		message_changed.emit("%s  −%d HP" % [definitions[element].display_name.to_upper(), damage])
	state.board.refill(state.selected)
	state.selected.clear()
	selection_changed.emit()
	_finish_turn()

func _finish_turn() -> void:
	state.selected.clear()
	selection_changed.emit()
	state.turn_index += 1
	state.leader_turns_left = maxi(0, state.leader_turns_left - 1)
	if state.living_enemies().is_empty():
		if state.round_index >= state.total_rounds:
			_end_battle(true)
			return
		state.round_index += 1
		state.enemy_max_hp.assign([4000, 900, 1200] if state.round_index == state.total_rounds else [1400, 700, 900])
		state.enemy_hp.assign(state.enemy_max_hp)
		state.target = 0
		message_changed.emit("ROUND %d/%d" % [state.round_index, state.total_rounds])
	else:
		state.party_hp = maxi(0, state.party_hp - stage.enemy_attack * state.living_enemies().size())
		if state.party_hp == 0:
			_end_battle(false)
			return
		if state.enemy_hp[state.target] == 0:
			state.target = state.living_enemies()[0]
	state.phase = BattleState.Phase.PLAYER_INPUT
	_ensure_playable_board()
	state_changed.emit()

func _ensure_playable_board() -> void:
	# Com 12 cartas e estes 7 tipos, geralmente há trios; o fallback evita travas.
	if MatchResolver.available_match(state.board.cards).is_empty():
		state.board.cards[0] = CardDefinition.Kind.WILD
		state.board.cards[1] = CardDefinition.Kind.WILD
		state.board.cards[2] = CardDefinition.Kind.WILD

func select_target(index: int) -> void:
	if state.phase != BattleState.Phase.PLAYER_INPUT:
		return
	if index < 0 or index >= state.enemy_hp.size() or state.enemy_hp[index] <= 0:
		return
	state.target = index
	state_changed.emit()

func use_skill(index: int) -> void:
	if state.phase != BattleState.Phase.PLAYER_INPUT or index < 0 or index >= 5:
		return
	if state.skill_charge[index] < stage.skill_threshold:
		message_changed.emit("SKILL %d/%d — COMBINE CARTAS DO ELEMENTO" % [state.skill_charge[index], stage.skill_threshold])
		return
	state.skill_charge[index] = 0
	DamageResolver.apply_damage(state, 650)
	message_changed.emit("SKILL %s  −650 HP" % definitions[index].display_name.to_upper())
	_finish_turn()

func use_leader_skill() -> void:
	if state.phase != BattleState.Phase.PLAYER_INPUT:
		return
	if state.leader_turns_left > 0:
		message_changed.emit("LÍDER — AGUARDE %d TURNOS" % state.leader_turns_left)
		return
	state.leader_turns_left = stage.leader_cooldown + 1
	DamageResolver.apply_damage(state, 400)
	message_changed.emit("LIDERANÇA  −400 HP")
	_finish_turn()

func _end_battle(won: bool) -> void:
	state.phase = BattleState.Phase.VICTORY if won else BattleState.Phase.DEFEAT
	state_changed.emit()
	message_changed.emit("VITÓRIA — TOQUE EM FASES" if won else "DERROTA — TOQUE EM FASES")
	battle_finished.emit(won)

func restart(from_first_round: bool = true) -> void:
	_generation += 1
	state = BattleState.new()
	state.total_rounds = stage.total_rounds
	state.party_max_hp = _party_max_hp()
	if from_first_round:
		state.round_index = 1
		state.party_hp = state.party_max_hp
		state.enemy_max_hp.assign([1400, 700, 900])
		state.enemy_hp.assign(state.enemy_max_hp)
	state_changed.emit()
	selection_changed.emit()
	message_changed.emit("COMBINE CARTAS, LIBERE O PODER DOS SEUS MONSTROS!")
