class_name TerminalScreen
extends Control

const KIT := "res://design/ilha-digital-godot-kit/"
const CREAM := Color("f5efe2")
const AMBER := Color("f2a33c")
const MINT := Color("6fe3b8")
const DANGER := Color("ff6b4a")
const CARD_NAMES := ["dragon", "knight", "nature", "light", "dark", "wild", "capsule", "dragon", "knight", "nature", "wild", "light"]
const CARD_VALUES := [4, 7, 6, 9, 8, 10, 5, 4, 7, 6, 10, 9]
const CARD_X := [24.0, 188.7, 353.3, 518.0, 682.7, 847.3]
const CHARACTERS := {
	"A1": ["assets/characters/ally_01_crimson_clamp_256.png", Rect2(70.4, 376.6, 200, 200), "dragon", 38],
	"A2": ["assets/characters/ally_02_bone_raider_256.png", Rect2(289.1, 355.1, 192, 192), "dark", 38],
	"A3": ["assets/characters/ally_03_panda_gunner_256.png", Rect2(171.8, 504.4, 212, 212), "knight", 38],
	"A4": ["assets/characters/ally_04_twin_apes_256.png", Rect2(27.1, 672.4, 228, 228), "light", 38],
	"A5": ["assets/characters/ally_05_flora_fairy_256.png", Rect2(300.4, 679.8, 228, 228), "nature", 38],
	"E1": ["assets/enemies/boss_01_long_ear_guardian_512.png", Rect2(597.8, 274, 336, 336), "light", 40],
	"E2": ["assets/enemies/enemy_01_dusk_dragon_256.png", Rect2(503.1, 635.7, 252, 252), "dark", 36],
	"E3": ["assets/enemies/enemy_02_twin_tail_256.png", Rect2(747.1, 650.4, 252, 252), "nature", 36],
	"BOSS": ["assets/enemies/boss_01_long_ear_guardian_512.png", Rect2(502.7, 386.8, 448, 448), "light", 40],
}
const RINGS := {
	"A1": Rect2(97,545,146,50), "A2": Rect2(314,517,142,50), "A3": Rect2(201,683,154,54),
	"A4": Rect2(58,865,166,58), "A5": Rect2(331,873,166,58), "E1": Rect2(647,561,238,78),
	"E2": Rect2(538,849,182,62), "E3": Rect2(782,863,182,62),
	"BOSS": Rect2(570,769,314,102),
}
const CHIP_POS := {
	"A1": Vector2(114,586), "A2": Vector2(329,556), "A3": Vector2(222,727), "A4": Vector2(85,913), "A5": Vector2(358,921),
	"E1": Vector2(679,629), "E2": Vector2(542,901), "E3": Vector2(786,915),
	"BOSS": Vector2(640,862),
}
const ELEMENT_COLORS := {"dragon": Color("ff5a3d"), "knight": Color("4da8ff"), "nature": Color("5bd75b"), "light": Color("ffc93c"), "dark": Color("b06bff")}
const KIND_NAMES := ["dragon", "knight", "nature", "light", "dark", "capsule", "wild"]
const ALLY_SLOT_BY_ELEMENT := ["A1", "A3", "A5", "A4", "A2"]
const ENEMY_SLOTS := ["E1", "E2", "E3"]
const DRAW_ORDER := ["A2", "A1", "E1", "A3", "E2", "A4", "E3", "A5"]

var selected_cards: Array[int] = []
var target := ""
var stage_nodes := {}
var card_nodes: Array[TextureButton] = []
var selected_frames: Array[TextureRect] = []
var card_value_plates: Array[TextureRect] = []
var card_value_labels: Array[Label] = []
var queue_nodes: Array[TextureRect] = []
var card_base_y: Array[float] = []
var controller: BattleController
var target_visual_requested := false
var tropical := true
var visual_state := "padrao"

func _ready() -> void:
	set_process_unhandled_key_input(true)
	_build()
	controller = get_node("BattleController") as BattleController
	controller.state_changed.connect(_render_gameplay)
	controller.selection_changed.connect(_render_gameplay)
	controller.message_changed.connect(_show_gameplay_message)
	(stage_nodes.leader as TextureButton).pressed.connect(controller.use_leader_skill)
	_render_gameplay()

func _build() -> void:
	_add_color("Shell", Rect2(0,0,1024,1600), Color("16130d"), self)
	var header := _section("Header")
	_add_texture("AvatarImage", "assets/hud/header/avatar_placeholder.png", Rect2(32,24,84,84), header)
	_add_texture("AvatarFrame", "assets/hud/header/avatar_frame.png", Rect2(26,18,96,96), header)
	var player_name := _add_label("PlayerName", "Jinsa", Rect2(140,24,190,52), 30, CREAM, header, false, 700)
	player_name.add_theme_font_override("font", _font("fonts/InstrumentSans-Variable.ttf", 700))
	_add_label("Rank", "TAMER · LV38", Rect2(223,43,180,36), 14, AMBER, header)
	_add_progress("XP", "assets/hud/header/xp_bar_under.png", "assets/hud/header/xp_bar_progress.png", Rect2(140,86,296,8), 51.0, Color.WHITE, header)
	_add_label("XPValue", "6120/12000", Rect2(450,72,180,38), 16, Color(CREAM,0.45), header)
	_add_texture("SyncDot", "assets/hud/header/sync_dot.png", Rect2(848,43,46,46), header)
	_add_label("Sync", "SYNC", Rect2(894,44,58,42), 14, Color(CREAM,0.4), header, true)
	var menu := _add_button("MenuButton", "assets/icons/ui/icon_menu_48.png", Rect2(946,38,58,58), header)
	menu.tooltip_text = "Menu"
	var strip := _section("AccountStrip")
	_add_texture("Background", "assets/hud/strip/strip_bg.png", Rect2(0,132,1024,92), strip)
	for x in [340,682]:
		_add_texture("Rule", "assets/hud/strip/strip_rule.png", Rect2(x,148,2,54), strip)
	var cells := [
		["Bits","assets/icons/currency/icon_bits_48.png",28,56,"BITS","12.845.900",AMBER],
		["Gems","assets/icons/currency/icon_gems_48.png",370,398,"GEMAS","128.400",Color("b06bff")],
		["Energy","assets/icons/currency/icon_energy_48.png",712,740,"ENERGIA","092/100",MINT],
	]
	for cell in cells:
		_add_texture(cell[0]+"Icon", cell[1], Rect2(cell[2],152,18,18), strip)
		_add_label(cell[0]+"Label", cell[4], Rect2(cell[3],143,150,35), 14, Color(CREAM,0.45), strip)
		_add_label(cell[0]+"Value", cell[5], Rect2(cell[2],166,285,45), 25, CREAM, strip, false, 600)
	_add_label("EnergyTimer", "+04:12", Rect2(916,143,80,35), 14, Color(MINT,0.7), strip, true)
	_build_visor()
	var team := _section("TeamHUD")
	_add_label("Label", "EQUIPE HP", Rect2(24,983,110,38), 14, MINT, team)
	stage_nodes["party_hp_bar"] = _add_progress("PartyHP", "assets/hud/team/team_hp_under.png", "assets/hud/team/team_hp_progress_mint.png", Rect2(141,997,587,12), 89.0, Color.WHITE, team)
	stage_nodes["party_hp_value"] = _add_label("Value", "2840/3200", Rect2(748,982,130,38), 19, CREAM, team, true, 500)
	var leader := _add_button("Leader", "assets/buttons/button_leader_normal_ref.png", Rect2(888,984,112,38), team)
	leader.tooltip_text = "Habilidade do líder"
	stage_nodes["leader"] = leader
	_build_bank()
	_build_navigation()
	var toast := _section("Toast")
	toast.visible = false

func _build_visor() -> void:
	var visor := _section("Visor")
	var bg := _add_texture("Background", "assets/background/bg_tropical_visor_976x736.png", Rect2(24,232,976,736), visor)
	stage_nodes["background"] = bg
	var rings_under := _section("RingsUnder", visor)
	for slot in DRAW_ORDER:
		_add_texture(slot, "assets/hud/stage/ring_%s_under.png" % slot, RINGS[slot], rings_under)
	var ring_progress := _section("RingProgress", visor)
	for slot in DRAW_ORDER:
		var value := 72.0 if slot.begins_with("A") else (48.0 if slot == "E1" else 70.0)
		_add_ring(slot, value, ring_progress)
	var figures := _section("Characters", visor)
	for slot in DRAW_ORDER:
		var data: Array = CHARACTERS[slot]
		var figure := _add_texture(slot, data[0], data[1], figures)
		stage_nodes[slot] = figure
		if slot.begins_with("E") or slot.begins_with("A"):
			var hit := Button.new()
			hit.name = "HitArea"
			hit.flat = true
			hit.focus_mode = Control.FOCUS_NONE
			hit.position = data[1].position + Vector2(data[1].size.x * 0.19, data[1].size.y * 0.05)
			hit.size = Vector2(data[1].size.x * 0.62, data[1].size.y * 0.87)
			if slot.begins_with("E"):
				hit.pressed.connect(_on_target_pressed.bind(slot))
			else:
				hit.pressed.connect(_on_ally_pressed.bind(slot))
			figures.add_child(hit)
	var rings_over := _section("RingsOver", visor)
	for slot in DRAW_ORDER:
		_add_texture(slot, "assets/hud/stage/ring_%s_over.png" % slot, RINGS[slot], rings_over)
	_add_texture("Scanline", "assets/background/visor_film_scanline_976x736.png", Rect2(24,232,976,736), visor)
	_add_texture("Vignette", "assets/background/visor_film_vignette_976x736.png", Rect2(24,232,976,736), visor)
	var chrome := _section("Chrome", visor)
	_add_visor_corner_masks(chrome)
	_add_texture("Frame", "assets/hud/visor/visor_frame.png", Rect2(0,185,1024,870), chrome)
	for item in [["TL",40,248],["TR",952,248],["BL",40,920],["BR",952,920]]:
		_add_texture("Corner%s" % item[0], "assets/hud/visor/visor_corner_%s.png" % String(item[0]).to_lower(), Rect2(item[1],item[2],32,32), chrome)
	_add_texture("Sector", "assets/hud/visor/visor_sector_ref.png", Rect2(76,249,263,31), chrome)
	_add_texture("Round", "assets/hud/visor/visor_round_ref.png", Rect2(834,250,114,56), chrome)
	var chips := _section("Chips", visor)
	for slot in DRAW_ORDER:
		_build_chip(slot, chips)
	var ready := _add_texture("SkillReady", "assets/hud/stage/chip_ally_ready_ref.png", Rect2(177,710,202,78), chips)
	ready.visible = false
	stage_nodes["ready"] = ready
	var boss_ring_under := _add_texture("BossUnder", "assets/hud/stage/ring_BOSS_under.png", RINGS.BOSS, rings_under)
	var boss_ring := TextureProgressBar.new()
	boss_ring.name = "BossProgress"
	boss_ring.position = RINGS.BOSS.position
	boss_ring.size = RINGS.BOSS.size
	boss_ring.texture_progress = load(KIT + "assets/hud/stage/ring_BOSS_progress.png")
	boss_ring.fill_mode = TextureProgressBar.FILL_CLOCKWISE
	boss_ring.radial_initial_angle = 90.0
	boss_ring.value = 46
	boss_ring.tint_progress = Color("ff4a3a")
	ring_progress.add_child(boss_ring)
	var boss_figure := _add_texture("BOSS", CHARACTERS.BOSS[0], CHARACTERS.BOSS[1], figures)
	figures.move_child(boss_figure, 7)
	var boss_over := _add_texture("BossOver", "assets/hud/stage/ring_BOSS_over.png", RINGS.BOSS, rings_over)
	for node in [boss_ring_under, boss_ring, boss_figure, boss_over]:
		node.visible = false
	stage_nodes["boss_nodes"] = [boss_ring_under, boss_ring, boss_figure, boss_over]
	_build_chip("BOSS", chips)
	for node in stage_nodes.chip_BOSS:
		node.visible = false
	var aim := _add_texture("Aim", "assets/hud/visor/aim_chefe.png", Rect2(610,281,312,312), visor)
	aim.visible = false
	stage_nodes["aim"] = aim
	var popup := _add_texture("TargetPopup", "assets/hud/popup/popup_target_ref_lado.png", Rect2(234,256,432,232), visor)
	popup.visible = false
	stage_nodes["popup"] = popup

func _add_ring(slot: String, value: float, parent: Node) -> void:
	var ring := TextureProgressBar.new()
	ring.name = slot
	ring.position = RINGS[slot].position
	ring.size = RINGS[slot].size
	ring.texture_progress = load(KIT + "assets/hud/stage/ring_%s_progress.png" % slot)
	ring.fill_mode = TextureProgressBar.FILL_CLOCKWISE
	ring.radial_initial_angle = 90.0
	ring.value = value
	ring.tint_progress = ELEMENT_COLORS[CHARACTERS[slot][2]] if slot.begins_with("A") else Color("ff4a3a")
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(ring)
	stage_nodes["ring_%s" % slot] = ring

func _build_chip(slot: String, parent: Node) -> void:
	var enemy := slot.begins_with("E") or slot == "BOSS"
	var pos: Vector2 = CHIP_POS[slot]
	var width := 174.0 if enemy else 112.0
	var nodes: Array[CanvasItem] = []
	var chip := _add_texture(slot, "assets/hud/stage/chip_enemy_box.png" if enemy else "assets/hud/stage/chip_ally_box.png", Rect2(pos.x,pos.y,width,50), parent)
	nodes.append(chip)
	var element: String = CHARACTERS[slot][2]
	var badge := _add_texture("Badge", "assets/icons/elements/badge_%s.png" % element, Rect2(pos.x+9,pos.y+10,31,30), parent)
	var level := _add_label("Level", "LV%d" % CHARACTERS[slot][3], Rect2(pos.x+39,pos.y+8,55,32), 16, CREAM, parent, true)
	nodes.append_array([badge, level])
	if enemy:
		if slot == "E3":
			for node in nodes:
				node.visible = false
			var reference := _add_texture("E3Reference", "assets/hud/stage/chip_enemy_ref.png", Rect2(pos.x,pos.y,174,50), parent)
			nodes.append(reference)
		else:
			var turns := _add_texture("Turns", "assets/hud/stage/chip_turn_red_ref.png" if slot == "E2" else "assets/hud/stage/chip_turn_amber_ref.png", Rect2(pos.x+101,pos.y+16,53,12), parent)
			nodes.append(turns)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_nodes["chip_%s" % slot] = nodes

func _build_bank() -> void:
	var bank := _section("Bank")
	_add_label("Label", "BANCO", Rect2(24,1039,62,38), 14, Color(CREAM,0.5), bank)
	_add_texture("ComboOff", "assets/hud/bank/bank_combo_off.png", Rect2(94,1050,66,18), bank)
	_add_texture("Rule", "assets/hud/bank/bank_rule.png", Rect2(176,1058,603,2), bank)
	_add_label("QueueLabel", "FILA", Rect2(793,1039,54,38), 14, Color(CREAM,0.4), bank, true)
	for i in 4:
		queue_nodes.append(_add_texture("Queue%02d" % (i+1), "assets/cards/card_%s@1x.png" % ["knight","nature","light","dark"][i], Rect2(854+i*37,1041,31,36), bank))
	var combo := _add_texture("Combo2Of3", "assets/hud/bank/bank_combo_2of3.png", Rect2(94,1050,66,18), bank)
	combo.visible = false
	stage_nodes["combo"] = combo
	var cards := _section("Cards", bank)
	for i in 12:
		var row := i / 6
		var x: float = CARD_X[i % 6]
		var y := 1094.0 + row * 188.8
		var button := _add_button("Card%02d" % (i+1), "assets/cards/card_%s@2x.png" % CARD_NAMES[i], Rect2(x,y,152.7,176.8), cards)
		button.pressed.connect(_on_card_pressed.bind(i))
		card_nodes.append(button)
		card_base_y.append(y)
		var frame := _add_texture("Selected", "assets/cards/card_frame_selected.png", Rect2(x-24,y-54,221,270), cards)
		frame.visible = false
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		selected_frames.append(frame)
		card_value_plates.append(_add_texture("ValuePlate", "assets/cards/card_value_plate.png", Rect2(x+10,y+138,33,31), cards))
		card_value_labels.append(_add_label("Value", str(CARD_VALUES[i]), Rect2(x+11,y+137,31,31), 19, Color.WHITE, cards, true, 600))

func _build_navigation() -> void:
	var nav := _section("Navigation")
	var defs := [
		["Equipe","assets/buttons/button_nav_equipe_ref.png",Rect2(24,1479,232,101)],
		["Invocar","assets/buttons/button_nav_invocar_ref.png",Rect2(272,1479,232,101)],
		["Loja","assets/buttons/button_nav_loja_ref.png",Rect2(520,1479,232,101)],
		["Fases","assets/buttons/button_nav_fases_ref.png",Rect2(734,1453,290,147)],
	]
	for def in defs:
		_add_button(def[0], def[1], def[2], nav)

func _toggle_card(index: int) -> void:
	if index in selected_cards:
		selected_cards.erase(index)
	else:
		selected_cards.append(index)
	selected_frames[index].visible = index in selected_cards
	card_nodes[index].position.y += 10 if index not in selected_cards else -10

func _on_card_pressed(index: int) -> void:
	controller.select_card(index)

func _on_target_pressed(slot: String) -> void:
	var enemy_index := ENEMY_SLOTS.find(slot)
	if enemy_index >= 0:
		target_visual_requested = true
		controller.select_target(enemy_index)

func _on_ally_pressed(slot: String) -> void:
	var element := ALLY_SLOT_BY_ELEMENT.find(slot)
	if element >= 0:
		controller.use_skill(element)

func _render_gameplay() -> void:
	if controller == null or controller.definitions.size() < KIND_NAMES.size():
		return
	var state := controller.state
	selected_cards.assign(state.selected)
	for i in 12:
		var kind: int = state.board.cards[i]
		var visible := kind >= 0
		card_nodes[i].visible = visible
		card_value_plates[i].visible = visible
		card_value_labels[i].visible = visible
		selected_frames[i].visible = visible and i in state.selected
		card_nodes[i].disabled = state.phase != BattleState.Phase.PLAYER_INPUT
		var target_y := card_base_y[i] - (10.0 if i in state.selected else 0.0)
		if not is_equal_approx(card_nodes[i].position.y, target_y):
			var movement := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			movement.tween_property(card_nodes[i], "position:y", target_y, 0.10)
		if visible:
			card_nodes[i].texture_normal = load(KIT + "assets/cards/card_%s@2x.png" % KIND_NAMES[kind])
			card_value_labels[i].text = str(state.board.values[i])
	for i in queue_nodes.size():
		if i < state.board.bag.size():
			queue_nodes[i].texture = load(KIT + "assets/cards/card_%s@1x.png" % KIND_NAMES[state.board.bag[i]])
	(stage_nodes.combo as TextureRect).visible = state.selected.size() == 2
	var hp_ratio := 100.0 * state.party_hp / maxi(1.0, float(state.party_max_hp))
	(stage_nodes.party_hp_bar as TextureProgressBar).value = hp_ratio
	(stage_nodes.party_hp_value as Label).text = "%d/%d" % [state.party_hp, state.party_max_hp]
	for element in 5:
		var ally_slot: String = ALLY_SLOT_BY_ELEMENT[element]
		(stage_nodes["ring_%s" % ally_slot] as TextureProgressBar).value = state.skill_charge[element]
	for enemy_index in state.enemy_hp.size():
		var enemy_slot: String = ENEMY_SLOTS[enemy_index]
		var alive := state.enemy_hp[enemy_index] > 0
		var enemy_ratio := 100.0 * state.enemy_hp[enemy_index] / maxi(1.0, float(state.enemy_max_hp[enemy_index]))
		(stage_nodes["ring_%s" % enemy_slot] as TextureProgressBar).value = enemy_ratio
		stage_nodes[enemy_slot].modulate = Color.WHITE if alive else Color(0.35, 0.35, 0.35, 0.45)
	if target_visual_requested:
		_update_target_visual(ENEMY_SLOTS[state.target])

func _update_target_visual(slot: String) -> void:
	target = slot
	var aim: TextureRect = stage_nodes.aim
	var popup: TextureRect = stage_nodes.popup
	aim.visible = true
	popup.visible = true
	if slot == "E1":
		aim.texture = load(KIT + "assets/hud/visor/aim_chefe.png")
		aim.position = Vector2(610,281)
		aim.size = Vector2(312,312)
		popup.texture = load(KIT + "assets/hud/popup/popup_target_ref_lado.png")
		popup.position = Vector2(234,256)
		popup.size = Vector2(432,232)
	else:
		aim.texture = load(KIT + "assets/hud/visor/aim_inimigo.png")
		aim.position = Vector2(512,641) if slot == "E2" else Vector2(756,656)
		aim.size = Vector2(234,234)
		popup.texture = load(KIT + "assets/hud/popup/popup_target_ref_acima.png")
		popup.position = Vector2(414,466) if slot == "E2" else Vector2(588,480)
		popup.size = Vector2(432,232)

func _show_gameplay_message(message: String) -> void:
	tooltip_text = message

func _select_target(slot: String) -> void:
	target = "" if target == slot else slot
	var aim: TextureRect = stage_nodes.aim
	var popup: TextureRect = stage_nodes.popup
	aim.visible = not target.is_empty()
	popup.visible = not target.is_empty()
	if target.is_empty():
		return
	if target == "E1":
		aim.texture = load(KIT + "assets/hud/visor/aim_chefe.png")
		aim.position = Vector2(610,281)
		aim.size = Vector2(312,312)
		popup.texture = load(KIT + "assets/hud/popup/popup_target_ref_lado.png")
		popup.position = Vector2(234,256)
		popup.size = Vector2(432,232)
	else:
		aim.texture = load(KIT + "assets/hud/visor/aim_inimigo.png")
		aim.position = Vector2(512,641) if target == "E2" else Vector2(756,656)
		aim.size = Vector2(234,234)
		popup.texture = load(KIT + "assets/hud/popup/popup_target_ref_acima.png")
		popup.position = Vector2(414,466) if target == "E2" else Vector2(588,480)
		popup.size = Vector2(432,232)

func set_visual_state(state_name: String) -> void:
	visual_state = state_name
	stage_nodes.background.texture = load(KIT + ("assets/background/bg_deserto_visor_976x736.png" if state_name == "deserto" else "assets/background/bg_tropical_visor_976x736.png"))
	for index in selected_cards.duplicate():
		_toggle_card(index)
	(stage_nodes.combo as TextureRect).visible = false
	(stage_nodes.ready as TextureRect).visible = state_name == "skill_pronta"
	var leader: TextureButton = stage_nodes.leader
	leader.texture_normal = load(KIT + "assets/buttons/button_leader_normal_ref.png")
	leader.position = Vector2(888,984)
	leader.size = Vector2(112,38)
	var toast: Control = get_node("Toast")
	for child in toast.get_children():
		child.queue_free()
	toast.visible = false
	_set_boss_only(state_name == "chefe_sozinho")
	target = ""
	(stage_nodes.aim as TextureRect).visible = false
	(stage_nodes.popup as TextureRect).visible = false
	if state_name == "cartas_selecionadas":
		_toggle_card(0)
		_toggle_card(7)
		(stage_nodes.combo as TextureRect).visible = true
		leader.texture_normal = load(KIT + "assets/buttons/button_leader_active_ref.png")
		leader.position = Vector2(856,984)
		leader.size = Vector2(144,38)
		var banner := NinePatchRect.new()
		banner.name = "Leadership"
		banner.texture = load(KIT + "assets/hud/toast/toast_box_amber.png")
		banner.position = Vector2(249,867)
		banner.size = Vector2(528,149)
		banner.patch_margin_left = 64
		banner.patch_margin_right = 64
		banner.patch_margin_top = 54
		banner.patch_margin_bottom = 54
		banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		toast.add_child(banner)
		_add_label("Text", "LIDERANÇA ATIVA · +25% NESTE TURNO", Rect2(249,893,528,72), 19, AMBER, toast, true)
		toast.visible = true
	elif state_name in ["alertas", "aviso_vermelho", "aviso_menta"]:
		var kind := "amber" if state_name == "alertas" else ("red" if state_name == "aviso_vermelho" else "mint")
		var rect := Rect2(317,867,389,149) if kind == "amber" else (Rect2(220,867,584,149) if kind == "red" else Rect2(373,867,278,149))
		_add_texture("Message", "assets/hud/toast/toast_%s_ref.png" % kind, rect, toast)
		toast.visible = true
		if state_name == "alertas":
			leader.texture_normal = load(KIT + "assets/buttons/button_leader_cooldown_ref.png")
			leader.position = Vector2(899,984)
			leader.size = Vector2(101,38)
	elif state_name == "alvo_chefe":
		_select_target("E1")
	elif state_name == "alvo_inimigo":
		_select_target("E2")

func _set_boss_only(enabled: bool) -> void:
	for slot in ["E1", "E2", "E3"]:
		stage_nodes[slot].visible = not enabled
		for group in ["RingsUnder", "RingProgress", "RingsOver"]:
			var node := get_node_or_null("Visor/%s/%s" % [group, slot])
			if node:
				node.visible = not enabled
		for node in stage_nodes["chip_%s" % slot]:
			node.visible = not enabled and (slot != "E3" or node.name == "E3Reference")
	for node in stage_nodes.boss_nodes:
		node.visible = enabled
	for node in stage_nodes.chip_BOSS:
		node.visible = enabled

func _add_visor_corner_masks(parent: Node) -> void:
	var corners := [
		[Vector2(24,232), Vector2(56,264), -90.0, -180.0],
		[Vector2(1000,232), Vector2(968,264), 0.0, -90.0],
		[Vector2(24,968), Vector2(56,936), 180.0, 90.0],
		[Vector2(1000,968), Vector2(968,936), 0.0, 90.0],
	]
	for i in corners.size():
		var data: Array = corners[i]
		var outer: Vector2 = data[0]
		var center: Vector2 = data[1]
		var polygon := PackedVector2Array([outer])
		polygon.append(Vector2(center.x, outer.y) if i < 2 else Vector2(outer.x, center.y))
		for step in 13:
			var angle := deg_to_rad(lerpf(data[2], data[3], step / 12.0))
			polygon.append(center + Vector2(cos(angle), sin(angle)) * 32.0)
		var mask := Polygon2D.new()
		mask.name = "Mask%d" % i
		mask.polygon = polygon
		mask.color = Color("16130d")
		parent.add_child(mask)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Z:
			controller.undo_selection()
			return
		if event.keycode == KEY_R:
			controller.restart()
			return
		var states := {KEY_F1:"padrao", KEY_F2:"cartas_selecionadas", KEY_F3:"skill_pronta", KEY_F4:"alertas", KEY_F5:"deserto", KEY_F6:"chefe_sozinho"}
		if states.has(event.keycode):
			set_visual_state(states[event.keycode])

func _section(name: String, parent: Node = self) -> Control:
	var section := Control.new()
	section.name = name
	section.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	section.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(section)
	return section

func _add_texture(name: String, path: String, rect: Rect2, parent: Node) -> TextureRect:
	var item := TextureRect.new()
	item.name = name
	item.texture = load(KIT + path)
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.position = rect.position
	item.size = rect.size
	item.stretch_mode = TextureRect.STRETCH_SCALE
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

func _add_button(name: String, path: String, rect: Rect2, parent: Node) -> TextureButton:
	var button := TextureButton.new()
	button.name = name
	button.texture_normal = load(KIT + path)
	button.position = rect.position
	button.size = rect.size
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	parent.add_child(button)
	return button

func _add_color(name: String, rect: Rect2, color: Color, parent: Node) -> ColorRect:
	var item := ColorRect.new()
	item.name = name
	item.position = rect.position
	item.size = rect.size
	item.color = color
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

func _add_progress(name: String, under: String, progress: String, rect: Rect2, value: float, tint: Color, parent: Node) -> TextureProgressBar:
	var bar := TextureProgressBar.new()
	bar.name = name
	bar.texture_under = load(KIT + under)
	bar.texture_progress = load(KIT + progress)
	bar.position = rect.position
	bar.size = rect.size
	bar.value = value
	bar.tint_progress = tint
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bar)
	return bar

func _font(path: String, weight: int) -> FontVariation:
	var font := FontVariation.new()
	font.base_font = load(KIT + path)
	font.variation_opentype = {"wght": weight}
	return font

func _add_label(name: String, value: String, rect: Rect2, font_size: int, color: Color, parent: Node, centered := false, weight := 400) -> Label:
	var label := Label.new()
	label.name = name
	label.text = value
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_override("font", _font("fonts/MartianMono-Variable.ttf", weight))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label
