extends Node

var encounter_data: Array = []
var encounter_rate: float = 0.05
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func load_encounters_for_map(map_id: String) -> void:
	encounter_data.clear()

	var file_path := "res://data/encounters/%s.json" % map_id
	if not FileAccess.file_exists(file_path):
		push_warning("EncounterManager: no encounter file for map_id %s" % map_id)
		return

	var json_file := FileAccess.open(file_path, FileAccess.READ)
	if json_file == null:
		push_warning("EncounterManager: failed to open %s" % file_path)
		return

	var parsed = JSON.parse_string(json_file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("EncounterManager: invalid JSON in %s" % file_path)
		return

	encounter_data = parsed.get("encounters", [])

func roll_encounter() -> Pokemon:
	if encounter_data.is_empty():
		return null

	var roll := rng.randi_range(1, 100)
	var current := 0

	for entry in encounter_data:
		current += int(entry.get("rate", 0))
		if roll <= current:
			var min_level := int(entry.get("level_min", 1))
			var max_level := int(entry.get("level_max", min_level))
			var pokemon_level := rng.randi_range(min_level, max_level)
			return Pokemon.new_wild(int(entry["id"]), pokemon_level)

	return null

func check_for_encounter_at_position(
	pos: Vector2,
	dir: String,
	encounter_layer: TileMapLayer
) -> void:
	if encounter_layer == null:
		return

	var local_pos := encounter_layer.to_local(pos)
	var cell_coords := encounter_layer.local_to_map(local_pos)
	var tile_data := encounter_layer.get_cell_tile_data(cell_coords)

	if tile_data == null:
		return

	if tile_data.get_custom_data("encounter_grass") != true:
		return

	if rng.randf() >= encounter_rate:
		return

	var map_root := encounter_layer.get_parent()
	if map_root == null:
		push_warning("EncounterManager: encounter layer has no parent map node")
		return

	var map_id := _get_map_id_from_node(map_root)
	if map_id.is_empty():
		push_warning("EncounterManager: could not determine map_id from %s" % map_root.name)
		return

	load_encounters_for_map(map_id)

	var encountered_pokemon := roll_encounter()
	if encountered_pokemon == null:
		push_warning("EncounterManager: no Pokémon rolled for map_id %s" % map_id)
		return

	var intro_lines := PackedStringArray([
		"A wild %s appeared!" % encountered_pokemon.base_data.name
	])

	BattleManager.start_wild_battle(
		[encountered_pokemon],
		pos,
		dir,
		intro_lines
	)

func _get_map_id_from_node(map_node: Node) -> String:
	if map_node == null:
		return ""

	if "map_id" in map_node:
		return str(map_node.map_id)

	if map_node.has_meta("map_id"):
		return str(map_node.get_meta("map_id"))

	return ""
