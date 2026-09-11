extends Control
signal card_pressed(index: int)

func _ready() -> void:
	for slot in $Slots.get_children():
		slot.pressed.connect(func(): card_pressed.emit(slot.slot_index))

func render(state: BattleState, definitions: Array[CardDefinition]) -> void:
	for slot in $Slots.get_children():
		var kind: int = state.board.cards[slot.slot_index]
		slot.visible = kind >= 0
		if kind < 0:
			continue
		slot.show_card(kind, definitions[kind], state.board.values[slot.slot_index])
		slot.disabled = state.phase != BattleState.Phase.PLAYER_INPUT
	update_selection(state.selected)

func update_selection(indices: Array[int]) -> void:
	for slot in $Slots.get_children():
		slot.set_selected(slot.slot_index in indices)

func show_message(message: String) -> void:
	$Fields/Message.set_value(message)
