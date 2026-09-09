extends ArtSection
var shown: Array[int] = [0, 1, 2, 3, 4, 6]

func render(board: BoardState, definitions: Array[CardDefinition]) -> void:
	for i in 6:
		if shown[i] != board.bag[i]:
			$Cards.get_child(i).texture = definitions[board.bag[i]].preview
	shown.assign(board.bag)
