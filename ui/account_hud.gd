extends Control

func _ready() -> void:
	PlayerProfile.changed.connect(render)
	render()

func render() -> void:
	$Fields/PlayerName.set_value(PlayerProfile.player_name)
	$Fields/Level.set_value(str(PlayerProfile.level))
	$Fields/XPValue.set_value("%d / %d" % [PlayerProfile.xp, PlayerProfile.xp_max])
	$Fields/XPBar.set_state(PlayerProfile.xp, PlayerProfile.xp_max)
	$Fields/Money.set_value(str(PlayerProfile.money))
	$Fields/Tickets.set_value(str(PlayerProfile.tickets))
	$Fields/Energy.set_value("%d/%d" % [PlayerProfile.energy, PlayerProfile.energy_max])
	$Fields/EnergyBar.set_state(PlayerProfile.energy, PlayerProfile.energy_max)
