extends Node

var encounter_data = []
var rng = RandomNumberGenerator.new()

func load_encounters(file_path: String):
	var json_file = FileAccess.open(file_path, FileAccess.READ)
	if json_file:
		var result = JSON.parse_string(json_file.get_as_text())
		encounter_data = result["encounters"]
		
func roll_encounter() -> Dictionary:
	var roll = rng.randi_range(1, 100)
	var current = 0

	for entry in encounter_data:
		current += entry["rate"]
		if roll <= current:
			return load_pokemon_data(entry["pokemon"])
	
	return {}
	
func load_pokemon_data(pokemon_name: String) -> Dictionary:
	var path = "res://data/pokemon/%s.json" % pokemon_name.to_lower()
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var response = JSON.parse_string(file.get_as_text())
		return response
	else:
		push_error("Failed to load Pokémon data at %s" % path)
		return {}

func check_for_encounter_at_position(pos: Vector2, dir: Vector2, encounterLayer: TileMapLayer):
	var local_pos = encounterLayer.to_local(pos)
	var cell_coords = encounterLayer.local_to_map(local_pos)
	var tile_data = encounterLayer.get_cell_tile_data(cell_coords)

	if tile_data and tile_data.get_custom_data("encounter_grass") == true:
		if randf() < 0.05: # wild encounter rate
			print("A wild encounter begins!")
			load_encounters("res://data/encounters/" + encounterLayer.get_parent().name + ".json")
			var encountered_pokemon = EncounterManager.roll_encounter()
			BattleManager.start_battle(encountered_pokemon, pos, dir, encounterLayer.get_parent().scene_file_path)
