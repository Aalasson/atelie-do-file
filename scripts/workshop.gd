extends Node3D
## Coordena as partes. O modelo não depende da UI e o bastidor só representa dados.
const Model = preload("res://scripts/challenge.gd")
const G = preload("res://tools/geometry.gd")
var model := Model.new()
var selected_color := 0
var queued_click := Vector2(-1,-1)
var axes: Node3D
@onready var board = $Bastidor
@onready var rig = $CameraRig
@onready var hud = $Interface
@onready var audio = $Audio
@onready var yarns: Array = [$Novelos/Coral,$Novelos/Azul,$Novelos/Amarelo]
@onready var sun: DirectionalLight3D = $Ambiente/Sol

func _ready() -> void:
	board.refresh(model)
	rig.clicked.connect(func(at: Vector2): queued_click=at)
	rig.view_changed.connect(hud.set_view)
	hud.action_requested.connect(handle_action)
	hud.set_view("explore")
	axes = Node3D.new()
	axes.name = "EixosDemonstracao"
	axes.position = Vector3(-0.15,2.13,0.2)
	add_child(axes)
	for data in [[Vector3.RIGHT,Color("c8453f"),"X"],[Vector3.UP,Color("368c45"),"Y"],[Vector3.BACK,Color("3b69b8"),"Z"]]:
		G.rod(axes,data[2],Vector3.ZERO,data[0]*1.45,0.015,G.material(data[1]))
		var label := G.label(axes,data[2],data[0]*1.55,42)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = data[1]
	axes.visible = false

func handle_action(action: String, value: Variant = null) -> void:
	if action.begins_with("color_"):
		select_color(int(value))
		return
	match action:
		"erase":
			select_color(0 if selected_color==-1 else -1)
		"verify":
			verify()
		"reset":
			model.reset()
			refresh()
			board.show_hint()
			hud.set_status("Escolha uma cor.","Uma nova trama!")
		"hint":
			give_hint()
		"solution":
			model.showing_solution = not model.showing_solution
			refresh()
			board.show_hint()
			hud.set_status("Pinte do outro lado da linha verde.","Sua vez!")
		"explore", "work":
			rig.choose_view(action)
		"home":
			rig.choose_view(rig.mode)
		"sound":
			audio.set_muted(not audio.muted)
			hud.set_sound(audio.muted)
		"transform":
			yarns[0].demonstrate(value.x,value.y,value.z)
		"restore_yarn":
			yarns[0].restore()
			hud.reset_sliders()
		"axes":
			axes.visible = bool(value) and hud.cg_open
		"shadows":
			sun.shadow_enabled = bool(value)
		"cg_visible":
			axes.visible = bool(value) and hud.axes_check.button_pressed
			sun.shadow_enabled = hud.shadow_check.button_pressed if value else true

func select_color(index: int) -> void:
	selected_color = index
	hud.set_color(index)
	for i in range(yarns.size()):
		yarns[i].set_selected(index==i)
	hud.set_status("Clique no quadradinho que quer apagar." if index==-1 else "Pinte do outro lado da linha verde.","Vamos apagar?" if index==-1 else "Fio %s na mão!"%Model.COLOR_NAMES[index])

func refresh() -> void:
	board.refresh(model)
	board.show_highlight()
	hud.set_solution(model.showing_solution)

func verify() -> void:
	if model.showing_solution:
		return
	var mistakes: Array[Vector2i] = model.mistakes()
	if mistakes.is_empty():
		board.show_hint()
		hud.set_status("Você conseguiu! Os dois lados combinam.","Trama concluída!")
		audio.play_feedback(true)
	else:
		give_hint()

func give_hint() -> void:
	var mistakes: Array[Vector2i] = model.mistakes()
	if mistakes.is_empty():
		hud.set_status("Sua trama está pronta. Clique em Conferir.","Pronta para conferir!")
		return
	var first: Vector2i = mistakes[0]
	board.show_hint(first.x,first.y)
	var clue := "Os dois devem ficar vazios." if model.expected(first.x,first.y)<0 else "Use a mesma cor nos dois."
	hud.set_status("Veja estes dois quadradinhos. %s" % clue,"Vamos olhar este par?","hint")

func paint(row: int, column: int) -> void:
	if model.paint(row,column,selected_color):
		if hud.has_method("set_completed"):
			hud.set_completed(false)
		board.refresh(model)
		board.show_hint()
		audio.play_feedback()
		hud.set_status("Clique no quadradinho que quer apagar." if selected_color==-1 else "Pinte do outro lado da linha verde.","Fio removido." if selected_color==-1 else "Fio %s colocado!"%Model.COLOR_NAMES[selected_color])

func pick(screen_position: Vector2) -> Dictionary:
	var camera: Camera3D = rig.camera
	var origin := camera.project_ray_origin(screen_position)
	var end := origin+camera.project_ray_normal(screen_position)*30
	var query := PhysicsRayQueryParameters3D.create(origin,end,1)
	return get_world_3d().direct_space_state.intersect_ray(query)

func activate_hit(hit: Dictionary) -> void:
	if hit.is_empty() or hud.piece_open or hud.cg_open or model.showing_solution:
		return
	var body: Node = hit.collider
	if body is Node3D and not body.is_visible_in_tree():
		return
	if body.get_meta("kind","")=="yarn":
		select_color(body.get_meta("color"))
	elif body.get_meta("kind","")=="cell":
		paint(body.get_meta("row"),body.get_meta("column"))

func _physics_process(_delta: float) -> void:
	rig.scene_rect = hud.scene_rect
	# Consultas ao espaço físico acontecem aqui, nunca dentro do evento de mouse.
	if queued_click.x>=0:
		activate_hit(pick(queued_click))
		queued_click = Vector2(-1,-1)
	var pointer := get_viewport().get_mouse_position()
	if not hud.scene_rect.has_point(pointer) or model.showing_solution or rig.dragging or hud.piece_open or hud.cg_open:
		board.show_highlight()
		hud.hover_label.text = "Arraste para observar sua peça. Esc para voltar." if hud.piece_open else "Clique para tecer · arraste para ajustar a vista · Esc para sair"
		if model.showing_solution and not hud.piece_open:
			hud.hover_label.text = "Observe o exemplo. Sua tentativa está guardada."
		if hud.cg_open:
			hud.hover_label.text = "Experimente os controles e observe o novelo coral."
		return
	var hit := pick(pointer)
	if not hit.is_empty() and hit.collider.get_meta("kind","")=="cell":
		var row: int = hit.collider.get_meta("row")
		var column: int = hit.collider.get_meta("column")
		board.show_highlight(row,column)
		hud.hover_label.text = "Linha %d · coluna %d — %s"%[row+1,column+1,"apagar" if selected_color==-1 else "tecer com fio "+Model.COLOR_NAMES[selected_color]]
	else:
		board.show_highlight()
		hud.hover_label.text = "Clique para tecer · arraste para ajustar a vista · Esc para sair"
