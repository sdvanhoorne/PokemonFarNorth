extends Resource

class_name PokemonBase

var id: int
var name: String
var type1: String
var type2: String
var base_stats = null
var learnable_moves = []
var evolutions = null

func _init(_id: int):
	id = _id
	name = Pokedex.pokedex[id]
	if name == null:
		push_error("Pokémon ID %d not found in Pokedex." % id)
		return 
	
	var path = "res://data/pokemon/%s.json" % name
	var file = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	
	type1 = data["type1"]
	type2 = data["type2"]
	base_stats = PokemonStats.new(data["base_stats"])
	learnable_moves = data["learnable_moves"] as Array[Dictionary]
	evolutions = data.get("evolutions", [])
