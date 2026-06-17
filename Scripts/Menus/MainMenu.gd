# ============================================
# MainMenu.gd
# Menú principal con gestión completa de partidas
# ============================================
extends Control

@onready var btn_new_game: Button = $MarginContainer/VBoxContainer/NewGame
@onready var btn_continue: Button = $MarginContainer/VBoxContainer/Continue
@onready var btn_load_game: Button = $MarginContainer/VBoxContainer/LoadGame
@onready var btn_options: Button = $MarginContainer/VBoxContainer/Options
@onready var btn_exit: Button = $MarginContainer/VBoxContainer/Exit
@onready var cursor: Sprite2D = $Cursor

const SLOT_SELECTOR_SCENE  = preload("res://Scenes/menus/SlotSelectorPanel.tscn")
const OPTIONS_MENU_SCENE   = preload("res://Scenes/menus/OptionsMenu.tscn")
const PRESENTATION_SCENE   = "res://Scenes/intro/Presentation.tscn"
const PLAYER_ROOM_SCENE    = "res://Scenes/world/PlayerRoom.tscn"

# Offset del cursor: a la izquierda del botón, punta levemente encima del centro
const CURSOR_OFFSET_X = -4.0  # distancia a la izquierda
const CURSOR_OFFSET_Y = 0.0 # sube un poco respecto al centro vertical

var options: Array = []
var current_option: int = 0
var can_select: bool = false

var has_saves: bool = false

# ============================================
# INICIALIZACIÓN
# ============================================

func _ready():
	# Ocultar menu principal
	modulate.a = 0.0
	cursor.visible = false
	
	has_saves = SaveManager.has_any_save()
	
	options = [btn_new_game, btn_continue, btn_load_game, btn_options, btn_exit]

	_setup_button_texts()
	_setup_button_signals()

	# Esperar un frame para que los botones tengan su fuente y tamaño listos
	await get_tree().process_frame
	_setup_button_sizes()

	# Continue y LoadGame solo disponibles si hay partidas guardadas
	_set_option_available(btn_continue,  has_saves)
	_set_option_available(btn_load_game, has_saves)

	# Enfocar el botón inicial según si hay partidas guardadas
	current_option = 2 if has_saves else 0  # LoadGame o NewGame
	
	# Esperar a que el layout y los tamaños estén listos
	await get_tree().process_frame
	await get_tree().process_frame

	# Aparecer con fade in suave
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	await tween.finished

	# Ahora los botones tienen su posición correcta
	_focus_option(current_option)
	cursor.visible = true
	can_select = true

func _setup_button_texts():
	#Asigna los textos localizados a cada botón.
	btn_new_game.text  = tr("NEWGAME")   # "Nueva Partida"
	btn_continue.text  = tr("CONTINUE")   # "Continuar"
	btn_load_game.text = tr("LOADGAME")  # "Cargar Partida"
	btn_options.text   = tr("OPTIONS")    # "Opciones"
	btn_exit.text      = tr("EXITGAME")       # "Salir"

func _setup_button_sizes():
	#Ajusta cada botón al tamaño de su texto + 2 caracteres capitales de padding.
	for btn in options:
		var font = btn.get_theme_font("font")
		var font_size = btn.get_theme_font_size("font_size")
		if not font:
			continue
		var text_width = font.get_string_size(btn.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var char_width = font.get_string_size("M", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var padding    = char_width * 4.0  # 1 carácter capital a cada lado
		btn.custom_minimum_size = Vector2(text_width + padding, btn.custom_minimum_size.y)
		btn.size = btn.custom_minimum_size  # forzar reajuste inmediato

	# Forzar recálculo del layout
	$MarginContainer/VBoxContainer.queue_sort()
	$MarginContainer.queue_sort()


func _setup_button_signals():
	#Conecta clicks y hover de cada botón.
	btn_new_game.pressed.connect(start_new_game)
	btn_continue.pressed.connect(continue_game)
	btn_load_game.pressed.connect(load_game)
	btn_options.pressed.connect(open_options)
	btn_exit.pressed.connect(quit_game)

	# Desactivar navegación automática de Godot en todos los botones
	for btn in options:
		btn.focus_neighbor_top    = btn.get_path()
		btn.focus_neighbor_bottom = btn.get_path()
		btn.focus_neighbor_left   = btn.get_path()
		btn.focus_neighbor_right  = btn.get_path()
		btn.focus_next            = btn.get_path()
		btn.focus_previous        = btn.get_path()


	# Hover por mouse
	btn_new_game.mouse_entered.connect(func(): _on_button_hovered(0))
	btn_continue.mouse_entered.connect(func(): _on_button_hovered(1))
	btn_load_game.mouse_entered.connect(func(): _on_button_hovered(2))
	btn_options.mouse_entered.connect(func(): _on_button_hovered(3))
	btn_exit.mouse_entered.connect(func(): _on_button_hovered(4))

func _set_option_available(option: Button, available: bool):
	option.visible  = available
	option.disabled = not available


# ============================================
# CURSOR
# ============================================

func _on_button_focused(index: int):
	#Teclado/gamepad movió el focus.
	if current_option == index:
		return
	current_option = index
	_move_cursor_to(options[index])

func _on_button_hovered(index: int):
	#Mouse entró en un botón.
	if options[index].disabled:
		return
	if current_option != index:
		AudioManager.play_sfx("menu_move")
	current_option = index
	options[index].grab_focus()
	_move_cursor_to(options[index])

func _move_cursor_to(btn: Button):
	#Posiciona el cursor a la izquierda del botón, centrado verticalmente con offset.
	var target = Vector2(
		btn.global_position.x + CURSOR_OFFSET_X,
		btn.global_position.y + btn.size.y / 2.0 + CURSOR_OFFSET_Y
	)
	cursor.global_position = target

func _focus_option(index: int):
	#Enfoca un botón y mueve el cursor sin reproducir sonido.
	options[index].grab_focus()
	_move_cursor_to(options[index])

# ============================================
# INPUT
# ============================================

func _input(event):
	if not can_select:
		return

	if event.is_action_pressed("ui_down"):
		_navigate(1)
	elif event.is_action_pressed("ui_up"):
		_navigate(-1)
	elif event.is_action_pressed("ui_accept"):
		# Evitar doble disparo cuando el botón con focus ya maneja ui_accept
		if not options[current_option].has_focus():
			select_option()


func _navigate(direction: int):
	#Mueve el foco al siguiente botón disponible en la dirección indicada.
	var next = current_option
	var attempts = 0
	while attempts < options.size() - 1:
		next = (next + direction + options.size()) % options.size()
		if not options[next].disabled:
			break
		attempts += 1

	if next == current_option:
		return

	AudioManager.play_sfx("menu_move")
	current_option = next
	# grab_focus() sin activar la navegación automática de Godot
	options[current_option].grab_focus()
	_move_cursor_to(options[current_option])


# ============================================
# SELECCIÓN
# ============================================

func select_option():
	match current_option:
		0: start_new_game()
		1: continue_game()
		2: load_game()
		3: open_options()
		4: quit_game()

# ============================================
# NUEVA PARTIDA
# ============================================

func start_new_game():
	can_select = false
	AudioManager.play_sfx("menu_select")
	_open_slot_selector(SlotSelectorPanel.Mode.NEW_GAME)


# ============================================
# CONTINUAR (última partida guardada)
# ============================================

func continue_game():
	if not has_saves:
		AudioManager.play_sfx("menu_error")
		return

	can_select = false
	AudioManager.play_sfx("menu_select")

	var loaded = SaveManager.load_latest_save()
	if not loaded:
		can_select = true
		return

	await ScreenFade.fade_out()
	_go_to_active_scene()

# ============================================
# CARGAR PARTIDA (menú de slots)
# ============================================

func load_game():
	if not has_saves:
		AudioManager.play_sfx("menu_error")
		return

	can_select = false
	AudioManager.play_sfx("menu_select")

	_open_slot_selector(SlotSelectorPanel.Mode.LOAD_GAME)


func _on_game_loaded():
	await ScreenFade.fade_out()
	_go_to_active_scene()


func _on_load_menu_closed():
	can_select = true

# ============================================
# SLOT SELECTOR
# ============================================

func _open_slot_selector(mode: SlotSelectorPanel.Mode):
	var panel = SLOT_SELECTOR_SCENE.instantiate()
	add_child(panel)
	panel.setup(mode)

	match mode:
		SlotSelectorPanel.Mode.NEW_GAME:
			panel.slot_confirmed.connect(_on_new_game_slot_confirmed)
		SlotSelectorPanel.Mode.LOAD_GAME:
			panel.slot_confirmed.connect(_on_load_slot_confirmed)

	panel.panel_closed.connect(_on_slot_selector_closed)

func _on_new_game_slot_confirmed(_slot: int):
	await ScreenFade.fade_out()
	get_tree().change_scene_to_file(PRESENTATION_SCENE)

func _on_load_slot_confirmed(_slot: int):
	_on_game_loaded()

func _on_slot_selector_closed():
	can_select = true

# ============================================
# OPCIONES
# ============================================

func open_options():
	can_select = false

	AudioManager.play_sfx("menu_select")
	
	var opts = OPTIONS_MENU_SCENE.instantiate()

	add_child(opts)
	opts.menu_closed.connect(func(): can_select = true)

# ============================================
# SALIR
# ============================================

func quit_game():
	can_select = false
	AudioManager.play_sfx("menu_select")
	await ScreenFade.fade_out()
	get_tree().quit()

# ============================================
# UTILIDADES
# ============================================

func _go_to_active_scene():
	#Va a la escena activa guardada o a PlayerRoom por defecto.
	var active_scene = Game.GameData.active_scene
	if active_scene != "" and ResourceLoader.exists(active_scene):
		get_tree().change_scene_to_file(active_scene)
	else:
		get_tree().change_scene_to_file(PLAYER_ROOM_SCENE)
