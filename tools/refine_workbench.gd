extends SceneTree
## Entrega 1: gera recursos salvos, sem processamento de modelagem durante o jogo.
const G = preload("res://tools/geometry.gd")
const Materials = preload("res://tools/material_library.gd")

func _initialize() -> void:
	weave()
	frame()
	yarn()
	print("Entrega 1: trama, bastidor e novelos gerados.")
	quit()

func wood(color: Color, axis: Vector3) -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = load("res://materials/wood.gdshader")
	result.set_shader_parameter("timber",color)
	result.set_shader_parameter("grain_axis",axis)
	Materials.bind_maps(result,"plywood")
	return result

func center(t: float, lane: int, crosswise: bool) -> Vector3:
	var fixed := -0.12+float(lane)*0.06
	var height := cos((t+0.12)/0.06*PI+float(lane)*PI)*0.012
	return Vector3(fixed,-height,t) if crosswise else Vector3(t,height,fixed)

func weave() -> void:
	var node := Node3D.new()
	node.name = "Preenchimento"
	node.set_script(load("res://scripts/fill.gd"))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Cinco fios por direção. Alturas opostas alternam passagem por cima/baixo.
	for crosswise in [false,true]:
		for lane in range(5):
			for segment in range(20):
				for side in range(6):
					for corner in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,0),Vector2i(1,1),Vector2i(0,1)]:
						var t := -0.15+float(segment+corner.x)*0.015
						var angle := float(side+corner.y)/6.0*TAU
						var tangent := (center(t+0.0001,lane,crosswise)-center(t-0.0001,lane,crosswise)).normalized()
						var across := Vector3.RIGHT if crosswise else Vector3.BACK
						var up := tangent.cross(across).normalized()
						var normal := across*cos(angle)+up*sin(angle)
						st.set_normal(normal)
						st.add_vertex(center(t,lane,crosswise)+normal*0.0095)
	st.index()
	var material := G.material(Color("d47b63"),0.95)
	var woven := G.mesh(node,"FiosCombinados",st.commit(),material)
	# A consulta de sombra dos fios é desativada para evitar centenas de pequenos
	# auto-sombreamentos instáveis. A moldura e objetos maiores projetam sombras.
	woven.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	G.save_scene(node,"res://scenes/preenchimento.tscn")
	node.free()

func frame() -> void:
	var node: Node3D = load("res://scenes/bastidor.tscn").instantiate()
	var old_frame := node.get_node("Moldura")
	old_frame.free()
	var border := G.group(node,"Moldura")
	var horizontal := wood(Color("9e7955"),Vector3.RIGHT)
	var vertical := wood(Color("b6946e"),Vector3.BACK)
	for z in [-1.335,1.335]:
		G.rounded(border,"Travessa",Vector3(2.83,0.18,0.16),Vector3(0,0,z),0.012,horizontal)
	for x in [-1.335,1.335]:
		G.rounded(border,"Lateral",Vector3(0.16,0.18,2.506),Vector3(x,0,0),0.012,vertical)
	var brass := G.material(Color("826842"),0.48)
	brass.metallic = 0.48
	var screws := G.group(border,"Fixacoes")
	var slots := G.group(border,"Fendas")
	var feet := G.group(border,"ApoiosFeltro")
	var dark := G.material(Color("493d2d"),0.9)
	var felt := G.material(Color("646457"),1.0)
	for x in [-1.335,1.335]:
		for z in [-1.335,1.335]:
			var screw := CylinderMesh.new()
			screw.top_radius = 0.021
			screw.bottom_radius = 0.021
			screw.height = 0.009
			screw.radial_segments = 12
			screw.rings = 1
			G.mesh(screws,"Cabeca",screw,brass,Vector3(x,0.094,z))
			G.rod(slots,"Ranhura",Vector3(x-0.012,0.099,z),Vector3(x+0.012,0.099,z),0.0018,dark)
			G.rounded(feet,"Apoio",Vector3(0.18,0.035,0.18),Vector3(x,-0.1075,z),0.006,felt)
	G.combine_children(screws,"Cabecas",brass)
	G.combine_children(slots,"Ranhuras",dark)
	G.combine_children(feet,"Feltro",felt)
	# Laçadas ligam a malha à moldura. Detalhe didático, sem padrão tradicional.
	var ties := G.group(border,"Amarracoes")
	var cotton := G.material(Color("cfc1a5"),0.96)
	for vertical_side in [false,true]:
		for sign_value in [-1.0,1.0]:
			for i in range(9):
				var at := -1.24+float(i)*0.31
				var points := [Vector3(at,0.018,sign_value*1.22),Vector3(at,0.101,sign_value*1.265),Vector3(at,0.101,sign_value*1.423),Vector3(at,-0.098,sign_value*1.423),Vector3(at,-0.098,sign_value*1.27)]
				for j in range(points.size()-1):
					var a: Vector3 = points[j]
					var b: Vector3 = points[j+1]
					if vertical_side:
						a = Vector3(a.z,a.y,a.x)
						b = Vector3(b.z,b.y,b.x)
					G.rod(ties,"Laco",a,b,0.0045,cotton)
	G.combine_children(ties,"Cordas",cotton)
	G.save_scene(node,"res://scenes/bastidor.tscn")
	node.free()

func yarn() -> void:
	var node: Node3D = load("res://scenes/novelo.tscn").instantiate()
	# Vinte e sete voltas continuam volumétricas, reunidas em uma malha.
	G.combine_children(node.get_node("FiosEnrolados"),"FioContinuo",G.material(Color("dfcab0"),0.94))
	G.save_scene(node,"res://scenes/novelo.tscn")
	node.free()
