extends SceneTree
## Gera ambiente e personagem nativos; apenas esta versão de exploração é alterada.
const G = preload("res://tools/geometry.gd")
const Materials = preload("res://tools/material_library.gd")
const S := 0.52
var timber: ShaderMaterial
var fabric: ShaderMaterial
var cream := G.material(Color("e5dac4"))
var brass := G.material(Color("86734a"),0.3)

func _initialize() -> void:
	timber = ShaderMaterial.new()
	timber.shader = load("res://materials/wood.gdshader")
	timber.set_shader_parameter("timber",Color("ab8765"))
	Materials.bind_maps(timber,"plywood")
	fabric = ShaderMaterial.new()
	fabric.shader = load("res://materials/fabric.gdshader")
	fabric.set_shader_parameter("fabric_color",Color("d6c8a8"))
	Materials.bind_maps(fabric,"fabric_pattern_05")
	room()
	if not "--room-only" in OS.get_cmdline_user_args():
		character()
	print("Ambiente gerado; personagem preservada com --room-only.")
	quit()

func solid(parent: Node, title: String, size: Vector3, at: Vector3, surface: Material) -> MeshInstance3D:
	var object := G.box(parent,title,size,at,surface)
	var shape := BoxShape3D.new()
	shape.size = size
	G.collider(parent,title+"Colisao",shape,at,{},2)
	return object

func ball(parent: Node, title: String, at: Vector3, size: Vector3, surface: Material) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = 0.5
	shape.height = 1.0
	shape.radial_segments = 24
	shape.rings = 12
	var node := G.mesh(parent,title,shape,surface,at)
	node.scale = size
	return node

func rounded(parent: Node, title: String, size: Vector3, at: Vector3, radius: float, surface: Material) -> MeshInstance3D:
	# Seis faces subdivididas; cantos são projetados sobre um raio de arredondamento.
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
		var us := [-hu,-hu+radius*0.25,-hu+radius*0.6,-hu+radius,hu-radius,hu-radius*0.6,hu-radius*0.25,hu]
		var vs := [-hv,-hv+radius*0.25,-hv+radius*0.6,-hv+radius,hv-radius,hv-radius*0.6,hv-radius*0.25,hv]
		for i in range(7):
			for j in range(7):
				for ij in [Vector2i(i,j),Vector2i(i+1,j),Vector2i(i+1,j+1),Vector2i(i,j),Vector2i(i+1,j+1),Vector2i(i,j+1)]:
					var p: Vector3 = normal*hn+u*us[ij.x]+v*vs[ij.y]
					var clamped := p.clamp(-inner,inner)
					var n := (p-clamped).normalized()
					st.set_normal(n)
					st.add_vertex(clamped+n*radius)
	st.index()
	return G.mesh(parent,title,st.commit(),surface,at)

func room() -> void:
	var node := Node3D.new()
	node.name = "Ambiente"
	var source: Node3D = load("res://scenes/ambiente_base.tscn").instantiate()
	# Reaproveita a modelagem anterior, corrigindo sua escala para a circulação humana.
	var mini := G.group(node,"Bancada")
	mini.scale = Vector3.ONE*S
	for name in ["Mesa","PecaInspiracao","SuportePeca","HasteSuporte"]:
		var child := source.get_node(name)
		child.owner = null
		source.remove_child(child)
		mini.add_child(child)
	# Troca o tampo por uma única peça com bordas arredondadas.
	for child in mini.get_node("Mesa").get_children():
		if child.name.begins_with("Tabua") or child.name.begins_with("Veio"):
			child.free()
		elif child is MeshInstance3D:
			var vertical_timber := timber.duplicate() as ShaderMaterial
			vertical_timber.set_shader_parameter("grain_axis",Vector3.UP)
			child.material_override = vertical_timber
	# Quatro tábuas com veios longitudinais, juntas estreitas e chanfros discretos.
	for index in range(4):
		var plank := timber.duplicate() as ShaderMaterial
		plank.set_shader_parameter("grain_axis",Vector3.BACK)
		plank.set_shader_parameter("variation_seed",float(index)*7.31)
		plank.set_shader_parameter("timber",Color("b79775").darkened(float(index%3)*0.018))
		G.rounded(mini.get_node("Mesa"),"TabuaAcabada",Vector3(1.371,0.19,3.76),Vector3(-2.0625+index*1.375,1.79,0),0.024,plank)
	var sample := mini.get_node("PecaInspiracao")
	for child in sample.get_children():
		if child is MeshInstance3D and child.name=="Tecido":
			var linen := fabric.duplicate() as ShaderMaterial
			linen.set_shader_parameter("fabric_color",Color("b6aa8e"))
			child.material_override = linen
	var table_shape := BoxShape3D.new()
	table_shape.size = Vector3(2.86,1.02,1.96)
	G.collider(node,"ColisaoMesa",table_shape,Vector3(0,0.5,0),{},2)
	source.free()
	var floor_mat := G.material(Color("bda78b"))
	solid(node,"BasePiso",Vector3(9,0.15,11.25),Vector3(0,-0.08,1.125),floor_mat)
	for x in range(-6,6):
		for z in range(-6,9):
			var color := Color("ccb898").darkened(float(posmod(x*17+z*13,5))*0.012)
			G.box(node,"Ladrilho",Vector3(0.745,0.018,0.745),Vector3(x*0.75+0.375,-0.001,z*0.75+0.375),G.material(color))
	var plaster := Materials.plaster()
	# Parede dos fundos contém abertura real para a janela.
	solid(node,"FundoEsquerdo",Vector3(1,3.5,0.18),Vector3(-4,1.75,-4.5),plaster)
	solid(node,"FundoDireito",Vector3(5.9,3.5,0.18),Vector3(1.55,1.75,-4.5),plaster)
	solid(node,"AbaixoJanela",Vector3(2.1,1.1,0.18),Vector3(-2.45,0.55,-4.5),plaster)
	solid(node,"AcimaJanela",Vector3(2.1,0.65,0.18),Vector3(-2.45,3.175,-4.5),plaster)
	for x in [-4.5,4.5]:
		solid(node,"ParedeLateral",Vector3(0.18,3.5,11),Vector3(x,1.75,1),plaster)
	# Entrada fechada: abertura da alvenaria, com folha de madeira e colisão.
	solid(node,"FrenteEsquerda",Vector3(3.5,3.5,0.18),Vector3(-2.75,1.75,6.5),plaster)
	solid(node,"FrenteDireita",Vector3(4.3,3.5,0.18),Vector3(2.35,1.75,6.5),plaster)
	solid(node,"AcimaPorta",Vector3(1.2,1.1,0.18),Vector3(-0.4,2.95,6.5),plaster)
	solid(node,"Porta",Vector3(1.18,2.4,0.10),Vector3(-0.4,1.2,6.5),timber)
	ball(node,"Macaneta",Vector3(-0.83,1.0,6.40),Vector3.ONE*0.08,brass)
	for x in [-4.39,4.39]:
		G.box(node,"Rodape",Vector3(0.045,0.12,10.8),Vector3(x,0.065,1),timber)
	G.box(node,"RodapeFundo",Vector3(8.8,0.12,0.04),Vector3(0,0.065,-4.39),timber)
	# Vidro fosco translúcido à luz visual, sem bloquear os raios da iluminação.
	var window := G.group(node,"Janela")
	for x in [-3.52,-1.38]:
		G.box(window,"Lateral",Vector3(0.09,1.85,0.2),Vector3(x,1.97,-4.47),timber)
	for y in [1.07,2.87]:
		G.box(window,"Travessa",Vector3(2.24,0.09,0.2),Vector3(-2.45,y,-4.47),timber)
	var glass := G.material(Color("cddcdd"))
	glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var pane := G.box(window,"Vidro",Vector3(2.05,1.74,0.025),Vector3(-2.45,1.97,-4.53),glass)
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var glass_shape := BoxShape3D.new()
	glass_shape.size = Vector3(2.1,1.8,0.1)
	G.collider(window,"ColisaoJanela",glass_shape,Vector3(-2.45,1.97,-4.5),{},2)
	G.box(window,"Montante",Vector3(0.045,1.78,0.07),Vector3(-2.45,1.97,-4.38),cream)
	G.box(window,"MontanteHorizontal",Vector3(2.1,0.045,0.07),Vector3(-2.45,1.98,-4.38),cream)
	rounded(window,"Peitoril",Vector3(2.4,0.09,0.38),Vector3(-2.45,1.07,-4.32),0.025,timber)
	# Duas cortinas estreitas; a área central da janela fica livre.
	for x in [-3.6,-1.28]:
		for i in range(5):
			var curtain := G.box(window,"DobraCortina",Vector3(0.075,2.12,0.035),Vector3(x+i*0.05,1.87,-4.25+sin(i*1.6)*0.035),fabric)
			curtain.rotation.z = sin(i)*0.016
	G.rod(window,"Varao",Vector3(-3.85,3,-4.22),Vector3(-1.02,3,-4.22),0.018,brass)
	# Estante lateral: objetos fora da rota principal até o bastidor.
	var shelf := G.group(node,"Estante")
	shelf.position = Vector3(3.95,0,-1.4)
	for z in [-0.92,0.92]:
		rounded(shelf,"Lateral",Vector3(0.60,2.05,0.09),Vector3(0,1.025,z),0.025,timber)
	for y in [0.15,0.70,1.25,1.85]:
		rounded(shelf,"Prateleira",Vector3(0.62,0.055,1.92),Vector3(0,y,0),0.018,timber)
	var shelf_shape := BoxShape3D.new()
	shelf_shape.size = Vector3(0.65,2.05,1.98)
	G.collider(shelf,"ColisaoEstante",shelf_shape,Vector3(0,1.025,0),{},2)
	for i in range(6):
		var colors := [Color("b45f4b"),Color("547c85"),Color("d1a145")]
		ball(shelf,"NoveloGuardado",Vector3(-0.05,1.4,-0.7+i*0.27),Vector3.ONE*0.23,G.material(colors[i%3],1.0))
	for i in range(4):
		rounded(shelf,"TecidoDobrado",Vector3(0.45,0.075,0.63),Vector3(-0.03,0.77+i*0.075,0.36),0.028,fabric)
	for z in [-0.6,0.35]:
		rounded(shelf,"CaixaDeFios",Vector3(0.48,0.32,0.55),Vector3(0,0.335,z),0.02,G.material(Color("ac9873")))
	# Banqueta lateral; não ocupa a posição de trabalho em frente à mesa.
	var stool := G.group(node,"Banqueta")
	stool.position = Vector3(-2.1,0,0.0)
	for x in [-0.18,0.18]:
		for z in [-0.18,0.18]:
			G.rod(stool,"Pe",Vector3(x,0.02,z),Vector3(x*0.8,0.47,z*0.8),0.035,timber)
	rounded(stool,"Assento",Vector3(0.5,0.09,0.5),Vector3(0,0.48,0),0.035,timber)
	var stool_shape := BoxShape3D.new()
	stool_shape.size = Vector3(0.52,0.55,0.52)
	G.collider(stool,"ColisaoBanqueta",stool_shape,Vector3(0,0.275,0),{},2)
	# Tapete fino e tecidos de apoio têm espessura, mas não criam degraus.
	G.box(node,"Tapete",Vector3(2.6,0.008,1.45),Vector3(0,0.012,2.05),fabric)
	for i in range(25):
		G.rod(node,"FranjaTapete",Vector3(-1.24+i*0.104,0.015,2.79),Vector3(-1.24+i*0.104,0.015,2.89),0.004,cream)
	# Luminária de trabalho e pequeno recipiente para materiais.
	G.rod(node,"BaseLuminaria",Vector3(1.17,0.99,-0.65),Vector3(1.17,1.56,-0.65),0.018,brass)
	G.rod(node,"BracoLuminaria",Vector3(1.17,1.56,-0.65),Vector3(0.9,1.64,-0.5),0.015,brass)
	var shade := CylinderMesh.new()
	shade.top_radius = 0.065
	shade.bottom_radius = 0.16
	shade.height = 0.13
	G.mesh(node,"Cupula",shade,G.material(Color("426452")),Vector3(0.9,1.62,-0.5))
	var lamp := SpotLight3D.new()
	lamp.name = "LuzTrabalho"
	lamp.position = Vector3(0.9,1.48,-0.5)
	lamp.rotation_degrees.x = -74
	lamp.light_color = Color("ffe8c6")
	lamp.light_energy = 0.28
	lamp.spot_range = 2.5
	lamp.spot_angle = 54
	lamp.shadow_enabled = false
	node.add_child(lamp)
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("d6ddd9")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d2dee0")
	env.ambient_light_energy = 0.48
	world.environment = env
	node.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "Sol"
	sun.rotation_degrees = Vector3(-43,24,0)
	sun.light_energy = 0.50
	sun.light_color = Color("fff3df")
	sun.shadow_enabled = true
	sun.shadow_bias = 0.1
	sun.shadow_normal_bias = 2.0
	sun.directional_shadow_max_distance = 14
	node.add_child(sun)
	preload("res://tools/room_finishing.gd").new().apply(node)
	G.save_scene(node,"res://scenes/ambiente.tscn")
	node.free()

func character() -> void:
	preload("res://tools/character_builder.gd").new().build()
