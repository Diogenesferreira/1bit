extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1024, 1536)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var screen = load("res://battle/battle_screen.tscn").instantiate()
	viewport.add_child(screen)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://output/verification")
	var result := viewport.get_texture().get_image().save_png("res://output/verification/initial.png")
	print("INITIAL_CAPTURE: ", result)
	var controller: BattleController = screen.get_node("BattleController")
	controller.load_test_hand()
	controller.select_card(0)
	controller.select_card(1)
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://output/verification/entries.png")
	controller.select_card(2)
	await create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	result = viewport.get_texture().get_image().save_png("res://output/verification/after_combo.png")
	print("COMBO_CAPTURE: ", result)
	viewport.queue_free()
	await process_frame
	quit()
