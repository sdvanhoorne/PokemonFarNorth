extends Node

const party_path = "res://data/player/party.json"

# func _ready():

func get_party() -> Array[Dictionary]:
	var party_pokemon = []
	var party = FileAccess.open(party_path, FileAccess.READ)
	if party:
		for pokemonName in JSON.parse_string(party.get_as_text())["party"]:
			var pokemonData = FileAccess.open("res://data/pokemon/" + pokemonName + ".json", FileAccess.READ)
			if pokemonData == null:
				print("Couldn't find data for " + pokemonName)
			party_pokemon.append(JSON.parse_string(pokemonData.get_as_text()))
	return party_pokemon
