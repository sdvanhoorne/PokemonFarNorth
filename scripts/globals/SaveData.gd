extends Node

const SAVE_DIR := "user://saves"
const SAVE_PATH := SAVE_DIR + "/primary_save.json"
const SAVE_VERSION := 1

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> bool:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

	var save_data := {
		"version": SAVE_VERSION,
		"current_map_id": GameState.current_map_id,
		"player": {
			"position": {
				"x": GameState.player_position.x,
				"y": GameState.player_position.y
			},
			"facing_direction": GameState.player_facing_direction
		},
		"party": _serialize_party(),
		"defeated_trainers": GameState.defeated_trainers.keys(),
		"event_flags": GameState.event_flags.duplicate(true),
		"saved_at_unix": Time.get_unix_time_from_system()
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: failed to open save file for writing")
		return false

	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	return true

func load_game() -> bool:
	print(ProjectSettings.globalize_path("user://saves/primary_save.json"))
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: failed to open save file for reading")
		return false

	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveManager: save file is invalid")
		return false

	_apply_save_data(parsed)
	return true

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func get_save_summary() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		return {}

	return {
		"current_map_id": parsed.get("current_map_id", ""),
		"saved_at_unix": parsed.get("saved_at_unix", 0),
		"party_count": parsed.get("party", []).size()
	}

func _apply_save_data(data: Dictionary) -> void:
	GameState.current_map_id = data.get("current_map_id", "")
	var player_data: Dictionary = data.get("player", {})
	var pos_data: Dictionary = player_data.get("position", {})

	GameState.player_position = Vector2(
		float(pos_data.get("x", 0.0)),
		float(pos_data.get("y", 0.0))
	)
	GameState.player_facing_direction = player_data.get("facing_direction", "down")

	GameState.defeated_trainers.clear()
	for trainer_id in data.get("defeated_trainers", []):
		GameState.defeated_trainers[String(trainer_id)] = true

	GameState.event_flags = data.get("event_flags", {}).duplicate(true)

	_deserialize_party(data.get("party", []))

func _serialize_party() -> Array:
	var party_data: Array = []

	for pokemon in PlayerInventory.PartyPokemon:
		party_data.append({
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
		})

	return party_data

func _deserialize_party(party_data: Array) -> void:
	PlayerInventory.PartyPokemon.clear()

	for pokemon_data in party_data:
		var pokemon = Pokemon.new_existing(pokemon_data)
		PlayerInventory.PartyPokemon.append(pokemon)
