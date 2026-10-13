extends SceneTree
const G = preload("res://tools/geometry.gd")
func _initialize() -> void:
	var original: Node3D = load("res://scenes/preenchimento.tscn").instantiate()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for child in original.get_children():
		if child is MeshInstance3D:
			st.append_from(child.mesh,0,child.transform)
	var combined := st.commit()
	assert(combined.get_surface_count()==1)
	assert(combined.surface_get_array_len(0)>0)
	var result := Node3D.new()
	result.name = "Preenchimento"
	result.set_script(load("res://scripts/fill.gd"))
	G.mesh(result,"FiosCombinados",combined,G.material(Color("cd6550"),1.0))
	G.save_scene(result,"res://scenes/preenchimento.tscn")
	print("Fios combinados: uma malha por célula, preservando os cilindros e suas normais.")
	result.free()
	original.free()
	quit()
