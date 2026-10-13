extends RefCounted
## Recursos compartilhados e salvos nas cenas; sem download ou geração em execução.
static var averages: Dictionary = {}

static func bind_maps(material: ShaderMaterial, asset: String) -> void:
	var folder := "res://textures/polyhaven/"+asset+"/"
	var color_texture: Texture2D = load(folder+"color.jpg")
	material.set_shader_parameter("color_map",color_texture)
	material.set_shader_parameter("normal_map",load(folder+"normal.png"))
	material.set_shader_parameter("roughness_map",load(folder+"roughness.jpg"))
	if not averages.has(asset):
		var source := color_texture.get_image()
		if source.is_compressed():
			assert(source.decompress() == OK)
		var sum := Vector3.ZERO
		var samples := 0
		# Média no espaço linear para normalizar a imagem sem mudar a paleta.
		for y in range(0,source.get_height(),8):
			for x in range(0,source.get_width(),8):
				var color := source.get_pixel(x,y).srgb_to_linear()
				sum += Vector3(color.r,color.g,color.b)
				samples += 1
		sum /= float(samples)
		averages[asset] = Color(sum.x,sum.y,sum.z).linear_to_srgb()
	material.set_shader_parameter("texture_average",averages[asset])
	# Valores explícitos ficam disponíveis no Inspector mesmo após gerar sem GPU.
	material.set_shader_parameter("meters_per_tile",2.23 if asset == "plastered_wall_02" else 0.5)
	material.set_shader_parameter("relief_strength",0.55 if asset == "fabric_pattern_05" else 0.3)
	if asset != "plastered_wall_02":
		material.set_shader_parameter("texture_strength",0.45 if asset == "fabric_pattern_05" else 0.8)

static func character_fabric(material: ShaderMaterial) -> void:
	# Na roupa, deixa a trama legível e reduz as faixas do tecido de referência.
	var color: Color = material.get_shader_parameter("fabric_color")
	var is_linen := color.r > 0.65 and color.r > color.g
	material.set_shader_parameter("texture_strength",0.18 if is_linen else 0.045)

static func plaster() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load("res://materials/plaster.gdshader")
	material.set_shader_parameter("surface_color",Color("ded9cf"))
	bind_maps(material,"plastered_wall_02")
	return material
