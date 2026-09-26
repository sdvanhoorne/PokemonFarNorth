extends Node2D

@onready var map_loader: MapLoader = $MapLoader
@onready var map_name_control: Control = $MapNameCanvas/MapName


func _ready() -> void:
	DialogueManager.message_box = $DialogueCanvas/MessageBox
	map_loader.initialize(
		self,
		map_name_control
	)

func load_map(
	request: MapLoadRequest,
	player: Node2D = null
) -> Node2D:
	return await map_loader.load_map(request, player)

func capture_runtime_state() -> void:
	map_loader.capture_runtime_state()
