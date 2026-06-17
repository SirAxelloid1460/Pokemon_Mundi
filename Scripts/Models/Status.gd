# ============================================
# Status.gd
# Clase para estados de Pokémon (quemadura, parálisis, etc.)
# Ubicación: res://scripts/models/Status.gd
# ============================================
class_name Status
extends Resource

# ============================================
# ENUM para acceso rápido
# ============================================

enum StatusID {
	FAINTED = 0,
	BURNED = 1,
	FROZEN = 2,
	PARALYZED = 3,
	POISONED = 4,
	BADLY_POISONED = 5,
	ASLEEP = 6,
	ABILITY_CHANGE = 7,
	ABILITY_SUPPRESSION = 8,
	TYPE_CHANGE = 9,
	MIMIC = 10,
	SUBSTITUTE = 11,
	ILLUSION = 12,
	BOUND = 13,
	CURSE = 14,
	PERISH_SONG = 15,
	SEEDED = 16,
	SALT_CURE = 17,
	MIMIC_2 = 18,
	AUTOMATIZED = 19,
	IDENTIFIED = 20,
	MINIMIZED = 21,
	TAR_SHOT = 22,
	GROUNDED = 23,
	MAGNETIC_LEVITATION = 24,
	TELEKINESIS = 25,
	AQUA_RING = 26,
	ROOTING = 27,
	LASER_FOCUS = 28,
	TAKING_AIM = 29,
	DROWSY = 30,
	CHARGED = 31,
	STOCKPILE = 32,
	DEFENSE_CURL = 33,
	CANT_ESCAPE = 34,
	NO_RETREAT = 35,
	OCTOLOCK = 36,
	DISABLE = 37,
	EMBARGO = 38,
	HEAL_BLOCK = 39,
	IMPRISONED = 40,
	TAUNT = 41,
	THROAT_CHOP = 42,
	TORMENT = 43,
	CONFUSION = 44,
	INFATUATION = 45,
	GETTING_PUMPED = 46,
	GUARD_SPLIT = 47,
	POWER_SPLIT = 48,
	SPEED_SWAP = 49,
	POWER_TRICK = 50,
	CHOICE_LOCK = 51,
	RAMPAGE = 52,
	ROLLING = 53,
	MAKING_UPROAR = 54,
	BIDE = 55,
	RECHARGE = 56,
	CHARGING_TURN = 57,
	FLINCH = 58,
	BRACING = 59,
	CENTER_OF_ATTENTION = 60,
	MAGIC_COAT = 61,
	PROTECTION = 62,
	SEMI_INVULNERABLE = 63,
	DYNAMAX = 64,
	MEGA_EVOLVED = 65,
	GIGAMAX = 66,
	TERA_STELLARIZED = 67,
	MYSTERIOUS_BARRIER = 68
}

# ============================================
# PROPIEDADES
# ============================================

var id: int
var name: String
var icon: String

# Características del estado
var volatile: bool           # Se elimina al cambiar de Pokémon
var damaging: bool          # Causa daño por turno
var incapacitating: bool    # Impide actuar
var accumulative: bool      # Se acumula (ej: Badly Poisoned)
var focus: bool             # Requiere concentración

# ============================================
# CONSTRUCTOR
# ============================================

func _init(
	_id: int = 0,
	_name: String = "None",
	_volatile: bool = false,
	_damaging: bool = false,
	_incapacitating: bool = false,
	_accumulative: bool = false,
	_focus: bool = false
):
	id = _id
	name = _name
	icon = _name
	volatile = _volatile
	damaging = _damaging
	incapacitating = _incapacitating
	accumulative = _accumulative
	focus = _focus

# ============================================
# LOCALIZACIÓN (PATRÓN ESTÁNDAR)
# ============================================

func get_display_name() -> String:
	#Nombre traducido para mostrar al usuario
	return tr(name)

func get_description() -> String:
	#Descripción traducida
	return tr(name + "_DESC")

# ============================================
# PROPIEDADES DEL ESTADO
# ============================================

func is_major_status() -> bool:
	#Retorna true si es un estado mayor (BRN, FRZ, PAR, PSN, SLP)
	return id >= StatusID.BURNED and id <= StatusID.ASLEEP

func is_volatile() -> bool:
	#Retorna true si el estado desaparece al cambiar de Pokémon
	return volatile

func is_permanent() -> bool:
	#Retorna true si el estado es permanente (no volátil)
	return not volatile

func causes_damage() -> bool:
	#Retorna true si el estado causa daño por turno
	return damaging

func prevents_action() -> bool:
	#Retorna true si el estado puede impedir actuar
	return incapacitating

func is_accumulative() -> bool:
	#Retorna true si el daño se acumula (Badly Poisoned, Curse)
	return accumulative

func requires_focus() -> bool:
	#Retorna true si requiere concentración (Bide, Charge)
	return focus

# ============================================
# EFECTOS EN BATALLA
# ============================================

func get_damage_per_turn(max_hp: int, turns_active: int = 1) -> int:
	#Calcula el daño que causa este estado por turno
	if not damaging:
		return 0
	
	match id:
		StatusID.BURNED:
			# Quemadura: 1/16 del HP máximo
			return max(1, int(max_hp / 16.0))
		
		StatusID.POISONED:
			# Envenenado: 1/8 del HP máximo
			return max(1, int(max_hp / 8.0))
		
		StatusID.BADLY_POISONED:
			# Gravemente envenenado: daño aumenta cada turno
			return max(1, int(max_hp * turns_active / 16.0))
		
		StatusID.BOUND:
			# Atrapado (Bind, Wrap, etc.): 1/8 del HP máximo
			return max(1, int(max_hp / 8.0))
		
		StatusID.CURSE:
			# Maldición: 1/4 del HP máximo
			return max(1, int(max_hp / 4.0))
		
		StatusID.SEEDED:
			# Drenadoras (Leech Seed): 1/8 del HP máximo
			return max(1, int(max_hp / 8.0))
	
	return 0

func get_speed_modifier() -> float:
	#Retorna el modificador de velocidad (1.0 = normal, 0.5 = mitad)
	if id == StatusID.PARALYZED:
		return 0.5  # Parálisis reduce velocidad a la mitad
	return 1.0

func get_attack_modifier() -> float:
	#Retorna el modificador de ataque físico
	if id == StatusID.BURNED:
		return 0.5  # Quemadura reduce ataque físico a la mitad
	return 1.0

func can_act_this_turn() -> bool:
	#Verifica si el Pokémon puede actuar este turno (probabilístico)
	match id:
		StatusID.FROZEN:
			# 20% de descongelarse
			return randf() < 0.2
		
		StatusID.PARALYZED:
			# 25% de no poder atacar
			return randf() > 0.25
		
		StatusID.ASLEEP:
			# Se maneja por contador de turnos
			return false
		
		StatusID.FLINCH:
			# Retroceso impide actuar este turno
			return false
		
		StatusID.RECHARGE:
			# Recarga impide actuar
			return false
		
		StatusID.CONFUSION:
			# 33% de golpearse a sí mismo
			if randf() < 0.33:
				return false
	
	return true

# ============================================
# INFORMACIÓN Y UI
# ============================================

func get_abbreviation() -> String:
	#Retorna la abreviatura del estado (BRN, PAR, etc.)
	match id:
		StatusID.BURNED: return "BRN"
		StatusID.FROZEN: return "FRZ"
		StatusID.PARALYZED: return "PAR"
		StatusID.POISONED: return "PSN"
		StatusID.BADLY_POISONED: return "TOX"
		StatusID.ASLEEP: return "SLP"
		StatusID.FAINTED: return "FNT"
		_: return name.substr(0, 3).to_upper()

func get_color() -> Color:
	#Retorna el color asociado al estado
	match id:
		StatusID.BURNED: return Color(0.95, 0.45, 0.20)  # Naranja-rojo
		StatusID.FROZEN: return Color(0.40, 0.75, 0.95)  # Azul claro
		StatusID.PARALYZED: return Color(0.95, 0.85, 0.30)  # Amarillo
		StatusID.POISONED: return Color(0.70, 0.35, 0.80)  # Morado
		StatusID.BADLY_POISONED: return Color(0.55, 0.20, 0.65)  # Morado oscuro
		StatusID.ASLEEP: return Color(0.65, 0.65, 0.70)  # Gris
		StatusID.FAINTED: return Color(0.30, 0.30, 0.30)  # Gris oscuro
		StatusID.CONFUSION: return Color(0.95, 0.75, 0.50)  # Naranja claro
		_: return Color.WHITE

func get_icon_path() -> String:
	#Retorna la ruta al icono del estado
	return "res://Assets/Graphic/Sprites/status/" + icon.to_lower() + ".png"

func has_icon() -> bool:
	#Verifica si existe el icono
	return ResourceLoader.exists(get_icon_path())

# ============================================
# DURACIÓN Y CONTADORES
# ============================================

func get_default_duration() -> int:
	#Retorna la duración por defecto del estado (en turnos, -1 = permanente)
	match id:
		StatusID.ASLEEP:
			# 1-3 turnos
			return randi_range(1, 3)
		
		StatusID.CONFUSION:
			# 1-4 turnos
			return randi_range(1, 4)
		
		StatusID.FLINCH:
			# Solo dura 1 turno
			return 1
		
		StatusID.BOUND:
			# 4-5 turnos
			return randi_range(4, 5)
		
		StatusID.DISABLE:
			# 4 turnos
			return 4
		
		StatusID.TAUNT:
			# 3 turnos
			return 3
		
		StatusID.EMBARGO:
			# 5 turnos
			return 5
		
		StatusID.HEAL_BLOCK:
			# 5 turnos
			return 5
		
		# Estados permanentes hasta curación
		StatusID.BURNED, StatusID.FROZEN, StatusID.PARALYZED, \
		StatusID.POISONED, StatusID.BADLY_POISONED:
			return -1
		
		# Estados volátiles sin duración fija
		_:
			if volatile:
				return -1  # Se elimina al cambiar
			else:
				return -1  # Permanente hasta curación

# ============================================
# CURACIÓN Y REMOCIÓN
# ============================================

func can_be_cured_by_rest() -> bool:
	#Retorna true si Rest puede curar este estado
	return is_major_status()

func can_be_cured_by_full_heal() -> bool:
	#Retorna true si Full Heal puede curar este estado
	return is_major_status() or id == StatusID.CONFUSION

func can_be_cured_by_awakening() -> bool:
	#Retorna true si Awakening puede curar este estado
	return id == StatusID.ASLEEP

func can_be_cured_by_burn_heal() -> bool:
	#Retorna true si Burn Heal puede curar este estado
	return id == StatusID.BURNED

func can_be_cured_by_ice_heal() -> bool:
	#Retorna true si Ice Heal puede curar este estado
	return id == StatusID.FROZEN

func can_be_cured_by_paralyze_heal() -> bool:
	#Retorna true si Paralyze Heal puede curar este estado
	return id == StatusID.PARALYZED

func can_be_cured_by_antidote() -> bool:
	#Retorna true si Antidote puede curar este estado
	return id == StatusID.POISONED or id == StatusID.BADLY_POISONED

# ============================================
# UTILIDADES
# ============================================

func is_valid() -> bool:
	#Verifica si el estado es válido
	return id >= 0 and name != ""

func _to_string() -> String:
	#Para debugging
	return "Status(%d: %s, %s)" % [
		id, 
		name,
		"Volatile" if volatile else "Permanent"
	]

# ============================================
# COMPATIBILIDAD CON TIPOS
# ============================================

func is_immune_type(type_id: int) -> bool:
	#Verifica si un tipo es inmune a este estado
	match id:
		StatusID.BURNED:
			# Tipo Fuego es inmune a quemadura
			return type_id == Type.TypeID.FIRE
		
		StatusID.FROZEN:
			# Tipo Hielo es inmune a congelación
			return type_id == Type.TypeID.ICE
		
		StatusID.PARALYZED:
			# Tipo Eléctrico es inmune a parálisis (Gen 6+)
			return type_id == Type.TypeID.ELECTRIC
		
		StatusID.POISONED, StatusID.BADLY_POISONED:
			# Tipos Veneno y Acero son inmunes a envenenamiento
			return type_id == Type.TypeID.POISON or type_id == Type.TypeID.STEEL
	
	return false

# ============================================
# INFORMACIÓN PARA BATALLA
# ============================================

func get_battle_message_on_apply() -> String:
	#Mensaje cuando se aplica el estado
	match id:
		StatusID.BURNED: return "{pokemon} fue quemado!"
		StatusID.FROZEN: return "{pokemon} fue congelado!"
		StatusID.PARALYZED: return "{pokemon} fue paralizado!"
		StatusID.POISONED: return "{pokemon} fue envenenado!"
		StatusID.BADLY_POISONED: return "{pokemon} fue gravemente envenenado!"
		StatusID.ASLEEP: return "{pokemon} se durmió!"
		StatusID.CONFUSION: return "{pokemon} se confundió!"
		_: return "{pokemon} fue afectado por " + name + "!"

func get_battle_message_on_turn() -> String:
	#Mensaje al inicio del turno si está activo
	match id:
		StatusID.BURNED: return "{pokemon} sufre quemaduras!"
		StatusID.POISONED, StatusID.BADLY_POISONED: return "{pokemon} sufre envenenamiento!"
		StatusID.ASLEEP: return "{pokemon} está dormido."
		StatusID.FROZEN: return "{pokemon} está congelado!"
		StatusID.PARALYZED: return "{pokemon} está paralizado!"
		StatusID.CONFUSION: return "{pokemon} está confundido!"
		_: return ""

func get_battle_message_on_cure() -> String:
	#Mensaje cuando se cura el estado
	match id:
		StatusID.BURNED: return "{pokemon} se curó de la quemadura!"
		StatusID.FROZEN: return "{pokemon} se descongeló!"
		StatusID.PARALYZED: return "{pokemon} se curó de la parálisis!"
		StatusID.POISONED, StatusID.BADLY_POISONED: return "{pokemon} se curó del envenenamiento!"
		StatusID.ASLEEP: return "{pokemon} se despertó!"
		StatusID.CONFUSION: return "{pokemon} dejó de estar confundido!"
		_: return "{pokemon} se curó!"
