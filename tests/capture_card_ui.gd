extends SceneTree

# Captura visual manual da composicao final das cartas. Nao participa da
# execucao do jogo nem dos testes de regra.

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
	await process_frame
	await create_timer(0.25).timeout
	_salvar("05_alpha_next_e_icones_v2.png")

	var indice := -1
	for i in EstadoBatalha.TAMANHO_MAO:
		if tela.estado.mao[i] != null:
			indice = i
			break
	if indice >= 0:
		await tela._ao_tocar_casa(indice)
		await process_frame
		_salvar("06_alpha_next_selecionada_v2.png")
	quit()


func _salvar(nome: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAIDA))
	var imagem := root.get_texture().get_image()
	var erro := imagem.save_png(ProjectSettings.globalize_path(SAIDA + nome))
	if erro != OK:
		push_error("Falha ao salvar captura %s: %s" % [nome, error_string(erro)])
	else:
		print("CAPTURA: ", ProjectSettings.globalize_path(SAIDA + nome))
