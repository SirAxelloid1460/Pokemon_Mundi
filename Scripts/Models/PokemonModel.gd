class_name Pokemon

func _init(_pokeID:int, _pokedexNr:int, _name:String, _description:String, _species:String, _type1:String, _type2:String, _height:float, _weight:float, _innateAbilities:Array, _baseFriendship:int, _XPYield:int, _flatcatchRate:int, _catchRateFullHP, _locations:Array, _learnableMoves:Array, _learnableTM:Array, _learnableHM:Array, _shiny:bool, _alolan:bool, _galarian:bool, _gender:bool, _paldean:bool, _ultraBeast:bool, _moves:Array, _HP_max:int, _Attack_max:int, _Defense_max:int, _SpAttack_max:int, _SpDefense_max:int, _Speed_max:int, _growthType:String, _evolve_from:int, _evolve_to:Array):
	pokeID = _pokeID
	pokedexNr = _pokedexNr
	name = _name
	description = _description
	species = _species
	type1 = _type1
	type2 = _type2
	height = _height
	weight = _weight
	innateAbilities = _innateAbilities
	baseFriendship = _baseFriendship
	XPYield = _XPYield
	flatcatchRate = _flatcatchRate
	catchRateFullHP = _catchRateFullHP
	locations = _locations
	learnableMoves = _learnableMoves
	learnableTM = _learnableTM
	learnableHM = _learnableHM
	shiny = _shiny
	alolan = _alolan
	galarian = _galarian
	gender = _gender
	paldean = _paldean
	ultraBeast = _ultraBeast

	moves = _moves

	HP_max = _HP_max
	Attack_max = _Attack_max
	Defense_max = _Defense_max
	SpAttack_max = _SpAttack_max
	SpDefense_max = _SpDefense_max
	Speed_max = _Speed_max

	growthType = _growthType
	
	avatar_front = str(_pokeID) + "_front"
	avatar_back = str(_pokeID) + "_back"
	avatar_system = str(_pokeID) + "_system"
	avatar_overworld = str(_pokeID) + "_overworld"
	
	roar = str(_pokeID) + "_roar"
	evolve_from = _evolve_from
	evolve_to = _evolve_to
	caught = false
	terastellarized = false


#variables
var pokeID: int
var pokedexNr: int
var name: String
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
var paldean: bool
var ultraBeast: bool

var moves: Array

var currentFriendship: int
var currentStatus: String

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
var evolve_from: int
var evolve_to: Array

var caught: bool
var terastellarized: bool
