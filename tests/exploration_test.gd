extends SceneTree
const Main = preload("res://scenes/main.tscn")
var game
var failures: Array[String] = []
var count := 0
var metrics: Dictionary = {}
var evidence_folder := "res://evidence"

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool,message: String) -> void:
	count += 1
	if not condition:
		failures.append(message)
		push_error("FAIL: "+message)
	else:
		print("PASS: "+message)

func frames(n: int = 4) -> void:
	for i in range(n):
		await physics_frame
		await process_frame

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await frames()

func move(action: String,seconds: float) -> void:
	Input.action_press(action)
	await create_timer(seconds).timeout
	Input.action_release(action)
	await frames(8)

func at(position: Vector3) -> void:
	game.player.position = position
	game.player.velocity = Vector3.ZERO
	await frames(12)

func click(point: Vector2) -> void:
	# Alinha o ponteiro nativo antes de injetar press/release. Um movimento do
	# sistema entre os eventos poderia transformar o clique sintético em arrasto.
	# Camera3D fornece coordenadas do viewport. Input.parse_input_event aplicava
	# o stretch novamente quando a janela tinha tamanho diferente de 1366x900.
	root.warp_mouse(point)
	await frames(2)
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event,true)
	await frames(1)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
	await frames()

func cell(row: int,column: int) -> Vector2:
	return game.rig.camera.unproject_position(game.board.to_global(game.board.cell_position(row,column)+Vector3(0,0.06,0)))

func drag_view(point: Vector2) -> void:
	var down := InputEventMouseButton.new()
	down.position = point
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	root.push_input(down,true)
	var drag := InputEventMouseMotion.new()
	drag.position = point+Vector2(50,20)
	drag.relative = Vector2(50,20)
	drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(drag,true)
	down = down.duplicate()
	down.position = drag.position
	down.pressed = false
	root.push_input(down,true)
	await frames()

func wheel_up(point: Vector2) -> void:
	var wheel := InputEventMouseButton.new()
	wheel.position = point
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	root.push_input(wheel,true)
	await frames()

func capture(title: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence_folder+"/"+title+".png")

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--evidence-dir="):
			evidence_folder = argument.trim_prefix("--evidence-dir=")
	DirAccess.make_dir_recursive_absolute(evidence_folder)
	# A janela de ensaio não disputa foco com o desktop. Eventos são injetados
	# abaixo; as notificações de perda/retorno de foco continuam testadas ao final.
	root.unfocusable = true
	root.mouse_passthrough = true
	await frames(6)
	game = Main.instantiate()
	root.add_child(game)
	current_scene = game
	await frames(20)
	check(game.paused and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"Abertura não captura mouse sem consentimento de interação")
	game.resume_button.pressed.emit()
	await frames(12)
	check(game.player.is_on_floor() and game.player.position.y>=-0.02,"Personagem nasce apoiada, fora dos móveis")
	check(game.mode==game.Mode.EXPLORE and game.player.controls_enabled,"Exploração habilita controle")
	# Novos objetos devem respeitar a circulação e o espaço físico.
	await at(Vector3(-2.88,0.03,-0.25))
	await move("move_forward",0.65)
	check(game.player.position.z> -0.60,"Cesto bloqueia passagem pelo objeto")
	await at(Vector3(0,0.03,3.0))
	await capture("01-exploracao")
	var old_yaw: float = game.player.pivot.rotation.y
	var look := InputEventMouseMotion.new()
	look.position = Vector2(680,450)
	look.relative = Vector2(30,0)
	Input.parse_input_event(look)
	await frames()
	check(game.player.pivot.rotation.y!=old_yaw,"Mouse altera câmera em terceira pessoa")
	game.player.pivot.rotation.y = 0
	await key(KEY_E)
	check(game.mode==game.Mode.EXPLORE,"E distante não abre bastidor")
	await move("move_forward",0.65)
	check(game.player.position.z<2.2 and game.player.position.z>1.2,"Caminhada aproxima da bancada")
	check(game.audio.steps_played>0,"Passos emitidos ao caminhar")
	await move("move_forward",1.3)
	check(game.player.position.z>1.17,"Colisão da mesa impede atravessar tampo e pernas")
	await at(Vector3(4,0.03,2.5))
	await move("move_right",0.8)
	check(game.player.position.x<4.22,"Parede lateral bloqueia personagem")
	game.player.pivot.rotation.y = PI/2
	await frames(10)
	check(game.player.spring.get_hit_length()<game.player.spring.spring_length,"SpringArm recolhe câmera junto à parede")
	var camera_pos: Vector3 = game.player.camera.global_position
	check(absf(camera_pos.x)<4.45 and absf(camera_pos.z)<4.45,"Câmera permanece dentro da sala")
	game.player.pivot.rotation.y = 0
	await at(Vector3(-2.1,0.03,1.1))
	await move("move_forward",0.9)
	check(game.player.position.z>0.46,"Banqueta bloqueia personagem")
	await at(Vector3(3.0,0.03,-1.4))
	await move("move_right",0.8)
	check(game.player.position.x<3.43,"Estante bloqueia personagem")
	await at(Vector3(0,0.03,1.68))
	check(game.can_interact,"Proximidade correta libera interação")
	check(game.player.spring.get_hit_length()>2.5,"Câmera se afasta novamente ao sair da parede")
	var idle_steps: int = game.audio.steps_played
	await create_timer(0.5).timeout
	check(game.audio.steps_played==idle_steps,"Personagem parada não produz passos")
	# Um obstáculo temporário entre personagem e alvo deve impedir o uso através dele.
	var blocker := StaticBody3D.new()
	blocker.collision_layer = 2
	blocker.position = Vector3(0,1.35,1.48)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.8,0.7,0.08)
	collision.shape = shape
	blocker.add_child(collision)
	game.add_child(blocker)
	await frames()
	await key(KEY_E)
	check(game.mode==game.Mode.EXPLORE,"Obstáculo entre personagem e estação bloqueia interação")
	blocker.queue_free()
	await frames()
	await key(KEY_E)
	await create_timer(0.85).timeout
	check(game.mode==game.Mode.WORK and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"E próximo transita para bastidor e libera cursor")
	check(absf(game.transition_camera.global_basis.determinant()-1.0)<0.001,"Transição mantém base de câmera sem deformação")
	var fixed: Vector3 = game.player.position
	await move("move_forward",0.4)
	check(game.player.position.distance_to(fixed)<0.02,"Personagem fica parada durante atividade")
	var blue: Vector2 = game.hud.buttons.color_1.get_global_rect().get_center()
	await click(blue)
	check(game.selected_color==1,"Cor azul selecionável na barra da atividade")
	var before_toolbar: Array = game.model.answer.duplicate(true)
	await click(game.hud.buttons.color_2.get_global_rect().get_center())
	check(game.selected_color==2 and game.model.answer==before_toolbar,"Clique na paleta da Trilha seleciona fio sem pintar por baixo")
	await click(game.hud.buttons.hint.get_global_rect().get_center())
	check(game.board.hint_marks[0].visible and game.model.answer==before_toolbar,"Dica da barra inferior funciona por clique e preserva a trama")
	var coral_yarn: Vector2 = game.rig.camera.unproject_position(game.yarns[0].global_position)
	await click(coral_yarn)
	check(game.selected_color==0 and game.model.answer==before_toolbar,"Novelo 3D visível permite escolher coral sem pintar a trama")
	await click(blue)
	await click(cell(1,5))
	if game.model.answer[1][5]!=1:
		var hit: Dictionary = game.pick(cell(1,5))
		print("Diagnóstico seleção: mode=",game.mode," paused=",game.paused," color=",game.selected_color," value=",game.model.answer[1][5]," moved=",game.rig.moved," target=",hit.get("collider")," pointer=",root.get_mouse_position()," expected=",cell(1,5))
	check(game.model.answer[1][5]==1,"Célula recebe cor selecionada")
	game.hud.buttons.erase.pressed.emit()
	await click(cell(1,5))
	check(game.model.answer[1][5]==-1,"Apagar funciona")
	game.hud.buttons.color_0.pressed.emit()
	await click(cell(1,5))
	game.hud.buttons.verify.pressed.emit()
	check("Veja estes dois" in game.hud.feedback_label.text,"Validação incompleta orienta correção")
	var saved: Array = game.model.answer.duplicate(true)
	var camera_before: Transform3D = game.rig.camera.transform
	var distance_before: float = game.rig.distance
	await drag_view(cell(1,5))
	check(game.model.answer==saved,"Arrastar durante a atividade não pinta células")
	check(game.rig.camera.transform.is_equal_approx(camera_before),"Arrasto não gira a câmera durante a pintura")
	await wheel_up(cell(1,5))
	check(is_equal_approx(game.rig.distance,distance_before),"Roda não muda o tamanho da malha durante a atividade")
	game.hud.set_piece(true)
	await frames()
	await drag_view(cell(1,5))
	check(not is_zero_approx(game.rig.yaw) and game.model.answer==saved,"Peça permite girar a câmera sem pintar")
	await wheel_up(cell(1,5))
	check(game.rig.distance<distance_before,"Peça permite aproximação pela roda")
	game.hud.buttons.back_piece.pressed.emit()
	await frames()
	check(is_zero_approx(game.rig.yaw) and is_equal_approx(game.rig.distance,3.12),"Voltar da peça restaura vista fixa da atividade")
	game.hud.buttons.pause.pressed.emit()
	game.hud.buttons.pause_help.pressed.emit()
	game.hud.buttons.solution.pressed.emit()
	await click(cell(0,7))
	check(game.model.answer==saved and game.model.showing_solution,"Solução preserva tentativa e bloqueia escrita")
	await capture("02-bastidor")
	game.hud.buttons.back_solution.pressed.emit()
	check(not game.model.showing_solution and game.model.answer==saved,"Voltar da solução recupera tentativa")
	await key(KEY_ESCAPE)
	check(game.paused and game.hud.modal_kind=="pause","Esc da atividade abre menu de pausa")
	game.hud.buttons.explore.pressed.emit()
	await create_timer(0.85).timeout
	check(game.mode==game.Mode.EXPLORE and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED,"Voltar ao ateliê devolve exploração com mouse capturado")
	await key(KEY_E)
	await create_timer(0.85).timeout
	check(game.model.answer==saved,"Sair e voltar preserva matriz")
	game.hud.set_cg(true)
	game.hud.axes_check.button_pressed = true
	game.hud.shadow_check.button_pressed = false
	game.hud.sliders.move.value = 0.3
	game.hud.sliders.rotate.value = 90
	game.hud.sliders.scale.value = 1.2
	check(game.axes.visible and not game.sun.shadow_enabled,"Modo CG mantém eixos e sombras")
	check(is_equal_approx(game.yarns[0].rotation.y,PI/2) and is_equal_approx(game.yarns[0].scale.x,1.2),"Transformações do novelo preservadas")
	game.hud.buttons.restore_yarn.pressed.emit()
	check(game.yarns[0].scale.is_equal_approx(Vector3.ONE),"Restauração do novelo")
	game.hud.set_cg(false)
	for row in range(8):
		for column in range(4,8):
			game.select_color(game.model.expected(row,column))
			game.paint(row,column)
	game.hud.buttons.verify.pressed.emit()
	check(game.model.mistakes().is_empty() and "conseguiu" in game.hud.feedback_label.text,"Conclusão matemática preservada")
	game.hud.buttons.success_close.pressed.emit()
	game.hud.buttons.reset.pressed.emit()
	game.hud.buttons.reset_confirm.pressed.emit()
	check(game.model.answer[1][5]==-1,"Reinício funciona")
	# Foco perdido exige retomada explícita, inclusive durante uma transição.
	game.leave_work()
	game.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	await create_timer(0.85).timeout
	check(game.paused and not game.player.controls_enabled and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"Perda de foco durante transição mantém pausa segura")
	game.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
	check(game.paused,"Retorno de foco não captura mouse automaticamente")
	game.resume_game()
	await key(KEY_ESCAPE)
	check(game.paused,"Esc na exploração abre pausa")
	await key(KEY_ESCAPE)
	check(not game.paused and game.player.controls_enabled,"Esc na pausa retoma exploração")
	game.audio.play_step(Vector3(0,0,2.0))
	var rug_stream: AudioStream = game.audio.step_player.stream
	check(game.audio.last_surface=="tapete","Passo identifica o tapete")
	game.audio.play_step(Vector3(2.0,0,2.0))
	check(game.audio.last_surface=="piso" and game.audio.step_player.stream!=rug_stream,"Piso usa contato sonoro diferente do tapete")
	check(game.audio.step_player.global_position.is_equal_approx(Vector3(2.0,0.1,2.0)),"Passo é emitido junto ao ponto de apoio")
	game.volume_slider.value = 0
	var quiet_steps: int = game.audio.steps_played
	game.audio.play_step()
	check(not game.audio.ambience.playing and game.audio.steps_played==quiet_steps,"Volume zero silencia ambiente e novos contatos")
	game.volume_slider.value = 0.75
	check(game.audio.ambience.playing and is_equal_approx(game.audio.level,0.75),"Controle de volume restaura reprodução")
	game.handle_action("sound")
	check(game.audio.muted and not game.audio.ambience.playing and not game.audio.step_player.playing and not game.audio.player.playing,"Mute silencia todos os players")
	var steps: int = game.audio.steps_played
	await move("move_back",0.5)
	check(game.audio.steps_played==steps,"Caminhar silenciado não reproduz passos")
	# Amostra real de tempos de quadro, em execução gráfica e resolução registrada.
	var frame_times: Array[float] = []
	var last := Time.get_ticks_usec()
	for i in range(90):
		await process_frame
		var now := Time.get_ticks_usec()
		frame_times.append(float(now-last)/1000.0)
		last=now
	frame_times.sort()
	metrics={"frames":90,"median_ms":frame_times[45],"p95_ms":frame_times[85],"viewport":str(root.size),"gpu":RenderingServer.get_video_adapter_name(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
	await at(Vector3(-0.7,0.03,2.7))
	game.player.pivot.rotation.y = -0.25
	game.player.visual.rotation.y = 0.45
	await frames(10)
	await capture("03-ambiente")
	game.queue_free()
	current_scene = null
	await frames()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var report := {"engine":Engine.get_version_info().string,"checks":count,"failures":failures,"performance":metrics,"executable":OS.get_executable_path(),"resource_root":ProjectSettings.globalize_path("res://")}
	var file := FileAccess.open(evidence_folder+"/results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("RESULTADO: %d verificações; %d falhas. Métricas: %s"%[count,failures.size(),metrics])
	quit(0 if failures.is_empty() else 1)
