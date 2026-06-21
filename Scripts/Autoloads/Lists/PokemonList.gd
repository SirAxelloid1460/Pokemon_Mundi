# ============================================
# PokemonList.gd
# Lista de Pokémon (PATRÓN ESTÁNDAR) — carga Pokemon.json vía StaticDataManagement.
# ============================================
extends Node

# ============================================
# RUTAS
# ============================================

var pokemon_graph_path: String = "res://Assets/Sprites/pokemon"
var pokemon_sfx_path: String = "res://Assets/SFX/pokemon"

# ============================================
# CACHÉ
# ============================================

var _cache: Array[Pokemon] = []
var _cache_by_id: Dictionary = {}
var _cache_by_name: Dictionary = {}
var _cache_loaded: bool = false

# ============================================
# CARGA DE DATOS
# ============================================

func get_list() -> Array[Pokemon]:
	#Carga todos los Pokémon desde JSON (StaticDataManagement)
	if _cache_loaded:
		return _cache

	var data = StaticDataManagement.pokemon_list_DATA
	if data == null or data.is_empty():
		push_error("PokemonList: no se pudieron cargar los datos de Pokémon")
		return _cache

	# Ordenar por número de Pokédex (las claves son strings numéricas)
	var keys = data.keys()
	keys.sort_custom(func(a, b): return int(a) < int(b))

	for key in keys:
		var p := Pokemon.new(data[key])
		_cache.append(p)
		_cache_by_id[p.pokeID] = p
		_cache_by_name[p.name.to_lower()] = p

	_cache_loaded = true
	print("PokemonList: %d Pokémon cargados desde JSON" % _cache.size())
	return _cache

# ============================================
# BÚSQUEDA (PATRÓN ESTÁNDAR)
# ============================================

func get_by_id(pokemon_id: int) -> Pokemon:
	if not _cache_loaded:
		get_list()
	return _cache_by_id.get(pokemon_id, null)

func get_by_name(pokemon_name: String) -> Pokemon:
	if not _cache_loaded:
		get_list()
	return _cache_by_name.get(pokemon_name.to_lower(), null)

func get_evolutions(pokemon_id: int) -> Array[Pokemon]:
	#Devuelve los Pokémon a los que evoluciona el dado.
	var result: Array[Pokemon] = []
	var p := get_by_id(pokemon_id)
	if p == null:
		return result
	for evo_id in p.evolve_to:
		var evo := get_by_id(int(evo_id))
		if evo != null:
			result.append(evo)
	return result

# ============================================
# UTILIDADES (PATRÓN ESTÁNDAR)
# ============================================

func reload():
	_cache_loaded = false
	_cache.clear()
	_cache_by_id.clear()
	_cache_by_name.clear()
	get_list()

func get_total_count() -> int:
	if not _cache_loaded:
		get_list()
	return _cache.size()

func exists(pokemon_id: int) -> bool:
	if not _cache_loaded:
		get_list()
	return _cache_by_id.has(pokemon_id)

# ============================================
# DEBUG
# ============================================

func print_summary():
	if not OS.is_debug_build():
		return
	if not _cache_loaded:
		get_list()
	print("=== POKEMON LIST ===")
	print("Total: %d Pokémon" % _cache.size())
	print("====================")
