# ============================================
# LoadGameMenu.gd
# MenÃº de selecciÃ³n de partidas guardadas
# UbicaciÃ³n: res://scenes/menus/load_game_menu.gd
# ============================================
extends Control

signal game_loaded
signal menu_closed

@onready var save_slots_container = $Panel/MarginContainer/VBoxContainer/SaveSlotsContainer
@onready var back_button = $Panel/MarginContainer/VBoxContainer/BackButton
@onready var delete_button = $Panel/MarginContainer/VBoxContainer/DeleteButton

var save_slot_scene = preload("res://Scenes/SaveSlotCard.tscn")
var selected_slot: int = -1
var save_cards: Array = []

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	delete_button.disabled = true
	
	load_save_slots()

func load_save_slots():
	#Carga y muestra todos los slots de guardado
	# Limpiar slots existentes
	for child in save_slots_container.get_children():
		child.queue_free()
	
	save_cards.clear()
	
	# Cargar informaciÃ³n de todos los saves
	var saves = SaveManager.get_all_saves_info()
	
	# Mostrar slots (incluir vacÃ­os)
	for slot in range(1, SaveManager.MAX_SAVE_SLOTS + 1):
		var card = save_slot_scene.instantiate()
		save_slots_container.add_child(card)
		save_cards.append(card)
		
		# Buscar informaciÃ³n del slot
		var save_info = null
		for save in saves:
			if save.slot == slot:
				save_info = save
				break
		
		# Configurar la tarjeta
		if save_info:
			card.setup(save_info)
		else:
			card.setup_empty(slot)
		
		# Conectar seÃ±al de selecciÃ³n
		card.slot_selected.connect(_on_slot_selected)
		card.slot_double_clicked.connect(_on_slot_double_clicked)

func _on_slot_selected(slot: int):
	#Cuando se selecciona un slot
	selected_slot = slot
	
	# Actualizar visual de las tarjetas
	for card in save_cards:
		card.set_selected(card.slot_number == slot)
	
	# Habilitar botÃ³n de eliminar si hay save
	delete_button.disabled = not SaveManager.has_save_file(slot)

func _on_slot_double_clicked(slot: int):
	#Cuando se hace doble click en un slot
	if SaveManager.has_save_file(slot):
		load_selected_save(slot)

func load_selected_save(slot: int):
	#Carga el save del slot seleccionado
	if SaveManager.load_game(slot):
		AudioManager.play_sfx("menu_select")
		emit_signal("game_loaded")
	else:
		# Mostrar error
		push_error("Error al cargar la partida")

func _on_delete_pressed():
	#Elimina el save seleccionado con confirmaciÃ³n
	if selected_slot < 0:
		return
	
	var confirmation = ConfirmationDialog.new()
	confirmation.dialog_text = "Â¿EstÃ¡s seguro de que deseas eliminar esta partida? Esta acciÃ³n no se puede deshacer."
	confirmation.ok_button_text = "Eliminar"
	confirmation.cancel_button_text = "Cancelar"
	
	add_child(confirmation)
	confirmation.popup_centered()
	
	confirmation.confirmed.connect(func():
		SaveManager.delete_save(selected_slot)
		load_save_slots()  # Recargar lista
		selected_slot = -1
		delete_button.disabled = true
		confirmation.queue_free()
	)
	
	confirmation.canceled.connect(func():
		confirmation.queue_free()
	)

func _on_back_pressed():
	#Vuelve al menÃº principal
	AudioManager.play_sfx("menu_back")
	emit_signal("menu_closed")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
