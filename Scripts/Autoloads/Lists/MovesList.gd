# ============================================
# MovesList.gd
# Carga movimientos desde JSON (StaticDataManagement)
# Compatible con tu estructura existente
# UbicaciÃƒÂ³n: res://scripts/data/MovesList.gd
# ============================================
extends Node

# Rutas a recursos
var moves_graph_path: String = "res://Assets/Graphic/Sprites/moves"
var moves_sfx_path: String = "res://Assets/SFX/moves"

# Cache de movimientos cargados
var _moves_cache: Array[Move] = []
var _moves_by_id: Dictionary = {}
var _cache_loaded: bool = false

# ============================================
# CARGA DE MOVIMIENTOS DESDE JSON
# ============================================

func get_list() -> Array[Move]:
	#Carga todos los movimientos desde StaticDataManagement
	# Si ya estÃƒÂ¡ cacheado, retornar cache
	if _cache_loaded:
		return _moves_cache
	
	# Obtener datos JSON desde StaticDataManagement
	var move_data = StaticDataManagement.moves_list_DATA
	
	if move_data == null or move_data.is_empty():
		push_error("MovesList: No se pudieron cargar los datos de movimientos")
		return []
	
	var moves_list: Array[Move] = []
	
	# Convertir cada entrada del JSON a un objeto Move
	for key in move_data.keys():
		var m = move_data[key]
		
		# Crear movimiento con los datos del JSON
		var move = Move.new(
			m.get("moveID", 0),
			tr(str(m.get("Name", ""))),  # TraducciÃƒÂ³n del nombre
			m.get("Power", 0),
			m.get("Accuracy", 1.0),
			m.get("PP", 10),
			m.get("Type", "Normal"),
			m.get("Category", "Physical"),
			m.get("Description", ""),
			m.get("Contact", false),
			m.get("overworldUse", false)
		)
		
		# Configurar propiedades especiales basadas en el movimiento
		_configure_special_properties(move)
		
		moves_list.append(move)
		_moves_by_id[move.moveID] = move
	
	# Guardar en cache
	_moves_cache = moves_list
	_cache_loaded = true
	
	print("MovesList: %d movimientos cargados desde JSON" % moves_list.size())
	
	return moves_list

# ============================================
# CONFIGURACIÃƒâ€œN DE PROPIEDADES ESPECIALES
# ============================================

func _configure_special_properties(move: Move):
	#Configura propiedades especiales de movimientos especÃƒÂ­ficos
	match move.moveID:
		# ==================== MOVIMIENTOS CON EFECTOS ====================
		
		7:  # Fire Punch
			move.effect_chance = 10  # 10% de quemar
			move.effect_id = 1  # ID de efecto "burn"
		
		8:  # Ice Punch
			move.effect_chance = 10  # 10% de congelar
			move.effect_id = 2  # ID de efecto "freeze"
		
		9:  # Thunder Punch
			move.effect_chance = 10  # 10% de paralizar
			move.effect_id = 3  # ID de efecto "paralyze"
		
		# ==================== MOVIMIENTOS CON PRIORIDAD ====================
		
		# Quick Attack (si lo tienes en tu JSON con otro ID)
		# 98:
		# 	move.priority = 1
		
		# ==================== MOVIMIENTOS CON CRÃƒÂTICO ALTO ====================
		
		2:  # Karate Chop
			move.crit_rate = 1  # Alta tasa de crÃƒÂ­tico
		
		13:  # Razor Wind
			move.crit_rate = 1
		
		# ==================== MOVIMIENTOS DE DRENAJE ====================
		
		# Absorb, Mega Drain, Giga Drain (aÃƒÂ±adir IDs cuando los tengas)
		# move.drain = 50  # Drena 50% del daÃƒÂ±o
		
		# ==================== MOVIMIENTOS CON RECOIL ====================
		
		# Take Down, Double-Edge (aÃƒÂ±adir IDs cuando los tengas)
		# move.recoil = 25  # Recibe 25% del daÃƒÂ±o como recoil
		
		# ==================== MOVIMIENTOS QUE CAUSAN FLINCH ====================
		
		23:  # Stomp
			move.flinch_chance = 30  # 30% de hacer retroceder
		
		# ==================== CASOS ESPECIALES ====================
		
		12:  # Guillotine (One-Hit KO)
			# Ya detectado por power >= 65535
			pass
		
		14:  # Swords Dance
			move.effect_id = 10  # ID para "aumentar Attack x2"
		
		18:  # Whirlwind
			move.priority = -6  # Baja prioridad
			move.effect_id = 20  # Forzar cambio de PokÃƒÂ©mon

# ============================================
# BÃƒÅ¡SQUEDA Y FILTROS
# ============================================

func get_move_by_id(move_id: int) -> Move:
	#Obtiene un movimiento por su ID
	# Asegurar que la lista estÃƒÂ© cargada
	if not _cache_loaded:
		get_list()
	
	return _moves_by_id.get(move_id, null)

func get_move_by_name(move_name: String) -> Move:
	#Busca un movimiento por nombre (case-insensitive)
	if not _cache_loaded:
		get_list()
	
	var search_name = move_name.to_lower()
	for move in _moves_cache:
		if move.name.to_lower() == search_name:
			return move
	
	return null

func get_moves_by_type(type_name: String) -> Array[Move]:
	#Obtiene todos los movimientos de un tipo especÃƒÂ­fico
	if not _cache_loaded:
		get_list()
	
	var result: Array[Move] = []
	for move in _moves_cache:
		if move.type == type_name:
			result.append(move)
	
	return result

func get_moves_by_category(category_name: String) -> Array[Move]:
	#Obtiene todos los movimientos de una categorÃƒÂ­a
	if not _cache_loaded:
		get_list()
	
	var result: Array[Move] = []
	for move in _moves_cache:
		if move.category == category_name:
			result.append(move)
	
	return result

func get_damaging_moves() -> Array[Move]:
	#Retorna todos los movimientos que hacen daÃƒÂ±o
	if not _cache_loaded:
		get_list()
	
	var result: Array[Move] = []
	for move in _moves_cache:
		if move.is_damaging():
			result.append(move)
	
	return result

func get_status_moves() -> Array[Move]:
	#Retorna todos los movimientos de estado
	if not _cache_loaded:
		get_list()
	
	var result: Array[Move] = []
	for move in _moves_cache:
		if move.is_status():
			result.append(move)
	
	return result

func get_overworld_moves() -> Array[Move]:
	#Retorna todos los movimientos usables fuera de batalla (HMs)
	if not _cache_loaded:
		get_list()
	
	var result: Array[Move] = []
	for move in _moves_cache:
		if move.overworldUse:
			result.append(move)
	
	return result

# ============================================
# UTILIDADES
# ============================================

func reload_moves():
	#Fuerza la recarga de movimientos desde el JSON
	_cache_loaded = false
	_moves_cache.clear()
	_moves_by_id.clear()
	get_list()

func get_total_moves_count() -> int:
	#Retorna el nÃƒÂºmero total de movimientos cargados
	if not _cache_loaded:
		get_list()
	return _moves_cache.size()

func move_exists(move_id: int) -> bool:
	#Verifica si existe un movimiento con ese ID
	if not _cache_loaded:
		get_list()
	return _moves_by_id.has(move_id)

# ============================================
# VALIDACIÃƒâ€œN
# ============================================

func validate_moves() -> Dictionary:
	#Valida que todos los movimientos estÃƒÂ©n correctamente cargados
	if not _cache_loaded:
		get_list()
	
	var stats = {
		"total": _moves_cache.size(),
		"valid": 0,
		"invalid": 0,
		"errors": []
	}
	
	for move in _moves_cache:
		if move.is_valid():
			stats.valid += 1
		else:
			stats.invalid += 1
			stats.errors.append("Move %d (%s) es invÃƒÂ¡lido" % [move.moveID, move.name])
	
	return stats

# ============================================
# DEBUG
# ============================================

func print_moves_summary():
	#Imprime un resumen de los movimientos cargados (debug)
	if not OS.is_debug_build():
		return
	
	if not _cache_loaded:
		get_list()
	
	print("=== RESUMEN DE MOVIMIENTOS ===")
	print("Total: %d movimientos" % _moves_cache.size())
	
	# Contar por tipo
	var types = {}
	for move in _moves_cache:
		if not types.has(move.type):
			types[move.type] = 0
		types[move.type] += 1
	
	print("\nPor tipo:")
	for type_name in types.keys():
		print("  %s: %d" % [type_name, types[type_name]])
	
	# Contar por categorÃƒÂ­a
	var categories = {}
	for move in _moves_cache:
		if not categories.has(move.category):
			categories[move.category] = 0
		categories[move.category] += 1
	
	print("\nPor categorÃƒÂ­a:")
	for cat_name in categories.keys():
		print("  %s: %d" % [cat_name, categories[cat_name]])
	
	# Movimientos especiales
	var overworld = get_overworld_moves().size()
	var multi_hit = 0
	var one_hit_ko = 0
	
	for move in _moves_cache:
		if move.is_multi_hit():
			multi_hit += 1
		if move.is_one_hit_ko():
			one_hit_ko += 1
	
	print("\nEspeciales:")
	print("  Uso fuera de batalla: %d" % overworld)
	print("  Multi-hit: %d" % multi_hit)
	print("  One-Hit KO: %d" % one_hit_ko)
	print("==============================")

func print_move_details(move_id: int):
	#Imprime detalles de un movimiento especÃƒÂ­fico (debug)
	if not OS.is_debug_build():
		return
	
	var move = get_move_by_id(move_id)
	if not move:
		print("Movimiento %d no encontrado" % move_id)
		return
	
	print("=== MOVE #%d ===" % move_id)
	print("Name: %s" % move.name)
	print("Type: %s" % move.type)
	print("Category: %s" % move.category)
	print("Power: %d" % move.power)
	print("Accuracy: %.0f%%" % (move.accuracy * 100))
	print("PP: %d" % move.totalpp)
	print("Contact: %s" % move.contact)
	print("Overworld: %s" % move.overworldUse)
	print("Description: %s" % move.description)
	
	var props = move.get_special_properties()
	if not props.is_empty():
		print("\nPropiedades especiales:")
		for key in props.keys():
			print("  %s: %s" % [key, props[key]])
	
	print("================")
