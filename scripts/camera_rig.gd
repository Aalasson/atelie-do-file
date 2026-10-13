extends Node3D
## Pivô lógico de órbita. O alvo, os ângulos e a distância definem a posição.
signal clicked(screen_position: Vector2)
signal view_changed(mode: String)
@onready var camera: Camera3D = $Camera3D
var mode := "work"
var enabled := false
var inspection := false
var target := Vector3(-0.1,1.35,0)
var yaw := 0.54
var pitch := 0.50
var distance := 10.9
var dragging := false
var moved := false
var pressed_at := Vector2.ZERO
var tween: Tween
var scene_rect := Rect2(0,88,1048,770)

func _ready() -> void:
	choose_view("work",true)

func choose_view(next_mode: String, immediate: bool = false) -> void:
	mode = next_mode
	cancel_tween()
	var goal_target := Vector3(-0.078,1.0452,0.104) if mode=="work" else Vector3(-0.1,1.35,0)
	var goal_yaw := 0.0 if mode=="work" else 0.54
	var goal_pitch := 1.36 if mode=="work" else 0.50
	var goal_distance := 3.12 if mode=="work" else 3.12
	if immediate:
		target = goal_target
		yaw = goal_yaw
		pitch = goal_pitch
		distance = goal_distance
	else:
		tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(self,"target",goal_target,0.8)
		tween.tween_property(self,"yaw",goal_yaw,0.8)
		tween.tween_property(self,"pitch",goal_pitch,0.8)
		tween.tween_property(self,"distance",goal_distance,0.8)
	update_camera()
	view_changed.emit(mode)

func cancel_tween() -> void:
	if tween and tween.is_valid():
		tween.kill()

func set_inspection(active: bool) -> void:
	if inspection != active:
		inspection = active
		dragging = false
		choose_view("work", true)

func _process(delta: float) -> void:
	if enabled:
		update_camera()

func update_camera() -> void:
	camera.position = target+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance
	camera.look_at(target)
	# Preserva a vista inclinada da bancada, com os objetos ao redor do bastidor.
	var viewport_size := get_viewport().get_visible_rect().size
	var area_height := maxf(180.0, minf(scene_rect.size.y, scene_rect.size.x / 1.55))
	var half_span := 1.75 * viewport_size.y / area_height * 0.5
	camera.fov = rad_to_deg(2.0 * atan(half_span / 3.12))
	var scale_at_target := distance * tan(deg_to_rad(camera.fov) * 0.5) / viewport_size.y
	var center := scene_rect.get_center()
	camera.h_offset = scale_at_target * (viewport_size.x - center.x * 2.0)
	camera.v_offset = scale_at_target * (center.y * 2.0 - viewport_size.y)

func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventMouseButton and scene_rect.has_point(event.position):
		if event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
			cancel_tween()
			dragging = true
			moved = false
			pressed_at = event.position
		if inspection and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			cancel_tween()
			var multiplier := 0.9 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.1
			distance = clampf(distance*multiplier,2.6,3.8)

func _input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventMouseMotion and dragging:
		if event.position.distance_to(pressed_at)>6:
			moved = true
		if moved and inspection:
			yaw = clampf(yaw-event.relative.x*0.006,-0.35,0.35)
			pitch = clampf(pitch+event.relative.y*0.006,1.05,1.48)
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed and dragging:
		dragging = false
		if not moved and event.position.distance_to(pressed_at)<6 and scene_rect.has_point(event.position):
			clicked.emit(event.position)

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		dragging = false
