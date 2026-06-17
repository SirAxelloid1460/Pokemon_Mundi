# ============================================
# TypesList.gd
# Lista de tipos de Pokémon (PATRÓN ESTÁNDAR)
# Ubicación: res://scripts/data/TypesList.gd
# ============================================
extends Node

# ============================================
# RUTAS
# ============================================

var types_graph_path: String = "res://Assets/Graphic/Sprites/types"

# ============================================
# CACHÉ
# ============================================

var _cache: Array[Type] = []
var _cache_by_id: Dictionary = {}
var _cache_by_name: Dictionary = {}
var _cache_loaded: bool = false

# ============================================
# CARGA DE DATOS
# ============================================

func get_list() -> Array[Type]:
	#Carga todos los tipos desde JSON o código
	if _cache_loaded:
		return _cache
	
	# Intentar cargar desde JSON si existe
	var from_json = _load_from_json()
	if not from_json.is_empty():
		_cache = from_json
	else:
		# Fallback: cargar desde código
		_cache = _create_hardcoded_types()
	
	# Configurar efectividades
	_setup_type_effectiveness()
	
	# Crear índices
	for type in _cache:
		_cache_by_id[type.id] = type
		_cache_by_name[type.name.to_lower()] = type
	
	_cache_loaded = true
	print("TypesList: %d tipos cargados" % _cache.size())
	
	return _cache

func _load_from_json() -> Array[Type]:
	#Intenta cargar tipos desde JSON
	# Si existe StaticDataManagement con types_list_DATA
	if not Engine.has_singleton("StaticDataManagement"):
		return []
	
	var data = StaticDataManagement.types_list_DATA if StaticDataManagement.has("types_list_DATA") else {}
	
	if data.is_empty():
		return []
	
	var types_list: Array[Type] = []
	
	for key in data.keys():
		var t = data[key]
		
		var type_color = Color(t.get("Color", "#FFFFFF"))
		
		var type = Type.new(
			t.get("id", 0),
			t.get("Name", ""),
			t.get("Name", "") + "_DESC",
			t.get("Name", "").to_lower().replace("type_", ""),
			type_color
		)
		
		types_list.append(type)
	
	return types_list

func _create_hardcoded_types() -> Array[Type]:
	#Crea tipos hardcoded (fallback si no hay JSON)
	var types_list: Array[Type] = []
	
	# 0: Normal
	types_list.append(Type.new(0, "TYPE_NORMAL", "TYPE_NORMAL_DESC", "normal", Color("#A8A878")))
	
	# 1: Fighting
	types_list.append(Type.new(1, "TYPE_FIGHTING", "TYPE_FIGHTING_DESC", "fighting", Color("#C03028")))
	
	# 2: Flying
	types_list.append(Type.new(2, "TYPE_FLYING", "TYPE_FLYING_DESC", "flying", Color("#A890F0")))
	
	# 3: Poison
	types_list.append(Type.new(3, "TYPE_POISON", "TYPE_POISON_DESC", "poison", Color("#A040A0")))
	
	# 4: Ground
	types_list.append(Type.new(4, "TYPE_GROUND", "TYPE_GROUND_DESC", "ground", Color("#E0C068")))
	
	# 5: Rock
	types_list.append(Type.new(5, "TYPE_ROCK", "TYPE_ROCK_DESC", "rock", Color("#B8A038")))
	
	# 6: Bug
	types_list.append(Type.new(6, "TYPE_BUG", "TYPE_BUG_DESC", "bug", Color("#A8B820")))
	
	# 7: Ghost
	types_list.append(Type.new(7, "TYPE_GHOST", "TYPE_GHOST_DESC", "ghost", Color("#705898")))
	
	# 8: Steel
	types_list.append(Type.new(8, "TYPE_STEEL", "TYPE_STEEL_DESC", "steel", Color("#B8B8D0")))
	
	# 9: Stellar
	types_list.append(Type.new(9, "TYPE_STELLAR", "TYPE_STELLAR_DESC", "stellar", Color("#40B5A5")))
	
	# 10: Fire
	types_list.append(Type.new(10, "TYPE_FIRE", "TYPE_FIRE_DESC", "fire", Color("#F08030")))
	
	# 11: Water
	types_list.append(Type.new(11, "TYPE_WATER", "TYPE_WATER_DESC", "water", Color("#6890F0")))
	
	# 12: Grass
	types_list.append(Type.new(12, "TYPE_GRASS", "TYPE_GRASS_DESC", "grass", Color("#78C850")))
	
	# 13: Electric
	types_list.append(Type.new(13, "TYPE_ELECTRIC", "TYPE_ELECTRIC_DESC", "electric", Color("#F8D030")))
	
	# 14: Psychic
	types_list.append(Type.new(14, "TYPE_PSYCHIC", "TYPE_PSYCHIC_DESC", "psychic", Color("#F85888")))
	
	# 15: Ice
	types_list.append(Type.new(15, "TYPE_ICE", "TYPE_ICE_DESC", "ice", Color("#98D8D8")))
	
	# 16: Dragon
	types_list.append(Type.new(16, "TYPE_DRAGON", "TYPE_DRAGON_DESC", "dragon", Color("#7038F8")))
	
	# 17: Dark
	types_list.append(Type.new(17, "TYPE_DARK", "TYPE_DARK_DESC", "dark", Color("#705848")))
	
	# 18: Fairy
	types_list.append(Type.new(18, "TYPE_FAIRY", "TYPE_FAIRY_DESC", "fairy", Color("#EE99AC")))
	
	return types_list

func _setup_type_effectiveness():
	#Configura la tabla de efectividades de tipos
	for type in _cache:
		# Inicializar diccionarios vacíos
		type.attacker = {}
		type.defender = {}
	
	# ============================================
	# TABLA DE EFECTIVIDADES COMPLETA
	# ============================================
	# Formato: _set_effectiveness(ATACANTE, DEFENSOR, MULTIPLICADOR)
	# 2.0 = Súper efectivo
	# 0.5 = Poco efectivo
	# 0.0 = Inmune
	
	# ============================================
	# 1) FAIRY
	# ============================================
	# Fuerte contra: Dragon, Dark, Fighting
	_set_effectiveness(Type.TypeID.FAIRY, Type.TypeID.DRAGON, 2.0)
	_set_effectiveness(Type.TypeID.FAIRY, Type.TypeID.DARK, 2.0)
	_set_effectiveness(Type.TypeID.FAIRY, Type.TypeID.FIGHTING, 2.0)
	# Débil contra: Steel, Poison
	_set_effectiveness(Type.TypeID.FAIRY, Type.TypeID.STEEL, 0.5)
	_set_effectiveness(Type.TypeID.FAIRY, Type.TypeID.POISON, 0.5)
	
	# ============================================
	# 2) STEEL
	# ============================================
	# Fuerte contra: Fairy, Ice, Rock
	_set_effectiveness(Type.TypeID.STEEL, Type.TypeID.FAIRY, 2.0)
	_set_effectiveness(Type.TypeID.STEEL, Type.TypeID.ICE, 2.0)
	_set_effectiveness(Type.TypeID.STEEL, Type.TypeID.ROCK, 2.0)
	# Débil contra: Fire, Fighting, Ground
	_set_effectiveness(Type.TypeID.STEEL, Type.TypeID.FIRE, 0.5)
	_set_effectiveness(Type.TypeID.STEEL, Type.TypeID.FIGHTING, 0.5)
	_set_effectiveness(Type.TypeID.STEEL, Type.TypeID.GROUND, 0.5)
	
	# ============================================
	# 3) BUG
	# ============================================
	# Fuerte contra: Grass, Psychic, Dark
	_set_effectiveness(Type.TypeID.BUG, Type.TypeID.GRASS, 2.0)
	_set_effectiveness(Type.TypeID.BUG, Type.TypeID.PSYCHIC, 2.0)
	_set_effectiveness(Type.TypeID.BUG, Type.TypeID.DARK, 2.0)
	# Débil contra: Fire, Rock, Flying
	_set_effectiveness(Type.TypeID.BUG, Type.TypeID.FIRE, 0.5)
	_set_effectiveness(Type.TypeID.BUG, Type.TypeID.ROCK, 0.5)
	_set_effectiveness(Type.TypeID.BUG, Type.TypeID.FLYING, 0.5)
	# Débil adicional contra: Steel, Fighting, Fairy
	_set_effectiveness(Type.TypeID.BUG, Type.TypeID.STEEL, 0.5)
	_set_effectiveness(Type.TypeID.BUG, Type.TypeID.FIGHTING, 0.5)
	_set_effectiveness(Type.TypeID.BUG, Type.TypeID.FAIRY, 0.5)
	
	# ============================================
	# 4) WATER
	# ============================================
	# Fuerte contra: Fire, Rock, Ground
	_set_effectiveness(Type.TypeID.WATER, Type.TypeID.FIRE, 2.0)
	_set_effectiveness(Type.TypeID.WATER, Type.TypeID.ROCK, 2.0)
	_set_effectiveness(Type.TypeID.WATER, Type.TypeID.GROUND, 2.0)
	# Débil contra: Electric, Grass
	_set_effectiveness(Type.TypeID.WATER, Type.TypeID.WATER, 0.5)
	_set_effectiveness(Type.TypeID.WATER, Type.TypeID.GRASS, 0.5)
	_set_effectiveness(Type.TypeID.WATER, Type.TypeID.DRAGON, 0.5)
	
	# ============================================
	# 5) DRAGON
	# ============================================
	# Fuerte contra: Dragon
	_set_effectiveness(Type.TypeID.DRAGON, Type.TypeID.DRAGON, 2.0)
	# Débil contra: Steel
	_set_effectiveness(Type.TypeID.DRAGON, Type.TypeID.STEEL, 0.5)
	# Inmune contra: Fairy
	_set_effectiveness(Type.TypeID.DRAGON, Type.TypeID.FAIRY, 0.0)
	
	# ============================================
	# 6) ELECTRIC
	# ============================================
	# Fuerte contra: Water, Flying
	_set_effectiveness(Type.TypeID.ELECTRIC, Type.TypeID.WATER, 2.0)
	_set_effectiveness(Type.TypeID.ELECTRIC, Type.TypeID.FLYING, 2.0)
	# Débil contra: Electric, Grass, Dragon
	_set_effectiveness(Type.TypeID.ELECTRIC, Type.TypeID.ELECTRIC, 0.5)
	_set_effectiveness(Type.TypeID.ELECTRIC, Type.TypeID.GRASS, 0.5)
	_set_effectiveness(Type.TypeID.ELECTRIC, Type.TypeID.DRAGON, 0.5)
	# Inmune contra: Ground
	_set_effectiveness(Type.TypeID.ELECTRIC, Type.TypeID.GROUND, 0.0)
	
	# ============================================
	# 7) GHOST (Phantom)
	# ============================================
	# Fuerte contra: Ghost, Psychic
	_set_effectiveness(Type.TypeID.GHOST, Type.TypeID.GHOST, 2.0)
	_set_effectiveness(Type.TypeID.GHOST, Type.TypeID.PSYCHIC, 2.0)
	# Débil contra: Dark
	_set_effectiveness(Type.TypeID.GHOST, Type.TypeID.DARK, 0.5)
	# Inmune contra: Normal
	_set_effectiveness(Type.TypeID.GHOST, Type.TypeID.NORMAL, 0.0)
	
	# ============================================
	# 8) FIRE
	# ============================================
	# Fuerte contra: Steel, Bug, Grass, Ice
	_set_effectiveness(Type.TypeID.FIRE, Type.TypeID.STEEL, 2.0)
	_set_effectiveness(Type.TypeID.FIRE, Type.TypeID.BUG, 2.0)
	_set_effectiveness(Type.TypeID.FIRE, Type.TypeID.GRASS, 2.0)
	_set_effectiveness(Type.TypeID.FIRE, Type.TypeID.ICE, 2.0)
	# Débil contra: Water, Ground, Rock
	_set_effectiveness(Type.TypeID.FIRE, Type.TypeID.WATER, 0.5)
	_set_effectiveness(Type.TypeID.FIRE, Type.TypeID.GROUND, 0.5)
	_set_effectiveness(Type.TypeID.FIRE, Type.TypeID.ROCK, 0.5)
	# Débil adicional contra: Fire, Dragon
	_set_effectiveness(Type.TypeID.FIRE, Type.TypeID.FIRE, 0.5)
	_set_effectiveness(Type.TypeID.FIRE, Type.TypeID.DRAGON, 0.5)
	
	# ============================================
	# 9) ICE
	# ============================================
	# Fuerte contra: Dragon, Grass, Ground, Flying
	_set_effectiveness(Type.TypeID.ICE, Type.TypeID.DRAGON, 2.0)
	_set_effectiveness(Type.TypeID.ICE, Type.TypeID.GRASS, 2.0)
	_set_effectiveness(Type.TypeID.ICE, Type.TypeID.GROUND, 2.0)
	_set_effectiveness(Type.TypeID.ICE, Type.TypeID.FLYING, 2.0)
	# Débil contra: Steel, Fire, Fighting, Rock
	_set_effectiveness(Type.TypeID.ICE, Type.TypeID.STEEL, 0.5)
	_set_effectiveness(Type.TypeID.ICE, Type.TypeID.FIRE, 0.5)
	_set_effectiveness(Type.TypeID.ICE, Type.TypeID.FIGHTING, 0.5)
	_set_effectiveness(Type.TypeID.ICE, Type.TypeID.ROCK, 0.5)
	# Débil adicional contra: Water, Ice
	_set_effectiveness(Type.TypeID.ICE, Type.TypeID.WATER, 0.5)
	_set_effectiveness(Type.TypeID.ICE, Type.TypeID.ICE, 0.5)
	
	# ============================================
	# 10) FIGHTING
	# ============================================
	# Fuerte contra: Steel, Ice, Normal, Rock, Dark
	_set_effectiveness(Type.TypeID.FIGHTING, Type.TypeID.STEEL, 2.0)
	_set_effectiveness(Type.TypeID.FIGHTING, Type.TypeID.ICE, 2.0)
	_set_effectiveness(Type.TypeID.FIGHTING, Type.TypeID.NORMAL, 2.0)
	_set_effectiveness(Type.TypeID.FIGHTING, Type.TypeID.ROCK, 2.0)
	_set_effectiveness(Type.TypeID.FIGHTING, Type.TypeID.DARK, 2.0)
	# Débil contra: Fairy, Psychic, Flying
	_set_effectiveness(Type.TypeID.FIGHTING, Type.TypeID.FAIRY, 0.5)
	_set_effectiveness(Type.TypeID.FIGHTING, Type.TypeID.PSYCHIC, 0.5)
	_set_effectiveness(Type.TypeID.FIGHTING, Type.TypeID.FLYING, 0.5)
	# Débil adicional contra: Bug, Poison
	_set_effectiveness(Type.TypeID.FIGHTING, Type.TypeID.BUG, 0.5)
	_set_effectiveness(Type.TypeID.FIGHTING, Type.TypeID.POISON, 0.5)
	# Inmune contra: Ghost
	_set_effectiveness(Type.TypeID.FIGHTING, Type.TypeID.GHOST, 0.0)
	
	# ============================================
	# 11) NORMAL
	# ============================================
	# Débil contra: Rock, Steel
	_set_effectiveness(Type.TypeID.NORMAL, Type.TypeID.ROCK, 0.5)
	_set_effectiveness(Type.TypeID.NORMAL, Type.TypeID.STEEL, 0.5)
	# Inmune contra: Ghost
	_set_effectiveness(Type.TypeID.NORMAL, Type.TypeID.GHOST, 0.0)
	
	# ============================================
	# 12) GRASS (Plant)
	# ============================================
	# Fuerte contra: Water, Rock, Ground
	_set_effectiveness(Type.TypeID.GRASS, Type.TypeID.WATER, 2.0)
	_set_effectiveness(Type.TypeID.GRASS, Type.TypeID.ROCK, 2.0)
	_set_effectiveness(Type.TypeID.GRASS, Type.TypeID.GROUND, 2.0)
	# Débil contra: Fire, Bug, Ice, Poison, Flying
	_set_effectiveness(Type.TypeID.GRASS, Type.TypeID.FIRE, 0.5)
	_set_effectiveness(Type.TypeID.GRASS, Type.TypeID.BUG, 0.5)
	_set_effectiveness(Type.TypeID.GRASS, Type.TypeID.ICE, 0.5)
	_set_effectiveness(Type.TypeID.GRASS, Type.TypeID.POISON, 0.5)
	_set_effectiveness(Type.TypeID.GRASS, Type.TypeID.FLYING, 0.5)
	# Débil adicional contra: Grass, Steel, Dragon
	_set_effectiveness(Type.TypeID.GRASS, Type.TypeID.GRASS, 0.5)
	_set_effectiveness(Type.TypeID.GRASS, Type.TypeID.STEEL, 0.5)
	_set_effectiveness(Type.TypeID.GRASS, Type.TypeID.DRAGON, 0.5)
	
	# ============================================
	# 13) PSYCHIC
	# ============================================
	# Fuerte contra: Fighting, Poison
	_set_effectiveness(Type.TypeID.PSYCHIC, Type.TypeID.FIGHTING, 2.0)
	_set_effectiveness(Type.TypeID.PSYCHIC, Type.TypeID.POISON, 2.0)
	# Débil contra: Psychic, Steel
	_set_effectiveness(Type.TypeID.PSYCHIC, Type.TypeID.PSYCHIC, 0.5)
	_set_effectiveness(Type.TypeID.PSYCHIC, Type.TypeID.STEEL, 0.5)
	# Inmune contra: Dark
	_set_effectiveness(Type.TypeID.PSYCHIC, Type.TypeID.DARK, 0.0)
	
	# ============================================
	# 14) ROCK
	# ============================================
	# Fuerte contra: Bug, Ice, Fire, Flying
	_set_effectiveness(Type.TypeID.ROCK, Type.TypeID.BUG, 2.0)
	_set_effectiveness(Type.TypeID.ROCK, Type.TypeID.ICE, 2.0)
	_set_effectiveness(Type.TypeID.ROCK, Type.TypeID.FIRE, 2.0)
	_set_effectiveness(Type.TypeID.ROCK, Type.TypeID.FLYING, 2.0)
	# Débil contra: Steel, Water, Fighting, Grass, Ground
	_set_effectiveness(Type.TypeID.ROCK, Type.TypeID.STEEL, 0.5)
	_set_effectiveness(Type.TypeID.ROCK, Type.TypeID.WATER, 0.5)
	_set_effectiveness(Type.TypeID.ROCK, Type.TypeID.FIGHTING, 0.5)
	_set_effectiveness(Type.TypeID.ROCK, Type.TypeID.GRASS, 0.5)
	_set_effectiveness(Type.TypeID.ROCK, Type.TypeID.GROUND, 0.5)
	
	# ============================================
	# 15) DARK
	# ============================================
	# Fuerte contra: Ghost, Psychic
	_set_effectiveness(Type.TypeID.DARK, Type.TypeID.GHOST, 2.0)
	_set_effectiveness(Type.TypeID.DARK, Type.TypeID.PSYCHIC, 2.0)
	# Débil contra: Fighting, Fairy
	_set_effectiveness(Type.TypeID.DARK, Type.TypeID.FIGHTING, 0.5)
	_set_effectiveness(Type.TypeID.DARK, Type.TypeID.FAIRY, 0.5)
	# Débil adicional contra: Dark
	_set_effectiveness(Type.TypeID.DARK, Type.TypeID.DARK, 0.5)
	
	# ============================================
	# 16) GROUND
	# ============================================
	# Fuerte contra: Steel, Electric, Fire, Rock, Poison
	_set_effectiveness(Type.TypeID.GROUND, Type.TypeID.STEEL, 2.0)
	_set_effectiveness(Type.TypeID.GROUND, Type.TypeID.ELECTRIC, 2.0)
	_set_effectiveness(Type.TypeID.GROUND, Type.TypeID.FIRE, 2.0)
	_set_effectiveness(Type.TypeID.GROUND, Type.TypeID.ROCK, 2.0)
	_set_effectiveness(Type.TypeID.GROUND, Type.TypeID.POISON, 2.0)
	# Débil contra: Grass, Ice
	_set_effectiveness(Type.TypeID.GROUND, Type.TypeID.GRASS, 0.5)
	_set_effectiveness(Type.TypeID.GROUND, Type.TypeID.ICE, 0.5)
	# Débil adicional contra: Bug
	_set_effectiveness(Type.TypeID.GROUND, Type.TypeID.BUG, 0.5)
	# Inmune contra: Flying
	_set_effectiveness(Type.TypeID.GROUND, Type.TypeID.FLYING, 0.0)
	
	# ============================================
	# 17) POISON
	# ============================================
	# Fuerte contra: Fairy, Grass
	_set_effectiveness(Type.TypeID.POISON, Type.TypeID.FAIRY, 2.0)
	_set_effectiveness(Type.TypeID.POISON, Type.TypeID.GRASS, 2.0)
	# Débil contra: Poison, Ground, Rock, Ghost
	_set_effectiveness(Type.TypeID.POISON, Type.TypeID.POISON, 0.5)
	_set_effectiveness(Type.TypeID.POISON, Type.TypeID.GROUND, 0.5)
	_set_effectiveness(Type.TypeID.POISON, Type.TypeID.ROCK, 0.5)
	_set_effectiveness(Type.TypeID.POISON, Type.TypeID.GHOST, 0.5)
	# Inmune contra: Steel
	_set_effectiveness(Type.TypeID.POISON, Type.TypeID.STEEL, 0.0)
	
	# ============================================
	# 18) FLYING
	# ============================================
	# Fuerte contra: Grass, Bug, Fighting
	_set_effectiveness(Type.TypeID.FLYING, Type.TypeID.GRASS, 2.0)
	_set_effectiveness(Type.TypeID.FLYING, Type.TypeID.BUG, 2.0)
	_set_effectiveness(Type.TypeID.FLYING, Type.TypeID.FIGHTING, 2.0)
	# Débil contra: Electric, Ice, Rock
	_set_effectiveness(Type.TypeID.FLYING, Type.TypeID.ELECTRIC, 0.5)
	_set_effectiveness(Type.TypeID.FLYING, Type.TypeID.ROCK, 0.5)
	# Débil adicional contra: Steel
	_set_effectiveness(Type.TypeID.FLYING, Type.TypeID.STEEL, 0.5)
	
	# ============================================
	# 19) STELLAR (Terastellar)
	# ============================================
	# Fuerte contra: Stellar
	_set_effectiveness(Type.TypeID.STELLAR, Type.TypeID.STELLAR, 2.0)

func _set_effectiveness(attacker_id: int, defender_id: int, multiplier: float):
	#Configura efectividad de un tipo contra otro
	if attacker_id >= 0 and attacker_id < _cache.size():
		_cache[attacker_id].attacker[defender_id] = multiplier
	
	if defender_id >= 0 and defender_id < _cache.size():
		_cache[defender_id].defender[attacker_id] = multiplier

# ============================================
# BÚSQUEDA (PATRÓN ESTÁNDAR)
# ============================================

func get_by_id(type_id: int) -> Type:
	#Obtiene un tipo por ID
	if not _cache_loaded:
		get_list()
	return _cache_by_id.get(type_id, null)

func get_by_name(type_name: String) -> Type:
	#Obtiene un tipo por nombre
	if not _cache_loaded:
		get_list()
	return _cache_by_name.get(type_name.to_lower(), null)

# ============================================
# UTILIDADES (PATRÓN ESTÁNDAR)
# ============================================

func reload():
	#Recarga los tipos
	_cache_loaded = false
	_cache.clear()
	_cache_by_id.clear()
	_cache_by_name.clear()
	get_list()

func get_total_count() -> int:
	#Total de tipos
	if not _cache_loaded:
		get_list()
	return _cache.size()

func exists(type_id: int) -> bool:
	#Verifica si existe un tipo
	if not _cache_loaded:
		get_list()
	return _cache_by_id.has(type_id)

# ============================================
# DEBUG (PATRÓN ESTÁNDAR)
# ============================================

func print_summary():
	#Imprime resumen (debug)
	if not OS.is_debug_build():
		return
	
	if not _cache_loaded:
		get_list()
	
	print("=== TYPES LIST ===")
	print("Total: %d tipos" % _cache.size())
	print("==================")

func print_type_info(type_id: int):
	#Imprime info de un tipo (debug)
	if not OS.is_debug_build():
		return
	
	var type = get_by_id(type_id)
	if not type:
		print("Tipo %d no encontrado" % type_id)
		return
	
	print("=== TIPO: %s ===" % type.get_display_name())
	print("ID: %d" % type.id)
	print("Color: %s" % type.color)
	print("================")
