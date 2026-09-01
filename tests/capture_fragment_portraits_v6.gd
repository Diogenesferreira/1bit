extends SceneTree

const SAIDA := "res://novos modelos refeitos/alpha_jogavel/11_selos_retratos_definitivos_v1.png"


func _initialize() -> void:
	call_deferred("_capturar")


func _capturar() -> void:
	root.size = Vector2i(1700, 420)
	root.content_scale_size = Vector2i(1700, 420)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var tela := Control.new()
	tela.size = Vector2(1700, 420)
	root.add_child(tela)
	var fundo := ColorRect.new()
	fundo.size = tela.size
	fundo.color = Color("77777f")
	tela.add_child(fundo)
	for i in Unidades.ALIADOS.size():
		var placa := ColorRect.new()
		placa.position = Vector2(10 + i * 338, 10)
		placa.size = Vector2(330, 400)
		placa.color = Color("8d8178") if i % 2 == 0 else Color("66727b")
		tela.add_child(placa)
		var d: Dictionary = Unidades.ALIADOS[i]
		var textura := Arte.tex_recortada(String(d.retrato), d.retrato_recorte as Rect2)
		var selo := FragmentPortrait.new()
		selo.position = Vector2(10 + i * 338, 34)
		selo.size = Vector2(330, 330)
		tela.add_child(selo)
		selo.montar(String(d.elemento), textura,
			float(d.get("retrato_zoom", 1.0)), d.get("retrato_offset", Vector2.ZERO))
	await process_frame
	await create_timer(0.15).timeout
	var erro := root.get_texture().get_image().save_png(ProjectSettings.globalize_path(SAIDA))
	if erro != OK:
		push_error("Falha ao salvar captura: %s" % error_string(erro))
	else:
		print("CAPTURA: ", ProjectSettings.globalize_path(SAIDA))
	quit()
