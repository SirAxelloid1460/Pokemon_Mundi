# ============================================
# SlotSelectorPanel.gd
# Panel selector de slots — nueva partida y cargar partida
# Ubicación: res://Scripts/Menus/SlotSelectorPanel.gd
# ============================================
extends Control
class_name SlotSelectorPanel

signal slot_confirmed(slot: int)
signal panel_closed

enum Mode { NEW_GAME, LOAD_GAME }

@onready var title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var grid: GridContainer = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var action_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ActionButton
@onready var rename_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/RenameButton
@onready var delete_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/DeleteButton
@onready var back_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/BackButton
@onready var error_label: Label = $PanelContainer/MarginContainer/VBoxContainer/ErrorLabel

const SAVE_SLOT_CARD = preload("res://Scenes/SaveSlotCard.tscn")
const COLUMNS = 3

var mode: Mode = Mode.NEW_GAME
var selected_slot: int = -1
var save_cards: Array = []

# ============================================
# INICIALIZACIÓN
# ============================================

func _ready():
	grid.columns = COLUMNS

	action_button.pressed.connect(_on_action_pressed)
	rename_button.pressed.connect(_on_rename_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	back_button.pressed.connect(_on_back_pressed)

	error_label.visible = false
	modulate.a = 0.0

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func setup(p_mode: Mode):
	#Configura el panel según el modo y carga los slots.
	mode = p_mode

	back_button.text    = tr("SAVE_BACK")       # "Volver"
	rename_button.text  = tr("SAVE_RENAME")     # "Renombrar"
	delete_button.text  = tr("SAVE_DELETE")     # "Eliminar"

	match mode:
		Mode.NEW_GAME:
			title_label.text    = tr("SAVE_SELECT_SLOT_NEW")   # "¿Dónde guardar la nueva partida?"
			action_button.text  = tr("SAVE_CREATE")            # "Crear partida"
			rename_button.visible = false
			delete_button.visible = false

		Mode.LOAD_GAME:
			title_label.text    = tr("SAVE_SELECT_SLOT_LOAD")  # "Selecciona una partida"
			action_button.text  = tr("SAVE_LOAD")              # "Cargar"
			rename_button.visible = true
			delete_button.visible = true

	action_button.disabled = true
	rename_button.disabled = true
	delete_button.disabled = true

	_load_slots()

# ============================================
# CARGA DE SLOTS
# ============================================

func _load_slots():
	#Limpia y recarga todas las tarjetas.
	for child in grid.get_children():
		child.queue_free()
	save_cards.clear()
	selected_slot = -1

	var saves = SaveManager.get_all_saves_info()

	# En modo nueva partida: mostrar slot vacío primero
	if mode == Mode.NEW_GAME:
		_add_empty_card(SaveManager.get_next_slot())

	# Mostrar saves existentes (ya vienen ordenados por fecha)
	for save_info in saves:
		_add_save_card(save_info)

	# En modo carga: si no hay saves mostrar mensaje
	if mode == Mode.LOAD_GAME and saves.is_empty():
		error_label.text    = tr("SAVE_NO_SAVES")  # "No hay partidas guardadas"
		error_label.visible = true

	# Seleccionar automáticamente la primera tarjeta disponible
	await get_tree().process_frame
	if not save_cards.is_empty():
		var first_card = save_cards[0]
		_on_slot_selected(first_card.slot_number)
		first_card.set_selected(true)

func _add_empty_card(slot: int):
	var card = SAVE_SLOT_CARD.instantiate()
	grid.add_child(card)
	save_cards.append(card)
	card.setup_empty(slot)
	card.slot_selected.connect(_on_slot_selected)
	card.slot_double_clicked.connect(_on_slot_double_clicked)

func _add_save_card(save_info: Dictionary):
	var card = SAVE_SLOT_CARD.instantiate()
	grid.add_child(card)
	save_cards.append(card)
	card.setup(save_info)
	card.slot_selected.connect(_on_slot_selected)
	card.slot_double_clicked.connect(_on_slot_double_clicked)

# ============================================
# SELECCIÓN DE SLOT
# ============================================

func _on_slot_selected(slot: int):
	selected_slot = slot
	error_label.visible = false

	# Actualizar visual de selección
	for card in save_cards:
		card.set_selected(card.slot_number == slot)

	# Habilitar botones según estado del slot
	var has_save = SaveManager.has_save_file(slot)
	action_button.disabled = false

	match mode:
		Mode.NEW_GAME:
			# Siempre se puede crear — si existe pedirá confirmación
			action_button.disabled = false

		Mode.LOAD_GAME:
			# Solo se puede cargar si hay save
			action_button.disabled = not has_save
			rename_button.disabled = not has_save
			delete_button.disabled = not has_save

func _on_slot_double_clicked(slot: int):
	_on_slot_selected(slot)
	if not action_button.disabled:
		_on_action_pressed()

# ============================================
# BOTONES DE ACCIÓN
# ============================================

func _on_action_pressed():
	if selected_slot < 0:
		return

	match mode:
		Mode.NEW_GAME:
			await _handle_new_game()
		Mode.LOAD_GAME:
			_handle_load_game()

func _handle_new_game():
	#Inicia nueva partida en el slot seleccionado.
	var success = await SaveManager.new_game(selected_slot, false)
	if success:
		AudioManager.play_sfx("menu_select")
		emit_signal("slot_confirmed", selected_slot)
	# Si no success el SaveManager ya mostró el diálogo de confirmación

func _handle_load_game():
	#Carga la partida del slot seleccionado.
	if SaveManager.load_game(selected_slot):
		AudioManager.play_sfx("menu_select")
		emit_signal("slot_confirmed", selected_slot)
	else:
		error_label.text    = tr("SAVE_LOAD_ERROR")  # "Error al cargar la partida"
		error_label.visible = true

func _on_rename_pressed():
	if selected_slot < 0 or not SaveManager.has_save_file(selected_slot):
		return

	# Crear diálogo de renombrado
	var dialog = AcceptDialog.new()
	dialog.title = tr("SAVE_RENAME_TITLE")  # "Renombrar partida"

	var line_edit = LineEdit.new()
	var current_name = SaveManager.get_save_info(selected_slot).get("slot_name", "")
	line_edit.text = current_name
	line_edit.max_length = 32
	dialog.add_child(line_edit)

	get_tree().root.add_child(dialog)
	dialog.popup_centered()
	line_edit.grab_focus()

	dialog.confirmed.connect(func():
		var new_name = line_edit.text.strip_edges()
		if new_name != "" and new_name != current_name:
			SaveManager.rename_slot(selected_slot, new_name)
			_load_slots()  # Recargar para mostrar nuevo nombre
		dialog.queue_free()
	)
	dialog.canceled.connect(func(): dialog.queue_free())

func _on_delete_pressed():
	if selected_slot < 0 or not SaveManager.has_save_file(selected_slot):
		return

	var save_info   = SaveManager.get_save_info(selected_slot)
	var dialog      = ConfirmationDialog.new()
	dialog.title    = tr("SAVE_DELETE_TITLE")
	dialog.dialog_text = tr("SAVE_DELETE_CONFIRM") % [
		save_info.get("slot_name", "?"),
		save_info.get("player_name", "?")
	]
	dialog.ok_button_text     = tr("SAVE_DELETE_YES")
	dialog.cancel_button_text = tr("SAVE_DELETE_NO")

	get_tree().root.add_child(dialog)
	dialog.popup_centered()

	dialog.confirmed.connect(func():
		SaveManager.delete_save(selected_slot)
		selected_slot = -1
		_load_slots()
		dialog.queue_free()
	)
	dialog.canceled.connect(func(): dialog.queue_free())

func _on_back_pressed():
	AudioManager.play_sfx("menu_back")
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	emit_signal("panel_closed")
	queue_free()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		return

	if save_cards.is_empty():
		return

	var current_index = _get_selected_index()

	if event.is_action_pressed("ui_right"):
		_navigate_to((current_index + 1) % save_cards.size())
	elif event.is_action_pressed("ui_left"):
		_navigate_to((current_index - 1 + save_cards.size()) % save_cards.size())
	elif event.is_action_pressed("ui_down"):
		_navigate_to(min(current_index + COLUMNS, save_cards.size() - 1))
	elif event.is_action_pressed("ui_up"):
		_navigate_to(max(current_index - COLUMNS, 0))
	elif event.is_action_pressed("ui_accept"):
		if not action_button.disabled:
			_on_action_pressed()

func _get_selected_index() -> int:
	#Retorna el índice en save_cards de la tarjeta actualmente seleccionada.
	for i in range(save_cards.size()):
		if save_cards[i].slot_number == selected_slot:
			return i
	return 0
	
func _navigate_to(index: int):
	#Mueve la selección a la tarjeta en el índice dado.
	if index < 0 or index >= save_cards.size():
		return
	var card = save_cards[index]
	_on_slot_selected(card.slot_number)
	AudioManager.play_sfx("menu_move")
