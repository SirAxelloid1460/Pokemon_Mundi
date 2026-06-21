class_name VivillonPattern
extends RefCounted
# Determina el patrón de Vivillon según el país real del jugador (region-lock del 3DS).
# Fuente del mapa: Bulbapedia. País obtenido de OS.get_locale() (ya usado por LocalizationManager).
# En países "divididos" entre varios patrones se elige el representativo (más extenso/poblado);
# afinar si hace falta. Fancy y Poké Ball NO son region-lock (solo eventos), por eso no se asignan.

const DEFAULT_PATTERN := "vivillon-meadow"

# ISO 3166-1 alpha-2 (código de país del locale) → slug de forma.
const COUNTRY_TO_PATTERN := {
	# Icy Snow / Polar / Tundra (norte frío)
	"FI": "vivillon-icy-snow",
	"SE": "vivillon-polar",
	"NO": "vivillon-tundra", "IS": "vivillon-tundra",
	# Continental (centro de Europa + Asia oriental)
	"DE": "vivillon-continental", "NL": "vivillon-continental", "DK": "vivillon-continental",
	"CN": "vivillon-continental", "KR": "vivillon-continental", "BE": "vivillon-continental",
	"AT": "vivillon-continental", "CH": "vivillon-continental", "PL": "vivillon-continental",
	"CZ": "vivillon-continental", "SK": "vivillon-continental", "HU": "vivillon-continental",
	# Garden (Islas británicas + Oceanía templada)
	"GB": "vivillon-garden", "IE": "vivillon-garden", "NZ": "vivillon-garden",
	# Elegant (Japón)
	"JP": "vivillon-elegant",
	# Meadow (Francia y similares; también el fallback)
	"FR": "vivillon-meadow",
	# Modern (EE. UU.)
	"US": "vivillon-modern",
	# Marine (península ibérica, Italia, Chile)
	"ES": "vivillon-marine", "PT": "vivillon-marine", "IT": "vivillon-marine",
	"CL": "vivillon-marine", "GR": "vivillon-marine",
	# Archipelago (Caribe / norte de Sudamérica)
	"DO": "vivillon-archipelago", "PR": "vivillon-archipelago", "HT": "vivillon-archipelago",
	"CU": "vivillon-archipelago",
	# High Plains (oeste de EE.UU. ya es Modern; aquí Rusia/Azerbaiyán)
	"RU": "vivillon-high-plains", "AZ": "vivillon-high-plains",
	# Sandstorm (Oriente Medio + Turquía)
	"TR": "vivillon-sandstorm", "SA": "vivillon-sandstorm", "AE": "vivillon-sandstorm",
	"IL": "vivillon-sandstorm", "IR": "vivillon-sandstorm", "IQ": "vivillon-sandstorm",
	"JO": "vivillon-sandstorm", "KW": "vivillon-sandstorm", "QA": "vivillon-sandstorm",
	"OM": "vivillon-sandstorm", "BH": "vivillon-sandstorm", "LB": "vivillon-sandstorm",
	"SY": "vivillon-sandstorm", "YE": "vivillon-sandstorm",
	# River (Australia)
	"AU": "vivillon-river",
	# Monsoon (sur/este de Asia)
	"IN": "vivillon-monsoon", "HK": "vivillon-monsoon", "TW": "vivillon-monsoon",
	# Savanna (cono sur y Brasil)
	"BR": "vivillon-savanna", "AR": "vivillon-savanna", "UY": "vivillon-savanna",
	"PY": "vivillon-savanna", "BO": "vivillon-savanna",
	# Sun (Centroamérica + sur de México)
	"MX": "vivillon-sun", "GT": "vivillon-sun", "HN": "vivillon-sun", "NI": "vivillon-sun",
	"SV": "vivillon-sun", "BZ": "vivillon-sun", "ZW": "vivillon-sun",
	# Ocean (islas)
	"RE": "vivillon-ocean",
	# Jungle (trópico ecuatorial)
	"CO": "vivillon-jungle", "VE": "vivillon-jungle", "PE": "vivillon-jungle",
	"EC": "vivillon-jungle", "MY": "vivillon-jungle", "SG": "vivillon-jungle",
	"PA": "vivillon-jungle", "CR": "vivillon-jungle", "GF": "vivillon-jungle",
	"GY": "vivillon-jungle", "SR": "vivillon-jungle",
}

# Extrae el código de país de un locale tipo "es_ES", "en_US.UTF-8", "pt_BR@variant".
static func country_from_locale(locale: String) -> String:
	var parts := locale.split("_")
	if parts.size() < 2:
		return ""
	var cc := parts[1]
	cc = cc.split(".")[0]
	cc = cc.split("@")[0]
	return cc.to_upper()

# Slug del patrón para un código de país (con fallback).
static func pattern_for_country(country_code: String) -> String:
	return COUNTRY_TO_PATTERN.get(country_code.to_upper(), DEFAULT_PATTERN)

# Slug del patrón para un locale completo.
static func pattern_for_locale(locale: String) -> String:
	return pattern_for_country(country_from_locale(locale))

# Slug del patrón del jugador actual (según el SO).
static func pattern_for_player() -> String:
	return pattern_for_locale(OS.get_locale())
