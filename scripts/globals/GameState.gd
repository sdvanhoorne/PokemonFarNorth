extends Node

signal gameplay_input_changed(enabled: bool)
signal state_changed(new_state: State)

### STATE ###
enum WorldEntry { NEW_GAME, LOAD_GAME, RETURN_FROM_BATTLE }
enum State { MAIN_MENU, OVERWORLD, BATTLE}

var world_entry: WorldEntry = WorldEntry.LOAD_GAME

var current_state: State = State.MAIN_MENU:
	set(value):
		if current_state == value:
			return
		current_state = value
		state_changed.emit(value)

### PLAYER ###

var current_map_id: String = ""
var player_position: Vector2 = Vector2.ZERO
var player_facing_direction: String = "down"
var defeated_trainers: Dictionary = {}
var event_flags: Dictionary = {}

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

func reset_run_state() -> void:
	current_map_id = ""
	player_position = Vector2.ZERO
	player_facing_direction = "down"
	defeated_trainers.clear()
	event_flags.clear()

func mark_trainer_defeated(trainer_id: String) -> void:
	defeated_trainers[trainer_id] = true

func is_trainer_defeated(trainer_id: String) -> bool:
	return defeated_trainers.get(trainer_id, false)

func set_event_flag(flag_name: String, value: bool = true) -> void:
	event_flags[flag_name] = value

func get_event_flag(flag_name: String, default_value: bool = false) -> bool:
	return event_flags.get(flag_name, default_value)
