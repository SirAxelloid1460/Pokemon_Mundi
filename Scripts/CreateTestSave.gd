# ============================================
# CreateTestSave.gd
# Script temporal para generar partidas de prueba
# 
# USO: Adjuntarlo a cualquier nodo, correr el juego
# una vez y luego eliminarlo.
# ============================================
extends Node

func _ready():
	create_test_saves()
	print("✅ Partidas de prueba creadas. Podés eliminar este script.")

func create_test_saves():
	# ---- Partida 1 — Entrenador ----
	Game.reset_game_data()
	Game.player_name   = "Ash"
	Game.player_gender = "boy"
	Game.player_appearance = {
		"skin_tone": 1, "hair_style": 2, "hair_color": 0,
		"hat": 1, "shirt": 0, "pants": 0, "shoes": 0, "gloves": 0
	}
	Game.GameData.money   = 12500
	Game.GameData.badges  = 3
	Game.GameData.play_time = 7234.0  # ~2h
	Game.GameData.active_scene = "res://Scenes/world/PalletTown.tscn"
	Game.GameData.event_flags["player_objective"] = "trainer"
	Game.GameData.pokedex_caught = [1, 4, 7, 25, 133]
	SaveManager.save_game(2, "Ash — Pueblo Paleta")

	# ---- Partida 2 — Ranger ----
	Game.reset_game_data()
	Game.player_name   = "Lunick"
	Game.player_gender = "boy"
	Game.player_appearance = {
		"skin_tone": 0, "hair_style": 4, "hair_color": 5,
		"hat": 0, "shirt": 2, "pants": 1, "shoes": 2, "gloves": 1
	}
	Game.GameData.money   = 3000
	Game.GameData.badges  = 0
	Game.GameData.play_time = 3612.0  # ~1h
	Game.GameData.active_scene = "res://Scenes/world/AlmiaForest.tscn"
	Game.GameData.event_flags["player_objective"] = "ranger"
	Game.GameData.pokedex_caught = [25, 393, 396]
	SaveManager.save_game(3, "Lunick — Bosque Almia")

	# ---- Partida 3 — Profesora ----
	Game.reset_game_data()
	Game.player_name   = "Rosa"
	Game.player_gender = "girl"
	Game.player_appearance = {
		"skin_tone": 2, "hair_style": 6, "hair_color": 8,
		"hat": 0, "shirt": 5, "pants": 3, "shoes": 4, "gloves": 0
	}
	Game.GameData.money   = 45000
	Game.GameData.badges  = 8
	Game.GameData.play_time = 54321.0  # ~15h
	Game.GameData.active_scene = "res://Scenes/world/ProfessorLab.tscn"
	Game.GameData.event_flags["player_objective"] = "professor"
	var pokedex: Array[int] = []
	for i in range(1, 52):
		pokedex.append(i)
	Game.GameData.pokedex_caught = pokedex  # 51 Pokémon capturados
	SaveManager.save_game(4, "Rosa — Laboratorio")

	# Resetear GameData para no dejar basura
	Game.reset_game_data()
	SaveManager.current_slot = -1
