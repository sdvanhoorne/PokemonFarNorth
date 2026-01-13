extends Node2D
class_name Interactable

@export var enabled: bool = true
@export var cooldown_sec: float = 0.0  # optional anti-spam
@export var prompt_text: String = ""   # optional (for "A: Talk" later)

var _busy := false
var _cooling_down := false

func can_interact(_player: Node) -> bool:
	return enabled and (not _busy) and (not _cooling_down) and GameState.gameplay_input_enabled

func interact(player: Node) -> void:
	# Player calls this. Subclasses implement _do_interact().
	if not can_interact(player):
		return

	_busy = true
	get_viewport().set_input_as_handled()
	await _do_interact(player)
	_busy = false

	if cooldown_sec > 0.0:
		_cooling_down = true
		await get_tree().create_timer(cooldown_sec).timeout
		_cooling_down = false

func _do_interact(_player: Node) -> void:
	push_error("_do_interact not implemented")
