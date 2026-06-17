# ============================================
# LocalizationManager.gd (Autoload/Singleton)
# Gestor de idiomas y localización
# Ubicación: res://Scripts/Autoloads/LocalizationManager.gd
#
# IMPORTANTE: Configurar como AutoLoad
# Project Settings → AutoLoad → Nombre: "LocalizationManager"
#
# ESTRUCTURA de archivos de traducción:
# res://translates/
# ├── es_ES.po  ├── es_LA.po  ├── en.po
# ├── fr.po     ├── de.po     ├── it.po
# ├── pt.po     └── ja.po
#
# VARIANTES REGIONALES:
# - "es_ES" y "es_LA" son idiomas distintos en el selector
# - Comparten la misma base de Godot locale "es" para tr()
#   pero get_current_language() retorna el código completo
#   para que IntroScreen pueda elegir el video correcto
# ============================================
extends Node

# ============================================
# IDIOMAS DISPONIBLES
#
# "locale" → código que se pasa a TranslationServer
# "code"   → código completo usado internamente (para videos, etc.)
# ============================================
var languages: Dictionary = {
	"es_ES": {
		"code":   "es_ES",
		"locale": "es",
		"name":   "Español (España)",
		"flag":   "res://translates/flags/es_ES.png"
	},
	"es_LA": {
		"code":   "es_LA",
		"locale": "es",
		"name":   "Español (Latinoamérica)",
		"flag":   "res://translates/flags/es_LA.png"
	},
	"en": {
		"code":   "en",
		"locale": "en",
		"name":   "English",
		"flag":   "res://translates/flags/en.png"
	},
	"fr": {
		"code":   "fr",
		"locale": "fr",
		"name":   "Français",
		"flag":   "res://translates/flags/fr.png"
	},
	"de": {
		"code":   "de",
		"locale": "de",
		"name":   "Deutsch",
		"flag":   "res://translates/flags/de.png"
	},
	"it": {
		"code":   "it",
		"locale": "it",
		"name":   "Italiano",
		"flag":   "res://translates/flags/it.png"
	},
	"pt": {
		"code":   "pt",
		"locale": "pt",
		"name":   "Português",
		"flag":   "res://translates/flags/pt.png"
	},
	"ja": {
		"code":   "ja",
		"locale": "ja",
		"name":   "日本語",
		"flag":   "res://translates/flags/ja.png"
	},
}

# Mapeo de locale del sistema → código interno
# OS.get_locale() puede retornar "es_ES", "es_MX", "es_AR", etc.
const LOCALE_TO_CODE: Dictionary = {
	"es_ES": "es_ES",
	"es_MX": "es_LA",
	"es_AR": "es_LA",
	"es_CO": "es_LA",
	"es_CL": "es_LA",
	"es_PE": "es_LA",
	"es_VE": "es_LA",
	"es_EC": "es_LA",
	"es_GT": "es_LA",
	"es_CU": "es_LA",
	"es_BO": "es_LA",
	"es_DO": "es_LA",
	"es_HN": "es_LA",
	"es_PY": "es_LA",
	"es_SV": "es_LA",
	"es_NI": "es_LA",
	"es_CR": "es_LA",
	"es_PA": "es_LA",
	"es_UY": "es_LA",
}

var current_language: String = "es_ES"

# ============================================
# INICIALIZACIÓN
# ============================================

func _ready():
	#Carga el idioma guardado o detecta el del sistema.
	var saved = Game.GameData.game_options.get("language", "")
	#var saved = "en" #For Debugging language

	if saved != "" and languages.has(saved):
		set_language(saved)
	else:
		_detect_system_language()

func _detect_system_language():
	#Detecta el idioma del sistema con soporte para variantes regionales.
	var system_locale = OS.get_locale()  # ej: "es_ES", "es_MX", "en_US"

	# 1. Buscar locale completo en el mapeo (es_MX → es_LA)
	if LOCALE_TO_CODE.has(system_locale):
		set_language(LOCALE_TO_CODE[system_locale])
		return

	# 2. Buscar por código corto (en, fr, de...)
	var short = system_locale.substr(0, 2)
	if languages.has(short):
		set_language(short)
		return

	# 3. Fallback
	set_language("es_ES")

# ============================================
# API PÚBLICA
# ============================================

func get_available_languages() -> Array:
	#Retorna la lista de idiomas para mostrar en el selector de opciones.
	var lang_list = []
	for lang_code in languages.keys():
		lang_list.append(languages[lang_code])
	return lang_list

func set_language(lang_code: String):
	#Cambia el idioma del juego.
	if not languages.has(lang_code):
		push_warning("LocalizationManager: Idioma no soportado: '%s'" % lang_code)
		lang_code = "es_ES"

	current_language = lang_code
	var locale = languages[lang_code].locale
	TranslationServer.set_locale(locale)

	# Guardar en GameData
	Game.GameData.game_options["language"] = lang_code

	print("LocalizationManager: Idioma → %s (locale: %s)" % [
		languages[lang_code].name, locale
	])

func get_current_language() -> String:
	#Retorna el código completo del idioma actual (ej: "es_ES", "es_LA", "en").
	#Usado por IntroScreen para elegir el video correcto.
	return current_language

func get_current_locale() -> String:
	#Retorna el locale de Godot (ej: "es", "en", "ja").
	#Usado por TranslationServer internamente.
	return languages[current_language].locale

func get_text(key: String) -> String:
	#Obtiene un texto traducido por su clave.
	return tr(key)
