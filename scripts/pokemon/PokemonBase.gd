extends Resource

class_name PokemonBase

var id: int
var name: String
var base_stats: Dictionary # { "hp": int, "attack": int, ... }
var learnable_moves: Array[Dictionary] # [ { "level": int, "move_id": int } ]
var evolutions: Array[Dictionary] # [ { "level": int, "pokemon_id": int } ]

func _init(data := {}):
	id = data["id"]
	name = data["name"]
