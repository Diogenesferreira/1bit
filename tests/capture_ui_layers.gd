extends SceneTree
## Teste gráfico: ao esconder os nós, a imagem de fundo não pode conter suas cópias.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1024, 1536)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var screen = load("res://battle/battle_screen.tscn").instantiate()
	viewport.add_child(screen)
	await process_frame
	await process_frame
	screen.get_node("AccountHUD/Fields/Money").hide()
	screen.get_node("AccountHUD/Fields/XPBar").hide()
	screen.get_node("AttackBoard/Slots/CardSlot01").hide()
	screen.get_node("BagPreview/Cards/Next01").hide()
	screen.get_node("BottomNavigation/Buttons/Equipe").hide()
	await process_frame
	await RenderingServer.frame_post_draw
	var capture := viewport.get_texture().get_image()
	var regions := [Rect2i(597, 28, 102, 41), Rect2i(251, 57, 227, 10), Rect2i(28, 982, 150, 160), Rect2i(228, 817, 81, 85), Rect2i(6, 1359, 246, 166)]
	var expected := Color("071526")
	var failures := 0
	for region in regions:
		for y in range(region.position.y + 2, region.end.y - 2, 3):
			for x in range(region.position.x + 2, region.end.x - 2, 3):
				var pixel := capture.get_pixel(x, y)
				if absf(pixel.r - expected.r) + absf(pixel.g - expected.g) + absf(pixel.b - expected.b) > 0.015:
					failures += 1
	DirAccess.make_dir_recursive_absolute("res://output/verification")
	capture.save_png("res://output/verification/ui_layers_hidden.png")
	print("HIDDEN UI LAYERS: 5 | RESIDUAL PIXELS: %d" % failures)
	viewport.queue_free()
	await process_frame
	quit(1 if failures else 0)
