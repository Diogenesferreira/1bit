extends SceneTree

# Prancha deterministica dos sete tipos para validar a paleta no layout real.

const PASTA_SAIDA := "res://novos modelos refeitos/alpha_jogavel/"


func _initialize() -> void:
	call_deferred("_capturar")


func _capturar() -> void:
	root.size = Vector2i(558, 1000)
	root.content_scale_size = Vector2i(940, 1685)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var tela := (load("res://scenes/battle/BattleScreen.tscn") as PackedScene).instantiate() as BattleScreen
	root.add_child(tela)
	await process_frame
	var tipos := ["dragon", "knight", "nature", "light", "dark",
		Carta.CURA, Carta.CORINGA, "dragon", "nature", "dark"]
	for i in EstadoBatalha.TAMANHO_MAO:
		tela.estado.mao[i] = Carta.new(tipos[i], i % 9 + 1)
	tela._desenhar_campo()
	tela._casas_campo[6].definir_selecionada(true)
	await process_frame
	await create_timer(0.12).timeout
	_salvar("10_paleta_elemental_cards_v1.png")
	for i in 7:
		tela._casas_campo[i].definir_selecionada(true)
	await create_timer(0.12).timeout
	_salvar("11_paleta_cards_selecionados_v1.png")
	quit()


func _salvar(nome: String) -> void:
	var caminho := PASTA_SAIDA + nome
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA_SAIDA))
	var erro := root.get_texture().get_image().save_png(ProjectSettings.globalize_path(caminho))
	if erro != OK:
		push_error("Falha ao salvar captura: %s" % error_string(erro))
	else:
		print("CAPTURA: ", ProjectSettings.globalize_path(caminho))
