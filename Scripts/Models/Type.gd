# ============================================
# Type.gd
# Modelo de tipo de Pokémon (PATRÓN ESTÁNDAR)
# Ubicación: res://scripts/models/Type.gd
# ============================================
class_name Type
extends Resource

# ============================================
# ENUM
# ============================================

enum TypeID {
	NORMAL = 0,
	FIGHTING = 1,
	FLYING = 2,
	POISON = 3,
	GROUND = 4,
	ROCK = 5,
	BUG = 6,
	GHOST = 7,
	STEEL = 8,
	STELLAR = 9,
	FIRE = 10,
	WATER = 11,
	GRASS = 12,
	ELECTRIC = 13,
	PSYCHIC = 14,
	ICE = 15,
	DRAGON = 16,
	DARK = 17,
	FAIRY = 18
}

# ============================================
# PROPIEDADES
# ============================================

var id: int
var name: String  # ID de traducción (ej: "TYPE_FIRE")
var description: String  # ID de descripción
var icon: String
var color: Color

# Efectividades (cargadas desde TypesList)
var attacker: Dictionary = {}  # {type_id: multiplier}
var defender: Dictionary = {}  # {type_id: multiplier}

# ============================================
# CONSTRUCTOR
# ============================================

func _init(
	_id: int = 0,
	_name: String = "",
	_description: String = "",
	_icon: String = "",
	_color: Color = Color.WHITE
):
	id = _id
	name = _name
	description = _description if _description != "" else _name + "_DESC"
	icon = _icon if _icon != "" else _name.to_lower().replace("type_", "")
	color = _color

# ============================================
# LOCALIZACIÓN (PATRÓN ESTÁNDAR)
# ============================================

func get_display_name() -> String:
	#Nombre traducido para mostrar
	return tr(name)

func get_description() -> String:
	#Descripción traducida
	return tr(description)

# ============================================
# RECURSOS
# ============================================

func get_icon_path() -> String:
	#Ruta al icono del tipo
	return "res://Assets/Graphic/Sprites/types/" + icon + ".png"

func get_color() -> Color:
	#Color del tipo
	return color

# ============================================
# ============================================
# EFECTIVIDADES (DESDE TIPO DEL MOVIMIENTO ATACANTE)
# ============================================

func get_effectiveness_against(defender_type_id: int) -> float:
	#Retorna la efectividad de ESTE tipo (movimiento) atacando a UN tipo defensor
	return attacker.get(defender_type_id, 1.0)

func get_effectiveness_against_pokemon(defender_type1_id: int, defender_type2_id: int = -1) -> float:
	#Calcula la efectividad de ESTE tipo (movimiento) atacando a un Pokémon con 1 o 2 tipos
	# Efectividad contra el primer tipo
	var effectiveness1 = get_effectiveness_against(defender_type1_id)
	
	# Si no hay segundo tipo o es el mismo, retornar efectividad simple
	if defender_type2_id < 0 or defender_type2_id == defender_type1_id:
		return effectiveness1
	
	# Efectividad contra el segundo tipo
	var effectiveness2 = get_effectiveness_against(defender_type2_id)
	
	# Multiplicar ambas efectividades
	return effectiveness1 * effectiveness2

func is_super_effective_against_pokemon(defender_type1_id: int, defender_type2_id: int = -1) -> bool:
	#Verifica si ESTE tipo (movimiento) es súper efectivo contra el Pokémon defensor
	return get_effectiveness_against_pokemon(defender_type1_id, defender_type2_id) >= 2.0

func is_not_very_effective_against_pokemon(defender_type1_id: int, defender_type2_id: int = -1) -> bool:
	#Verifica si ESTE tipo (movimiento) es poco efectivo contra el Pokémon defensor
	var eff = get_effectiveness_against_pokemon(defender_type1_id, defender_type2_id)
	return eff > 0.0 and eff <= 0.5

func has_no_effect_on_pokemon(defender_type1_id: int, defender_type2_id: int = -1) -> bool:
	#Verifica si ESTE tipo (movimiento) no tiene efecto en el Pokémon defensor (inmune)
	return get_effectiveness_against_pokemon(defender_type1_id, defender_type2_id) == 0.0

func get_effectiveness_message(defender_type1_id: int, defender_type2_id: int = -1) -> String:
	#Retorna el mensaje de efectividad para mostrar en batalla
	var eff = get_effectiveness_against_pokemon(defender_type1_id, defender_type2_id)
	
	if eff == 0.0:
		return "¡No tiene efecto!"
	elif eff < 1.0:
		return "No es muy eficaz..."
	elif eff > 1.0:
		return "¡Es súper eficaz!"
	else:
		return ""  # Efectividad normal, no mostrar mensaje

# ============================================
# VERIFICACIONES DE TIPO (PARA EL DEFENSOR)
# ============================================

func is_immune_to(attacker_type_id: int) -> bool:
	#Verifica si ESTE tipo es inmune al tipo atacante
	return defender.get(attacker_type_id, 1.0) == 0.0

# ============================================
# FUNCIONES ESTÁTICAS (USO RÁPIDO EN BATALLA)
# ============================================

static func calculate_move_effectiveness(move_type_id: int, pokemon_type1_id: int, pokemon_type2_id: int = -1) -> float:
	#Función estática para calcular efectividad de un movimiento contra un Pokémon
	var move_type = TypesList.get_by_id(move_type_id)
	if not move_type:
		return 1.0
	
	return move_type.get_effectiveness_against_pokemon(pokemon_type1_id, pokemon_type2_id)

static func get_move_effectiveness_message(move_type_id: int, pokemon_type1_id: int, pokemon_type2_id: int = -1) -> String:
	#Función estática para obtener el mensaje de efectividad
	var move_type = TypesList.get_by_id(move_type_id)
	if not move_type:
		return ""
	
	return move_type.get_effectiveness_message(pokemon_type1_id, pokemon_type2_id)

# ============================================
# CONVERSIÓN
# ============================================

static func from_string(type_name: String) -> int:
	#Convierte nombre a TypeID
	match type_name.to_upper():
		"NORMAL": return TypeID.NORMAL
		"FIGHTING": return TypeID.FIGHTING
		"FLYING": return TypeID.FLYING
		"POISON": return TypeID.POISON
		"GROUND": return TypeID.GROUND
		"ROCK": return TypeID.ROCK
		"BUG": return TypeID.BUG
		"GHOST": return TypeID.GHOST
		"STEEL": return TypeID.STEEL
		"STELLAR": return TypeID.STELLAR
		"FIRE": return TypeID.FIRE
		"WATER": return TypeID.WATER
		"GRASS": return TypeID.GRASS
		"ELECTRIC": return TypeID.ELECTRIC
		"PSYCHIC": return TypeID.PSYCHIC
		"ICE": return TypeID.ICE
		"DRAGON": return TypeID.DRAGON
		"DARK": return TypeID.DARK
		"FAIRY": return TypeID.FAIRY
		_: return -1

static func to_string_name(type_id: int) -> String:
	#Convierte TypeID a nombre
	match type_id:
		TypeID.NORMAL: return "Normal"
		TypeID.FIGHTING: return "Fighting"
		TypeID.FLYING: return "Flying"
		TypeID.POISON: return "Poison"
		TypeID.GROUND: return "Ground"
		TypeID.ROCK: return "Rock"
		TypeID.BUG: return "Bug"
		TypeID.GHOST: return "Ghost"
		TypeID.STEEL: return "Steel"
		TypeID.STELLAR: return "Stellar"
		TypeID.FIRE: return "Fire"
		TypeID.WATER: return "Water"
		TypeID.GRASS: return "Grass"
		TypeID.ELECTRIC: return "Electric"
		TypeID.PSYCHIC: return "Psychic"
		TypeID.ICE: return "Ice"
		TypeID.DRAGON: return "Dragon"
		TypeID.DARK: return "Dark"
		TypeID.FAIRY: return "Fairy"
		_: return "Unknown"

# ============================================
# UTILIDADES (PATRÓN ESTÁNDAR)
# ============================================

func is_valid() -> bool:
	#Verifica si el tipo es válido
	return id >= 0 and id <= 18 and name != ""

func _to_string() -> String:
	#Para debugging
	return "Type(%d: %s)" % [id, name]
