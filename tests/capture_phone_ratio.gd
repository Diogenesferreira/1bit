extends SceneTree

const OUTPUT := "res://novos modelos refeitos/alpha_jogavel/18_phone_20x9.png"


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	root.size = Vector2i(450, 1000)
	root.content_scale_size = Vector2i(940, 1685)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	var screen := (load("res://scenes/battle/BattleScreen.tscn") as PackedScene).instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	await create_timer(0.3).timeout
	var image := root.get_texture().get_image()
	if image == null:
		push_error("Falha ao capturar viewport 20:9")
	else:
		image.save_png(ProjectSettings.globalize_path(OUTPUT))
	quit()
