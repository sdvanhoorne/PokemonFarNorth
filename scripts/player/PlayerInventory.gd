extends Node

const party_path = "res://data/player/party.json"
var PartyPokemon = [] # array of pokemon

func _ready():
	get_party()

#func get_party() -> Array[Dictionary]:
	#var party_pokemon = []
	#var party = FileAccess.open(party_path, FileAccess.READ)
	#if party:
		#for pokemonName in JSON.parse_string(party.get_as_text())["party"]:
			#var pokemonData = FileAccess.open("res://data/pokemon/" + pokemonName + ".json", FileAccess.READ)
			#if pokemonData == null:
				#print("Couldn't find data for " + pokemonName)
			#party_pokemon.append(JSON.parse_string(pokemonData.get_as_text()))
	#return party_pokemon

func get_party():
	PartyPokemon = []
	var party = FileAccess.open(party_path, FileAccess.READ)
	if party:
		for pokemonData in JSON.parse_string(party.get_as_text())["party"]:
			var pokemon = Pokemon.new(pokemonData)
			PartyPokemon.append(pokemon)
			
# func save_party() -> void:
	# save PartyPokemon to party.json
	
