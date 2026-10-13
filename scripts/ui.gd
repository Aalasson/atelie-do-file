extends CanvasLayer
## Interface infantil; os cálculos e a tentativa continuam no modelo.
signal action_requested(action: String, value: Variant)
const Model = preload("res://scripts/challenge.gd")
const Art = preload("res://scripts/ui_art.gd")
const INK := Color("233f39")
const PAPER := Color("fffaf0")
const GREEN := Color("285d50")
const MUTED := Color("536b62")
var root_control: Control
var buttons: Dictionary = {}
var feedback_label: Label
var feedback_title: Label
var feedback_panel: PanelContainer
var hover_label: Label
var cg_box: VBoxContainer
var task_box: VBoxContainer
var task_title: Label
var task_copy: Label
var sliders: Dictionary = {}
var axes_check: CheckBox
var shadow_check: CheckBox
var cg_open := false
var scene_rect := Rect2()
var serif: SystemFont
var modal: Control
var modal_kind := ""
var pages: Dictionary = {}
var pause_title: Label
var volume_slider: HSlider
var volume_label: Label
var selection_label: Label
var stage_label: Label
var solution_label: Label
var work_active := false
var piece_open := false
var solution_showing := false
var saved_focus: Control
var guide_page := 0
var guide_title: Label
var guide_copy: Label
var guide_art: Control
var guide_count: Label
var modal_card: PanelContainer

func _ready() -> void:
	serif = SystemFont.new()
	serif.font_names = font_families()
	serif.font_weight = 700
	root_control = Control.new()
	root_control.name = "Tela"
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	var theme := Theme.new()
	var font := SystemFont.new()
	font.font_names = font_families()
	theme.default_font = font
	theme.default_font_size = 20
	for type in ["Label","Button","CheckBox"]:
		theme.set_color("font_color",type,INK)
	for state in ["hover","pressed","focus"]:
		theme.set_color("font_"+state+"_color","Button",INK)
	theme.set_stylebox("normal","Button",style(Color("fffdf7"),Color("c6d3c5")))
	theme.set_stylebox("hover","Button",style(Color("e4efe4"),GREEN,2))
	theme.set_stylebox("pressed","Button",style(Color("d6e5d9"),GREEN,2))
	theme.set_stylebox("disabled","Button",style(Color("ecece2")))
	theme.set_color("font_disabled_color","Button",Color("728076"))
	theme.set_stylebox("focus","Button",style(Color.TRANSPARENT,Color("276c92"),3))
	theme.set_stylebox("focus","CheckBox",style(Color.TRANSPARENT,Color("276c92"),3))
	theme.set_stylebox("focus","HSlider",style(Color.TRANSPARENT,Color("276c92"),3))
	root_control.theme = theme
	build_header()
	build_sidebar()
	build_scene_labels()
	build_modals()
	get_viewport().size_changed.connect(layout)
	layout()

func font_families() -> PackedStringArray:
	return PackedStringArray(["Segoe UI"])

func style(bg: Color, border: Color = Color.TRANSPARENT, width: int = 1, padding: int = 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(16)
	s.set_border_width_all(width)
	s.border_color = border
	s.content_margin_left = padding
	s.content_margin_right = padding
	s.content_margin_top = padding
	s.content_margin_bottom = padding
	return s

func text(parent: Node, content: String, size: int = 20, title: bool = false) -> Label:
	var label := Label.new()
	label.text = content
	label.add_theme_font_size_override("font_size",size)
	if title:
		label.add_theme_font_override("font",serif)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func button(parent: Node, content: String, key: String, value: Variant = null) -> Button:
	var result := Button.new()
	result.name = key.validate_node_name()
	result.text = content
	result.custom_minimum_size.y = 52
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.focus_mode = Control.FOCUS_ALL
	parent.add_child(result)
	buttons[key] = result
	result.pressed.connect(func(): action_requested.emit(key,value))
	return result

func primary(b: Button) -> void:
	for state in ["normal","hover","pressed"]:
		b.add_theme_stylebox_override(state,style(GREEN.lightened(0.07) if state=="hover" else GREEN))
		b.add_theme_color_override("font_"+state+"_color" if state!="normal" else "font_color",Color.WHITE)
	b.add_theme_color_override("font_focus_color",Color.WHITE)
	b.add_theme_font_override("font",serif)

func spacer(parent: Node, height: float = 8) -> void:
	var empty := Control.new()
	empty.custom_minimum_size.y = height
	empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(empty)

func stack(parent: Node, gap: int = 12) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",gap)
	parent.add_child(box)
	return box

func row(parent: Node, gap: int = 10) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation",gap)
	parent.add_child(box)
	return box

func art(parent: Node, minimum: Vector2, motif: String = "weave") -> Control:
	var picture = Art.new()
	picture.motif = motif
	picture.custom_minimum_size = minimum
	picture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(picture)
	return picture

func build_header() -> void:
	var panel := Panel.new()
	panel.name = "Cabecalho"
	panel.add_theme_stylebox_override("panel",style(PAPER))
	root_control.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.offset_bottom = 84
	var emblem := art(panel,Vector2(50,50),"yarn")
	emblem.position = Vector2(22,17)
	emblem.size = Vector2(50,50)
	var title := text(panel,"Ateliê do Filé",27,true)
	title.position = Vector2(82,12)
	title.size = Vector2(290,37)
	var subtitle := text(panel,"Matemática nas Tramas",17)
	subtitle.position = Vector2(83,49)
	subtitle.size = Vector2(285,24)
	stage_label = text(panel,"EXPLORE E DESCUBRA",17,true)
	stage_label.position = Vector2(408,30)
	stage_label.size = Vector2(340,28)
	stage_label.add_theme_color_override("font_color",MUTED)
	var actions := row(panel)
	actions.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	actions.offset_left = -496
	actions.offset_right = -20
	actions.offset_top = 16
	actions.offset_bottom = 68
	button(actions,"Som: ligado","sound").custom_minimum_size.x = 168
	button(actions,"Como jogar","help").custom_minimum_size.x = 156
	button(actions,"Pausa","pause").custom_minimum_size.x = 130

func build_sidebar() -> void:
	var panel := Panel.new()
	panel.name = "Painel"
	panel.add_theme_stylebox_override("panel",style(PAPER,Color("d8dfcf")))
	root_control.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -350
	panel.offset_right = -16
	panel.offset_top = 100
	panel.offset_bottom = -16
	var scroll := ScrollContainer.new()
	panel.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 20
	scroll.offset_right = -20
	scroll.offset_top = 18
	scroll.offset_bottom = -18
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var content := stack(scroll,0)
	task_box = stack(content,8)
	text(task_box,"DESAFIO DE SIMETRIA",15,true).add_theme_color_override("font_color",MUTED)
	task_title = text(task_box,"Um lado é o\nespelho do outro!",28,true)
	task_copy = text(task_box,"Observe a esquerda e complete a direita.",20)
	solution_label = text(task_box,"EXEMPLO COMPLETO\nSua tentativa está guardada.",18,true)
	solution_label.visible = false
	text(task_box,"1. Escolha uma cor",21,true)
	var palette := row(task_box,6)
	for i in range(3):
		var b := button(palette,Model.COLOR_NAMES[i].capitalize(),"color_%d"%i,i)
		b.custom_minimum_size = Vector2(84,60)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size",17)
		b.tooltip_text = "Escolher fio "+Model.COLOR_NAMES[i]
	selection_label = text(task_box,"Selecionado: coral",17,true)
	text(task_box,"2. Clique nos quadradinhos",19,true)
	var tools := row(task_box)
	button(tools,"Apagar","erase").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button(tools,"Dica","hint").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feedback_panel = PanelContainer.new()
	feedback_panel.add_theme_stylebox_override("panel",style(Color("e8efe2")))
	task_box.add_child(feedback_panel)
	var feedback := stack(feedback_panel,4)
	feedback_title = text(feedback,"Vamos tecer?",19,true)
	feedback_label = text(feedback,"A linha verde divide os dois lados do desenho.",18)
	feedback_label.custom_minimum_size.y = 56
	primary(button(task_box,"Conferir minha trama","verify"))
	button(task_box,"Ver exemplo completo","solution")
	button(task_box,"Ver peça em destaque","piece").visible = false
	button(task_box,"Começar de novo","reset")
	cg_box = stack(content,12)
	cg_box.visible = false
	text(cg_box,"PARA A APRESENTAÇÃO",15,true)
	text(cg_box,"Explore a CG",28,true)
	text(cg_box,"Transforme o novelo coral e observe o que muda.",19)
	axes_check = CheckBox.new()
	axes_check.text = "Mostrar eixos X / Y / Z"
	axes_check.custom_minimum_size.y = 48
	cg_box.add_child(axes_check)
	axes_check.toggled.connect(func(on: bool): action_requested.emit("axes",on))
	shadow_check = CheckBox.new()
	shadow_check.text = "Mostrar sombras"
	shadow_check.custom_minimum_size.y = 48
	shadow_check.button_pressed = true
	cg_box.add_child(shadow_check)
	shadow_check.toggled.connect(func(on: bool): action_requested.emit("shadows",on))
	make_slider("move","Mover · translação","Muda a posição na mesa.",-0.45,0.45,0.01,0)
	make_slider("rotate","Girar · rotação","Gira em torno do eixo Y.",-180,180,1,0)
	make_slider("scale","Aumentar · escala","Mantém as proporções.",0.65,1.35,0.01,1)
	button(cg_box,"Restaurar novelo","restore_yarn")
	text(cg_box,"X: vermelho · Y: verde · Z: azul",16)
	primary(button(cg_box,"Voltar ao desafio","close_cg"))
	set_color(0)

func make_slider(key: String, title: String, explanation: String, low: float, high: float, step: float, initial: float) -> void:
	var label := text(cg_box,title+"  "+str(initial),19,true)
	var slider := HSlider.new()
	slider.name = key
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.value = initial
	slider.custom_minimum_size.y = 44
	cg_box.add_child(slider)
	sliders[key] = slider
	slider.value_changed.connect(func(value: float):
		label.text = title+"  "+("%.2f"%value)
		action_requested.emit("transform",Vector3(sliders.move.value,sliders.rotate.value,sliders.scale.value)))
	text(cg_box,explanation,17)

func build_scene_labels() -> void:
	var intro := PanelContainer.new()
	intro.name = "Introducao"
	intro.position = Vector2(22,104)
	intro.size = Vector2(610,48)
	intro.add_theme_stylebox_override("panel",style(PAPER,Color.TRANSPARENT,1,10))
	intro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(intro)
	text(intro,"MODELO À ESQUERDA    |    SUA TRAMA À DIREITA",17,true).name = "Titulo"
	var nav := row(root_control)
	nav.name = "Navegacao"
	button(nav,"Voltar ao ateliê","explore")
	button(nav,"Ajustar a vista","home")
	button(nav,"Explorar a CG","cg")
	button(nav,"Voltar ao desafio","back_piece").visible = false
	buttons["work"] = buttons.home
	hover_label = text(root_control,"Clique para tecer. Arraste para mudar a vista.",17)
	hover_label.name = "Dica"
	hover_label.add_theme_color_override("font_shadow_color",PAPER)
	hover_label.add_theme_constant_override("shadow_offset_x",1)
	hover_label.add_theme_constant_override("shadow_offset_y",1)

func make_page(key: String) -> VBoxContainer:
	var page := stack(modal_card,14)
	page.visible = false
	pages[key] = page
	return page

func build_modals() -> void:
	modal = Control.new()
	modal.name = "Telas"
	root_control.add_child(modal)
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.08,0.16,0.13,0.65)
	modal.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	modal.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_card = PanelContainer.new()
	modal_card.custom_minimum_size.x = 760
	modal_card.add_theme_stylebox_override("panel",style(PAPER,Color("e1d9bd"),2,32))
	center.add_child(modal_card)
	var welcome := make_page("welcome")
	text(welcome,"CULTURA DE ALAGOAS  /  4º ANO",16,true).add_theme_color_override("font_color",MUTED)
	var greeting := row(welcome,26)
	var title_box := stack(greeting,12)
	title_box.custom_minimum_size.x = 390
	text(title_box,"Ateliê do Filé",40,true)
	text(title_box,"Matemática nas Tramas",24,true)
	text(title_box,"Vamos criar com cores\ne descobrir a simetria?",23)
	art(greeting,Vector2(260,250))
	text(welcome,"Explore o ateliê e encontre o bastidor sobre a mesa.",21)
	primary(button(welcome,"Vamos começar!","start"))
	var welcome_actions := row(welcome)
	button(welcome_actions,"Como jogar","welcome_help").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button(welcome_actions,"Fechar o jogo","welcome_quit").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text(welcome,"Desenhos didáticos inspirados no filé de Alagoas.",16).add_theme_color_override("font_color",MUTED)
	var pause := make_page("pause")
	text(pause,"PODE FAZER UMA PAUSA",16,true)
	pause_title = text(pause,"Seu ateliê está esperando",30,true)
	text(pause,"Sua trama fica guardada enquanto o jogo está aberto.",21)
	primary(button(pause,"Continuar jogando","resume"))
	button(pause,"Relembrar como jogar","pause_help")
	var volume_row := row(pause)
	volume_label = text(volume_row,"Volume: 75%",20,true)
	volume_label.custom_minimum_size.x = 175
	volume_slider = HSlider.new()
	volume_slider.min_value = 0
	volume_slider.max_value = 1
	volume_slider.step = 0.05
	volume_slider.value = 0.75
	volume_slider.custom_minimum_size = Vector2(360,48)
	volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_slider.tooltip_text = "Ajustar o volume de todos os sons"
	volume_row.add_child(volume_slider)
	volume_slider.value_changed.connect(func(value: float):
		volume_label.text = "Volume: %d%%"%roundi(value*100)
		action_requested.emit("volume",value))
	button(pause,"Som: ligado","pause_sound")
	button(pause,"Fechar o jogo","pause_quit")
	text(pause,"Tab: escolher botão  ·  Enter: confirmar  ·  Esc: voltar",17)
	var help := make_page("help")
	guide_count = text(help,"COMO JOGAR  ·  1 DE 3",16,true)
	guide_title = text(help,"Encontre a mesa",30,true)
	guide_art = art(help,Vector2(0,220),"mirror")
	guide_copy = text(help,"",22)
	guide_copy.custom_minimum_size.y = 104
	var guide_actions := row(help)
	button(guide_actions,"Anterior","help_prev").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var next_tip := button(guide_actions,"Próxima dica","help_next")
	next_tip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary(next_tip)
	button(help,"Voltar","help_close")
	text(help,"Interpretação didática: os desenhos não reproduzem padrões tradicionais específicos.",16).add_theme_color_override("font_color",MUTED)
	var reset := make_page("reset")
	text(reset,"Começar uma nova trama?",30,true)
	text(reset,"Isso apaga as cores que você colocou. O modelo à esquerda continua igual.",22)
	primary(button(reset,"Continuar minha trama","reset_cancel"))
	button(reset,"Sim, começar de novo","reset_confirm")
	var success := make_page("success")
	text(success,"TRAMA CONCLUÍDA",16,true)
	text(success,"Você criou uma simetria!",32,true)
	art(success,Vector2(0,210))
	text(success,"Os dois lados têm as mesmas cores, à mesma distância da linha verde.",23)
	primary(button(success,"Ver minha peça","success_piece"))
	var success_actions := row(success)
	button(success_actions,"Continuar no bastidor","success_close").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button(success_actions,"Explorar o ateliê","success_explore").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var quit_page := make_page("quit")
	text(quit_page,"Fechar o ateliê?",32,true)
	text(quit_page,"Sua trama não fica salva depois de fechar o jogo.",23)
	primary(button(quit_page,"Continuar jogando","quit_cancel"))
	button(quit_page,"Sim, fechar o jogo","quit_confirm")
	modal.visible = false
	set_guide(0)

func set_guide(index: int) -> void:
	guide_page = clampi(index,0,2)
	var titles := ["1. Explore o ateliê","2. Faça um reflexo","3. Confira e descubra"]
	var copies := ["Use WASD ou as setas para andar. Mova o mouse para olhar.\nPerto da mesa, pressione E para começar.","Escolha um fio e clique à direita da linha verde.\nCopie a cor à mesma distância do outro lado. Vazios também contam!","Clique em Conferir minha trama. Use Dica se precisar.\nVocê pode apagar, ver um exemplo e tentar de novo, no seu ritmo."]
	guide_title.text = titles[guide_page]
	guide_copy.text = copies[guide_page]
	guide_count.text = "COMO JOGAR  ·  %d DE 3"%(guide_page+1)
	guide_art.motif = "mirror" if guide_page==1 else "weave"
	guide_art.queue_redraw()
	buttons.help_prev.disabled = guide_page==0
	buttons.help_next.text = "Entendi!" if guide_page==2 else "Próxima dica"
	if modal_kind=="help":
		call_deferred("focus_page","help_next")

func open_modal(kind: String) -> void:
	if not modal.visible:
		saved_focus = get_viewport().gui_get_focus_owner()
	modal_kind = kind
	modal.visible = true
	for key in pages:
		pages[key].visible = key==kind
	modal_card.size = Vector2.ZERO
	var preferred := {"welcome":"start","pause":"resume","help":"help_next","reset":"reset_cancel","success":"success_piece","quit":"quit_cancel"}
	call_deferred("focus_page",preferred[kind])

func focus_page(key: String) -> void:
	if not modal.visible:
		return
	var focusables: Array[Control] = []
	collect_focus(pages[modal_kind],focusables)
	for i in range(focusables.size()):
		focusables[i].focus_next = focusables[i].get_path_to(focusables[(i+1)%focusables.size()])
		focusables[i].focus_previous = focusables[i].get_path_to(focusables[(i-1+focusables.size())%focusables.size()])
	buttons[key].grab_focus()

func collect_focus(parent: Node, result: Array[Control]) -> void:
	for child in parent.get_children():
		if child is Control and child.is_visible_in_tree() and child.focus_mode==Control.FOCUS_ALL:
			if not (child is BaseButton and child.disabled):
				result.append(child)
		collect_focus(child,result)

func close_modal() -> void:
	modal.visible = false
	modal_kind = ""
	if is_instance_valid(saved_focus) and saved_focus.is_visible_in_tree():
		saved_focus.grab_focus()

func layout() -> void:
	var dimensions := get_viewport().get_visible_rect().size
	var right := 0.0 if piece_open else 366.0
	scene_rect = Rect2(0,84,dimensions.x-right,dimensions.y-84)
	var nav := root_control.get_node("Navegacao") as HBoxContainer
	nav.position = Vector2(22,dimensions.y-106)
	hover_label.position = Vector2(26,dimensions.y-41)
	hover_label.size = Vector2(scene_rect.size.x-40,28)

func set_status(message: String, heading: String = "Vamos tecer?", tone: String = "neutral") -> void:
	feedback_title.text = heading
	feedback_label.text = message
	var color := Color("fff0cf") if tone=="hint" else Color("e8efe2")
	feedback_panel.add_theme_stylebox_override("panel",style(color))

func set_color(index: int) -> void:
	for i in range(3):
		var s := style(Model.COLORS[i].lightened(0.70),GREEN if i==index else Model.COLORS[i].darkened(0.12),3 if i==index else 1,8)
		buttons["color_%d"%i].add_theme_stylebox_override("normal",s)
	selection_label.text = "Selecionado: apagar" if index==-1 else "Selecionado: "+Model.COLOR_NAMES[index]
	buttons.erase.text = "Apagar ✓" if index==-1 else "Apagar"

func set_solution(showing: bool) -> void:
	solution_showing = showing
	task_title.text = "Veja os dois\nlados iguais!" if showing else "Um lado é o\nespelho do outro!"
	task_copy.text = "Observe as cores e a distância até a linha verde." if showing else "Observe a esquerda e complete a direita."
	for child in task_box.get_children():
		child.visible = not showing or child.get_index()<3 or child in [solution_label,buttons.solution,buttons.piece]
	solution_label.visible = showing
	buttons.solution.text = "Voltar à minha tentativa" if showing else "Ver exemplo completo"
	buttons.piece.visible = showing
	for key in ["verify","erase","hint","reset","color_0","color_1","color_2"]:
		buttons[key].disabled = showing
	stage_label.text = "OBSERVE O EXEMPLO" if showing else "VAMOS CRIAR UMA SIMETRIA"

func set_cg(opened: bool) -> void:
	cg_open = opened
	cg_box.visible = opened
	task_box.visible = not opened
	buttons.cg.text = "Voltar ao desafio" if opened else "Explorar a CG"
	action_requested.emit("cg_visible",opened)

func reset_sliders() -> void:
	sliders.move.value = 0
	sliders.rotate.value = 0
	sliders.scale.value = 1

func set_work(active: bool) -> void:
	work_active = active
	root_control.get_node("Painel").visible = active and not piece_open
	root_control.get_node("Navegacao").visible = active
	root_control.get_node("Introducao").visible = active
	hover_label.visible = active
	stage_label.text = "VAMOS CRIAR UMA SIMETRIA" if active else "EXPLORE E DESCUBRA"
	if active and solution_showing:
		stage_label.text = "OBSERVE O EXEMPLO"
	if active and piece_open:
		stage_label.text = "INSPIRADA NO FILÉ DE ALAGOAS"

func set_piece(opened: bool) -> void:
	piece_open = opened
	set_work(work_active)
	for key in ["explore","home","cg"]:
		buttons[key].visible = not opened
	buttons.back_piece.visible = opened
	(root_control.get_node("Introducao/Titulo") as Label).text = "SUA PEÇA EM DESTAQUE" if opened else "MODELO À ESQUERDA    |    SUA TRAMA À DIREITA"
	stage_label.text = "INSPIRADA NO FILÉ DE ALAGOAS" if opened else "VAMOS CRIAR UMA SIMETRIA"
	layout()

func set_sound(muted: bool) -> void:
	for key in ["sound","pause_sound"]:
		buttons[key].text = "Som: desligado" if muted else "Som: ligado"

func set_view(_mode: String) -> void:
	pass
