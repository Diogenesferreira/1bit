extends SceneTree

var checks: int = 0
var failures: int = 0

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var screen = load("res://battle/battle_screen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	var profile = root.get_node("PlayerProfile")
	var account: Node = screen.get_node("AccountHUD/Fields")
	var controller: BattleController = screen.get_node("BattleController")
	controller.load_test_hand()
	controller.state.party_hp = 2840
	var hud: Node = screen.get_node("CombatHUD/Fields")
	var initial_profile: Dictionary = profile.to_dictionary()
	var reference_profile := {"money": 154200, "tickets": 50, "energy": 92, "level": 38, "player_name": "JINSA", "xp": 6120}
	profile.restore(reference_profile)
	expect(account.get_node("Money/Value") is Label, "Moedas têm um Label separado")
	expect(account.get_node("XPBar") is ProgressBar, "XP usa ProgressBar real")
	expect(account.get_node("EnergyBar") is ProgressBar, "Energia usa ProgressBar real")
	expect(hud.get_node("PartyBar") is ProgressBar, "HP global usa ProgressBar real")
	profile.restore({"money": 0, "tickets": 789, "energy": 17, "level": 123, "player_name": "DOMADOR", "xp": 456})
	expect(account.get_node("Money").text == "0", "Valor zero atualiza moedas")
	expect(account.get_node("Tickets").text == "789", "Tickets atualizam independentemente")
	expect(account.get_node("PlayerName/Value").text == "DOMADOR", "Nome real ligado à conta")
	expect(account.get_node("Level/Value").text == "123", "Level real ligado à conta")
	expect(account.get_node("XPBar").value == 456, "Carga real de XP")
	expect(account.get_node("EnergyBar").value == 17, "Carga real de energia")
	expect(not account.get_node("Money/ReferenceInk").visible, "Texto antigo sai quando o valor muda")
	profile.restore(reference_profile)
	expect(account.get_node("Money/ReferenceInk").visible, "Retornar ao valor original restaura sua grafia")
	expect(not account.get_node("Money/Value").visible, "Não há dois números sobrepostos")
	profile.restore(initial_profile)
	controller.state.party_max_hp = 4000
	controller.state_changed.emit()
	expect(hud.get_node("PartyBar").max_value == 4000, "Mudança apenas de HP máximo atualiza barra")
	expect(hud.get_node("PartyHP").text == "2840 / 4000", "Mudança apenas de HP máximo atualiza texto")
	controller.state.round_index = 1
	controller.state_changed.emit()
	expect(hud.get_node("Round/Value").text == "1 / 3", "Round é um texto separado")
	controller.select_target(1)
	expect(hud.get_node("EnemyHP").text == "700 / 700", "HP segue inimigo selecionado")
	expect(hud.get_node("EnemyBar").value == 700 and hud.get_node("EnemyBar").max_value == 700, "Barra segue inimigo selecionado")
	controller.state.skill_charge[2] = 100
	controller.state_changed.emit()
	expect(screen.get_node("Battlefield/Fields/Skill2").value == 100, "Skill individual separada")
	controller.state.board.values[0] = 9
	controller.state.board.bag_values[0] = 9
	controller.state_changed.emit()
	var card: CardView = screen.get_node("AttackBoard/Slots/CardSlot01")
	expect(card.get_node("Number/Value") is Label, "Número da carta é Label independente")
	expect(card.get_node("Face") is TextureRect, "Arte da carta é nó separado")
	expect(card.power == 9 and card.get_node("Number").text == "9", "Força muda sem trocar o elemento")
	expect(not card.get_node("Number/ReferenceInk").visible, "Número pintado não sobrepõe a nova força")
	expect(screen.get_node("BagPreview/Cards/Next01/Number").text == "9", "Número na BAG também segue os dados")
	expect(DamageResolver.combo_power(controller.state.board.values, [0, 1, 2]) == 17, "Mesmo valor exibido é usado no dano")
	controller.state.board.values[0] = 4
	controller.state_changed.emit()
	expect(card.get_node("Number/ReferenceInk").visible, "Força original retorna sem resíduo")
	card.set_selected(true)
	expect(card.get_node("Selection").visible, "Seleção é um componente separado")
	card.hide()
	expect(not card.get_node("Face").is_visible_in_tree(), "Ocultar carta oculta sua arte")
	expect(not card.get_node("Number").is_visible_in_tree(), "Ocultar carta oculta seu número")
	print("UI COMPONENT CHECKS: %d | FAILURES: %d" % [checks, failures])
	screen.queue_free()
	await process_frame
	quit(1 if failures else 0)
