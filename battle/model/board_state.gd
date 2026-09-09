class_name BoardState
extends RefCounted

const INITIAL_CARDS: Array[int] = [0, 1, 2, 3, 4, 6, 5, 0, 1, 2, 6, 3]
const INITIAL_BAG: Array[int] = [0, 1, 2, 3, 4, 6]
var cards: Array[int] = []
var bag: Array[int] = []
var rng := RandomNumberGenerator.new()

func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	cards.assign(INITIAL_CARDS)
	bag.assign(INITIAL_BAG)

func refill(indices: Array[int]) -> void:
	# Consome na ordem da seleção; a BAG é uma fila, não contagens.
	for index in indices:
		cards[index] = bag.pop_front()
		# Coringa menos frequente que os demais tipos.
		var roll := rng.randi_range(0, 12)
		bag.append(6 if roll == 12 else roll % 6)
