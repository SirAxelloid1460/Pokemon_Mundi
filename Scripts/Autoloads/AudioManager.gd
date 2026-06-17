# ============================================
# AudioManager.gd (Autoload/Singleton)
# Gestiona mÃºsica y efectos de sonido
# UbicaciÃ³n: res://scripts/autoloads/AudioManager.gd
# 
# IMPORTANTE: Este archivo debe estar configurado como AutoLoad
# Project Settings â†’ AutoLoad â†’ Nombre: "AudioManager"
# 
# REQUISITOS:
# - Buses de audio "Music" y "SFX" deben existir
# - Project Settings â†’ Audio â†’ Buses
# ============================================

extends Node

# Reproductores de audio
var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []

# ConfiguraciÃ³n
const MAX_SFX_PLAYERS: int = 8
const FADE_DURATION: float = 1.0

# Bibliotecas de audio
var sfx_library: Dictionary = {}
var music_library: Dictionary = {}

# Estado actual
var current_music: String = ""
var music_volume: float = 100.0
var sfx_volume: float = 100.0

func _ready():
	_setup_audio_buses()
	_create_audio_players()
	_load_audio_libraries()

func _setup_audio_buses():
	#Configura los buses de audio si no existen
	# Verificar si los buses existen, si no, crearlos
	var bus_layout = AudioServer.get_bus_count()
	
	# Crear bus de mÃºsica si no existe
	var music_bus_idx = AudioServer.get_bus_index("Music")
	if music_bus_idx == -1:
		AudioServer.add_bus()
		music_bus_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(music_bus_idx, "Music")
		AudioServer.set_bus_send(music_bus_idx, "Master")
	
	# Crear bus de SFX si no existe
	var sfx_bus_idx = AudioServer.get_bus_index("SFX")
	if sfx_bus_idx == -1:
		AudioServer.add_bus()
		sfx_bus_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(sfx_bus_idx, "SFX")
		AudioServer.set_bus_send(sfx_bus_idx, "Master")

func _create_audio_players():
	#Crea los reproductores de audio
	# Crear reproductor de mÃºsica
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	music_player.name = "MusicPlayer"
	add_child(music_player)
	
	# Crear pool de reproductores de SFX
	for i in range(MAX_SFX_PLAYERS):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		player.name = "SFXPlayer" + str(i)
		add_child(player)
		sfx_players.append(player)

func _load_audio_libraries():
	#Carga las bibliotecas de audio desde archivos
	# SFX
	_load_sfx("menu_select", "res://audio/sfx/menu_select.wav")
	_load_sfx("menu_move", "res://audio/sfx/menu_move.wav")
	_load_sfx("menu_back", "res://audio/sfx/menu_back.wav")
	_load_sfx("menu_error", "res://audio/sfx/menu_error.wav")
	_load_sfx("text_blip", "res://audio/sfx/text_blip.wav")
	_load_sfx("menu_cursor", "res://audio/sfx/menu_cursor.wav")
	
	# MÃºsica
	_load_music("title", "res://audio/music/title.ogg")
	_load_music("main_menu", "res://audio/music/main_menu.ogg")
	_load_music("intro", "res://audio/music/intro.ogg")
	_load_music("lab", "res://audio/music/lab.ogg")
	_load_music("route", "res://audio/music/route.ogg")
	_load_music("battle_wild", "res://audio/music/battle_wild.ogg")
	_load_music("battle_trainer", "res://audio/music/battle_trainer.ogg")

func _load_sfx(sfx_name: String, path: String):
	#Carga un efecto de sonido si existe
	if ResourceLoader.exists(path):
		sfx_library[sfx_name] = load(path)
	else:
		if OS.is_debug_build():
			push_warning("SFX no encontrado: " + path)

func _load_music(music_name: String, path: String):
	#Carga una pista de mÃºsica si existe
	if ResourceLoader.exists(path):
		music_library[music_name] = load(path)
	else:
		if OS.is_debug_build():
			push_warning("MÃºsica no encontrada: " + path)

# ============================================
# FUNCIONES DE MÃšSICA
# ============================================

func play_music(track_name: String, fade_in: float = 0.0):
	#Reproduce una pista de mÃºsica.
	#Args:
	#	track_name: Nombre de la pista en la biblioteca
	#	fade_in: DuraciÃ³n del fade in en segundos (0 = sin fade)
	var stream = music_library.get(track_name)
	if not stream:
		push_warning("MÃºsica no encontrada: " + track_name)
		return
	
	# Si ya estÃ¡ sonando esta mÃºsica, no hacer nada
	if current_music == track_name and music_player.playing:
		return
	
	current_music = track_name
	
	if fade_in > 0:
		music_player.volume_db = -80
		music_player.stream = stream
		music_player.play()
		
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", linear_to_db(music_volume / 100.0), fade_in)
	else:
		music_player.volume_db = linear_to_db(music_volume / 100.0)
		music_player.stream = stream
		music_player.play()

func stop_music(fade_out: float = 0.0):
	#Detiene la mÃºsica actual.
	#Args:
	#	fade_out: DuraciÃ³n del fade out en segundos (0 = sin fade)
	if fade_out > 0:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80, fade_out)
		await tween.finished
		music_player.stop()
	else:
		music_player.stop()
	
	current_music = ""

func pause_music():
	#Pausa la mÃºsica actual
	music_player.stream_paused = true

func resume_music():
	#Resume la mÃºsica pausada
	music_player.stream_paused = false

func is_music_playing() -> bool:
	#Retorna true si hay mÃºsica sonando
	return music_player.playing

func get_current_music() -> String:
	#Retorna el nombre de la mÃºsica actual
	return current_music

# ============================================
# FUNCIONES DE EFECTOS DE SONIDO
# ============================================

func play_sfx(sfx_name: String, pitch: float = 1.0):
	#Reproduce un efecto de sonido.
	#Args:
	#	sfx_name: Nombre del SFX en la biblioteca
	#	pitch: VariaciÃ³n de pitch (1.0 = normal)
	var stream = sfx_library.get(sfx_name)
	if not stream:
		if OS.is_debug_build():
			push_warning("SFX no encontrado: " + sfx_name)
		return
	
	# Buscar un reproductor disponible
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.pitch_scale = pitch
			player.volume_db = linear_to_db(sfx_volume / 100.0)
			player.play()
			return
	
	# Si no hay reproductores disponibles, usar el primero (override)
	if sfx_players.size() > 0:
		var player = sfx_players[0]
		player.stream = stream
		player.pitch_scale = pitch
		player.volume_db = linear_to_db(sfx_volume / 100.0)
		player.play()

func stop_all_sfx():
	#Detiene todos los efectos de sonido
	for player in sfx_players:
		player.stop()

# ============================================
# FUNCIONES DE VOLUMEN
# ============================================

func set_music_volume(volume: float):
	#Ajusta el volumen de la mÃºsica (0-100).
	#Args:
	#	volume: Volumen de 0 a 100
	music_volume = clamp(volume, 0.0, 100.0)
	var db = linear_to_db(music_volume / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)

func set_sfx_volume(volume: float):
	#Ajusta el volumen de los efectos de sonido (0-100).
	#Args:
	#	volume: Volumen de 0 a 100
	sfx_volume = clamp(volume, 0.0, 100.0)
	var db = linear_to_db(sfx_volume / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db)

func set_master_volume(volume: float):
	#Ajusta el volumen master (0-100).
	#Args:
	#	volume: Volumen de 0 a 100
	#
	var vol = clamp(volume, 0.0, 100.0)
	var db = linear_to_db(vol / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)

func get_music_volume() -> float:
	#Retorna el volumen actual de mÃºsica (0-100)
	return music_volume

func get_sfx_volume() -> float:
	#Retorna el volumen actual de SFX (0-100)
	return sfx_volume

func mute_music():
	#Silencia la mÃºsica
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), true)

func unmute_music():
	#Quita el silencio de la mÃºsica
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), false)

func mute_sfx():
	#Silencia los efectos de sonido
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), true)

func unmute_sfx():
	#Quita el silencio de los efectos de sonido
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), false)

# ============================================
# UTILIDADES
# ============================================

func linear_to_db(linear: float) -> float:
	#Convierte volumen lineal (0-1) a decibelios.
	#Args:
	#	linear: Volumen lineal de 0.0 a 1.0
	#Returns:
	#	Volumen en decibelios
	
	if linear <= 0:
		return -80.0
	return 20.0 * log(linear) / log(10.0)

func db_to_linear(db: float) -> float:
	# Convierte decibelios a volumen lineal (0-1).
	#Args:
	#	db: Volumen en decibelios
	#Returns:
	#	Volumen lineal de 0.0 a 1.0
	if db <= -80:
		return 0.0
	return pow(10.0, db / 20.0)

# ============================================
# FUNCIONES DE TRANSICIÃ“N
# ============================================

func crossfade_music(new_track: String, duration: float = FADE_DURATION):
	#Hace crossfade entre la mÃºsica actual y una nueva.
	#Args:
	#	new_track: Nombre de la nueva pista
	#	duration: DuraciÃ³n del crossfade
	if current_music == new_track:
		return
	
	# Fade out mÃºsica actual
	await stop_music(duration)
	
	# Esperar un poco antes de empezar la nueva
	await get_tree().create_timer(duration / 2.0).timeout
	
	# Fade in nueva mÃºsica
	play_music(new_track, duration)

func duck_music(duck_amount: float = 0.3, duration: float = 0.5):
	#Reduce el volumen de la mÃºsica temporalmente (para diÃ¡logos importantes).
	#Args:
	#	duck_amount: Cantidad a reducir (0-1, donde 1 = silencio total)
	#	duration: DuraciÃ³n de la transiciÃ³n

	var target_db = linear_to_db((music_volume / 100.0) * (1.0 - duck_amount))
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", target_db, duration)

func unduck_music(duration: float = 0.5):
	#Restaura el volumen normal de la mÃºsica.
	#Args:
	#	duration: DuraciÃ³n de la transiciÃ³n
	
	var target_db = linear_to_db(music_volume / 100.0)
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", target_db, duration)
