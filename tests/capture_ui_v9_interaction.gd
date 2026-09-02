extends SceneTree

const SAIDA := "res://novos modelos refeitos/alpha_jogavel/18_ui_v10_duas_entradas.png"

func _initialize() -> void:
	call_deferred("_capturar")

func _capturar() -> void:
	root.size = Vector2i(558, 1000)
	root.content_scale_size = Vector2i(940, 1685)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var tela := (load("res://scenes/battle/BattleScreen.tscn") as PackedScene).instantiate() as BattleScreen
	root.add_child(tela)
	await process_frame
	var escolhidos: Array[int] = []
	var alvo := ""
	for i in EstadoBatalha.TAMANHO_MAO:
		var carta: Carta = tela.estado.mao[i]
		if carta == null or carta.tipo == Carta.CORINGA:
			continue
		var candidatos: Array[int] = []
		for j in EstadoBatalha.TAMANHO_MAO:
			var outra: Carta = tela.estado.mao[j]
			if outra != null and Carta.combina(outra.tipo, carta.tipo):
				candidatos.append(j)
		if candidatos.size() >= 2:
			escolhidos = candidatos.slice(0, 2)
			alvo = carta.tipo
			break
	if escolhidos.size() == 2:
		await tela._ao_tocar_casa(escolhidos[0])
		await tela._ao_tocar_casa(escolhidos[1])
	await create_timer(0.12).timeout
	var caminho := ProjectSettings.globalize_path(SAIDA)
	DirAccess.make_dir_recursive_absolute(caminho.get_base_dir())
	var erro := root.get_texture().get_image().save_png(caminho)
	if erro == OK:
		print("CAPTURA: ", caminho, " tipo=", alvo)
	else:
		push_error("Falha ao salvar captura: %s" % error_string(erro))
	quit()
