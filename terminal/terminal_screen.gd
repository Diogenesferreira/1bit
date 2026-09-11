class_name TerminalScreen
extends Control

const BattleFxCanvasScript := preload("res://terminal/battle_fx_canvas.gd")
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
var order_badges: Array[TextureRect] = []
var order_labels: Array[Label] = []
var queue_nodes: Array[TextureRect] = []
var card_base_y: Array[float] = []
var controller: BattleController
var target_visual_requested := false
var effect_layer: Control
var fx_canvas: Control
var end_layer: Control
var figure_base_positions := {}
var previous_enemy_hp: Array[int] = []
var previous_enemy_countdowns: Array[int] = []
var previous_party_hp := -1
var previous_skill_charge: Array[int] = []
var previous_leader_active := false
var elapsed_idle := 0.0
var rendered_cards: Array[int] = []
var battle_damage_total := 0
var battle_combo_total := 0
var battle_max_chain := 0
var battle_critical_total := 0
var tropical := true
var visual_state := "padrao"

func _ready() -> void:
	set_process_unhandled_key_input(true)
	_build()
	controller = get_node("BattleController") as BattleController
	controller.state_changed.connect(_render_gameplay)
	controller.message_changed.connect(_show_gameplay_message)
	controller.combo_visual_requested.connect(_animate_combo)
	controller.abandonment_visual_requested.connect(_animate_abandonment)
	controller.battle_reset.connect(_reset_visual_tracking)
	controller.battle_finished.connect(_show_end_screen)
	controller.skill_visual_requested.connect(_animate_skill_cast)
	controller.selection_resolve_delay = 0.28
	controller.chain_step_delay = 1.42
	(stage_nodes.leader as TextureButton).pressed.connect(controller.use_leader_skill)
	_render_gameplay()

func _reset_visual_tracking() -> void:
	previous_enemy_hp.clear()
	previous_enemy_countdowns.clear()
	previous_party_hp = -1
	previous_skill_charge.clear()
	rendered_cards.clear()
	previous_leader_active = false
	battle_damage_total = 0
	battle_combo_total = 0
	battle_max_chain = 0
	battle_critical_total = 0
	if end_layer:
		for child in end_layer.get_children():
			child.queue_free()
		end_layer.visible = false
	if fx_canvas:
		fx_canvas.clear_all()
	for slot in DRAW_ORDER:
		var figure: TextureRect = stage_nodes.get(slot) as TextureRect
		if figure:
			figure.position = figure_base_positions[slot]
			figure.scale = Vector2.ONE
			figure.rotation = 0.0
			figure.modulate = Color.WHITE

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
	end_layer = _section("EndScreen")
	end_layer.visible = false
	effect_layer = _section("BattleFX")
	fx_canvas = BattleFxCanvasScript.new()
	fx_canvas.name = "LightCanvas"
	fx_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effect_layer.add_child(fx_canvas)
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
		figure.pivot_offset = Vector2(data[1].size.x * 0.5, data[1].size.y * 0.96)
		figure_base_positions[slot] = figure.position
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
		var initial_count := 2 if slot == "E1" else (3 if slot == "E3" else 1)
		var counter_bg := _add_color("TurnBackground", Rect2(pos.x+99,pos.y+14,58,17), Color("18150f"), parent)
		nodes.append(counter_bg)
		var bars: Array[ColorRect] = []
		for i in 3:
			var dash := _add_color("TurnDash%d" % i, Rect2(pos.x+102+i*9,pos.y+20,6,4), AMBER, parent)
			bars.append(dash)
			nodes.append(dash)
		var count_label := _add_label("TurnValue", str(initial_count), Rect2(pos.x+132,pos.y+13,24,18), 12, AMBER, parent, true, 600)
		nodes.append(count_label)
		stage_nodes["turn_label_%s" % slot] = count_label
		stage_nodes["turn_bars_%s" % slot] = bars
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
		var badge := _add_texture("OrderBadge", "assets/cards/card_order_badge.png", Rect2(x+117,y+7,28,28), cards)
		badge.visible = false
		order_badges.append(badge)
		var order := _add_label("Order", "", Rect2(x+117,y+7,28,28), 16, Color("1a1105"), cards, true, 600)
		order.visible = false
		order_labels.append(order)

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
	var first_render := rendered_cards.is_empty()
	if first_render:
		rendered_cards.resize(12)
		rendered_cards.fill(-2)
	if previous_skill_charge.is_empty():
		previous_skill_charge.resize(5)
		previous_skill_charge.fill(-1)
	var changed_cards: Array[int] = []
	selected_cards.assign(state.selected)
	for i in 12:
		var kind: int = state.board.cards[i]
		var previous_kind := rendered_cards[i]
		var visible := kind >= 0
		if not first_render and previous_kind >= 0 and kind < 0 and i in BoardState.ENTRIES and state.phase == BattleState.Phase.PLAYER_INPUT:
			_animate_entry_return(i, previous_kind, card_value_labels[i].text.to_int())
		card_nodes[i].visible = visible
		card_value_plates[i].visible = visible
		card_value_labels[i].visible = visible
		selected_frames[i].visible = visible and i in state.selected
		var order_index := state.selected.find(i)
		order_badges[i].visible = visible and order_index >= 0
		order_labels[i].visible = visible and order_index >= 0
		order_labels[i].text = str(order_index + 1) if order_index >= 0 else ""
		card_nodes[i].disabled = state.phase != BattleState.Phase.PLAYER_INPUT
		var target_y := card_base_y[i] - (10.0 if i in state.selected else 0.0)
		if not is_equal_approx(card_nodes[i].position.y, target_y):
			var movement := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			movement.tween_property(card_nodes[i], "position:y", target_y, 0.10)
			movement.parallel().tween_property(card_value_plates[i], "position:y", target_y + 138.0, 0.10)
			movement.parallel().tween_property(card_value_labels[i], "position:y", target_y + 137.0, 0.10)
			movement.parallel().tween_property(order_badges[i], "position:y", target_y + 7.0, 0.10)
			movement.parallel().tween_property(order_labels[i], "position:y", target_y + 7.0, 0.10)
		if visible:
			card_nodes[i].texture_normal = load(KIT + "assets/cards/card_%s@2x.png" % KIND_NAMES[kind])
			card_value_labels[i].text = str(state.board.values[i])
		if not first_render and previous_kind != kind:
			changed_cards.append(i)
		if not first_render and previous_kind < 0 and kind >= 0 and i in BoardState.ENTRIES:
			_animate_entry_drop(i)
	for i in queue_nodes.size():
		if i < state.board.bag.size():
			queue_nodes[i].texture = load(KIT + "assets/cards/card_%s@1x.png" % KIND_NAMES[state.board.bag[i]])
	(stage_nodes.combo as TextureRect).visible = state.selected.size() == 2
	var leader: TextureButton = stage_nodes.leader
	if state.leader_active:
		leader.texture_normal = load(KIT + "assets/buttons/button_leader_active_ref.png")
		leader.position = Vector2(856,984)
		leader.size = Vector2(144,38)
	elif state.leader_turns_left > 0:
		leader.texture_normal = load(KIT + "assets/buttons/button_leader_cooldown_ref.png")
		leader.position = Vector2(899,984)
		leader.size = Vector2(101,38)
	else:
		leader.texture_normal = load(KIT + "assets/buttons/button_leader_normal_ref.png")
		leader.position = Vector2(888,984)
		leader.size = Vector2(112,38)
	if state.leader_active and not previous_leader_active:
		_animate_leader_activation()
	elif previous_leader_active and not state.leader_active and state.leader_turns_left > 0:
		_spawn_float_text("LIDERANÇA RECARREGA · %d CORRENTES" % state.leader_turns_left, Vector2(766,952), DANGER, 17)
	previous_leader_active = state.leader_active
	var party_bar: TextureProgressBar = stage_nodes.party_hp_bar
	var party_label: Label = stage_nodes.party_hp_value
	if previous_party_hp < 0:
		_set_hp_display(party_bar, party_label, state.party_hp, state.party_max_hp)
	elif state.party_hp != previous_party_hp:
		_tween_hp_display(party_bar, party_label, previous_party_hp, state.party_hp, state.party_max_hp, 0.38, 0.11 if state.party_hp < previous_party_hp else 0.0)
	for element in 5:
		var ally_slot: String = ALLY_SLOT_BY_ELEMENT[element]
		var ally_ring: TextureProgressBar = stage_nodes["ring_%s" % ally_slot]
		if previous_skill_charge[element] < 0:
			ally_ring.value = state.skill_charge[element]
		elif previous_skill_charge[element] != state.skill_charge[element]:
			_tween_progress(ally_ring, previous_skill_charge[element], state.skill_charge[element], 0.32, 0.62)
		previous_skill_charge[element] = state.skill_charge[element]
	for enemy_index in state.enemy_hp.size():
		var enemy_slot: String = ENEMY_SLOTS[enemy_index]
		var alive := state.enemy_hp[enemy_index] > 0
		var enemy_ring: TextureProgressBar = stage_nodes["ring_%s" % enemy_slot]
		_update_enemy_counter(enemy_slot, enemy_index, state.enemy_countdowns[enemy_index])
		if previous_enemy_hp.size() != state.enemy_hp.size():
			enemy_ring.value = 100.0 * state.enemy_hp[enemy_index] / maxi(1.0, float(state.enemy_max_hp[enemy_index]))
		elif state.enemy_hp[enemy_index] != previous_enemy_hp[enemy_index]:
			_tween_progress(enemy_ring,
				100.0 * previous_enemy_hp[enemy_index] / maxi(1.0, float(state.enemy_max_hp[enemy_index])),
				100.0 * state.enemy_hp[enemy_index] / maxi(1.0, float(state.enemy_max_hp[enemy_index])), 0.42, 0.30)
		var just_defeated := previous_enemy_hp.size() == state.enemy_hp.size() and previous_enemy_hp[enemy_index] > 0 and not alive
		stage_nodes[enemy_slot].modulate = Color.WHITE if alive or just_defeated else Color(0.35, 0.35, 0.35, 0.45)
		if previous_enemy_hp.size() == state.enemy_hp.size() and state.enemy_hp[enemy_index] < previous_enemy_hp[enemy_index]:
			var dealt := previous_enemy_hp[enemy_index] - state.enemy_hp[enemy_index]
			battle_damage_total += dealt
			var hit_delay := _animate_enemy_hit(enemy_slot, dealt)
			if just_defeated:
				_animate_enemy_defeat(enemy_slot, hit_delay + 0.24)
	if previous_party_hp >= 0 and state.party_hp < previous_party_hp:
		_animate_party_hit(previous_party_hp - state.party_hp)
	elif previous_party_hp >= 0 and state.party_hp > previous_party_hp:
		_animate_party_heal(state.party_hp - previous_party_hp)
	if changed_cards.size() >= 3 and state.phase == BattleState.Phase.PLAYER_INPUT and not state.last_chain.is_empty():
		_animate_hand_redistribution(changed_cards)
	previous_enemy_hp.assign(state.enemy_hp)
	previous_enemy_countdowns.assign(state.enemy_countdowns)
	previous_party_hp = state.party_hp
	rendered_cards.assign(state.board.cards)
	if target_visual_requested:
		_update_target_visual(ENEMY_SLOTS[state.target])

func _animate_combo(event: Dictionary) -> void:
	var color := _element_color(int(event.element))
	var center := Vector2(512, 1280)
	battle_combo_total += 1
	battle_max_chain = maxi(battle_max_chain, int(event.chain) + 1)
	battle_critical_total += int(bool(event.critical))
	var cascade_delay := 0.15 if int(event.chain) > 0 else 0.0
	fx_canvas.flash(center, 90.0, 0.44, cascade_delay + 0.50)
	for i in 3:
		var index: int = event.indices[i]
		var clone := _make_effect_card(int(event.kinds[i]), int(event.values[i]), _card_position_for_logic_slot(index))
		var aligned := center - Vector2(76, 88) + Vector2((i - 1) * 92, 0)
		var merged := center - Vector2(76, 88)
		var tween := create_tween()
		if cascade_delay > 0.0:
			clone.modulate.a = 0.45
			tween.tween_property(clone, "modulate:a", 1.0, 0.075)
			tween.tween_property(clone, "modulate:a", 0.55, 0.0375)
			tween.tween_property(clone, "modulate:a", 1.0, 0.0375)
		tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(clone, "position", aligned, 0.28)
		tween.parallel().tween_property(clone, "scale", Vector2.ONE * 1.14, 0.28)
		tween.tween_interval(0.09)
		tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(clone, "position", merged, 0.44)
		tween.parallel().tween_property(clone, "rotation", deg_to_rad((i - 1) * 3.0), 0.22)
		tween.parallel().tween_method(_set_card_white.bind(clone), 0.0, 1.0, 0.44)
		tween.tween_property(clone, "rotation", 0.0, 0.12)
		tween.parallel().tween_property(clone, "scale", Vector2.ONE * 1.28, 0.15)
		if i == 0:
			tween.tween_callback(_spawn_combo_burst.bind(event, color))
		tween.tween_property(clone, "modulate:a", 0.0, 0.16)
		tween.parallel().tween_property(clone, "scale", Vector2.ONE * 1.7, 0.16)
		tween.tween_callback(clone.queue_free)

func _make_effect_card(kind: int, value: int, at_position: Vector2) -> Control:
	var holder := Control.new()
	holder.position = at_position
	holder.size = Vector2(152.7, 176.8)
	holder.pivot_offset = holder.size * 0.5
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_layer.add_child(holder)
	var face := _add_texture("Face", "assets/cards/card_%s@2x.png" % KIND_NAMES[kind], Rect2(Vector2.ZERO, holder.size), holder)
	face.material = _fusion_material()
	_add_texture("ValuePlate", "assets/cards/card_value_plate.png", Rect2(10,138,33,31), holder)
	_add_label("Value", str(value), Rect2(11,137,31,31), 19, Color.WHITE, holder, true, 600)
	return holder

func _fusion_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform float white : hint_range(0.0,1.0) = 0.0; void fragment(){ vec4 t=texture(TEXTURE,UV)*COLOR; t.rgb=mix(t.rgb,vec3(1.0),white*t.a); COLOR=t; }"
	var material := ShaderMaterial.new()
	material.shader = shader
	return material

func _set_card_white(value: float, holder: Control) -> void:
	var face := holder.get_node_or_null("Face") as TextureRect
	if face and face.material:
		(face.material as ShaderMaterial).set_shader_parameter("white", value)
	var number := holder.get_node_or_null("Value") as Label
	var plate := holder.get_node_or_null("ValuePlate") as TextureRect
	if number:
		number.modulate.a = 1.0 - value
	if plate:
		plate.modulate.a = 1.0 - value

func _card_position_for_logic_slot(slot: int) -> Vector2:
	if slot == 12:
		return Vector2(854, 1041)
	return Vector2(CARD_X[slot % 6], card_base_y[slot])

func _spawn_combo_burst(event: Dictionary, color: Color) -> void:
	var center := Vector2(512, 1280)
	fx_canvas.flash(center, 190.0, 0.22)
	fx_canvas.shock(center, color, 300.0, 0.38)
	fx_canvas.burst(center, color, 56, 180.0, 720.0, 0.62, 320.0)
	if int(event.chain) > 0:
		_spawn_float_text("CADEIA ×%d" % (int(event.chain) + 1), center + Vector2(0,-118), AMBER, 28)
	if bool(event.critical):
		_spawn_float_text("CRÍTICO", center + Vector2(0,-72), DANGER, 30)
	if int(event.element) == CardDefinition.Kind.CAPSULE:
		_spawn_energy_orbs(center, Vector2(512, 1003), color)
	elif int(event.element) == CardDefinition.Kind.WILD:
		for slot in ALLY_SLOT_BY_ELEMENT:
			_spawn_energy_orbs(center, _figure_center(slot), color, 4, slot)
	else:
		var slot: String = ALLY_SLOT_BY_ELEMENT[int(event.element)]
		_spawn_energy_orbs(center, _figure_center(slot), color, 4, slot)

func _spawn_energy_orbs(from: Vector2, to: Vector2, color: Color, count := 4, aura_key := "") -> void:
	for i in count:
		fx_canvas.orb(from, to, color, 0.56, 120.0, 9.0, 0.07 + i * 0.055)
	var impact_delay := 0.07 + (count - 1) * 0.055 + 0.56
	get_tree().create_timer(impact_delay).timeout.connect(func():
		if not is_instance_valid(fx_canvas):
			return
		fx_canvas.burst(to, color, 14, 60.0, 300.0, 0.42, 120.0)
		if not aura_key.is_empty():
			fx_canvas.set_aura(aura_key, to + Vector2(0, 45), color)
			_hop_figure(aura_key, 6.0)
	)

func _animate_leader_activation() -> void:
	var leader: TextureButton = stage_nodes.leader
	leader.pivot_offset = leader.size * 0.5
	var pulse := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse.tween_property(leader, "scale", Vector2.ONE * 1.24, 0.16)
	pulse.tween_property(leader, "scale", Vector2.ONE, 0.22)
	var origin := leader.position + leader.size * 0.5
	fx_canvas.flash(origin, 150.0, 0.22)
	fx_canvas.shock(origin, AMBER, 230.0, 0.38)
	fx_canvas.burst(origin, AMBER, 34, 120.0, 520.0, 0.52, 120.0)
	for slot in ALLY_SLOT_BY_ELEMENT:
		_spawn_energy_orbs(origin, _figure_center(slot), AMBER, 3, slot)
		var figure: TextureRect = stage_nodes[slot]
		var aura := create_tween()
		aura.tween_interval(0.50)
		aura.tween_property(figure, "modulate", Color("ffd36a"), 0.16)
		aura.tween_property(figure, "modulate", Color.WHITE, 0.28)
	_spawn_float_text("♛ LIDERANÇA · +25% NESTA CORRENTE", Vector2(720,940), AMBER, 18)

func _hop_figure(slot: String, height: float) -> void:
	var figure: TextureRect = stage_nodes.get(slot) as TextureRect
	if figure == null:
		return
	var origin: Vector2 = figure_base_positions[slot]
	figure.set_meta("fx_until", Time.get_ticks_msec() + 300)
	var hop := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hop.tween_property(figure, "position:y", origin.y - height, 0.12)
	hop.set_ease(Tween.EASE_IN)
	hop.tween_property(figure, "position:y", origin.y, 0.16)

func _animate_skill_cast(event: Dictionary) -> void:
	var element := int(event.element)
	var slot: String = ALLY_SLOT_BY_ELEMENT[element]
	var at := _figure_center(slot)
	var color := _element_color(element)
	fx_canvas.flash(at, 150.0, 0.28)
	fx_canvas.shock(at, color, 210.0, 0.38)
	fx_canvas.burst(at, color, 32, 100.0, 520.0, 0.52, -80.0)
	_hop_figure(slot, 10.0)
	_spawn_float_text("SKILL · %s" % KIND_NAMES[element].to_upper(), at + Vector2(0,-90), color, 23)

func _fx_dot(center: Vector2, diameter: float, color: Color) -> ColorRect:
	var dot := ColorRect.new()
	dot.position = center - Vector2.ONE * diameter * 0.5
	dot.size = Vector2.ONE * diameter
	dot.pivot_offset = dot.size * 0.5
	dot.color = color
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_layer.add_child(dot)
	return dot

func _spawn_float_text(value: String, at_position: Vector2, color: Color, size: int, delay := 0.0) -> void:
	var label := _add_label("CombatText", value, Rect2(at_position-Vector2(190,35),Vector2(380,70)), size, color, effect_layer, true, 700)
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2.ONE * 1.5
	if delay > 0.0:
		label.modulate.a = 0.0
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if delay > 0.0:
		tween.tween_interval(delay)
		tween.tween_callback(func(): label.modulate.a = 1.0)
	tween.tween_property(label, "scale", Vector2.ONE, 0.18)
	tween.parallel().tween_property(label, "position:y", label.position.y - 24.0, 0.70)
	tween.tween_interval(0.28)
	tween.tween_property(label, "modulate:a", 0.0, 0.22)
	tween.tween_callback(label.queue_free)

func _animate_enemy_hit(slot: String, damage: int) -> float:
	var figure: TextureRect = stage_nodes[slot]
	var impact_delay := _spawn_attack_streaks(slot)
	figure.set_meta("fx_until", Time.get_ticks_msec() + int((impact_delay + 0.24) * 1000.0))
	var origin: Vector2 = figure_base_positions[slot]
	var tween := create_tween()
	tween.tween_interval(impact_delay)
	tween.tween_property(figure, "position:x", origin.x - 16.0, 0.05)
	tween.tween_property(figure, "position:x", origin.x + 14.0, 0.05)
	tween.tween_property(figure, "position:x", origin.x, 0.07)
	_spawn_float_text("TOTAL  −%d" % damage, _figure_center(slot) + Vector2(0,-70), DANGER, 34, impact_delay + 0.12)
	return impact_delay

func _animate_enemy_defeat(slot: String, delay: float) -> void:
	var figure: TextureRect = stage_nodes[slot]
	var origin: Vector2 = figure_base_positions[slot]
	figure.set_meta("fx_until", Time.get_ticks_msec() + int((delay + 0.70) * 1000.0))
	fx_canvas.flash(_figure_center(slot), 130.0, 0.30, delay)
	fx_canvas.burst(_figure_center(slot), DANGER, 38, 80.0, 420.0, 0.64, -30.0, delay)
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_interval(delay)
	tween.tween_property(figure, "position:y", origin.y + 28.0, 0.42)
	tween.parallel().tween_property(figure, "scale", Vector2.ONE * 0.82, 0.42)
	tween.parallel().tween_property(figure, "modulate", Color(0.28,0.28,0.28,0.28), 0.42)
	_spawn_float_text("SINAL PERDIDO", _figure_center(slot) + Vector2(0,-112), DANGER, 20, delay)

func _spawn_attack_streaks(enemy_slot: String) -> float:
	var destination := _figure_center(enemy_slot)
	var shot_index := 0
	for combo in controller.state.last_chain:
		var element := int(combo.element)
		if element == CardDefinition.Kind.CAPSULE:
			continue
		var sources: Array[String] = []
		if element == CardDefinition.Kind.WILD:
			sources.assign(ALLY_SLOT_BY_ELEMENT)
		else:
			sources.append(ALLY_SLOT_BY_ELEMENT[element])
		for source in sources:
			var delay := shot_index * 0.13
			var color := _element_color(element)
			var origin := _figure_center(source)
			var source_element := ALLY_SLOT_BY_ELEMENT.find(source)
			var amount := int(combo.partials.get(source_element, combo.damage))
			fx_canvas.clear_aura(source)
			fx_canvas.streak(origin, destination, color, 0.30, delay)
			get_tree().create_timer(delay).timeout.connect(_hop_figure.bind(source, 4.2))
			get_tree().create_timer(delay + 0.30).timeout.connect(func():
				if is_instance_valid(fx_canvas):
					fx_canvas.burst(destination, color, 16, 80.0, 400.0, 0.36, 80.0)
			)
			var number_offset := Vector2(((shot_index % 3) - 1) * 44.0, -70.0 - (shot_index % 2) * 36.0)
			_spawn_float_text("%d%s" % [amount, "!" if bool(combo.critical) else ""], destination + number_offset,
				color, 27 if bool(combo.critical) else 23, delay + 0.30)
			shot_index += 1
	return 0.30 + maxf(0.0, (shot_index - 1) * 0.13)

func _animate_entry_drop(index: int) -> void:
	var button := card_nodes[index]
	var plate := card_value_plates[index]
	var number := card_value_labels[index]
	var final_position := Vector2(CARD_X[index % 6], card_base_y[index])
	button.pivot_offset = button.size * 0.5
	button.position = queue_nodes[0].position
	button.scale = Vector2.ONE * 0.22
	button.modulate.a = 0.45
	plate.visible = false
	number.visible = false
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "position", final_position, 0.42)
	tween.parallel().tween_property(button, "scale", Vector2.ONE, 0.42)
	tween.parallel().tween_property(button, "modulate:a", 1.0, 0.20)
	tween.tween_callback(func():
		plate.visible = controller.state.board.cards[index] >= 0
		number.visible = controller.state.board.cards[index] >= 0
	)

func _animate_entry_return(index: int, kind: int, value: int) -> void:
	var clone := _make_effect_card(kind, value, Vector2(CARD_X[index % 6], card_base_y[index]))
	var destination := queue_nodes[0].position
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(clone, "position", destination, 0.18)
	tween.parallel().tween_property(clone, "scale", Vector2.ONE * 0.30, 0.18)
	tween.parallel().tween_property(clone, "modulate:a", 0.0, 0.18)
	tween.tween_callback(clone.queue_free)

func _animate_abandonment() -> void:
	var cards := get_node("Bank/Cards") as Control
	var tween := create_tween()
	for offset in [-8.0, 7.0, -5.0, 3.0, 0.0]:
		tween.tween_property(cards, "position:x", offset, 0.03)
	_spawn_float_text("ABANDONO · TURNO PASSOU", Vector2(512,1080), DANGER, 21)

func _animate_hand_redistribution(_changed: Array[int]) -> void:
	var pile := Vector2(512.0 - 76.0, 1280.0 - 88.0)
	var visible_indices: Array[int] = []
	for index in 12:
		if controller.state.board.cards[index] >= 0:
			visible_indices.append(index)
	for order in visible_indices.size():
		var index := visible_indices[order]
		var face := card_nodes[index]
		var plate := card_value_plates[index]
		var number := card_value_labels[index]
		var destination := Vector2(CARD_X[index % 6], card_base_y[index])
		face.disabled = true
		var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.tween_property(face, "position", pile, 0.24)
		tween.parallel().tween_property(plate, "position", pile + Vector2(10,138), 0.24)
		tween.parallel().tween_property(number, "position", pile + Vector2(11,137), 0.24)
		tween.tween_interval(order * 0.026)
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(face, "position", destination, 0.22)
		tween.parallel().tween_property(plate, "position", destination + Vector2(10,138), 0.22)
		tween.parallel().tween_property(number, "position", destination + Vector2(11,137), 0.22)
		if order == visible_indices.size() - 1:
			tween.tween_callback(func():
				for card in card_nodes:
					card.disabled = controller.state.phase != BattleState.Phase.PLAYER_INPUT
			)
	_spawn_float_text("REDISTRIBUIÇÃO", Vector2(512,1190), AMBER, 25, 0.18)

func _set_hp_display(bar: TextureProgressBar, label: Label, hp: int, maximum: int) -> void:
	bar.value = 100.0 * hp / maxi(1.0, float(maximum))
	label.text = "%d/%d" % [hp, maximum]

func _tween_hp_display(bar: TextureProgressBar, label: Label, from: int, to: int, maximum: int,
		duration: float, delay := 0.0) -> void:
	_set_hp_display(bar, label, from, maximum)
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_method(_set_hp_tween_value.bind(bar, label, maximum), float(from), float(to), duration)

func _set_hp_tween_value(value: float, bar: TextureProgressBar, label: Label, maximum: int) -> void:
	_set_hp_display(bar, label, roundi(value), maximum)

func _tween_progress(bar: TextureProgressBar, from: float, to: float, duration: float, delay := 0.0) -> void:
	bar.value = from
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(bar, "value", to, duration)

func _update_enemy_counter(slot: String, enemy_index: int, value: int) -> void:
	var color := DANGER if value <= 1 else AMBER
	var label: Label = stage_nodes["turn_label_%s" % slot]
	label.text = str(value)
	label.add_theme_color_override("font_color", color)
	var bars: Array = stage_nodes["turn_bars_%s" % slot]
	for i in bars.size():
		bars[i].color = Color(color, 1.0 if i < value else 0.16)
	if previous_enemy_countdowns.size() == controller.state.enemy_countdowns.size() and previous_enemy_countdowns[enemy_index] != value:
		label.pivot_offset = label.size * 0.5
		label.scale = Vector2.ONE * 1.55
		create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(label, "scale", Vector2.ONE, 0.22)

func _animate_party_hit(damage: int) -> void:
	_spawn_float_text("−%d" % damage, Vector2(810, 947), DANGER, 30, 0.11)
	var hp_bar: TextureProgressBar = stage_nodes.party_hp_bar
	hp_bar.modulate = DANGER
	var hp_pulse := create_tween()
	hp_pulse.tween_interval(0.11)
	hp_pulse.tween_property(hp_bar, "modulate", Color.WHITE, 0.26)
	for attack in controller.state.last_enemy_attacks:
		var enemy_index := int(attack.enemy)
		if enemy_index < 0 or enemy_index >= ENEMY_SLOTS.size():
			continue
		var figure: TextureRect = stage_nodes[ENEMY_SLOTS[enemy_index]]
		var origin: Vector2 = figure_base_positions[ENEMY_SLOTS[enemy_index]]
		figure.set_meta("fx_until", Time.get_ticks_msec() + 360)
		var lunge := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		lunge.tween_property(figure, "position:x", origin.x - 22.0, 0.16)
		lunge.set_ease(Tween.EASE_IN_OUT)
		lunge.tween_property(figure, "position:x", origin.x, 0.16)
	var visor := get_node("Visor") as Control
	var tween := create_tween()
	tween.tween_property(visor, "position:x", -8.0, 0.05)
	tween.tween_property(visor, "position:x", 8.0, 0.05)
	tween.tween_property(visor, "position:x", 0.0, 0.08)

func _animate_party_heal(amount: int) -> void:
	var at := Vector2(512,1003)
	fx_canvas.flash(at, 120.0, 0.28)
	fx_canvas.burst(at, MINT, 24, 50.0, 220.0, 0.50, -80.0)
	_spawn_float_text("+%d HP" % amount, Vector2(810,947), MINT, 30)
	var hp_bar: TextureProgressBar = stage_nodes.party_hp_bar
	hp_bar.modulate = MINT
	create_tween().tween_property(hp_bar, "modulate", Color.WHITE, 0.42)

func _figure_center(slot: String) -> Vector2:
	var figure: TextureRect = stage_nodes[slot]
	return figure.position + figure.size * Vector2(0.5,0.58)

func _element_color(element: int) -> Color:
	if element == CardDefinition.Kind.CAPSULE:
		return Color("c89a5a")
	if element == CardDefinition.Kind.WILD:
		return Color("cfcfe4")
	return ELEMENT_COLORS[KIND_NAMES[element]]

func _process(delta: float) -> void:
	elapsed_idle += delta
	for slot in DRAW_ORDER:
		var figure := stage_nodes.get(slot) as TextureRect
		if figure == null or Time.get_ticks_msec() < int(figure.get_meta("fx_until", 0)):
			continue
		if slot.begins_with("E") and controller and controller.state.enemy_hp[ENEMY_SLOTS.find(slot)] <= 0:
			continue
		var phase := float(slot.unicode_at(1) % 5) * 0.71
		var wave := sin(elapsed_idle * 2.0 + phase)
		var breath := 1.0 + wave * 0.022
		figure.scale = Vector2(breath, 1.0 + wave * 0.014)
		figure.position = figure_base_positions[slot] + Vector2(0, wave * 1.2)
		figure.rotation = deg_to_rad(wave * 0.8) if slot.begins_with("E") else 0.0
		if fx_canvas:
			fx_canvas.move_aura(slot, _figure_center(slot) + Vector2(0,45))

func _show_end_screen(won: bool) -> void:
	await get_tree().create_timer(0.42).timeout
	if controller.state.phase not in [BattleState.Phase.VICTORY, BattleState.Phase.DEFEAT]:
		return
	for child in end_layer.get_children():
		child.queue_free()
	end_layer.visible = true
	var overlay_color := Color(0.03,0.025,0.02,0.78) if won else Color(0.10,0.005,0.01,0.82)
	_add_color("Veil", Rect2(0,232,1024,1221), overlay_color, end_layer)
	var word := "VITÓRIA" if won else "DERROTA"
	var title_color := Color("ffd36a") if won else DANGER
	var letter_width := 76.0
	var start_x := 512.0 - word.length() * letter_width * 0.5
	for i in word.length():
		var letter := _add_label("Letter%d" % i, word.substr(i,1), Rect2(start_x+i*letter_width,410,letter_width,100), 54, title_color, end_layer, true, 700)
		letter.pivot_offset = letter.size * 0.5
		letter.position.y -= 38.0 if won else -10.0
		letter.scale = Vector2.ONE * (2.4 if won else 0.35)
		letter.modulate.a = 0.0
		var reveal := create_tween().set_trans(Tween.TRANS_BACK if won else Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		reveal.tween_interval(0.18 + i * 0.075)
		reveal.tween_property(letter, "modulate:a", 1.0, 0.12)
		reveal.parallel().tween_property(letter, "position:y", 410.0, 0.42 if won else 0.30)
		reveal.parallel().tween_property(letter, "scale", Vector2.ONE, 0.42 if won else 0.30)
	var subtitle := "SETOR 03 · ILHA DIGITAL · LIMPO" if won else "EQUIPE CAÍDA · SINAL PERDIDO"
	var sub := _add_label("Subtitle", subtitle, Rect2(212,502,600,42), 16, MINT if won else DANGER, end_layer, true, 600)
	sub.modulate.a = 0.0
	var sub_tween := create_tween()
	sub_tween.tween_interval(0.78)
	sub_tween.tween_property(sub, "modulate:a", 1.0, 0.36)
	var panel := _add_color("StatsPanel", Rect2(190,1080,644,278), Color(0.055,0.045,0.03,0.96), end_layer)
	panel.modulate.a = 0.0
	var panel_tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	panel_tween.tween_interval(1.02)
	panel_tween.tween_property(panel, "modulate:a", 1.0, 0.42)
	var stats := [["DANO TOTAL",battle_damage_total],["COMBOS",battle_combo_total],["MAIOR CADEIA",battle_max_chain],["CRÍTICOS",battle_critical_total]]
	for i in stats.size():
		var x := 216.0 + (i % 2) * 302.0
		var y := 1100.0 + (i / 2) * 82.0
		var caption := _add_label("Caption%d" % i, stats[i][0], Rect2(x,y,250,28), 13, Color(CREAM,0.55), end_layer)
		var value := _add_label("Stat%d" % i, "0", Rect2(x,y+25,250,42), 27, CREAM, end_layer, false, 700)
		caption.modulate.a = 0.0
		value.modulate.a = 0.0
		var reveal_stat := create_tween()
		reveal_stat.tween_interval(1.15 + i * 0.08)
		reveal_stat.tween_callback(func(): caption.modulate.a = 1.0; value.modulate.a = 1.0)
		reveal_stat.tween_method(func(n: float): value.text = str(roundi(n)), 0.0, float(stats[i][1]), 0.75)
	var replay := Button.new()
	replay.name = "Replay"
	replay.text = "JOGAR DE NOVO" if won else "TENTAR DE NOVO"
	replay.position = Vector2(322,1282)
	replay.size = Vector2(380,62)
	replay.add_theme_font_override("font", _font("fonts/MartianMono-Variable.ttf", 700))
	replay.add_theme_font_size_override("font_size", 18)
	replay.add_theme_color_override("font_color", Color("171109"))
	var button_style := StyleBoxFlat.new()
	button_style.bg_color = AMBER if won else DANGER
	button_style.corner_radius_top_left = 8
	button_style.corner_radius_top_right = 8
	button_style.corner_radius_bottom_left = 8
	button_style.corner_radius_bottom_right = 8
	replay.add_theme_stylebox_override("normal", button_style)
	replay.pressed.connect(func(): controller.restart(false))
	end_layer.add_child(replay)
	if won:
		fx_canvas.flash(Vector2(512,460), 250.0, 0.42)
		fx_canvas.shock(Vector2(512,460), title_color, 360.0, 0.55)
		fx_canvas.burst(Vector2(512,460), title_color, 90, 160.0, 900.0, 1.10, 240.0)
		for slot in ALLY_SLOT_BY_ELEMENT:
			_hop_figure(slot, 10.0)
	else:
		var visor := get_node("Visor") as Control
		var defeat_shake := create_tween()
		for x in [-9.0,8.0,-6.0,4.0,0.0]:
			defeat_shake.tween_property(visor, "position:x", x, 0.08)

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
			node.visible = not enabled
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
