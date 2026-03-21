extends Node

signal gameplay_input_changed(enabled: bool)

var current_map_id: String = ""
var player_world_position: Vector2 = Vector2.ZERO

var gameplay_input_enabled: bool = true:
	set(v):
		if gameplay_input_enabled == v:
			return
		gameplay_input_enabled = v
		gameplay_input_changed.emit(v)

func lock_gameplay_input() -> void:
	gameplay_input_enabled = false

func unlock_gameplay_input() -> void:
	gameplay_input_enabled = true
