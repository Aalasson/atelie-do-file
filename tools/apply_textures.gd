extends SceneTree
## Atualiza só materiais de cenas existentes, preservando geometria e controles.
const Library = preload("res://tools/material_library.gd")
var visited: Dictionary = {}
var count := 0
var wall_material: ShaderMaterial

func _initialize() -> void:
	wall_material = Library.plaster()
	for path in ["res://scenes/ambiente.tscn","res://scenes/personagem.tscn","res://scenes/bastidor.tscn"]:
		var scene: Node = load(path).instantiate()
		visit(scene,path.ends_with("/personagem.tscn"))
		var packed := PackedScene.new()
		assert(packed.pack(scene) == OK)
		assert(ResourceSaver.save(packed,path) == OK)
		scene.free()
	print("Texturas aplicadas: ",count," materiais compartilhados. Geometria preservada.")
	quit()

func visit(node: Node, character: bool) -> void:
	if node is MeshInstance3D:
		var material: Material = node.material_override
		if material is ShaderMaterial and material.shader:
			var shader_path: String = material.shader.resource_path
			if not visited.has(material.get_instance_id()):
				if shader_path.ends_with("/wood.gdshader"):
					Library.bind_maps(material,"plywood")
					count += 1
				elif shader_path.ends_with("/fabric.gdshader"):
					Library.bind_maps(material,"fabric_pattern_05")
					if character:
						Library.character_fabric(material)
					count += 1
				visited[material.get_instance_id()] = true
			if shader_path.ends_with("/plaster.gdshader"):
				node.material_override = wall_material
		elif material is StandardMaterial3D and material.albedo_color.is_equal_approx(Color("ded9cf")):
			node.material_override = wall_material
	for child in node.get_children():
		visit(child,character)
