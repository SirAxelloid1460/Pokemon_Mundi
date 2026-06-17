class_name PokemonList

var pokemon_graph_path:String = "res://Assets/Graphic/Sprites/pokemon"
var pokemon_sfx_path:String = "res://Assets/SFX/pokemon"

func get_list() -> Array[Pokemon]:
	var pokemon_list: Array[Pokemon] = []
	pokemon_list.append(Pokemon.new())

	return pokemon_list
