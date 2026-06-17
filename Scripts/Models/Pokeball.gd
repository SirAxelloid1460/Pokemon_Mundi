# ============================================
# Pokeball.gd
# Clase para Pokéballs
# Compatible con JSON de StaticDataManagement
# Ubicación: res://scripts/models/Pokeball.gd
# ============================================
class_name Pokeball
extends Resource

# ============================================
# PROPIEDADES BASE (compatibles con tu JSON)
# ============================================

var ballID: int
var icon: int
var name: String
var description: String
var rate_multiplier: float
var flat_bonus: int
var price: int

# ============================================
# PROPIEDADES CALCULADAS
# ============================================

var sfx: String
var animation: int

# ============================================
# CONSTRUCTOR
# ============================================

func _init(
	_ballID: int = 1,
	_icon: int = 0,
	_name: String = "POKEBALL",
	_description: String = "",
	_rate_multiplier: float = 1.0,
	_flat_bonus: int = 0,
	_price: int = 200
):
	ballID = _ballID
	icon = _icon
	name = _name
	description = _description
	rate_multiplier = _rate_multiplier
	flat_bonus = _flat_bonus
	price = _price
	sfx = str(_ballID) + ".ogg"
	animation = _icon

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
# MÉTODOS DE CAPTURA
# ============================================

func calculate_catch_rate(pokemon_catch_rate: int, pokemon_hp_percent: float, 
						  status_modifier: float = 1.0) -> float:
	#Calcula la probabilidad de captura
	# Master Ball = captura garantizada
	if is_master_ball():
		return 1.0
	
	# Fórmula simplificada de Pokémon Gen III+
	var hp_modifier = (3.0 - 2.0 * pokemon_hp_percent)
	var modified_catch_rate = ((pokemon_catch_rate * rate_multiplier) + flat_bonus) * hp_modifier * status_modifier
	
	# Limitar entre 1 y 255
	modified_catch_rate = clamp(modified_catch_rate, 1, 255)
	
	# Probabilidad final (simplificada)
	var catch_probability = modified_catch_rate / 255.0
	
	return clamp(catch_probability, 0.0, 1.0)

func is_master_ball() -> bool:
	#Retorna true si es Master Ball (captura garantizada)
	return rate_multiplier >= 1000000

func is_purchasable() -> bool:
	#Retorna true si se puede comprar en tiendas
	return price > 0

# ============================================
# INFORMACIÓN
# ============================================

func get_info_text() -> String:
	#Retorna información de la ball para UI
	var info = tr(name) + "\n"
	
	if is_master_ball():
		info += "¡Captura garantizada!\n"
	else:
		info += "Tasa: x" + str(rate_multiplier) + "\n"
		if flat_bonus != 0:
			info += "Bonus: " + ("+" if flat_bonus > 0 else "") + str(flat_bonus) + "\n"
	
	if is_purchasable():
		info += "Precio: $" + str(price)
	else:
		info += "No disponible en tiendas"
	
	return info

func get_display_price() -> String:
	#Retorna el precio formateado
	if price == 0:
		return "---"
	return "$" + str(price)

# ============================================
# RUTAS DE RECURSOS
# ============================================

func get_sprite_path() -> String:
	#Ruta al sprite de la ball
	return "res://Assets/Graphic/Sprites/pokeball/ball_%d.png" % icon

func get_sfx_path() -> String:
	#Ruta al sonido de la ball
	return "res://Assets/SFX/pokeball/" + sfx

func has_sprite() -> bool:
	#Verifica si existe el sprite
	return ResourceLoader.exists(get_sprite_path())

func has_sfx() -> bool:
	#Verifica si existe el sonido
	return ResourceLoader.exists(get_sfx_path())

# ============================================
# UTILIDADES
# ============================================

func is_valid() -> bool:
	#Verifica si la ball es válida
	return ballID > 0 and name != "" and rate_multiplier > 0

func _to_string() -> String:
	#Para debugging
	return "Pokeball(%d: %s, x%.1f, $%d)" % [ballID, name, rate_multiplier, price]
