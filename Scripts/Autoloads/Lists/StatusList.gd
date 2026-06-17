extends Node

var status_graph_path:String = "res://Assets/Graphic/Sprites/status"
var status_sfx_path:String = "res://Assets/SFX/status"

# Cache
var _status_cache: Array[Status] = []
var _status_by_id: Dictionary = {}
var _status_by_name: Dictionary = {}
var _cache_loaded: bool = false

# ============================================
# CARGA DE ESTADOS
# ============================================

func get_list() -> Array[Status]:
	#Retorna la lista de todos los estados
	if _cache_loaded:
		return _status_cache
	
	var status_list: Array[Status] = []

	status_list.append(Status.new(0, "Fainted", false, false, true, false, false))
	status_list.append(Status.new(1, "Burned", false, true, false, false, false))
	status_list.append(Status.new(2, "Frozen", false, false, true, false, false))
	status_list.append(Status.new(3, "Paralyzed", false, false, true, false, false))
	status_list.append(Status.new(4, "Poisoned", false, true, false, true, false))
	status_list.append(Status.new(5, "BadlyPoisoned", false, true, false, false, false))
	status_list.append(Status.new(6, "Asleep", false, false, true, false, false))
	status_list.append(Status.new(7, "Ability Change", true, false, false, true, false))
	status_list.append(Status.new(8, "Ability Supression", true, false, false, true, false))
	status_list.append(Status.new(9, "Type Change", true, false, false, false, false))
	status_list.append(Status.new(10, "Mimic", true, false, false, false, false))
	status_list.append(Status.new(11, "Substitute", true, false, false, false, false))
	status_list.append(Status.new(12, "Illusion", true, false, false, false, false))
	status_list.append(Status.new(13, "Bound", true, true, false, false, false))
	status_list.append(Status.new(14, "Curse", true, true, false, false, false))
	status_list.append(Status.new(15, "Perish Song", true, true, false, false, false))
	status_list.append(Status.new(16, "Seeded", true, true, false, false, false))
	status_list.append(Status.new(17, "Salt Cure", true, false, false, false, false))
	status_list.append(Status.new(18, "Mimic", true, false, false, false, false))
	status_list.append(Status.new(19, "Automatized", true, false, false, true, false))
	status_list.append(Status.new(20, "Identified", true, false, false, false, false))
	status_list.append(Status.new(21, "Minimized", true, false, false, false, false))
	status_list.append(Status.new(22, "Tar Shot", true, false, false, false, false))
	status_list.append(Status.new(23, "Grounded", true, false, false, false, false))
	status_list.append(Status.new(24, "Magnetic Levitation", true, false, false, false, false))
	status_list.append(Status.new(25, "Telekinesis", true, false, false, false, false))
	status_list.append(Status.new(26, "Aqua Ring", true, false, false, false, false))
	status_list.append(Status.new(27, "Rooting", true, false, false, false, false))
	status_list.append(Status.new(28, "Laser Focus", true, false, false, false, true))
	status_list.append(Status.new(29, "Taking Aim", true, false, false, false, true))
	status_list.append(Status.new(30, "Drowsy", true, false, false, false, true))
	status_list.append(Status.new(31, "Charged", true, false, false, false, false))
	status_list.append(Status.new(32, "Stockpile", true, false, false, true, false))
	status_list.append(Status.new(33, "Defense Curl", true, false, false, true, false))
	status_list.append(Status.new(34, "Can't Escape", true, false, false, false, false))
	status_list.append(Status.new(35, "No Retreat", true, false, false, false, false))
	status_list.append(Status.new(36, "Octolock", true, false, false, false, false))
	status_list.append(Status.new(37, "Disable", true, false, false, false, false))
	status_list.append(Status.new(38, "Embargo", true, false, false, false, false))
	status_list.append(Status.new(39, "Heal Block", true, false, false, false, false))
	status_list.append(Status.new(40, "Imprisoned", true, false, false, false, false))
	status_list.append(Status.new(41, "Taunt", true, false, false, false, false))
	status_list.append(Status.new(42, "Throat Chop", true, false, false, false, false))
	status_list.append(Status.new(43, "Torment", true, false, false, false, false))
	status_list.append(Status.new(44, "Confusion", true, false, false, false, false))
	status_list.append(Status.new(45, "Infatuation", true, false, false, false, false))
	status_list.append(Status.new(46, "Getting Pumped", true, false, false, true, false))
	status_list.append(Status.new(47, "Guard Split", true, false, false, false, false))
	status_list.append(Status.new(48, "Power Split", true, false, false, false, false))
	status_list.append(Status.new(49, "Speed Swap", true, false, false, false, false))
	status_list.append(Status.new(50, "Power Trick", true, false, false, false, false))
	status_list.append(Status.new(51, "Choice Lock", true, false, false, false, false))
	status_list.append(Status.new(52, "Rampage", true, false, false, false, false))
	status_list.append(Status.new(53, "Rolling", true, false, false, true, false))
	status_list.append(Status.new(54, "Making an Uproar", true, false, false, false, false))
	status_list.append(Status.new(55, "Bide", true, false, true, false, false))
	status_list.append(Status.new(56, "Recharge", true, false, true, false, false))
	status_list.append(Status.new(57, "Charging Turn", true, false, true, false, false))
	status_list.append(Status.new(58, "Flinch", true, false, false, false, false))
	status_list.append(Status.new(59, "Bracing", true, false, false, false, false))
	status_list.append(Status.new(60, "Center of Attention", true, false, false, false, false))
	status_list.append(Status.new(61, "Magic Coat", true, false, false, false, false))
	status_list.append(Status.new(62, "Protection", true, false, false, false, false))
	status_list.append(Status.new(63, "Semi-Invulnerable", true, false, false, false, false))
	status_list.append(Status.new(64, "Dynamax", true, false, false, false, false))
	status_list.append(Status.new(65, "MegaEvolved", true, false, false, false, false))
	status_list.append(Status.new(66, "Gigamax", true, false, false, false, false))
	status_list.append(Status.new(67, "TeraStellarized", true, false, false, false, false))
	status_list.append(Status.new(68, "Mysterious Barrier", true, false, false, false, false))
	
	# Cachear
	for status in status_list:
		_status_by_id[status.id] = status
		_status_by_name[status.name.to_lower()] = status
	
	_status_cache = status_list
	_cache_loaded = true
	
	print("StatusList: %d estados cargados" % status_list.size())
	
	return status_list

# ============================================
# BÃšSQUEDA
# ============================================

func get_status_by_id(status_id: int) -> Status:
	#Obtiene un estado por ID
	if not _cache_loaded:
		get_list()
	return _status_by_id.get(status_id, null)

func get_status_by_name(status_name: String) -> Status:
	#Obtiene un estado por nombre
	if not _cache_loaded:
		get_list()
	return _status_by_name.get(status_name.to_lower(), null)

# ============================================
# FILTROS
# ============================================

func get_major_statuses() -> Array[Status]:
	#Retorna los estados mayores (BRN, FRZ, PAR, PSN, SLP)
	if not _cache_loaded:
		get_list()
	
	var result: Array[Status] = []
	for status in _status_cache:
		if status.is_major_status():
			result.append(status)
	
	return result

func get_volatile_statuses() -> Array[Status]:
	#Retorna todos los estados volÃ¡tiles
	if not _cache_loaded:
		get_list()
	
	var result: Array[Status] = []
	for status in _status_cache:
		if status.is_volatile():
			result.append(status)
	
	return result

func get_damaging_statuses() -> Array[Status]:
	#Retorna estados que causan daÃ±o
	if not _cache_loaded:
		get_list()
	
	var result: Array[Status] = []
	for status in _status_cache:
		if status.causes_damage():
			result.append(status)
	
	return result

func get_incapacitating_statuses() -> Array[Status]:
	#Retorna estados que impiden actuar
	if not _cache_loaded:
		get_list()
	
	var result: Array[Status] = []
	for status in _status_cache:
		if status.prevents_action():
			result.append(status)
	
	return result

# ============================================
# UTILIDADES
# ============================================

func reload_statuses():
	#Recarga los estados
	_cache_loaded = false
	_status_cache.clear()
	_status_by_id.clear()
	_status_by_name.clear()
	get_list()

func get_total_count() -> int:
	#Retorna el total de estados
	if not _cache_loaded:
		get_list()
	return _status_cache.size()

func status_exists(status_id: int) -> bool:
	#Verifica si existe un estado
	if not _cache_loaded:
		get_list()
	return _status_by_id.has(status_id)

# ============================================
# DEBUG
# ============================================

func print_summary():
	#Imprime resumen de estados (debug)
	if not OS.is_debug_build():
		return
	
	if not _cache_loaded:
		get_list()
	
	print("=== ESTADOS ===")
	print("Total: %d" % _status_cache.size())
	print("Mayores: %d" % get_major_statuses().size())
	print("VolÃ¡tiles: %d" % get_volatile_statuses().size())
	print("Que daÃ±an: %d" % get_damaging_statuses().size())
	print("Incapacitantes: %d" % get_incapacitating_statuses().size())
	print("===============")

func print_status_info(status_id: int):
	#Imprime info de un estado (debug)
	if not OS.is_debug_build():
		return
	
	var status = get_status_by_id(status_id)
	if not status:
		print("Estado %d no encontrado" % status_id)
		return
	
	print("=== ESTADO: %s ===" % status.name)
	print("ID: %d" % status.id)
	print("VolÃ¡til: %s" % status.is_volatile())
	print("DaÃ±a: %s" % status.causes_damage())
	print("Incapacita: %s" % status.prevents_action())
	print("Acumulativo: %s" % status.is_accumulative())
	print("Requiere foco: %s" % status.requires_focus())
	print("Color: %s" % status.get_color())
	print("Abreviatura: %s" % status.get_abbreviation())
	print("==================")
