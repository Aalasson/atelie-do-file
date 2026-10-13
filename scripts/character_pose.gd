extends Node3D
## Passos com apoio no mundo e solução analítica de duas articulações por perna.
signal footfall
const THIGH := 0.415
const SHIN := 0.425
const ANKLE_HEIGHT := 0.1005
var initialized := false
var feet: Array[Vector3] = [Vector3.ZERO,Vector3.ZERO]
var foot_yaw := [0.0,0.0]
var planted := [true,true]
var active_foot := -1
var next_foot := 0
var swing_elapsed := 0.0
var swing_duration := 0.22
var swing_start := Vector3.ZERO
var swing_end := Vector3.ZERO
var swing_yaw := 0.0
var blend := 0.0
var breath := 0.0
var previous_origin := Vector3.ZERO
var distance_walked := 0.0
var reach_error := 0.0
@onready var body: Node3D = $Corpo
@onready var torso: Node3D = $Corpo/Tronco
@onready var legs: Array[Node3D] = [$Corpo/PernaE,$Corpo/PernaD]
@onready var knees: Array[Node3D] = [$Corpo/PernaE/Joelho,$Corpo/PernaD/Joelho]
@onready var ankles: Array[Node3D] = [$Corpo/PernaE/Joelho/Tornozelo,$Corpo/PernaD/Joelho/Tornozelo]
@onready var arms: Array[Node3D] = [$Corpo/Tronco/BracoE,$Corpo/Tronco/BracoD]

func rest_anchor(index: int) -> Vector3:
	return global_transform*Vector3(-0.105 if index==0 else 0.105,0,0)

func on_ground(point: Vector3) -> Vector3:
	var query := PhysicsRayQueryParameters3D.create(point+Vector3.UP*0.30,point-Vector3.UP*0.45,2)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	point.y = hit.position.y+ANKLE_HEIGHT if not hit.is_empty() else global_position.y+ANKLE_HEIGHT
	return point

func reset_feet() -> void:
	for index in range(2):
		feet[index] = on_ground(rest_anchor(index))
		foot_yaw[index] = global_rotation.y
		planted[index] = true
	active_foot = -1
	next_foot = 0
	blend = 0
	previous_origin = global_position
	initialized = true

func start_step(index: int, motion: Vector3, walking: bool) -> void:
	active_foot = index
	planted[index] = false
	swing_elapsed = 0
	swing_start = feet[index]
	swing_yaw = foot_yaw[index]
	swing_duration = 0.22 if walking else 0.19
	var target := rest_anchor(index)
	if walking:
		var nominal_speed := float(get_parent().get("speed"))
		target += motion.normalized()*minf(maxf(motion.length(),nominal_speed*0.8)*0.27,0.42)
		# Limita a passada antes de paredes ou pés de móveis.
		var start := rest_anchor(index)+Vector3.UP*0.17
		var query := PhysicsRayQueryParameters3D.create(start,target+Vector3.UP*0.17,2)
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			target = hit.position-motion.normalized()*0.19
			target.y = global_position.y
	swing_end = on_ground(target)

func update_pose(delta: float, motion: Vector3, walking: bool, enabled: bool) -> void:
	if not initialized or global_position.distance_to(previous_origin)>0.8:
		reset_feet()
	previous_origin = global_position
	var horizontal_speed := motion.length()
	var weight := clampf(horizontal_speed/1.55,0,1) if walking and enabled else 0.0
	blend = move_toward(blend,weight,delta*5)
	breath += delta*1.8
	distance_walked += horizontal_speed*delta if walking else 0.0
	body.position.y = lerpf(0.925,0.878,blend)
	torso.position.y = 0.08+sin(breath)*0.0018
	torso.rotation.x = lerpf(torso.rotation.x,-0.035*blend,1-exp(-delta*9))
	if active_foot<0:
		if walking and enabled:
			start_step(next_foot,motion,true)
		else:
			# Depois de parar ou girar, recoloca um pé de cada vez sob o corpo.
			for index in [next_foot,1-next_foot]:
				var target := on_ground(rest_anchor(index))
				if feet[index].distance_to(target)>0.028 or absf(angle_difference(foot_yaw[index],global_rotation.y))>0.16:
					start_step(index,Vector3.ZERO,false)
					break
	if active_foot>=0:
		swing_elapsed += delta
		var t := minf(swing_elapsed/swing_duration,1.0)
		var smooth_t := t*t*(3-2*t)
		feet[active_foot] = swing_start.lerp(swing_end,smooth_t)
		feet[active_foot].y += sin(t*PI)*lerpf(0.035,0.065,blend)
		foot_yaw[active_foot] = lerp_angle(swing_yaw,global_rotation.y,smooth_t)
		if t>=1:
			planted[active_foot] = true
			next_foot = 1-active_foot
			active_foot = -1
			if walking and enabled:
				footfall.emit()
	reach_error = 0.0
	for index in range(2):
		solve_leg(index)
	var relative_left := to_local(feet[0])
	var relative_right := to_local(feet[1])
	var swing := clampf((relative_left.z-relative_right.z)*0.9,-0.36,0.36)*blend
	for index in range(2):
		var side := -1.0 if index==0 else 1.0
		arms[index].rotation.x = lerpf(arms[index].rotation.x,swing if index==0 else -swing,1-exp(-delta*12))
		arms[index].rotation.z = side*(0.07+sin(breath+index)*0.007)
		arms[index].get_node("Cotovelo").rotation.x = lerpf(arms[index].get_node("Cotovelo").rotation.x,0.17+blend*0.20,1-exp(-delta*10))

func solve_leg(index: int) -> void:
	var leg := legs[index]
	var target := body.to_local(feet[index])-leg.position
	var distance := clampf(target.length(),0.08,THIGH+SHIN-0.002)
	var axis := target.normalized()
	var forward := Vector3.FORWARD-axis*Vector3.FORWARD.dot(axis)
	if forward.length_squared()<0.001:
		forward = Vector3.RIGHT
	forward = forward.normalized()
	var along := (THIGH*THIGH-SHIN*SHIN+distance*distance)/(2*distance)
	var bend := sqrt(maxf(THIGH*THIGH-along*along,0.0))
	var joint := axis*along+forward*bend
	leg.quaternion = Quaternion(Vector3.DOWN,joint.normalized())
	var shin_direction := leg.basis.inverse()*(axis*distance-joint)
	knees[index].quaternion = Quaternion(Vector3.DOWN,shin_direction.normalized())
	# Orientação do sapato fica estável enquanto o pé sustenta o corpo.
	ankles[index].global_basis = Basis(Vector3.UP,foot_yaw[index])
	reach_error = maxf(reach_error,ankles[index].global_position.distance_to(feet[index]))
