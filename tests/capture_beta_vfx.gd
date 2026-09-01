extends SceneTree

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
	var evento := {"cartas": [
		{"tipo": "nature", "valor": 3}, {"tipo": "nature", "valor": 5},
		{"tipo": "nature", "valor": 7}], "slots": [0, 1, 2]}
	tela._anim_trio(evento)
	await create_timer(0.30).timeout
	_salvar("12a_fusao_alinhamento_v1.png")
	await create_timer(0.38).timeout
	_salvar("12b_fusao_convergencia_v1.png")
	await create_timer(0.25).timeout
	_salvar("12c_fusao_estouro_v1.png")
	await create_timer(0.55).timeout
	tela._anim_energia("nature", BattleScreen.FUSAO_CENTRO,
		tela._aliados[2].centro_no_canvas())
	await create_timer(0.62).timeout
	_salvar("12d_energia_bezier_v1.png")
	await create_timer(0.80).timeout
	var impacto := ElementImpact.new()
	tela._voos.add_child(impacto)
	impacto.iniciar("nature", tela._inimigos[0].centro_no_canvas())
	tela._flutuar_placa("+16", tela._aliados[2].centro_no_canvas() + Vector2(0, -74),
		"nature")
	tela._flutuar("-16", tela._inimigos[0].centro_no_canvas() + Vector2(0, -72), 22)
	await create_timer(0.32).timeout
	_salvar("12e_impacto_elemental_v1.png")
	quit()


func _salvar(nome: String) -> void:
	var caminho := SAIDA + nome
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAIDA))
	var erro := root.get_texture().get_image().save_png(ProjectSettings.globalize_path(caminho))
	if erro == OK:
		print("CAPTURA: ", ProjectSettings.globalize_path(caminho))
	else:
		push_error("Falha ao salvar captura: %s" % error_string(erro))
