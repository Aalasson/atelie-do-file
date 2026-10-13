extends CharacterBody3D
## Movimento no plano da câmera. A malha gira; o corpo de colisão não precisa girar.
signal footstep
@export var speed := 1.55
@export var acceleration := 7.0
@export var deceleration := 10.0
@export var turn_speed := 9.0
var controls_enabled := false
var moving := false
var camera_distance := 3.2
var zoom_target := 3.2
@onready var visual = $Visual
@onready var pivot: Node3D = $CameraPivot
@onready var spring: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D

func _ready() -> void:
	spring.add_excluded_object(get_rid())
	zoom_target = spring.spring_length
	camera_distance = spring.spring_length
	visual.footfall.connect(func(): footstep.emit())

func _physics_process(delta: float) -> void:
	spring.spring_length = lerpf(spring.spring_length,zoom_target,1.0-exp(-12.0*delta))
	var input_vector := Vector2.ZERO
	if controls_enabled:
		input_vector = Input.get_vector("move_left","move_right","move_forward","move_back")
	var direction := Basis(Vector3.UP,pivot.global_rotation.y)*Vector3(input_vector.x,0,input_vector.y)
	var flat := Vector2(velocity.x,velocity.z)
	var desired := Vector2(direction.x,direction.z)*speed
	flat = flat.move_toward(desired,(acceleration if input_vector.length()>0 else deceleration)*delta)
	velocity.x = flat.x
	velocity.z = flat.y
	if not is_on_floor():
		velocity.y -= 9.8*delta
	else:
		velocity.y = -0.1
	if not controls_enabled:
		velocity.x = 0
		velocity.z = 0
	move_and_slide()
	var actual := Vector2(get_real_velocity().x,get_real_velocity().z).length()
	moving = actual>0.12 and is_on_floor() and controls_enabled
	if direction.length()>0.1 and controls_enabled:
		visual.rotation.y = rotate_toward(visual.rotation.y,atan2(-direction.x,-direction.z),turn_speed*delta)
	visual.update_pose(delta,Vector3(get_real_velocity().x,0,get_real_velocity().z),moving,controls_enabled)
	# A personagem desaparece quando a câmera precisa ficar muito perto de seu centro.
	visual.visible = camera.global_position.distance_to(global_position+Vector3.UP*1.4)>0.7

func _process(delta: float) -> void:
	# Recolhe imediatamente para evitar atravessar paredes; retorna suavemente.
	var safe_distance := spring.get_hit_length()
	camera_distance = minf(camera_distance,safe_distance)
	camera_distance = lerpf(camera_distance,safe_distance,1.0-exp(-9.0*delta))
	camera.position.z = camera_distance

func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled or Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		pivot.rotation.y -= event.relative.x*0.003
		pivot.rotation.x = clampf(pivot.rotation.x-event.relative.y*0.003,deg_to_rad(-34),deg_to_rad(8))
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:
			zoom_target = clampf(zoom_target-0.2,1.5,3.5)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
			zoom_target = clampf(zoom_target+0.2,1.5,3.5)
