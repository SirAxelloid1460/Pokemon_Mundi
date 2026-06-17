# ============================================
# SaveSlotCard.gd
# Tarjeta individual de slot de guardado
# ============================================
extends PanelContainer

signal slot_selected(slot: int)
signal slot_double_clicked(slot: int)

@onready var slot_name_label: Label = $MarginContainer/VBoxContainer/SlotName
@onready var info_container: HBoxContainer = $MarginContainer/VBoxContainer/InfoContainer
@onready var player_name_label: Label = $MarginContainer/VBoxContainer/InfoContainer/DataContainer/PlayerName
@onready var play_time_label: Label = $MarginContainer/VBoxContainer/InfoContainer/DataContainer/PlayTime
@onready var location_label: Label = $MarginContainer/VBoxContainer/InfoContainer/DataContainer/Location
@onready var empty_label: Label = $MarginContainer/VBoxContainer/EmptyLabel

var slot_number: int = -1
var is_empty: bool = true
var click_timer: float = 0.0
var click_count: int = 0
var _is_selected: bool = false

# ============================================
# INICIALIZACIÓN
# ============================================

func _ready():
	gui_input.connect(_on_gui_input)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	mouse_filter = Control.MOUSE_FILTER_STOP


# ============================================
# SETUP
# ============================================

func setup(save_info: Dictionary):
	#Configura la tarjeta con información de una partida existente.
	is_empty    = false
	slot_number = save_info.slot

	slot_name_label.text = save_info.get("slot_name", "Partida %d" % (slot_number - 1))
	player_name_label.text = save_info.get("player_name", "???")
	play_time_label.text = _format_time(save_info.get("play_time", 0.0))
	location_label.text  = _format_location(save_info.get("location", ""))

	info_container.visible = true
	empty_label.visible    = false

func setup_empty(slot: int):
	#Configura la tarjeta como slot vacío (nueva partida).
	is_empty    = true
	slot_number = slot

	slot_name_label.text   = tr("SAVE_NEW_SLOT")  # "— Nueva partida —"
	info_container.visible = false
	empty_label.visible    = true
	empty_label.text       = tr("SAVE_EMPTY")     # "Vacío"

func set_selected(selected: bool):
	#Marca o desmarca la tarjeta visualmente.
	_is_selected = selected
	if selected:
		add_theme_stylebox_override("panel", get_theme_stylebox("selected_panel", "PanelContainer"))
	else:
		remove_theme_stylebox_override("panel")

# ============================================
# UTILIDADES
# ============================================

func _format_time(seconds: float) -> String:
	var hours   = int(seconds / 3600)
	var minutes = int((seconds - hours * 3600) / 60)
	return "%02d:%02d" % [hours, minutes]

func _format_location(scene_path: String) -> String:
	if scene_path == "":
		return tr("SAVE_UNKNOWN_LOCATION")  # "Ubicación desconocida"
	return scene_path.get_file().replace(".tscn", "").replace("_", " ").capitalize()

# ============================================
# INPUT
# ============================================
func _on_mouse_entered():
	#Resalta la tarjeta al hacer hover.
	AudioManager.play_sfx("menu_move")
	emit_signal("slot_selected", slot_number)

func _on_mouse_exited():
	pass  # El panel maneja el estado visual via set_selected()

func _set_hover(hovered: bool):
	if hovered:
		add_theme_stylebox_override("panel", get_theme_stylebox("hover_panel", "PanelContainer"))
	else:
		remove_theme_stylebox_override("panel")

func _on_gui_input(event: InputEvent):
	if not event is InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return

	emit_signal("slot_selected", slot_number)

	# Detección de doble click
	if click_count == 0:
		click_count = 1
		click_timer = 0.0
	elif click_count == 1 and click_timer < 0.3:
		emit_signal("slot_double_clicked", slot_number)
		click_count = 0
	else:
		click_count = 1
		click_timer = 0.0

func _process(delta):
	if click_count > 0:
		click_timer += delta
		if click_timer > 0.3:
			click_count = 0
