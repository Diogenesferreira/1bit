class_name BoardState
extends RefCounted

const HAND := [0, 1, 2, 3, 4, 6, 7, 8, 9, 10]
const ENTRIES := [5, 11]
var cards: Array[int] = []
var values: Array[int] = []
var bag: Array[int] = []
var bag_values: Array[int] = []
var deck: Array[int] = []
var rng := RandomNumberGenerator.new()
var forced_openings := 0

func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	cards.resize(12)
	cards.fill(-1)
	values.resize(12)
	for i in 9:
		append_preview()
	complete_hand()

func append_preview() -> void:
	if deck.is_empty():
		deck.resize(100)
		deck.fill(-1)
		for kind in [6, 5]:
			var quantity := 8 if kind == 6 else 12
			for n in quantity:
				var start := int(n * 100.0 / quantity)
				var end := int((n + 1) * 100.0 / quantity) - 1
				var position := rng.randi_range(start, end)
				while deck[position] != -1:
					position = (position + 1) % 100
				deck[position] = kind
		var attacks: Array[int] = []
		for kind in 5:
			for n in 16:
				attacks.append(kind)
		for i in range(attacks.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp := attacks[i]
			attacks[i] = attacks[j]
			attacks[j] = tmp
		for i in 100:
			if deck[i] < 0:
				deck[i] = attacks.pop_back()
		# Repair attack runs without moving stratified wild/heal cards.
		for i in range(3, 100):
			if deck[i] == deck[i-1] and deck[i] == deck[i-2] and deck[i] == deck[i-3]:
				for j in range(i + 1, 99):
					if deck[j] < 5 and deck[j] != deck[i] and deck[j-1] != deck[i] and deck[j+1] != deck[i]:
						var tmp := deck[i]
						deck[i] = deck[j]
						deck[j] = tmp
						break
	bag.append(deck.pop_back())
	bag_values.append(rng.randi_range(1, 9))

func draw() -> Array[int]:
	var result: Array[int] = [bag.pop_front(), bag_values.pop_front()]
	append_preview()
	return result

func enter_from_bag(index: int) -> void:
	var card := draw()
	cards[index] = card[0]
	values[index] = card[1]

func complete_hand() -> void:
	for entry in ENTRIES:
		if cards[entry] < 0:
			continue
		for index in HAND:
			if cards[index] < 0:
				cards[index] = cards[entry]
				values[index] = values[entry]
				cards[entry] = -1
				break
	for index in HAND:
		if cards[index] < 0:
			enter_from_bag(index)
	ensure_playable()
	var ordered: Array = []
	for index in HAND:
		ordered.append([cards[index], values[index]])
	ordered.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	for i in HAND.size():
		cards[HAND[i]] = ordered[i][0]
		values[HAND[i]] = ordered[i][1]

func ensure_playable() -> void:
	if not MatchResolver.available_match(cards).is_empty():
		return
	var counts := [0, 0, 0, 0, 0, 0]
	for kind in cards:
		if kind >= 0 and kind < 6:
			counts[kind] += 1
	var target: int = counts.find(counts.max())
	var orphan := -1
	for index in HAND:
		if cards[index] >= 0 and cards[index] < 6 and cards[index] != target:
			if orphan == -1 or counts[cards[index]] < counts[cards[orphan]]:
				orphan = index
	if orphan >= 0:
		cards[orphan] = target
		forced_openings += 1

func snapshot() -> Dictionary:
	return {"cards": cards.duplicate(), "values": values.duplicate(), "bag": bag.duplicate(),
		"bag_values": bag_values.duplicate(), "deck": deck.duplicate(), "rng": rng.state}

func restore(data: Dictionary) -> void:
	cards.assign(data.cards)
	values.assign(data.values)
	bag.assign(data.bag)
	bag_values.assign(data.bag_values)
	deck.assign(data.deck)
	rng.state = data.rng
