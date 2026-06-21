extends Node

var GameData := GameModel.new()

func _ready():
	#Cargar configuración guardada al arrancar.
	SaveManager.load_config()
	_apply_audio_settings()

func _apply_audio_settings():
	#Aplica los volúmenes guardados al AudioManager.
	AudioManager.set_master_volume(GameData.game_options.get("master_volume", 100))
	AudioManager.set_music_volume(GameData.game_options.get("music_volume", 100))
	AudioManager.set_sfx_volume(GameData.game_options.get("sound_volume", 100))

#@onready var PokemonDB = PokemonDatabase
#@onready var MoveDB = MoveDatabase
#@onready var ItemDB = ItemDatabase

# ============================================
# INTRODUCCIÓN
# ============================================

var player_name: String:
	get: return GameData.name
	set(value): GameData.name = value

var player_gender: String:
	get: return GameData.gender
	set(value): GameData.gender = value

var player_appearance: Dictionary:
	get: return GameData.appearance
	set(value): GameData.appearance = value

var money: int:
	get: return GameData.money
	set(value): GameData.money = value

var badges: int:
	get: return GameData.badges
	set(value): GameData.badges = value

# Equipo Pokémon del jugador (máximo 6)
#var party: Array[Pokemon]:
#	get: return GameData.player_pokemon
#	set(value): GameData.player_pokemon = value

# Pokédex
var pokedex_seen: Array[int]:
	get: return GameData.pokedex_seen
	set(value): GameData.pokedex_seen = value

var pokedex_caught: Array[int]:
	get: return GameData.pokedex_caught
	set(value): GameData.pokedex_caught = value

var items: Dictionary = {}

# ============================================
# FUNCIONES
# ============================================

func load_scene(scene: String):
	#Carga una escena por nombre relativo.
	var scene_to_load = "res://Scenes/" + scene + ".tscn"
	if ResourceLoader.exists(scene_to_load):
		get_tree().change_scene_to_file(scene_to_load)
	else:
		push_error("Escena no encontrada: " + scene_to_load)

# ============================================
# EQUIPO
# ============================================

# func add_to_party(pokemon: Pokemon) -> bool:
# 	if party.size() < 6:
# 		GameData.player_pokemon.append(pokemon)
# 		return true
# 	return false

# func remove_from_party(index: int) -> bool:
# 	if index >= 0 and index < party.size():
# 		party.remove_at(index)
# 		return true
# 	return false

# func get_party_size() -> int:
# 	return party.size()

# func has_usable_pokemon() -> bool:
# 	for pokemon in party:
# 		if not pokemon.is_fainted():
# 			return true
# 	return false

# func get_first_usable_pokemon() -> Pokemon:
# 	for pokemon in party:
# 		if not pokemon.is_fainted():
# 			return pokemon
# 	return null

# func heal_all_pokemon():
# 	for pokemon in GameData.player_pokemon:
# 		pokemon.current_hp = pokemon.get_max_hp()
# 		pokemon.cure_status()
# 		for i in range(pokemon.moves.size()):
# 			pokemon.move_pp[i] = pokemon.moves[i].pp

# ============================================
# APARIENCIA DEL JUGADOR
# ============================================

# COMENTADO - Descomentar cuando PlayerSprite esté implementado
# func create_player_sprite() -> PlayerSprite:
# 	var player_sprite = PlayerSprite.new()
# 	player_sprite.initialize(player_appearance, player_gender)
# 	return player_sprite

# func update_player_sprite(player_sprite: PlayerSprite):
# 	player_sprite.initialize(player_appearance, player_gender)

# ============================================
# POKÉDEX
# ============================================

func register_seen(pokemon_id: int):
	#Registra un Pokémon como visto en la Pokédex.
	if not pokedex_seen.has(pokemon_id):
		pokedex_seen.append(pokemon_id)

func register_caught(pokemon_id: int):
	#Registra un Pokémon como capturado en la Pokédex.
	if not pokedex_caught.has(pokemon_id):
		pokedex_caught.append(pokemon_id)
	register_seen(pokemon_id)

func is_pokemon_seen(pokemon_id: int) -> bool:
	#Verifica si un Pokémon ha sido visto.
	return pokedex_seen.has(pokemon_id)

func is_pokemon_caught(pokemon_id: int) -> bool:
	#Verifica si un Pokémon ha sido capturado.
	return pokedex_caught.has(pokemon_id)

func get_pokedex_completion() -> float:
	#Retorna el porcentaje de completitud de la Pokédex.
	var total_pokemon = PokemonList.get_total_count()
	if total_pokemon == 0:
		return 0.0
	return (float(pokedex_caught.size()) / float(total_pokemon)) * 100.0

# ============================================
# INVENTARIO
# ============================================

func add_item(item_id: int, quantity: int = 1):
	#Añade items al inventario.
	if items.has(item_id):
		items[item_id] += quantity
	else:
		items[item_id] = quantity

func remove_item(item_id: int, quantity: int = 1) -> bool:
	#Elimina items del inventario. Retorna true si se pudo.
	if not items.has(item_id) or items[item_id] < quantity:
		return false
	items[item_id] -= quantity
	if items[item_id] <= 0:
		items.erase(item_id)
	return true

func has_item(item_id: int, quantity: int = 1) -> bool:
	#Verifica si el jugador tiene cierta cantidad de un item.
	return items.get(item_id, 0) >= quantity

func get_item_quantity(item_id: int) -> int:
	#Retorna la cantidad de un item específico.
	return items.get(item_id, 0)

# ============================================
# DINERO
# ============================================

func add_money(amount: int):
	#Añade dinero al jugador (máx. 999,999).
	money = min(money + amount, 999999)

func remove_money(amount: int) -> bool:
	#Quita dinero al jugador. Retorna true si se pudo.
	if money < amount:
		return false
	money -= amount
	return true

func has_money(amount: int) -> bool:
	#Verifica si el jugador tiene suficiente dinero.
	return money >= amount

# ============================================
# MEDALLAS
# ============================================

func add_badge():
	#Añade una medalla al jugador (máx. 64).
	badges = min(badges + 1, 64)

func has_badge(badge_number: int) -> bool:
	#Verifica si el jugador tiene cierta medalla (1-64).
	return badges >= badge_number

# ============================================
# EVENTOS
# ============================================

func set_event_flag(flag_name: String, value: Variant = true):
	#Marca o guarda un evento/valor. Acepta bool, String, int, etc.
	GameData.event_flags[flag_name] = value

func get_event_flag(flag_name: String, default: Variant = null) -> Variant:
	#Obtiene el valor de un event flag con un valor por defecto.
	return GameData.event_flags.get(flag_name, default)

func has_event_flag(flag_name: String) -> bool:
	#Verifica si un evento ha ocurrido (flag existe y es truthy).
	return GameData.has_event_flag(flag_name)

# ============================================
# OBJETIVO DEL JUGADOR
# ============================================

func get_player_objective() -> String:
	#Retorna el objetivo del jugador: "trainer", "ranger" o "professor".
	return GameData.event_flags.get("player_objective", "trainer")

# ============================================
# PROGRESO
# ============================================

func get_play_time() -> float:
	#Retorna el tiempo de juego en segundos.
	return GameData.play_time

func get_play_time_formatted() -> String:
	#Retorna el tiempo de juego formateado como HH:MM:SS.
	return GameData.get_play_time_formatted()

func add_steps(steps: int = 1):
	#Añade pasos caminados.
	GameData.steps_walked += steps

# ============================================
# RESET (para nueva partida)
# ============================================

func reset_game_data():
	#Resetea todos los datos del jugador (para nueva partida).
	GameData.reset()
	print("Datos Reseteados")

# ============================================
# DEBUG
# ============================================

func print_game_state():
	#Imprime el estado actual del juego (debug).
	if not OS.is_debug_build():
		return
	print("=== ESTADO DEL JUEGO ===")
	print("Jugador: ", GameData.name)
	print("Género: ", GameData.gender)
	print("Objetivo: ", get_player_objective())
	print("Dinero: ", GameData.money)
	print("Medallas: ", GameData.badges)
	print("Pokédex: ", GameData.pokedex_caught.size(), " capturados")
	print("Tiempo de juego: ", get_play_time_formatted())
	# print("Equipo: ", GameData.player_pokemon.size(), " Pokémon")
	print("========================")
