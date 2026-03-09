extends Resource
class_name PokemonBase

var id: int
var name: String
var type1: String
var type2: String
var base_stats = null
var learnable_moves = []
var evolutions = null
var sprite: Texture2D

func _init(_id: int):
	id = _id
	name = Pokedex.pokedex[id]
	if name == null:
		push_error("Pokémon ID %d not found in Pokedex." % id)
		return 
	
	var path = "res://data/pokemon/%s.json" % name
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("Could not find file for %d" % name)
		return
		
	var data = JSON.parse_string(file.get_as_text())
	
	if data == null:
		print("Data file incomplete for %d" % name)
		return
		
	type1 = data["type1"]
	type2 = data["type2"]
	base_stats = PokemonStats.new(data["base_stats"])
	learnable_moves = data["learnable_moves"] as Array[Dictionary]
	evolutions = data.get("evolutions", [])
	
	sprite = Paths.load_sprite(Paths.join(Paths.POKEMON_FRONT_SPRITES, name))
