class_name GameMenu
extends CanvasLayer
# Menú de campo: barra horizontal de iconos (Mapa, Mochila, Pokédex, Equipo, Personaje, Otros).
# Se abre con ui_cancel (Esc) en el overworld; pausa el árbol. Navega izq/der, ui_accept abre.

enum State { CLOSED, BAR, DETAIL, OTHERS, OPTIONS, POKEDEX, BAG }

const OPTIONS_MENU_SCENE := "res://Scenes/menus/OptionsMenu.tscn"
const TITLE_SCENE := "res://Scenes/TitleScreen.tscn"
const VIEWPORT := Vector2(1280, 720)

const ENTRIES := [
	{"key": "pokedex",   "name": "Pokédex"},
	{"key": "equipo",    "name": "Equipo"},
	{"key": "personaje", "name": "Personaje"},
	{"key": "mapa",      "name": "Mapa"},
	{"key": "home",      "name": "Home"},
]
const OTHERS_ITEMS := ["Guardar", "Opciones", "Salir al título"]

const SEL_COLOR := Color(0.05, 0.42, 0.42)
const NORMAL_COLOR := Color(0, 0, 0)
const BAR_TEXT := Color(0.92, 0.93, 0.97)
const BAR_SEL := Color(1.0, 0.88, 0.35)

var state: int = State.CLOSED
var current_index: int = 0
var others_index: int = 0

var _dim: ColorRect
var _bar: PanelContainer
var _cells: Array = []
var _detail_panel: PanelContainer
var _detail_label: RichTextLabel
var _others_panel: PanelContainer
var _others_labels: Array = []

func _ready():
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_set_visible_all(false)

# ============================================
# CONSTRUCCIÓN DE UI
# ============================================

func _build_ui():
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.3)   # oscurecido tenue
	_dim.position = Vector2.ZERO
	_dim.size = VIEWPORT
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)

	# --- Barra horizontal (sin marco ni fondo) ---
	_bar = PanelContainer.new()
	_bar.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(_bar)

	var bmargin := MarginContainer.new()
	for s in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		bmargin.add_theme_constant_override(s, 14)
	_bar.add_child(bmargin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	bmargin.add_child(hbox)

	for i in range(ENTRIES.size()):
		if i > 0:
			hbox.add_child(VSeparator.new())
		var cell := VBoxContainer.new()
		cell.alignment = BoxContainer.ALIGNMENT_CENTER
		cell.add_theme_constant_override("separation", 4)
		cell.custom_minimum_size = Vector2(104, 0)
		var icon := MenuIcon.new()
		icon.custom_minimum_size = Vector2(56, 56)
		cell.add_child(icon)
		var lbl := Label.new()
		lbl.text = ENTRIES[i].name
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_color_override("font_color", BAR_TEXT)
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		lbl.add_theme_constant_override("outline_size", 4)
		cell.add_child(lbl)
		hbox.add_child(cell)
		_cells.append({"cell": cell, "icon": icon, "label": lbl})

	# --- Panel de detalle (centrado) ---
	_detail_panel = PanelContainer.new()
	_detail_panel.add_theme_stylebox_override("panel", _make_frame_stylebox())
	add_child(_detail_panel)
	var dmargin := MarginContainer.new()
	for s in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		dmargin.add_theme_constant_override(s, 24)
	_detail_panel.add_child(dmargin)
	_detail_label = RichTextLabel.new()
	_detail_label.bbcode_enabled = true
	_detail_label.fit_content = true
	_detail_label.scroll_active = false
	_detail_label.custom_minimum_size = Vector2(620, 0)
	_detail_label.add_theme_font_size_override("normal_font_size", 26)
	_detail_label.add_theme_font_size_override("bold_font_size", 30)
	_detail_label.add_theme_color_override("default_color", NORMAL_COLOR)
	dmargin.add_child(_detail_label)

	# --- Panel "Otros" (lista vertical) ---
	_others_panel = PanelContainer.new()
	_others_panel.add_theme_stylebox_override("panel", _make_frame_stylebox())
	add_child(_others_panel)
	var omargin := MarginContainer.new()
	for s in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		omargin.add_theme_constant_override(s, 28)
	_others_panel.add_child(omargin)
	var ovbox := VBoxContainer.new()
	ovbox.add_theme_constant_override("separation", 12)
	omargin.add_child(ovbox)
	for item in OTHERS_ITEMS:
		var l := Label.new()
		l.text = item
		l.add_theme_font_size_override("font_size", 28)
		l.add_theme_color_override("font_color", NORMAL_COLOR)
		ovbox.add_child(l)
		_others_labels.append(l)

func _make_frame_stylebox() -> StyleBox:
	var sb := StyleBoxTexture.new()
	sb.texture = load("res://Assets/Sprites/Frames/frame_1.png")
	sb.texture_margin_left = 6
	sb.texture_margin_top = 6
	sb.texture_margin_right = 6
	sb.texture_margin_bottom = 6
	sb.set_content_margin_all(8)
	return sb

# ============================================
# ABRIR / CERRAR
# ============================================

func open():
	if state != State.CLOSED:
		return
	if not _can_open():
		return
	current_index = 0
	state = State.BAR
	_dim.visible = true
	_detail_panel.visible = false
	_others_panel.visible = false
	_update_bar()
	get_tree().paused = true
	AudioManager.play_sfx("menu_select")
	# Mostrar la barra centrada abajo una vez calculado su tamaño
	_bar.modulate.a = 0.0
	_bar.visible = true
	await get_tree().process_frame
	_bar.reset_size()
	_bar.position = Vector2((VIEWPORT.x - _bar.size.x) * 0.5, 24.0)   # zona superior
	_bar.modulate.a = 1.0

func close():
	state = State.CLOSED
	_set_visible_all(false)
	get_tree().paused = false
	AudioManager.play_sfx("menu_back")

func _can_open() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	if not scene.is_in_group("overworld"):
		return false
	if scene.has_method("is_menu_blocked") and scene.is_menu_blocked():
		return false
	return true

func _set_visible_all(v: bool):
	if _dim: _dim.visible = v
	if _bar: _bar.visible = v
	if _detail_panel: _detail_panel.visible = v
	if _others_panel: _others_panel.visible = v

func _center_panel(panel: Control):
	panel.modulate.a = 0.0
	await get_tree().process_frame
	if not is_instance_valid(panel):
		return
	panel.reset_size()
	panel.position = Vector2((VIEWPORT.x - panel.size.x) * 0.5, (VIEWPORT.y - panel.size.y) * 0.4)
	panel.modulate.a = 1.0

# ============================================
# INPUT
# ============================================

func _input(event: InputEvent):
	match state:
		State.CLOSED:
			if event.is_action_pressed("ui_cancel"):
				open()
				get_viewport().set_input_as_handled()
			elif event.is_action_pressed("abrir_mochila"):
				open_bag()
				get_viewport().set_input_as_handled()
		State.BAG:
			var bag_click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
			if event.is_action_pressed("ui_cancel") or event.is_action_pressed("abrir_mochila") or bag_click:
				close()
				get_viewport().set_input_as_handled()
		State.BAR:
			_input_bar(event)
		State.DETAIL:
			var click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
			if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept") or click:
				_back_to_bar()
				get_viewport().set_input_as_handled()
		State.OTHERS:
			_input_others(event)
		State.OPTIONS:
			pass
		State.POKEDEX:
			pass

func _input_bar(event: InputEvent):
	# Ratón: hover resalta, clic abre
	if event is InputEventMouseMotion:
		var hov := _bar_cell_at(event.position)
		if hov >= 0 and hov != current_index:
			current_index = hov
			AudioManager.play_sfx("menu_move")
			_update_bar()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clk := _bar_cell_at(event.position)
		if clk >= 0:
			current_index = clk
			_update_bar()
			get_viewport().set_input_as_handled()
			_select(ENTRIES[current_index].key)
		return
	if event.is_action_pressed("ui_right"):
		current_index = (current_index + 1) % ENTRIES.size()
		AudioManager.play_sfx("menu_move")
		_update_bar()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		current_index = (current_index - 1 + ENTRIES.size()) % ENTRIES.size()
		AudioManager.play_sfx("menu_move")
		_update_bar()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_select(ENTRIES[current_index].key)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _input_others(event: InputEvent):
	# Ratón: hover resalta, clic selecciona
	if event is InputEventMouseMotion:
		var hov := _others_item_at(event.position)
		if hov >= 0 and hov != others_index:
			others_index = hov
			AudioManager.play_sfx("menu_move")
			_update_others()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clk := _others_item_at(event.position)
		if clk >= 0:
			others_index = clk
			_update_others()
			get_viewport().set_input_as_handled()
			_others_select(others_index)
		return
	if event.is_action_pressed("ui_down"):
		others_index = (others_index + 1) % OTHERS_ITEMS.size()
		AudioManager.play_sfx("menu_move")
		_update_others()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		others_index = (others_index - 1 + OTHERS_ITEMS.size()) % OTHERS_ITEMS.size()
		AudioManager.play_sfx("menu_move")
		_update_others()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_others_select(others_index)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_back_to_bar()
		get_viewport().set_input_as_handled()

# Índice de la celda de la barra bajo el punto de pantalla (o -1).
func _bar_cell_at(p: Vector2) -> int:
	for i in range(_cells.size()):
		var c: Control = _cells[i].cell
		if c and c.get_global_rect().has_point(p):
			return i
	return -1

# Índice del ítem de "Otros" bajo el punto (o -1).
func _others_item_at(p: Vector2) -> int:
	for i in range(_others_labels.size()):
		var l: Label = _others_labels[i]
		if l and l.get_global_rect().has_point(p):
			return i
	return -1

# ============================================
# BARRA
# ============================================

func _update_bar():
	for i in range(_cells.size()):
		var sel: bool = i == current_index
		_cells[i].icon.setup(ENTRIES[i].key, sel)
		_cells[i].label.add_theme_color_override("font_color", BAR_SEL if sel else BAR_TEXT)

func _select(key: String):
	match key:
		"pokedex":   _open_pokedex()
		"equipo":    _show_detail(_party_text())
		"personaje": _show_detail(_trainer_text())
		"mapa":      _show_detail(_map_text())
		"home":      _open_others()

# Mochila: pantalla propia abierta con atajo (tecla I por defecto), fuera del menú del dispositivo.
func open_bag():
	if state != State.CLOSED:
		return
	if not _can_open():
		return
	state = State.BAG
	_dim.visible = true
	_bar.visible = false
	_others_panel.visible = false
	_detail_label.text = _bag_text() + "\n\n[i](ESC / I para cerrar)[/i]"
	_detail_panel.visible = true
	get_tree().paused = true
	AudioManager.play_sfx("menu_select")
	_center_panel(_detail_panel)

func _show_detail(text: String):
	state = State.DETAIL
	_detail_label.text = text + "\n\n[i](ESC para volver)[/i]"
	_others_panel.visible = false
	_detail_panel.visible = true
	AudioManager.play_sfx("menu_select")
	_center_panel(_detail_panel)

func _back_to_bar():
	state = State.BAR
	_detail_panel.visible = false
	_others_panel.visible = false
	_update_bar()
	AudioManager.play_sfx("menu_back")

# ============================================
# POKÉDEX (pantalla completa)
# ============================================

func _open_pokedex():
	state = State.POKEDEX
	_bar.visible = false
	_detail_panel.visible = false
	_others_panel.visible = false
	var screen := PokedexScreen.new()
	screen.closed.connect(_on_pokedex_closed.bind(screen))
	add_child(screen)

func _on_pokedex_closed(screen: Node):
	if is_instance_valid(screen):
		screen.queue_free()
	_bar.visible = true
	_back_to_bar()

# ============================================
# OTROS (submenú vertical)
# ============================================

func _open_others():
	state = State.OTHERS
	others_index = 0
	_detail_panel.visible = false
	_others_panel.visible = true
	_update_others()
	AudioManager.play_sfx("menu_select")
	_center_panel(_others_panel)

func _update_others():
	for i in range(_others_labels.size()):
		_others_labels[i].add_theme_color_override("font_color", SEL_COLOR if i == others_index else NORMAL_COLOR)

func _others_select(index: int):
	match index:
		0: _do_save()
		1: _open_options()
		2: _exit_to_title()

func _do_save():
	var slot = SaveManager.current_slot
	if slot < 0:
		slot = SaveManager.get_next_slot()
	var ok = SaveManager.save_game(slot)
	if ok:
		_show_detail("[b]GUARDAR[/b]\n\nPartida guardada en la ranura %d." % slot)
	else:
		_show_detail("[b]GUARDAR[/b]\n\nNo se pudo guardar la partida.")

func _exit_to_title():
	state = State.CLOSED
	_set_visible_all(false)
	get_tree().paused = false
	await ScreenFade.fade_out()
	get_tree().change_scene_to_file(TITLE_SCENE)

func _open_options():
	if not ResourceLoader.exists(OPTIONS_MENU_SCENE):
		_show_detail("[b]OPCIONES[/b]\n\nMenú de opciones no disponible.")
		return
	state = State.OPTIONS
	_bar.visible = false
	_detail_panel.visible = false
	_others_panel.visible = false
	var opts = load(OPTIONS_MENU_SCENE).instantiate()
	opts.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(opts)
	if opts.has_signal("menu_closed"):
		opts.menu_closed.connect(func():
			if is_instance_valid(opts):
				opts.queue_free()
			state = State.BAR
			_bar.visible = true
			_update_bar()
		)

# ============================================
# CONTENIDO DE LOS PANELES
# ============================================

func _map_text() -> String:
	return "[b]MAPA[/b]\n\nMapa del mundo.\n(Disponible próximamente.)"

func _trainer_text() -> String:
	var g = "Chica" if Game.player_gender == "girl" else "Chico"
	return "[b]PERSONAJE[/b]\n\n" + \
		"Nombre: %s\n" % Game.player_name + \
		"Género: %s\n" % g + \
		"Dinero: %d\n" % Game.money + \
		"Medallas: %d\n" % Game.badges + \
		"Pokédex: %d capturados\n" % Game.pokedex_caught.size() + \
		"Tiempo: %s" % Game.get_play_time_formatted()

func _party_text() -> String:
	return "[b]EQUIPO[/b]\n\nAún no tienes Pokémon en tu equipo.\n(El sistema de Pokémon llegará pronto.)"

func _bag_text() -> String:
	if Game.items.is_empty():
		return "[b]MOCHILA[/b]\n\nTu mochila está vacía."
	var text = "[b]MOCHILA[/b]\n\n"
	for id in Game.items:
		text += "Objeto %s  x%d\n" % [str(id), Game.items[id]]
	return text
