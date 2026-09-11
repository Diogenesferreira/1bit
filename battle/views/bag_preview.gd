extends Control

func render(board: BoardState, definitions: Array[CardDefinition]) -> void:
	for i in 6:
		$Cards.get_child(i).show_card(board.bag[i], definitions[board.bag[i]], board.bag_values[i])
