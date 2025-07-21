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
			var pokemon = Pokemon.new_existing(pokemonData)
			PartyPokemon.append(pokemon)

func write_party():
	var party_data: Array = []

	for pokemon in PartyPokemon:
		var pokemon_data := {
			"id": int(pokemon.base_data.id),
			"level": int(pokemon.level),
			"status": pokemon.status,
			"current_hp": pokemon.current_hp,
			"current_xp": pokemon.current_xp,
			"stats": {
				"hp": pokemon.stats.hp,
				"attack": pokemon.stats.attack,
				"defense": pokemon.stats.defense,
				"special_attack": pokemon.stats.special_attack,
				"special_defense": pokemon.stats.special_defense,
				"speed": pokemon.stats.speed
			},
			"move_ids": pokemon.move_ids
		}
		party_data.append(pokemon_data)

	var save_dict := { "Party": party_data }
	var file := FileAccess.open(party_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_dict, "\t"))  # Pretty-print with tab spacing
	file.close()
