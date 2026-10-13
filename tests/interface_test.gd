extends SceneTree
## Fluxos reais de telas, redução de opções e preservação da tentativa.
var game
var failures: Array[String] = []
var checks := 0
var folder := "res://evidence/trilha-ambientacao/interfaces"
var table_materials: Array[Dictionary] = []
var original_shadow_opacity := 1.0

func _initialize() -> void:
	call_deferred("run")

func frames(n: int = 6) -> void:
	for i in range(n):
		await process_frame
		await physics_frame

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
	else:
		print("PASS: " + message)

func capture(name: String) -> void:
	await frames(3)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder + "/" + name + ".png")

func press(key: String) -> void:
	var target: Button = game.hud.buttons[key]
	if not target.is_visible_in_tree() or target.disabled:
		check(false, "Botão inacessível no fluxo: " + key)
		return
	target.pressed.emit()
	await frames()

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
	await frames()

func check_page(kind: String) -> void:
	var window := root.get_visible_rect().grow(1)
	check(window.encloses(game.hud.modal_card.get_global_rect()), "Diálogo %s cabe na janela" % kind)
	var controls: Array[Control] = []
	game.hud.collect_focus(game.hud.pages[kind], controls)
	var visible := true
	for control in controls:
		visible = visible and window.encloses(control.get_global_rect())
	check(visible, "Controles do diálogo %s estão dentro da janela" % kind)
	check(game.hud.pages[kind].is_ancestor_of(root.gui_get_focus_owner()), "Foco pertence ao diálogo " + kind)

func check_ambience(context: String) -> void:
	var original_materials := true
	for surface in table_materials:
		original_materials = original_materials and surface.mesh.material_override == surface.material
	check(original_materials, "Texturas e relevo originais permanecem na mesa: " + context)
	check(game.sun.shadow_enabled and is_equal_approx(game.sun.shadow_opacity, original_shadow_opacity), "Sombras do ateliê preservadas: " + context)
	var decorations_visible := true
	for path in ["Novelos", "Personagem", "Ambiente/Bancada/PecaInspiracao", "Ambiente/BaseLuminaria", "Ambiente/AcabamentoEntrega3/UtensiliosMesa"]:
		decorations_visible = decorations_visible and game.get_node(path).is_visible_in_tree()
	check(decorations_visible, "Objetos do ateliê permanecem visíveis: " + context)

func check_activity(context: String) -> void:
	var scene: Rect2 = game.hud.scene_rect
	var all_cells := true
	for r in range(8):
		for c in range(8):
			var point: Vector2 = game.rig.camera.unproject_position(game.board.to_global(game.board.cell_position(r,c)))
			all_cells = all_cells and scene.has_point(point)
	check(all_cells, "As 64 células cabem na área 3D: " + context)
	var controls: Array[Control] = []
	game.hud.collect_focus(game.hud.root_control, controls)
	check(controls.size() == 7, "A atividade apresenta somente sete botões: " + context)
	var bounds := root.get_visible_rect().grow(1)
	var visible := true
	for control in controls:
		visible = visible and bounds.encloses(control.get_global_rect())
	check(visible, "Todos os sete botões cabem na janela: " + context)
	check(scene.end.y < game.hud.tools_panel.position.y, "Barra de ferramentas fica fora da malha: " + context)
	check(game.hud.board_labels.get_global_rect().end.y <= scene.position.y, "Rótulos ficam acima da malha: " + context)
	check(not game.rig.inspection, "Atividade mantém câmera estável: " + context)
	check_ambience(context)
	var surroundings_in_frame := true
	for node in [game.yarns[0], game.yarns[1], game.yarns[2], game.get_node("Ambiente/Bancada/PecaInspiracao")]:
		var point: Vector2 = game.rig.camera.unproject_position(node.global_position)
		surroundings_in_frame = surroundings_in_frame and scene.has_point(point)
	check(surroundings_in_frame, "Novelos e peça de inspiração cabem junto do bastidor: " + context)
	var window_scale := Vector2(root.size) / root.get_visible_rect().size
	var smallest_cell := INF
	for r in range(7):
		for c in range(7):
			var center: Vector2 = game.rig.camera.unproject_position(game.board.to_global(game.board.cell_position(r,c))) * window_scale
			var right: Vector2 = game.rig.camera.unproject_position(game.board.to_global(game.board.cell_position(r,c+1))) * window_scale
			var below: Vector2 = game.rig.camera.unproject_position(game.board.to_global(game.board.cell_position(r+1,c))) * window_scale
			smallest_cell = minf(smallest_cell, minf(center.distance_to(right), center.distance_to(below)))
	check(smallest_cell >= 36.0, "Células mantêm ao menos 36 pixels entre centros para clicar: %s (%.1f px)" % [context, smallest_cell])

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--evidence-dir="):
			folder = argument.trim_prefix("--evidence-dir=")
	DirAccess.make_dir_recursive_absolute(folder)
	root.unfocusable = true
	root.mouse_passthrough = true
	await frames()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await frames(24)
	for mesh in game.get_node("Ambiente/Bancada/Mesa").get_children():
		if mesh is MeshInstance3D and str(mesh.name).begins_with("TabuaAcabada"):
			table_materials.append({"mesh":mesh, "material":mesh.material_override})
	original_shadow_opacity = game.sun.shadow_opacity
	check(game.paused and game.hud.modal_kind=="welcome", "Abertura mantém controles parados")
	check_page("welcome")
	check(root.gui_get_focus_owner()==game.hud.buttons.start, "Foco inicial na ação principal")
	await capture("01-boas-vindas")
	await key(KEY_TAB)
	check(game.hud.pages.welcome.is_ancestor_of(root.gui_get_focus_owner()), "Tab permanece no diálogo")
	await press("welcome_help")
	check_page("help")
	check(not game.hud.buttons.solution.is_visible_in_tree(), "Exemplo só é oferecido depois de chegar à bancada")
	await press("help_next")
	await capture("02-ajuda")
	await press("help_next")
	await press("help_next")
	check(game.hud.modal_kind=="welcome", "Ajuda inicial retorna às boas-vindas")
	await press("start")
	check(not game.paused and game.player.controls_enabled, "Iniciar habilita exploração")
	await capture("03-exploracao")
	game.player.position = Vector3(0,0.03,1.68)
	game.player.velocity = Vector3.ZERO
	await frames(20)
	game.enter_work()
	await create_timer(0.9).timeout
	check(game.mode==game.Mode.WORK, "Bancada abre desafio")
	check_activity("janela inicial")
	check(game.hud.feedback_label.text=="Escolha uma cor.", "Entrada mostra uma única próxima ação")
	await capture("04-atividade")
	await press("color_1")
	check(game.hud.feedback_label.text=="Pinte do outro lado da linha verde.", "Escolha de cor avança a orientação")
	await press("verify")
	check(game.board.hint_marks[0].visible and game.board.hint_marks[1].visible, "Conferência incompleta destaca um par")
	check("Veja estes dois" in game.hud.feedback_label.text, "Dica usa mensagem curta no mesmo espaço")
	await capture("05-dica")
	await press("color_0")
	game.paint(1,5)
	var saved: Array = game.model.answer.duplicate(true)
	await press("pause")
	check_page("pause")
	await capture("06-pausa")
	await press("reset")
	check_page("reset")
	check(game.paused and game.model.answer==saved, "Pedir reinício não apaga tentativa")
	await capture("07-reiniciar")
	await press("reset_cancel")
	check(game.model.answer==saved and game.hud.modal_kind=="pause", "Cancelar reinício retorna à pausa com a trama")
	await press("pause_help")
	check_page("help")
	check(game.paused and not game.rig.enabled, "Ajuda bloqueia pintura e câmera")
	await press("solution")
	check(not game.paused and game.model.answer==saved and game.model.showing_solution, "Exemplo sai da ajuda preservando a tentativa")
	check(not game.hud.tools_panel.visible and game.hud.buttons.color_0.disabled, "Exemplo recolhe e bloqueia ferramentas de pintura")
	await capture("08-exemplo")
	await press("piece")
	check(game.hud.piece_open and game.rig.inspection, "Peça permite inspeção")
	check_ambience("peça em destaque")
	await capture("09-peca")
	await key(KEY_ESCAPE)
	check(not game.hud.piece_open and game.model.showing_solution and not game.rig.inspection, "Esc da peça retorna ao exemplo com câmera estável")
	await press("back_solution")
	check(game.model.answer==saved and not game.model.showing_solution, "Voltar do exemplo recupera tentativa")
	check_activity("retorno do exemplo")
	await press("pause")
	await press("options_menu")
	check_page("options")
	await capture("10-opcoes")
	await press("welcome")
	check(game.paused and game.hud.modal_kind=="welcome", "Menu permite voltar ao início")
	await press("start")
	check(not game.paused and game.mode==game.Mode.WORK and game.model.answer==saved, "Retomar pela abertura preserva tentativa e bancada")
	await press("pause")
	await press("sound_menu")
	check_page("sound")
	await capture("11-som")
	game.volume_slider.value = 0.35
	check(is_equal_approx(game.audio.level,0.35), "Volume do menu chega ao áudio")
	await press("pause_sound")
	check(game.audio.muted and "desligado" in game.hud.buttons.pause_sound.text, "Som pode ser silenciado no menu")
	await key(KEY_ESCAPE)
	check(game.hud.modal_kind=="pause", "Esc de Som retorna à pausa")
	await press("options_menu")
	await press("pause_quit")
	check_page("quit")
	await press("quit_cancel")
	check(game.hud.modal_kind=="options", "Cancelar saída retorna ao menu de origem")
	await press("cg")
	check(not game.paused and game.hud.cg_open and not game.hud.task_box.visible, "Apresentação de CG abre pelo menu")
	check(game.rig.inspection, "CG permite órbita")
	check_ambience("apresentação de CG")
	await capture("12-cg")
	await key(KEY_ESCAPE)
	check(not game.hud.cg_open and not game.rig.inspection, "Esc da CG retorna à câmera fixa")
	for r in range(8):
		for c in range(4,8):
			game.model.paint(r,c,game.model.expected(r,c))
	game.refresh()
	await press("verify")
	check_page("success")
	check(game.hud.modal_kind=="success" and game.hud.completed, "Conclusão só após simetria correta")
	await capture("13-conclusao")
	await press("success_piece")
	check(not game.paused and game.hud.piece_open, "Conclusão abre peça real")
	await press("back_piece")
	await press("color_1")
	game.paint(1,5)
	check(not game.hud.completed, "Editar depois da conclusão pede nova conferência")
	await press("pause")
	await press("reset")
	await press("reset_confirm")
	check(game.model.answer[1][5]==-1 and not game.paused, "Reinício confirmado limpa tentativa")
	check(game.hud.feedback_label.text=="Escolha uma cor.", "Reinício volta à primeira orientação")
	root.size = Vector2i(1000,680)
	await frames(16)
	check_activity("1000 × 680")
	await capture("14-atividade-janela-minima")
	await press("pause")
	check_page("pause")
	await capture("15-pausa-janela-minima")
	await press("pause_help")
	check_page("help")
	await capture("16-ajuda-janela-minima")
	await press("help_close")
	check(game.hud.modal_kind=="pause", "Ajuda retorna à pausa de origem")
	await press("sound_menu")
	check_page("sound")
	await press("sound_back")
	await press("options_menu")
	check_page("options")
	await press("options_back")
	await press("resume")
	root.size = Vector2i(1600,900)
	await frames(16)
	check_activity("1600 × 900")
	await capture("17-atividade-tela-larga")
	await key(KEY_ESCAPE)
	check(game.paused and game.hud.modal_kind=="pause", "Esc na atividade abre a pausa")
	await press("explore")
	await create_timer(0.9).timeout
	check(game.mode==game.Mode.EXPLORE and not game.paused, "Voltar ao ateliê restaura exploração")
	check_ambience("retorno à exploração")
	var report := {"engine":Engine.get_version_info().string,"checks":checks,"failures":failures,"minimum_window":"1000x680","executable":OS.get_executable_path(),"resource_root":ProjectSettings.globalize_path("res://")}
	var file := FileAccess.open(folder+"/results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("INTERFACES: " + JSON.stringify(report))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	quit(0 if failures.is_empty() else 1)
