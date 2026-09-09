extends ArtSection
signal card_pressed(index: int)

func _ready() -> void:
	for slot in $Slots.get_children():
		slot.pressed.connect(func(): card_pressed.emit(slot.slot_index))

func render(state: BattleState, definitions: Array[CardDefinition]) -> void:
	for slot in $Slots.get_children():
		slot.show_card(state.board.cards[slot.slot_index], definitions[state.board.cards[slot.slot_index]])
		slot.disabled = state.phase != BattleState.Phase.PLAYER_INPUT
	update_selection(state.selected)

func update_selection(indices: Array[int]) -> void:
	for slot in $Slots.get_children():
		slot.set_selected(slot.slot_index in indices)

func show_message(message: String) -> void:
	set_text_patch("message", Rect2(391, 22, 610, 30), message, 17, Color("54c8ef"))
