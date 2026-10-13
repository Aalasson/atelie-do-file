extends Node3D
## A cena salva contém a moldura, os fios e 64 instâncias reutilizáveis.
const Model = preload("res://scripts/challenge.gd")
const ThreadMaterials = preload("res://scripts/thread_materials.gd")
const CELL_SIZE := 0.31
var materials: Array[ShaderMaterial] = []
var hint_marks: Array[Node3D] = []
@onready var fills: Node3D = $Preenchimentos
@onready var highlight: MeshInstance3D = $Destaque

func _ready() -> void:
	for index in range(Model.COLORS.size()):
		materials.append(ThreadMaterials.get_color(index))
	for i in range(2):
		var mark := Node3D.new()
		add_child(mark)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("344e42")
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		for side in range(4):
			var mesh := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(0.30,0.018,0.012) if side<2 else Vector3(0.012,0.018,0.30)
			mesh.mesh = box
			mesh.material_override = material
			mesh.position = Vector3(0,0.08,-0.145 if side==0 else 0.145) if side<2 else Vector3(-0.145 if side==2 else 0.145,0.08,0)
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mark.add_child(mesh)
		mark.visible = false
		hint_marks.append(mark)

func show_hint(row: int = -1, column: int = -1) -> void:
	for i in range(hint_marks.size()):
		hint_marks[i].visible = row>=0
		if row>=0:
			hint_marks[i].position = cell_position(row,column if i==1 else 7-column)

func cell_position(row: int, column: int) -> Vector3:
	return Vector3(-1.24+(column+0.5)*CELL_SIZE,0.035,-1.24+(row+0.5)*CELL_SIZE)

func refresh(model: RefCounted) -> void:
	for row in range(8):
		for column in range(8):
			var color: int = model.displayed(row,column)
			var fill := fills.get_node("Fio_%d_%d"%[row,column]) as Node3D
			fill.visible = color>=0
			if color>=0:
				for child in fill.get_children():
					if child is MeshInstance3D:
						child.material_override = materials[color]

func show_highlight(row: int = -1, column: int = -1) -> void:
	highlight.visible = row>=0 and column>=4
	if highlight.visible:
		highlight.position = cell_position(row,column)+Vector3(0,0.08,0)
