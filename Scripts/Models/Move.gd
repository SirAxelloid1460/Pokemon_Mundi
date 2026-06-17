# ============================================
# Move.gd
# Clase para movimientos Pokémon
# Compatible con carga desde JSON
# Ubicación: res://scripts/models/Move.gd
# ============================================
class_name Move
extends Resource

# ============================================
# ENUMS
# ============================================

enum MoveType {
	NORMAL, FIRE, WATER, ELECTRIC, GRASS, ICE,
	FIGHTING, POISON, GROUND, FLYING, PSYCHIC,
	BUG, ROCK, GHOST, DRAGON, DARK, STEEL, FAIRY
}

enum Category {
	PHYSICAL,
	SPECIAL,
	STATUS
}

# ============================================
# PROPIEDADES BASE (compatibles con tu JSON)
# ============================================

var moveID: int
var name: String
var power: int
var accuracy: float  # 0.0 - 1.0 (como en tu JSON)
var totalpp: int
var currentpp: int
var type: String  # Mantenemos String para compatibilidad con JSON
var category: String  # Mantenemos String para compatibilidad con JSON
var description: String
var contact: bool
var overworldUse: bool

# ============================================
# PROPIEDADES CALCULADAS (recursos)
# ============================================

var animation_front: String
var animation_back: String
var animation_overworld: String
var sfx: String

# ============================================
# PROPIEDADES ADICIONALES (opcionales)
# ============================================

var priority: int = 0
var effect_chance: int = 0
var effect_id: int = -1
var target: int = 0
var crit_rate: int = 0
var flinch_chance: int = 0
var recoil: int = 0
var drain: int = 0
var multi_hit_min: int = 1  # Para movimientos como Double Slap
var multi_hit_max: int = 1

# ============================================
# CONSTRUCTOR
# ============================================

func _init(
	_moveID: int = 0,
	_name: String = "",
	_power: int = 0,
	_accuracy: float = 1.0,
	_totalpp: int = 10,
	_type: String = "Normal",
	_category: String = "Physical",
	_description: String = "",
	_contact: bool = false,
	_overworldUse: bool = false
):
	moveID = _moveID
	name = _name
	power = _power
	accuracy = _accuracy
	totalpp = _totalpp
	currentpp = _totalpp
	type = _type
	category = _category
	description = _description
	contact = _contact
	overworldUse = _overworldUse
	
	# Generar nombres de recursos
	_generate_resource_names()
	
	# Detectar multi-hit basado en nombre o descripción
	_detect_multi_hit()

func _generate_resource_names():
	#Genera los nombres de animaciones y SFX basados en el nombre del movimiento
	if name != "":
		var safe_name = name.to_lower().replace(" ", "_")
		animation_front = safe_name + "_front"
		animation_back = safe_name + "_back"
		animation_overworld = safe_name + "_overworld"
		sfx = safe_name + ".ogg"

func _detect_multi_hit():
	#Detecta si el movimiento golpea múltiples veces basado en descripción
	var desc_lower = description.to_lower()
	
	# Double Slap, Comet Punch, etc. (2-5 hits)
	if "2 to 5 times" in desc_lower:
		multi_hit_min = 2
		multi_hit_max = 5
	# Double Kick (2 hits fijos)
	elif "twice" in desc_lower or "double" in name.to_lower():
		multi_hit_min = 2
		multi_hit_max = 2
	# Triple Kick (3 hits)
	elif "triple" in name.to_lower():
		multi_hit_min = 3
		multi_hit_max = 3

# ============================================
# LOCALIZACIÓN (PATRÓN ESTÁNDAR)
# ============================================

func get_display_name() -> String:
	#Nombre traducido para mostrar al usuario
	return tr(name)

func get_description() -> String:
	#Descripción traducida
	return tr(description)

# ============================================
# CONVERSIÓN DE TIPOS (String <-> Enum)
# ============================================

func get_type_enum() -> Type.TypeID:
	#Convierte el string de tipo a Type.TypeID de la clase global Type
	return Type.from_string(type)

func get_type_id() -> Type.TypeID:
	#Alias para get_type_enum() - más intuitivo para comparaciones
	return get_type_enum()

func get_category_enum() -> Category:
	#Convierte el string de categoría a enum
	return category_from_string(category)

static func category_from_string(cat_str: String) -> Category:
	#Convierte string a enum Category
	match cat_str:
		"Physical": return Category.PHYSICAL
		"Special": return Category.SPECIAL
		"Status": return Category.STATUS
		_: return Category.PHYSICAL

# ============================================
# MÉTODOS DE PP
# ============================================

func restore_pp(amount: int = -1):
	#Restaura PP del movimiento
	if amount == -1:
		currentpp = totalpp
	else:
		currentpp = min(currentpp + amount, totalpp)

func use_pp() -> bool:
	#Consume 1 PP del movimiento
	if currentpp > 0:
		currentpp -= 1
		return true
	return false

func has_pp() -> bool:
	#Retorna true si el movimiento tiene PP disponible
	return currentpp > 0

func get_pp_percentage() -> float:
	#Retorna el porcentaje de PP actual (0.0 - 1.0)
	if totalpp == 0:
		return 0.0
	return float(currentpp) / float(totalpp)

# ============================================
# CONSULTAS DE TIPO Y CATEGORÍA
# ============================================

func is_physical() -> bool:
	#Retorna true si el movimiento es físico
	return category == "Physical"

func is_special() -> bool:
	#Retorna true si el movimiento es especial
	return category == "Special"

func is_status() -> bool:
	#Retorna true si el movimiento es de estado
	return category == "Status"

func is_damaging() -> bool:
	#Retorna true si el movimiento hace daño
	return power > 0

func is_multi_hit() -> bool:
	#Retorna true si el movimiento golpea múltiples veces
	return multi_hit_max > 1

func is_one_hit_ko() -> bool:
	#Retorna true si es un movimiento de KO en un golpe (como Guillotine)
	return power >= 65535  # Valor especial en el JSON

# ============================================
# CÁLCULO DE HITS MÚLTIPLES
# ============================================

func get_hit_count() -> int:
	#Retorna el número de golpes para movimientos multi-hit
	if not is_multi_hit():
		return 1
	
	# 2-5 hits con distribución de probabilidad
	if multi_hit_min == 2 and multi_hit_max == 5:
		var rand = randf()
		if rand < 0.375:  # 37.5%
			return 2
		elif rand < 0.75:  # 37.5%
			return 3
		elif rand < 0.875:  # 12.5%
			return 4
		else:  # 12.5%
			return 5
	
	# Hits fijos (Double Kick, etc.)
	return multi_hit_min

# ============================================
# INFORMACIÓN Y FORMATEO
# ============================================

func get_accuracy_percentage() -> int:
	#Retorna la precisión como porcentaje (0-100)
	if accuracy >= 10:  # Caso especial como Whirlwind
		return 100
	return int(accuracy * 100)

func get_info_text() -> String:
	#Retorna un texto con la información del movimiento para UI
	var info = name + "\n"
	info += "Type: " + type + "\n"
	info += "Category: " + category + "\n"
	
	if is_damaging():
		info += "Power: " + str(power) + "\n"
	else:
		info += "Power: ---\n"
	
	info += "Accuracy: " + str(get_accuracy_percentage()) + "%\n"
	info += "PP: " + str(currentpp) + "/" + str(totalpp) + "\n"
	info += "\n" + description
	
	return info

func get_short_info() -> String:
	#Retorna información breve para batalla
	return "%s (PP: %d/%d)" % [name, currentpp, totalpp]

# ============================================
# RUTAS DE RECURSOS
# ============================================

func get_animation_path(perspective: String = "front") -> String:
	#Retorna la ruta a la animación del movimiento
	var base_path = "res://Assets/Graphic/Sprites/moves/"
	match perspective:
		"front":
			return base_path + animation_front
		"back":
			return base_path + animation_back
		"overworld":
			return base_path + animation_overworld
		_:
			return base_path + animation_front

func get_sfx_path() -> String:
	#Retorna la ruta al archivo de sonido del movimiento
	return "res://Assets/SFX/moves/" + sfx

func has_animation(perspective: String = "front") -> bool:
	#Verifica si existe la animación
	var path = get_animation_path(perspective)
	return ResourceLoader.exists(path)

func has_sfx() -> bool:
	#Verifica si existe el archivo de sonido
	return ResourceLoader.exists(get_sfx_path())

# ============================================
# SERIALIZACIÓN
# ============================================

func to_dict() -> Dictionary:
	#Convierte el movimiento a diccionario para guardado
	return {
		"moveID": moveID,
		"currentpp": currentpp,
		"priority": priority,
		"effect_chance": effect_chance,
		"effect_id": effect_id
	}

func from_dict(data: Dictionary):
	#Carga datos desde un diccionario
	if data.has("currentpp"):
		currentpp = data.currentpp
	if data.has("priority"):
		priority = data.priority
	if data.has("effect_chance"):
		effect_chance = data.effect_chance
	if data.has("effect_id"):
		effect_id = data.effect_id

# ============================================
# UTILIDADES
# ============================================

func duplicate_move() -> Move:
	#Crea una copia del movimiento
	var new_move = Move.new(
		moveID, name, power, accuracy, totalpp,
		type, category, description, contact, overworldUse
	)
	new_move.currentpp = currentpp
	new_move.priority = priority
	new_move.effect_chance = effect_chance
	new_move.effect_id = effect_id
	new_move.target = target
	new_move.crit_rate = crit_rate
	new_move.flinch_chance = flinch_chance
	new_move.recoil = recoil
	new_move.drain = drain
	new_move.multi_hit_min = multi_hit_min
	new_move.multi_hit_max = multi_hit_max
	return new_move

func is_valid() -> bool:
	#Verifica si el movimiento es válido
	if moveID <= 0:
		return false
	if name == "":
		return false
	if totalpp <= 0:
		return false
	return true

func _to_string() -> String:
	#Override para debugging
	return "Move(%d: %s, %s/%s, Power: %d, PP: %d/%d)" % [
		moveID, name, type, category, power, currentpp, totalpp
	]

# ============================================
# EFECTOS ESPECIALES
# ============================================

func get_special_properties() -> Dictionary:
	#Retorna propiedades especiales del movimiento
	var props = {}
	
	if is_one_hit_ko():
		props["one_hit_ko"] = true
	
	if is_multi_hit():
		props["multi_hit"] = true
		props["hit_range"] = [multi_hit_min, multi_hit_max]
	
	if contact:
		props["makes_contact"] = true
	
	if overworldUse:
		props["overworld_use"] = true
	
	if priority != 0:
		props["priority"] = priority
	
	if recoil > 0:
		props["recoil"] = recoil
	
	if drain > 0:
		props["drain"] = drain
	
	return props
