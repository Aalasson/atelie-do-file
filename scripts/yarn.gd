@tool
extends Node3D
## Novelo.tscn é instanciado três vezes; cada instância recebe uma cor.
const Model = preload("res://scripts/challenge.gd")
@export_range(0,2) var color_index := 0:
	set(value):
		color_index = value
		if is_node_ready():
			apply_color()
var initial_position := Vector3.ZERO
var initial_rotation := Vector3.ZERO
var ring: MeshInstance3D

func _ready() -> void:
	initial_position = position
	initial_rotation = rotation
	apply_color()
	var shape := TorusMesh.new()
	shape.inner_radius = 0.32
	shape.outer_radius = 0.344
	shape.rings = 32
	shape.ring_segments = 8
	ring = MeshInstance3D.new()
	ring.name = "SelecaoVisual"
	ring.mesh = shape
	var green := StandardMaterial3D.new()
	green.albedo_color = Color("315d45")
	ring.material_override = green
	ring.position.y = -0.28
	ring.visible = color_index==0
	add_child(ring)

func set_selected(selected: bool) -> void:
	ring.visible = selected

func demonstrate(displacement: float, degrees: float, factor: float) -> void:
	var safe_factor := clampf(factor,0.65,1.35)
	position = initial_position+Vector3(0,0.28*(safe_factor-1),clampf(displacement,-0.45,0.45))
	rotation = initial_rotation+Vector3(0,deg_to_rad(clampf(degrees,-180,180)),0)
	scale = Vector3.ONE*safe_factor

func restore() -> void:
	demonstrate(0,0,1)

func apply_color() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Model.COLORS[color_index]
	material.roughness = 1.0
	$Nucleo.material_override = material
	var winding := material.duplicate() as StandardMaterial3D
	winding.albedo_color = material.albedo_color.lightened(0.12)
	for ring_mesh in $FiosEnrolados.get_children():
		ring_mesh.material_override = winding
	$Selecao.set_meta("color",color_index)
