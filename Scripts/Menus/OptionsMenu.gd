# ============================================
# OptionsMenu.gd
# Menú de opciones con tabs
# Ubicación: res://Scripts/Menus/OptionsMenu.gd
#
# Estructura de nodos:
#   OptionsMenu (Control)          ← Full Rect
#   └── Background (ColorRect)     ← negro, alpha 0.75
#   └── PanelContainer
#       └── MarginContainer
#           └── VBoxContainer
#               ├── TitleLabel (Label)
#               ├── TabContainer
#               │   ├── Audio (Control)
#               │   ├── Video (Control)
#               │   ├── Gameplay (Control)
#               │   ├── Interface (Control)
#               │   └── Controls (Control)
#               └── HBoxContainer          ← botones
#                   ├── ApplyButton
#                   ├── CancelButton
#                   └── ResetButton
# ============================================
extends Control
class_name OptionsMenu

signal menu_closed

# ============================================
# REFERENCIAS — ESTRUCTURA
# ============================================

@onready var tab_container: TabContainer = $PanelContainer/MarginContainer/VBoxContainer/TabContainer
@onready var apply_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ApplyButton
@onready var cancel_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CancelButton
@onready var reset_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ResetButton

# ============================================
# REFERENCIAS — TAB AUDIO
# ============================================

@onready var master_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/MasterRow/Slider
@onready var master_value: Label = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/MasterRow/Value
@onready var music_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/MusicRow/Slider
@onready var music_value: Label = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/MusicRow/Value
@onready var sfx_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/SFXRow/Slider
@onready var sfx_value: Label = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/SFXRow/Value

# ============================================
# REFERENCIAS — TAB VIDEO
# ============================================

@onready var window_mode_option: OptionButton = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Video/VBoxContainer/WindowModeRow/OptionButton
@onready var vsync_check: CheckButton = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Video/VBoxContainer/VSyncRow/CheckButton
@onready var resolution_option: OptionButton = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Video/VBoxContainer/ResolutionRow/OptionButton

# ============================================
# REFERENCIAS — TAB GAMEPLAY
# ============================================

@onready var text_speed_left: Button = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Gameplay/VBoxContainer/TextSpeedRow/ArrowLeft
@onready var text_speed_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Gameplay/VBoxContainer/TextSpeedRow/ValueLabel
@onready var text_speed_right: Button = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Gameplay/VBoxContainer/TextSpeedRow/ArrowRight
@onready var battle_style_left: Button = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Gameplay/VBoxContainer/BattleStyleRow/ArrowLeft
@onready var battle_style_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Gameplay/VBoxContainer/BattleStyleRow/ValueLabel
@onready var battle_style_right: Button = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Gameplay/VBoxContainer/BattleStyleRow/ArrowRight
@onready var battle_animations_check: CheckButton = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Gameplay/VBoxContainer/BattleAnimationsRow/CheckButton

# ============================================
# REFERENCIAS — TAB INTERFACE
# ============================================

@onready var language_left: Button = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Interface/VBoxContainer/LanguageRow/ArrowLeft
@onready var language_flag: TextureRect = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Interface/VBoxContainer/LanguageRow/Flag
@onready var language_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Interface/VBoxContainer/LanguageRow/ValueLabel
@onready var language_right: Button = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Interface/VBoxContainer/LanguageRow/ArrowRight
@onready var theme_left: Button = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Interface/VBoxContainer/ThemeRow/ArrowLeft
@onready var theme_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Interface/VBoxContainer/ThemeRow/ValueLabel
@onready var theme_right: Button = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Interface/VBoxContainer/ThemeRow/ArrowRight

# ============================================
# REFERENCIAS — TAB CONTROLES
# ============================================

@onready var keyboard_list: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Controls/HSplitContainer/KeyboardContainer/ScrollContainer/KeyboardList
@onready var gamepad_list: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Controls/HSplitContainer/GamepadContainer/ScrollContainer/GamepadList

# ============================================
# ESTADO
# ============================================

# Opciones originales al abrir el menú (para cancelar)
var _original_options: Dictionary = {}
# Opciones temporales (se aplican en tiempo real, se revierten al cancelar)
var _temp_options: Dictionary = {}

var _is_remapping: bool = false
var _remap_action: String = ""
var _remap_device: String = ""  # "keyboard" o "gamepad"
var _remap_button: Button = null

# Acciones a mapear
const ACTIONS = [
	{"name": "ui_up",      "display": "Arriba"},
	{"name": "ui_down",    "display": "Abajo"},
	{"name": "ui_left",    "display": "Izquierda"},
	{"name": "ui_right",   "display": "Derecha"},
	{"name": "ui_accept",  "display": "Aceptar"},
	{"name": "ui_cancel",  "display": "Cancelar"},
	{"name": "quick_save", "display": "Guardado Rápido"},
	{"name": "menu",       "display": "Menú"},
]

const RESOLUTIONS = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

# ============================================
# INICIALIZACIÓN
# ============================================

func _ready():
	modulate.a = 0.0
	_original_options = Game.GameData.game_options.duplicate(true)
	_temp_options     = Game.GameData.game_options.duplicate(true)

	_setup_texts()
	_setup_audio_tab()
	_setup_video_tab()
	_setup_gameplay_tab()
	_setup_interface_tab()
	_setup_controls_tab()
	_connect_signals()

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func _setup_texts():
	apply_button.text  = tr("OPT_APPLY")
	cancel_button.text = tr("OPT_CANCEL")
	reset_button.text  = tr("OPT_RESET")

	tab_container.set_tab_title(0, tr("OPT_TAB_AUDIO"))
	tab_container.set_tab_title(1, tr("OPT_TAB_VIDEO"))
	tab_container.set_tab_title(2, tr("OPT_TAB_GAMEPLAY"))
	tab_container.set_tab_title(3, tr("OPT_TAB_INTERFACE"))
	tab_container.set_tab_title(4, tr("OPT_TAB_CONTROLS"))

func _connect_signals():
	apply_button.pressed.connect(_on_apply_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	reset_button.pressed.connect(_on_reset_pressed)

	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)

	window_mode_option.item_selected.connect(_on_window_mode_changed)
	vsync_check.toggled.connect(_on_vsync_toggled)
	resolution_option.item_selected.connect(_on_resolution_changed)

	text_speed_left.pressed.connect(func(): _cycle_text_speed(-1))
	text_speed_right.pressed.connect(func(): _cycle_text_speed(1))
	battle_style_left.pressed.connect(func(): _cycle_battle_style(-1))
	battle_style_right.pressed.connect(func(): _cycle_battle_style(1))
	battle_animations_check.toggled.connect(_on_battle_animations_toggled)

	language_left.pressed.connect(func(): _cycle_language(-1))
	language_right.pressed.connect(func(): _cycle_language(1))
	theme_left.pressed.connect(func(): _cycle_theme(-1))
	theme_right.pressed.connect(func(): _cycle_theme(1))

# ============================================
# SETUP DE TABS
# ============================================

func _setup_audio_tab():
	master_slider.value = _temp_options.get("master_volume", 100)
	music_slider.value  = _temp_options.get("music_volume", 100)
	sfx_slider.value    = _temp_options.get("sound_volume", 100)
	_update_volume_labels()

func _setup_video_tab():
	window_mode_option.clear()
	window_mode_option.add_item(tr("OPT_WINDOWED"),    0)
	window_mode_option.add_item(tr("OPT_FULLSCREEN"),  1)
	window_mode_option.add_item(tr("OPT_BORDERLESS"),  2)

	match DisplayServer.window_get_mode():
		DisplayServer.WINDOW_MODE_WINDOWED:   window_mode_option.select(0)
		DisplayServer.WINDOW_MODE_FULLSCREEN: window_mode_option.select(1)
		DisplayServer.WINDOW_MODE_MAXIMIZED:  window_mode_option.select(2)
		_: window_mode_option.select(0)

	vsync_check.button_pressed = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED

	resolution_option.clear()
	var current_size = DisplayServer.window_get_size()
	for i in range(RESOLUTIONS.size()):
		var res = RESOLUTIONS[i]
		resolution_option.add_item("%dx%d" % [res.x, res.y], i)
		if res == current_size:
			resolution_option.select(i)

const TEXT_SPEED_OPTIONS = ["OPT_SPEED_SLOW", "OPT_SPEED_NORMAL", "OPT_SPEED_FAST"]
const BATTLE_STYLE_OPTIONS = ["OPT_STYLE_SWITCH", "OPT_STYLE_SET"]

var _text_speed_index: int = 0
var _battle_style_index: int = 0

func _setup_gameplay_tab():
	_text_speed_index  = _temp_options.get("text_speed", 1)
	_battle_style_index = _temp_options.get("battle_style", 0)
	_update_text_speed_label()
	_update_battle_style_label()
	battle_animations_check.button_pressed = _temp_options.get("battle_scene", true)

func _update_text_speed_label():
	text_speed_label.text = tr(TEXT_SPEED_OPTIONS[_text_speed_index])

func _update_battle_style_label():
	battle_style_label.text = tr(BATTLE_STYLE_OPTIONS[_battle_style_index])

var _language_index: int = 0
var _theme_index: int = 0

func _setup_interface_tab():
	# Idioma — encontrar índice actual
	var languages = LocalizationManager.get_available_languages()
	var current_lang = _temp_options.get("language", "es_ES")
	_language_index = 0
	for i in range(languages.size()):
		if languages[i].code == current_lang:
			_language_index = i
			break
	_update_language_label()

	# Tema — encontrar índice actual
	var themes = ThemeManager.get_available_themes()
	var current_theme = _temp_options.get("ui_theme", "default")
	_theme_index = 0
	for i in range(themes.size()):
		if themes[i].id == current_theme:
			_theme_index = i
			break
	_update_theme_label()

func _update_language_label():
	var languages = LocalizationManager.get_available_languages()
	if languages.is_empty():
		return
	var lang = languages[_language_index]
	language_label.text = lang.name

	# Cargar bandera
	var flag_path = lang.get("flag", "")
	if flag_path != "" and ResourceLoader.exists(flag_path):
		language_flag.texture = load(flag_path)
		language_flag.visible = true
	else:
		language_flag.visible = false

func _update_theme_label():
	var themes = ThemeManager.get_available_themes()
	if themes.is_empty():
		return
	theme_label.text = themes[_theme_index].name

func _setup_controls_tab():
	_build_control_list(keyboard_list, "keyboard")
	_build_control_list(gamepad_list, "gamepad")

func _build_control_list(list: VBoxContainer, device: String):
	for child in list.get_children():
		child.queue_free()

	for action in ACTIONS:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var label = Label.new()
		label.text = action.display
		label.custom_minimum_size = Vector2(180, 32)
		label.add_theme_font_size_override("font_size", 32)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(label)

		var btn = Button.new()
		btn.text = _get_key_name(action.name, device)
		btn.custom_minimum_size = Vector2(140, 32)
		btn.add_theme_font_size_override("font_size", 24)
		btn.pressed.connect(_on_remap_pressed.bind(action.name, device, btn))
		row.add_child(btn)

		list.add_child(row)

func _get_key_name(action_name: String, device: String) -> String:
	var events = InputMap.action_get_events(action_name)
	for event in events:
		if device == "keyboard" and event is InputEventKey:
			return OS.get_keycode_string(event.physical_keycode)
		elif device == "gamepad" and event is InputEventJoypadButton:
			return "Botón %d" % event.button_index
	return tr("OPT_UNASSIGNED")

# ============================================
# CALLBACKS — AUDIO
# ============================================

func _on_master_changed(value: float):
	_temp_options.master_volume = int(value)
	_update_volume_labels()
	AudioManager.set_master_volume(value)

func _on_music_changed(value: float):
	_temp_options.music_volume = int(value)
	_update_volume_labels()
	AudioManager.set_music_volume(value)

func _on_sfx_changed(value: float):
	_temp_options.sound_volume = int(value)
	_update_volume_labels()
	AudioManager.set_sfx_volume(value)
	AudioManager.play_sfx("menu_cursor")

func _update_volume_labels():
	master_value.text = "%d%%" % int(master_slider.value)
	music_value.text  = "%d%%" % int(music_slider.value)
	sfx_value.text    = "%d%%" % int(sfx_slider.value)

# ============================================
# CALLBACKS — VIDEO
# ============================================

func _on_window_mode_changed(index: int):
	match index:
		0: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

func _on_vsync_toggled(toggled: bool):
	if toggled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func _on_resolution_changed(index: int):
	var res = RESOLUTIONS[index]
	DisplayServer.window_set_size(res)
	var screen_size = DisplayServer.screen_get_size()
	DisplayServer.window_set_position((screen_size - res) / 2)

# ============================================
# CALLBACKS — GAMEPLAY
# ============================================

func _cycle_text_speed(direction: int):
	_text_speed_index = (_text_speed_index + direction + TEXT_SPEED_OPTIONS.size()) % TEXT_SPEED_OPTIONS.size()
	_temp_options.text_speed = _text_speed_index
	_update_text_speed_label()
	AudioManager.play_sfx("menu_move")

func _cycle_battle_style(direction: int):
	_battle_style_index = (_battle_style_index + direction + BATTLE_STYLE_OPTIONS.size()) % BATTLE_STYLE_OPTIONS.size()
	_temp_options.battle_style = _battle_style_index
	_update_battle_style_label()
	AudioManager.play_sfx("menu_move")

func _on_battle_animations_toggled(toggled: bool):
	_temp_options.battle_scene = toggled

# ============================================
# CALLBACKS — INTERFACE
# ============================================

func _cycle_language(direction: int):
	var languages = LocalizationManager.get_available_languages()
	if languages.is_empty():
		return
	_language_index = (_language_index + direction + languages.size()) % languages.size()
	var lang = languages[_language_index]
	_temp_options.language = lang.code
	LocalizationManager.set_language(lang.code)
	_update_language_label()
	AudioManager.play_sfx("menu_move")

func _cycle_theme(direction: int):
	var themes = ThemeManager.get_available_themes()
	if themes.is_empty():
		return
	_theme_index = (_theme_index + direction + themes.size()) % themes.size()
	var theme = themes[_theme_index]
	_temp_options.ui_theme = theme.id
	ThemeManager.apply_theme(theme.id)
	_update_theme_label()
	AudioManager.play_sfx("menu_move")

# ============================================
# CALLBACKS — CONTROLES
# ============================================

func _on_remap_pressed(action_name: String, device: String, btn: Button):
	if _is_remapping:
		return
	_is_remapping   = true
	_remap_action   = action_name
	_remap_device   = device
	_remap_button   = btn
	btn.text        = tr("OPT_PRESS_KEY")
	btn.disabled    = true

func _input(event: InputEvent):
	if _is_remapping:
		_handle_remap_input(event)
		return

	if event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()

func _handle_remap_input(event: InputEvent):
	var valid = false

	if _remap_device == "keyboard" and event is InputEventKey and event.pressed:
		# Eliminar eventos de teclado existentes para esta acción
		var existing = InputMap.action_get_events(_remap_action)
		for e in existing:
			if e is InputEventKey:
				InputMap.action_erase_event(_remap_action, e)
		InputMap.action_add_event(_remap_action, event)
		_remap_button.text = OS.get_keycode_string(event.physical_keycode)
		valid = true

	elif _remap_device == "gamepad" and event is InputEventJoypadButton and event.pressed:
		var existing = InputMap.action_get_events(_remap_action)
		for e in existing:
			if e is InputEventJoypadButton:
				InputMap.action_erase_event(_remap_action, e)
		InputMap.action_add_event(_remap_action, event)
		_remap_button.text = "Botón %d" % event.button_index
		valid = true

	if valid:
		_remap_button.disabled = false
		_is_remapping          = false
		_remap_action          = ""
		_remap_device          = ""
		_remap_button          = null
		get_viewport().set_input_as_handled()

# ============================================
# APLICAR / CANCELAR / RESET
# ============================================

func _on_apply_pressed():
	#Guarda las opciones actuales permanentemente.
	Game.GameData.game_options = _temp_options.duplicate(true)
	_original_options          = _temp_options.duplicate(true)

	# Guardar config independientemente del save activo
	SaveManager.save_config()

	if SaveManager.current_slot >= 0:
		SaveManager.save_game()

	AudioManager.play_sfx("menu_select")
	_close()

func _on_cancel_pressed():
	#Revierte todos los cambios al estado original.
	AudioManager.play_sfx("menu_back")

	# Revertir audio
	AudioManager.set_master_volume(_original_options.get("master_volume", 100))
	AudioManager.set_music_volume(_original_options.get("music_volume", 100))
	AudioManager.set_sfx_volume(_original_options.get("sound_volume", 100))

	# Revertir idioma
	LocalizationManager.set_language(_original_options.get("language", "es_ES"))

	# Revertir tema
	ThemeManager.apply_theme(_original_options.get("ui_theme", "default"))

	# Revertir video
	var window_mode = _original_options.get("window_mode", 0)
	match window_mode:
		0: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

	_close()

func _on_reset_pressed():
	#Resetea todas las opciones a valores por defecto.
	var confirmation = ConfirmationDialog.new()
	confirmation.dialog_text      = tr("OPT_RESET_CONFIRM")
	confirmation.ok_button_text   = tr("OPT_RESET_YES")
	confirmation.cancel_button_text = tr("OPT_RESET_NO")
	get_tree().root.add_child(confirmation)
	confirmation.popup_centered()

	confirmation.confirmed.connect(func():
		_temp_options = {
			"text_speed":    1,
			"battle_style":  0,
			"battle_scene":  true,
			"master_volume": 100,
			"sound_volume":  100,
			"music_volume":  100,
			"ui_theme":      "default",
			"language":      "es_ES",
		}
		# Aplicar inmediatamente
		AudioManager.set_master_volume(100)
		AudioManager.set_music_volume(100)
		AudioManager.set_sfx_volume(100)
		LocalizationManager.set_language("es_ES")
		ThemeManager.apply_theme("default")

		# Recargar controles por defecto
		InputMap.load_from_project_settings()
		_setup_controls_tab()

		# Recargar UI
		_setup_audio_tab()
		_setup_video_tab()
		_setup_gameplay_tab()
		_setup_interface_tab()

		confirmation.queue_free()
	)
	confirmation.canceled.connect(func(): confirmation.queue_free())

func _close():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	emit_signal("menu_closed")
	queue_free()
