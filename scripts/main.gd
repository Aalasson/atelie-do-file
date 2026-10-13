extends "res://scripts/workshop.gd"
## Estados: explorar, transição e trabalhar. Pausa/foco são uma camada separada.
enum Mode {EXPLORE, TRANSITION, WORK}
var mode: Mode = Mode.EXPLORE
var paused := false
var can_interact := false
var request_interaction := false
var transition: Tween
var transition_serial := 0
var exploration_hint: Label
var pause_panel: Control
var resume_button: Button
var hud_explore: Control
var intro_label: Label
var pause_title: Label
var volume_slider: HSlider
var help_return := ""
var quit_return := ""
var reset_return := ""
@onready var player = $Personagem
@onready var transition_camera: Camera3D = $TransitionCamera
@onready var station: Marker3D = $PontoTrabalho

func _ready() -> void:
	super._ready()
	hud.workspace_changed.connect(refresh_work_view)
	configure_input()
	axes.position *= 0.52
	axes.scale = Vector3.ONE*0.52
	create_exploration_hud()
	player.footstep.connect(func(): audio.play_step(player.global_position))
	player.camera.make_current()
	rig.enabled = false
	set_work_ui(false)
	# Um clique inicial evita capturar o mouse sem uma ação do jogador.
	pause_game("Bem-vinda ao ateliê",true)

func configure_input() -> void:
	var actions := {"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"move_forward":[KEY_W,KEY_UP],"move_back":[KEY_S,KEY_DOWN]}
	for action in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in actions[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action,event)

func create_exploration_hud() -> void:
	hud_explore = Control.new()
	hud_explore.name = "Exploracao"
	hud_explore.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.root_control.add_child(hud_explore)
	hud_explore.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_label = hud.feedback_label
	exploration_hint = hud.text(hud_explore,"",21,true)
	exploration_hint.add_theme_stylebox_override("normal",hud.style(hud.PAPER))
	exploration_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exploration_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	exploration_hint.offset_left = 24
	exploration_hint.offset_right = -24
	exploration_hint.offset_top = -90
	exploration_hint.offset_bottom = -24
	exploration_hint.add_theme_color_override("font_color",Color("263d30"))
	pause_panel = hud.modal
	pause_title = hud.pause_title
	resume_button = hud.buttons.start
	volume_slider = hud.volume_slider
	volume_slider.set_value_no_signal(audio.level)
	hud.music_slider.set_value_no_signal(audio.music_level)
	hud.root_control.move_child(hud.modal,-1)

func set_work_ui(active: bool) -> void:
	hud.set_work(active)
	if hud_explore:
		hud_explore.visible = not active and mode!=Mode.TRANSITION

func refresh_work_view() -> void:
	rig.scene_rect = hud.scene_rect
	rig.set_inspection(hud.cg_open or hud.piece_open)

func handle_action(action: String,value: Variant = null) -> void:
	if action in ["sound_menu", "options_menu"]:
		hud.open_modal("sound" if action=="sound_menu" else "options")
		return
	if action in ["sound_back", "options_back"]:
		hud.open_modal("pause")
		return
	if action=="welcome":
		pause_game()
		hud.open_modal("welcome")
		return
	if action in ["sound","pause_sound"]:
		super.handle_action("sound",value)
		return
	if action=="volume":
		audio.set_level(float(value))
		return
	if action=="music_volume":
		audio.set_music_level(float(value))
		return
	if action in ["start","resume"]:
		resume_game()
		return
	if action=="pause":
		pause_game()
		return
	if action in ["help","welcome_help","pause_help"]:
		help_return = hud.modal_kind
		pause_game()
		hud.set_guide(0 if mode==Mode.EXPLORE else 1)
		hud.open_modal("help")
		return
	if action in ["help_prev","help_next","help_close"]:
		if action=="help_close" or (action=="help_next" and hud.guide_page==2):
			close_help()
		else:
			hud.set_guide(hud.guide_page+(-1 if action=="help_prev" else 1))
		return
	if action in ["welcome_quit","pause_quit"]:
		quit_return = hud.modal_kind
		hud.open_modal("quit")
		return
	if action=="quit_cancel":
		hud.open_modal(quit_return if not quit_return.is_empty() else "pause")
		return
	if action=="quit_confirm":
		get_tree().quit()
		return
	if action=="reset_cancel":
		if reset_return.is_empty():
			resume_game()
		else:
			hud.open_modal(reset_return)
		return
	if action=="success_close":
		resume_game()
		return
	if action=="reset_confirm":
		resume_game()
		super.handle_action("reset")
		hud.set_completed(false)
		return
	if action in ["success_piece","success_explore"]:
		resume_game()
		if action=="success_piece":
			hud.set_piece(true)
		else:
			leave_work()
		return
	if action=="explore" and mode==Mode.WORK:
		if paused:
			resume_game()
		leave_work()
		return
	if mode!=Mode.WORK:
		return
	if action=="reset":
		reset_return = hud.modal_kind
		pause_game()
		hud.open_modal("reset")
		return
	if action in ["solution", "back_solution"]:
		if paused:
			resume_game()
		hud.set_cg(false)
		hud.set_piece(false)
		super.handle_action("solution")
		return
	if action in ["cg","close_cg"]:
		if paused:
			resume_game()
		hud.set_piece(false)
		hud.set_cg(not hud.cg_open if action=="cg" else false)
		return
	if paused:
		return
	if action in ["piece","back_piece"]:
		hud.set_piece(action=="piece")
		return
	if action in ["home","work"]:
		rig.choose_view("work")
		return
	super.handle_action(action,value)

func close_help() -> void:
	if help_return.is_empty():
		resume_game()
	else:
		hud.open_modal(help_return)

func verify() -> void:
	if not model.showing_solution and model.mistakes().is_empty():
		hud.set_completed(true)
		pause_game()
		hud.open_modal("success")
		# O som de conclusão acompanha esta tela; a personagem continua parada.
		audio.suspend(false)
	# O coordenador emite a conquista uma única vez, após preparar o estado de áudio.
	super.verify()

func interaction_available() -> bool:
	if player.global_position.distance_to(station.global_position)>0.66:
		return false
	var origin: Vector3 = player.global_position+Vector3.UP*1.35
	var destination: Vector3 = station.global_position+Vector3(0,1.35,-0.35)
	var query := PhysicsRayQueryParameters3D.create(origin,destination,2)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _physics_process(delta: float) -> void:
	player.controls_enabled = mode==Mode.EXPLORE and not paused
	if paused:
		queued_click = Vector2(-1,-1)
		board.show_highlight()
		return
	if mode==Mode.WORK:
		super._physics_process(delta)
		return
	queued_click = Vector2(-1,-1)
	board.show_highlight()
	if mode==Mode.EXPLORE:
		can_interact = interaction_available()
		exploration_hint.text = "E — Começar minha trama" if can_interact else "WASD ou setas: andar    ·    Mouse: olhar    ·    Esc: pausa e ajuda"
		intro_label.text = "Você encontrou o bastidor!" if can_interact else "Encontre a mesa do ateliê."
		if request_interaction:
			request_interaction = false
			if can_interact:
				enter_work()

func enter_work() -> void:
	if mode!=Mode.EXPLORE or paused or not interaction_available():
		return
	player.controls_enabled = false
	player.velocity = Vector3.ZERO
	model.showing_solution = false
	refresh()
	hud.layout()
	rig.scene_rect = hud.scene_rect
	rig.choose_view("work",true)
	rig.update_camera()
	blend_camera(player.camera,rig.camera,true)
	audio.play_transition(true)

func leave_work() -> void:
	if mode!=Mode.WORK:
		return
	hud.set_cg(false)
	hud.set_piece(false)
	model.showing_solution = false
	refresh()
	rig.enabled = false
	rig.dragging = false
	blend_camera(rig.camera,player.camera,false)
	audio.play_transition(false)

func blend_camera(from: Camera3D,to: Camera3D,entering: bool) -> void:
	mode = Mode.TRANSITION
	audio.set_working(entering)
	transition_serial += 1
	var serial := transition_serial
	queued_click = Vector2(-1,-1)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_work_ui(false)
	transition_camera.global_transform = from.get_camera_transform()
	transition_camera.h_offset = 0
	transition_camera.fov = from.fov
	transition_camera.make_current()
	if transition and transition.is_valid():
		transition.kill()
	var start_transform := from.get_camera_transform()
	var end_transform := to.get_camera_transform()
	var start_fov := from.fov
	var end_fov := to.fov
	transition = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	transition.tween_method(func(weight: float):
		var orientation := start_transform.basis.get_rotation_quaternion().slerp(end_transform.basis.get_rotation_quaternion(),weight)
		transition_camera.global_transform = Transform3D(Basis(orientation),start_transform.origin.lerp(end_transform.origin,weight))
		transition_camera.fov = lerpf(start_fov,end_fov,weight),0.0,1.0,0.7)
	transition.tween_callback(func():
		if serial!=transition_serial:
			return
		mode = Mode.WORK if entering else Mode.EXPLORE
		to.make_current()
		rig.enabled = entering and not paused
		set_work_ui(entering)
		if entering:
			hud.set_view("work")
		player.controls_enabled = not entering and not paused
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if entering or paused else Input.MOUSE_MODE_CAPTURED)

func pause_game(title: String = "Uma pausa?",initial: bool = false) -> void:
	paused = true
	player.controls_enabled = false
	player.velocity = Vector3.ZERO
	rig.enabled = false
	rig.dragging = false
	queued_click = Vector2(-1,-1)
	request_interaction = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.open_modal("welcome" if initial else "pause")
	if initial:
		hud_explore.visible = false
	pause_title.text = title
	resume_button = hud.buttons.start if initial else hud.buttons.resume
	audio.suspend(true)

func resume_game() -> void:
	paused = false
	hud.close_modal()
	set_work_ui(mode==Mode.WORK)
	player.controls_enabled = mode==Mode.EXPLORE
	rig.enabled = mode==Mode.WORK
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mode==Mode.EXPLORE else Input.MOUSE_MODE_VISIBLE
	audio.suspend(false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode==KEY_ESCAPE or event.keycode==KEY_ESCAPE:
			if paused:
				if hud.modal_kind=="help":
					close_help()
				elif hud.modal_kind=="quit":
					handle_action("quit_cancel")
				elif hud.modal_kind in ["sound", "options"]:
					hud.open_modal("pause")
				elif hud.modal_kind=="reset":
					handle_action("reset_cancel")
				else:
					resume_game()
			elif hud.piece_open:
				hud.set_piece(false)
			elif hud.cg_open:
				hud.set_cg(false)
			elif model.showing_solution:
				handle_action("back_solution")
			else:
				pause_game()
			get_viewport().set_input_as_handled()
		elif (event.physical_keycode==KEY_E or event.keycode==KEY_E) and mode==Mode.EXPLORE and not paused:
			request_interaction = true

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT and is_node_ready():
		if not paused:
			pause_game("Vamos continuar quando você voltar")
		audio.suspend(true, true)
