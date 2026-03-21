extends Node

var trainers: Dictionary = {}

func _ready() -> void:
	var file := FileAccess.open("res://data/npc/trainers.json", FileAccess.READ)
	if file == null:
		push_error("Could not open trainers.json")
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		trainers = parsed
	else:
		push_error("Invalid trainers.json format")

func get_trainer_class(id: String) -> String:
	if trainers.has(id):
		return trainers[id]["trainer_class"]
	push_error("Could not find class for trainer %d", id)
	return ""
	
func get_trainer_pokemon(id: String) -> Array[Pokemon]:
	if trainers.has(id):
		var pokemon: Array[Pokemon] = []
		for p in trainers[id]["battle_team"]:
			pokemon.append(Pokemon.new_trainer_pokemon(p))
		return pokemon
	push_error("Could not find pokemon for trainer %d", id)
	return []
