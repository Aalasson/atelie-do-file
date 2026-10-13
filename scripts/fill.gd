@tool
extends Node3D
## Cena reutilizável: a cor também aparece no editor, antes de executar o jogo.
const Model = preload("res://scripts/challenge.gd")
const ThreadMaterials = preload("res://scripts/thread_materials.gd")
@export_range(0,2) var color_index := 0:
	set(value):
		color_index = value
		if is_node_ready():
			update_material()

func _ready() -> void:
	update_material()

func update_material() -> void:
	var material := ThreadMaterials.get_color(color_index)
	for child in get_children():
		if child is MeshInstance3D:
			child.material_override = material
