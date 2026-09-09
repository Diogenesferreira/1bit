extends ArtSection
signal target_pressed(index: int)
signal skill_pressed(index: int)
signal leader_pressed

const SKILL_BARS := [Rect2(123, 286, 84, 10), Rect2(341, 286, 84, 10), Rect2(250, 419, 84, 10), Rect2(112, 582, 84, 10), Rect2(346, 582, 84, 10)]
const ENEMY_BARS := [Rect2(749, 362, 154, 11), Rect2(637, 580, 134, 11), Rect2(852, 580, 132, 11)]
var shown_hp: Array[int] = [1850, 900, 1200]
var shown_skill: Array[int] = [75, 75, 75, 75, 75]
var shown_cooldown: int = 0

func _ready() -> void:
	for i in $Allies.get_child_count():
		$Allies.get_child(i).pressed.connect(func(): skill_pressed.emit(i))
	for i in 3:
		$Enemies.get_child(i).pressed.connect(func(): target_pressed.emit(i))
	$Leader.pressed.connect(func(): leader_pressed.emit())

func render(state: BattleState) -> void:
	for i in state.enemy_hp.size():
		if state.enemy_hp[i] != shown_hp[i]:
			set_bar_patch("enemy_%d" % i, ENEMY_BARS[i], float(state.enemy_hp[i]) / state.enemy_max_hp[i], Color("ec283b"))
			shown_hp[i] = state.enemy_hp[i]
		$Enemies.get_child(i).disabled = state.enemy_hp[i] <= 0
	for i in 5:
		if state.skill_charge[i] != shown_skill[i]:
			set_bar_patch("skill_%d" % i, SKILL_BARS[i], state.skill_charge[i] / 100.0, Color("22c3f4"))
			shown_skill[i] = state.skill_charge[i]
	if shown_cooldown != state.leader_turns_left:
		$Leader.tooltip_text = "Liderança disponível" if state.leader_turns_left == 0 else "Liderança: %d turnos" % state.leader_turns_left
		shown_cooldown = state.leader_turns_left
