extends SceneTree

var checks := 0
var failures := 0

func expect(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func wait_chain(controller: BattleController) -> void:
	for frame in 1000:
		if controller.state.phase != BattleState.Phase.RESOLVING:
			return
		await create_timer(0.02).timeout
	expect(false, "Resolution exceeded timeout")

func run() -> void:
	expect(MatchResolver.resolve([0,0,6], [0,1,2]).valid, "Wild substitutes attack")
	expect(MatchResolver.resolve([5,5,6], [0,1,2]).valid, "Wild substitutes healing")
	expect(MatchResolver.resolve([6,6,6], [0,1,2]).element == 6, "All wild targets team")
	expect(not MatchResolver.resolve([0,1,6], [0,1,2]).valid, "Different colors invalid")
	expect(not MatchResolver.resolve([0,0,0], [0,0,2]).valid, "Repeated slot invalid")
	expect(MatchResolver.critical_score([0,0,0], [4,4,4]) == 40, "Equal values critical")
	expect(MatchResolver.critical_score([0,0,0], [4,2,3]) > 0, "Unordered sequence critical")
	expect(MatchResolver.critical_score([0,0,6], [5,5,9]) == 50, "Wild completes repeated value")
	expect(MatchResolver.critical_score([0,0,6], [2,7,9]) == 0, "Wild alone does not guarantee critical")
	expect(DamageResolver.reduction_for_defense(200) > DamageResolver.reduction_for_defense(100), "Mais defesa aumenta a reducao")
	expect(DamageResolver.damage_after_defense(1000, 100) > 0 and DamageResolver.damage_after_defense(1000, 100) < 1000, "Defesa reduz por multiplicacao sem zerar dano")
	for seed_value in range(1, 101):
		var b := BoardState.new(seed_value)
		expect(b.cards[5] == -1 and b.cards[11] == -1, "Entries empty at opening")
		expect(not MatchResolver.available_match(b.cards).is_empty(), "Guaranteed playable hand")
		var snapshot := b.snapshot()
		var next := b.draw()
		b.restore(snapshot)
		expect(b.draw() == next, "Undo preserves draw and RNG")
		var counts := [0,0,0,0,0,0,0]
		b.deck.clear()
		b.bag.clear()
		b.bag_values.clear()
		for n in 100:
			b.append_preview()
			counts[b.bag.back()] += 1
		expect(counts == [16,16,16,16,16,12,8], "Fixed bag composition")
	var b := BoardState.new(10)
	b.cards.assign([0,0,0,0,0,-1,1,1,6,2,3,-1])
	b.values.assign([9,9,9,2,3,0,1,5,8,2,3,0])
	b.bag[0] = 5
	var trio := MatchResolver.cascade(b, [true,true,true,true,true])
	expect(b.cards[trio[0]] == 0, "Count 5 and count 2 share priority; best critical wins")
	trio = MatchResolver.cascade(b, [false,true,true,true,true])
	expect(b.cards[trio[0]] == 1, "Unavailable ally excluded")
	var c := BattleController.new()
	root.add_child(c)
	c.load_test_hand()
	var original := c.state.board.snapshot()
	c.select_card(0)
	expect(c.state.board.cards[5] == 2 and c.state.selected == [0], "First touch draws top into row entry")
	c.select_card(1)
	expect(c.state.board.cards[11] == 3, "Second touch falls into other entry")
	c.undo_selection()
	expect(c.state.selected == [0] and c.state.board.cards[11] == -1, "Undo second touch")
	c.undo_selection()
	expect(c.state.board.snapshot() == original, "Full undo restores exact queue, deck, RNG")
	c.select_card(0)
	c.select_card(1)
	c.select_card(0)
	expect(c.state.selected == [1] and c.state.board.bag[0] == 3, "Deselect earlier mark preserves independent later mark")
	c.cancel_selection()
	expect(c.state.board.snapshot() == original, "Cancel restores original bag")
	var hp := c.state.party_hp
	c.select_card(0)
	c.select_card(3)
	expect(c.state.enemy_countdown == 2 and c.state.selected == [3], "Color abandonment spends one turn")
	c.select_card(0)
	c.select_card(3)
	expect(c.state.party_hp < hp and c.state.enemy_countdowns == [3,3,3], "Each enemy attacks and resets its own counter")
	c.load_test_hand()
	c.select_card(0)
	c.select_card(1)
	c.select_card(2)
	expect(c.state.phase == BattleState.Phase.RESOLVING, "Input locked during chain")
	var initial_enemy := c.state.enemy_hp.duplicate()
	await create_timer(0.2).timeout
	expect(c.state.enemy_hp == initial_enemy, "Damage deferred until whole chain finishes")
	await wait_chain(c)
	expect(c.state.last_chain.size() >= 2, "Automatic cascade after manual trio")
	expect(c.state.last_chain[0].critical and c.state.last_chain[0].damage == 237, "444 critical uses Dragon attack plus card power")
	expect(c.state.last_chain[1].critical and c.state.last_chain[1].damage == 245, "234 critical receives the second-chain bonus")
	expect(c.state.enemy_countdown == 2 and c.state.turn_index == 2, "Whole chain spends exactly one turn")
	expect(c.state.board.cards.count(-1) == 2, "Final refill restores ten cards")
	expect(c.state.board.cards[5] == -1 and c.state.board.cards[11] == -1, "Final entries empty")
	c.load_test_hand()
	c.select_card(0)
	c.select_card(1)
	c.select_card(2)
	c.restart()
	var restarted := c.state.board.snapshot()
	await create_timer(0.5).timeout
	expect(c.state.board.snapshot() == restarted and c.state.last_chain.is_empty(), "Restart cancels pending resolution")
	c.load_test_hand()
	c.state.board.cards.assign([5,5,6,0,1,-1,2,3,4,0,1,-1])
	c.state.board.values.assign([5,5,9,1,2,0,3,4,5,6,7,0])
	c.state.party_hp = 3000
	c.select_card(0)
	c.select_card(1)
	c.select_card(2)
	await wait_chain(c)
	expect(c.state.last_chain[0].heal > 0 and c.state.party_hp == 3200, "Wild healing critical and HP cap")
	c.load_test_hand()
	c.state.board.cards.assign([6,6,6,0,1,-1,2,3,4,0,1,-1])
	c.state.board.values.assign([2,5,9,1,2,0,3,4,5,6,7,0])
	c.select_card(0)
	c.select_card(1)
	c.select_card(2)
	await wait_chain(c)
	expect(c.state.last_chain[0].damage == 990, "All wild contributes fully to five allies")
	c.load_test_hand()
	var before_leader := c.state.enemy_hp.duplicate()
	c.use_leader_skill()
	expect(c.state.leader_active and c.state.enemy_hp == before_leader, "Leader activation stores the bonus without immediate damage")
	c.select_card(0)
	c.select_card(1)
	c.select_card(2)
	await wait_chain(c)
	expect(not c.state.leader_active and c.state.leader_turns_left == 3, "Damage consumes leadership and starts cooldown")
	c.queue_free()
	await process_frame
	print("BATTLE CHECKS: %d | FAILURES: %d" % [checks, failures])
	quit(1 if failures else 0)
