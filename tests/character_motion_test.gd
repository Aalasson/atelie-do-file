extends SceneTree
## Testes comportamentais de locomoção, apoio e taxas de atualização.
var player
var world: Node3D
var checks := 0
var failures: Array[String] = []
var reports: Array = []
var steps := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if value:
		print("PASS: "+message)
	else:
		failures.append(message)
		push_error("FAIL: "+message)

func ticks(amount: int) -> void:
	for i in range(amount):
		await physics_frame

func contact(index: int) -> Vector3:
	return player.visual.ankles[index].get_node("ContatoChao").global_position

func add_actor() -> void:
	player = load("res://scenes/personagem.tscn").instantiate()
	player.set_script(load("res://scripts/player.gd"))
	player.position = Vector3(0,0.04,2)
	world.add_child(player)
	player.footstep.connect(func(): steps+=1)
	await ticks(12)
	player.controls_enabled = true
	player.visual.reset_feet()
	await ticks(3)

func motion_case(render_rate: int, physics_rate: int) -> void:
	Engine.max_fps = render_rate
	Engine.physics_ticks_per_second = physics_rate
	await add_actor()
	await physics_frame
	var origin: Vector3 = player.position
	var last_foot := [contact(0),contact(1)]
	var last_planted: Array = player.visual.planted.duplicate()
	var max_slip := 0.0
	var minimum_sole := 1.0
	var max_reach_error := 0.0
	var max_lift := 0.0
	var knee_motion := 0.0
	var feet_samples := 0
	Input.action_press("move_forward")
	for frame in range(physics_rate*2):
		await physics_frame
		for index in range(2):
			var foot: Vector3 = contact(index)
			minimum_sole = minf(minimum_sole,foot.y)
			max_lift = maxf(max_lift,foot.y)
			if last_planted[index] and player.visual.planted[index]:
				var slip := Vector2(foot.x-last_foot[index].x,foot.z-last_foot[index].z).length()
				max_slip = maxf(max_slip,slip)
				feet_samples+=1
			last_foot[index] = foot
			last_planted[index] = player.visual.planted[index]
			knee_motion = maxf(knee_motion,player.visual.knees[index].quaternion.get_angle())
		max_reach_error = maxf(max_reach_error,player.visual.reach_error)
	Input.action_release("move_forward")
	var traveled: float = origin.distance_to(player.position)
	var prefix := "%d FPS / %d Hz: "%[render_rate,physics_rate]
	check(traveled>2.85 and traveled<3.05,prefix+"distância de caminhada coerente em 2 s")
	check(max_slip<0.025,prefix+"pé apoiado desliza menos de 2,5 cm por atualização")
	check(minimum_sole>=-0.003,prefix+"sola não penetra o piso")
	check(max_lift>0.035 and knee_motion>0.3,prefix+"pé levanta e joelho articula")
	check(max_reach_error<0.045,prefix+"alvos permanecem ao alcance das pernas")
	await ticks(physics_rate)
	check(Vector2(player.velocity.x,player.velocity.z).length()<0.001,prefix+"desacelera até parar")
	var resting_steps := steps
	var rest_origin: Vector3 = player.position
	await ticks(physics_rate/2)
	check(steps==resting_steps and player.position.distance_to(rest_origin)<0.001,prefix+"parada não anda nem produz passos")
	reports.append({"render_cap":render_rate,"physics_hz":physics_rate,"distance_2s_m":traveled,"max_stance_slip_per_tick_m":max_slip,"min_sole_y_m":minimum_sole,"max_foot_lift_m":max_lift,"max_reach_error_m":max_reach_error,"stance_samples":feet_samples})
	player.queue_free()
	await ticks(2)

func run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	for action in ["move_left","move_right","move_forward","move_back"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	world = Node3D.new()
	root.add_child(world)
	current_scene = world
	var floor := StaticBody3D.new()
	floor.collision_layer = 2
	floor.position.y = -0.5
	var shape := BoxShape3D.new()
	shape.size = Vector3(30,1,30)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	floor.add_child(collision)
	world.add_child(floor)
	# Primeiro varia renderização mantendo física; depois varia a própria física.
	for rates in [[30,60],[60,60],[120,60],[120,30],[120,120]]:
		await motion_case(rates[0],rates[1])
	var minimum := 10.0
	var maximum := 0.0
	for result in reports:
		minimum = minf(minimum,result.distance_2s_m)
		maximum = maxf(maximum,result.distance_2s_m)
	check(maximum-minimum<0.05,"Variação de distância entre taxas fica abaixo de 5 cm")
	Engine.physics_ticks_per_second = 60
	Engine.max_fps = 120
	await add_actor()
	player.pivot.rotation.y = PI/2
	await physics_frame
	Input.action_press("move_forward")
	await ticks(60)
	Input.action_release("move_forward")
	check(player.position.x< -1.1 and absf(player.position.z-2)<0.1,"Movimento acompanha rotação da câmera")
	await ticks(30)
	player.pivot.rotation.y = 0
	var diagonal_start: Vector3 = player.position
	Input.action_press("move_back")
	Input.action_press("move_right")
	await ticks(60)
	var diagonal_speed: float = Vector2(player.velocity.x,player.velocity.z).length()
	check(absf(diagonal_speed-player.speed)<0.01,"Diagonal respeita velocidade máxima")
	Input.action_release("move_back")
	Input.action_release("move_right")
	await ticks(40)
	var locked_at: Vector3 = player.position
	player.controls_enabled = false
	var locked_steps := steps
	Input.action_press("move_forward")
	await ticks(40)
	Input.action_release("move_forward")
	check(player.position.distance_to(locked_at)<0.001 and steps==locked_steps,"Controles bloqueados mantêm personagem parada")
	var output_folder := "res://evidence/entrega-02"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--evidence-dir="):
			output_folder = argument.trim_prefix("--evidence-dir=")
	DirAccess.make_dir_recursive_absolute(output_folder)
	var file := FileAccess.open(output_folder+"/motion-results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"conditions":{"engine":Engine.get_version_info().string,"gpu":RenderingServer.get_video_adapter_name(),"vsync":"disabled","scene":"isolated character and flat floor"},"samples":reports},"\t"))
	file.close()
	print("MOTION: %d verificações; %d falhas."%[checks,failures.size()])
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	world.queue_free()
	await ticks(3)
	quit(0 if failures.is_empty() else 1)
