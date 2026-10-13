extends SceneTree
var game
var folder: String
var portrait: Camera3D

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
		# Sessão dirigida de captura: garante retomada se outra janela receber foco.
		# O teste de integração separado cobre o comportamento real de perda de foco.
		if game and is_instance_valid(game) and game.paused:
			game.resume_game()

func capture(title: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+"/"+title+".png")

func frame_character(front: bool = true) -> void:
	portrait.global_position = game.player.global_position+Vector3(1.35,1.35,2.6) if front else game.player.global_position+Vector3(2.8,1.25,0.2)
	portrait.look_at(game.player.global_position+Vector3(0,0.92,0),Vector3.UP)
	portrait.make_current()

func run() -> void:
	root.unfocusable = true
	root.mouse_passthrough = true
	await frames(6)
	var args := OS.get_cmdline_user_args()
	var label := args[0] if not args.is_empty() else "depois"
	folder = "res://evidence/entrega-02/"+label
	DirAccess.make_dir_recursive_absolute(folder)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await frames(30)
	game.resume_game()
	game.audio.set_muted(true)
	await frames(10)
	await capture("01-exploracao")
	game.hud.visible = false
	game.player.visual.rotation.y = PI
	portrait = Camera3D.new()
	portrait.fov = 43
	game.add_child(portrait)
	frame_character()
	await frames(35)
	await capture("02-personagem")
	frame_character(false)
	await frames(5)
	await capture("03-perfil")
	# Caminhada real de costas para a bancada, vista pela lateral.
	Input.action_press("move_back")
	for i in range(4):
		await frames(8)
		frame_character(false)
		await capture("04-passo-"+str(i+1))
	Input.action_release("move_back")
	await frames(30)
	game.hud.visible = true
	game.player.position = Vector3(0,0.03,1.68)
	game.player.visual.rotation.y = 0
	game.player.velocity = Vector3.ZERO
	await frames(15)
	game.enter_work()
	await create_timer(0.9).timeout
	await capture("05-bastidor")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game.queue_free()
	await frames(3)
	quit()
