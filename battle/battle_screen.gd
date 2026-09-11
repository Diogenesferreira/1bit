extends Control

@onready var controller: BattleController = $BattleController

func _ready() -> void:
	$AttackBoard.card_pressed.connect(controller.select_card)
	$Battlefield.target_pressed.connect(controller.select_target)
	$Battlefield.skill_pressed.connect(controller.use_skill)
	$Battlefield.leader_pressed.connect(controller.use_leader_skill)
	controller.state_changed.connect(_render)
	controller.selection_changed.connect(func(): $AttackBoard.update_selection(controller.state.selected))
	controller.message_changed.connect($AttackBoard.show_message)
	controller.battle_finished.connect(_on_battle_finished)
	$BottomNavigation.navigation_requested.connect(_navigate)
	_render()
	$AttackBoard.show_message("3 CARTAS = COMBO | INIMIGOS EM 3")

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Z:
			controller.undo_selection()
		elif event.keycode == KEY_F6:
			controller.load_test_hand()

func _render() -> void:
	$AttackBoard.render(controller.state, controller.definitions)
	$BagPreview.render(controller.state.board, controller.definitions)
	$CombatHUD.render(controller.state)
	$Battlefield.render(controller.state)

func _on_battle_finished(won: bool) -> void:
	if won:
		PlayerProfile.award_victory()

func _navigate(destination: String) -> void:
	# Três entradas reservadas, como no escopo original. Sem telas inventadas.
	if destination == "fases" and controller.state.phase in [BattleState.Phase.VICTORY, BattleState.Phase.DEFEAT]:
		controller.restart()
