class_name SaveData
extends Resource

const SAVE_GAME_PATH = "user://saves/primary_save.tres"

@export var player_inventory: Resource
@export var current_map_id: String
@export var player_position: Vector2

func write_savedata() -> void:
	ResourceSaver.save(self, SAVE_GAME_PATH)

static func load_savedata() -> Resource:
	if ResourceLoader.exists(SAVE_GAME_PATH):
		return load(SAVE_GAME_PATH)
	return null
