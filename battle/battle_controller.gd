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
var _marks: Array[Dictionary] = []
var _undo: Array[Dictionary] = []
const CHAIN_BONUS := 0.3 # Project estimate, not recovered original balance.
const CRITICAL_MULTIPLIER := 1.5
const MAX_CHAIN := 100 # Safety guard, not the unconfirmed original limit of 31.

func _ready() -> void:
	for card_name in CARD_PATHS:
		definitions.append(load("res://data/cards/%s.tres" % card_name))
	state.party_max_hp = _party_max_hp()
	state.party_hp = mini(state.party_hp, state.party_max_hp)
	state.total_rounds = stage.total_rounds
	state.round_index = 1
	state.party_hp = state.party_max_hp
	if not stage.enemies.is_empty():
		state.enemy_max_hp.clear()
		for enemy in stage.enemies:
			state.enemy_max_hp.append(enemy.max_hp)
	state.enemy_max_hp.assign([1400, 700, 900])
	state.enemy_hp.assign(state.enemy_max_hp)
	state.enemy_defense.assign(stage.enemy_defense)

func _party_max_hp() -> int:
	var total := 0
	for ally in stage.allies:
		total += ally.max_hp
	return clampi(total if total > 0 else 3200, 1, stage.hp_cap)

func select_card(index: int) -> void:
	if state.phase != BattleState.Phase.PLAYER_INPUT or index < 0 or index >= 12:
		return
	if state.board.cards[index] < 0:
		return
	if index in state.selected:
		var before := _selection_snapshot()
		var pos := state.selected.find(index)
		var later := state.selected.slice(pos + 1)
		state.board.restore(_marks[pos])
		state.selected.resize(pos)
		_marks.resize(pos)
		# Replay independent later marks; a dependent entry disappears with its purchase.
		for remaining: int in later:
			if remaining in BoardState.HAND:
				_mark(remaining)
		_undo.append(before)
		_refresh_selection()
		return
	var color := -1
	for selected in state.selected:
		if state.board.cards[selected] != 6:
			color = state.board.cards[selected]
	var kind := state.board.cards[index]
	if color >= 0 and kind != 6 and kind != color:
		# Abandonment consumes a turn; no undo may recover spent enemy turns.
		cancel_selection()
		_finish_turn()
		if state.phase != BattleState.Phase.PLAYER_INPUT:
			return
		if state.board.cards[index] != kind:
			return
	_undo.append(_selection_snapshot())
	_mark(index)
	if state.selected.size() == 3:
		state.phase = BattleState.Phase.RESOLVING
		_undo.clear()
		_refresh_selection()
		var generation := _generation
		await get_tree().create_timer(0.12).timeout
		if generation != _generation:
			return
		resolve_selected()
	else:
		_refresh_selection()
		message_changed.emit("%d/3 CARTAS | INIMIGOS EM %d" % [state.selected.size(), state.enemy_countdown])

func _mark(index: int) -> void:
	_marks.append(state.board.snapshot())
	state.selected.append(index)
	if state.selected.size() >= 3:
		return
	var entries := [5, 11] if index < 6 else [11, 5]
	for entry: int in entries:
		if state.board.cards[entry] < 0:
			state.board.enter_from_bag(entry)
			break

func _refresh_selection() -> void:
	state_changed.emit()
	selection_changed.emit()

func _selection_snapshot() -> Dictionary:
	return {"board": state.board.snapshot(), "selected": state.selected.duplicate(), "marks": _marks.duplicate(true)}

func undo_selection() -> void:
	if state.phase != BattleState.Phase.PLAYER_INPUT or _undo.is_empty():
		return
	var snapshot: Dictionary = _undo.pop_back()
	state.board.restore(snapshot.board)
	state.selected.assign(snapshot.selected)
	_marks.assign(snapshot.marks)
	_refresh_selection()

func cancel_selection() -> void:
	if not _marks.is_empty():
		state.board.restore(_marks[0])
	_marks.clear()
	_undo.clear()
	state.selected.clear()

func load_test_hand() -> void:
	restart()
	state.board = BoardState.new(2026)
	state.board.cards.assign([0, 0, 0, 1, 1, -1, 1, 2, 3, 4, 5, -1])
	state.board.values.assign([4, 4, 4, 2, 3, 0, 4, 6, 9, 8, 5, 0])
	state.board.bag.assign([2, 3, 4, 5, 6, 0])
	state.board.bag_values.assign([6, 9, 8, 5, 7, 4])
	_refresh_selection()
	message_changed.emit("TESTE: TOQUE NOS 3 DRAGONS 4")

func resolve_selected() -> void:
	if state.phase != BattleState.Phase.RESOLVING or not MatchResolver.resolve(state.board.cards, state.selected).valid:
		return
	var generation := _generation
	var trio := state.selected.duplicate()
	state.last_chain.clear()
	var total_damage := 0
	var total_heal := 0
	var criticals := 0
	while not trio.is_empty() and state.last_chain.size() < MAX_CHAIN:
		var kinds: Array[int] = []
		var numbers: Array[int] = []
		for index in trio:
			if index == 12:
				var drawn := state.board.draw()
				kinds.append(drawn[0])
				numbers.append(drawn[1])
			else:
				kinds.append(state.board.cards[index])
				numbers.append(state.board.values[index])
				state.board.cards[index] = -1
		var element: int = MatchResolver.resolve(kinds, [0, 1, 2]).element
		var critical := MatchResolver.critical_score(kinds, numbers) > 0
		var power := numbers[0] + numbers[1] + numbers[2]
		var multiplier := (1.0 + CHAIN_BONUS * state.last_chain.size()) * (CRITICAL_MULTIPLIER if critical else 1.0)
		var damage := 0
		var heal := 0
		if element == 5:
			heal = roundi(power * stage.heal_per_power * (CRITICAL_MULTIPLIER if critical else 1.0))
		else:
			for ally in stage.allies:
				if state.available_elements[ally.element] and (element == 6 or ally.element == element):
					damage += roundi(power * stage.damage_per_power * multiplier)
					state.skill_charge[ally.element] = mini(stage.skill_threshold, state.skill_charge[ally.element] + stage.skill_gain)
		total_damage += damage
		total_heal += heal
		criticals += int(critical)
		state.last_chain.append({"element": element, "values": numbers, "critical": critical, "damage": damage, "heal": heal})
		state.selected.clear()
		state_changed.emit()
		message_changed.emit("CHAIN %d %s | +%d DANO" % [state.last_chain.size(), "CRITICO" if critical else "", damage])
		await get_tree().create_timer(0.3).timeout
		if generation != _generation:
			return
		if 12 - state.board.cards.count(-1) <= 1:
			state.board.cards.fill(-1)
			state.board.complete_hand()
		trio = MatchResolver.cascade(state.board, state.available_elements)
	state.board.complete_hand()
	DamageResolver.apply_damage(state, total_damage)
	var actual_heal := mini(total_heal, state.party_max_hp - state.party_hp)
	state.party_hp += actual_heal
	state.selected.clear()
	_marks.clear()
	_undo.clear()
	_finish_turn()
	if state.phase == BattleState.Phase.PLAYER_INPUT:
		message_changed.emit("CHAIN %d | %d CRIT | -%d / +%d HP | INIMIGO %d" % [state.last_chain.size(), criticals, total_damage, actual_heal, state.enemy_countdown])

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
		state.enemy_defense.assign(stage.enemy_defense)
		state.target = 0
		state.enemy_countdown = 3
		message_changed.emit("ROUND %d/%d" % [state.round_index, state.total_rounds])
	else:
		state.enemy_countdown -= 1
		if state.enemy_countdown <= 0:
			state.party_hp = maxi(0, state.party_hp - stage.enemy_attack * state.living_enemies().size())
			state.enemy_countdown = 3
		if state.party_hp == 0:
			_end_battle(false)
			return
		if state.enemy_hp[state.target] == 0:
			state.target = state.living_enemies()[0]
	state.phase = BattleState.Phase.PLAYER_INPUT
	_ensure_playable_board()
	state_changed.emit()

func _ensure_playable_board() -> void:
	state.board.ensure_playable()

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
	cancel_selection()
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
	cancel_selection()
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
	_marks.clear()
	_undo.clear()
	state = BattleState.new()
	state.total_rounds = stage.total_rounds
	state.party_max_hp = _party_max_hp()
	if from_first_round:
		state.round_index = 1
		state.party_hp = state.party_max_hp
		state.enemy_max_hp.assign([1400, 700, 900])
		state.enemy_hp.assign(state.enemy_max_hp)
		state.enemy_defense.assign(stage.enemy_defense)
	state_changed.emit()
	selection_changed.emit()
	message_changed.emit("COMBINE CARTAS, LIBERE O PODER DOS SEUS MONSTROS!")
