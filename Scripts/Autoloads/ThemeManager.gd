# ============================================
# ThemeManager.gd (Autoload/Singleton)
# Gestor de temas/marcos de UI
# Ubicación: res://scripts/autoloads/ThemeManager.gd
#
# IMPORTANTE: Configurar como AutoLoad
# Project Settings → AutoLoad → Nombre: "ThemeManager"
# ============================================
extends Node

var themes: Dictionary = {
	"default": {
		"id": "default",
		"name": "Clásico",
		"description": "Estilo clásico de Pokémon",
		"theme_path": "res://themes/classic_theme.tres",
		"preview": "res://themes/previews/classic.png"
	},
	"modern": {
		"id": "modern",
		"name": "Moderno",
		"description": "Diseño moderno y limpio",
		"theme_path": "res://themes/modern_theme.tres",
		"preview": "res://themes/previews/modern.png"
	},
	"retro": {
		"id": "retro",
		"name": "Retro",
		"description": "Estilo pixel art retro",
		"theme_path": "res://themes/retro_theme.tres",
		"preview": "res://themes/previews/retro.png"
	},
	"neon": {
		"id": "neon",
		"name": "Neón",
		"description": "Colores vibrantes neón",
		"theme_path": "res://themes/neon_theme.tres",
		"preview": "res://themes/previews/neon.png"
	}
}

var current_theme_id: String = "default"

func get_available_themes() -> Array:
	#Retorna la lista de temas disponibles.
	var theme_list = []
	for theme_id in themes.keys():
		theme_list.append(themes[theme_id])
	return theme_list

func get_theme_data(theme_id: String) -> Dictionary:
	#Obtiene datos de un tema específico.
	return themes.get(theme_id, themes["default"])

func preview_theme(theme_id: String):
	#Previsualiza un tema sin aplicarlo permanentemente.
	apply_theme(theme_id)

func apply_theme(theme_id: String):
	#Aplica un tema a toda la UI.
	if not themes.has(theme_id):
		push_warning("ThemeManager: Tema no encontrado: " + theme_id)
		theme_id = "default"

	current_theme_id = theme_id
	var theme_data = themes[theme_id]
	var theme_path = theme_data.theme_path

	if ResourceLoader.exists(theme_path):
		var theme = load(theme_path)
		_apply_theme_recursive(get_tree().root, theme)
		print("ThemeManager: Tema aplicado: " + theme_data.name)
	else:
		push_warning("ThemeManager: Archivo de tema no encontrado: " + theme_path)

func _apply_theme_recursive(node: Node, theme: Theme):
	#Aplica el tema recursivamente a todos los nodos Control.
	if node is Control:
		node.theme = theme
	for child in node.get_children():
		_apply_theme_recursive(child, theme)

func get_current_theme_id() -> String:
	#Retorna el ID del tema actual.
	return current_theme_id
