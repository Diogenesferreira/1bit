extends SceneTree

const SAIDA := "res://novos modelos refeitos/alpha_jogavel/17_ui_final_v10.png"

func _initialize() -> void:
	call_deferred("_capturar")

func _capturar() -> void:
	root.size = Vector2i(558, 1000)
	root.content_scale_size = Vector2i(940, 1685)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var tela := (load("res://scenes/battle/BattleScreen.tscn") as PackedScene).instantiate()
	root.add_child(tela)
	await process_frame
	await process_frame
	await create_timer(0.30).timeout
	var caminho := ProjectSettings.globalize_path(SAIDA)
	DirAccess.make_dir_recursive_absolute(caminho.get_base_dir())
	var erro := root.get_texture().get_image().save_png(caminho)
	if erro != OK:
		push_error("Falha ao salvar captura: %s" % error_string(erro))
	else:
		print("CAPTURA: ", caminho)
	quit()
