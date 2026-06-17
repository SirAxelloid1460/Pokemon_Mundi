extends Node

var moves_list_DATA = {}
var pokemon_list_DATA = {}
var status_list_DATA = {}
var pokeball_list_DATA = {}
var type_list_DATA = {}

var moves_list_path = "res://Scripts/StaticData/Moves.json"
var pokemon_list_path = "res://Scripts/StaticData/Pokemon.json"
var status_list_path = "res://Scripts/StaticData/Status.json"
var pokeball_list_path = "res://Scripts/StaticData/Pokeballs.json"
var type_list_path = "res://Scripts/StaticData/Types.json"

func _ready() -> void:
	moves_list_DATA = load_json_list(moves_list_path)
	pokemon_list_DATA = load_json_list(pokemon_list_path)
	status_list_DATA = load_json_list(status_list_path)
	pokeball_list_DATA = load_json_list(pokeball_list_path)
	type_list_DATA = load_json_list(type_list_path)

func load_json_list(filePath:String):
	if FileAccess.file_exists(filePath):
		
		var dataFile = FileAccess.open(filePath, FileAccess.READ)
		var parsedResult = JSON.parse_string(dataFile.get_as_text())
		
		if parsedResult is Dictionary:
			return parsedResult
		else:
			print("Error reading file")
		
	else:
		print("File not found")
