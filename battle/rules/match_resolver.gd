class_name MatchResolver
extends RefCounted

static func resolve(cards: Array[int], indices: Array[int], _leader_element: int = 0) -> Dictionary:
	if indices.size() != 3:
		return {"valid": false}
	var seen: Array[int] = []
	var element := -1
	for index in indices:
		if index < 0 or index >= cards.size() or index in seen:
			return {"valid": false}
		seen.append(index)
		var kind: int = cards[index]
		if kind < 0 or kind > CardDefinition.Kind.WILD:
			return {"valid": false}
		if kind == CardDefinition.Kind.WILD:
			continue
		if element == -1:
			element = kind
		elif element != kind:
			return {"valid": false}
	if element == -1:
		element = CardDefinition.Kind.WILD
	return {"valid": true, "element": element}

static func available_match(cards: Array[int]) -> Array[int]:
	for a in range(cards.size() - 2):
		for b in range(a + 1, cards.size() - 1):
			for c in range(b + 1, cards.size()):
				var indices: Array[int] = [a, b, c]
				if resolve(cards, indices).get("valid", false):
					return indices
	return []

static func critical_score(kinds: Array[int], numbers: Array[int]) -> int:
	var counts := {}
	var wilds := 0
	for i in kinds.size():
		if kinds[i] == 6:
			wilds += 1
		else:
			counts[numbers[i]] = int(counts.get(numbers[i], 0)) + 1
	var score := 0
	for value: int in counts:
		if counts[value] + wilds >= 3:
			score = maxi(score, value * 10)
	var sorted := numbers.duplicate()
	sorted.sort()
	if sorted[0] == sorted[2]:
		score = maxi(score, sorted[0] * 10)
	if sorted[1] == sorted[0] + 1 and sorted[2] == sorted[1] + 1:
		score = maxi(score, sorted[1] * 3)
	return score

static func cascade(board: BoardState, available: Array[bool]) -> Array[int]:
	var kinds := board.cards.duplicate()
	var numbers := board.values.duplicate()
	kinds.append(board.bag[0])
	numbers.append(board.bag_values[0])
	var best: Array[int] = []
	var best_key: Array = []
	for a in 12:
		for b in range(a + 1, 12):
			for c in range(b + 1, 13):
				var trio: Array[int] = [a, b, c]
				var result := resolve(kinds, trio)
				if not result.valid:
					continue
				var element: int = result.element
				if element < 5 and not available[element]:
					continue
				var count := board.cards.count(element)
				var priority := 0 if count % 3 == 2 else (1 if count % 3 == 1 else 2)
				var trio_kinds: Array[int] = [kinds[a], kinds[b], kinds[c]]
				var trio_values: Array[int] = [numbers[a], numbers[b], numbers[c]]
				var score := critical_score(trio_kinds, trio_values)
				var hand_wilds := int(kinds[a] == 6) + int(kinds[b] == 6) + int(c < 12 and kinds[c] == 6)
				var key := [priority, -score, hand_wilds, element, c, b, a]
				if best.is_empty() or _less(key, best_key):
					best = trio
					best_key = key
	return best

static func _less(a: Array, b: Array) -> bool:
	for i in a.size():
		if a[i] != b[i]:
			return a[i] < b[i]
	return false
