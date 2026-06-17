# ============================================
# PokeballList.gd
# Carga Pokéballs desde JSON (StaticDataManagement)
# Compatible con tu estructura existente
# Ubicación: res://scripts/data/PokeballList.gd
# ============================================
extends Node

# Rutas a recursos
var pokeball_graph_path: String = "res://Assets/Graphic/Sprites/pokeball"
var pokeball_sfx_path: String = "res://Assets/SFX/pokeball"

# Cache
var _pokeballs_cache: Array[Pokeball] = []
var _pokeballs_by_id: Dictionary = {}
var _cache_loaded: bool = false

# ============================================
# CARGA DESDE JSON
# ============================================

func get_list() -> Array[Pokeball]:
	#Carga todas las Pokéballs desde StaticDataManagement
	if _cache_loaded:
		return _pokeballs_cache
	
	var pokeball_data = StaticDataManagement.pokeball_list_DATA
	
	if pokeball_data == null or pokeball_data.is_empty():
		push_error("PokeballList: No se pudieron cargar Pokéballs")
		return []
	
	var pokeball_list: Array[Pokeball] = []
	
	for key in pokeball_data.keys():
		var pb = pokeball_data[key]
		
		var pokeball = Pokeball.new(
			pb.get("BallID", 0),
			pb.get("Icon", 0),
			tr(str(pb.get("Name", ""))),
			tr(str(pb.get("Description", ""))),
			pb.get("Rate", 1.0),
			pb.get("FlatBonus", 0),
			pb.get("Price", 0)
		)
		
		pokeball_list.append(pokeball)
		_pokeballs_by_id[pokeball.ballID] = pokeball
	
	_pokeballs_cache = pokeball_list
	_cache_loaded = true
	
	print("PokeballList: %d Pokéballs cargadas" % pokeball_list.size())
	
	return pokeball_list

# ============================================
# BÚSQUEDA
# ============================================

func get_pokeball_by_id(ball_id: int) -> Pokeball:
	#Obtiene una Pokéball por ID
	if not _cache_loaded:
		get_list()
	return _pokeballs_by_id.get(ball_id, null)

func get_pokeball_by_name(ball_name: String) -> Pokeball:
	#Busca una Pokéball por nombre
	if not _cache_loaded:
		get_list()
	
	var search_name = ball_name.to_lower()
	for pokeball in _pokeballs_cache:
		if pokeball.name.to_lower() == search_name:
			return pokeball
	
	return null

func get_buyable_pokeballs() -> Array[Pokeball]:
	#Retorna Pokéballs que se pueden comprar
	if not _cache_loaded:
		get_list()
	
	var result: Array[Pokeball] = []
	for pokeball in _pokeballs_cache:
		if pokeball.is_purchasable():
			result.append(pokeball)
	
	return result

func get_basic_pokeballs() -> Array[Pokeball]:
	#Retorna las 3 Pokéballs básicas
	return [
		get_pokeball_by_id(1),  # Poké Ball
		get_pokeball_by_id(2),  # Great Ball
		get_pokeball_by_id(3)   # Ultra Ball
	]

# ============================================
# UTILIDADES
# ============================================

func reload_pokeballs():
	#Recarga las Pokéballs
	_cache_loaded = false
	_pokeballs_cache.clear()
	_pokeballs_by_id.clear()
	get_list()

func get_total_count() -> int:
	#Retorna el total de Pokéballs
	if not _cache_loaded:
		get_list()
	return _pokeballs_cache.size()

func pokeball_exists(ball_id: int) -> bool:
	#Verifica si existe una Pokéball
	if not _cache_loaded:
		get_list()
	return _pokeballs_by_id.has(ball_id)

# ============================================
# DEBUG
# ============================================

func print_summary():
	#Imprime resumen de Pokéballs (debug)
	if not OS.is_debug_build():
		return
	
	if not _cache_loaded:
		get_list()
	
	print("=== POKÉBALLS ===")
	print("Total: %d" % _pokeballs_cache.size())
	print("Comprables: %d" % get_buyable_pokeballs().size())
	print("=================")
