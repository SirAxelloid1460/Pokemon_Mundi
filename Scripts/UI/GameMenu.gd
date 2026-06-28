class_name GameMenu
extends CanvasLayer
# Dispositivo de campo (estilo teléfono, PLACEHOLDER gráfico): marco coral + DOCK lateral
# persistente (Pokédex · Equipo · Personaje · Mapa · Home) + pantalla con la app actual.
# Se abre con Esc (pausa el árbol). La Mochila va aparte (tecla I, estado BAG).
# Nota: el arte real del chasis/iconos y la Pokédex anidada llegan después (correcciones gráficas).

enum State { CLOSED, DEVICE, POKEDEX, OPTIONS, BAG }

const OPTIONS_MENU_SCENE := "res://Scenes/menus/OptionsMenu.tscn"
const TITLE_SCENE := "res://Scenes/TitleScreen.tscn"
const VIEWPORT := Vector2(1280, 720)

const APPS := [
	{"key": "pokedex",   "name": "Pokédex"},
	{"key": "equipo",    "name": "Equipo"},
	{"key": "personaje", "name": "Personaje"},
	{"key": "mapa",      "name": "Mapa"},
	{"key": "home",      "name": "Home"},
]
const HOME_ITEMS := ["Guardar", "Opciones", "Salir al título"]

const CORAL := Color(0.93, 0.45, 0.36)
const FRAME_DARK := Color(0.06, 0.06, 0.08)
const SCREEN_BG := Color(0.80, 0.95, 0.96)
const ACCENT := Color(0.05, 0.42, 0.42)
const INK := Color(0.10, 0.10, 0.12)
const DOCK_BG := Color(0.20, 0.45, 0.70)
const DOCK_SEL := Color(0.22, 0.62, 0.98)

const CONTENT_RECT := Rect2(48, 40, 1060, 640)
const DOCK_X := 1190.0
const DOCK_ICON := 64.0
const DOCK_STEP := 84.0

var state: int = State.CLOSED
var app_index: int = 0
var home_index: int = 0
var home_focused: bool = false

var _root: Control
var _content: Control
var _dock_cells: Array = []     # [{rect, bg, icon, key}]
var _home_labels: Array = []
var _bag_overlay: Control

func _ready():
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_root.visible = false

# ============================================
# CONSTRUCCIÓN
# ============================================

func _build_ui():
	_root = Control.new()
	_root.size = VIEWPORT
	add_child(_root)

	# Marco placeholder: coral exterior + borde oscuro + pantalla
	var coral := ColorRect.new()
	coral.color = CORAL
	coral.size = VIEWPORT
	_root.add_child(coral)
	var black := ColorRect.new()
	black.color = FRAME_DARK
	black.position = Vector2(14, 14)
	black.size = VIEWPORT - Vector2(28, 28)
	_root.add_child(black)
	var screen := ColorRect.new()
	screen.color = SCREEN_BG
	screen.position = Vector2(22, 22)
	screen.size = VIEWPORT - Vector2(44, 44)
	_root.add_child(screen)

	# Área de contenido (app actual)
	_content = Control.new()
	_content.position = CONTENT_RECT.position
	_content.size = CONTENT_RECT.size
	_root.add_child(_content)

	# Dock lateral derecho (siempre visible)
	var total: float = DOCK_STEP * float(APPS.size() - 1)
	var y0: float = (VIEWPORT.y - total) * 0.5 - DOCK_ICON * 0.5
	for i in range(APPS.size()):
		var cy: float = y0 + i * DOCK_STEP
		var rect := Rect2(DOCK_X - 8, cy - 8, DOCK_ICON + 16, DOCK_ICON + 16)
		var bg := ColorRect.new()
		bg.position = rect.position
		bg.size = rect.size
		_root.add_child(bg)
		var icon := MenuIcon.new()
		icon.size = Vector2(DOCK_ICON, DOCK_ICON)
		icon.custom_minimum_size = icon.size
		icon.position = Vector2(DOCK_X, cy)
		_root.add_child(icon)
		_dock_cells.append({"rect": rect, "bg": bg, "icon": icon, "key": APPS[i].key})

# ============================================
# ABRIR / CERRAR
# ============================================

func open():
	if state != State.CLOSED:
		return
	if not _can_open():
		return
	state = State.DEVICE
	app_index = 2          # Personaje como pantalla de inicio
	home_focused = false
	_root.visible = true
	get_tree().paused = true
	AudioManager.play_sfx("menu_select")
	_refresh_dock()
	_show_info(_trainer_text())

func close():
	state = State.CLOSED
	_root.visible = false
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
		State.DEVICE:
			_input_device(event)
		State.BAG:
			var clk: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
			if event.is_action_pressed("ui_cancel") or event.is_action_pressed("abrir_mochila") or clk:
				close_bag()
				get_viewport().set_input_as_handled()
		State.POKEDEX, State.OPTIONS:
			pass

func _input_device(event: InputEvent):
	# --- Ratón ---
	if event is InputEventMouseMotion:
		if home_focused:
			var hi := _home_item_at(event.position)
			if hi >= 0 and hi != home_index:
				home_index = hi
				AudioManager.play_sfx("menu_move")
				_refresh_home()
		var di := _dock_at(event.position)
		if di >= 0 and di != app_index:
			app_index = di
			AudioManager.play_sfx("menu_move")
			_refresh_dock()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var dclk := _dock_at(event.position)
		if dclk >= 0:
			app_index = dclk
			_refresh_dock()
			get_viewport().set_input_as_handled()
			_activate(app_index)
			return
		if home_focused:
			var hclk := _home_item_at(event.position)
			if hclk >= 0:
				home_index = hclk
				_refresh_home()
				get_viewport().set_input_as_handled()
				_home_select(home_index)
		return
	# --- Teclado ---
	if home_focused:
		if event.is_action_pressed("ui_down"):
			home_index = (home_index + 1) % HOME_ITEMS.size()
			AudioManager.play_sfx("menu_move"); _refresh_home(); get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_up"):
			home_index = (home_index - 1 + HOME_ITEMS.size()) % HOME_ITEMS.size()
			AudioManager.play_sfx("menu_move"); _refresh_home(); get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept"):
			_home_select(home_index); get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_cancel"):
			home_focused = false; _refresh_dock(); AudioManager.play_sfx("menu_back"); get_viewport().set_input_as_handled()
	else:
		if event.is_action_pressed("ui_down"):
			app_index = (app_index + 1) % APPS.size()
			AudioManager.play_sfx("menu_move"); _refresh_dock(); get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_up"):
			app_index = (app_index - 1 + APPS.size()) % APPS.size()
			AudioManager.play_sfx("menu_move"); _refresh_dock(); get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept"):
			_activate(app_index); get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_cancel"):
			close(); get_viewport().set_input_as_handled()

func _dock_at(p: Vector2) -> int:
	for i in range(_dock_cells.size()):
		if (_dock_cells[i].rect as Rect2).has_point(p):
			return i
	return -1

func _home_item_at(p: Vector2) -> int:
	for i in range(_home_labels.size()):
		if (_home_labels[i] as Label).get_global_rect().has_point(p):
			return i
	return -1

# ============================================
# DOCK / APPS
# ============================================

func _refresh_dock():
	for i in range(_dock_cells.size()):
		var sel: bool = (not home_focused) and i == app_index
		(_dock_cells[i].bg as ColorRect).color = DOCK_SEL if sel else DOCK_BG
		(_dock_cells[i].icon as MenuIcon).setup(_dock_cells[i].key, sel)

func _activate(index: int):
	var key: String = APPS[index].key
	match key:
		"pokedex":
			_open_pokedex()
			return
		"equipo":
			_show_info(_party_text()); home_focused = false
		"personaje":
			_show_info(_trainer_text()); home_focused = false
		"mapa":
			_show_info(_map_text()); home_focused = false
		"home":
			_show_home(); home_focused = true; home_index = 0; _refresh_home()
	_refresh_dock()
	AudioManager.play_sfx("menu_select")

func _clear_content():
	for c in _content.get_children():
		c.queue_free()
	_home_labels.clear()

func _show_info(text: String):
	_clear_content()
	var bg := ColorRect.new()
	bg.color = Color(1, 1, 1, 0.88)
	bg.position = Vector2(24, 24)
	bg.size = Vector2(CONTENT_RECT.size.x - 60, CONTENT_RECT.size.y - 48)
	_content.add_child(bg)
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.position = Vector2(52, 48)
	rt.size = Vector2(CONTENT_RECT.size.x - 116, CONTENT_RECT.size.y - 96)
	rt.add_theme_font_size_override("normal_font_size", 28)
	rt.add_theme_font_size_override("bold_font_size", 34)
	rt.add_theme_color_override("default_color", INK)
	rt.text = text
	_content.add_child(rt)

func _show_home():
	_clear_content()
	var bg := ColorRect.new()
	bg.color = Color(1, 1, 1, 0.88)
	bg.position = Vector2(24, 24)
	bg.size = Vector2(CONTENT_RECT.size.x - 60, CONTENT_RECT.size.y - 48)
	_content.add_child(bg)
	var title := Label.new()
	title.text = "HOME"
	title.position = Vector2(56, 44)
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", ACCENT)
	_content.add_child(title)
	var y := 130.0
	for item in HOME_ITEMS:
		var l := Label.new()
		l.text = item
		l.position = Vector2(72, y)
		l.size = Vector2(420, 46)
		l.add_theme_font_size_override("font_size", 30)
		l.add_theme_color_override("font_color", INK)
		_content.add_child(l)
		_home_labels.append(l)
		y += 60.0

func _refresh_home():
	for i in range(_home_labels.size()):
		(_home_labels[i] as Label).add_theme_color_override("font_color", DOCK_SEL if i == home_index else INK)

func _home_select(index: int):
	match index:
		0: _do_save()
		1: _open_options()
		2: _exit_to_title()

# ============================================
# POKÉDEX (pantalla completa sobre el dispositivo)
# ============================================

func _open_pokedex():
	state = State.POKEDEX
	_root.visible = false
	var screen := PokedexScreen.new()
	screen.closed.connect(_on_pokedex_closed.bind(screen))
	add_child(screen)

func _on_pokedex_closed(screen: Node):
	if is_instance_valid(screen):
		screen.queue_free()
	state = State.DEVICE
	_root.visible = true
	_refresh_dock()

# ============================================
# HOME: GUARDAR / OPCIONES / SALIR
# ============================================

func _do_save():
	var slot: int = SaveManager.current_slot
	if slot < 0:
		slot = SaveManager.get_next_slot()
	var ok: bool = SaveManager.save_game(slot)
	home_focused = false
	_refresh_dock()
	if ok:
		_show_info("[b]GUARDAR[/b]\n\nPartida guardada en la ranura %d." % slot)
	else:
		_show_info("[b]GUARDAR[/b]\n\nNo se pudo guardar la partida.")

func _open_options():
	if not ResourceLoader.exists(OPTIONS_MENU_SCENE):
		_show_info("[b]OPCIONES[/b]\n\nMenú de opciones no disponible.")
		return
	state = State.OPTIONS
	_root.visible = false
	var opts = load(OPTIONS_MENU_SCENE).instantiate()
	opts.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(opts)
	if opts.has_signal("menu_closed"):
		opts.menu_closed.connect(func():
			if is_instance_valid(opts):
				opts.queue_free()
			state = State.DEVICE
			_root.visible = true
			home_focused = false
			_refresh_dock()
		)

func _exit_to_title():
	state = State.CLOSED
	_root.visible = false
	get_tree().paused = false
	await ScreenFade.fade_out()
	get_tree().change_scene_to_file(TITLE_SCENE)

# ============================================
# MOCHILA (atajo, tecla I) — fuera del dispositivo
# ============================================

func open_bag():
	if state != State.CLOSED:
		return
	if not _can_open():
		return
	state = State.BAG
	get_tree().paused = true
	_bag_overlay = ColorRect.new()
	_bag_overlay.color = Color(0, 0, 0, 0.45)
	_bag_overlay.size = VIEWPORT
	add_child(_bag_overlay)
	var panel := ColorRect.new()
	panel.color = Color(1, 1, 1, 0.96)
	panel.position = Vector2(340, 200)
	panel.size = Vector2(600, 320)
	_bag_overlay.add_child(panel)
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.position = Vector2(28, 24)
	rt.size = Vector2(544, 272)
	rt.add_theme_font_size_override("normal_font_size", 26)
	rt.add_theme_color_override("default_color", INK)
	rt.text = _bag_text() + "\n\n[i](ESC / I para cerrar)[/i]"
	panel.add_child(rt)
	AudioManager.play_sfx("menu_select")

func close_bag():
	state = State.CLOSED
	if is_instance_valid(_bag_overlay):
		_bag_overlay.queue_free()
		_bag_overlay = null
	get_tree().paused = false
	AudioManager.play_sfx("menu_back")

# ============================================
# CONTENIDO DE LAS APPS
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
