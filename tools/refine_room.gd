extends SceneTree
const G = preload("res://tools/geometry.gd")

func _initialize() -> void:
	var room: Node3D = load("res://scenes/ambiente.tscn").instantiate()
	preload("res://tools/room_finishing.gd").new().apply(room)
	G.save_scene(room,"res://scenes/ambiente.tscn")
	room.free()
	# Estruturas estáticas podem ser agrupadas; as 64 colisões ficam individuais.
	var frame: Node3D = load("res://scenes/bastidor.tscn").instantiate()
	for title in ["Malha","EixoSimetria"]:
		var group := frame.get_node(title)
		var material: Material = group.get_child(0).material_override
		G.combine_children(group,"FiosCombinados",material)
	G.save_scene(frame,"res://scenes/bastidor.tscn")
	frame.free()
	print("Entrega 3: ambiente, utensílios, iluminação e agrupamento estático salvos.")
	quit()
