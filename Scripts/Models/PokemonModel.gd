class_name Pokemon

# Construcción flexible: Pokemon.new() vacío o Pokemon.new(dict) desde Pokemon.json.
func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		from_dict(data)

func from_dict(d: Dictionary) -> void:
	pokeID = int(d.get("pokeID", 0))
	pokedexNr = int(d.get("pokedexNr", pokeID))
	name = str(d.get("Name", ""))
	name_en = str(d.get("NameEN", name))
	description = str(d.get("Description", ""))
	species = str(d.get("Species", ""))
	type1 = str(d.get("Type1", ""))
	type2 = str(d.get("Type2", ""))
	height = float(d.get("Height", 0.0))
	weight = float(d.get("Weight", 0.0))
	innateAbilities = d.get("Abilities", [])
	baseFriendship = int(d.get("BaseFriendship", 0))
	XPYield = int(d.get("XPYield", 0))
	flatcatchRate = int(d.get("CatchRate", 0))
	catchRateFullHP = int(d.get("CatchRate", 0))
	growthType = str(d.get("GrowthType", ""))
	gender_rate = int(d.get("GenderRate", -1))
	gender = gender_rate != -1
	isBaby = bool(d.get("IsBaby", false))
	isLegendary = bool(d.get("IsLegendary", false))
	isMythical = bool(d.get("IsMythical", false))
	evolution_chain = int(d.get("EvolutionChain", 0))
	evolve_from = int(d.get("EvolveFrom", 0))
	evolve_to = d.get("EvolveTo", [])

	# Específicos de Mundi (placeholder hasta definir reglas de tier/stats)
	tier = str(d.get("Tier", ""))
	level_cap = int(d.get("LevelCap", 0))
	HP_max = int(d.get("HP_max", 0))
	Attack_max = int(d.get("Attack_max", 0))
	Defense_max = int(d.get("Defense_max", 0))
	SpAttack_max = int(d.get("SpAttack_max", 0))
	SpDefense_max = int(d.get("SpDefense_max", 0))
	Speed_max = int(d.get("Speed_max", 0))

	# Datos aún no poblados (learnsets, localizaciones, formas regionales)
	locations = d.get("Locations", [])
	learnableMoves = d.get("LearnableMoves", [])
	learnableTM = d.get("LearnableTM", [])
	learnableHM = d.get("LearnableHM", [])
	shiny = bool(d.get("Shiny", false))
	alolan = bool(d.get("Alolan", false))
	galarian = bool(d.get("Galarian", false))
	paldean = bool(d.get("Paldean", false))
	ultraBeast = bool(d.get("UltraBeast", false))
	moves = d.get("Moves", [])

	_derive_assets()

func _derive_assets() -> void:
	avatar_front = str(pokeID) + "_front"
	avatar_back = str(pokeID) + "_back"
	avatar_system = str(pokeID) + "_system"
	avatar_overworld = str(pokeID) + "_overworld"
	roar = str(pokeID) + "_roar"
	caught = false
	terastellarized = false

# Nombre mostrable: usa el nickname si existe, si no el nombre de especie.
func display_name() -> String:
	return nickname if nickname != "" else name

func has_two_types() -> bool:
	return type2 != ""


#variables
var pokeID: int
var pokedexNr: int
var name: String
var name_en: String
var description: String
var species: String
var type1: String
var type2: String
var height: float
var weight: float
var innateAbilities: Array
var baseFriendship: int
var XPYield: int
var flatcatchRate: int
var catchRateFullHP: int
var locations: Array
var learnableMoves: Array
var learnableTM: Array
var learnableHM: Array
var shiny: bool
var alolan: bool
var galarian: bool
var gender: bool
var gender_rate: int
var paldean: bool
var ultraBeast: bool
var isBaby: bool
var isLegendary: bool
var isMythical: bool

var moves: Array

var currentFriendship: int
var currentStatus: String

# Específicos de Pokémon Mundi
var tier: String
var level_cap: int

var HP_max: int
var Attack_max: int
var Defense_max: int
var SpAttack_max: int
var SpDefense_max: int
var Speed_max: int

var HP_current: int
var Attack_current: int
var Defense_current: int
var SpAttack_current: int
var SpDefense_current: int
var Speed_current: int

var nickname: String
var currentXP: int
var growthType: String
var XP_next_level: int

var avatar_front: String
var avatar_back: String
var avatar_system: String
var avatar_overworld: String

var roar: String
var evolution_chain: int
var evolve_from: int
var evolve_to: Array

var caught: bool
var terastellarized: bool
