extends SceneTree
const Model = preload("res://scripts/challenge.gd")

func _initialize() -> void:
	var m := Model.new()
	assert(m.mistakes().size()==18)
	assert(not m.paint(0,0,1),"Referência não pode ser alterada")
	assert(not m.paint(-1,7,1))
	assert(not m.paint(8,7,1))
	assert(not m.paint(0,8,1))
	assert(not m.paint(0,4,4))
	m.paint(1,5,0)
	var saved: Array = m.answer.duplicate(true)
	m.showing_solution = true
	assert(not m.paint(1,5,2))
	assert(m.answer==saved)
	m.showing_solution = false
	for row in range(8):
		for column in range(4,8):
			m.paint(row,column,m.expected(row,column))
	assert(m.mistakes().is_empty())
	m.paint(0,7,0)
	assert(m.mistakes().size()==1,"Vazios também precisam ser refletidos")
	m.paint(0,7,-1)
	assert(m.mistakes().is_empty())
	m.reset()
	assert(m.answer[1][5]==-1 and not m.showing_solution)
	print("PASS: modelo, limites, referência imutável, solução, vazios e reinício.")
	quit()
