extends Node

var encounter_data = []
var rng = RandomNumberGenerator.new()

func load_encounters(file_path: String):
	var json_file = FileAccess.open(file_path, FileAccess.READ)
	if json_file:
		var result = JSON.parse_string(json_file.get_as_text())
		encounter_data = result["encounters"]
		
func roll_encounter() -> Pokemon:
	var roll = rng.randi_range(1, 100)
	var current = 0

	for entry in encounter_data:
		current += entry["rate"]
		if roll <= current:
			var minLevel = entry.get("level_min")
			var maxLevel = entry.get("level_max")
			var pokemonLevel = rng.randi_range(minLevel, maxLevel)
			return load_pokemon(entry["pokemon"], pokemonLevel)
	
	return Pokemon.new()
	
func load_pokemon(pokemonName: String, pokemonLevel: int) -> Pokemon:
	var path = "res://data/pokemon/%s.json" % pokemonName
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var response = JSON.parse_string(file.get_as_text())
		var wildPokemon = Pokemon.new_wild(pokemonLevel, response)
		return wildPokemon
	else:
		push_error("Failed to load Pokémon data at %s" % path)
		return Pokemon.new()

func check_for_encounter_at_position(pos: Vector2, dir: Vector2, encounterLayer: TileMapLayer):
	var local_pos = encounterLayer.to_local(pos)
	var cell_coords = encounterLayer.local_to_map(local_pos)
	var tile_data = encounterLayer.get_cell_tile_data(cell_coords)

	if tile_data and tile_data.get_custom_data("encounter_grass") == true:
		if randf() < 0.05: # wild encounter rate
			print("A wild encounter begins!")
			load_encounters("res://data/encounters/" + encounterLayer.get_parent().name + ".json")
			var encountered_pokemon = EncounterManager.roll_encounter()
			BattleManager.start_battle([encountered_pokemon], pos, dir, encounterLayer.get_parent().scene_file_path)
