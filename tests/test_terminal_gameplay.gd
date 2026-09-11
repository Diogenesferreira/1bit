extends SceneTree

var checks := 0
var failures := 0

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func wait_chain(controller: BattleController) -> void:
	for frame in 1000:
		if controller.state.phase != BattleState.Phase.RESOLVING:
			return
		await create_timer(0.01).timeout
	expect(false, "A corrente excedeu o tempo limite")

func run() -> void:
	var screen: TerminalScreen = load("res://terminal/terminal_screen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	var controller := screen.controller
	controller.load_test_hand()
	await process_frame
	expect(screen.card_nodes[0].texture_normal.resource_path.ends_with("card_dragon@2x.png"), "Carta usa o asset exato do kit")
	expect(screen.card_value_labels[0].text == "4", "Numero visual acompanha o estado")
	expect(not screen.card_nodes[5].visible and not screen.card_nodes[11].visible, "Sexta coluna comeca como entrada vazia")
	screen.card_nodes[0].pressed.emit()
	await process_frame
	expect(controller.state.selected == [0], "Botao do terminal seleciona na logica")
	expect(controller.state.board.cards[5] == 2 and screen.card_nodes[5].visible, "BAG desce para a entrada da primeira linha")
	screen.card_nodes[1].pressed.emit()
	await process_frame
	expect(controller.state.selected == [0, 1], "Segunda carta forma selecao 2/3")
	expect(screen.get_node("Bank/Combo2Of3").visible, "Indicador visual 2/3 responde a gameplay")
	expect(controller.state.board.cards[11] == 3 and screen.card_nodes[11].visible, "Segunda compra desce para a outra linha")
	screen.card_nodes[2].pressed.emit()
	expect(controller.state.phase == BattleState.Phase.RESOLVING, "Terceira carta bloqueia entrada durante a corrente")
	await wait_chain(controller)
	await process_frame
	expect(controller.state.last_chain.size() >= 2, "Trio manual dispara cascata automatica")
	expect(controller.state.last_chain[0].critical, "Tres numeros iguais geram critico")
	expect(controller.state.enemy_hp[0] < controller.state.enemy_max_hp[0], "Dano final chega ao inimigo selecionado")
	expect(controller.state.enemy_countdown == 2, "Corrente inteira consome um turno inimigo")
	expect(controller.state.board.cards.count(-1) == 2, "Mao volta a dez cartas e duas entradas")
	expect(screen.card_nodes[5].visible == false and screen.card_nodes[11].visible == false, "Entradas visuais esvaziam apos redistribuir")
	controller.load_test_hand()
	controller.state.board.cards.assign([5,5,6,0,1,-1,2,3,4,0,1,-1])
	controller.state.board.values.assign([5,5,9,1,2,0,3,4,5,6,7,0])
	controller.state.party_hp = 3000
	controller.state_changed.emit()
	for index in [0,1,2]:
		screen.card_nodes[index].pressed.emit()
	await wait_chain(controller)
	expect(controller.state.party_hp == controller.state.party_max_hp, "Capsule com Wild cura sem exceder o HP global")
	print("TERMINAL GAMEPLAY CHECKS: %d | FAILURES: %d" % [checks, failures])
	screen.queue_free()
	await process_frame
	quit(1 if failures else 0)
