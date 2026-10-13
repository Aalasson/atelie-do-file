extends RefCounted
## Modelagem local: superfícies por seções, pivôs articulares e materiais nativos.
const G = preload("res://tools/geometry.gd")
const Materials = preload("res://tools/material_library.gd")

func ball(parent: Node, name: String, at: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 20
	mesh.rings = 12
	var result := G.mesh(parent,name,mesh,material,at)
	result.scale = dimensions
	return result

func cloth(color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load("res://materials/fabric.gdshader")
	material.set_shader_parameter("fabric_color",color)
	Materials.bind_maps(material,"fabric_pattern_05")
	Materials.character_fabric(material)
	return material

func loft(parent: Node, name: String, rings: Array, material: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(rings.size()-1):
		for j in range(24):
			for corner in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,0),Vector2i(1,1),Vector2i(0,1)]:
				var ring: Vector4 = rings[i+corner.x]
				var angle := float(j+corner.y)/24.0*TAU
				var previous: Vector4 = rings[maxi(0,i+corner.x-1)]
				var next: Vector4 = rings[mini(rings.size()-1,i+corner.x+1)]
				var along := Vector3(sin(angle)*(next.y-previous.y),next.x-previous.x,cos(angle)*(next.z-previous.z)+next.w-previous.w)
				var around := Vector3(cos(angle)*ring.y,0,-sin(angle)*ring.z)
				st.set_normal(around.cross(along).normalized())
				st.add_vertex(Vector3(sin(angle)*ring.y,ring.x,cos(angle)*ring.z+ring.w))
	st.index()
	G.mesh(parent,name,st.commit(),material)

func hair_point(t: float, angle: float) -> Vector3:
	var edge := 0.101+0.128*(0.5-0.5*cos(angle))
	var radius := pow(maxf(cos(t*PI*0.5),0),0.82)
	return Vector3(sin(angle)*0.139*radius,lerpf(edge,0.331,sin(t*PI*0.5)),cos(angle)*0.128*radius+0.009)

func hair_cap(parent: Node, material: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(8):
		for j in range(32):
			for c in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,0),Vector2i(1,1),Vector2i(0,1)]:
				var t := float(i+c.x)/8.0
				var angle := float(j+c.y)/32.0*TAU
				var along := hair_point(minf(t+0.002,1),angle)-hair_point(maxf(t-0.002,0),angle)
				var around := hair_point(minf(t,0.995),angle+0.002)-hair_point(minf(t,0.995),angle-0.002)
				st.set_normal(around.cross(along).normalized())
				st.add_vertex(hair_point(t,angle))
	st.index()
	G.mesh(parent,"Cabelo",st.commit(),material)

func apron(parent: Node, material: Material, trim: Material) -> void:
	# Painel levemente curvo com espessura; a modelagem não usa simulação de tecido.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows := [Vector3(-0.165,0.175,-0.165),Vector3(0.0,0.19,-0.149),Vector3(0.13,0.145,-0.149),Vector3(0.29,0.12,-0.153)]
	for back in [false,true]:
		for i in range(rows.size()-1):
			for j in range(8):
				var corners := [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,0),Vector2i(1,1),Vector2i(0,1)]
				if not back:
					corners.reverse()
				for corner in corners:
					var row: Vector3 = rows[i+corner.x]
					var across := float(j+corner.y)/8.0*2.0-1.0
					st.set_normal(Vector3(across*0.15,0,1 if back else -1).normalized())
					st.add_vertex(Vector3(across*row.y,row.x,row.z+across*across*0.025+(0.006 if back else 0.0)))
	st.index()
	G.mesh(parent,"Avental",st.commit(),material)
	for sign_value in [-1.0,1.0]:
		G.rod(parent,"AlcaAvental",Vector3(sign_value*0.106,0.285,-0.14),Vector3(sign_value*0.12,0.398,-0.061),0.011,material)
		G.rod(parent,"AlcaCostas",Vector3(sign_value*0.12,0.398,-0.061),Vector3(sign_value*0.13,0.13,0.12),0.010,material)
	G.rounded(parent,"BolsoAvental",Vector3(0.20,0.115,0.010),Vector3(0,-0.047,-0.168),0.004,trim)
	G.rod(parent,"CosturaBolso",Vector3(-0.092,0.007,-0.175),Vector3(0.092,0.007,-0.175),0.002,material)
	G.rod(parent,"DivisaoBolso",Vector3(0.018,0.005,-0.175),Vector3(0.018,-0.10,-0.175),0.0015,material)
	for sign_value in [-1.0,1.0]:
		G.rod(parent,"LacoCostas",Vector3(0,0.06,0.135),Vector3(sign_value*0.078,0.082,0.143),0.008,material)
		G.rod(parent,"PontaLaco",Vector3(0,0.06,0.14),Vector3(sign_value*0.05,-0.08,0.149),0.006,material)

func build() -> void:
	var node := CharacterBody3D.new()
	node.name = "Personagem"
	node.collision_layer = 4
	node.collision_mask = 2
	node.floor_snap_length = 0.15
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.23
	capsule.height = 1.78
	collision.shape = capsule
	collision.position.y = 0.89
	node.add_child(collision)
	var visual := G.group(node,"Visual")
	visual.set_script(load("res://scripts/character_pose.gd"))
	var body := G.group(visual,"Corpo")
	body.position.y = 0.925
	var skin := G.material(Color("b98060"),0.82)
	var hair := G.material(Color("352921"),0.91)
	var hair_highlight := G.material(Color("4b372a"),0.94)
	var shirt := cloth(Color("6f9480"))
	var cuff := cloth(Color("87a18c"))
	var trousers := cloth(Color("384f5e"))
	var hem := cloth(Color("495e68"))
	var linen := cloth(Color("c7b393"))
	var pocket := cloth(Color("bba582"))
	var leather := G.material(Color("806046"),0.8)
	var sole := G.material(Color("443d34"),0.92)
	var lace := G.material(Color("c4b295"),0.97)
	loft(body,"Quadril",[Vector4(-0.09,0.12,0.089,0),Vector4(-0.045,0.17,0.118,0),Vector4(0.04,0.178,0.119,0),Vector4(0.10,0.158,0.11,0)],trousers)
	var torso := G.group(body,"Tronco")
	torso.position.y = 0.08
	loft(torso,"Blusa",[Vector4(-0.005,0.17,0.113,0),Vector4(0.055,0.179,0.12,0),Vector4(0.21,0.19,0.14,0),Vector4(0.31,0.213,0.133,0),Vector4(0.367,0.226,0.106,0),Vector4(0.401,0.17,0.085,0),Vector4(0.433,0.064,0.059,0)],shirt)
	apron(torso,linen,pocket)
	G.rod(torso,"Pescoco",Vector3(0,0.421,0),Vector3(0,0.497,0),0.057,skin)
	for sign_value in [-1.0,1.0]:
		G.rod(torso,"Gola",Vector3(sign_value*0.066,0.427,-0.04),Vector3(0,0.373,-0.11),0.012,cuff)
	var head := G.group(torso,"Cabeca")
	head.position.y = 0.453
	loft(head,"Rosto",[Vector4(0,0.025,0.04,-0.023),Vector4(0.025,0.075,0.075,-0.015),Vector4(0.075,0.108,0.099,-0.009),Vector4(0.15,0.126,0.111,0),Vector4(0.23,0.12,0.11,0.005),Vector4(0.287,0.089,0.08,0.01),Vector4(0.315,0.002,0.002,0.01)],skin)
	hair_cap(head,hair)
	ball(head,"Coque",Vector3(0,0.219,0.134),Vector3(0.139,0.13,0.12),hair)
	var hair_tie := TorusMesh.new()
	hair_tie.inner_radius = 0.045
	hair_tie.outer_radius = 0.049
	hair_tie.rings = 24
	hair_tie.ring_segments = 6
	var tie := G.mesh(head,"Prendedor",hair_tie,cuff,Vector3(0,0.217,0.128))
	tie.rotation.x = PI/2
	for i in range(7):
		var angle := float(i)*0.20-0.6
		G.rod(head,"MechaCoque",Vector3(sin(angle)*0.050,0.261,0.168),Vector3(sin(angle)*0.049,0.178,0.169),0.0018,hair_highlight)
	var whites := G.material(Color("e7ded0"),0.85)
	var iris := G.material(Color("34291f"),0.67)
	var lip := G.material(Color("815341"),0.93)
	for sign_value in [-1.0,1.0]:
		ball(head,"Orelha",Vector3(sign_value*0.124,0.137,0.012),Vector3(0.036,0.065,0.043),skin)
		ball(head,"Olho",Vector3(sign_value*0.045,0.175,-0.101),Vector3(0.045,0.026,0.022),whites)
		ball(head,"Iris",Vector3(sign_value*0.045,0.176,-0.113),Vector3(0.018,0.020,0.008),iris)
		ball(head,"ReflexoOlho",Vector3(sign_value*0.045-0.003,0.181,-0.117),Vector3.ONE*0.004,whites)
		G.rod(head,"Sobrancelha",Vector3(sign_value*0.024,0.205,-0.103),Vector3(sign_value*0.067,0.200,-0.098),0.005,hair)
	ball(head,"Nariz",Vector3(0,0.131,-0.108),Vector3(0.038,0.052,0.052),skin)
	G.rod(head,"Boca",Vector3(-0.028,0.080,-0.102),Vector3(0,0.074,-0.108),0.003,lip)
	G.rod(head,"Boca",Vector3(0,0.074,-0.108),Vector3(0.028,0.080,-0.102),0.003,lip)
	for sign_value in [-1.0,1.0]:
		var suffix := "E" if sign_value<0 else "D"
		var arm := G.group(torso,"Braco"+suffix)
		arm.position = Vector3(sign_value*0.236,0.352,0)
		ball(arm,"Ombro",Vector3(sign_value*0.006,-0.039,0),Vector3(0.145,0.15,0.157),shirt)
		loft(arm,"Manga",[Vector4(-0.166,0.065,0.067,0),Vector4(-0.07,0.073,0.077,0),Vector4(0.015,0.053,0.060,0)],shirt)
		loft(arm,"BarraManga",[Vector4(-0.17,0.067,0.069,0),Vector4(-0.145,0.067,0.069,0)],cuff)
		loft(arm,"Braco",[Vector4(-0.255,0.047,0.050,0),Vector4(-0.15,0.057,0.058,0)],skin)
		var elbow := G.group(arm,"Cotovelo")
		elbow.position.y = -0.255
		ball(elbow,"Articulacao",Vector3.ZERO,Vector3.ONE*0.097,skin)
		loft(elbow,"Antebraco",[Vector4(-0.237,0.033,0.035,0),Vector4(-0.16,0.042,0.042,0),Vector4(-0.05,0.051,0.051,0),Vector4(0,0.046,0.047,0)],skin)
		var wrist := G.group(elbow,"Punho")
		wrist.position.y = -0.238
		ball(wrist,"Articulacao",Vector3.ZERO,Vector3(0.067,0.06,0.071),skin)
		ball(wrist,"Palma",Vector3(0,-0.045,-0.007),Vector3(0.074,0.11,0.047),skin)
		ball(wrist,"Polegar",Vector3(-sign_value*0.036,-0.036,-0.012),Vector3(0.027,0.065,0.032),skin)
		for finger in range(3):
			ball(wrist,"Dedo",Vector3(-0.02+float(finger)*0.019,-0.090,-0.007),Vector3(0.021,0.044,0.036),skin)
		var leg := G.group(body,"Perna"+suffix)
		leg.position.x = sign_value*0.105
		loft(leg,"Coxa",[Vector4(-0.414,0.065,0.065,0),Vector4(-0.29,0.074,0.077,0),Vector4(-0.10,0.088,0.097,0),Vector4(0.018,0.087,0.095,0)],trousers)
		var knee := G.group(leg,"Joelho")
		knee.position.y = -0.415
		ball(knee,"Articulacao",Vector3.ZERO,Vector3(0.129,0.132,0.135),trousers)
		loft(knee,"Canela",[Vector4(-0.394,0.049,0.052,0),Vector4(-0.25,0.060,0.066,0),Vector4(-0.07,0.066,0.071,0),Vector4(0.02,0.063,0.065,0)],trousers)
		loft(knee,"BarraCalca",[Vector4(-0.403,0.051,0.055,0),Vector4(-0.367,0.052,0.056,0)],hem)
		var ankle := G.group(knee,"Tornozelo")
		ankle.position.y = -0.425
		G.rounded(ankle,"Solado",Vector3(0.164,0.027,0.282),Vector3(0,-0.086,-0.062),0.009,sole)
		G.rounded(ankle,"Sapato",Vector3(0.155,0.075,0.268),Vector3(0,-0.040,-0.061),0.032,leather)
		for i in range(3):
			G.rod(ankle,"Cadarco",Vector3(-0.038,-0.001,-0.055-float(i)*0.022),Vector3(0.038,-0.001,-0.069-float(i)*0.022),0.002,lace)
		var contact := Marker3D.new()
		contact.name = "ContatoChao"
		contact.position = Vector3(0,-0.0995,-0.062)
		ankle.add_child(contact)
	# Mantém a câmera e seus limites da Entrega 1.
	var original: Node3D = load("res://scenes/personagem.tscn").instantiate()
	var pivot := original.get_node("CameraPivot")
	pivot.owner = null
	original.remove_child(pivot)
	node.add_child(pivot)
	original.free()
	G.save_scene(node,"res://scenes/personagem.tscn")
	node.free()
