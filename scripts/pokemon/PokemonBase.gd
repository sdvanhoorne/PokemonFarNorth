extends Resource

class_name PokemonBase

var id: int
var name: String
var base_stats = null
var learnable_moves: Array[Dictionary] 
var evolutions: Array[Dictionary]

func _init(data := {}):
	id = data["id"]
	name = data["name"]
	base_stats = PokemonStats.new(data["base_stats"])
	learnable_moves = data["learnable_moves"]
	evolutions = data["evolutions"]
