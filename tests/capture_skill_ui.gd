extends SceneTree

# Prancha visual isolada do medidor: diferentes cargas, mesma ancora.

const SAIDA := "res://novos modelos refeitos/alpha_jogavel/"


func _initialize() -> void:
	call_deferred("_capturar")


func _capturar() -> void:
	root.size = Vector2i(558, 1000)
	root.content_scale_size = Vector2i(940, 1685)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var tela := (load("res://scenes/battle/BattleScreen.tscn") as PackedScene).instantiate() as BattleScreen
	root.add_child(tela)
	await process_frame
	var amostras := [1, 3, 5, 7, 8]
	for i in mini(amostras.size(), tela.estado.aliados.size()):
		tela.estado.aliados[i].skill = amostras[i]
		tela._aliados[i].definir_skill_visual(amostras[i])
	await process_frame
	await create_timer(0.15).timeout
	_salvar("07_medidores_skill_posicao_fixa_v1.png")

	for i in tela.estado.aliados.size():
		tela.estado.aliados[i].skill = 8
		tela._aliados[i].definir_skill_visual(8)
	await process_frame
	_salvar("08_medidores_skill_cheios_clicaveis_v1.png")

	var clique := InputEventMouseButton.new()
	clique.button_index = MOUSE_BUTTON_LEFT
	clique.pressed = true
	tela._aliados[2]._card._gui_input(clique)
	await create_timer(0.06).timeout
	_salvar("09_medidor_skill_feedback_clique_v1.png")
	quit()


func _salvar(nome: String) -> void:
	var caminho := SAIDA + nome
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAIDA))
	var erro := root.get_texture().get_image().save_png(ProjectSettings.globalize_path(caminho))
	if erro != OK:
		push_error("Falha ao salvar captura: %s" % error_string(erro))
	else:
		print("CAPTURA: ", ProjectSettings.globalize_path(caminho))
