extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1024, 1600)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var screen: Control = load("res://terminal/terminal_screen.tscn").instantiate()
	viewport.add_child(screen)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://output/verification")
	var result := viewport.get_texture().get_image().save_png("res://output/verification/terminal_padrao.png")
	print("TERMINAL_CAPTURE: ", result)
	for state in ["cartas_selecionadas", "skill_pronta", "alertas", "deserto", "chefe_sozinho", "alvo_chefe", "alvo_inimigo"]:
		screen.set_visual_state(state)
		await process_frame
		await RenderingServer.frame_post_draw
		result = viewport.get_texture().get_image().save_png("res://output/verification/terminal_%s.png" % state)
		print("STATE_CAPTURE %s: %s" % [state, result])
	viewport.queue_free()
	await process_frame
	quit()
