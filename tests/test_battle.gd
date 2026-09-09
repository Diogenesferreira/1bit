extends SceneTree

var failures: int = 0
var checks: int = 0

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var indices: Array[int] = [0, 1, 2]
	expect(MatchResolver.resolve([0, 0, 6], indices).get("valid", false), "Dois Dragon + Wild")
	expect(not MatchResolver.resolve([0, 1, 6], indices).get("valid", false), "Elementos incompatíveis")
	expect(MatchResolver.resolve([6, 6, 6], indices)["element"] == 0, "Três coringas usam líder")
	expect(MatchResolver.resolve([5, 5, 5], indices).get("valid", false), "Três Capsules curam")
	expect(not MatchResolver.resolve([5, 5, 6], indices).get("valid", false), "Wild substitui elementos, não Capsule")
	expect(not MatchResolver.resolve([0, 0, 0], [0, 0, 1]).get("valid", false), "Sem reutilizar a mesma carta")
	expect(not MatchResolver.resolve([0, 0, 0], [-1, 0, 1]).get("valid", false), "Índice negativo rejeitado")
	var board := BoardState.new(12345)
	board.refill([7, 0, 11])
	expect(board.cards[7] == 0 and board.cards[0] == 1 and board.cards[11] == 2, "BAG consumida na ordem da seleção")
	expect(board.bag.size() == 6 and board.bag[0] == 3, "BAG mantém seis próximas cartas")
	var screen = load("res://battle/battle_screen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	var controller: BattleController = screen.get_node("BattleController")
	expect(screen.get_node("AttackBoard/Slots").get_child_count() == 12, "Doze slots ativos")
	expect(screen.get_node("BagPreview/Cards").get_child_count() == 6, "Seis previews")
	expect(screen.get_node("Battlefield/Allies").get_child_count() == 5, "Cinco aliados")
	expect(screen.get_node("Battlefield/Enemies").get_child_count() == 4, "Quatro slots de inimigos")
	expect(controller.state.round_index == 3 and controller.state.party_hp == 2840, "Abertura reproduz o mockup")
	controller.select_card(0)
	controller.select_card(0)
	expect(controller.state.selected.is_empty(), "Toque repetido desmarca")
	controller.select_card(0)
	controller.select_card(1)
	controller.select_card(2)
	expect(controller.state.selected.is_empty() and controller.state.turn_index == 1, "Trio inválido não consome turno")
	controller.select_card(0)
	controller.select_card(7)
	controller.select_card(5)
	controller.select_card(1)
	expect(controller.state.selected.size() == 3, "Entrada bloqueada durante resolução")
	await create_timer(0.2).timeout
	expect(controller.state.enemy_hp[0] == 1490, "Dano 18 × 20 aplicado ao boss")
	expect(controller.state.party_hp == 2645, "Três inimigos contra-atacam")
	expect(controller.state.board.cards[7] == 1 and controller.state.board.cards[5] == 2, "Refill real após combo")
	expect(controller.state.skill_charge[0] == 100, "Combo carrega skill individual")
	controller.use_skill(0)
	expect(controller.state.enemy_hp[0] == 840 and controller.state.skill_charge[0] == 0, "Skill consome carga e aplica dano")
	controller.use_leader_skill()
	expect(controller.state.leader_turns_left == 3, "Líder tem recarga de três turnos")
	var hp_before: int = controller.state.enemy_hp[0]
	controller.use_leader_skill()
	expect(controller.state.enemy_hp[0] == hp_before, "Líder bloqueado durante recarga")
	controller.state.board.cards[0] = 5
	controller.state.board.cards[1] = 5
	controller.state.board.cards[2] = 5
	controller.state.party_hp = 3190
	controller.state.selected.assign(indices)
	controller.resolve_selected()
	expect(controller.state.party_hp == 3005, "Cura limitada ao máximo, seguida de contra-ataque")
	controller.state.enemy_hp.assign([10, 10, 10])
	controller.state.board.cards.assign(BoardState.INITIAL_CARDS)
	controller.state.selected.assign([0, 7, 5])
	var coins: int = root.get_node("PlayerProfile").money
	controller.resolve_selected()
	expect(controller.state.phase == BattleState.Phase.VICTORY, "Dano encadeado conclui vitória")
	expect(root.get_node("PlayerProfile").money == coins + 250, "Recompensa de vitória")
	controller.restart()
	expect(controller.state.round_index == 1 and controller.state.party_hp == 3200, "Reinício desde round 1")
	controller.state.enemy_hp.assign([1, 1, 1])
	controller.state.selected.assign([0, 7, 5])
	controller.resolve_selected()
	expect(controller.state.round_index == 2 and controller.state.party_hp == 3200, "Próximo round sem ataque fantasma")
	controller.state.party_hp = 1
	controller.state.board.cards.assign(BoardState.INITIAL_CARDS)
	controller.state.selected.assign([0, 7, 5])
	controller.resolve_selected()
	expect(controller.state.phase == BattleState.Phase.DEFEAT, "Derrota em zero HP")
	controller.restart(false)
	controller.select_card(0)
	controller.select_card(7)
	controller.select_card(5)
	controller.restart(false)
	await create_timer(0.2).timeout
	expect(controller.state.turn_index == 1 and controller.state.enemy_hp[0] == 1850, "Reinício cancela resolução pendente")
	# Teste de toque no botão real, não apenas chamada direta ao controlador.
	var card: Control = screen.get_node("AttackBoard/Slots/CardSlot01")
	var point := card.global_position + card.size / 2.0
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = point
		root.push_input(event, true)
		await process_frame
	expect(controller.state.selected == [0], "Hitbox da carta recebe clique real")
	# Simula uma partida completa para garantir término sem tabuleiro travado.
	controller.restart()
	controller.state.board.rng.seed = 42
	var turns := 0
	while controller.state.phase == BattleState.Phase.PLAYER_INPUT and turns < 100:
		var match_indices := MatchResolver.available_match(controller.state.board.cards)
		expect(not match_indices.is_empty(), "Tabuleiro sempre jogável")
		if match_indices.is_empty():
			break
		controller.state.selected.assign(match_indices)
		controller.resolve_selected()
		turns += 1
	expect(controller.state.phase in [BattleState.Phase.VICTORY, BattleState.Phase.DEFEAT], "Partida completa termina")
	print("CHECKS: %d | FAILURES: %d" % [checks, failures])
	screen.queue_free()
	await process_frame
	quit(1 if failures else 0)
