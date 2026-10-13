extends RefCounted
## Ferramentas de modelagem usadas pelo gerador de cenas; não são um motor próprio.
static func material(color: Color, roughness: float = 0.8) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	return result

static func group(parent: Node, title: String) -> Node3D:
	var result := Node3D.new()
	result.name = title
	parent.add_child(result, true)
	return result

static func mesh(parent: Node, title: String, shape: Mesh, surface: Material, at: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	result.name = title
	result.mesh = shape
	result.material_override = surface
	result.position = at
	parent.add_child(result, true)
	return result

static func box(parent: Node, title: String, size: Vector3, at: Vector3, surface: Material) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return mesh(parent, title, shape, surface, at)

static func rod(parent: Node, title: String, a: Vector3, b: Vector3, radius: float, surface: Material) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = a.distance_to(b)
	shape.radial_segments = 8
	shape.rings = 1
	var result := mesh(parent, title, shape, surface, (a+b)*0.5)
	result.quaternion = Quaternion(Vector3.UP, (b-a).normalized())
	return result

static func label(parent: Node, text: String, at: Vector3, font_size: int = 32) -> Label3D:
	var result := Label3D.new()
	result.name = "Rotulo"
	result.text = text
	result.font_size = font_size
	result.pixel_size = 0.0035
	result.modulate = Color("40513d")
	result.outline_size = 0
	result.position = at
	result.rotation_degrees.x = -90
	parent.add_child(result, true)
	return result

static func collider(parent: Node, title: String, shape: Shape3D, at: Vector3, metadata: Dictionary, layer: int = 1) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = title
	body.position = at
	body.collision_layer = layer
	body.collision_mask = 0
	for key in metadata:
		body.set_meta(key, metadata[key])
	parent.add_child(body, true)
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = shape
	body.add_child(collision)
	return body

static func save_scene(node: Node, path: String) -> void:
	assign_owners(node, node)
	var packed := PackedScene.new()
	var result := packed.pack(node)
	assert(result == OK, "Falha ao empacotar " + path)
	assert(ResourceSaver.save(packed, path) == OK, "Falha ao salvar " + path)

static func assign_owners(node: Node, owner_root: Node) -> void:
	for child in node.get_children():
		child.owner = owner_root
		if child.scene_file_path.is_empty():
			assign_owners(child, owner_root)

static func rounded(parent: Node, title: String, size: Vector3, at: Vector3, radius: float, surface: Material) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := size*0.5
	var inner := half-Vector3.ONE*radius
	var faces := [[Vector3.RIGHT,Vector3.BACK,Vector3.UP],[Vector3.LEFT,Vector3.FORWARD,Vector3.UP],[Vector3.UP,Vector3.RIGHT,Vector3.BACK],[Vector3.DOWN,Vector3.RIGHT,Vector3.FORWARD],[Vector3.BACK,Vector3.LEFT,Vector3.UP],[Vector3.FORWARD,Vector3.RIGHT,Vector3.UP]]
	for face in faces:
		var normal: Vector3 = face[0]
		var u: Vector3 = face[1]
		var v: Vector3 = face[2]
		var hu: float = absf(u.dot(half))
		var hv: float = absf(v.dot(half))
		var hn: float = absf(normal.dot(half))
		var us := [-hu,-hu+radius*0.3,-hu+radius,hu-radius,hu-radius*0.3,hu]
		var vs := [-hv,-hv+radius*0.3,-hv+radius,hv-radius,hv-radius*0.3,hv]
		for i in range(5):
			for j in range(5):
				for ij in [Vector2i(i,j),Vector2i(i+1,j),Vector2i(i+1,j+1),Vector2i(i,j),Vector2i(i+1,j+1),Vector2i(i,j+1)]:
					var p: Vector3 = normal*hn+u*us[ij.x]+v*vs[ij.y]
					var n := (p-p.clamp(-inner,inner)).normalized()
					st.set_normal(n)
					st.add_vertex(p.clamp(-inner,inner)+n*radius)
	st.index()
	return mesh(parent,title,st.commit(),surface,at)

static func combine_children(parent: Node3D, title: String, surface: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var found := false
	for child in parent.get_children():
		if child is MeshInstance3D:
			for surface_index in range(child.mesh.get_surface_count()):
				st.append_from(child.mesh,surface_index,child.transform)
			child.free()
			found = true
	if found:
		st.index()
		mesh(parent,title,st.commit(),surface)
