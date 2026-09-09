class_name MatchResolver
extends RefCounted

static func resolve(cards: Array[int], indices: Array[int], leader_element: int = 0) -> Dictionary:
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
	if element == CardDefinition.Kind.CAPSULE:
		for index in indices:
			if cards[index] != CardDefinition.Kind.CAPSULE:
				return {"valid": false}
	if element == -1:
		element = leader_element
	return {"valid": true, "element": element}

static func available_match(cards: Array[int]) -> Array[int]:
	for a in range(cards.size() - 2):
		for b in range(a + 1, cards.size() - 1):
			for c in range(b + 1, cards.size()):
				var indices: Array[int] = [a, b, c]
				if resolve(cards, indices).get("valid", false):
					return indices
	return []
