# ============================================
# SaveManager.gd (Autoload/Singleton)
# Sistema de guardado con slots infinitos y nombres
# Ubicación: res://Scripts/Autoloads/SaveManager.gd
#
# IMPORTANTE: Configurar como AutoLoad
# Project Settings → AutoLoad → Nombre: "SaveManager"
#
# SLOTS:
#   0    → Auto-save
#   1    → Quick-save
#   2-N  → Slots manuales (infinitos)
#
# ARCHIVOS:
#   user://save_game_slot_0.dat   (auto)
#   user://save_game_slot_1.dat   (quick)
#   user://save_game_slot_2.dat   (manual 1)
#   user://save_game_slot_3.dat   ...etc
# ============================================
extends Node

# ============================================
# CONSTANTES
# ============================================

const SAVE_PATH       = "user://save_game_slot_{slot}.dat"
const AUTO_SAVE_SLOT  = 0
const QUICK_SAVE_SLOT = 1
const SAVE_VERSION    = 1
const MAX_DISPLAY     = 10   # Slots visibles en el grid a la vez

# ============================================
# VARIABLES
# ============================================

var current_slot: int = -1

# ============================================
# VALIDACIÓN DE SLOTS
# ============================================

func is_valid_slot(slot: int) -> bool:
	#Slots válidos: 0 (auto), 1-N (manuales), 99 (quick).
	if slot == AUTO_SAVE_SLOT:  return true
	if slot == QUICK_SAVE_SLOT: return true
	if slot >= 2:               return true
	return false

func validate_slot(slot: int, context: String = "") -> bool:
	if not is_valid_slot(slot):
		var msg = "SaveManager"
		if context != "": msg += " (%s)" % context
		msg += ": Slot inválido: %d" % slot
		push_error(msg)
		return false
	return true

# ============================================
# SLOTS — DESCUBRIMIENTO DINÁMICO
# ============================================

func get_all_manual_slots() -> Array[int]:
	#Escanea user:// y retorna todos los slots manuales existentes.
	var slots: Array[int] = []
	var dir = DirAccess.open("user://")
	if not dir:
		return slots

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.begins_with("save_game_slot_") and file_name.ends_with(".dat"):
			var slot_str = file_name.replace("save_game_slot_", "").replace(".dat", "")
			if slot_str.is_valid_int():
				var slot = slot_str.to_int()
				if slot >= 2:
					slots.append(slot)
		file_name = dir.get_next()
	dir.list_dir_end()

	slots.sort()
	return slots

func get_next_slot() -> int:
	#Retorna el siguiente número de slot manual disponible.
	var existing = get_all_manual_slots()
	if existing.is_empty():
		return 2
	return existing.max() + 1

# ============================================
# INICIAR NUEVA PARTIDA
# ============================================

func new_game(slot: int = -1, force: bool = false) -> bool:
	#Inicia una nueva partida. Si slot = -1 usa el siguiente disponible.
	#Si el slot ya existe y force = false, pide confirmación.
	if slot == -1:
		slot = get_next_slot()

	if not validate_slot(slot, "new_game"):
		return false

	if not force and has_save_file(slot):
		var save_info  = get_save_info(slot)
		var confirmed  = await show_overwrite_confirmation(
			slot,
			save_info.get("player_name", "???"),
			format_play_time(save_info.get("play_time", 0.0)),
			save_info.get("badges", 0)
		)
		if not confirmed:
			return false

	Game.reset_game_data()
	Game.money  = 3000
	Game.badges = 0
	current_slot = slot

	print("SaveManager: Nueva partida en slot %d" % slot)
	return true

# ============================================
# GUARDAR PARTIDA
# ============================================

func save_game(slot: int = -1, slot_name: String = "") -> bool:
	#Guarda el estado actual. Si slot_name está vacío usa el nombre actual o genera uno.
	if slot == -1:
		slot = current_slot

	if slot < 0:
		push_error("SaveManager: No hay slot activo.")
		return false

	if not validate_slot(slot, "save_game"):
		return false

	# Nombre del slot: usar el pasado, o el guardado, o generar automáticamente
	var final_name = slot_name
	if final_name == "":
		final_name = _get_current_slot_name(slot)

	var save_data = {
		"version":   SAVE_VERSION,
		"slot":      slot,
		"slot_name": final_name,
		"timestamp": Time.get_unix_time_from_system(),
		"game_data": Game.GameData.to_dict()
	}

	var path = SAVE_PATH.format({"slot": slot})
	var file = FileAccess.open(path, FileAccess.WRITE)

	if file:
		file.store_var(save_data)
		file.close()
		current_slot = slot
		print("SaveManager: Guardado en slot %d (%s)" % [slot, final_name])
		return true
	else:
		push_error("SaveManager: Error al guardar slot %d (Error: %d)" % [slot, FileAccess.get_open_error()])
		return false

func _get_current_slot_name(slot: int) -> String:
	#Genera un nombre automático para el slot basado en el estado actual del juego.
	match slot:
		AUTO_SAVE_SLOT:  return "Auto-Save"
		QUICK_SAVE_SLOT: return "Quick Save"

	# Intentar usar info relevante del juego
	var player_name = Game.GameData.name
	var location    = Game.GameData.active_scene

	# Extraer nombre legible de la escena
	if location != "":
		var scene_name = location.get_file().replace(".tscn", "").replace("_", " ").capitalize()
		if player_name != "":
			return "%s — %s" % [player_name, scene_name]
		return scene_name

	if player_name != "":
		return player_name

	return "Partida %d" % slot

func rename_slot(slot: int, new_name: String) -> bool:
	#Renombra un slot existente sin cambiar los datos de juego.
	if not has_save_file(slot):
		return false

	var path = SAVE_PATH.format({"slot": slot})
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return false

	var save_data = file.get_var()
	file.close()

	save_data["slot_name"] = new_name.strip_edges()

	file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return false

	file.store_var(save_data)
	file.close()
	print("SaveManager: Slot %d renombrado a '%s'" % [slot, new_name])
	return true

func quick_save() -> bool:
	var result = save_game(QUICK_SAVE_SLOT)
	if result: print("SaveManager: Quick Save completado")
	return result

func auto_save() -> bool:
	var result = save_game(AUTO_SAVE_SLOT)
	if result: print("SaveManager: Auto-Save completado")
	return result

# ============================================
# CARGAR PARTIDA
# ============================================

func load_game(slot: int) -> bool:
	if not validate_slot(slot, "load_game"):
		return false

	if not has_save_file(slot):
		push_warning("SaveManager: No hay partida en slot %d" % slot)
		return false

	var path = SAVE_PATH.format({"slot": slot})
	var file = FileAccess.open(path, FileAccess.READ)

	if not file:
		push_error("SaveManager: Error al abrir slot %d (Error: %d)" % [slot, FileAccess.get_open_error()])
		return false

	var save_data = file.get_var()
	file.close()

	var version = save_data.get("version", 0)
	if version != SAVE_VERSION:
		push_warning("SaveManager: Versión incompatible en slot %d (v%d vs v%d)" % [slot, version, SAVE_VERSION])

	Game.GameData.from_dict(save_data.get("game_data", {}))
	Game.player_name       = Game.GameData.name
	Game.player_gender     = Game.GameData.gender
	Game.player_appearance = Game.GameData.appearance
	current_slot           = slot

	print("SaveManager: Cargado slot %d (%s)" % [slot, save_data.get("slot_name", "?")])
	return true

func load_latest_save() -> bool:
	var latest = get_latest_save_info()
	if latest.is_empty():
		push_warning("SaveManager: No hay partidas guardadas")
		return false
	return load_game(latest.get("slot", AUTO_SAVE_SLOT))

# ============================================
# ELIMINAR PARTIDA
# ============================================

func delete_save(slot: int) -> bool:
	if not validate_slot(slot, "delete_save"):
		return false

	if not has_save_file(slot):
		push_warning("SaveManager: No hay partida en slot %d" % slot)
		return false

	var path  = SAVE_PATH.format({"slot": slot})
	var error = DirAccess.remove_absolute(path)

	if error == OK:
		if current_slot == slot:
			current_slot = -1
		print("SaveManager: Slot %d eliminado" % slot)
		return true
	else:
		push_error("SaveManager: Error al eliminar slot %d (Error: %d)" % [slot, error])
		return false

# ============================================
# VERIFICAR EXISTENCIA
# ============================================

func has_save_file(slot: int) -> bool:
	if not is_valid_slot(slot):
		return false
	return FileAccess.file_exists(SAVE_PATH.format({"slot": slot}))

func has_any_save() -> bool:
	if has_save_file(AUTO_SAVE_SLOT):  return true
	if has_save_file(QUICK_SAVE_SLOT): return true
	for slot in get_all_manual_slots():
		if has_save_file(slot):
			return true
	return false

# ============================================
# INFORMACIÓN DE GUARDADOS
# ============================================

func get_save_info(slot: int) -> Dictionary:
	#Obtiene metadata del save sin cargarlo completamente.
	if not has_save_file(slot):
		return {}

	var path = SAVE_PATH.format({"slot": slot})
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}

	var save_data = file.get_var()
	file.close()

	var game_data = save_data.get("game_data", {})

	return {
		"slot":        slot,
		"slot_name":   save_data.get("slot_name", "Partida %d" % slot),
		"player_name": game_data.get("name", "???"),
		"gender":      game_data.get("gender", "boy"),
		"play_time":   game_data.get("play_time", 0.0),
		"badges":      game_data.get("badges", 0),
		"pokedex":     game_data.get("pokedex_caught", []).size(),
		"money":       game_data.get("money", 0),
		"location":    game_data.get("active_scene", ""),
		"objective":   game_data.get("event_flags", {}).get("player_objective", "trainer"),
		"timestamp":   save_data.get("timestamp", 0),
	}

func get_all_saves_info() -> Array[Dictionary]:
	#Retorna info de todos los slots manuales ordenados por timestamp (más reciente primero).
	#Incluye un slot vacío al inicio para crear nueva partida.
	var saves: Array[Dictionary] = []

	for slot in get_all_manual_slots():
		var info = get_save_info(slot)
		if not info.is_empty():
			saves.append(info)

	# Ordenar por timestamp descendente (más reciente primero)
	saves.sort_custom(func(a, b): return a.timestamp > b.timestamp)

	return saves

func get_latest_save_info() -> Dictionary:
	#Obtiene la partida más reciente de todos los slots.
	var latest:    Dictionary = {}
	var latest_ts: int        = 0

	for slot in [AUTO_SAVE_SLOT, QUICK_SAVE_SLOT]:
		var info = get_save_info(slot)
		if not info.is_empty() and info.timestamp > latest_ts:
			latest_ts = info.timestamp
			latest    = info

	for slot in get_all_manual_slots():
		var info = get_save_info(slot)
		if not info.is_empty() and info.timestamp > latest_ts:
			latest_ts = info.timestamp
			latest    = info

	return latest

# ============================================
# DIÁLOGOS Y CONFIRMACIONES
# ============================================

func show_overwrite_confirmation(slot: int, player_name: String, play_time: String, badges: int) -> bool:
	var dialog       = ConfirmationDialog.new()
	dialog.title     = "⚠️ Advertencia"
	dialog.dialog_text = "Ya existe una partida en este slot:\n\nJugador: %s\nTiempo: %s\nMedallas: %d/8\n\n¿Deseas sobreescribirla?\n⚠️ Esta acción no se puede deshacer." % [player_name, play_time, badges]
	dialog.ok_button_text     = "Sí, sobreescribir"
	dialog.cancel_button_text = "No, cancelar"
	dialog.dialog_autowrap    = true

	get_tree().root.add_child(dialog)
	dialog.popup_centered()

	var confirmed = false
	dialog.confirmed.connect(func(): confirmed = true)
	dialog.canceled.connect(func():  confirmed = false)

	await dialog.visibility_changed
	dialog.queue_free()

	if confirmed:
		await show_delete_animation(slot, player_name, play_time, badges)

	return confirmed

func show_delete_animation(slot: int, player_name: String, play_time: String, badges: int):
	#Animación visual de borrado — mantenida del sistema anterior.
	var anim_panel = Panel.new()
	anim_panel.size = Vector2(500, 400)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_color = Color(0.8, 0.2, 0.2, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	anim_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.size = anim_panel.size
	anim_panel.add_child(vbox)

	var margin = MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 20)
	vbox.add_child(margin)

	var inner = VBoxContainer.new()
	margin.add_child(inner)

	var title_label = Label.new()
	title_label.text = "🗑️ Eliminando partida..."
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(title_label)

	var info_label = Label.new()
	info_label.text = "\nJugador: %s\nTiempo: %s\nMedallas: %d" % [player_name, play_time, badges]
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(info_label)

	get_tree().root.add_child(anim_panel)

	var vp_size = get_tree().root.get_visible_rect().size
	anim_panel.position = (vp_size - anim_panel.size) / 2.0

	# Animación de glitch
	for i in range(6):
		anim_panel.modulate = Color(randf(), randf(), randf(), 1.0)
		await get_tree().create_timer(0.08).timeout

	anim_panel.modulate = Color.WHITE

	var tween = create_tween()
	tween.tween_property(anim_panel, "modulate:a", 0.0, 0.5)
	await tween.finished

	anim_panel.queue_free()

# ============================================
# UTILIDADES
# ============================================

func get_slot_name(slot: int) -> String:
	match slot:
		AUTO_SAVE_SLOT:  return "Auto-Save"
		QUICK_SAVE_SLOT: return "Quick Save"
		_:               return "Partida %d" % (slot - 1)

func format_play_time(seconds: float) -> String:
	var hours   = int(seconds / 3600)
	var minutes = int((seconds - hours * 3600) / 60)
	var secs    = int(seconds) % 60
	return "%02d:%02d:%02d" % [hours, minutes, secs]

func format_timestamp(unix_time: int) -> String:
	var dt = Time.get_datetime_dict_from_unix_time(unix_time)
	return "%04d-%02d-%02d %02d:%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute]

# ============================================
# CONFIGURACIÓN GLOBAL (persiste entre sesiones)
# ============================================

const CONFIG_PATH = "user://config.dat"

func save_config() -> bool:
	#Guarda las opciones del juego independientemente de los saves.
	var file = FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if not file:
		push_error("SaveManager: Error al guardar configuración")
		return false
	file.store_var(Game.GameData.game_options.duplicate(true))
	file.close()
	print("SaveManager: Configuración guardada")
	return true

func load_config() -> bool:
	#Carga las opciones del juego al arrancar.
	if not FileAccess.file_exists(CONFIG_PATH):
		return false
	var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if not file:
		return false
	var options = file.get_var()
	file.close()
	if options is Dictionary:
		Game.GameData.game_options.merge(options, true)
		print("SaveManager: Configuración cargada")
		return true
	return false

# ============================================
# DEBUG
# ============================================

func print_all_saves_summary():
	if not OS.is_debug_build():
		return
	print("\n=== PARTIDAS GUARDADAS ===")
	for slot in [AUTO_SAVE_SLOT, QUICK_SAVE_SLOT] + get_all_manual_slots():
		if has_save_file(slot):
			var info = get_save_info(slot)
			print("Slot %d (%s): %s — %s" % [slot, info.slot_name, info.player_name, format_play_time(info.play_time)])
		else:
			print("Slot %d: Vacío" % slot)
	print("==========================\n")
