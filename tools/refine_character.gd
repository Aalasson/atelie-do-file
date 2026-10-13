extends SceneTree
func _initialize() -> void:
	preload("res://tools/character_builder.gd").new().build()
	print("Entrega 2: personagem articulada salva.")
	quit()
