extends Control
signal target_pressed(index: int)
signal skill_pressed(index: int)
signal leader_pressed

var shown_cooldown: int = 0
var definitions: StageDefinition = preload("res://data/stages/ilha_digital.tres")

func _ready() -> void:
	for i in $Allies.get_child_count():
		$Allies.get_child(i).pressed.connect(func(): skill_pressed.emit(i))
	for i in 3:
		$Enemies.get_child(i).pressed.connect(func(): target_pressed.emit(i))
	$Leader.pressed.connect(func(): leader_pressed.emit())

func render(state: BattleState) -> void:
	for i in state.enemy_hp.size():
		get_node("Fields/EnemyHP%d" % i).set_state(state.enemy_hp[i], state.enemy_max_hp[i])
		get_node("Fields/EnemyLevel%d" % i).set_value("LV %d" % definitions.enemies[i].level)
		$Enemies.get_child(i).disabled = state.enemy_hp[i] <= 0
	for i in 5:
		get_node("Fields/Skill%d" % i).set_state(state.skill_charge[i], 100)
		get_node("Fields/AllyLevel%d" % i).set_value("LV %d" % definitions.allies[i].level)
	if shown_cooldown != state.leader_turns_left:
		$Leader.tooltip_text = "Liderança disponível" if state.leader_turns_left == 0 else "Liderança: %d turnos" % state.leader_turns_left
		shown_cooldown = state.leader_turns_left
