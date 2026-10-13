extends RefCounted
## Entrega 3: acabamento salvo na cena, sem gerar objetos durante a partida.
const G = preload("res://tools/geometry.gd")
const Materials = preload("res://tools/material_library.gd")
var wood: ShaderMaterial
var cloth: ShaderMaterial
var brass: StandardMaterial3D
var details: Node3D

func apply(room: Node3D) -> void:
	if room.has_node("AcabamentoEntrega3"):
		return
	wood = ShaderMaterial.new()
	wood.shader = load("res://materials/wood.gdshader")
	wood.set_shader_parameter("timber",Color("9b7959"))
	Materials.bind_maps(wood,"plywood")
	cloth = ShaderMaterial.new()
	cloth.shader = load("res://materials/fabric.gdshader")
	cloth.set_shader_parameter("fabric_color",Color("dfd3b7"))
	Materials.bind_maps(cloth,"fabric_pattern_05")
	brass = G.material(Color("9f8459"),0.38)
	brass.metallic = 0.65
	details = G.group(room,"AcabamentoEntrega3")
	floor_tiles(room)
	walls()
	window(room)
	stool(room)
	shelf(room)
	basket()
	scissors()
	wall_piece()
	lighting(room)

func ring(parent: Node3D, title: String, radius: float, thickness: float, at: Vector3, surface: Material) -> MeshInstance3D:
	var shape := TorusMesh.new()
	shape.inner_radius = radius-thickness
	shape.outer_radius = radius+thickness
	shape.rings = 32
	shape.ring_segments = 8
	return G.mesh(parent,title,shape,surface,at)

func cylinder(parent: Node, title: String, radius: float, height: float, at: Vector3, surface: Material) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 24
	shape.rings = 1
	return G.mesh(parent,title,shape,surface,at)

func floor_tiles(room: Node3D) -> void:
	# Sete lotes estáticos, salvos também no gerador headless. A base física
	# fica intacta. MultiMesh perdia seus buffers no renderizador dummy do gerador.
	var transforms: Array[Transform3D] = []
	for child in room.get_children():
		if child is MeshInstance3D and child.name.begins_with("Ladrilho"):
			transforms.append(child.transform)
			child.free()
	var base_material := G.material(Color("bca48e"),0.86)
	var sample := G.rounded(details,"MoldeLadrilho",Vector3(0.736,0.018,0.736),Vector3.ZERO,0.003,base_material)
	var shape: Mesh = sample.mesh
	sample.free()
	var tiles := G.group(details,"Ladrilhos")
	for color in range(7):
		var material := G.material(Color("bca48e").lightened(float(color)*0.012),0.86)
		var batch := G.group(tiles,"Lote%d"%color)
		for i in range(transforms.size()):
			if (i*17)%7==color:
				var tile := G.mesh(batch,"Ladrilho",shape,material)
				tile.transform = transforms[i]
		G.combine_children(batch,"Piso",material)
		batch.get_child(0).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	room.get_node("BasePiso").material_override = G.material(Color("998a74"),0.95)

func walls() -> void:
	var panel := G.material(Color("839c8b"),0.94)
	var trim := G.material(Color("bcc6b0"),0.82)
	var group := G.group(details,"FaixaParedes")
	for x in [-4.392,4.392]:
		G.box(group,"Faixa",Vector3(0.025,0.89,10.75),Vector3(x,0.56,0.975),panel)
		G.rounded(group,"Friso",Vector3(0.045,0.045,10.75),Vector3(x,1.02,0.975),0.009,trim)
		G.rounded(group,"Sanca",Vector3(0.10,0.10,10.75),Vector3(x,3.34,0.975),0.015,trim)
	G.box(group,"FaixaFundo",Vector3(8.76,0.89,0.025),Vector3(0,0.56,-4.392),panel)
	G.rounded(group,"FrisoFundo",Vector3(8.76,0.045,0.045),Vector3(0,1.02,-4.392),0.009,trim)
	G.rounded(group,"SancaFundo",Vector3(8.76,0.10,0.10),Vector3(0,3.34,-4.392),0.015,trim)
	for data in [Vector2(-2.75,3.25),Vector2(2.35,4.05)]:
		G.box(group,"FaixaEntrada",Vector3(data.y,0.89,0.025),Vector3(data.x,0.56,6.392),panel)
		G.rounded(group,"FrisoEntrada",Vector3(data.y,0.045,0.045),Vector3(data.x,1.02,6.37),0.009,trim)

func window(room: Node3D) -> void:
	var original := room.get_node("Janela")
	var glass: MeshInstance3D = original.get_node("Vidro")
	var view := ShaderMaterial.new()
	view.shader = load("res://materials/window_view.gdshader")
	glass.material_override = view
	# Ferragens, caixilho com espessura e pequenos encaixes.
	var hardware := G.group(details,"FerragensJanela")
	for x in [-3.48,-1.42]:
		for y in [1.35,2.55]:
			G.rounded(hardware,"Dobradica",Vector3(0.055,0.13,0.035),Vector3(x,y,-4.35),0.008,brass)
	G.rounded(hardware,"Fecho",Vector3(0.16,0.025,0.035),Vector3(-2.45,1.98,-4.33),0.006,brass)
	G.combine_children(hardware,"Ferragens",brass)
	var plant := G.group(details,"PlantaPeitoril")
	plant.position = Vector3(-3.24,1.115,-4.25)
	var clay := G.material(Color("b47052"),0.9)
	var pot := CylinderMesh.new()
	pot.bottom_radius = 0.063
	pot.top_radius = 0.086
	pot.height = 0.15
	pot.radial_segments = 24
	G.mesh(plant,"Vaso",pot,clay,Vector3(0,0.075,0))
	ring(plant,"BordaVaso",0.082,0.009,Vector3(0,0.15,0),clay)
	cylinder(plant,"Terra",0.075,0.009,Vector3(0,0.149,0),G.material(Color("554737"),1.0))
	var leaves := G.group(plant,"Folhagem")
	var green := G.material(Color("497b5e"),0.87)
	for i in range(9):
		var angle := float(i)*2.4
		var height := 0.16+float(i%3)*0.035
		var end := Vector3(cos(angle)*0.11,0.17+height,sin(angle)*0.10)
		G.rod(leaves,"Caule",Vector3(0,0.15,0),end,0.003,green)
		var leaf := SphereMesh.new()
		leaf.radius = 0.5
		leaf.height = 1.0
		leaf.radial_segments = 12
		leaf.rings = 6
		var item := G.mesh(leaves,"Folha",leaf,green,end)
		item.scale = Vector3(0.064,0.12,0.015)
		item.rotation = Vector3(0.5,angle,-0.3)
	G.combine_children(leaves,"FolhasECaules",green)

func stool(room: Node3D) -> void:
	var seat := room.get_node("Banqueta")
	var bars := G.group(seat,"Travessas")
	for side in [-1.0,1.0]:
		G.rod(bars,"Apoio",Vector3(-0.163,0.23,side*0.163),Vector3(0.163,0.23,side*0.163),0.018,wood)
		G.rod(bars,"Apoio",Vector3(side*0.163,0.20,-0.163),Vector3(side*0.163,0.20,0.163),0.018,wood)
	G.combine_children(bars,"TravessasUnidas",wood)

func shelf(room: Node3D) -> void:
	var shelf_node := room.get_node("Estante")
	# Troca as esferas de reserva por núcleos e voltas de fio, reunidos por cor.
	var yarn_mesh: Mesh
	var yarn_scene: Node3D = load("res://scenes/novelo.tscn").instantiate()
	yarn_mesh = yarn_scene.get_node("FiosEnrolados/FioContinuo").mesh
	yarn_scene.free()
	for child in shelf_node.get_children():
		if child is MeshInstance3D and child.name.begins_with("NoveloGuardado"):
			var material: Material = child.material_override
			var winding := G.mesh(shelf_node,"FiosReserva",yarn_mesh,material,child.position)
			winding.scale = Vector3.ONE*0.30
			child.scale *= 0.90
	var boxes := G.group(details,"EtiquetasEstante")
	for z in [-0.6,0.35]:
		var label := Label3D.new()
		label.text = "FIOS" if z<0 else "TECIDOS"
		label.font_size = 28
		label.pixel_size = 0.002
		label.modulate = Color("f2e3c7")
		label.outline_size = 0
		label.position = Vector3(3.70,0.36,-1.4+z)
		label.rotation.y = -PI/2
		boxes.add_child(label)
	var folded := G.group(details,"PanosLaterais")
	for i in range(3):
		var fabric := cloth.duplicate() as ShaderMaterial
		fabric.set_shader_parameter("fabric_color",[Color("c9b694"),Color("8da294"),Color("b77962")][i])
		G.rounded(folded,"PanoDobrado",Vector3(0.44,0.05,0.58),Vector3(3.91,1.895+i*0.049,-1.1),0.018,fabric)

func basket() -> void:
	var basket_node := G.group(details,"Cesto")
	basket_node.position = Vector3(-2.88,0.015,-1.1)
	var wicker := wood.duplicate() as ShaderMaterial
	wicker.set_shader_parameter("timber",Color("af885b"))
	wicker.set_shader_parameter("grain_axis",Vector3.UP)
	var shell := CylinderMesh.new()
	shell.top_radius = 0.297
	shell.bottom_radius = 0.239
	shell.height = 0.43
	shell.cap_top = false
	shell.radial_segments = 40
	G.mesh(basket_node,"Parede",shell,wicker,Vector3(0,0.23,0))
	var horizontal := G.group(basket_node,"TramaHorizontal")
	var vertical := G.group(basket_node,"TramaVertical")
	for i in range(12):
		var y := 0.035+float(i)*0.035
		ring(horizontal,"Volta",0.239+y*0.135,0.009,Vector3(0,y,0),wicker)
	for i in range(32):
		var angle := float(i)*TAU/32.0
		G.rod(vertical,"Tala",Vector3(cos(angle)*0.243,0.018,sin(angle)*0.243),Vector3(cos(angle)*0.303,0.455,sin(angle)*0.303),0.007,wicker)
	G.combine_children(horizontal,"Voltas",wicker)
	G.combine_children(vertical,"Talas",wicker)
	ring(basket_node,"Aro",0.30,0.018,Vector3(0,0.46,0),wicker)
	cylinder(basket_node,"Fundo",0.24,0.02,Vector3(0,0.025,0),wicker)
	G.rounded(basket_node,"TecidoGuardado",Vector3(0.38,0.10,0.35),Vector3(-0.02,0.36,0),0.028,cloth)
	G.rounded(basket_node,"PontaTecido",Vector3(0.19,0.20,0.018),Vector3(-0.09,0.36,0.29),0.008,cloth)
	var shape := CylinderShape3D.new()
	shape.radius = 0.34
	shape.height = 0.52
	G.collider(basket_node,"ColisaoCesto",shape,Vector3(0,0.26,0),{},2)

func scissors() -> void:
	var tools := G.group(details,"UtensiliosMesa")
	tools.position = Vector3(0.99,0.990,0.63)
	tools.rotation.y = 0.25
	var metal := G.material(Color("bcc7c5"),0.30)
	metal.metallic = 0.78
	var handles := G.material(Color("495f55"),0.48)
	for side in [-1.0,1.0]:
		var half := G.group(tools,"MetadeTesoura")
		half.rotation.y = side*0.18
		var handle := ring(half,"Cabo",0.030,0.008,Vector3(side*0.012,0.009,0.066),handles)
		handle.scale.z = 1.30
		G.rounded(half,"Lamina",Vector3(0.017,0.006,0.15),Vector3(0,0.008,-0.045),0.003,metal)
	cylinder(tools,"PivoTesoura",0.009,0.008,Vector3(0,0.014,0.015),brass)
	# Dois carretéis fora da área clicável do bastidor.
	for i in range(2):
		var at := Vector3(0.23,0.01,-0.20-i*0.11)
		cylinder(tools,"Carretel",0.032,0.012,at,wood)
		cylinder(tools,"FioCarretel",0.025,0.065,at+Vector3.UP*0.037,cloth)
		cylinder(tools,"TopoCarretel",0.032,0.010,at+Vector3.UP*0.075,wood)

func wall_piece() -> void:
	var picture := G.group(details,"QuadroFile")
	picture.position = Vector3(0.95,2.0,-4.35)
	G.rounded(picture,"Moldura",Vector3(1.42,1.04,0.06),Vector3.ZERO,0.018,wood)
	G.box(picture,"Fundo",Vector3(1.32,0.94,0.012),Vector3(0,0,0.037),cloth)
	var grid := G.group(picture,"MalhaDidatica")
	var thread := G.material(Color("d5c6a8"),0.98)
	for i in range(9):
		var p := -0.36+float(i)*0.09
		G.rod(grid,"Coluna",Vector3(p,-0.36,0.05),Vector3(p,0.36,0.05),0.003,thread)
		G.rod(grid,"Linha",Vector3(-0.36,p,0.05),Vector3(0.36,p,0.05),0.003,thread)
	G.combine_children(grid,"Fios",thread)
	for index in range(3):
		var colored := G.group(picture,"Motivo")
		var material := G.material([Color("b8795e"),Color("547b7e"),Color("c4a357")][index],0.94)
		for row in range(8):
			for column in range(8):
				var distance := absf(row-3.5)+absf(column-3.5)
				if distance < 4 and int(distance)%3==index:
					for line in range(4):
						var x := -0.35+column*0.09+line*0.019
						G.rod(colored,"Ponto",Vector3(x,-0.35+row*0.09,0.058),Vector3(x,-0.28+row*0.09,0.058),0.005,material)
		G.combine_children(colored,"FiosColoridos",material)
	var title := Label3D.new()
	title.text = "FILÉ DE ALAGOAS"
	title.font_size = 40
	title.pixel_size = 0.0018
	title.position = Vector3(0,-0.70,0.035)
	title.outline_size = 0
	title.modulate = Color("3d5749")
	picture.add_child(title)

func lighting(room: Node3D) -> void:
	var env: Environment = room.get_node("WorldEnvironment").environment
	env.ambient_light_color = Color("dbe3df")
	env.ambient_light_energy = 0.43
	var sun: DirectionalLight3D = room.get_node("Sol")
	sun.light_energy = 0.42
	sun.shadow_normal_bias = 1.0
	sun.shadow_bias = 0.06
	var fill := OmniLight3D.new()
	fill.name = "LuzDaJanela"
	fill.position = Vector3(-2.4,2.25,-3.7)
	fill.omni_range = 6.5
	fill.omni_attenuation = 0.8
	fill.light_energy = 0.32
	fill.light_color = Color("e1e8e1")
	fill.shadow_enabled = false
	details.add_child(fill)
