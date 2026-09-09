extends ArtSection

func _ready() -> void:
	PlayerProfile.changed.connect(render)
	render()

func render() -> void:
	if PlayerProfile.money != 154200:
		set_text_patch("money", Rect2(597, 28, 102, 41), str(PlayerProfile.money), 24, Color("ffe362"))
	if PlayerProfile.xp != 6120:
		set_text_patch("xp", Rect2(323, 73, 174, 24), "%d / %d" % [PlayerProfile.xp, PlayerProfile.xp_max], 19, Color("9adcfb"))
		set_bar_patch("xp_bar", Rect2(251, 57, 227, 10), float(PlayerProfile.xp) / PlayerProfile.xp_max, Color("28b8f0"))
	if PlayerProfile.level != 38:
		set_text_patch("level", Rect2(181, 50, 63, 36), str(PlayerProfile.level), 27, Color("ffe362"))
