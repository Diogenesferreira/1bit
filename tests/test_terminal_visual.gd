extends SceneTree

var checks := 0
var failures := 0

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var screen: TerminalScreen = load("res://terminal/terminal_screen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	expect(screen.size == Vector2(1024,1600), "Tela usa a resolução oficial do kit")
	expect(screen.get_node("Visor/Characters").get_child_count() >= 8, "Personagens são nós independentes")
	expect(screen.get_node("Visor/RingsUnder").get_child_count() >= 8, "Anéis são componentes independentes")
	expect(screen.get_node("Bank/Cards").get_child_count() == 48, "Cada carta possui botão, moldura, placa e número")
	expect(screen.card_nodes.size() == 12, "Doze cartas interativas")
	for slot in ["A1","A2","A3","A4","A5","E1","E2","E3"]:
		expect(screen.stage_nodes.has(slot), "%s existe como personagem separado" % slot)
	screen.set_visual_state("cartas_selecionadas")
	expect(screen.selected_cards == [0,7], "Estado homologado seleciona duas cartas")
	expect(screen.get_node("Bank/Combo2Of3").visible, "Indicador 2/3 usa asset do kit")
	screen.set_visual_state("skill_pronta")
	expect(screen.get_node("Visor/Chips/SkillReady").visible, "Estado de skill pronta disponível")
	screen.set_visual_state("alertas")
	expect(screen.get_node("Toast").visible, "Estado de alerta disponível")
	screen.set_visual_state("deserto")
	expect("deserto" in screen.stage_nodes.background.texture.resource_path, "Bioma de deserto usa asset próprio")
	screen.set_visual_state("chefe_sozinho")
	expect(not screen.stage_nodes.E2.visible and screen.stage_nodes.boss_nodes[2].visible, "Formação de chefe sozinho disponível")
	screen.set_visual_state("alvo_inimigo")
	expect(screen.stage_nodes.aim.visible and screen.stage_nodes.popup.visible, "Mira e popup de alvo disponíveis")
	for path in [
		"assets/background/bg_tropical_visor_976x736.png", "assets/background/bg_deserto_visor_976x736.png",
		"assets/hud/header/header_ref.png", "assets/hud/strip/strip_ref.png", "assets/hud/team/team_ref.png",
		"assets/hud/bank/bank_header_ref.png", "assets/cards/card_wild@2x.png",
		"assets/characters/ally_05_flora_fairy_256.png", "assets/enemies/boss_01_long_ear_guardian_512.png",
		"fonts/InstrumentSans-Variable.ttf", "fonts/MartianMono-Variable.ttf"]:
		expect(ResourceLoader.exists("res://design/ilha-digital-godot-kit/" + path), "Kit contém %s" % path)
	print("TERMINAL VISUAL CHECKS: %d | FAILURES: %d" % [checks, failures])
	screen.queue_free()
	await process_frame
	quit(1 if failures else 0)
