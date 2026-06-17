# ============================================
# GameModel.gd
# Modelo de datos del juego (para guardado/carga)
# ============================================
class_name GameModel

# ============================================
# DATOS DEL JUGADOR
# ============================================

var name: String = ""
var gender: String = ""  # "boy" o "girl"

var appearance: Dictionary = {
	"skin_tone": 0,
	"hair_style": 0,
	"hair_color": 0,
	"outfit": 0
}

# ============================================
# UBICACIÓN Y PROGRESO
# ============================================

var active_scene: String = ""
var last_position: Vector2 = Vector2.ZERO
var last_direction: String = "down"  # "up", "down", "left", "right"

# ============================================
# EQUIPO POKÉMON
# ============================================

#var player_pokemon: Array[Pokemon] = []

# ============================================
# POKÉDEX
# ============================================

var pokedex_seen: Array[int] = []
var pokedex_caught: Array[int] = []

# ============================================
# INVENTARIO Y RECURSOS
# ============================================

var money: int = 3000
var items: Dictionary = {}
var medicine_bag: Dictionary = {}
var pokeball_bag: Dictionary = {}
var key_items: Array[int] = []

# ============================================
# PROGRESO DEL JUEGO
# ============================================

var badges: int = 0

# Flags de eventos: acepta cualquier Variant (bool, String, int...)
# Ejemplo: {"defeated_gym_1": true, "player_objective": "trainer"}
var event_flags: Dictionary = {}

var active_quests: Array[Dictionary] = []

# ============================================
# ESTADÍSTICAS DEL JUGADOR
# ============================================

var play_time: float = 0.0
var steps_walked: int = 0
var battles_won: int = 0
var battles_lost: int = 0
var total_pokemon_caught: int = 0

# ============================================
# OPCIONES Y CONFIGURACIÓN
# ============================================

var game_options: Dictionary = {
	"text_speed":    1,         # 0=lento, 1=normal, 2=rápido
	"battle_style":  0,         # 0=cambio, 1=set
	"battle_scene":  true,      # Mostrar animaciones de batalla
	"master_volume": 100,       # 0-100
	"sound_volume":  100,       # 0-100
	"music_volume":  100,       # 0-100
	"ui_theme":      "default", # ID del tema de UI
	"language":      "es_ES",   # Código de idioma
}

# ============================================
# FUNCIONES AUXILIARES
# ============================================

# COMENTADO - Descomentar cuando PlayerSprite esté implementado
# func create_player_sprite() -> PlayerSprite:
# 	var player_sprite = PlayerSprite.new()
# 	player_sprite.initialize(appearance, gender)
# 	return player_sprite

# func update_player_sprite(player_sprite: PlayerSprite):
# 	player_sprite.initialize(appearance, gender)

func get_play_time_formatted() -> String:
	#Retorna el tiempo de juego formateado como HH:MM:SS.
	var hours = int(play_time / 3600)
	var minutes = int((play_time - hours * 3600) / 60)
	var seconds = int(play_time) % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

func has_pokemon() -> bool:
	# COMENTADO - Descomentar cuando tengas la clase Pokemon
	# return player_pokemon.size() > 0
	return false

func has_usable_pokemon() -> bool:
	# COMENTADO - Descomentar cuando tengas la clase Pokemon
	# for pokemon in player_pokemon:
	# 	if not pokemon.is_fainted():
	# 		return true
	return false

func get_party_size() -> int:
	# COMENTADO - Descomentar cuando tengas la clase Pokemon
	# return player_pokemon.size()
	return 0

func can_add_pokemon() -> bool:
	# COMENTADO - Descomentar cuando tengas la clase Pokemon
	# return player_pokemon.size() < 6
	return true

func get_pokedex_completion() -> float:
	#Retorna el porcentaje de Pokédex completada (asume 151 Pokémon).
	var total_pokemon = 151
	if total_pokemon == 0:
		return 0.0
	return (float(pokedex_caught.size()) / float(total_pokemon)) * 100.0

func has_event_flag(flag_name: String) -> bool:
	#Verifica si un evento ha ocurrido (flag existe y es truthy).
	var value = event_flags.get(flag_name, null)
	if value == null:
		return false
	if value is bool:
		return value
	if value is int or value is float:
		return value != 0
	if value is String:
		return value != ""
	return true

func set_event_flag(flag_name: String, value: Variant = true):
	#Guarda un event flag con cualquier valor.
	event_flags[flag_name] = value

func has_item(item_id: int, quantity: int = 1) -> bool:
	#Verifica si tiene cierta cantidad de un item.
	return items.get(item_id, 0) >= quantity

func get_item_count(item_id: int) -> int:
	#Retorna la cantidad de un item.
	return items.get(item_id, 0)

func has_badge(badge_number: int) -> bool:
	#Verifica si tiene cierta medalla (1-8).
	return badges >= badge_number

# ============================================
# SERIALIZACIÓN PARA GUARDADO
# ============================================

func to_dict() -> Dictionary:
	#Convierte el modelo a un diccionario para guardar.
	# COMENTADO - Descomentar cuando tengas la clase Pokemon
	# var pokemon_data = []
	# for pokemon in player_pokemon:
	# 	pokemon_data.append(pokemon.to_dict())

	return {
		"name": name,
		"gender": gender,
		"appearance": appearance,
		"active_scene": active_scene,
		"last_position": {"x": last_position.x, "y": last_position.y},
		"last_direction": last_direction,
		#"player_pokemon": pokemon_data,
		"pokedex_seen": pokedex_seen,
		"pokedex_caught": pokedex_caught,
		"money": money,
		"items": items,
		"medicine_bag": medicine_bag,
		"pokeball_bag": pokeball_bag,
		"key_items": key_items,
		"badges": badges,
		"event_flags": event_flags,
		"active_quests": active_quests,
		"play_time": play_time,
		"steps_walked": steps_walked,
		"battles_won": battles_won,
		"battles_lost": battles_lost,
		"total_pokemon_caught": total_pokemon_caught,
		"game_options": game_options,
	}

func from_dict(data: Dictionary):
	#Carga datos desde un diccionario.
	name = data.get("name", "")
	gender = data.get("gender", "boy")
	appearance = data.get("appearance", {"skin_tone": 0, "hair_style": 0, "hair_color": 0, "outfit": 0})
	active_scene    = data.get("active_scene", "")

	var pos = data.get("last_position", {"x": 0, "y": 0})
	last_position = Vector2(pos.x, pos.y)
	last_direction = data.get("last_direction", "down")

	# COMENTADO - Descomentar cuando tengas la clase Pokemon
	# player_pokemon.clear()
	# for poke_data in data.get("player_pokemon", []):
	# 	var pokemon = Pokemon.new()
	# 	pokemon.from_dict(poke_data)
	# 	player_pokemon.append(pokemon)

	pokedex_seen = data.get("pokedex_seen", [])
	pokedex_caught = data.get("pokedex_caught", [])
	money = data.get("money", 3000)
	items = data.get("items", {})
	medicine_bag = data.get("medicine_bag", {})
	pokeball_bag = data.get("pokeball_bag", {})
	key_items = data.get("key_items", [])
	badges = data.get("badges", 0)
	event_flags = data.get("event_flags", {})
	active_quests = data.get("active_quests", [])
	play_time = data.get("play_time", 0.0)
	steps_walked = data.get("steps_walked", 0)
	battles_won = data.get("battles_won", 0)
	battles_lost = data.get("battles_lost", 0)
	total_pokemon_caught = data.get("total_pokemon_caught", 0)
	game_options = data.get("game_options", {
		"text_speed": 1,
		"battle_style": 0,
		"battle_scene": true,
		"sound_volume": 100,
		"music_volume": 100,
		"ui_theme": "default",
		"language": "es",
	})

# ============================================
# RESET (para nueva partida)
# ============================================

func reset():
	#Resetea todos los datos para una nueva partida.
	name = ""
	gender = "boy"
	appearance = {"skin_tone": 0, "hair_style": 0, "hair_color": 0, "outfit": 0}
	active_scene    = ""
	last_position = Vector2.ZERO
	last_direction = "down"
	#player_pokemon.clear()
	pokedex_seen.clear()
	pokedex_caught.clear()
	money = 3000
	items.clear()
	medicine_bag.clear()
	pokeball_bag.clear()
	key_items.clear()
	badges = 0
	event_flags.clear()
	active_quests.clear()
	play_time = 0.0
	steps_walked = 0
	battles_won = 0
	battles_lost = 0
	total_pokemon_caught = 0
	game_options = {
		"text_speed": 1,
		"battle_style": 0,
		"battle_scene": true,
		"sound_volume": 100,
		"music_volume": 100,
		"ui_theme": "default",
		"language": "es",
	}
