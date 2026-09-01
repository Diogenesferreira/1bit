extends SceneTree

const SAIDA := "res://novos modelos refeitos/alpha_jogavel/10_hud_inimigo_v6_estados.png"


func _initialize() -> void:
	call_deferred("_capturar")


func _capturar() -> void:
	root.size = Vector2i(558, 1000)
	root.content_scale_size = Vector2i(940, 1685)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var tela := (load("res://scenes/battle/BattleScreen.tscn") as PackedScene).instantiate() as BattleScreen
	root.add_child(tela)
	await process_frame
	var fracoes := [1.0, 0.72, 0.48, 0.22, 0.0]
	for i in mini(fracoes.size(), tela.estado.inimigos.size()):
		var inimigo: Dictionary = tela.estado.inimigos[i]
		inimigo.hp = roundi(float(inimigo.hp_max) * fracoes[i])
		tela._inimigos[i].atualizar()
		tela._inimigos[i].definir_turno(i + 1, 5)
	tela._inimigos[3].definir_selecionado(true)
	await create_timer(0.48).timeout
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAIDA.get_base_dir()))
	var erro := root.get_texture().get_image().save_png(ProjectSettings.globalize_path(SAIDA))
	if erro != OK:
		push_error("Falha ao salvar captura: %s" % error_string(erro))
	else:
		print("CAPTURA: ", ProjectSettings.globalize_path(SAIDA))
	quit()
