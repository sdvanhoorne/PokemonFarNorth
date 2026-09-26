extends Node2D
class_name World

@onready var map_loader: MapLoader = $MapLoader

func _ready() -> void:
	DialogueManager.message_box = $DialogueCanvas/MessageBox
	map_loader.initialize(self)
	var request = _get_initial_map_request()
	await map_loader.load_map(request)

func load_map(request: MapLoadRequest, player: Node2D = null) -> Node2D:
	return await map_loader.load_map(request, player)
	
func _get_initial_map_request() -> MapLoadRequest:
	match GameState.world_entry:
		GameState.WorldEntry.NEW_GAME:
			return MapLoadRequest.for_spawn(
				"starting_town",
				"StartingHouseSpawn",
				"down"
			)

		GameState.WorldEntry.LOAD_GAME:
			return MapLoadRequest.for_position(
				GameState.current_map_id,
				GameState.player_position,
				GameState.player_facing_direction
			)

	return null

func capture_runtime_state() -> void:
	map_loader.capture_runtime_state()
