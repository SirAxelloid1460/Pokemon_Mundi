extends PanelContainer

signal SELECTED(index: int)

const BOX_LEFT := 279.0                 # borde izquierdo = borde izquierdo del textbox
const BOX_BOTTOM := 521.0               # borde inferior = techo del textbox (esquinas coinciden)
const CHOICE_FONT := 28
const ARROW_Y_NUDGE := -3.0            # ajuste fino del centrado vertical de la flecha
const SEL_COLOR := Color(0.05, 0.42, 0.42)
const NORMAL_COLOR := Color(0, 0, 0)

@onready var choices_list: VBoxContainer = $MarginContainer/Choices
@onready var choices_prefab: Button = $MarginContainer/Choices/Option
@onready var option_arrow: TextureRect = $OptionBox/OptionArrow
@onready var margin_box: MarginContainer = $MarginContainer

var current_selection: int = 0
var _options: Array = []
var _buttons: Array[Button] = []

func _ready():
	choices_prefab.visible = false   # plantilla oculta; las opciones reales son duplicados
	# Márgenes laterales para que el texto no toque los bordes (izq. deja sitio a la flecha)
	margin_box.add_theme_constant_override("margin_left", 42)
	margin_box.add_theme_constant_override("margin_right", 26)
	hide_choices()

func show_choices(options: Array, start_option: int = 0):
	#La selección se marca con flecha + color (el texto no cambia, no se mueve).
	_options = options
	_build_buttons()
	if _options.is_empty():
		return
	current_selection = clamp(start_option, 0, _options.size() - 1)

	# Oculta mientras el contenedor calcula tamaños; luego encoge a contenido y coloca
	modulate.a = 0.0
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	visible = true
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	reset_size()
	# Esquina inferior-izquierda fija en la superior-izquierda del textbox; crece hacia arriba
	var box_size = get_combined_minimum_size()
	global_position = Vector2(BOX_LEFT, BOX_BOTTOM - box_size.y)
	_update_selection()
	modulate.a = 1.0

func hide_choices():
	visible = false
	current_selection = 0

func _build_buttons():
	for btn in _buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	_buttons.clear()

	if option_arrow:
		option_arrow.visible = false   # se muestra al colocarla correctamente

	for i in range(_options.size()):
		var btn: Button = choices_prefab.duplicate()
		btn.visible = true
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.text = str(_options[i])
		btn.add_theme_font_size_override("font_size", CHOICE_FONT)
		btn.add_theme_color_override("font_hover_color", SEL_COLOR)
		btn.pressed.connect(_on_button_pressed.bind(i))
		btn.mouse_entered.connect(_on_button_hovered.bind(i))
		choices_list.add_child(btn)
		_buttons.append(btn)

	# Ancho uniforme según la opción más larga
	var font := choices_prefab.get_theme_font("font")
	var maxw := 0.0
	if font:
		for opt in _options:
			maxw = max(maxw, font.get_string_size(str(opt), HORIZONTAL_ALIGNMENT_LEFT, -1, CHOICE_FONT).x)
	for b in _buttons:
		b.custom_minimum_size = Vector2(maxw, b.custom_minimum_size.y)

func _update_selection():
	for i in range(_buttons.size()):
		_buttons[i].add_theme_color_override("font_color", SEL_COLOR if i == current_selection else NORMAL_COLOR)
	_position_arrow()

func _position_arrow():
	if option_arrow == null or _buttons.is_empty():
		return
	var btn := _buttons[current_selection]
	if btn.size == Vector2.ZERO:
		return   # layout aún no listo
	var arrow_w = option_arrow.size.x if option_arrow.size.x > 0.0 else 18.0
	var arrow_h = option_arrow.size.y if option_arrow.size.y > 0.0 else 24.0
	option_arrow.global_position = Vector2(
		btn.global_position.x - arrow_w - 6.0,
		btn.global_position.y + (btn.size.y - arrow_h) * 0.5 + ARROW_Y_NUDGE
	)
	option_arrow.visible = true

func _move_selection(direction: int):
	if _options.is_empty():
		return
	current_selection = (current_selection + direction + _options.size()) % _options.size()
	AudioManager.play_sfx("menu_move")
	_update_selection()

func _confirm():
	if _options.is_empty():
		return
	AudioManager.play_sfx("menu_select")
	visible = false
	SELECTED.emit(current_selection)

func _on_button_hovered(index: int):
	if index == current_selection:
		return
	current_selection = index
	AudioManager.play_sfx("menu_move")
	_update_selection()

func _on_button_pressed(index: int):
	current_selection = index
	_confirm()

func _input(event: InputEvent):
	if not visible or _options.is_empty():
		return

	if event.is_action_pressed("ui_down"):
		_move_selection(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_move_selection(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_confirm()
		get_viewport().set_input_as_handled()
