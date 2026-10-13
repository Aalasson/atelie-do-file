extends SceneTree
## Captura e medição comparáveis; não participa da execução normal do jogo.
var game
var folder: String
var report := {}

func _initialize() -> void:
	call_deferred("run")

func frames(amount: int) -> void:
	for i in range(amount):
		await process_frame
		if is_instance_valid(game) and game.paused:
			game.resume_game()

func capture(title: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+"/"+title+".png")

func measure(label: String) -> void:
	await frames(60)
	var durations: Array[float] = []
	var draws: Array[float] = []
	var primitives: Array[float] = []
	var last := Time.get_ticks_usec()
	for i in range(180):
		await process_frame
		var now := Time.get_ticks_usec()
		durations.append(float(now-last)/1000.0)
		last = now
		draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		primitives.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	durations.sort()
	draws.sort()
	primitives.sort()
	report[label] = {"frames":180,"median_ms":durations[90],"p95_ms":durations[171],"draw_calls":draws[90],"primitives":primitives[90]}

func run() -> void:
	# Captura dirigida sem disputar foco; a integração testa pausa separadamente.
	root.unfocusable = true
	root.mouse_passthrough = true
	await frames(6)
	var arguments := OS.get_cmdline_user_args()
	var label := arguments[0] if not arguments.is_empty() else "depois"
	var delivery := arguments[1] if arguments.size()>1 else "entrega-01"
	folder = "res://evidence/"+delivery+"/"+label
	DirAccess.make_dir_recursive_absolute(folder)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await frames(40)
	game.resume_game()
	game.audio.set_muted(true)
	game.player.pivot.rotation.y = 0
	game.player.pivot.rotation.x = deg_to_rad(-20)
	await frames(50)
	await capture("01-exploracao")
	await measure("exploracao")
	game.player.position = Vector3(0,0.03,1.68)
	game.player.velocity = Vector3.ZERO
	await frames(30)
	game.enter_work()
	await create_timer(1.0).timeout
	game.board.show_highlight()
	await capture("02-atividade")
	game.handle_action("solution")
	await frames(10)
	await capture("03-solucao")
	await measure("bastidor_solucao")
	# Inspeção oblíqua da área de trabalho; não altera a câmera jogável.
	game.hud.visible = false
	game.player.visible = false
	var detail_camera := Camera3D.new()
	game.add_child(detail_camera)
	detail_camera.position = Vector3(1.75,2.25,2.05)
	detail_camera.look_at(Vector3(-0.12,1.0,0.0),Vector3.UP)
	detail_camera.fov = 51
	detail_camera.make_current()
	await frames(30)
	await capture("04-bancada")
	if delivery == "entrega-03":
		detail_camera.position = Vector3(-3.5,2.65,4.5)
		detail_camera.look_at(Vector3(0,1.1,-0.5),Vector3.UP)
		detail_camera.fov = 62
		await frames(20)
		await capture("05-ambiente")
		detail_camera.position = Vector3(1.50,1.48,1.14)
		detail_camera.look_at(Vector3(1.02,1.04,0.59),Vector3.UP)
		detail_camera.fov =  46
		await frames(20)
		await capture("06-utensilios")
		detail_camera.position = Vector3(-3.8,1.25,0.1)
		detail_camera.look_at(Vector3(-2.88,0.25,-1.1),Vector3.UP)
		detail_camera.fov = 46
		await frames(20)
		await capture("07-cesto")
	if delivery == "texturas":
		game.player.visible = true
		game.player.visual.visible = true
		game.player.visual.rotation.y = PI
		detail_camera.position = game.player.position+Vector3(0.55,1.22,1.55)
		detail_camera.look_at(game.player.position+Vector3(0,1.04,0),Vector3.UP)
		detail_camera.fov = 38
		await frames(20)
		await capture("05-tecidos")
	report["conditions"] = {"engine":Engine.get_version_info().string,"gpu":RenderingServer.get_video_adapter_name(),"resolution":str(root.size),"vsync":"disabled for this comparison only","renderer":ProjectSettings.get_setting("rendering/renderer/rendering_method")}
	var file := FileAccess.open(folder+"/performance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("REVIEW "+label+": "+JSON.stringify(report))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game.queue_free()
	await frames(3)
	quit()
