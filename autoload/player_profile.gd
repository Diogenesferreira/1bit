extends Node
## Persistência da conta; o combate mantém seu próprio estado.
signal changed

var player_name: String = "JINSA"
var level: int = 38
var xp: int = 6120
var xp_max: int = 12000
var money: int = 154200
var tickets: int = 50
var energy: int = 92
var energy_max: int = 100

func to_dictionary() -> Dictionary:
	return {"player_name": player_name, "level": level, "xp": xp,
		"money": money, "tickets": tickets, "energy": energy}

func restore(data: Dictionary) -> void:
	player_name = str(data.get("player_name", "JINSA")).left(16)
	level = clampi(int(data.get("level", 38)), 1, 999)
	xp = clampi(int(data.get("xp", 6120)), 0, xp_max)
	money = maxi(0, int(data.get("money", 154200)))
	tickets = maxi(0, int(data.get("tickets", 50)))
	energy = clampi(int(data.get("energy", 92)), 0, energy_max)
	changed.emit()

func award_victory() -> void:
	money += 250
	xp += 120
	if xp >= xp_max:
		xp -= xp_max
		level += 1
	changed.emit()
