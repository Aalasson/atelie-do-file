extends Control
## Ilustração vetorial local; não reproduz um padrão tradicional específico.
var motif := "weave"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var center := size*0.5
	var unit := minf(size.x,size.y)
	if motif == "mark":
		var mark := StyleBoxFlat.new()
		mark.bg_color = Color("285d50")
		mark.set_corner_radius_all(14)
		draw_style_box(mark, Rect2(Vector2.ZERO, size))
		for i in range(3):
			var offset := unit * (0.3 + i * 0.2)
			draw_line(Vector2(offset, unit*0.2), Vector2(offset, unit*0.8), Color("fffaf0"), 2, true)
			draw_line(Vector2(unit*0.2, offset), Vector2(unit*0.8, offset), Color("fffaf0"), 2, true)
		return
	if motif == "yarn":
		draw_circle(center,unit*0.41,Color("d56e53"))
		for i in range(5):
			draw_arc(center+Vector2((i-2)*unit*0.08,0),unit*0.3,-1.8,1.8,24,Color("fce5cf"),1.5,true)
		return
	var frame := Rect2(center-Vector2.ONE*unit*0.41,Vector2.ONE*unit*0.82)
	draw_style_box(frame_style(),frame)
	var inside := frame.grow(-unit*0.06)
	var cell := inside.size.x/8.0
	for i in range(9):
		draw_line(inside.position+Vector2(i*cell,0),inside.position+Vector2(i*cell,inside.size.y),Color("c6bda5"),1.5,true)
		draw_line(inside.position+Vector2(0,i*cell),inside.position+Vector2(inside.size.x,i*cell),Color("c6bda5"),1.5,true)
	var model = preload("res://scripts/challenge.gd").new()
	for r in range(8):
		for c in range(8):
			var color: int = model.expected(r,c)
			if color < 0 or (motif=="mirror" and c>=4 and r!=3):
				continue
			var origin := inside.position+Vector2(c,r)*cell
			for j in range(1,5):
				var shift := cell*float(j)/5.0
				draw_line(origin+Vector2(shift,2),origin+Vector2(shift,cell-2),model.COLORS[color],maxf(1.5,unit*0.007),true)
				draw_line(origin+Vector2(2,shift),origin+Vector2(cell-2,shift),model.COLORS[color],maxf(1.5,unit*0.007),true)
	if motif=="mirror":
		draw_dashed_line(Vector2(center.x,inside.position.y-8),Vector2(center.x,inside.end.y+8),Color("285d50"),3,7,true)
		draw_line(inside.position+Vector2(2.5,3.5)*cell,inside.position+Vector2(5.5,3.5)*cell,Color("213d38"),3,true)

func frame_style() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("f5eddb")
	box.border_color = Color("ba8b58")
	box.set_border_width_all(10)
	box.set_corner_radius_all(14)
	box.shadow_color = Color(0.12,0.2,0.16,0.12)
	box.shadow_size = 8
	box.shadow_offset = Vector2(0,5)
	return box
