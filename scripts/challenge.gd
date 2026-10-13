extends RefCounted
## Estado independente da interface e da geometria. -1 representa vazio.
const SIZE := 8
const REFERENCE := ["........", "..cc....", ".cgg....", "cgbb....", "cgbb....", ".cgg....", "..cc....", "........"]
const CODES := {"c": 0, "b": 1, "g": 2}
const COLORS := [Color("cd6550"), Color("477e92"), Color("d5a23c")]
const COLOR_NAMES := ["coral", "azul", "amarelo"]
var answer: Array = []
var showing_solution := false

func _init() -> void:
	reset()

func reset() -> void:
	answer.clear()
	for row in range(SIZE):
		var cells: Array[int] = []
		cells.resize(SIZE)
		cells.fill(-1)
		answer.append(cells)
	showing_solution = false

func expected(row: int, column: int) -> int:
	var reflected := column if column < 4 else SIZE - 1 - column
	return CODES.get(REFERENCE[row][reflected], -1)

func paint(row: int, column: int, color: int) -> bool:
	if showing_solution or row < 0 or row >= SIZE or column < 4 or column >= SIZE or color < -1 or color > 2:
		return false
	answer[row][column] = color
	return true

func displayed(row: int, column: int) -> int:
	if column < 4 or showing_solution:
		return expected(row, column)
	return answer[row][column]

func mistakes() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for row in range(SIZE):
		for column in range(4, SIZE):
			if answer[row][column] != expected(row, column):
				result.append(Vector2i(row, column))
	return result
