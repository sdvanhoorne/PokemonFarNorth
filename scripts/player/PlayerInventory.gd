extends Node

const party_path = "res://data/player/party.json"
var PartyPokemon = [] 

func _ready():
	get_party()

func get_party():
	PartyPokemon = []
	var party = FileAccess.open(party_path, FileAccess.READ)
	if party:
		for pokemonData in JSON.parse_string(party.get_as_text()).get("Party"):
			var pokemon = Pokemon.new_existing(pokemonData)
			PartyPokemon.append(pokemon)

func write_party():
	var party_data: Array = []

	for pokemon in PartyPokemon:
		var pokemon_data := {
			"id": int(pokemon.base_data.id),
			"level": int(pokemon.level),
			"status": str(pokemon.status),
			"current_hp": int(pokemon.current_hp),
			"current_xp": int(pokemon.current_xp),
			"stats": {
				"hp": int(pokemon.stats.hp),
				"attack": int(pokemon.stats.attack),
				"defense": int(pokemon.stats.defense),
				"special_attack": int(pokemon.stats.special_attack),
				"special_defense": int(pokemon.stats.special_defense),
				"speed": int(pokemon.stats.speed)
			},
			"move_names": pokemon.move_names
		}
		party_data.append(pokemon_data)

	var save_dict := { "Party": party_data }
	var file := FileAccess.open(party_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_dict, "\t")) 
	file.close()
