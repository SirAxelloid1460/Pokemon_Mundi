extends NinePatchRect

signal text_displayed
signal dialogue_finished
signal option_selected(index: int)

var text_shown := false
var waiting_for_input := false
var current_dialogue_queue: Array = []
var current_dialogue_index := 0
var is_typing := false
var _type_tween: Tween

# Caracteres por segundo según game_options.text_speed (0=lento, 1=normal, 2=rápido)
const TEXT_CPS := {0: 22.0, 1: 45.0, 2: 90.0}

@onready var rich_text_label: RichTextLabel = $RichTextLabel
@onready var textbox_arrow: Sprite2D = $TextboxArrow
@onready var text_player: AnimationPlayer = $RichTextLabel/TextPlayer
@onready var option_box: PanelContainer = $ChoicesContainer

func _ready():
	text_displayed.connect(_on_text_displayed)
	option_box.SELECTED.connect(_on_option_selected)
	hide_textbox()

func _input(event: InputEvent):
	if not visible:
		return
	if not event.is_action_pressed("ui_accept"):
		return
	# Las opciones las maneja el ChoiceBox
	if option_box.visible:
		return
	# El accept es para el diálogo: consumirlo para que no lo reciba el mundo (evita reabrir)
	get_viewport().set_input_as_handled()
	# Si el texto se está escribiendo, completarlo de golpe
	if is_typing:
		_finish_typing()
		return
	# Si la flecha está visible, avanzar al siguiente diálogo
	if waiting_for_input and textbox_arrow.visible:
		advance_dialogue()

func hide_textbox():
	#Oculta completamente el textbox y resetea el estado
	visible = false
	rich_text_label.text = ""
	textbox_arrow.visible = false
	option_box.visible = false
	waiting_for_input = false
	current_dialogue_queue.clear()
	current_dialogue_index = 0

func show_dialogue(dialogue_lines: Array, options: Array = []):
	#Muestra una secuencia de diÃ¡logos.
	#dialogue_lines: Array de strings con cada lÃ­nea de diÃ¡logo
	#options: Array de opciones a mostrar despuÃ©s del Ãºltimo diÃ¡logo (opcional)
	visible = true
	current_dialogue_queue = dialogue_lines.duplicate()
	current_dialogue_index = 0
	
	# Guardar las opciones para mostrar al final
	if options.size() > 0:
		current_dialogue_queue.append({"type": "options", "data": options})
	
	# Mostrar primera lÃ­nea
	display_current_line()

func show_single_text(text: String):
	#Atajo: muestra una sola línea de diálogo.
	show_dialogue([text])

func show_text_with_options(prompt: String, options: Array):
	#Atajo: muestra una línea y, tras confirmarla, presenta opciones.
	show_dialogue([prompt], options)

func display_current_line():
	waiting_for_input = false
	option_box.visible = false
	textbox_arrow.visible = false
	
	var current_item = current_dialogue_queue[current_dialogue_index]
	
	# Verificar si es texto u opciones
	if typeof(current_item) == TYPE_DICTIONARY and current_item.get("type") == "options":
		# Mostrar opciones
		show_options(current_item["data"])
		return
	
	# Es texto normal: efecto máquina de escribir a velocidad constante
	rich_text_label.text = current_item
	text_shown = false
	_start_typewriter()

func _start_typewriter():
	is_typing = true
	rich_text_label.visible_characters = 0
	var total = rich_text_label.get_total_character_count()
	if total <= 0:
		total = rich_text_label.text.length()
	var cps = _text_cps()
	var duration = 0.0
	if cps > 0.0:
		duration = float(total) / cps
	if total <= 0 or duration <= 0.0:
		_on_typing_done()
		return
	if _type_tween and _type_tween.is_valid():
		_type_tween.kill()
	_type_tween = create_tween()
	_type_tween.tween_property(rich_text_label, "visible_characters", total, duration)
	_type_tween.finished.connect(_on_typing_done)

func _on_typing_done():
	rich_text_label.visible_characters = -1
	is_typing = false
	emit_signal("text_displayed")

func _finish_typing():
	#Completa el texto actual de golpe.
	if _type_tween and _type_tween.is_valid():
		_type_tween.kill()
	_on_typing_done()

func _text_cps() -> float:
	var idx = Game.GameData.game_options.get("text_speed", 1)
	return TEXT_CPS.get(idx, 45.0)

func advance_dialogue():
	current_dialogue_index += 1
	
	# Verificar si hay mÃ¡s lÃ­neas
	if current_dialogue_index < current_dialogue_queue.size():
		display_current_line()
	else:
		# TerminÃ³ el diÃ¡logo
		finish_dialogue()

func show_options(options: Array):
	waiting_for_input = true
	textbox_arrow.visible = false
	option_box.show_choices(options)

func finish_dialogue():
	hide_textbox()
	emit_signal("dialogue_finished")

func _on_text_displayed():
	text_shown = true
	waiting_for_input = true
	textbox_arrow.visible = true

func _on_option_selected(index: int):
	waiting_for_input = false
	hide_textbox()
	emit_signal("option_selected", index)

# (El salto de texto ahora lo gestiona _finish_typing al pulsar aceptar.)
