extends "res://scripts/ui.gd"
## Uma orientação e sete botões, com a bancada 3D ocupando a área central.
signal workspace_changed
const SURFACE := Color("f0f4e8")
const EDGE := Color("d5decb")
var work_surface: Control
var masks: Array[ColorRect] = []
var tools_panel: PanelContainer
var palette_row: HBoxContainer
var board_labels: HBoxContainer
var footer: HBoxContainer
var example_tools: HBoxContainer
var completed := false
var active_step := 0
var instruction := "Escolha uma cor."
var music_slider: HSlider
var music_label: Label

func _ready() -> void:
	super._ready()
	set_color(0)
	refresh_layout()
	call_deferred("layout")

func font_families() -> PackedStringArray:
	return PackedStringArray(["Trebuchet MS", "Segoe UI"])

func build_header() -> void:
	work_surface = Control.new()
	work_surface.name = "FundoDaTrilha"
	work_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(work_surface)
	for i in range(4):
		var mask := ColorRect.new()
		mask.color = SURFACE
		work_surface.add_child(mask)
		masks.append(mask)
	feedback_panel = PanelContainer.new()
	feedback_panel.name = "Cabecalho"
	feedback_panel.add_theme_stylebox_override("panel", style(PAPER, EDGE, 1, 12))
	root_control.add_child(feedback_panel)
	var header := row(feedback_panel, 20)
	feedback_label = text(header, instruction, 28, true)
	feedback_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var pause := button(header, "Pausa", "pause")
	pause.custom_minimum_size = Vector2(118, 56)
	# Estado de retorno usado pelo controlador, sem texto duplicado na tela.
	feedback_title = text(root_control, "", 18)
	feedback_title.hide()
	hover_label = text(root_control, "", 18)
	hover_label.hide()

func build_sidebar() -> void:
	tools_panel = PanelContainer.new()
	tools_panel.name = "Ferramentas"
	tools_panel.add_theme_stylebox_override("panel", style(PAPER, EDGE, 1, 12))
	root_control.add_child(tools_panel)
	task_box = stack(tools_panel, 0)
	palette_row = row(task_box, 12)
	for i in range(3):
		var b := button(palette_row, Model.COLOR_NAMES[i].capitalize(), "color_%d" % i, i)
		b.custom_minimum_size = Vector2(146, 64)
		b.add_theme_font_size_override("font_size", 22)
		b.tooltip_text = "Escolher fio " + Model.COLOR_NAMES[i]
	var stretch := Control.new()
	stretch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stretch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	palette_row.add_child(stretch)
	button(palette_row, "Apagar", "erase").custom_minimum_size = Vector2(130, 64)
	button(palette_row, "Dica", "hint").custom_minimum_size = Vector2(116, 64)
	var verify := button(palette_row, "Conferir", "verify")
	verify.custom_minimum_size = Vector2(180, 64)
	primary(verify)
	build_cg_panel()

func build_cg_panel() -> void:
	var panel := Panel.new()
	panel.name = "Painel"
	panel.add_theme_stylebox_override("panel", style(PAPER, EDGE))
	root_control.add_child(panel)
	var scroll := ScrollContainer.new()
	panel.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 20
	scroll.offset_right = -20
	scroll.offset_top = 18
	scroll.offset_bottom = -18
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cg_box = stack(scroll, 10)
	text(cg_box, "APRESENTAÇÃO DE CG", 18, true)
	text(cg_box, "Transforme o novelo coral.", 22)
	axes_check = CheckBox.new()
	axes_check.text = "Mostrar eixos X / Y / Z"
	axes_check.custom_minimum_size.y = 48
	cg_box.add_child(axes_check)
	axes_check.toggled.connect(func(on: bool): action_requested.emit("axes", on))
	shadow_check = CheckBox.new()
	shadow_check.text = "Mostrar sombras"
	shadow_check.custom_minimum_size.y = 48
	shadow_check.button_pressed = true
	cg_box.add_child(shadow_check)
	shadow_check.toggled.connect(func(on: bool): action_requested.emit("shadows", on))
	make_slider("move", "Mover · translação", "Muda a posição na mesa.", -0.45, 0.45, 0.01, 0)
	make_slider("rotate", "Girar · rotação", "Gira em torno do eixo Y.", -180, 180, 1, 0)
	make_slider("scale", "Aumentar · escala", "Mantém as proporções.", 0.65, 1.35, 0.01, 1)
	button(cg_box, "Restaurar novelo", "restore_yarn")
	text(cg_box, "X: vermelho · Y: verde · Z: azul", 16)

func build_scene_labels() -> void:
	board_labels = row(root_control, 0)
	board_labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for title in ["Modelo", "Sua trama"]:
		var label := text(board_labels, title, 20, true)
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_color_override("font_color", GREEN)
	footer = row(root_control, 16)
	footer.name = "NavegacaoDaPeca"
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	button(footer, "Ajustar vista", "home").custom_minimum_size.y = 60
	primary(button(footer, "Voltar ao desafio", "back_piece"))
	primary(button(footer, "Voltar ao desafio", "close_cg"))
	buttons["work"] = buttons.home
	example_tools = row(root_control, 16)
	example_tools.alignment = BoxContainer.ALIGNMENT_CENTER
	button(example_tools, "Ver peça em destaque", "piece").custom_minimum_size.y = 60
	primary(button(example_tools, "Voltar à minha tentativa", "back_solution"))

func clear_page(key: String) -> VBoxContainer:
	var page: VBoxContainer = pages[key]
	for child in page.get_children():
		page.remove_child(child)
		child.queue_free()
	return page

func build_modals() -> void:
	super.build_modals()
	var welcome := clear_page("welcome")
	text(welcome, "ATELIÊ DO FILÉ", 18, true).add_theme_color_override("font_color", GREEN)
	var greeting := row(welcome, 20)
	var title_box := stack(greeting, 14)
	title_box.custom_minimum_size.x = 406
	text(title_box, "Uma descoberta\nem cada fio.", 40, true)
	text(title_box, "Explore o ateliê, combine cores e descubra a simetria.", 23)
	art(greeting, Vector2(258, 248))
	text(welcome, "Observar → Criar → Descobrir", 21, true)
	primary(button(welcome, "Vamos explorar!", "start"))
	var actions := row(welcome)
	button(actions, "Como jogar", "welcome_help").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button(actions, "Fechar o jogo", "welcome_quit").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text(welcome, "Desenhos didáticos inspirados no bordado filé de Alagoas.", 16).add_theme_color_override("font_color", MUTED)
	var pause := clear_page("pause")
	pause_title = text(pause, "Uma pausa?", 32, true)
	text(pause, "Sua trama continua aqui.", 22)
	primary(button(pause, "Continuar", "resume"))
	var assistance := row(pause, 12)
	button(assistance, "Como jogar", "pause_help").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button(assistance, "Som e volume", "sound_menu").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var navigation := row(pause, 12)
	button(navigation, "Recomeçar", "reset").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button(navigation, "Voltar ao ateliê", "explore").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button(pause, "Mais opções", "options_menu")
	var sound := make_page("sound")
	text(sound, "Som e volume", 32, true)
	music_label = text(sound, "Música: 60%", 22, true)
	music_slider = HSlider.new()
	music_slider.min_value = 0
	music_slider.max_value = 1
	music_slider.step = 0.05
	music_slider.value = 0.60
	music_slider.custom_minimum_size = Vector2(480, 56)
	music_slider.tooltip_text = "Volume da música de fundo. Zero desliga só a música."
	sound.add_child(music_slider)
	music_slider.value_changed.connect(func(value: float):
		music_label.text = "Música: %d%%" % roundi(value * 100)
		action_requested.emit("music_volume", value))
	volume_label = text(sound, "Efeitos e ambiente: 75%", 22, true)
	volume_slider = HSlider.new()
	volume_slider.min_value = 0
	volume_slider.max_value = 1
	volume_slider.step = 0.05
	volume_slider.value = 0.75
	volume_slider.custom_minimum_size = Vector2(480, 56)
	volume_slider.tooltip_text = "Volume dos passos, sons de tecer e ambiente"
	sound.add_child(volume_slider)
	volume_slider.value_changed.connect(func(value: float):
		volume_label.text = "Efeitos e ambiente: %d%%" % roundi(value * 100)
		action_requested.emit("volume", value))
	text(sound, "Continue o jogo para ouvir os ajustes.", 19)
	button(sound, "Som: ligado", "pause_sound")
	buttons["sound"] = buttons.pause_sound
	primary(button(sound, "Voltar à pausa", "sound_back"))
	var options := make_page("options")
	text(options, "Mais opções", 32, true)
	button(options, "Tela de início", "welcome")
	button(options, "Apresentação de CG", "cg")
	button(options, "Fechar o jogo", "pause_quit")
	primary(button(options, "Voltar à pausa", "options_back"))
	var example := button(pages.help, "Ver exemplo completo", "solution")
	pages.help.move_child(example, pages.help.get_child_count() - 2)
	guide_art.custom_minimum_size.y = 180
	(pages.success.get_child(0) as Label).text = "OBSERVAR → CRIAR → DESCOBRIR ✓"
	set_guide(0)

func set_guide(index: int) -> void:
	super.set_guide(index)
	if guide_page == 2:
		guide_copy.text = "Clique em Conferir. Use Dica para comparar um par.\nVocê pode apagar ou ver o exemplo, no seu ritmo."

func layout() -> void:
	if not is_instance_valid(footer):
		return
	var dimensions := get_viewport().get_visible_rect().size
	var width := dimensions.x
	var height := dimensions.y
	feedback_panel.position = Vector2(24, 14)
	feedback_panel.size = Vector2(width - 48, 80)
	scene_rect = Rect2(24, 130, width - 48, height - 252)
	if piece_open:
		scene_rect = Rect2(24, 112, width - 48, height - 230)
	elif cg_open:
		scene_rect = Rect2(24, 112, width - 404, height - 230)
	var bar_width := minf(1040, width - 48)
	tools_panel.position = Vector2((width - bar_width) * 0.5, height - 106)
	tools_panel.size = Vector2(bar_width, 88)
	var label_width := minf(scene_rect.size.y * 0.94, scene_rect.size.x * 0.7)
	board_labels.position = Vector2(scene_rect.get_center().x - label_width * 0.5, 102)
	board_labels.size = Vector2(label_width, 26)
	footer.position = Vector2(24, height - 92)
	footer.size = Vector2(width - 48, 60)
	example_tools.position = footer.position
	example_tools.size = footer.size
	var panel: Control = root_control.get_node("Painel")
	panel.position = Vector2(width - 360, 112)
	panel.size = Vector2(336, height - 230)
	var rectangles := [Rect2(0, 0, width, scene_rect.position.y), Rect2(0, scene_rect.end.y, width, height - scene_rect.end.y), Rect2(0, scene_rect.position.y, scene_rect.position.x, scene_rect.size.y), Rect2(scene_rect.end.x, scene_rect.position.y, width - scene_rect.end.x, scene_rect.size.y)]
	for i in range(4):
		masks[i].position = rectangles[i].position
		masks[i].size = rectangles[i].size

func refresh_layout() -> void:
	if not is_instance_valid(footer):
		return
	var painting := work_active and not piece_open and not cg_open and not solution_showing
	work_surface.visible = work_active
	tools_panel.visible = painting
	task_box.visible = painting
	board_labels.visible = work_active and not piece_open and not cg_open
	board_labels.get_child(1).text = "Reflexo" if solution_showing else "Sua trama"
	cg_box.visible = cg_open
	root_control.get_node("Painel").visible = work_active and cg_open
	footer.visible = work_active and (piece_open or cg_open)
	buttons.back_piece.visible = piece_open
	buttons.close_cg.visible = cg_open
	example_tools.visible = work_active and solution_showing and not piece_open and not cg_open
	feedback_label.text = instruction
	if not work_active:
		feedback_label.text = "Encontre a mesa do ateliê."
	elif piece_open:
		feedback_label.text = "Arraste para observar sua peça."
	elif cg_open:
		feedback_label.text = "Experimente posição, giro e tamanho."
	elif solution_showing:
		feedback_label.text = "Exemplo completo. Sua tentativa está guardada."
	active_step = 0 if solution_showing else (2 if completed else (1 if work_active else 0))
	layout()
	workspace_changed.emit()

func set_work(active: bool) -> void:
	work_active = active
	refresh_layout()

func set_piece(opened: bool) -> void:
	piece_open = opened
	refresh_layout()

func set_cg(opened: bool) -> void:
	cg_open = opened
	refresh_layout()
	action_requested.emit("cg_visible", opened)

func set_solution(showing: bool) -> void:
	solution_showing = showing
	for key in ["verify", "erase", "hint", "reset", "color_0", "color_1", "color_2"]:
		buttons[key].disabled = showing
	refresh_layout()

func set_color(index: int) -> void:
	for i in range(3):
		var chosen := i == index
		var b: Button = buttons["color_%d" % i]
		b.text = ("✓ " if chosen else "") + Model.COLOR_NAMES[i].capitalize()
		b.add_theme_stylebox_override("normal", style(Model.COLORS[i].lightened(0.73), GREEN if chosen else EDGE, 3 if chosen else 1, 10))
		var gradient := Gradient.new()
		gradient.colors = PackedColorArray([Model.COLORS[i], Model.COLORS[i]])
		var swatch := GradientTexture2D.new()
		swatch.gradient = gradient
		swatch.width = 20
		swatch.height = 20
		b.icon = swatch
		b.add_theme_constant_override("h_separation", 8)
	buttons.erase.text = "Apagar ✓" if index == -1 else "Apagar"
	buttons.erase.add_theme_stylebox_override("normal", style(Color("e6efdf") if index == -1 else PAPER, GREEN if index == -1 else EDGE, 3 if index == -1 else 1))

func set_status(message: String, heading: String = "", _tone: String = "neutral") -> void:
	instruction = message
	feedback_title.text = heading
	if work_active and not piece_open and not cg_open and not solution_showing:
		feedback_label.text = instruction

func set_completed(value: bool) -> void:
	completed = value
	active_step = 2 if value else 1

func open_modal(kind: String) -> void:
	buttons.start.text = "Continuar minha descoberta" if work_active else "Vamos explorar!"
	buttons.reset.visible = work_active and not solution_showing
	buttons.explore.visible = work_active
	buttons.cg.visible = work_active
	buttons.solution.visible = work_active and not solution_showing
	if not modal.visible:
		saved_focus = get_viewport().gui_get_focus_owner()
	modal_kind = kind
	modal.visible = true
	for key in pages:
		pages[key].visible = key == kind
	modal_card.custom_minimum_size.x = 760 if kind in ["welcome", "help", "success"] else 640
	modal_card.size = Vector2.ZERO
	var preferred := {"welcome":"start", "pause":"resume", "help":"help_next", "reset":"reset_cancel", "success":"success_piece", "quit":"quit_cancel", "sound":"sound_back", "options":"options_back"}
	call_deferred("focus_page", preferred[kind])
