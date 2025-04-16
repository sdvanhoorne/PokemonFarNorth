extends Node

const party_path = "res://data/player/party.json"
var PartyPokemon = [] # array of pokemon

func _ready():
	get_party()

func get_party():
	PartyPokemon = []
	var party = FileAccess.open(party_path, FileAccess.READ)
	if party:
		for pokemonData in JSON.parse_string(party.get_as_text()).get("Party"):
			var pokemon = Pokemon.new(pokemonData)
			PartyPokemon.append(pokemon)
