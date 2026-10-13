@tool
extends RefCounted
## Três recursos compartilhados por todas as células, também no editor.
const Model = preload("res://scripts/challenge.gd")
const ThreadShader = preload("res://materials/thread.gdshader")
static var palette: Array[ShaderMaterial] = []

static func get_color(index: int) -> ShaderMaterial:
	if palette.is_empty():
		for color in Model.COLORS:
			var material := ShaderMaterial.new()
			material.shader = ThreadShader
			material.set_shader_parameter("thread_color",color)
			palette.append(material)
	return palette[clampi(index,0,2)]
